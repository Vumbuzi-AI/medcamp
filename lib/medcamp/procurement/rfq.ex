defmodule Medcamp.Procurement.Rfq do
  use Ecto.Schema
  import Ecto.Changeset

  @priorities ~w(normal high urgent)
  @statuses ~w(draft sent closed cancelled)

  schema "rfqs" do
    field :reference, :string
    field :title, :string
    field :department, :string
    field :priority, :string, default: "normal"
    field :issue_date, :date
    field :quote_deadline, :date
    field :delivery_by, :date
    field :currency, :string, default: "KES"
    field :delivery_terms, :string
    field :payment_terms, :string
    field :special_instructions, :string
    field :status, :string, default: "draft"

    belongs_to :created_by, Medcamp.Accounts.User, foreign_key: :created_by_id

    has_many :items, Medcamp.Procurement.RfqItem
    has_many :invitations, Medcamp.Procurement.RfqInvitation
    has_many :quotes, Medcamp.Procurement.Quote

    timestamps(type: :utc_datetime)
  end

  def priorities, do: @priorities
  def statuses, do: @statuses

  def changeset(rfq, attrs) do
    rfq
    |> cast(attrs, [
      :reference,
      :title,
      :department,
      :priority,
      :issue_date,
      :quote_deadline,
      :delivery_by,
      :currency,
      :delivery_terms,
      :payment_terms,
      :special_instructions,
      :status,
      :created_by_id
    ])
    |> validate_required([:reference, :title, :quote_deadline, :status])
    |> validate_inclusion(:priority, @priorities)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:reference)
  end
end
