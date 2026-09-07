defmodule Medcamp.Repo.Migrations.AddIsOtcToDrugs do
  use Ecto.Migration

  def change do
    alter table(:drugs) do
      add :is_otc, :boolean, default: false
    end
  end
end
