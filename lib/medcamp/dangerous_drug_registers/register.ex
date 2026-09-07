defmodule Medcamp.DangerousDrugRegisters.Register do
  use Ecto.Schema
  import Ecto.Changeset

  schema "dangerous_drug_registers" do
    field :month, :integer
    field :year, :integer
    field :entries, :map, default: %{}
    field :last_entry_number, :integer, default: 0

    belongs_to :drug, Medcamp.Drugs.Drug
    belongs_to :created_by, Medcamp.Accounts.User, foreign_key: :created_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(register, attrs) do
    register
    |> cast(attrs, [:drug_id, :month, :year, :entries, :last_entry_number, :created_by_id])
    |> validate_required([:drug_id, :month, :year])
    |> validate_inclusion(:month, 1..12)
    |> validate_number(:year, greater_than: 2020, less_than: 2100)
    |> validate_number(:last_entry_number, greater_than_or_equal_to: 0)
    |> unique_constraint([:drug_id, :month, :year],
      name: :unique_dangerous_drug_register_per_month
    )
  end
end
