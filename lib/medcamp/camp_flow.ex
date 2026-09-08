defmodule Medcamp.CampFlow do
  @moduledoc """
  Advances a patient's visit as they move through the camp.

  Each clinical context calls in here after recording its own work, rather
  than every LiveView remembering to bump a status: triage advances the
  visit, a doctor note picks it up, a lab request or a prescription sends it
  to that queue. The role queues then read the status back
  (`Medcamp.PatientVisits.list_queue/2`), so a step that is recorded is a
  step the next role can see.

  Advancing is best-effort and never blocks the clinical record: if a patient
  somehow has no open visit for today, the note or result is still saved and
  the visit simply is not moved. Losing a doctor's note because a queue
  marker could not be written would be the worse failure.
  """

  require Logger

  alias Medcamp.PatientVisits

  @doc """
  Moves the patient's open visit for today to `status`.

  Returns the untouched `result` it was given, so it can be dropped into a
  create pipeline without changing what the caller sees.
  """
  def advance(result, status)

  def advance({:ok, %{patient_id: patient_id}} = result, status) when is_integer(patient_id) do
    case PatientVisits.current_visit_for_patient(patient_id) do
      nil ->
        Logger.debug("no open visit for patient #{patient_id}; not advancing to #{status}")

      visit ->
        PatientVisits.update_status(visit, status)
    end

    result
  end

  def advance(result, _status), do: result
end
