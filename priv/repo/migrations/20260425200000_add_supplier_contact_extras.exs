defmodule Medcamp.Repo.Migrations.AddSupplierContactExtras do
  use Ecto.Migration

  def change do
    alter table(:suppliers) do
      add :contact_designation, :string
      add :alternate_contact_name, :string
      add :alternate_contact_email, :string
      add :alternate_contact_telephone, :string
    end
  end
end
