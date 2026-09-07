defmodule Medcamp.Repo.Migrations.BackfillRequisitionRequestedAt do
  use Ecto.Migration

  def up do
    execute("""
    UPDATE requisitions
    SET requested_at = inserted_at
    WHERE requested_at IS NULL
    """)
  end

  def down do
    :ok
  end
end
