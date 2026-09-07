defmodule Medcamp.Suppliers.SupplierRecall do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(initiated in_progress completed cancelled)
  @severities ~w(low medium high critical)

  schema "supplier_recalls" do
    field :recall_number, :string
    field :recall_date, :date
    field :reason, :string
    field :description, :string
    field :affected_products, :string
    field :severity, :string, default: "medium"
    field :status, :string, default: "initiated"
    field :notes, :string
    belongs_to :supplier, Medcamp.Suppliers.Supplier

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def severities, do: @severities

  def status_label("initiated"), do: "Initiated"
  def status_label("in_progress"), do: "In Progress"
  def status_label("completed"), do: "Completed"
  def status_label("cancelled"), do: "Cancelled"
  def status_label(_), do: "Unknown"

  def status_color("initiated"), do: "bg-amber-100 text-amber-800"
  def status_color("in_progress"), do: "bg-blue-100 text-blue-800"
  def status_color("completed"), do: "bg-emerald-100 text-emerald-800"
  def status_color("cancelled"), do: "bg-gray-100 text-gray-800"
  def status_color(_), do: "bg-gray-100 text-gray-800"

  def severity_label("low"), do: "Low"
  def severity_label("medium"), do: "Medium"
  def severity_label("high"), do: "High"
  def severity_label("critical"), do: "Critical"
  def severity_label(_), do: "Unknown"

  def severity_color("low"), do: "bg-slate-100 text-slate-700"
  def severity_color("medium"), do: "bg-amber-100 text-amber-800"
  def severity_color("high"), do: "bg-orange-100 text-orange-800"
  def severity_color("critical"), do: "bg-rose-100 text-rose-800"
  def severity_color(_), do: "bg-gray-100 text-gray-800"

  @doc false
  def changeset(recall, attrs) do
    recall
    |> cast(attrs, [
      :recall_number,
      :recall_date,
      :reason,
      :description,
      :affected_products,
      :severity,
      :status,
      :notes,
      :supplier_id
    ])
    |> validate_required([:recall_number, :reason, :affected_products, :supplier_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:severity, @severities)
    |> foreign_key_constraint(:supplier_id)
  end
end
