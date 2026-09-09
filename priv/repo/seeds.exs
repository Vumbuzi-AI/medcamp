# Seeds a medical camp with one login per role, a lab test catalogue and a
# small drug stock, so a fresh database is immediately usable.
#
#     mix run priv/repo/seeds.exs
#
# Idempotent: re-running updates the seeded records rather than duplicating
# them. Every account uses the same demo password - change or remove these
# before running a real camp.

alias Medcamp.Accounts
alias Medcamp.Accounts.User
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

## Staff -------------------------------------------------------------------

otp_for_email = fn email, desired_otp ->
  case Repo.get_by(User, otp: desired_otp) do
    nil -> desired_otp
    %User{email: ^email} -> desired_otp
    _other_user -> nil
  end
end

ensure_user = fn attrs ->
  user =
    case Accounts.get_user_by_email(attrs.email) do
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
            email_error = Keyword.get(changeset.errors, :email)

            if match?({_, metadata} when is_list(metadata), email_error) and
                 Keyword.get(elem(email_error, 1), :constraint) == :unique do
              # The lookup and insert are separate queries. If another seed
              # process (or a concurrent request) inserted this email between
              # them, use the row protected by the unique index.
              case Accounts.get_user_by_email(attrs.email) do
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
drug_stock = [
  %{
    gtin: "06161021090001",
    generic_name: "Paracetamol 500mg",
    brand_name: "Panadol",
    batch: "PCM-2601",
    expiry: "2027-06-30",
    quantity: 500
  },
  %{
    gtin: "06161021090002",
    generic_name: "Amoxicillin 250mg",
    brand_name: "Amoxil",
    batch: "AMX-2602",
    expiry: "2027-03-31",
    quantity: 300
  },
  %{
    gtin: "06161021090003",
    generic_name: "Artemether/Lumefantrine 20/120mg",
    brand_name: "Coartem",
    batch: "ALU-2603",
    expiry: "2026-12-31",
    quantity: 200
  },
  %{
    gtin: "06161021090004",
    generic_name: "Albendazole 400mg",
    brand_name: "Zentel",
    batch: "ALB-2604",
    expiry: "2028-01-31",
    quantity: 400
  },
  %{
    gtin: "06161021090005",
    generic_name: "Oral Rehydration Salts",
    brand_name: "ORS",
    batch: "ORS-2605",
    expiry: "2027-09-30",
    quantity: 250
  }
]

for attrs <- drug_stock do
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
            "uom" => "Tablets",
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

  unless Repo.get_by(Medcamp.Batches.Batch, gtin: attrs.gtin, batch: attrs.batch) do
    unwrap!.(
      DrugBatches.take_in_batch(%{
        drug_id: drug.id,
        inventory_received_id: item.id,
        inventory_manager_id: pharmacist.id,
        quantity: attrs.quantity,
        gtin: attrs.gtin,
        batch: attrs.batch,
        expiry: attrs.expiry
      }),
      "batch #{attrs.batch}"
    )
  end
end

## Demo patients -----------------------------------------------------------

patient_names = [
  {"Achieng", "Atieno", "Otieno", "Female"},
  {"Brian", "Kamau", "Mwangi", "Male"},
  {"Faith", "Wanjiku", "Njoroge", "Female"},
  {"David", "Kiptoo", "Koech", "Male"},
  {"Mary", "Naliaka", "Wekesa", "Female"},
  {"Samuel", "Mutua", "Musyoka", "Male"},
  {"Grace", "Wairimu", "Kariuki", "Female"},
  {"John", "Omondi", "Ouma", "Male"},
  {"Mercy", "Chebet", "Rono", "Female"},
  {"Peter", "Muriithi", "Njenga", "Male"},
  {"Lilian", "Akinyi", "Odhiambo", "Female"},
  {"Kevin", "Barasa", "Wafula", "Male"},
  {"Esther", "Muthoni", "Kimani", "Female"},
  {"Daniel", "Kiprotich", "Langat", "Male"},
  {"Joyce", "Nduta", "Maina", "Female"},
  {"Collins", "Onyango", "Okello", "Male"},
  {"Lucy", "Wambui", "Githinji", "Female"},
  {"Joseph", "Munyao", "Mutiso", "Male"},
  {"Irene", "Jepkoech", "Keter", "Female"},
  {"George", "Odongo", "Opiyo", "Male"},
  {"Beatrice", "Nanjala", "Simiyu", "Female"},
  {"Dennis", "Karanja", "Macharia", "Male"},
  {"Caroline", "Adhiambo", "Ochieng", "Female"},
  {"Victor", "Kipngetich", "Bett", "Male"},
  {"Ruth", "Nyambura", "Wanjohi", "Female"},
  {"Eric", "Mwendwa", "Kioko", "Male"},
  {"Ann", "Wangari", "Mbugua", "Female"},
  {"Martin", "Wanyonyi", "Were", "Male"},
  {"Sheila", "Cherono", "Korir", "Female"},
  {"Paul", "Ochieng", "Owino", "Male"}
]

locations = ["Nairobi", "Kiambu", "Machakos", "Kajiado", "Nakuru", "Murang'a"]

visit_reasons = [
  "Fever and headache",
  "Routine wellness check",
  "Cough and sore throat",
  "Abdominal discomfort",
  "Back and joint pain",
  "Medication review"
]

visit_statuses = ~w(triage_pending triaged with_doctor lab_pending pharmacy_pending completed)
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

    visit_date = Date.add(Date.utc_today(), -rem(index - 1, 7))
    visit_status = Enum.at(visit_statuses, rem(index - 1, length(visit_statuses)))
    visit_reason = Enum.at(visit_reasons, rem(index - 1, length(visit_reasons)))

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
      visit_type: if(rem(index, 4) == 0, do: "Follow-up", else: "Medical camp"),
      reason: "Demo: #{visit_reason}",
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
        emergency_scale: if(rem(index, 8) == 0, do: "Urgent", else: "Standard"),
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
        requested_test = Enum.at(lab_tests, rem(index - 1, length(lab_tests)))
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
              serial: "DEMO-LAB-#{String.pad_leading(to_string(index), 4, "0")}",
              result: if(report_complete, do: "Completed — within expected range", else: nil)
            }
          ]
        }

        unless Repo.get_by(LabResult, doctor_note_id: doctor_note.id) do
          LabResult.changeset(%LabResult{}, lab_attrs) |> Repo.insert!()
        end
      end

      if visit_status in ~w(pharmacy_pending completed) do
        drug = Enum.at(demo_drugs, rem(index - 1, length(demo_drugs)))
        item = Repo.get!(InventoryReceived, drug.inventory_received_id)
        quantity = 6 + rem(index, 5)

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
              price: 0,
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

        if visit_status == "completed" and
             is_nil(Repo.get_by(DrugGiven, drug_allocation_id: allocation.id, drug_id: drug.id)) do
          DrugGiven.changeset(%DrugGiven{}, %{
            drug_allocation_id: allocation.id,
            drug_id: drug.id,
            pharmacist_id: pharmacist.id,
            quantity: quantity,
            price: 0
          })
          |> Repo.insert!()
        end
      end
    end

    patient
  end)

IO.puts("""
Seeded medical camp:
  #{map_size(users)} staff logins (password: #{password})
  #{length(patients)} demo patients with visits and representative triage data
  completed consultations, lab requests/results, prescriptions and dispensing records
  #{length(lab_tests)} lab tests
  #{length(drug_stock)} drugs, each with one active batch

Log in as admin@gmail.com to add the rest of your camp staff.
New batches are immediately available for prescribing and dispensing.
""")
