alias Medcamp.Accounts
alias Medcamp.Accounts.User
alias Medcamp.Appointments
alias Medcamp.Appointments.Appointment
alias Medcamp.Batches
alias Medcamp.Batches.Batch
alias Medcamp.Departments
alias Medcamp.Departments.Department
alias Medcamp.DoctorNotes
alias Medcamp.DoctorNotes.DoctorNote
alias Medcamp.DrugBatches
alias Medcamp.DrugBatches.DrugBatch
alias Medcamp.Drugs
alias Medcamp.Drugs.Drug
alias Medcamp.InventoriesReceived
alias Medcamp.InventoriesReceived.InventoryReceived
alias Medcamp.LabResults
alias Medcamp.LabResults.LabResult
alias Medcamp.LabTestTemplates
alias Medcamp.LabTestTemplates.{LabTestCategory, LabTestTemplate}
alias Medcamp.LabTests
alias Medcamp.LabTests.LabTest
alias Medcamp.PatientVisits
alias Medcamp.PatientVisits.PatientVisit
alias Medcamp.Patients
alias Medcamp.Patients.Patient
alias Medcamp.Procedures
alias Medcamp.Procedures.Procedure
alias Medcamp.RadiologyTests
alias Medcamp.RadiologyTests.RadiologyTest
alias Medcamp.Repo
alias Medcamp.Rooms
alias Medcamp.Rooms.Room
alias Medcamp.Suppliers
alias Medcamp.Suppliers.Supplier

password = "123456"
now = DateTime.utc_now() |> DateTime.truncate(:second)

unwrap! = fn
  {:ok, record}, _label -> record
  {:error, changeset}, label -> raise "#{label} failed: #{inspect(changeset.errors)}"
end

create_once = fn schema, lookup, attrs, create_fun, label ->
  case Repo.get_by(schema, lookup) do
    nil -> unwrap!.(create_fun.(Map.merge(lookup, attrs)), label)
    record -> record
  end
end

departments = [
  %{name: "Pharmacy", code: "PHARM"},
  %{name: "Nursing", code: "NURSE"},
  %{name: "Laboratory", code: "LAB"},
  %{name: "Radiology", code: "RAD"},
  %{name: "Admin", code: "ADMIN"},
  %{name: "Reception", code: "RECEP"},
  %{name: "Inventory", code: "INV"},
  %{name: "Support", code: "SUP"},
  %{name: "Procurement", code: "PROC"},
  %{name: "Stores", code: "STORES"},
  %{name: "Finance", code: "FIN"},
  %{name: "Suppliers", code: "SUPPLIER"}
]

departments_by_code =
  departments
  |> Enum.map(fn attrs ->
    department =
      create_once.(
        Department,
        %{code: attrs.code},
        %{name: attrs.name},
        &Departments.create_department/1,
        "department #{attrs.code}"
      )

    {attrs.code, department}
  end)
  |> Map.new()

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
        registration_attrs = %{
          "email" => attrs.email,
          "password" => password,
          "role" => attrs.role,
          "name" => attrs.name,
          "otp" => attrs.otp
        }

        unwrap!.(Accounts.register_user(registration_attrs), "user #{attrs.email}")

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
    is_active: true,
    confirmed_at: user.confirmed_at || now
  }

  desired_changes =
    if attrs.department_code do
      Map.put(desired_changes, :department_id, departments_by_code[attrs.department_code].id)
    else
      desired_changes
    end

  desired_changes =
    case otp_for_email.(attrs.email, attrs.otp) do
      nil -> desired_changes
      otp -> Map.put(desired_changes, :otp, otp)
    end

  user
  |> Ecto.Changeset.change(desired_changes)
  |> Repo.update!()
end

