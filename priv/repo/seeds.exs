# Seeds a medical camp with one login per role plus a superadmin, a lab test
# catalogue, a stocked pharmacy and a full roster of patients with visits, so a
# fresh database is immediately usable.
#
#     mix run priv/repo/seeds.exs
#
# Idempotent: re-running updates the seeded records rather than duplicating
# them. Every account uses the same demo password - change or remove these
# before running a real camp.

import Ecto.Query, only: [from: 2]

alias Medcamp.Accounts
alias Medcamp.Accounts.User
alias Medcamp.Camps
alias Medcamp.Camps.Scope
alias Medcamp.DrugBatches
alias Medcamp.DrugAllocations.DrugAllocation
alias Medcamp.Drugs
alias Medcamp.Drugs.Drug
alias Medcamp.DrugsGiven.DrugGiven
alias Medcamp.DoctorNotes.DoctorNote
alias Medcamp.InventoriesReceived
alias Medcamp.InventoriesReceived.InventoryReceived
alias Medcamp.LabTests
alias Medcamp.LabTests.LabTest
alias Medcamp.LabResults.LabResult
alias Medcamp.Organisations
alias Medcamp.PatientVisits.PatientVisit
alias Medcamp.Patients
alias Medcamp.Patients.Patient
alias Medcamp.Repo
alias Medcamp.Tenancy
alias Medcamp.Triages.Triage

password = "123456"
now = DateTime.utc_now() |> DateTime.truncate(:second)

unwrap! = fn
  {:ok, record}, _label -> record
  {:error, changeset}, label -> raise "#{label} failed: #{inspect(changeset.errors)}"
end

## Organisation ------------------------------------------------------------
#
# Everything below is tenant-scoped, so the organisation has to exist and be
# entered before a single record is written.

organisation =
  case Organisations.get_organisation_by_slug("default") do
    nil ->
      unwrap!.(
        Organisations.create_organisation(%{
          "name" => "GHC Excellence",
          "slug" => "default",
          "location" => "Kenya",
          "logo" => "/images/logo.png",
          "primary_color" => "#373896",
          "accent_color" => "#6667ab"
        }),
        "default organisation"
      )

    existing ->
      existing
  end

Tenancy.put_org_id(organisation.id)

## Camp ---------------------------------------------------------------------
#
# The seeded activity below has to land somewhere, so the organisation gets
# one two-day camp and it is made active before anything else is written.

camp_start_date = Date.add(Date.utc_today(), -1)
camp_end_date = Date.utc_today()

camp_attrs = %{
  "name" => "Seed Camp",
  "location" => "Kenya",
  "start_date" => camp_start_date,
  "end_date" => camp_end_date
}

camp =
  case Repo.one(from c in Medcamp.Camps.Camp, where: c.name == "Seed Camp", limit: 1) do
    nil -> unwrap!.(Camps.create_camp(camp_attrs), "camp")
    existing -> unwrap!.(Camps.update_camp(existing, camp_attrs), "camp")
  end

{:ok, camp} = Camps.set_active_camp(camp)
Scope.put_active_camp_id(camp.id)

## Staff -------------------------------------------------------------------

otp_for_email = fn email, desired_otp ->
  case Repo.get_by(User, otp: desired_otp) do
    nil -> desired_otp
    %User{email: ^email} -> desired_otp
    _other_user -> nil
  end
end

