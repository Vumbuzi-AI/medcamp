defmodule Medcamp.Repo.Migrations.AddManagement do
  use Ecto.Migration

  def change do
    alter table(:doctor_notes) do
      add :management, :text
    end
  end
end
