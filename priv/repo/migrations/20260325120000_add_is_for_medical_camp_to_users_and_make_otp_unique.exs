defmodule Medcamp.Repo.Migrations.AddIsForMedicalCampToUsersAndMakeOtpUnique do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto", ""

    alter table(:users) do
      add :is_for_medical_camp, :boolean, null: false, default: false
    end

    # Ensure every user has an OTP value before adding constraints/indexes.
    # (Also re-generates OTP for any potential duplicates.)
    execute """
    UPDATE users
    SET otp = gen_random_uuid()::text
    WHERE otp IS NULL OR otp = '';
    """

    execute """
    WITH dupe AS (
      SELECT id,
             ROW_NUMBER() OVER (PARTITION BY otp ORDER BY id) AS rn
      FROM users
      WHERE otp IS NOT NULL AND otp <> ''
    )
    UPDATE users u
    SET otp = gen_random_uuid()::text
    FROM dupe d
    WHERE u.id = d.id AND d.rn > 1;
    """

    alter table(:users) do
      modify :otp, :string, null: false
    end

    create unique_index(:users, [:otp])
  end
end