ensure_user = fn attrs ->
  # Both ways `register_user/1` can report "this email is already here": the
  # changeset's `unsafe_validate_unique` (a SELECT, scoped to the current
  # organisation) and the unique index behind it (unscoped). Either one means
  # the row exists and the seed should adopt it rather than abort.
  taken_email? = fn changeset ->
    case Keyword.get(changeset.errors, :email) do
      {_message, metadata} when is_list(metadata) ->
        Keyword.get(metadata, :constraint) == :unique or
          Keyword.get(metadata, :validation) == :unsafe_unique

      _ ->
        false
    end
  end

  # ...and both ways it can be found again: the organisation-scoped lookup
  # matches what the changeset saw, the unscoped one matches the index.
  existing_user = fn email ->
    Accounts.get_organisation_user_by_email(email) || Accounts.get_user_by_email(email)
  end

  user =
    case existing_user.(attrs.email) do
      nil ->
        registration = %{
          "email" => attrs.email,
          "password" => password,
          "role" => attrs.role,
          "name" => attrs.name,
          "otp" => attrs.otp
        }

        case Accounts.register_user(registration) do
          {:ok, user} ->
            user

          {:error, changeset} ->
            if taken_email?.(changeset) do
              case existing_user.(attrs.email) do
                nil -> unwrap!.({:error, changeset}, "user #{attrs.email}")
                user -> user
              end
            else
              unwrap!.({:error, changeset}, "user #{attrs.email}")
            end
        end

      user ->
        user
    end

  user =
    user
    |> User.password_changeset(%{"password" => password})
    |> Repo.update!()

  desired_changes = %{
    name: attrs.name,
    role: attrs.role,
    organisation_id: organisation.id,
    is_active: true,
    confirmed_at: user.confirmed_at || now
  }

  desired_changes =
    case otp_for_email.(attrs.email, attrs.otp) do
      nil -> desired_changes
      otp -> Map.put(desired_changes, :otp, otp)
    end

  user
  |> Ecto.Changeset.change(desired_changes)
  |> Repo.update!()
end

users =
  [
    %{name: "Admin User", email: "admin@gmail.com", role: "admin", otp: "1001"},
    %{name: "Dr Amina Demo", email: "doctor@gmail.com", role: "doctor", otp: "1002"},
    %{name: "Nurse Brian Demo", email: "nurse@gmail.com", role: "nurse", otp: "1003"},
    %{
      name: "Receptionist Demo",
      email: "receptionist@gmail.com",
      role: "receptionist",
      otp: "1004"
    },
    %{name: "Pharmacist Demo", email: "pharmacist@gmail.com", role: "pharmacist", otp: "1005"},
    %{
      name: "Lab Technician Demo",
      email: "labtechnician@gmail.com",
      role: "labtechnician",
      otp: "1006"
    }
  ]
  |> Enum.map(&{&1.role, ensure_user.(&1)})
  |> Map.new()

pharmacist = users["pharmacist"]

## Superadmins -------------------------------------------------------------
#
# Platform accounts land at /superadmin/organisations. The current schema
# requires every user to have an organisation, so these accounts sit in the
# default organisation for storage only; `is_superadmin`, not `role`, gives
# them platform access. Add another entry here to seed a fellow superadmin.

superadmin_accounts = [
  %{
    name: "Superadmin",
    email: "superadmin@gmail.com",
    role: "admin",
    otp: "1000"
  }
]

for attrs <- superadmin_accounts do
  attrs
  |> ensure_user.()
  |> Ecto.Changeset.change(%{is_superadmin: true})
  |> Repo.update!()
end

## Lab test catalogue ------------------------------------------------------

lab_tests = [
  %{name: "Malaria RDT", price: 0},
  %{name: "Blood Sugar (RBS)", price: 0},
  %{name: "Haemoglobin (Hb)", price: 0},
  %{name: "Full Blood Count", price: 0},
  %{name: "Urinalysis", price: 0},
  %{name: "HIV Screening", price: 0},
  %{name: "Pregnancy Test (HCG)", price: 0},
  %{name: "Stool for Ova & Cysts", price: 0}
]

for attrs <- lab_tests do
  case Repo.get_by(LabTest, name: attrs.name) do
    nil -> unwrap!.(LabTests.create_lab_test(attrs), "lab test #{attrs.name}")
    lab_test -> lab_test
  end
end

# Keep the structured result templates aligned with this catalogue.
Code.require_file(Path.expand("seeds/current_lab_test_templates.exs", __DIR__))

## Drug stock --------------------------------------------------------------