seed_users = [
  %{
    name: "Admin User",
    email: "admin@gmail.com",
    role: "admin",
    otp: "1001",
    department_code: "ADMIN"
  },
  %{
    name: "Dr Amina Demo",
    email: "doctor@gmail.com",
    role: "doctor",
    otp: "1002",
    department_code: "ADMIN"
  },
  %{
    name: "Dr Peter Otieno",
    email: "doctor2@gmail.com",
    role: "doctor",
    otp: "1014",
    department_code: "ADMIN"
  },
  %{
    name: "Nurse Brian Demo",
    email: "nurse@gmail.com",
    role: "nurse",
    otp: "1003",
    department_code: "NURSE"
  },
  %{
    name: "Reception Demo",
    email: "reception@gmail.com",
    role: "reception",
    otp: "1004",
    department_code: "RECEP"
  },
  %{
    name: "Pharmacist Demo",
    email: "pharmacist@gmail.com",
    role: "pharmacist",
    otp: "1005",
    department_code: "PHARM"
  },
  %{
    name: "Lab Technician Demo",
    email: "labtechnician@gmail.com",
    role: "labtechnician",
    otp: "1006",
    department_code: "LAB"
  },
  %{
    name: "Radiologist Demo",
    email: "radiology@gmail.com",
    role: "radiologist",
    otp: "1007",
    department_code: "RAD"
  },
  %{
    name: "Inventory Manager Demo",
    email: "inventory@gmail.com",
    role: "inventory_manager",
    otp: "1008",
    department_code: "INV"
  },
  %{
    name: "Support Staff Demo",
    email: "support@gmail.com",
    role: "support staff",
    otp: "1009",
    department_code: "SUP"
  },
  %{
    name: "Procurement Officer Demo",
    email: "procurement@gmail.com",
    role: "procurement_officer",
    otp: "1010",
    department_code: "PROC"
  },
  %{
    name: "Stores Officer Demo",
    email: "stores@gmail.com",
    role: "stores_officer",
    otp: "1011",
    department_code: "STORES"
  },
  %{
    name: "Finance Officer Demo",
    email: "finance@gmail.com",
    role: "finance_officer",
    otp: "1012",
    department_code: "FIN"
  },
  %{
    name: "Supplier Portal Demo",
    email: "supplier@gmail.com",
    role: "supplier",
    otp: "1013",
    department_code: "SUPPLIER"
  }
]

users_by_role =
  seed_users
  |> Enum.map(fn attrs ->
    user = ensure_user.(attrs)
    {attrs.role, user}
  end)
  |> Map.new()

admin = users_by_role["admin"]
# `users_by_role` is keyed by role, and two seeded users now share role
# "doctor" — Map.new/1 keeps only the last one for a duplicate key, so both
# doctors are fetched explicitly by email instead to avoid silently
# colliding on whichever one happens to be last in `seed_users`.
doctor = Accounts.get_user_by_email("doctor@gmail.com")
doctor2 = Accounts.get_user_by_email("doctor2@gmail.com")
inventory_manager = users_by_role["inventory_manager"]
supplier_user = users_by_role["supplier"]

demo_patient =
  case Repo.get_by(Patient, national_id: "DEMO-001") do
    nil ->
      attrs = %{
        first_name: "Jane",
        middle_name: "Akinyi",
        last_name: "Demo",
        national_id: "DEMO-001",
        email: "jane.demo@gmail.com",
        phone_number: "0700000000",
        date_of_birth: ~D[1992-05-12],
        gender: "Female",
        home_address: "Kisumu",
        emergency_contact_name: "John Demo",
        emergency_contact_phone_number: "0711000000",
        emergency_contact_relationship: "Spouse",
        consent_agreement: true,
        patient_type: "outpatient",
        creator_id: admin.id,
        gsrn: Patients.get_available_gsrn(),
        pin: 4321
      }

      %Patient{}
      |> Patient.changeset(attrs)
      |> Repo.insert!()

    patient ->
      patient
  end

demo_visit =
  create_once.(
    PatientVisit,
    %{
      patient_id: demo_patient.id,
      reason: "Initial outpatient consultation",
      date: ~D[2026-06-29]
    },
    %{
      creator_id: admin.id,
      doctor_id: doctor.id,
      payment_type: "cash",
      visit_type: "outpatient",
      total_amount_paid: 0,
      has_paid: false
    },
    &PatientVisits.create_patient_visit/1,
    "demo patient visit"
  )

