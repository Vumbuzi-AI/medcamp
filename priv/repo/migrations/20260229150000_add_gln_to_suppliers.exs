defmodule Medcamp.Repo.Migrations.AddGlnToSuppliers do
  use Ecto.Migration

  def change do
    alter table(:suppliers) do
      add :gln, :string
    end
  end
end
