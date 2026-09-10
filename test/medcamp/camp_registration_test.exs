defmodule Medcamp.CampRegistrationTest do
  @moduledoc """
  The camp's defining rule: registering a patient is the same act as putting
  them in the queue, so a registration always produces a visit awaiting
  triage - and a rejected registration produces neither.
  """

  use Medcamp.DataCase, async: true

  import Medcamp.AccountsFixtures
  import Medcamp.CampsFixtures

  alias Medcamp.Camps.Scope
  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Patients
  alias Medcamp.Patients.Patient

  # Registration lands a patient on the active camp's roster, so every test
  # here needs one active (both in the DB and in this process).
  setup do
    camp = active_camp_fixture()
    Scope.put_active_camp_id(camp.id)
    %{camp: camp}
  end

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

    test "is refused, with nothing written, when no camp is active", %{nurse: nurse} do
      Scope.put_active_camp_id(nil)
      patients_before = Repo.aggregate(Patient, :count)
      visits_before = Repo.aggregate(PatientVisit, :count)

      assert {:error, :no_active_camp} = Patients.register_for_camp(valid_attrs(), nurse)

      assert Repo.aggregate(Patient, :count) == patients_before
      assert Repo.aggregate(PatientVisit, :count) == visits_before
    end
  end

  describe "receptionist registration" do
    test "a receptionist can register a patient and open the triage visit" do
      receptionist = user_fixture(%{role: "receptionist"})

      assert {:ok, {patient, visit}} =
               Patients.register_for_camp(valid_attrs(), receptionist)

      assert patient.creator_id == receptionist.id
      assert visit.patient_id == patient.id
      assert visit.creator_id == receptionist.id
      assert visit.status == "triage_pending"
    end
  end
end