# A handful of patients + lab results spanning distinct gender, age group,
# urgency, report status, doctor, and test name values, so the lab results
# search/filter panel has something real to filter against.
lab_results_seed_data = [
  %{
    patient: %{
      first_name: "Alice",
      last_name: "Wanjiru",
      national_id: "DEMO-002",
      email: "alice.wanjiru@gmail.com",
      phone_number: "0700000002",
      date_of_birth: ~D[1994-03-10],
      gender: "Female",
      home_address: "Nairobi"
    },
    doctor: doctor,
    symptoms: "Persistent fever and fatigue",
    urgency: "Urgent",
    report_complete: true,
    tests: [%{name: "Full Haemogram", price: 900}]
  },
  %{
    patient: %{
      first_name: "Brian",
      last_name: "Otieno",
      national_id: "DEMO-003",
      email: "brian.otieno@gmail.com",
      phone_number: "0700000003",
      date_of_birth: ~D[1988-11-02],
      gender: "Male",
      home_address: "Kisumu"
    },
    doctor: doctor2,
    symptoms: "Suspected malaria, chills and headache",
    urgency: "High",
    report_complete: false,
    tests: [%{name: "Malaria RDT", price: 300}]
  },
  %{
    patient: %{
      first_name: "Faith",
      last_name: "Mwangi",
      national_id: "DEMO-004",
      email: "faith.mwangi@gmail.com",
      phone_number: "0700000004",
      date_of_birth: ~D[2023-08-15],
      gender: "Female",
      home_address: "Nakuru"
    },
    doctor: doctor,
    symptoms: "Routine urinalysis screening",
    urgency: "Medium",
    report_complete: true,
    tests: [%{name: "Urinalysis", price: 400}]
  },
  %{
    patient: %{
      first_name: "Peter",
      last_name: "Kamau",
      national_id: "DEMO-005",
      email: "peter.kamau@gmail.com",
      phone_number: "0700000005",
      date_of_birth: ~D[1975-06-20],
      gender: "Male",
      home_address: "Nairobi"
    },
    doctor: doctor2,
    symptoms: "Annual wellness check",
    urgency: "Low",
    report_complete: false,
    tests: [%{name: "Full Haemogram", price: 900}, %{name: "Malaria RDT", price: 300}]
  },
  %{
    patient: %{
      first_name: "Grace",
      last_name: "Nyambura",
      national_id: "DEMO-006",
      email: "grace.nyambura@gmail.com",
      phone_number: "0700000006",
      date_of_birth: ~D[2001-09-30],
      gender: "Female",
      home_address: "Thika"
    },
    doctor: doctor,
    symptoms: "Abdominal pain, suspected UTI",
    urgency: "Urgent",
    report_complete: true,
    tests: [%{name: "Urinalysis", price: 400}]
  }
]

Enum.each(lab_results_seed_data, fn seed ->
  patient_attrs =
    Map.merge(seed.patient, %{
      consent_agreement: true,
      patient_type: "outpatient",
      creator_id: admin.id,
      gsrn: Patients.get_available_gsrn(),
      pin: Enum.random(1000..9999)
    })

  patient =
    create_once.(
      Patient,
      %{national_id: seed.patient.national_id},
      Map.delete(patient_attrs, :national_id),
      fn attrs -> Patient.changeset(%Patient{}, attrs) |> Repo.insert() end,
      "patient #{seed.patient.first_name} #{seed.patient.last_name}"
    )

  doctor_note =
    create_once.(
      DoctorNote,
      %{patient_id: patient.id, doctor_id: seed.doctor.id},
      %{
        date: ~D[2026-06-29],
        symptoms: seed.symptoms,
        time: ~T[09:00:00]
      },
      &DoctorNotes.create_doctor_note/1,
      "doctor note for #{seed.patient.first_name} #{seed.patient.last_name}"
    )

  create_once.(
    LabResult,
    %{patient_id: patient.id, doctor_note_id: doctor_note.id},
    %{
      doctor_id: seed.doctor.id,
      urgency: seed.urgency,
      report_complete: seed.report_complete,
      tests: seed.tests
    },
    &LabResults.create_lab_result/1,
    "lab result for #{seed.patient.first_name} #{seed.patient.last_name}"
  )
end)

rooms = [
  %{
    room_number: "CONS-01",
    name: "Consultation Room 1",
    type: "consultation",
    description: "General outpatient consultation room"
  },
  %{
    room_number: "LAB-01",
    name: "Laboratory Room",
    type: "laboratory",
    description: "Sample collection and processing room"
  },
  %{
    room_number: "WARD-01",
    name: "General Ward Bed 1",
    type: "ward",
    description: "General inpatient ward bed"
  }
]

