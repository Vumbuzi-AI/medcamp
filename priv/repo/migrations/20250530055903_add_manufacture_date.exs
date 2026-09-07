defmodule Medcamp.Repo.Migrations.AddManufactureDate do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :manufacture_date, :date
    end
  end
end
