defmodule Medcamp.Repo.Migrations.AddRandomPinsToExistingPatients do
  use Ecto.Migration

  def up do
    # First, create a function to generate random 4-digit PIN
    execute """
    CREATE OR REPLACE FUNCTION generate_random_pin()
    RETURNS integer AS $$
    BEGIN
      RETURN floor(random() * 9000 + 1000)::integer;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Update all patients who have NULL pin values
    execute """
    UPDATE patients
    SET pin = generate_random_pin()
    WHERE pin IS NULL;
    """

    # Drop the function as we no longer need it
    execute "DROP FUNCTION generate_random_pin();"
  end

  def down do
    # No down migration needed for this specific action
    # If you want to revert, you could set pins back to NULL, but that's likely not desired
  end
end