rooms_by_number =
  rooms
  |> Enum.map(fn attrs ->
    room =
      create_once.(
        Room,
        %{room_number: attrs.room_number},
        Map.merge(attrs, %{is_free: true, added_by: admin.id}),
        &Rooms.create_room/1,
        "room #{attrs.room_number}"
      )

    {attrs.room_number, room}
  end)
  |> Map.new()

supplier =
  create_once.(
    Supplier,
    %{email: "supplies@gmail.com"},
    %{
      name: "Demo Medical Supplies Ltd",
      contact: "0722000000",
      location: "Nairobi",
      description: "Development supplier for medical consumables",
      gln: "6163000000008"
    },
    &Suppliers.create_supplier/1,
    "demo supplier"
  )

supplier_user
|> Ecto.Changeset.change(supplier_id: supplier.id)
|> Repo.update!()

[
  %{name: "Consultation", description: "General outpatient consultation", price: 500},
  %{name: "Wound dressing", description: "Minor wound cleaning and dressing", price: 800},
  %{name: "Nebulization", description: "Nebulization treatment session", price: 700}
]
|> Enum.each(fn attrs ->
  create_once.(
    Procedure,
    %{name: attrs.name},
    Map.delete(attrs, :name),
    &Procedures.create_procedure/1,
    "procedure #{attrs.name}"
  )
end)

[
  %{
    name: "Full Haemogram",
    desription: "Complete blood count screening",
    price: 900,
    creator_id: admin.id
  },
  %{
    name: "Malaria RDT",
    desription: "Rapid malaria antigen test",
    price: 300,
    creator_id: admin.id
  },
  %{
    name: "Urinalysis",
    desription: "Routine urine chemistry and microscopy",
    price: 400,
    creator_id: admin.id
  }
]
|> Enum.each(fn attrs ->
  create_once.(
    LabTest,
    %{name: attrs.name},
    Map.delete(attrs, :name),
    &LabTests.create_lab_test/1,
    "lab test #{attrs.name}"
  )
end)

[
  %{
    name: "Chest X-Ray",
    description: "Plain chest radiograph",
    price: 1500,
    creator_id: admin.id
  },
  %{
    name: "Obstetric Ultrasound",
    description: "Routine obstetric ultrasound scan",
    price: 2500,
    creator_id: admin.id
  }
]
|> Enum.each(fn attrs ->
  create_once.(
    RadiologyTest,
    %{name: attrs.name},
    Map.delete(attrs, :name),
    &RadiologyTests.create_radiology_test/1,
    "radiology test #{attrs.name}"
  )
end)

haematology =
  create_once.(
    LabTestCategory,
    %{name: "Haematology"},
    %{description: "Blood count and morphology tests", display_order: 1},
    &LabTestTemplates.create_category/1,
    "lab category Haematology"
  )

chemistry =
  create_once.(
    LabTestCategory,
    %{name: "Chemistry"},
    %{description: "Routine clinical chemistry tests", display_order: 2},
    &LabTestTemplates.create_category/1,
    "lab category Chemistry"
  )

[
  %{
    name: "Full Haemogram Template",
    short_name: "FHG",
    description: "Common fields for a full haemogram result",
    category_id: haematology.id,
    display_order: 1,
    field_definitions: [
      %{
        name: "haemoglobin",
        label: "Haemoglobin",
        type: "number",
        unit: "g/dL",
        ref_range_text: "12.0-16.0",
        display_order: 1
      },
      %{
        name: "wbc",
        label: "White blood cells",
        type: "number",
        unit: "10^9/L",
        ref_range_text: "4.0-11.0",
        display_order: 2
      },
      %{
        name: "platelets",
        label: "Platelets",
        type: "number",
        unit: "10^9/L",
        ref_range_text: "150-400",
        display_order: 3
      }
    ]
  },
  %{
    name: "Random Blood Sugar Template",
    short_name: "RBS",
    description: "Single-field random blood sugar template",
    category_id: chemistry.id,
    display_order: 2,
    field_definitions: [
      %{
        name: "glucose",
        label: "Glucose",
        type: "number",
        unit: "mmol/L",
        ref_range_text: "3.9-7.8",
        display_order: 1
      }
    ]
  }
]
|> Enum.each(fn attrs ->
  create_once.(
    LabTestTemplate,
    %{name: attrs.name},
    Map.delete(attrs, :name),
    &LabTestTemplates.create_template/1,
    "lab template #{attrs.name}"
  )
end)

