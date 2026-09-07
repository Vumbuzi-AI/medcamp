defmodule Medcamp.Repo.Migrations.InsuranceCompany do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      add :insurance_company, :string
    end
  end
end
