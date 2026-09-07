# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds/subsidized_payments.exs
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Medcamp.Repo.insert!(%Medcamp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Medcamp.Repo
alias Medcamp.SubsidizedProcedures.SubsidizedProcedure

# Subsidized procedures (pricing strategy - last column / Column D prices)
subsidized_procedures = [
  {"Circumcision", 2250},
  {"MVA", 5500},
  {"I & D (local)", 1500},
  {"I & D (sedation)", 3500},
  {"Exploration (foreign body)", 2000},
  {"Foreign Body Removal", 1250},
  {"Foreign Body Removal under Sedation", 3500},
  {"Keloid Removal-Simple", 1250},
  {"Keloid Removal-Complicated", 2500},
  {"Keloid Removal-Sedation", 3500},
  {"Umblical Polyps", 1250},
  {"Wound Dressing-Simple", 200},
  {"Wound Dressing-Medium", 350},
  {"Wound Dressing-Large", 650},
  {"Injection", 125},
  {"Couselling", 250},
  {"Filling Forms", 500},
  {"Oxygen Therapy Per Hour", 350},
  {"Sunction Per Session", 275},
  {"Nebulization Per Solution", 1500},
  {"Application of Split", 1000},
  {"Armsling", 350},
  {"Stitching Per Suture", 550},
  {"Stitch Removal-Simple", 500},
  {"Stitch Removal-Complicated", 650},
  {"Delivery-Normal", 9000},
  {"Delivery-Difficult", 12500},
  {"Delivery-Senior Medcamp", 22500},
  {"Secondary Repair", 10500},
  {"FP-Implant Insertion", 850},
  {"FP-Implant Removal", 1150},
  {"FP-IUCD Insertion", 800},
  {"FP-IUCD Removal", 800},
  {"Vaginal Examination", 350},
  {"Servical Cancer Screening", 1000},
  {"Parectal Examination", 200},
  {"Cathertization", 600},
  {"Shaving", 150},
  {"Observation", 1000}
]

alias Medcamp.SubsidizedProcedures

for {name, price} <- subsidized_procedures do
  case Repo.get_by(SubsidizedProcedure, name: name) do
    nil ->
      %SubsidizedProcedure{}
      |> SubsidizedProcedure.changeset(%{name: name, price: price, description: ""})
      |> Repo.insert!()

    existing ->
      {:ok, _} = SubsidizedProcedures.update_subsidized_procedure(existing, %{price: price})
  end
end

IO.puts("✓ Subsidized procedures seeded (#{length(subsidized_procedures)} records)")