inventory_received =
  create_once.(
    InventoryReceived,
    %{gtin: "06163000000001"},
    %{
      brand_name: "Demo Paracetamol 500mg",
      generic_name: "Paracetamol",
      description: "Analgesic and antipyretic tablets",
      supplier: supplier.name,
      type: "drug",
      category: "Analgesics",
      strength: "500mg",
      uom: "tablets",
      weight: 100,
      room_id: rooms_by_number["LAB-01"].id,
      user_id: inventory_manager.id
    },
    &InventoriesReceived.create_inventory_received/1,
    "inventory received paracetamol"
  )

batch =
  create_once.(
    Batch,
    %{inventory_received_id: inventory_received.id, batch: "PCM-2026-A"},
    %{
      gtin: inventory_received.gtin,
      serial: "SER-DEMO-001",
      expiry: "2027-12-31",
      manufacture_date: ~D[2026-01-15],
      received_date: ~D[2026-06-29],
      manufacturer: "Demo Pharma",
      quantity: 100,
      remaining_quantity: 100,
      price_per_unit: 10,
      cost_per_unit: 6,
      uom: "tablet",
      weight: 0.5,
      supplier_id: supplier.id,
      inventory_manager_id: inventory_manager.id
    },
    &Batches.create_batch/1,
    "batch PCM-2026-A"
  )

drug =
  create_once.(
    Drug,
    %{inventory_received_id: inventory_received.id, brand_name: "Demo Paracetamol 500mg"},
    %{
      generic_name: "Paracetamol",
      inventory_manager_id: inventory_manager.id,
      is_otc: true,
      is_dangerous_drug: false
    },
    &Drugs.create_drug/1,
    "drug Demo Paracetamol 500mg"
  )

create_once.(
  DrugBatch,
  %{drug_id: drug.id, batch_id: batch.id},
  %{
    remaining_quantity: 100,
    inventory_manager_id: inventory_manager.id,
    inventory_received_id: inventory_received.id,
    is_confirmed: true,
    confirmed_by: inventory_manager.id,
    is_active: true
  },
  &DrugBatches.create_drug_batch/1,
  "drug batch Demo Paracetamol 500mg"
)

# ---------------------------------------------------------------------------
# Bulk data: enough rows per listing page to exercise pagination/filtering
# in the UI (each table default-paginates at 10-20 rows, so ~60 rows gives
# several pages without taking forever to seed).
# ---------------------------------------------------------------------------

first_names = ~w(
  James Mary John Patricia Robert Jennifer Michael Linda William Elizabeth
  David Barbara Richard Susan Joseph Jessica Thomas Sarah Charles Karen
  Wanjiku Otieno Njoroge Achieng Kiptoo Wafula Muthoni Odhiambo Chebet Kamau
  Akinyi Mwangi Njeri Omondi Wambui Kiprono Nyambura Wekesa Adhiambo Kariuki
)

last_names = ~w(
  Mwangi Otieno Wanjiru Kamau Njoroge Achieng Kiptoo Wafula Muthoni Odhiambo
  Chebet Kariuki Akinyi Njeri Omondi Wambui Kiprono Nyambura Wekesa Adhiambo
  Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez
)

genders = ["Male", "Female"]
counties = ~w(Nairobi Kisumu Nakuru Mombasa Eldoret Thika Kitale Machakos Meru Nyeri)
urgencies = ["Low", "Medium", "High", "Urgent"]
payment_types = ["cash", "insurance", "mpesa"]
visit_types = ["outpatient", "inpatient", "MCH", "referral in", "referral out"]

random_date = fn days_back ->
  Date.add(Date.utc_today(), -Enum.random(0..days_back))
end

random_time = fn ->
  Time.new!(Enum.random(7..18), Enum.random(0..59), 0)
end