# Each drug needs an item-master row (`inventories_received`) keyed by GTIN -
# that is the identity a prescription and a dispense are recorded against.
#
# Several drugs carry more than one batch so that batch selection, FEFO
# ordering and the expiry/stock-alert screens have something to work with. The
# short-dated batches below are deliberate: they keep the expiry filters and
# stock alerts populated.
drug_stock = [
  %{
    gtin: "06161021090001",
    generic_name: "Paracetamol 500mg",
    brand_name: "Panadol",
    uom: "Tablets",
    batches: [
      %{batch: "PCM-2601", expiry: "2027-06-30", quantity: 500},
      %{batch: "PCM-2611", expiry: "2026-11-30", quantity: 240}
    ]
  },
  %{
    gtin: "06161021090002",
    generic_name: "Amoxicillin 250mg",
    brand_name: "Amoxil",
    uom: "Capsules",
    batches: [
      %{batch: "AMX-2602", expiry: "2027-03-31", quantity: 300},
      %{batch: "AMX-2612", expiry: "2026-10-31", quantity: 150}
    ]
  },
  %{
    gtin: "06161021090003",
    generic_name: "Artemether/Lumefantrine 20/120mg",
    brand_name: "Coartem",
    uom: "Tablets",
    batches: [%{batch: "ALU-2603", expiry: "2026-12-31", quantity: 200}]
  },
  %{
    gtin: "06161021090004",
    generic_name: "Albendazole 400mg",
    brand_name: "Zentel",
    uom: "Tablets",
    batches: [%{batch: "ALB-2604", expiry: "2028-01-31", quantity: 400}]
  },
  %{
    gtin: "06161021090005",
    generic_name: "Oral Rehydration Salts",
    brand_name: "ORS",
    uom: "Sachets",
    batches: [%{batch: "ORS-2605", expiry: "2027-09-30", quantity: 250}]
  },
  %{
    gtin: "06161021090006",
    generic_name: "Ibuprofen 400mg",
    brand_name: "Brufen",
    uom: "Tablets",
    batches: [%{batch: "IBU-2606", expiry: "2027-08-31", quantity: 360}]
  },
  %{
    gtin: "06161021090007",
    generic_name: "Amlodipine 5mg",
    brand_name: "Norvasc",
    uom: "Tablets",
    batches: [%{batch: "AML-2607", expiry: "2028-02-28", quantity: 300}]
  },
  %{
    gtin: "06161021090008",
    generic_name: "Metformin 500mg",
    brand_name: "Glucophage",
    uom: "Tablets",
    batches: [
      %{batch: "MET-2608", expiry: "2027-11-30", quantity: 420},
      %{batch: "MET-2618", expiry: "2026-10-15", quantity: 120}
    ]
  },
  %{
    gtin: "06161021090009",
    generic_name: "Omeprazole 20mg",
    brand_name: "Losec",
    uom: "Capsules",
    batches: [%{batch: "OME-2609", expiry: "2027-07-31", quantity: 280}]
  },
  %{
    gtin: "06161021090010",
    generic_name: "Cetirizine 10mg",
    brand_name: "Zyrtec",
    uom: "Tablets",
    batches: [%{batch: "CET-2610", expiry: "2028-04-30", quantity: 320}]
  },
  %{
    gtin: "06161021090011",
    generic_name: "Ferrous Sulphate + Folic Acid",
    brand_name: "Ranferon",
    uom: "Tablets",
    batches: [%{batch: "FEF-2611", expiry: "2027-05-31", quantity: 500}]
  },
  %{
    gtin: "06161021090012",
    generic_name: "Cotrimoxazole 480mg",
    brand_name: "Septrin",
    uom: "Tablets",
    batches: [%{batch: "COT-2612", expiry: "2027-02-28", quantity: 260}]
  },
  %{
    gtin: "06161021090013",
    generic_name: "Salbutamol Inhaler 100mcg",
    brand_name: "Ventolin",
    uom: "Inhalers",
    batches: [%{batch: "SAL-2613", expiry: "2027-10-31", quantity: 60}]
  },
  %{
    gtin: "06161021090014",
    generic_name: "Hydrocortisone Cream 1%",
    brand_name: "Cortaid",
    uom: "Tubes",
    batches: [%{batch: "HYD-2614", expiry: "2027-04-30", quantity: 90}]
  },
  %{
    gtin: "06161021090015",
    generic_name: "Amoxicillin Suspension 125mg/5ml",
    brand_name: "Amoxil Syrup",
    uom: "Bottles",
    batches: [%{batch: "AMS-2615", expiry: "2026-09-30", quantity: 80}]
  },
  %{
    gtin: "06161021090016",
    generic_name: "Zinc Sulphate 20mg",
    brand_name: "Zincovit",
    uom: "Tablets",
    batches: [%{batch: "ZNC-2616", expiry: "2028-03-31", quantity: 300}]
  },
  %{
    gtin: "06161021090017",
    generic_name: "Diclofenac 50mg",
    brand_name: "Voltaren",
    uom: "Tablets",
    batches: [%{batch: "DIC-2617", expiry: "2027-12-31", quantity: 240}]
  },
  %{
    gtin: "06161021090018",
    generic_name: "Metronidazole 400mg",
    brand_name: "Flagyl",
    uom: "Tablets",
    batches: [%{batch: "MTZ-2618", expiry: "2027-01-31", quantity: 300}]
  },
  %{
    gtin: "06161021090019",
    generic_name: "Losartan 50mg",
    brand_name: "Cozaar",
    uom: "Tablets",
    batches: [%{batch: "LOS-2619", expiry: "2028-05-31", quantity: 200}]
  },
  %{
    gtin: "06161021090020",
    generic_name: "Multivitamin Syrup",
    brand_name: "Vitaplex",
    uom: "Bottles",
    batches: [%{batch: "MVT-2620", expiry: "2027-06-30", quantity: 110}]
  }
]

