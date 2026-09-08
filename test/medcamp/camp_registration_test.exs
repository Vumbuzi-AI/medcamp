defmodule Medcamp.CampRegistrationTest do
  @moduledoc """
  The camp's defining rule: registering a patient is the same act as putting
  them in the queue, so a registration always produces a visit awaiting
  triage - and a rejected registration produces neither.
  """

  use Medcamp.DataCase, async: true

  import Medcamp.AccountsFixtures

  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Patients
  alias Medcamp.Patients.Patient

  defp valid_attrs do
    %{
      "first_name" => "Amina",
      "last_name" => "Wanjiru",
      "gender" => "female",
      "date_of_birth" => ~D[1990-04-11],
      "phone_number" => "0712345678",
      "home_address" => "Kibera"
    }
  end

  describe "register_for_camp/2" do
    setup do
      %{nurse: user_fixture(%{role: "nurse"})}
    end

    test "creates the patient and opens their visit awaiting triage", %{nurse: nurse} do
      assert {:ok, {%Patient{} = patient, %PatientVisit{} = visit}} =
               Patients.register_for_camp(valid_attrs(), nurse)

      assert patient.first_name == "Amina"
      assert visit.patient_id == patient.id
      assert visit.status == "triage_pending"
      assert visit.date == Date.utc_today()
    end

    test "records the registering nurse on both the patient and the visit", %{nurse: nurse} do
      {:ok, {patient, visit}} = Patients.register_for_camp(valid_attrs(), nurse)

      assert patient.creator_id == nurse.id
      assert visit.creator_id == nurse.id
    end

    test "the new visit shows up in the triage queue", %{nurse: nurse} do
      {:ok, {_patient, visit}} = Patients.register_for_camp(valid_attrs(), nurse)

      assert PatientVisits.list_queue("triage_pending")
             |> Enum.map(& &1.id)
             |> Enum.member?(visit.id)
    end

    test "assigns the patient a GSRN and a PIN", %{nurse: nurse} do
      {:ok, {patient, _visit}} = Patients.register_for_camp(valid_attrs(), nurse)

      assert is_binary(patient.gsrn)
      assert is_integer(patient.pin)
    end

    test "an invalid registration leaves behind neither patient nor visit", %{nurse: nurse} do
      patients_before = Repo.aggregate(Patient, :count)
      visits_before = Repo.aggregate(PatientVisit, :count)

      attrs = Map.put(valid_attrs(), "first_name", nil)

      assert {:error, %Ecto.Changeset{}} = Patients.register_for_camp(attrs, nurse)

      assert Repo.aggregate(Patient, :count) == patients_before
      assert Repo.aggregate(PatientVisit, :count) == visits_before
    end
  end
end