bulk_patients =
  for i <- 1..60 do
    first = Enum.random(first_names)
    last = Enum.random(last_names)

    create_once.(
      Patient,
      %{national_id: "BULK-#{String.pad_leading(Integer.to_string(i), 4, "0")}"},
      %{
        first_name: first,
        last_name: last,
        email: "#{String.downcase(first)}.#{String.downcase(last)}.#{i}@gmail.com",
        phone_number: "07#{Enum.random(10_000_000..99_999_999)}",
        date_of_birth: Date.add(Date.utc_today(), -Enum.random(365..29_200)),
        gender: Enum.random(genders),
        home_address: Enum.random(counties),
        emergency_contact_name: "#{Enum.random(first_names)} #{Enum.random(last_names)}",
        emergency_contact_phone_number: "07#{Enum.random(10_000_000..99_999_999)}",
        emergency_contact_relationship: Enum.random(["Spouse", "Parent", "Sibling", "Friend"]),
        consent_agreement: true,
        patient_type: Enum.random(["outpatient", "inpatient"]),
        creator_id: admin.id,
        gsrn: Patients.get_available_gsrn(),
        pin: Enum.random(1000..9999)
      },
      fn attrs -> Patient.changeset(%Patient{}, attrs) |> Repo.insert() end,
      "bulk patient ##{i}"
    )
  end

bulk_doctors = [doctor, doctor2]

bulk_visits =
  for {patient, i} <- Enum.with_index(bulk_patients, 1) do
    create_once.(
      PatientVisit,
      %{patient_id: patient.id, reason: "Bulk seeded visit ##{i}"},
      %{
        date: random_date.(120),
        creator_id: admin.id,
        doctor_id: Enum.random(bulk_doctors).id,
        payment_type: Enum.random(payment_types),
        visit_type: Enum.random(visit_types),
        total_amount_paid: Enum.random([0, 300, 500, 900, 1500]),
        has_paid: Enum.random([true, false])
      },
      &PatientVisits.create_patient_visit/1,
      "bulk visit ##{i}"
    )
  end

bulk_doctor_notes =
  for {{patient, visit}, i} <- Enum.zip(bulk_patients, bulk_visits) |> Enum.with_index(1) do
    create_once.(
      DoctorNote,
      %{patient_id: patient.id, patient_visit_id: visit.id},
      %{
        doctor_id: Enum.random(bulk_doctors).id,
        date: visit.date,
        time: random_time.(),
        symptoms:
          Enum.random([
            "Fever and headache",
            "Persistent cough",
            "Abdominal pain",
            "Joint pain and swelling",
            "Skin rash",
            "Routine antenatal checkup",
            "Follow-up review",
            "Shortness of breath",
            "Dizziness and fatigue",
            "Sore throat"
          ]),
        diagnosis:
          Enum.random([
            "Upper respiratory tract infection",
            "Malaria",
            "Hypertension",
            "Type 2 diabetes",
            "Gastritis",
            "Urinary tract infection",
            nil
          ])
      },
      &DoctorNotes.create_doctor_note/1,
      "bulk doctor note ##{i}"
    )
  end

lab_test_catalog = [
  %{name: "Full Haemogram", price: 900},
  %{name: "Malaria RDT", price: 300},
  %{name: "Urinalysis", price: 400},
  %{name: "Liver Function Test", price: 1200},
  %{name: "Renal Function Test", price: 1100},
  %{name: "Lipid Profile", price: 1000},
  %{name: "Random Blood Sugar", price: 250},
  %{name: "Widal Test", price: 500}
]

Enum.zip(bulk_patients, bulk_doctor_notes)
|> Enum.with_index(1)
|> Enum.each(fn {{patient, doctor_note}, i} ->
  # Only ~two-thirds of visits produce a lab result, mirroring real usage.
  if rem(i, 3) != 0 do
    create_once.(
      LabResult,
      %{patient_id: patient.id, doctor_note_id: doctor_note.id},
      %{
        doctor_id: doctor_note.doctor_id,
        urgency: Enum.random(urgencies),
        report_complete: Enum.random([true, false]),
        tests: Enum.take_random(lab_test_catalog, Enum.random(1..2))
      },
      &LabResults.create_lab_result/1,
      "bulk lab result ##{i}"
    )
  end
end)

bulk_appointments =
  for {patient, i} <- Enum.with_index(bulk_patients, 1) do
    create_once.(
      Appointment,
      %{patient_id: patient.id, reason: "Bulk seeded appointment ##{i}"},
      %{
        date: Date.add(Date.utc_today(), Enum.random(-30..30)),
        time: random_time.(),
        doctor_id: Enum.random(bulk_doctors).id
      },
      &Appointments.create_appointment/1,
      "bulk appointment ##{i}"
    )
  end

