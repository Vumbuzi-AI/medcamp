# Demo data for exercising table pagination in dev.
#
# Additive and idempotent: safe to run repeatedly, never deletes anything.
# Requires the base seeds first (mix run priv/repo/seeds.exs).
#
#     mix run priv/repo/pagination_demo_seeds.exs

alias Medcamp.Accounts
alias Medcamp.Appointments
alias Medcamp.Appointments.Appointment
alias Medcamp.Batches
alias Medcamp.Batches.Batch
alias Medcamp.DangerousDrugRegisters
alias Medcamp.DangerousDrugRegisters.Register
alias Medcamp.DrugBatches
alias Medcamp.DrugBatches.DrugBatch
alias Medcamp.Drugs
alias Medcamp.Drugs.Drug
alias Medcamp.InventoriesReceived
alias Medcamp.InventoriesReceived.InventoryReceived
alias Medcamp.LabAllocations
alias Medcamp.LabAllocations.LabAllocation
alias Medcamp.NurseNotes
alias Medcamp.NurseNotes.NurseNote
alias Medcamp.NurseProcedures
alias Medcamp.NurseProcedures.NurseProcedure
alias Medcamp.Nursing
alias Medcamp.NursingAllocations.NursingAllocation
alias Medcamp.PatientVisits
alias Medcamp.PatientVisits.PatientVisit
alias Medcamp.Patients
alias Medcamp.Patients.Patient
alias Medcamp.Procedures.Procedure
alias Medcamp.Repo
alias Medcamp.RoomAllocations
alias Medcamp.RoomAllocations.RoomAllocation
alias Medcamp.Rooms.Room
alias Medcamp.ShiftHandovers
alias Medcamp.ShiftHandovers.ShiftHandover
alias Medcamp.StockTakes
alias Medcamp.StockTakes.StockTake
alias Medcamp.Suppliers.Supplier
alias Medcamp.Visitors
alias Medcamp.Visitors.VisitorBookEntry

today = ~D[2026-07-05]

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

require_user! = fn email ->
  Accounts.get_user_by_email(email) ||
    raise "Missing #{email} — run `mix run priv/repo/seeds.exs` first"
end

admin = require_user!.("admin@example.com")
doctor = require_user!.("doctor@example.com")
nurse = require_user!.("nurse@example.com")
reception = require_user!.("reception@example.com")
lab_tech = require_user!.("lab@example.com")
pharmacist = require_user!.("pharmacist@example.com")
inventory_manager = require_user!.("inventory@example.com")

supplier =
  Repo.get_by(Supplier, email: "supplies@example.com") ||
    raise "Missing demo supplier — run `mix run priv/repo/seeds.exs` first"

rooms = Repo.all(Room)
if rooms == [], do: raise("No rooms found — run `mix run priv/repo/seeds.exs` first")

procedures = Repo.all(Procedure)
if procedures == [], do: raise("No procedures found — run `mix run priv/repo/seeds.exs` first")

store_room = Repo.get_by(Room, room_number: "LAB-01") || hd(rooms)

# ---------------------------------------------------------------------------
# Patients (15)
# ---------------------------------------------------------------------------

first_names = ~w(Wanjiku Otieno Achieng Kamau Njeri Mutua Chebet Kiptoo Amina Baraka Zawadi Juma Nyambura Odhiambo Wafula)
last_names = ~w(Kariuki Omondi Adhiambo Mwangi Wambui Musyoka Rono Sang Hassan Mwita Njoroge Owino Gathoni Okoth Simiyu)

