defmodule Medcamp.SOPs.SOP do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sops" do
    field :name, :string
    field :description, :string
    field :valid_for_days, :integer
    field :pdf_path, :string
    field :original_filename, :string

    belongs_to :department, Medcamp.Departments.Department
    belongs_to :added_by, Medcamp.Accounts.User, foreign_key: :added_by_id

    timestamps(type: :utc_datetime)
  end

  @required_fields [
    :name,
    :description,
    :valid_for_days,
    :pdf_path,
    :original_filename,
    :department_id,
    :added_by_id
  ]

  def changeset(sop, attrs) do
    sop
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 2, max: 160)
    |> validate_length(:description, min: 3, max: 2_000)
    |> validate_number(:valid_for_days,
      greater_than: 0,
      less_than_or_equal_to: 3650,
      message: "must be between 1 and 3650 days"
    )
    |> validate_format(:pdf_path, ~r/^\/uploads\/.+\.pdf$/i,
      message: "must point to an uploaded PDF"
    )
    |> validate_length(:original_filename, min: 1, max: 255)
    |> foreign_key_constraint(:department_id)
    |> foreign_key_constraint(:added_by_id)
  end
end
