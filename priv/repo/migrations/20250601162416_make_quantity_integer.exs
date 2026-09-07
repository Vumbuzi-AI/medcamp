defmodule Medcamp.Repo.Migrations.MakeQuantityInteger do
  use Ecto.Migration

  def up do
    # Add temporary column
    alter table(:batches) do
      add :quantity_temp, :integer, default: 0
    end

    # Migrate data safely
    execute """
    UPDATE batches
    SET quantity_temp = CASE
      WHEN quantity IS NULL THEN 0
      WHEN quantity ~ '^[0-9]+$' THEN quantity::integer
      ELSE 0
    END
    """

    # Drop old column and rename new one
    alter table(:batches) do
      remove :quantity
    end

    alter table(:batches) do
      add :quantity, :integer, default: 0
    end

    execute "UPDATE batches SET quantity = quantity_temp"

    alter table(:batches) do
      remove :quantity_temp
    end
  end

  def down do
    alter table(:batches) do
      modify :quantity, :string
    end
  end
end