patients =
  Enum.map(1..15, fn i ->
    national_id = "DEMO-P" <> String.pad_leading("#{i}", 3, "0")

    case Repo.get_by(Patient, national_id: national_id) do
      nil ->
        %Patient{}
        |> Patient.changeset(%{
          first_name: Enum.at(first_names, i - 1),
          middle_name: "Demo",
          last_name: Enum.at(last_names, i - 1),
          national_id: national_id,
          email: "demo.patient#{i}@example.com",
          phone_number: "07000010#{String.pad_leading("#{i}", 2, "0")}",
          date_of_birth: Date.add(~D[1985-01-01], i * 211),
          gender: if(rem(i, 2) == 0, do: "Male", else: "Female"),
          home_address: "Kisumu",
          emergency_contact_name: "Contact #{i} Demo",
          emergency_contact_phone_number: "07110010#{String.pad_leading("#{i}", 2, "0")}",
          emergency_contact_relationship: "Sibling",
          consent_agreement: true,
          patient_type: "outpatient",
          creator_id: reception.id,
          gsrn: Patients.get_available_gsrn(),
          pin: 5000 + i
        })
        |> Repo.insert!()

      patient ->
        patient
    end
  end)

patient_at = fn i -> Enum.at(patients, rem(i, length(patients))) end

# ---------------------------------------------------------------------------
# Patient visits (30) — some insurance, spread over the last 3 weeks
# ---------------------------------------------------------------------------

visit_reasons = [
  "Fever and headache",
  "Follow-up review",
  "Abdominal pain",
  "Hypertension check",
  "Antenatal visit",
  "Minor injury"
]

insurers = ["NHIF", "Jubilee", "Britam"]

Enum.each(1..30, fn i ->
  patient = patient_at.(i)
  insurance? = rem(i, 3) == 0

  create_once.(
    PatientVisit,
    %{
      patient_id: patient.id,
      reason: Enum.at(visit_reasons, rem(i, 6)),
      date: Date.add(today, -rem(i, 21))
    },
    %{
      creator_id: reception.id,
      doctor_id: doctor.id,
      payment_type: if(insurance?, do: "insurance", else: "cash"),
      insurance_name: if(insurance?, do: Enum.at(insurers, rem(i, 3))),
      visit_type: "outpatient",
      total_amount_paid: 500,
      has_paid: rem(i, 2) == 0
    },
    &PatientVisits.create_patient_visit/1,
    "patient visit #{i}"
  )
end)

# ---------------------------------------------------------------------------
# Appointments (25)
# ---------------------------------------------------------------------------

appointment_reasons = [
  "Consultation",
  "Review of lab results",
  "Medication refill",
  "Physiotherapy session",
  "Vaccination"
]

Enum.each(1..25, fn i ->
  create_once.(
    Appointment,
    %{
      patient_id: patient_at.(i).id,
      date: Date.add(today, rem(i, 10) - 5),
      reason: Enum.at(appointment_reasons, rem(i, 5))
    },
    %{
      time: Time.new!(8 + rem(i, 8), 0, 0),
      doctor_id: doctor.id
    },
    &Appointments.create_appointment/1,
    "appointment #{i}"
  )
end)

# ---------------------------------------------------------------------------
# Lab + nursing allocations (25 each)
# ---------------------------------------------------------------------------

uoms = ~w(pcs ml box)

Enum.each(1..25, fn i ->
  create_once.(
    LabAllocation,
    %{allocated_to: lab_tech.id, expiry_date: Date.add(~D[2027-01-01], i)},
    %{
      allocated_quantity: 40 + i,
      remaining_quantity: 20 + i,
      uom: Enum.at(uoms, rem(i, 3)),
      allocated_by: inventory_manager.id
    },
    &LabAllocations.create_lab_allocation/1,
    "lab allocation #{i}"
  )

  create_once.(
    NursingAllocation,
    %{allocated_to: nurse.id, expiry_date: Date.add(~D[2027-02-01], i)},
    %{
      allocated_quantity: 40 + i,
      remaining_quantity: 20 + i,
      uom: Enum.at(uoms, rem(i, 3)),
      allocated_by: inventory_manager.id
    },
    &Nursing.create_nursing_allocation/1,
    "nursing allocation #{i}"
  )
end)

# ---------------------------------------------------------------------------
# Room allocations (25)
# ---------------------------------------------------------------------------

