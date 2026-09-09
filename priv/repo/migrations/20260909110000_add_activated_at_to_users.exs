defmodule Medcamp.Repo.Migrations.AddActivatedAtToUsers do
  use Ecto.Migration

  # Distinguishes an invited account that has never set a password ("Pending")
  # from one an admin explicitly deactivated ("Inactive"). Set the first time
  # a password is established; existing active users are treated as activated.
  def up do
    alter table(:users) do
      add :activated_at, :utc_datetime
    end

    execute """
    UPDATE users SET activated_at = COALESCE(confirmed_at, inserted_at)
    WHERE is_active = true
    """
  end

  def down do
    alter table(:users) do
      remove :activated_at
    end
  end
end