for {attrs, drug_index} <- Enum.with_index(drug_stock, 1) do
  # Deterministic demo acquisition price. Existing non-zero prices are kept so
  # rerunning seeds never overwrites a price entered through the application.
  default_unit_price = 5 + drug_index * 5

  item =
    case Repo.get_by(InventoryReceived, gtin: attrs.gtin) do
      nil ->
        unwrap!.(
          InventoriesReceived.create_inventory_received(%{
            "gtin" => attrs.gtin,
            "brand_name" => attrs.brand_name,
            "generic_name" => attrs.generic_name,
            "type" => "Drug",
            "category" => "Pharmaceuticals",
            "uom" => attrs.uom,
            "user_id" => pharmacist.id
          }),
          "item master #{attrs.gtin}"
        )

      item ->
        item
    end

  drug =
    case Repo.get_by(Drug, inventory_received_id: item.id) do
      nil ->
        unwrap!.(
          Drugs.create_drug(%{
            inventory_received_id: item.id,
            inventory_manager_id: pharmacist.id,
            generic_name: attrs.generic_name,
            brand_name: attrs.brand_name,
            is_otc: true
          }),
          "drug #{attrs.generic_name}"
        )

      drug ->
        drug
    end

  for batch_attrs <- attrs.batches do
    case Repo.get_by(Medcamp.Batches.Batch, gtin: attrs.gtin, batch: batch_attrs.batch) do
      nil ->
        unwrap!.(
          DrugBatches.take_in_batch(%{
            drug_id: drug.id,
            inventory_received_id: item.id,
            inventory_manager_id: pharmacist.id,
            quantity: batch_attrs.quantity,
            price_per_unit: default_unit_price,
            gtin: attrs.gtin,
            batch: batch_attrs.batch,
            expiry: batch_attrs.expiry
          }),
          "batch #{batch_attrs.batch}"
        )

      %{price_per_unit: price} = batch when price in [nil, 0] ->
        batch
        |> Medcamp.Batches.Batch.changeset(%{price_per_unit: default_unit_price})
        |> Repo.update!()

      batch ->
        batch
    end
  end
end

## Demo patients -----------------------------------------------------------
#
# The roster is generated rather than hand-listed so the camp has enough
# volume to exercise pagination, dashboard counts and the queue screens. Names
# are drawn from fixed pools by index, so re-running the seeds produces the
# same roster and updates those patients instead of adding new ones.

patient_count = 120

female_first_names =
  ~w(Achieng Faith Mary Grace Mercy Lilian Esther Joyce Lucy Irene Beatrice Caroline Ruth Ann
     Sheila Winnie Janet Purity Nancy Eunice Rose Dorcas Millicent Naomi Pauline Agnes Edith
     Damaris Consolata Hellen)

