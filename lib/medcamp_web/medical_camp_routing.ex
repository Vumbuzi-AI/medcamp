defmodule MedcampWeb.MedicalCampRouting do
  @moduledoc """
  Where a camp staff member lands after scanning a patient wristband.

  Camp work happens on a phone, one patient at a time, so a scan should drop
  the user straight on the thing they are about to fill in rather than on a
  patient overview they then have to tap through:

    * nurse -> the new triage form
    * doctor -> the new doctor note form
    * lab technician -> every lab request raised for the patient
    * pharmacist -> every drug allocation raised for the patient

  Lab and pharmacy land on the patient's full list rather than a single
  record: a patient can arrive at the bench with more than one request open,
  and the technician needs to pick the one they are about to work on.
  """

  def after_scan_path("nurse", patient), do: "/8018/#{patient.gsrn}/medical-camp/triages/new"

  def after_scan_path("doctor", patient),
    do: "/8018/#{patient.gsrn}/medical-camp/doctor_notes/new"

  def after_scan_path("labtechnician", patient), do: "/lab/#{patient.id}/lab_results"

  def after_scan_path("pharmacist", patient), do: "/pharmacist/#{patient.id}/drug_allocations"

  def after_scan_path(_role, patient), do: "/8018/#{patient.gsrn}/medical-camp"
end