bulk_rooms =
  for i <- 1..40 do
    type = Enum.random(["consultation", "laboratory", "ward", "theatre", "radiology"])

    create_once.(
      Room,
      %{room_number: "BULK-#{type |> String.slice(0, 3) |> String.upcase()}-#{i}"},
      %{
        name: "#{String.capitalize(type)} Room #{i}",
        type: type,
        description: "Seeded #{type} room for pagination testing",
        is_free: Enum.random([true, false]),
        added_by: admin.id
      },
      &Rooms.create_room/1,
      "bulk room ##{i}"
    )
  end

bulk_procedures =
  for i <- 1..30 do
    create_once.(
      Procedure,
      %{name: "Bulk Procedure #{i}"},
      %{
        description: "Seeded procedure ##{i} for pagination testing",
        price: Enum.random([300, 500, 700, 900, 1200, 1500])
      },
      &Procedures.create_procedure/1,
      "bulk procedure ##{i}"
    )
  end

bulk_radiology_tests =
  for i <- 1..25 do
    create_once.(
      RadiologyTest,
      %{name: "Bulk Radiology Test #{i}"},
      %{
        description: "Seeded radiology test ##{i} for pagination testing",
        price: Enum.random([800, 1200, 1500, 2000, 2500]),
        creator_id: admin.id
      },
      &RadiologyTests.create_radiology_test/1,
      "bulk radiology test ##{i}"
    )
  end

bulk_suppliers =
  for i <- 1..25 do
    create_once.(
      Supplier,
      %{email: "bulk.supplier#{i}@gmail.com"},
      %{
        name: "Bulk Supplier Ltd #{i}",
        contact: "07#{Enum.random(10_000_000..99_999_999)}",
        location: Enum.random(counties),
        description: "Seeded supplier ##{i} for pagination testing",
        gln: "616300000#{String.pad_leading(Integer.to_string(i), 4, "0")}"
      },
      &Suppliers.create_supplier/1,
      "bulk supplier ##{i}"
    )
  end

drug_catalog = [
  {"Amoxicillin 500mg", "Amoxicillin"},
  {"Paracetamol 500mg", "Paracetamol"},
  {"Metformin 850mg", "Metformin"},
  {"Amlodipine 5mg", "Amlodipine"},
  {"Ibuprofen 400mg", "Ibuprofen"},
  {"Omeprazole 20mg", "Omeprazole"},
  {"Ciprofloxacin 500mg", "Ciprofloxacin"},
  {"Losartan 50mg", "Losartan"}
]

bulk_inventory_received =
  for i <- 1..40 do
    {brand, generic} = Enum.random(drug_catalog)
    supplier = Enum.random(bulk_suppliers)

    create_once.(
      InventoryReceived,
      %{gtin: "0616300#{String.pad_leading(Integer.to_string(i), 7, "0")}"},
      %{
        brand_name: "#{brand} (Batch #{i})",
        generic_name: generic,
        description: "Seeded inventory item ##{i} for pagination testing",
        supplier: supplier.name,
        type: "drug",
        category:
          Enum.random(["Analgesics", "Antibiotics", "Antihypertensives", "Antidiabetics"]),
        strength: Enum.random(["250mg", "500mg", "850mg", "5mg", "20mg"]),
        uom: "tablets",
        weight: Enum.random(50..500),
        room_id: Enum.random(bulk_rooms).id,
        user_id: inventory_manager.id
      },
      &InventoriesReceived.create_inventory_received/1,
      "bulk inventory received ##{i}"
    )
  end

bulk_batches =
  for {inv, i} <- Enum.with_index(bulk_inventory_received, 1) do
    qty = Enum.random(50..500)

    create_once.(
      Batch,
      %{inventory_received_id: inv.id, batch: "BULK-BATCH-#{i}"},
      %{
        gtin: inv.gtin,
        serial: "SER-BULK-#{i}",
        expiry: Date.add(Date.utc_today(), Enum.random(90..730)) |> Date.to_iso8601(),
        manufacture_date: Date.add(Date.utc_today(), -Enum.random(30..365)),
        received_date: random_date.(180),
        manufacturer: "Seeded Pharma #{rem(i, 5) + 1}",
        quantity: qty,
        remaining_quantity: qty,
        price_per_unit: Enum.random(5..50),
        cost_per_unit: Enum.random(2..30),
        uom: "tablet",
        weight: Enum.random(1..10) / 10,
        supplier_id:
          (Enum.find(bulk_suppliers, fn s -> s.name == inv.supplier end) ||
             List.first(bulk_suppliers)).id,
        inventory_manager_id: inventory_manager.id
      },
      &Batches.create_batch/1,
      "bulk batch ##{i}"
    )
  end

