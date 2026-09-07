defmodule Medcamp.DangerousDrugRegisters do
  @moduledoc """
  Context for per-drug dangerous drug registers.
  """

  import Ecto.Query, warn: false

  alias Medcamp.DangerousDrugRegisters.Register
  alias Medcamp.Repo

  def get_register!(id) do
    Register
    |> Repo.get!(id)
    |> preload_register()
    |> normalize_register()
  end

  def get_register_by_drug_month_year(drug_id, month, year) do
    Register
    |> Repo.get_by(drug_id: drug_id, month: month, year: year)
    |> case do
      nil ->
        nil

      register ->
        register
        |> preload_register()
        |> normalize_register()
    end
  end

  def ensure_register(drug_id, month, year, user_id) do
    case get_register_by_drug_month_year(drug_id, month, year) do
      nil ->
        create_register(%{
          drug_id: drug_id,
          month: month,
          year: year,
          created_by_id: user_id,
          entries: %{"1" => empty_entry()},
          last_entry_number: 1
        })
        |> case do
          {:ok, register} ->
            {:ok, get_register!(register.id)}

          {:error, %Ecto.Changeset{} = changeset} ->
            case get_register_by_drug_month_year(drug_id, month, year) do
              nil -> {:error, changeset}
              register -> {:ok, register}
            end
        end

      register ->
        {:ok, register}
    end
  end

  def create_register(attrs \\ %{}) do
    %Register{}
    |> Register.changeset(attrs)
    |> Repo.insert()
  end

  def update_register(%Register{} = register, attrs) do
    register
    |> Register.changeset(attrs)
    |> Repo.update()
  end

  def add_entry(%Register{} = register) do
    next_entry_number = (register.last_entry_number || 0) + 1

    updated_entries =
      Map.put(register.entries || %{}, Integer.to_string(next_entry_number), empty_entry())

    update_register(register, %{
      entries: updated_entries,
      last_entry_number: next_entry_number
    })
  end

  def remove_entry(%Register{} = register, entry_id) do
    updated_entries = Map.delete(register.entries || %{}, to_string(entry_id))
    update_register(register, %{entries: updated_entries})
  end

  def update_entry(%Register{} = register, entry_id, field, value) do
    entry_id = to_string(entry_id)
    entries = register.entries || %{}
    entry = Map.get(entries, entry_id, empty_entry())
    updated_entries = Map.put(entries, entry_id, Map.put(entry, field, value))

    update_register(register, %{entries: updated_entries})
  end

  def list_entries(%Register{} = register) do
    register.entries
    |> Kernel.||(%{})
    |> Enum.sort_by(fn {entry_id, _entry} -> String.to_integer(entry_id) end)
    |> Enum.map(fn {entry_id, entry} -> {entry_id, entry || %{}} end)
  end

  def opening_balance(%Register{} = register) do
    case previous_register(register) do
      nil -> 0.0
      previous_register -> closing_balance(previous_register)
    end
  end

  def closing_balance(%Register{} = register) do
    entry_rows(register)
    |> List.last()
    |> case do
      nil -> opening_balance(register)
      row -> row.running_balance
    end
  end

  def entry_rows(%Register{} = register) do
    initial_balance = opening_balance(register)

    {rows, _balance} =
      register
      |> list_entries()
      |> Enum.reduce({[], initial_balance}, fn {entry_id, entry}, {rows, balance} ->
        received = quantity_value(Map.get(entry, "quantity_received"))
        dispensed = quantity_value(Map.get(entry, "quantity_dispensed"))
        running_balance = balance + received - dispensed

        row = %{
          id: entry_id,
          entry: entry,
          running_balance: running_balance
        }

        {[row | rows], running_balance}
      end)

    Enum.reverse(rows)
  end

  def empty_entry do
    %{
      "date" => "",
      "time" => "",
      "prescription_number" => "",
      "patient_name" => "",
      "patient_file_number" => "",
      "strength_form" => "",
      "batch_number" => "",
      "quantity_received" => "",
      "quantity_dispensed" => "",
      "prescriber" => "",
      "pharmacist" => "",
      "remarks" => ""
    }
  end

  def quantity_value(value) when value in [nil, ""], do: 0.0
  def quantity_value(value) when is_integer(value), do: value * 1.0
  def quantity_value(value) when is_float(value), do: value

  def quantity_value(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" ->
        0.0

      trimmed ->
        case Float.parse(trimmed) do
          {number, _rest} -> number
          :error -> 0.0
        end
    end
  end

  defp previous_register(%Register{} = register) do
    Register
    |> where([r], r.drug_id == ^register.drug_id)
    |> where(
      [r],
      r.year < ^register.year or (r.year == ^register.year and r.month < ^register.month)
    )
    |> order_by([r], desc: r.year, desc: r.month)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> nil
      previous_register -> normalize_register(previous_register)
    end
  end

  defp preload_register(%Register{} = register) do
    Repo.preload(register, [:created_by, drug: [:inventory_received, drug_batches: :batch]])
  end

  defp normalize_register(%Register{} = register) do
    %{register | entries: register.entries || %{}}
  end
end
