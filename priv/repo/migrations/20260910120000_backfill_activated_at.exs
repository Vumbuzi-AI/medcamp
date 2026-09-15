defmodule Medcamp.Repo.Migrations.BackfillActivatedAt do
  @moduledoc false

  use Ecto.Migration

  # `20260909110000_add_activated_at_to_users` backfilled `activated_at` only
  # `WHERE is_active = true`, so a user an admin had already *deactivated*
  # kept `activated_at = NULL` and `User.status/1` misreported them as
  # "pending" (invited, never set a password) instead of "inactive".
  #
  # A confirmed account has, by definition, established a password at least
  # once, so `confirmed_at` is the correct signal for "has been activated".
  def up do
    execute """
    UPDATE users
    SET activated_at = confirmed_at
    WHERE activated_at IS NULL AND confirmed_at IS NOT NULL
    """
  end

  def down, do: :ok
end