male_first_names =
  ~w(Brian David Samuel John Peter Kevin Daniel Collins Joseph George Dennis Victor Eric Martin
     Paul Stephen Antony Felix Moses Elijah Charles Isaac Nicholas Patrick Simon Timothy Vincent
     Wilson Duncan Fredrick)

middle_names =
  ~w(Atieno Kamau Wanjiku Kiptoo Naliaka Mutua Wairimu Omondi Chebet Muriithi Akinyi Barasa
     Muthoni Kiprotich Nduta Onyango Wambui Munyao Jepkoech Odongo Nanjala Karanja Adhiambo
     Kipngetich Nyambura Mwendwa Wangari Wanyonyi Cherono Ochieng)

surnames =
  ~w(Otieno Mwangi Njoroge Koech Wekesa Musyoka Kariuki Ouma Rono Njenga Odhiambo Wafula Kimani
     Langat Maina Okello Githinji Mutiso Keter Opiyo Simiyu Macharia Ochieng Bett Wanjohi Kioko
     Mbugua Were Korir Owino)

patient_names =
  Enum.map(1..patient_count, fn index ->
    gender = if rem(index, 2) == 0, do: "Female", else: "Male"

    first_name_pool = if gender == "Female", do: female_first_names, else: male_first_names

    first_name = Enum.at(first_name_pool, rem(div(index, 2), length(first_name_pool)))
    middle_name = Enum.at(middle_names, rem(index * 7, length(middle_names)))
    last_name = Enum.at(surnames, rem(index * 11, length(surnames)))

    {first_name, middle_name, last_name, gender}
  end)

locations = [
  "Nairobi",
  "Kiambu",
  "Machakos",
  "Kajiado",
  "Nakuru",
  "Murang'a",
  "Kisumu",
  "Kakamega",
  "Meru",
  "Nyeri",
  "Eldoret",
  "Mombasa"
]

visit_reasons = [
  "Fever and headache",
  "Routine wellness check",
  "Cough and sore throat",
  "Abdominal discomfort",
  "Back and joint pain",
  "Medication review",
  "Dizziness and fatigue",
  "Skin rash",
  "Blood pressure follow-up",
  "Persistent heartburn"
]

# The camp should look like a camp: most patients have moved through, a
# smaller tail is still queueing. Weighting the cycle keeps every queue
# populated without making the whole roster look stuck at reception.
visit_status_for = fn index ->
  case rem(index, 10) do
    0 -> "triage_pending"
    1 -> "triaged"
    2 -> "with_doctor"
    3 -> "lab_pending"
    4 -> "pharmacy_pending"
    _ -> "completed"
  end
end

nurse = users["nurse"]
receptionist = users["receptionist"]
doctor = users["doctor"]
lab_technician = users["labtechnician"]
demo_drugs = Repo.all(Drug)