Enum.each(1..25, fn i ->
  create_once.(
    RoomAllocation,
    %{
      patient_id: patient_at.(i).id,
      room_id: Enum.at(rooms, rem(i, length(rooms))).id,
      start_date: Date.add(today, -i)
    },
    %{
      end_date: Date.add(today, -i + 2),
      nurse_id: nurse.id,
      payment_type: "cash",
      total_amount_paid: 1000,
      has_paid: rem(i, 2) == 0
    },
    &RoomAllocations.create_room_allocation/1,
    "room allocation #{i}"
  )
end)

# ---------------------------------------------------------------------------
# Nurse notes (25) and nurse procedures (15)
# ---------------------------------------------------------------------------

Enum.each(1..25, fn i ->
  create_once.(
    NurseNote,
    %{
      nurse_id: nurse.id,
      content: "Demo note #{i}: routine observations recorded, patient stable."
    },
    %{patient_id: patient_at.(i).id},
    &NurseNotes.create_nurse_note/1,
    "nurse note #{i}"
  )
end)

Enum.each(1..15, fn i ->
  procedure = Enum.at(procedures, rem(i, length(procedures)))

  create_once.(
    NurseProcedure,
    %{patient_id: patient_at.(i).id, procedure_id: procedure.id},
    %{
      nurse_id: nurse.id,
      payment_type: "cash",
      has_paid: true,
      total_amount_paid: procedure.price
    },
    &NurseProcedures.create_nurse_procedure/1,
    "nurse procedure #{i}"
  )
end)

# ---------------------------------------------------------------------------
# Visitor book entries (25) — string keys: the changeset injects string-keyed
# visit defaults, so atom keys here would produce a mixed-key map
# ---------------------------------------------------------------------------

Enum.each(1..25, fn i ->
  name = "Demo Visitor #{i}"

  case Repo.get_by(VisitorBookEntry, visitor_name: name) do
    nil ->
      unwrap!.(
        Visitors.create_visitor_book_entry(%{
          "visitor_name" => name,
          "phone_number" => "07220020#{String.pad_leading("#{i}", 2, "0")}",
          "person_to_see" => "Administrator",
          "purpose" => "Official visit",
          "message" => "Demo visitor book entry #{i} for pagination testing.",
          "visited_on" => Date.to_iso8601(Date.add(today, -rem(i, 14))),
          "visited_at" => "#{String.pad_leading("#{8 + rem(i, 9)}", 2, "0")}:30",
          "user_id" => reception.id
        }),
        "visitor entry #{i}"
      )

    entry ->
      entry
  end
end)

# ---------------------------------------------------------------------------
# Stock takes (12) and shift handovers (15)
# ---------------------------------------------------------------------------

Enum.each(1..12, fn i ->
  create_once.(
    StockTake,
    %{date: Date.add(today, -i), admin_id: admin.id},
    %{
      status: if(i <= 6, do: "completed", else: "draft"),
      notes: "Demo stock take #{i}"
    },
    &StockTakes.create_stock_take/1,
    "stock take #{i}"
  )
end)

departments = ["Nursing", "Pharmacy", "Laboratory"]

Enum.each(1..15, fn i ->
  create_once.(
    ShiftHandover,
    %{shift_date: Date.add(today, -i), department: Enum.at(departments, rem(i, 3))},
    %{
      shift_start: Date.add(today, -i),
      shift_type: if(rem(i, 2) == 0, do: "day", else: "night"),
      handover_from: "Nurse Brian Demo",
      handover_to: "Nurse Alice Demo",
      patient_count: rem(i, 20) + 1,
      admissions: rem(i, 4),
      discharges: rem(i, 3),
      pending_tasks: "Demo pending tasks #{i}",
      notes: "Demo shift handover #{i}"
    },
    &ShiftHandovers.create_shift_handover/1,
    "shift handover #{i}"
  )
end)

# ---------------------------------------------------------------------------
# Drugs (24, half dangerous) + batches, pending batches, DDA registers
# ---------------------------------------------------------------------------

drug_names = ~w(Amoxicillin Ibuprofen Metformin Omeprazole Cetirizine Diazepam Morphine Tramadol Codeine Pethidine Amitriptyline Salbutamol)
categories = ["Analgesics", "Antibiotics", "Antihistamines"]

