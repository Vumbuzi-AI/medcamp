defmodule Medcamp.Repo.Migrations.CreatePatients do
  use Ecto.Migration

  def change do
    create table(:patients) do
      add :first_name, :string
      add :middle_name, :string
      add :last_name, :string
      add :national_id, :string
      add :email, :string
      add :phone_number, :string
      add :date_of_birth, :date
      add :gender, :string
      add :insurance_scheme, :string
      add :insurance_number, :string
      add :insurance_cover_limit, :integer
      add :has_insurance, :boolean, default: false
      add :emergency_contact_name, :string
      add :emergency_contact_phone_number, :string
      add :home_address, :string
      add :consent_agreement, :boolean, default: false
      add :emergency_contact_relationship, :string
      add :creator_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:patients, [:creator_id])
  end
end