patients =
  patient_names
  |> Enum.with_index(1)
  |> Enum.map(fn {{first_name, middle_name, last_name, gender}, index} ->
    email = "patient#{String.pad_leading(to_string(index), 2, "0")}@demo.medcamp.test"
    has_insurance = rem(index, 3) == 0

    patient_attrs = %{
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name,
      email: email,
      phone_number: "+254710#{String.pad_leading(to_string(index), 6, "0")}",
      national_id: "DEMO#{String.pad_leading(to_string(index), 5, "0")}",
      date_of_birth:
        Date.new!(1955 + rem(index * 7, 58), rem(index, 12) + 1, rem(index * 3, 27) + 1),
      gender: gender,
      consent_agreement: true,
      has_insurance: has_insurance,
      insurance_scheme: if(has_insurance, do: "SHA", else: nil),
      insurance_number: if(has_insurance, do: "SHA-DEMO-#{1000 + index}", else: nil),
      insurance_cover_limit: if(has_insurance, do: 50_000, else: nil),
      insurance_company: if(has_insurance, do: "Social Health Authority", else: nil),
      is_for_medical_camp: true,
      medical_camp_name: "GHC Community Medical Camp",
      patient_type: if(rem(index, 4) == 0, do: "Returning", else: "New"),
      home_address: Enum.at(locations, rem(index - 1, length(locations))),
      emergency_contact_name: "#{last_name} Family Contact",
      emergency_contact_phone_number: "+254720#{String.pad_leading(to_string(index), 6, "0")}",
      emergency_contact_relationship:
        Enum.at(["Spouse", "Parent", "Sibling", "Child"], rem(index, 4)),
      creator_id: receptionist.id
    }

    patient =
      case Repo.get_by(Patient, email: email) do
        nil ->
          patient_attrs
          |> Map.merge(%{gsrn: Patients.get_available_gsrn(), pin: 2000 + index})
          |> then(&Patient.changeset(%Patient{}, &1))
          |> Repo.insert!()

        existing ->
          existing
          |> Patient.changeset(patient_attrs)
          |> Repo.update!()
      end

    # Every patient's activity falls within the camp's two-day window. Roughly
    # a third attended on both days, which keeps repeat-visit screens useful;
    # everyone else is split evenly between day one and day two.
    visit_plan =
      if rem(index, 3) == 0 do
        [
          {:current, camp_end_date, visit_status_for.(index)},
          {:earlier, camp_start_date, "completed"}
        ]
      else
        visit_date = if rem(index, 2) == 0, do: camp_start_date, else: camp_end_date
        [{:current, visit_date, visit_status_for.(index)}]
      end

    # The camp roster - and so the whole Medical Camp Dashboard - is driven by
    # `camp_attendances`, which `Patients.register_*` writes as part of the
    # registration transaction. These patients are inserted straight through
    # the changeset, so the attendance row has to be written here or the camp
    # looks empty however many patients and triages exist.
    #
    # Dated from the patient's earliest visit rather than "now" so the
    # dashboard's per-day tabs span the camp instead of collapsing onto today.
    first_seen_date = visit_plan |> Enum.map(fn {_, date, _} -> date end) |> Enum.min(Date)

    first_seen_at =
      first_seen_date
      |> DateTime.new!(Time.new!(8 + rem(index, 6), rem(index * 7, 60), 0))
      |> DateTime.truncate(:second)

    %Medcamp.Camps.CampAttendance{}
    |> Medcamp.Camps.CampAttendance.changeset(%{
      patient_id: patient.id,
      camp_id: camp.id,
      first_seen_at: first_seen_at
    })
    |> Repo.insert(
      on_conflict: [set: [first_seen_at: first_seen_at, updated_at: now]],
      conflict_target: [:patient_id, :camp_id]
    )

    for {occurrence, visit_date, visit_status} <- visit_plan do
      visit_reason =
        Enum.at(
          visit_reasons,
          rem(index - 1 + if(occurrence == :earlier, do: 3, else: 0), length(visit_reasons))
        )

      # The reason doubles as the idempotency key for the visit, so the two
      # occurrences must not collide.
      reason =
        case occurrence do
          :current -> "Demo: #{visit_reason}"
          :earlier -> "Demo earlier visit: #{visit_reason}"
        end

      visit_attrs = %{
        patient_id: patient.id,
        creator_id: receptionist.id,
        doctor_id:
          if(visit_status in ~w(with_doctor lab_pending pharmacy_pending completed),
            do: users["doctor"].id,
            else: nil
          ),
        date: visit_date,
        time: Time.new!(8 + rem(index, 8), rem(index * 7, 60), 0),
        visit_type: if(occurrence == :earlier, do: "Follow-up", else: "Medical camp"),
        reason: reason,
        status: visit_status
      }

      visit =
        case Repo.get_by(PatientVisit, patient_id: patient.id, reason: visit_attrs.reason) do
          nil -> PatientVisit.changeset(%PatientVisit{}, visit_attrs) |> Repo.insert!()
          visit -> PatientVisit.changeset(visit, visit_attrs) |> Repo.update!()
        end

      if visit_status != "triage_pending" do
        triage_attrs = %{
          patient_id: patient.id,
          creator_id: nurse.id,
          date: visit_date,
          time: Time.new!(9 + rem(index, 7), rem(index * 5, 60), 0),
          temperature: 36.2 + rem(index, 14) / 10,
          blood_pressure: "#{105 + rem(index * 3, 35)}/#{65 + rem(index * 2, 25)}",
          pulse_rate: 66.0 + rem(index * 3, 34),
          oxygen_saturation: 95.0 + rem(index, 5),
          height: 150.0 + rem(index * 3, 35),
          weight: 48.0 + rem(index * 5, 42),
          allergies: if(rem(index, 7) == 0, do: "Penicillin", else: "No known allergies"),
          # Must stay within `Triage.emergency_scales/0` — the changeset
          # validates inclusion and the seed aborts on anything else.
          emergency_scale:
            cond do
              rem(index, 8) == 0 -> "High"
              rem(index, 3) == 0 -> "Medium"
              true -> "Low"
            end,
          pain: rem(index, 5) == 0,
          triage_notes: "Demo triage observations recorded during intake."
        }

        case Repo.get_by(Triage, patient_id: patient.id, date: visit_date) do
          nil -> Triage.changeset(%Triage{}, triage_attrs) |> Repo.insert!()
          triage -> Triage.changeset(triage, triage_attrs) |> Repo.update!()
        end
      end

      # Downstream records follow the visit's position in the camp. This keeps
      # the demo useful for every dashboard without inventing impossible data
      # (for example, a dispensed drug on a visit still waiting for triage).
      if visit_status != "triage_pending" do
        diagnosis =
          Enum.at(
            ["Upper respiratory tract infection", "Malaria", "Gastritis", "Musculoskeletal pain"],
            rem(index - 1, 4)
          )

        note_attrs = %{
          patient_id: patient.id,
          patient_visit_id: visit.id,
          doctor_id: doctor.id,
          date: visit_date,
          time: Time.new!(10 + rem(index, 6), rem(index * 11, 60), 0),
          reason_for_consulatation: visit_reason,
          symptoms: visit_reason,
          diagnosis: diagnosis,
          diagnosis_icd_code: Enum.at(["J06.9", "B54", "K29.7", "M79.1"], rem(index - 1, 4)),
          investigations: "Clinical examination and indicated point-of-care tests",
          impression: diagnosis,
          management: "Treat symptoms, complete prescribed medication, and return if worse.",
          clinical_notes: "Demo consultation completed during the medical camp.",
          doctor_signature: "Dr Amina Demo"
        }

        doctor_note =
          case Repo.get_by(DoctorNote, patient_visit_id: visit.id) do
            nil -> DoctorNote.changeset(%DoctorNote{}, note_attrs) |> Repo.insert!()
            note -> DoctorNote.changeset(note, note_attrs) |> Repo.update!()
          end

        if visit_status in ~w(lab_pending pharmacy_pending completed) do
          requested_test =
            Enum.at(
              lab_tests,
              rem(index - 1 + if(occurrence == :earlier, do: 4, else: 0), length(lab_tests))
            )

          report_complete = visit_status != "lab_pending"

          lab_attrs = %{
            name: requested_test.name,
            description: "Demo laboratory request from camp consultation",
            urgency: if(rem(index, 5) == 0, do: "Urgent", else: "Routine"),
            patient_id: patient.id,
            doctor_id: doctor.id,
            doctor_note_id: doctor_note.id,
            lab_technician_id: if(report_complete, do: lab_technician.id, else: nil),
            date_of_test: if(report_complete, do: visit_date, else: nil),
            sample_collection_date: if(report_complete, do: visit_date, else: nil),
            sample_collection_description:
              if(report_complete,
                do: "Sample collected and processed at camp laboratory",
                else: nil
              ),
            technician_name: if(report_complete, do: lab_technician.name, else: nil),
            test_findings:
              if(report_complete, do: "Result reviewed; see structured test result.", else: nil),
            report_complete: report_complete,
            has_paid: true,
            payment_type: "Medical camp",
            total_amount_paid: 0,
            time: Time.new!(11 + rem(index, 5), rem(index * 13, 60), 0),
            tests: [
              %{
                name: requested_test.name,
                price: requested_test.price,
                serial:
                  "DEMO-LAB-#{String.pad_leading(to_string(index), 4, "0")}-#{if occurrence == :earlier, do: "B", else: "A"}",
                result: if(report_complete, do: "Completed — within expected range", else: nil)
              }
            ]
          }

          case Repo.get_by(LabResult, doctor_note_id: doctor_note.id) do
            nil ->
              LabResult.changeset(%LabResult{}, lab_attrs) |> Repo.insert!()

            result ->
              # The embedded test row is already deterministic and its schema
              # rejects replacement without the existing embed ID. Update the
              # parent result fields while retaining that seeded payload.
              result
              |> LabResult.changeset(Map.delete(lab_attrs, :tests))
              |> Repo.update!()
          end
        end

        if visit_status in ~w(pharmacy_pending completed) do
          drug =
            Enum.at(
              demo_drugs,
              rem(index - 1 + if(occurrence == :earlier, do: 7, else: 0), length(demo_drugs))
            )

          item = Repo.get!(InventoryReceived, drug.inventory_received_id)
          quantity = 6 + rem(index, 5)

          unit_price =
            Repo.one(
              from b in Medcamp.Batches.Batch,
                where: b.inventory_received_id == ^item.id,
                select: max(b.price_per_unit)
            ) || 0

          dispensed_price = quantity * unit_price

          allocation_attrs = %{
            patient_id: patient.id,
            doctor_id: doctor.id,
            doctor_note_id: doctor_note.id,
            pharmacist_id: pharmacist.id,
            prescription: "#{item.generic_name}: take as directed after meals",
            quantity: quantity,
            has_been_assigned: true,
            has_paid: true,
            payment_type: "Medical camp",
            total_amount_paid: 0,
            drugs_assigned: [
              %{
                brand_name: item.brand_name,
                generic_name: item.generic_name,
                inventory_received_id: item.id,
                quantity: quantity,
                unit_of_measurement: item.uom || "Tablets",
                frequency: "Twice daily",
                duration_in_days: 3,
                price: dispensed_price,
                strength: "Standard",
                prescription_note: "Take after meals",
                route_of_administration: "Oral",
                has_been_given: visit_status == "completed"
              }
            ]
          }

          allocation =
            case Repo.get_by(DrugAllocation, doctor_note_id: doctor_note.id) do
              nil ->
                DrugAllocation.changeset(%DrugAllocation{}, allocation_attrs,
                  validate_available_quantity: false
                )
                |> Repo.insert!()

              existing ->
                existing
            end

          if visit_status == "completed" do
            dispense_attrs = %{
              drug_allocation_id: allocation.id,
              drug_id: drug.id,
              pharmacist_id: pharmacist.id,
              quantity: quantity,
              price: dispensed_price
            }

            case Repo.get_by(DrugGiven,
                   drug_allocation_id: allocation.id,
                   drug_id: drug.id
                 ) do
              nil -> DrugGiven.changeset(%DrugGiven{}, dispense_attrs) |> Repo.insert!()
              dispense -> DrugGiven.changeset(dispense, dispense_attrs) |> Repo.update!()
            end
          end
        end
      end
    end

    patient
  end)

# Older versions of this seed spread triages over several weeks. Remove only
# those recognisable demo rows so rerunning the seed fully reconciles an
# existing development database to this camp's two-day window.
patient_ids = Enum.map(patients, & &1.id)

from(t in Triage,
  where:
    t.patient_id in ^patient_ids and
      t.triage_notes == "Demo triage observations recorded during intake." and
      (t.date < ^camp_start_date or t.date > ^camp_end_date)
)
|> Repo.delete_all()

IO.puts("""
Seeded medical camp:
  #{map_size(users)} staff logins + 1 superadmin (password: #{password})
  #{length(patients)} demo patients, each with a current visit and one in three
    carrying an earlier completed visit, all within the two-day camp
  triage, consultations, lab requests/results, prescriptions and dispensing
    records following each visit's status
  #{length(lab_tests)} lab tests
  #{length(drug_stock)} drugs across #{drug_stock |> Enum.map(&length(&1.batches)) |> Enum.sum()} batches, including short-dated ones for the expiry
    and stock-alert screens

Log in as admin@gmail.com to add the rest of your camp staff, or
superadmin@gmail.com for the platform-wide organisation screens.
New batches are immediately available for prescribing and dispensing.
""")
