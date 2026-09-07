# =============================================================================
# INPATIENT CONTEXT
# File: lib/medcamp/inpatient.ex
# =============================================================================

defmodule Medcamp.Inpatient do
  @moduledoc """
  The Inpatient context - handles all inpatient-related operations.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Inpatient.{
    AdmissionNote,
    ContinuationNote,
    TreatmentSheet,
    VitalRecord,
    DischargeSummary
  }

  # ---------------------------------------------------------------------------
  # ADMISSION NOTES
  # ---------------------------------------------------------------------------

  def list_admission_notes do
    AdmissionNote
    |> preload([:patient, :doctor, :doctor_note])
    |> order_by(desc: :admission_date, desc: :admission_time)
    |> Repo.all()
  end

  def list_admission_notes_for_patient(patient_id) do
    AdmissionNote
    |> where([a], a.patient_id == ^patient_id)
    |> preload([:doctor, :doctor_note])
    |> order_by(desc: :admission_date, desc: :admission_time)
    |> Repo.all()
  end

  def get_admission_note!(id) do
    AdmissionNote
    |> preload([
      :patient,
      :doctor,
      :doctor_note,
      :continuation_notes,
      :treatment_sheets,
      :vital_records,
      :discharge_summary
    ])
    |> Repo.get!(id)
  end

  def create_admission_note(attrs \\ %{}) do
    %AdmissionNote{}
    |> AdmissionNote.changeset(attrs)
    |> Repo.insert()
  end

  def update_admission_note(%AdmissionNote{} = admission_note, attrs) do
    admission_note
    |> AdmissionNote.changeset(attrs)
    |> Repo.update()
  end

  def delete_admission_note(%AdmissionNote{} = admission_note) do
    Repo.delete(admission_note)
  end

  def change_admission_note(%AdmissionNote{} = admission_note, attrs \\ %{}) do
    AdmissionNote.changeset(admission_note, attrs)
  end

  # Check if patient is currently admitted (no discharge)
  def patient_currently_admitted?(patient_id) do
    AdmissionNote
    |> where([a], a.patient_id == ^patient_id)
    |> join(:left, [a], d in DischargeSummary, on: d.admission_note_id == a.id)
    |> where([a, d], is_nil(d.id))
    |> Repo.exists?()
  end

  def get_current_admission(patient_id) do
    AdmissionNote
    |> where([a], a.patient_id == ^patient_id)
    |> join(:left, [a], d in DischargeSummary, on: d.admission_note_id == a.id)
    |> where([a, d], is_nil(d.id))
    |> order_by(desc: :admission_date, desc: :admission_time)
    |> limit(1)
    |> preload([:patient, :doctor])
    |> Repo.one()
  end

  # ---------------------------------------------------------------------------
  # CONTINUATION NOTES
  # ---------------------------------------------------------------------------

  def list_continuation_notes_for_admission(admission_note_id) do
    ContinuationNote
    |> where([c], c.admission_note_id == ^admission_note_id)
    |> preload([:doctor])
    |> order_by(desc: :review_date, desc: :review_time)
    |> Repo.all()
  end

  def get_continuation_note!(id) do
    ContinuationNote
    |> preload([:admission_note, :doctor])
    |> Repo.get!(id)
  end

  def create_continuation_note(attrs \\ %{}) do
    %ContinuationNote{}
    |> ContinuationNote.changeset(attrs)
    |> Repo.insert()
  end

  def update_continuation_note(%ContinuationNote{} = continuation_note, attrs) do
    continuation_note
    |> ContinuationNote.changeset(attrs)
    |> Repo.update()
  end

  def delete_continuation_note(%ContinuationNote{} = continuation_note) do
    Repo.delete(continuation_note)
  end

  def change_continuation_note(%ContinuationNote{} = continuation_note, attrs \\ %{}) do
    ContinuationNote.changeset(continuation_note, attrs)
  end

  # ---------------------------------------------------------------------------
  # TREATMENT SHEETS
  # ---------------------------------------------------------------------------

  def list_treatment_sheets_for_admission(admission_note_id) do
    TreatmentSheet
    |> where([t], t.admission_note_id == ^admission_note_id)
    |> preload([:prescriber])
    |> order_by(desc: :prescription_date, desc: :prescription_time)
    |> Repo.all()
  end

  def get_treatment_sheet!(id) do
    TreatmentSheet
    |> preload([:admission_note, :prescriber])
    |> Repo.get!(id)
  end

  def create_treatment_sheet(attrs \\ %{}) do
    %TreatmentSheet{}
    |> TreatmentSheet.changeset(attrs)
    |> Repo.insert()
  end

  def update_treatment_sheet(%TreatmentSheet{} = treatment_sheet, attrs) do
    treatment_sheet
    |> TreatmentSheet.changeset(attrs)
    |> Repo.update()
  end

  def delete_treatment_sheet(%TreatmentSheet{} = treatment_sheet) do
    Repo.delete(treatment_sheet)
  end

  def change_treatment_sheet(%TreatmentSheet{} = treatment_sheet, attrs \\ %{}) do
    TreatmentSheet.changeset(treatment_sheet, attrs)
  end

  # Record medication administration
  def record_administration(treatment_sheet_id, admin_attrs) do
    treatment_sheet = get_treatment_sheet!(treatment_sheet_id)
    current_administrations = treatment_sheet.administrations || []

    new_admin = %{
      id: Ecto.UUID.generate(),
      administered_date: admin_attrs["administered_date"] || Date.utc_today(),
      administered_time: admin_attrs["administered_time"] || Time.utc_now(),
      administered_by_id: admin_attrs["administered_by_id"],
      administered_by_name: admin_attrs["administered_by_name"],
      notes: admin_attrs["notes"]
    }

    update_treatment_sheet(treatment_sheet, %{
      administrations: current_administrations ++ [new_admin]
    })
  end

  # ---------------------------------------------------------------------------
  # VITAL RECORDS
  # ---------------------------------------------------------------------------

  def list_vital_records_for_admission(admission_note_id) do
    VitalRecord
    |> where([v], v.admission_note_id == ^admission_note_id)
    |> preload([:recorded_by])
    |> order_by(desc: :recorded_date, desc: :recorded_time)
    |> Repo.all()
  end

  def get_vital_record!(id) do
    VitalRecord
    |> preload([:admission_note, :recorded_by])
    |> Repo.get!(id)
  end

  def create_vital_record(attrs \\ %{}) do
    %VitalRecord{}
    |> VitalRecord.changeset(attrs)
    |> Repo.insert()
  end

  def update_vital_record(%VitalRecord{} = vital_record, attrs) do
    vital_record
    |> VitalRecord.changeset(attrs)
    |> Repo.update()
  end

  def delete_vital_record(%VitalRecord{} = vital_record) do
    Repo.delete(vital_record)
  end

  def change_vital_record(%VitalRecord{} = vital_record, attrs \\ %{}) do
    VitalRecord.changeset(vital_record, attrs)
  end

  # ---------------------------------------------------------------------------
  # DISCHARGE SUMMARIES
  # ---------------------------------------------------------------------------

  def get_discharge_summary_for_admission(admission_note_id) do
    DischargeSummary
    |> where([d], d.admission_note_id == ^admission_note_id)
    |> preload([:doctor])
    |> Repo.one()
  end

  def get_discharge_summary!(id) do
    DischargeSummary
    |> preload([:admission_note, :doctor])
    |> Repo.get!(id)
  end

  def create_discharge_summary(attrs \\ %{}) do
    %DischargeSummary{}
    |> DischargeSummary.changeset(attrs)
    |> Repo.insert()
  end

  def update_discharge_summary(%DischargeSummary{} = discharge_summary, attrs) do
    discharge_summary
    |> DischargeSummary.changeset(attrs)
    |> Repo.update()
  end

  def delete_discharge_summary(%DischargeSummary{} = discharge_summary) do
    Repo.delete(discharge_summary)
  end

  def change_discharge_summary(%DischargeSummary{} = discharge_summary, attrs \\ %{}) do
    DischargeSummary.changeset(discharge_summary, attrs)
  end
end
