defmodule Medcamp.Repo.Migrations.AddIdentityDocumentsToPatients do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      add :birth_certificate_number, :string
      add :national_id_document, :string
      add :birth_certificate_document, :string
    end
  end
end
