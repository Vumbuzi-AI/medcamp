defmodule Medcamp.Repo.Migrations.BackfillCampAttendances do
  use Ecto.Migration

  # Every camp visit already on file implies an attendance. Seed one row per
  # (patient, camp) from the earliest such visit. Forward-only.
  def up do
    execute("""
    INSERT INTO camp_attendances
      (patient_id, camp_id, organisation_id, first_seen_at, inserted_at, updated_at)
    SELECT
      pv.patient_id,
      pv.camp_id,
      pv.organisation_id,
      MIN(pv.inserted_at),
      NOW(),
      NOW()
    FROM patient_visits pv
    WHERE pv.camp_id IS NOT NULL
    GROUP BY pv.patient_id, pv.camp_id, pv.organisation_id
    ON CONFLICT (patient_id, camp_id) DO NOTHING
    """)
  end

  def down, do: :ok
end
