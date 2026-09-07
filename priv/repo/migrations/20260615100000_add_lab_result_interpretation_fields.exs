defmodule Medcamp.Repo.Migrations.AddLabResultInterpretationFields do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :interpretation_payload, :map, null: false, default: %{}
      add :interpretation_status, :string, null: false, default: "pending"
      add :interpretation_generated_at, :utc_datetime
    end
  end
end
