defmodule Medcamp.PatientCharges do
  @moduledoc """
  Patient-linked emergency consumable charges and grouped payment batches.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Medcamp.Repo
  alias Medcamp.DoctorNotes
  alias Medcamp.Nursing
  alias Medcamp.PatientCharges.PatientCharge
  alias Medcamp.PatientCharges.PatientChargeBatch
  alias Medcamp.NursingConsumables.NursingConsumable

  def list_patient_charges_for_doctor_note(doctor_note_id) do
    PatientCharge
    |> where([charge], charge.doctor_note_id == ^doctor_note_id)
    |> order_by([charge], desc: charge.inserted_at)
    |> Repo.all()
    |> Repo.preload(patient_charge_preloads())
  end

  def get_patient_charge!(id) do
    PatientCharge
    |> Repo.get!(id)
    |> Repo.preload(patient_charge_preloads())
  end

  def get_patient_charge_batch!(id) do
    PatientChargeBatch
    |> Repo.get!(id)
    |> Repo.preload([
      :patient,
      doctor_note: [:doctor],
      patient_charges: patient_charge_preloads()
    ])
  end

  def charge_summary_for_doctor_note(doctor_note_id) do
    list_patient_charges_for_doctor_note(doctor_note_id)
    |> Enum.reduce(
      %{
        total_count: 0,
        pending_review_count: 0,
        approved_count: 0,
        approved_unpaid_count: 0,
        approved_unpaid_total: 0,
        paid_count: 0,
        paid_total: 0,
        waived_count: 0
      },
      fn charge, summary ->
        summary
        |> Map.update!(:total_count, &(&1 + 1))
        |> increment_count_for(charge)
        |> add_amount_for(charge)
      end
    )
  end

  def approve_patient_charge(%PatientCharge{} = charge, approved_by_id) do
    charge
    |> PatientCharge.changeset(%{
      status: "approved",
      approved_at: DateTime.utc_now() |> DateTime.truncate(:second),
      approved_by_id: approved_by_id,
      patient_charge_batch_id: nil,
      waived_at: nil,
      waived_by_id: nil
    })
    |> Repo.update()
  end

  def waive_patient_charge(%PatientCharge{} = charge, waived_by_id) do
    charge
    |> PatientCharge.changeset(%{
      status: "waived",
      waived_at: DateTime.utc_now() |> DateTime.truncate(:second),
      waived_by_id: waived_by_id,
      patient_charge_batch_id: nil
    })
    |> Repo.update()
  end

  def create_charge_for_nursing_consumable(
        %NursingConsumable{} = consumable,
        created_by_id \\ nil
      ) do
    existing_charge = Repo.get_by(PatientCharge, nursing_consumable_id: consumable.id)

    cond do
      existing_charge ->
        {:ok, Repo.preload(existing_charge, patient_charge_preloads())}

      is_nil(consumable.patient_id) or is_nil(consumable.doctor_note_id) ->
        {:ok, nil}

      true ->
        consumable =
          Repo.preload(consumable, [
            :patient,
            :doctor_note,
            nursing_allocation: [inventory_issued: [:inventory_received, :batch]]
          ])

        item_details = Nursing.allocation_item_details(consumable.nursing_allocation)
        unit_price = charge_unit_price(consumable)

        %PatientCharge{}
        |> PatientCharge.changeset(%{
          description: build_charge_description(consumable, item_details),
          quantity: consumable.consumed_quantity,
          unit_price: unit_price,
          total_price: unit_price * consumable.consumed_quantity,
          status: "pending_review",
          patient_id: consumable.patient_id,
          doctor_note_id: consumable.doctor_note_id,
          nursing_consumable_id: consumable.id,
          created_by_id: created_by_id
        })
        |> Repo.insert()
    end
  end

  def prepare_payment_batch_for_doctor_note(doctor_note_id, created_by_id) do
    doctor_note = DoctorNotes.get_doctor_note!(doctor_note_id)

    Multi.new()
    |> Multi.run(:clear_pending_batches, fn repo, _changes ->
      pending_batch_ids =
        repo.all(
          from(batch in PatientChargeBatch,
            where: batch.doctor_note_id == ^doctor_note_id and batch.status == "pending",
            select: batch.id
          )
        )

      if pending_batch_ids != [] do
        repo.update_all(
          from(charge in PatientCharge,
            where: charge.patient_charge_batch_id in ^pending_batch_ids and is_nil(charge.paid_at)
          ),
          set: [patient_charge_batch_id: nil]
        )

        repo.delete_all(from(batch in PatientChargeBatch, where: batch.id in ^pending_batch_ids))
      end

      {:ok, pending_batch_ids}
    end)
    |> Multi.run(:charges, fn repo, _changes ->
      charges =
        repo.all(
          from(charge in PatientCharge,
            where:
              charge.doctor_note_id == ^doctor_note_id and
                charge.status == "approved" and
                is_nil(charge.paid_at),
            order_by: [asc: charge.inserted_at]
          )
        )

      if charges == [] do
        {:error, :no_approved_charges}
      else
        {:ok, charges}
      end
    end)
    |> Multi.insert(:batch, fn %{charges: charges} ->
      total_amount =
        Enum.reduce(charges, 0, fn charge, total -> total + (charge.total_price || 0) end)

      PatientChargeBatch.changeset(%PatientChargeBatch{}, %{
        doctor_note_id: doctor_note_id,
        patient_id: doctor_note.patient_id,
        created_by_id: created_by_id,
        total_amount: total_amount,
        status: "pending"
      })
    end)
    |> Multi.run(:attach_charges, fn repo, %{charges: charges, batch: batch} ->
      charge_ids = Enum.map(charges, & &1.id)

      repo.update_all(
        from(charge in PatientCharge, where: charge.id in ^charge_ids),
        set: [patient_charge_batch_id: batch.id]
      )

      {:ok, charge_ids}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{batch: batch}} -> {:ok, get_patient_charge_batch!(batch.id)}
      {:error, :charges, :no_approved_charges, _changes} -> {:error, :no_approved_charges}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  def mark_batch_paid(%PatientChargeBatch{} = batch) do
    paid_at = DateTime.utc_now() |> DateTime.truncate(:second)

    Multi.new()
    |> Multi.update(
      :batch,
      PatientChargeBatch.changeset(batch, %{status: "paid", paid_at: paid_at})
    )
    |> Multi.update_all(
      :charges,
      from(charge in PatientCharge,
        where: charge.patient_charge_batch_id == ^batch.id and charge.status == "approved"
      ),
      set: [status: "paid", paid_at: paid_at]
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{batch: updated_batch}} -> {:ok, get_patient_charge_batch!(updated_batch.id)}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  def charge_batch_service_label(%PatientChargeBatch{} = batch) do
    batch = Repo.preload(batch, [:patient_charges, :doctor_note])
    note_date = batch.doctor_note && batch.doctor_note.date
    item_count = length(batch.patient_charges || [])

    base =
      case item_count do
        1 -> "Emergency Nursing Charge"
        count -> "Emergency Nursing Charges (#{count} items)"
      end

    if note_date do
      "#{base} – #{Calendar.strftime(note_date, "%d %b %Y")}"
    else
      base
    end
  end

  defp patient_charge_preloads do
    [
      :patient,
      :doctor_note,
      :created_by,
      :approved_by,
      :waived_by,
      :patient_charge_batch,
      nursing_consumable: [
        :patient,
        :doctor_note,
        nursing_allocation: [inventory_issued: [:inventory_received, :batch]]
      ]
    ]
  end

  defp increment_count_for(summary, %{status: "pending_review"}) do
    Map.update!(summary, :pending_review_count, &(&1 + 1))
  end

  defp increment_count_for(summary, %{status: "approved", paid_at: nil}) do
    summary
    |> Map.update!(:approved_count, &(&1 + 1))
    |> Map.update!(:approved_unpaid_count, &(&1 + 1))
  end

  defp increment_count_for(summary, %{status: "approved"}) do
    Map.update!(summary, :approved_count, &(&1 + 1))
  end

  defp increment_count_for(summary, %{status: "paid"}) do
    Map.update!(summary, :paid_count, &(&1 + 1))
  end

  defp increment_count_for(summary, %{status: "waived"}) do
    Map.update!(summary, :waived_count, &(&1 + 1))
  end

  defp increment_count_for(summary, _charge), do: summary

  defp add_amount_for(summary, %{status: "approved", paid_at: nil, total_price: amount}) do
    Map.update!(summary, :approved_unpaid_total, &(&1 + (amount || 0)))
  end

  defp add_amount_for(summary, %{status: "paid", total_price: amount}) do
    Map.update!(summary, :paid_total, &(&1 + (amount || 0)))
  end

  defp add_amount_for(summary, _charge), do: summary

  defp charge_unit_price(consumable) do
    case consumable do
      %{nursing_allocation: %{inventory_issued: %{batch: %{price_per_unit: price_per_unit}}}}
      when is_integer(price_per_unit) ->
        price_per_unit

      _ ->
        0
    end
  end

  defp build_charge_description(consumable, item_details) do
    purpose =
      consumable.purpose
      |> to_string()
      |> String.trim()

    base = "Emergency nursing item: #{item_details.display_name}"

    if purpose == "" do
      base
    else
      "#{base} (#{purpose})"
    end
  end
end
