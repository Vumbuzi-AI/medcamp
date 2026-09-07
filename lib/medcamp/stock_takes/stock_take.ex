defmodule Medcamp.StockTakes.StockTake do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stock_takes" do
    field :date, :date
    field :notes, :string
    field :status, :string, default: "draft"
    field :approved_at, :utc_datetime

    belongs_to :admin, Medcamp.Accounts.User, foreign_key: :admin_id
    belongs_to :requested_by, Medcamp.Accounts.User
    belongs_to :approved_by, Medcamp.Accounts.User
    belongs_to :department, Medcamp.Departments.Department
    has_many :entries, Medcamp.StockTakes.StockTakeEntry, foreign_key: :stock_take_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(stock_take, attrs) do
    stock_take
    |> cast(attrs, [
      :date,
      :notes,
      :status,
      :admin_id,
      :requested_by_id,
      :approved_by_id,
      :approved_at,
      :department_id
    ])
    |> validate_required([:date, :department_id])
    |> validate_owner_present()
    |> validate_inclusion(:status, ["draft", "pending", "approved", "rejected", "completed"])
    |> put_date_if_missing()
  end

  # A stock take belongs to either an admin who conducts it directly or a
  # requester who raises it for approval. At least one must be set.
  defp validate_owner_present(changeset) do
    if get_field(changeset, :admin_id) || get_field(changeset, :requested_by_id) do
      changeset
    else
      add_error(changeset, :admin_id, "or requested_by is required")
    end
  end

  defp put_date_if_missing(changeset) do
    if get_field(changeset, :date) do
      changeset
    else
      local_date =
        DateTime.utc_now()
        |> DateTime.add(3 * 60 * 60)
        |> DateTime.to_date()

      put_change(changeset, :date, local_date)
    end
  end
end