dda_drugs =
  Enum.reduce(1..24, [], fn i, acc ->
    generic = Enum.at(drug_names, rem(i - 1, 12))
    strength = if(i <= 12, do: "250mg", else: "500mg")
    brand = "Demo #{generic} #{strength}"
    gtin = "0616300000" <> String.pad_leading("#{100 + i}", 4, "0")
    dangerous? = rem(i, 2) == 0

    inventory_received =
      create_once.(
        InventoryReceived,
        %{gtin: gtin},
        %{
          brand_name: brand,
          generic_name: generic,
          description: "Demo #{generic} for pagination testing",
          supplier: supplier.name,
          type: "drug",
          category: Enum.at(categories, rem(i, 3)),
          strength: strength,
          uom: "tablets",
          weight: 100,
          room_id: store_room.id,
          user_id: inventory_manager.id
        },
        &InventoriesReceived.create_inventory_received/1,
        "inventory received #{brand}"
      )

    batch =
      create_once.(
        Batch,
        %{inventory_received_id: inventory_received.id, batch: "DEMO-B-#{i}"},
        %{
          gtin: gtin,
          serial: "SER-DEMO-#{100 + i}",
          expiry: "2027-12-31",
          manufacture_date: ~D[2026-01-15],
          received_date: Date.add(today, -i),
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
        "batch DEMO-B-#{i}"
      )

    drug =
      create_once.(
        Drug,
        %{inventory_received_id: inventory_received.id, brand_name: brand},
        %{
          generic_name: generic,
          inventory_manager_id: inventory_manager.id,
          is_otc: not dangerous?,
          is_dangerous_drug: dangerous?
        },
        &Drugs.create_drug/1,
        "drug #{brand}"
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
      "drug batch #{brand}"
    )

    # A second, unconfirmed batch per early drug feeds the pending-batches view
    if i <= 12 do
      pending_batch =
        create_once.(
          Batch,
          %{inventory_received_id: inventory_received.id, batch: "DEMO-PEND-#{i}"},
          %{
            gtin: gtin,
            serial: "SER-DEMO-PEND-#{100 + i}",
            expiry: "2028-06-30",
            manufacture_date: ~D[2026-05-01],
            received_date: today,
            manufacturer: "Demo Pharma",
            quantity: 50,
            remaining_quantity: 50,
            price_per_unit: 10,
            cost_per_unit: 6,
            uom: "tablet",
            weight: 0.5,
            supplier_id: supplier.id,
            inventory_manager_id: inventory_manager.id
          },
          &Batches.create_batch/1,
          "pending batch DEMO-PEND-#{i}"
        )

      create_once.(
        DrugBatch,
        %{drug_id: drug.id, batch_id: pending_batch.id},
        %{
          remaining_quantity: 50,
          inventory_manager_id: inventory_manager.id,
          inventory_received_id: inventory_received.id,
          is_confirmed: false,
          is_active: true
        },
        &DrugBatches.create_drug_batch/1,
        "pending drug batch #{brand}"
      )
    end

    if dangerous?, do: [drug | acc], else: acc
  end)

Enum.each(dda_drugs, fn drug ->
  Enum.each([6, 7], fn month ->
    create_once.(
      Register,
      %{drug_id: drug.id, month: month, year: 2026},
      %{created_by_id: pharmacist.id},
      &DangerousDrugRegisters.create_register/1,
      "DDA register drug=#{drug.id} #{month}/2026"
    )
  end)
end)

IO.puts("""

Pagination demo seed complete. Created or confirmed:
- 15 patients, 30 visits, 25 appointments
- 25 lab / 25 nursing / 25 room allocations
- 25 nurse notes, 15 nurse procedures
- 25 visitor book entries, 12 stock takes, 15 shift handovers
- 24 drugs (12 dangerous) with batches, 12 pending drug batches, DDA registers

Run again any time — it only fills in what is missing.
""")
