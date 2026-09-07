defmodule MedcampWeb.DrugsGivenController do
  use MedcampWeb, :controller
  alias Medcamp.DrugsGiven
  alias Medcamp.Batches
  alias Medcamp.DataMatrixParser

  @doc """
  POST /api/drug_allocations/check_verify
  Body: %{"gtin" => "...", "batch" => "678"}
  Returns whether the given GTIN and batch have a pending allocation that can be verified,
  plus batch and allocation details (mirrors the "Scan to Verify" context on the show page).
  GTIN is padded with preceding zeros to 14 characters (API sends 14 chars total).
  """
  def check_verify(conn, %{"gtin" => gtin, "batch" => batch})
      when is_binary(gtin) and is_binary(batch) do
    batch_record = Batches.get_batch_by_gtin_14_and_batch_number(gtin, batch)

    if is_nil(batch_record) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        404,
        Jason.encode!(%{ok: false, error: "Batch not found for the given GTIN and batch number"})
      )
    else
      case DrugsGiven.find_drug_given_with_pending_allocation_for_batch_and_gtin(
             batch_record.id,
             gtin
           ) do
        {:error, :not_found} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            200,
            Jason.encode!(%{
              ok: true,
              can_verify: false,
              message: "No pending allocation found for this batch",
              batch: batch_info(batch_record)
            })
          )

        {:ok, drug_given, idx} ->
          allocation = Enum.at(drug_given.batch_allocations, idx)

          batch_record =
            case allocation do
              %{batch_id: allocation_batch_id} when allocation_batch_id != batch_record.id ->
                Batches.get_batch!(allocation_batch_id)

              _ ->
                batch_record
            end

          drug_given = Medcamp.Repo.preload(drug_given, [:drug, :drug_allocation, :pharmacist])

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            200,
            Jason.encode!(%{
              ok: true,
              can_verify: true,
              batch: batch_info(batch_record),
              drug_given_id: drug_given.id,
              drug_allocation_id: drug_given.drug_allocation_id,
              drug_name: drug_given.drug && drug_given.drug.brand_name,
              allocation:
                allocation &&
                  %{
                    quantity: allocation.quantity,
                    unit_price: allocation.unit_price,
                    is_verified: allocation.is_verified
                  }
            })
          )
      end
    end
  end

  def check_verify(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      400,
      Jason.encode!(%{
        ok: false,
        error: "Missing or invalid body: require \"gtin\" and \"batch\" (strings)"
      })
    )
  end

  @doc """
  POST /api/drug_allocations/scan_verify
  Body: %{"gtin" => "...", "batch" => "678"}  OR  %{"datamatrix" => "..."}
  Verifies the batch allocation for the given GTIN and batch (or parses datamatrix to get them).
  Same effect as "Verify Batch" on the drug allocation show page.
  """
  def scan_verify(conn, %{"datamatrix" => datamatrix})
      when is_binary(datamatrix) and datamatrix != "" do
    case DataMatrixParser.process_datamatrix(datamatrix) do
      {:ok, %{batch: batch, batch_number: batch_number}} ->
        gtin_val = batch.gtin || (batch.inventory_received && batch.inventory_received.gtin)
        do_scan_verify(conn, gtin_val, batch_number, batch.id)

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{ok: false, error: "Invalid datamatrix: #{reason}"}))
    end
  end

  def scan_verify(conn, %{"gtin" => gtin, "batch" => batch})
      when is_binary(gtin) and is_binary(batch) do
    batch_record = Batches.get_batch_by_gtin_14_and_batch_number(gtin, batch)

    if is_nil(batch_record) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        404,
        Jason.encode!(%{ok: false, error: "Batch not found for the given GTIN and batch number"})
      )
    else
      gtin_used =
        batch_record.gtin ||
          (batch_record.inventory_received && batch_record.inventory_received.gtin)

      do_scan_verify(conn, gtin_used, batch_record.batch, batch_record.id)
    end
  end

  def scan_verify(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      400,
      Jason.encode!(%{
        ok: false,
        error: "Missing body: provide \"gtin\" and \"batch\", or \"datamatrix\""
      })
    )
  end

  defp do_scan_verify(conn, gtin, _batch_number, batch_id) do
    case DrugsGiven.find_drug_given_with_pending_allocation_for_batch_and_gtin(batch_id, gtin) do
      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{ok: false, error: "No pending allocation found for this batch"})
        )

      {:ok, drug_given, idx} ->
        allocation = Enum.at(drug_given.batch_allocations, idx)
        allocation_batch_id = allocation && allocation.batch_id

        case DrugsGiven.verify_batch_allocation(drug_given.id, allocation_batch_id || batch_id) do
          {:ok, updated} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              200,
              Jason.encode!(%{
                ok: true,
                message: "Batch allocation verified successfully",
                drug_given_id: updated.id,
                drug_allocation_id: updated.drug_allocation_id
              })
            )

          {:error, _} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{ok: false, error: "Failed to update verification"}))
        end
    end
  end

  defp batch_info(batch) do
    batch = Medcamp.Repo.preload(batch, :inventory_received)

    %{
      id: batch.id,
      batch: batch.batch,
      gtin: batch.gtin || (batch.inventory_received && batch.inventory_received.gtin),
      expiry: batch.expiry
    }
  end

  def get_drugs_to_be_scanned(conn, %{"drug_given_id" => drug_given_id}) do
    drugs_given = Medcamp.DrugsGiven.list_drugs_given_for_sichi(drug_given_id)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{message: "Success", drugs_given: drugs_given}))
  end

  def scan_out_drug(conn, %{"drug_given_id" => drug_given_id, "batch" => batch}) do
    IO.inspect(drug_given_id, label: "Drug Given ID")

    drugs_given = Medcamp.DrugsGiven.list_drugs_given_for_sichi(drug_given_id)

    valid_batches =
      drugs_given
      |> Enum.flat_map(fn drug -> drug.batch_info end)
      |> Enum.map(& &1.batch)

    case find_batch_id(drugs_given, batch) do
      {:ok, id} ->
        scan_out_a_batch(drug_given_id, id)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{message: "Success", batch_scanned: batch}))

      {:error, :batch_not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            message: "Incorrect Batch Number: Valid batches are #{Enum.join(valid_batches, ", ")}"
          })
        )
    end
  end

  defp scan_out_a_batch(drug_given_id, batch_id) do
    drug_given = Medcamp.DrugsGiven.get_drug_given!(drug_given_id)

    updated_allocations =
      Enum.map(drug_given.batch_allocations, fn allocation ->
        # Match by batch_id
        if allocation.batch_id == batch_id do
          # Convert to map and update
          allocation
          |> Map.from_struct()
          |> Map.put(:is_verified, true)
        else
          allocation
          |> Map.from_struct()
        end
      end)

    # Use the proper changeset function from your context
    attrs = %{batch_allocations: updated_allocations}

    drug_given
    |> DrugsGiven.DrugGiven.changeset(attrs)
    |> Medcamp.Repo.update()
  end

  def find_batch_id(drug_given_list, batch_number) do
    drug_given_list
    |> Enum.flat_map(fn drug -> drug.batch_info end)
    |> Enum.find(fn batch_info -> batch_info.batch == batch_number end)
    |> case do
      nil -> {:error, :batch_not_found}
      batch_info -> {:ok, batch_info.id}
    end
  end
end
