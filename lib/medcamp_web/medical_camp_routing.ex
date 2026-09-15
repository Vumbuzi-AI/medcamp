defmodule MedcampWeb.MedicalCampRouting do
  @moduledoc """
  Where a camp staff member lands after scanning a patient wristband.

  Camp work happens on a phone, one patient at a time, so a scan should drop
  the user straight on the thing they are about to fill in rather than on a
  patient overview they then have to tap through:

    * nurse -> the new triage form
    * doctor -> the new doctor note form
    * lab technician -> the patient's latest lab result
    * pharmacist -> the patient's latest drug allocation

  Lab and pharmacy fall back to the patient's list page when there is nothing
  to open yet (scanned before the doctor ordered anything).
  """

  alias Medcamp.DrugAllocations
  alias Medcamp.LabResults

  def after_scan_path("nurse", patient), do: "/8018/#{patient.gsrn}/medical-camp/triages/new"

  def after_scan_path("doctor", patient),
    do: "/8018/#{patient.gsrn}/medical-camp/doctor_notes/new"

  def after_scan_path("labtechnician", patient) do
    case LabResults.most_recent_lab_result_for_patient(patient.id) do
      nil -> "/lab/#{patient.id}/lab_results"
      lab_result -> "/lab/lab_results/#{lab_result.id}"
    end
  end

  def after_scan_path("pharmacist", patient) do
    case DrugAllocations.most_recent_drug_allocation_for_a_patient(patient.id) do
      nil -> "/pharmacist/#{patient.id}/drug_allocations"
      drug_allocation -> "/pharmacist/drug_allocations/#{drug_allocation.id}"
    end
  end

  def after_scan_path(_role, patient), do: "/8018/#{patient.gsrn}/medical-camp"
end