bulk_drugs =
  for {inv, i} <- Enum.with_index(bulk_inventory_received, 1) do
    create_once.(
      Drug,
      %{inventory_received_id: inv.id, brand_name: inv.brand_name},
      %{
        generic_name: inv.generic_name,
        inventory_manager_id: inventory_manager.id,
        is_otc: Enum.random([true, false]),
        is_dangerous_drug: false
      },
      &Drugs.create_drug/1,
      "bulk drug ##{i}"
    )
  end

Enum.zip([bulk_drugs, bulk_batches, bulk_inventory_received])
|> Enum.with_index(1)
|> Enum.each(fn {{drug, batch, inv}, i} ->
  create_once.(
    DrugBatch,
    %{drug_id: drug.id, batch_id: batch.id},
    %{
      remaining_quantity: batch.remaining_quantity,
      inventory_manager_id: inventory_manager.id,
      inventory_received_id: inv.id,
      is_confirmed: true,
      confirmed_by: inventory_manager.id,
      is_active: true
    },
    &DrugBatches.create_drug_batch/1,
    "bulk drug batch ##{i}"
  )
end)

# -----------------------------------------------------------------------
# Authorization (RBAC pilot) - see docs/RBAC_ACCESS_CONTROL_PLAN.md.
# Seeded so that, immediately after this runs, every role's *effective*
# access is identical to what the existing role-string plugs already give
# it today - this is additive scaffolding, not a behavior change.
# -----------------------------------------------------------------------
alias Medcamp.Authorization
alias Medcamp.Authorization.Permission

pilot_permissions = [
  %{
    slug: "doctor.procedures",
    description: "View and manage doctor procedures",
    resource_area: "doctor_procedures"
  },
  %{
    slug: "admin.audit_logs",
    description: "View the system audit log",
    resource_area: "audit_logs"
  },
  %{
    slug: "admin.users",
    description: "Manage user accounts and roles",
    resource_area: "users"
  }
]

permissions_by_slug =
  Map.new(pilot_permissions, fn attrs ->
    permission =
      create_once.(
        Permission,
        %{slug: attrs.slug},
        attrs,
        &Authorization.create_permission/1,
        "permission #{attrs.slug}"
      )

    {attrs.slug, permission}
  end)

# Reproduces today's access exactly: only the role that currently owns
# each pilot route gets the matching permission by default.
[
  {"doctor", "doctor.procedures"},
  {"admin", "admin.audit_logs"},
  {"admin", "admin.users"}
]
|> Enum.each(fn {role, slug} ->
  Authorization.grant_role_permission(role, slug, admin)
end)

IO.puts(
  "Authorization pilot: seeded #{map_size(permissions_by_slug)} permissions and their role defaults."
)

IO.puts("""

Bulk data seeded:
- #{length(bulk_patients)} patients, visits, doctor notes, and appointments
- #{length(bulk_rooms)} rooms
- #{length(bulk_procedures)} procedures
- #{length(bulk_radiology_tests)} radiology tests
- #{length(bulk_suppliers)} suppliers
- #{length(bulk_inventory_received)} inventory received / batches / drugs / drug batches
""")

IO.puts("""

Seed complete.

Created or confirmed:
- #{map_size(departments_by_code)} departments
- #{length(seed_users)} demo users
- 1 demo patient (#{demo_patient.first_name} #{demo_patient.last_name}) and visit ##{demo_visit.id}
- #{length(rooms)} rooms
- 1 supplier
- procedure, lab, radiology, lab-template, and pharmacy starter data

Log in with:
- admin@gmail.com / #{password}
- doctor@gmail.com / #{password}
- nurse@gmail.com / #{password}
- reception@gmail.com / #{password}
- procurement@gmail.com / #{password}
- supplier@gmail.com / #{password}

PINs for the seeded accounts are listed in README.md.
""")
