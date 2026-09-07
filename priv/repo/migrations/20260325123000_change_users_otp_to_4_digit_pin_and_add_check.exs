defmodule Medcamp.Repo.Migrations.ChangeUsersOtpTo4DigitPinAndAddCheck do
  use Ecto.Migration

  def change do
    # Ensure we can generate unique 4-digit PINs for all users.
    execute """
    DO $$
    BEGIN
      IF (SELECT COUNT(*) FROM users) > 10000 THEN
        RAISE EXCEPTION 'Cannot generate unique 4-digit OTP pins for more than 10000 users';
      END IF;
    END $$;
    """

    # Re-backfill `otp` as a 4-digit numeric string (leading zeros allowed).
    execute """
    WITH numbered AS (
      SELECT id, row_number() OVER (ORDER BY id) - 1 AS rn
      FROM users
    )
    UPDATE users u
    SET otp = lpad((numbered.rn % 10000)::text, 4, '0')
    FROM numbered
    WHERE u.id = numbered.id;
    """

    execute """
    ALTER TABLE users
    ADD CONSTRAINT users_otp_four_digit_pin_check
    CHECK (otp ~ '^[0-9]{4}$');
    """
  end
end
