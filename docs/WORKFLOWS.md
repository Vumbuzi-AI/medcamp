# Workflows

## The camp flow

One patient, one pass through the camp. There is no payment step anywhere.

```
nurse registers patient ──▶ visit created automatically (triage_pending)
                                      │
                            nurse triages  ──▶ triaged
                                      │
                        doctor writes note ──▶ with_doctor
                                      │
                    ┌─────────────────┴─────────────────┐
        doctor requests labs                doctor prescribes drugs
              lab_pending                      pharmacy_pending
                    │                                   │
        lab fills results                 pharmacist dispenses ──▶ completed
```

`status` lives on `patient_visits`. Every role queue is "today's visits at
status X" (`Medcamp.PatientVisits.list_queue/2`), and the only way a visit
reaches a status is a transition function on the same context — so a queue
and the step that feeds it cannot drift apart.

Transitions are applied by `Medcamp.CampFlow.advance/2`, called from the
clinical contexts rather than from LiveViews, so any caller that records the
work also moves the patient. Advancing is best-effort: if a patient has no
open visit, the clinical record is still saved.

## 1. Registration (nurse)

`Medcamp.Patients.register_for_camp/2` inserts the patient and their visit in
one transaction. Registering *is* joining the queue — there is no separate
"create visit" screen, and a failed registration leaves neither record
behind. The patient is assigned a GSRN and a PIN, and the PIN is texted to
them.

## 2. Triage (nurse)

`/nurse/triages/new`, or per patient at `/nurse/:patient_id/triages/new`.
Records temperature, BP, pulse, SpO₂, height/weight/BMI, allergies and an
emergency scale. Saving advances the visit to `triaged`.

## 3. Consultation (doctor)

The doctor scans the patient at `/doctor/scan` or picks them off
`/doctor/pending_patient_visits`, then writes a note at
`/doctor/patients/:id/notes/new`. The note supports ICD-coded diagnosis, AI
review and voice dictation. From the note's show page there are exactly two
onward actions:

* **Request lab** — `MedcampWeb.RequestLabComponent`, select tests + urgency.
* **Prescribe drug** — `MedcampWeb.PrescribeMedicineComponent`, select drugs,
  quantities, frequency and duration.

## 4. Lab

The request appears at `/lab/lab_results`. The technician adds templated
tests, fills in entries, and marks the report complete. Results are visible
back on the doctor's note under the Lab Work tab.

## 5. Pharmacy

### Stocking

1. **Add a drug** — `/pharmacist/drugs`. Creates the item-master row
   (`inventories_received`, keyed by GTIN) and the drug.
2. **Add a batch** — `/pharmacist/pending_drug_batches/new`. Key in what is
   printed on the pack: GTIN, batch/lot, expiry, quantity.
   `Medcamp.DrugBatches.take_in_batch/1` writes the `batch` and `drug_batch`
   in one transaction, unconfirmed.
3. **Confirm by scan** — `/pharmacist/pending_drug_batches/:id/scan`. Scanning
   the pack's GS1 DataMatrix parses out GTIN and batch and matches them
   against what was keyed in. Only a match confirms the batch, and only
   confirmed batches can be dispensed from — so a mis-keyed batch is caught
   at the shelf rather than at the patient.

### Dispensing

The prescription appears at `/pharmacist/drug_allocations`. The pharmacist
picks the drugs, scans each pack out (`/api/drug_allocations/scan_verify`,
`/api/drugs_given_scan_out`), then confirms. Confirming marks the allocation
dispensed and closes the visit as `completed`.

## Administration

The admin sees all of the above plus camp reporting and exports at
`/admin/medical_camp`, drug movement from batch intake through scan-out to
patient, users and per-panel permissions, login sessions and the audit trail.
