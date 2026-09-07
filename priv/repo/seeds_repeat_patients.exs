# priv/repo/seeds_repeat_patients.exs
#
# Seeds a handful of patients specifically to exercise
# Medcamp.PatientVisits.count_repeat_patients/0 and the "Returning Patients"
# dashboard card.
#
# NOTE: this always inserts fresh patients — running it twice will double
# the counts. If you need a clean slate, run `mix ecto.reset` first, or
# just accept that count_repeat_patients() grows by a fixed number
# (currently 2) each time you run this.
#
# Run with: mix run priv/repo/seeds_repeat_patients.exs

alias Medcamp.Accounts
alias Medcamp.Patients
alias Medcamp.PatientVisits

creator =
  case Accounts.list_users() do
    [user | _] ->
      user

    [] ->
      raise """
      No users found — create at least one user (e.g. via mix run priv/repo/seeds.exs,
      or through the app's signup) before running this seed script, since patients
      require a creator_id.
      """
  end

patients_fixture = [
  {"Wanjiru Kamau", "0711000001", :repeat_3_paid},
  {"Otieno Odhiambo", "0711000002", :repeat_2_paid_boundary},
  {"Achieng Njoroge", "0711000003", :not_repeat_1_paid},
  {"Mutiso Kilonzo", "0711000004", :not_repeat_2_visits_1_paid},
  {"Nafula Wekesa", "0711000005", :not_repeat_0_visits},
  {"Chebet Rono", "0711000006", :repeat_2_paid_boundary},
  {"Kiptoo Langat", "0711000007", :repeat_4_paid},
  {"Auma Ochieng", "0711000008", :repeat_2_paid_boundary},
  {"Mwangi Karanja", "0711000009", :repeat_5_paid},
  {"Adhiambo Owino", "0711000010", :repeat_2_paid_boundary},
  {"Kiplagat Cherono", "0711000011", :not_repeat_1_paid},
  {"Nyambura Gitau", "0711000012", :not_repeat_0_visits},
  {"Barasa Simiyu", "0711000013", :not_repeat_2_visits_1_paid},
  {"Waititu Ndungu", "0711000014", :not_repeat_1_paid},
  {"Cherotich Kiprono", "0711000015", :not_repeat_2_visits_0_paid}
]
create_patient = fn name, phone ->
  [first_name, last_name] = String.split(name, " ", parts: 2)

  case Patients.create_patient(%{
         first_name: first_name,
         last_name: last_name,
         phone_number: phone,
         date_of_birth: ~D[1992-06-15],
         gender: "female",
         home_address: "Nairobi",
         creator_id: creator.id
       }) do
    {:ok, patient} ->
      patient

    {:error, changeset} ->
      raise "Failed to create patient #{name}: #{inspect(changeset.errors)}"
  end
end

add_visit = fn patient, has_paid, days_ago ->
  inserted_at =
    DateTime.utc_now()
    |> DateTime.add(-days_ago * 24 * 3600, :second)
    |> DateTime.truncate(:second)

  case PatientVisits.create_patient_visit(%{
         "patient_id" => patient.id,
         "has_paid" => has_paid,
         "visit_type" => "General",
         "payment_type" => if(has_paid, do: "M-Pesa", else: "Pending"),
         "creator_id" => creator.id,
         "inserted_at" => inserted_at
       }) do
    {:ok, visit} ->
      visit

    {:error, changeset} ->
      raise "Failed to create visit for patient #{patient.id}: #{inspect(changeset.errors)}"
  end
end
Enum.each(patients_fixture, fn {name, phone, scenario} ->
  patient = create_patient.(name, phone)

  case scenario do
    :repeat_2_paid_boundary ->
      add_visit.(patient, true, 20)
      add_visit.(patient, true, 5)

    :repeat_3_paid ->
      add_visit.(patient, true, 30)
      add_visit.(patient, true, 15)
      add_visit.(patient, true, 1)

    :repeat_4_paid ->
      add_visit.(patient, true, 60)
      add_visit.(patient, true, 40)
      add_visit.(patient, true, 20)
      add_visit.(patient, true, 3)

    :repeat_5_paid ->
      add_visit.(patient, true, 90)
      add_visit.(patient, true, 70)
      add_visit.(patient, true, 45)
      add_visit.(patient, true, 10)
      add_visit.(patient, true, 2)

    :not_repeat_1_paid ->
      add_visit.(patient, true, 10)

    :not_repeat_2_visits_1_paid ->
      add_visit.(patient, true, 12)
      add_visit.(patient, false, 3)

    :not_repeat_2_visits_0_paid ->
      add_visit.(patient, false, 14)
      add_visit.(patient, false, 4)

    :not_repeat_0_visits ->
      :ok
  end

  IO.puts("Seeded #{name} — scenario: #{scenario}")
end)

IO.puts("\nExpect count_repeat_patients() to have gone up by 7")
IO.puts("(3 x repeat_2_paid_boundary + repeat_3_paid + repeat_4_paid + repeat_5_paid + 1 more repeat_2_paid_boundary = 7 repeat patients)")
