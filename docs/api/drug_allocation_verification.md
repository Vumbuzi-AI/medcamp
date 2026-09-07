# Drug Allocation Verification API

API for checking and verifying batch allocations when dispensing drugs. Use these endpoints to integrate scanners or external systems with the same “check then verify” flow as the pharmacy UI (Batch Allocations → Scan to Verify).

**Base URL:** `https://your-host/api` (e.g. `http://localhost:4000/api`)

**Content-Type:** All requests and responses use `application/json`.

---

## 1. Check to verify

Determines whether a given GTIN and batch number have a **pending** (unverified) allocation that can be verified. Does not change any data. Use this before calling scan_verify (e.g. to show the user what will be verified or to validate the scan).

### Endpoint

```
POST /api/drug_allocations/check_verify
```

### Request body

| Field   | Type   | Required | Description                                      |
|---------|--------|----------|--------------------------------------------------|
| `gtin`  | string | Yes      | GTIN of the product (e.g. 14 digits).           |
| `batch` | string | Yes      | Batch/lot number (e.g. `"678"`, `"Batch #678"`). |

### Example request

```bash
curl -X POST "https://your-host/api/drug_allocations/check_verify" \
  -H "Content-Type: application/json" \
  -d '{"gtin": "06123456789012", "batch": "678"}'
```

### Responses

**200 OK – Batch found, pending allocation exists (`can_verify: true`)**

```json
{
  "ok": true,
  "can_verify": true,
  "batch": {
    "id": 123,
    "batch": "678",
    "gtin": "06123456789012",
    "expiry": "2025-06-27"
  },
  "drug_given_id": 456,
  "drug_allocation_id": 789,
  "drug_name": "Paracetamol 500mg",
  "allocation": {
    "quantity": 1,
    "unit_price": 20,
    "is_verified": false
  }
}
```

**200 OK – Batch found, no pending allocation (`can_verify: false`)**

```json
{
  "ok": true,
  "can_verify": false,
  "message": "No pending allocation found for this batch",
  "batch": {
    "id": 123,
    "batch": "678",
    "gtin": "06123456789012",
    "expiry": "2025-06-27"
  }
}
```

**404 Not Found – No batch for this GTIN + batch**

```json
{
  "ok": false,
  "error": "Batch not found for the given GTIN and batch number"
}
```

**400 Bad Request – Missing or invalid body**

```json
{
  "ok": false,
  "error": "Missing or invalid body: require \"gtin\" and \"batch\" (strings)"
}
```

---

## 2. Scan to verify

Marks the **pending** batch allocation for the given GTIN and batch as verified. Same effect as using “Scan to Verify” and “Verify Batch” on the drug allocation show page. You can send either `gtin` + `batch` or a full `datamatrix` string (e.g. from a 2D barcode scanner).

### Endpoint

```
POST /api/drug_allocations/scan_verify
```

### Request body (option A – GTIN and batch)

| Field   | Type   | Required | Description                        |
|---------|--------|----------|------------------------------------|
| `gtin`  | string | Yes*     | GTIN of the product.               |
| `batch` | string | Yes*     | Batch/lot number.                  |

*Required when not using `datamatrix`.

### Request body (option B – Datamatrix)

| Field        | Type   | Required | Description                                      |
|--------------|--------|----------|--------------------------------------------------|
| `datamatrix` | string | Yes*     | Full datamatrix string (e.g. GS1; GTIN + batch). |

*Required when not using `gtin` and `batch`. GTIN and batch are parsed from the string.

### Example requests

**Using GTIN and batch:**

```bash
curl -X POST "https://your-host/api/drug_allocations/scan_verify" \
  -H "Content-Type: application/json" \
  -d '{"gtin": "06123456789012", "batch": "678"}'
```

**Using datamatrix (e.g. from scanner):**

```bash
curl -X POST "https://your-host/api/drug_allocations/scan_verify" \
  -H "Content-Type: application/json" \
  -d '{"datamatrix": "010612345678901210678..."}'
```

### Responses

**200 OK – Verification succeeded**

```json
{
  "ok": true,
  "message": "Batch allocation verified successfully",
  "drug_given_id": 456,
  "drug_allocation_id": 789
}
```

**404 Not Found – Batch not found**

```json
{
  "ok": false,
  "error": "Batch not found for the given GTIN and batch number"
}
```

**404 Not Found – No pending allocation for this batch**

```json
{
  "ok": false,
  "error": "No pending allocation found for this batch"
}
```

**400 Bad Request – Invalid or missing body**

```json
{
  "ok": false,
  "error": "Missing body: provide \"gtin\" and \"batch\", or \"datamatrix\""
}
```

**400 Bad Request – Invalid datamatrix (when using `datamatrix`)**

```json
{
  "ok": false,
  "error": "Invalid datamatrix: Could not extract GTIN from datamatrix"
}
```

**500 Internal Server Error – Update failed**

```json
{
  "ok": false,
  "error": "Failed to update verification"
}
```

---

## Expected behaviour

- **GTIN**  
  - 14-digit GTIN (or as stored in your system).  
  - Batch is matched by `batch.gtin` or `inventory_received.gtin`.

- **Batch**  
  - Batch/lot number as stored (e.g. `"678"`).  
  - Must match exactly the batch number for the given GTIN.

- **Pending allocation**  
  - Only **unverified** allocations can be verified.  
  - If the allocation is already verified, `check_verify` returns `can_verify: false` and `scan_verify` returns 404 “No pending allocation found”.

- **One pending allocation per batch**  
  - If multiple drug_given records have a pending allocation for the same batch, the **most recently created** drug_given is used for both check and verify.

- **Idempotency**  
  - `check_verify` is read-only and safe to call repeatedly.  
  - Calling `scan_verify` again for an already-verified allocation returns 404 (no pending allocation), so verification is effectively idempotent after the first success.

---

## Typical flow

1. **Scan or enter** GTIN + batch (or scan datamatrix).
2. **Optional:** Call `POST /api/drug_allocations/check_verify` to confirm there is a pending allocation and show details (e.g. drug name, quantity).
3. Call `POST /api/drug_allocations/scan_verify` with the same GTIN + batch (or datamatrix) to mark the allocation as verified.
4. Use the returned `drug_given_id` and `drug_allocation_id` if you need to link to the allocation in your UI or logs.

---

## Related UI

- **Pharmacy → Drug Allocations → [Allocation] → Batch Allocations**  
  Each row shows Batch, **GTIN**, Expiry, Quantity, Unit Price, Subtotal, Status, and a “Scan to Verify” action.  
  The same GTIN and batch shown there are the values to send to these APIs for testing or integration.
