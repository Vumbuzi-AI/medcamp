defmodule Medcamp.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["pending", "in_progress", "completed"]
  @priorities ["low", "medium", "high"]

  schema "todos" do
    field :title, :string
    field :description, :string
    field :due_date, :date
    field :status, :string, default: "pending"
    field :priority, :string, default: "medium"
    field :assigned_to_name, :string

    belongs_to :created_by, Medcamp.Accounts.User, foreign_key: :created_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [
      :title,
      :description,
      :due_date,
      :status,
      :priority,
      :assigned_to_name,
      :created_by_id
    ])
    |> validate_required([:title, :created_by_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:priority, @priorities)
  end

  def statuses, do: @statuses
  def priorities, do: @priorities

  def status_label("pending"), do: "Pending"
  def status_label("in_progress"), do: "In Progress"
  def status_label("completed"), do: "Completed"
  def status_label(s), do: s

  def status_classes("pending"), do: "bg-yellow-100 text-yellow-800"
  def status_classes("in_progress"), do: "bg-blue-100 text-blue-800"
  def status_classes("completed"), do: "bg-green-100 text-green-800"
  def status_classes(_), do: "bg-gray-100 text-gray-800"

  def priority_classes("low"), do: "bg-gray-100 text-gray-700"
  def priority_classes("medium"), do: "bg-orange-100 text-orange-700"
  def priority_classes("high"), do: "bg-red-100 text-red-700"
  def priority_classes(_), do: "bg-gray-100 text-gray-700"

  def overdue?(%__MODULE__{due_date: nil}), do: false
  def overdue?(%__MODULE__{status: "completed"}), do: false

  def overdue?(%__MODULE__{due_date: due_date}) do
    Date.compare(due_date, Date.utc_today()) == :lt
  end
end
