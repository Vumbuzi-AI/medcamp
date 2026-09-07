# Sentry Webhook Setup for Medcamp, CRM, and Chat

## Purpose

Use this runbook to connect Sentry error notifications to:

1. Medcamp's persistent webhook inbox.
2. The internal CRM as deduplicated incident records.
3. The chat interface as readable incident cards and notifications.

This document describes the payload Sentry currently sends for the Medcamp Elixir project and the contract the CRM and chat implementations should follow.

## Current Status

| Component | Status | Location |
| --- | --- | --- |
| Sentry SDK error capture | Active | Medcamp application and endpoint configuration |
| Medcamp webhook receiver | Active | `POST /api/webhooks/sentry` |
| Medcamp webhook storage | Active | `sentry_webhook_deliveries` |
| Medcamp admin inspector | Active | `/admin/sentry-webhooks` |
| CRM incident creation | Requires CRM implementation | See the CRM contract below |
| Chat incident cards/notifications | Requires chat implementation | See the chat contract below |

Do not mark the CRM or chat integration active until every item in the activation checklist passes.

## Recommended Flow

```mermaid
flowchart LR
  Sentry[Sentry Custom Integration] -->|error webhook| Medcamp[Medcamp webhook receiver]
  Medcamp --> Inbox[(sentry_webhook_deliveries)]
  Medcamp -->|normalized incident| CRM[Internal CRM]
  Medcamp -->|incident card/event| Chat[Chat interface]
  Admin[Admin user] --> Viewer[/admin/sentry-webhooks]
  Viewer --> Inbox
```

Medcamp is the recommended single receiver because it gives the organization one durable audit copy and one place to normalize Sentry's large payload before sending it to other systems.

The current code stores the webhook but does not yet forward it to the CRM or chat. Implement forwarding only after the CRM and chat endpoints below are available.

## Configure the Sentry Custom Integration

1. In Sentry, open **Settings → Custom Integrations**.
2. Create or edit the internal integration for Medcamp.
3. Set the webhook URL:

   ```text
   https://YOUR-MEDIC-DOMAIN/api/webhooks/sentry
   ```

4. Enable the required webhook subscription. For the payload currently received by Medcamp, the resource is `error` and the action is `created`.
5. Save the integration and send a test event.
6. Confirm Sentry receives HTTP `202` from Medcamp.
7. Sign in as a Medcamp administrator and inspect the delivery at:

   ```text
   https://YOUR-MEDIC-DOMAIN/admin/sentry-webhooks
   ```

Medcamp currently accepts the webhook without a shared secret. Treat the endpoint as public input: apply rate limiting or a Sentry IP allowlist at the reverse proxy when available.

Sentry expects webhook receivers to respond quickly. Medcamp should persist the delivery and return `202`; CRM/chat forwarding should run asynchronously rather than delaying the Sentry response. See [Sentry's webhook documentation](https://docs.sentry.io/organization/integrations/integration-platform/webhooks/).

## Incoming Sentry Error Payload

The important fields observed in the live Medcamp payload are:

| Sentry field | Meaning | Example |
| --- | --- | --- |
| `action` | Webhook action | `created` |
| `actor.name` | Originating actor | `Sentry` |
| `installation.uuid` | Custom integration installation | UUID |
| `data.error.event_id` | Unique occurrence ID | `cc332c...` |
| `data.error.issue_id` | Grouped Sentry issue ID | `7626195537` |
| `data.error.title` | Human-readable error title | `RuntimeError: boom` |
| `data.error.message` | Event message, when provided | String |
| `data.error.exception.values` | Exception types, values, and mechanism | Array |
| `data.error.level` | Severity | `error` |
| `data.error.environment` | Sentry environment | `dev` |
| `data.error.datetime` | Time the error occurred | ISO-8601 timestamp |
| `data.error.web_url` | Browser link to the Sentry event | HTTPS URL |
| `data.error.url` | Sentry API event URL | HTTPS URL |
| `data.error.project` | Sentry project ID | Numeric ID |
| `data.error.platform` | Runtime platform | `elixir` |
| `data.error.sdk` | Capturing SDK name/version | `sentry-elixir`, `10.2.1` |
| `data.error.user.geo` | Approximate location, when present | City/region/country |
| `data.error.tags` | Environment, runtime, OS, server, and other tags | Key/value pairs |
| `data.error.contexts.trace` | Trace and span IDs | Object |
| `data.error.contexts.runtime` | Language/runtime details | Object |
| `data.error.contexts.os` | Operating system details | Object |

The payload may contain request context or personal information. Do not copy the full payload into chat messages, and restrict CRM access to authorized staff.

## Normalized Incident Contract

Medcamp should transform the large Sentry payload into this smaller object before forwarding it to CRM or chat:

```json
{
  "source": "sentry",
  "event_id": "cc332c52754c46f68f63848c896d874b",
  "issue_id": "7626195537",
  "action": "created",
  "title": "RuntimeError: boom",
  "message": "boom",
  "exception_type": "RuntimeError",
  "level": "error",
  "environment": "dev",
  "platform": "elixir",
  "occurred_at": "2026-07-22T07:01:38.762072Z",
  "received_at": "2026-07-22T07:01:41Z",
  "project_id": "4511777366605824",
  "sentry_url": "https://sentry.io/organizations/ORG/issues/ISSUE/events/EVENT/",
  "trace_id": "cc332c52754c46f68f63848c896d874b",
  "span_id": "cc332c52754c46f6",
  "runtime": "elixir 1.18.2",
  "operating_system": "darwin 25.5.0",
  "server_name": "application-host",
  "location": {
    "city": "Nairobi",
    "region": "Kenya",
    "country_code": "KE"
  }
}
```

Use `event_id` as the idempotency key. A retry of the same Sentry event must update or reuse the existing CRM/chat record, not create a duplicate.

## CRM Implementation Contract

### Endpoint

The CRM should expose a server-to-server endpoint such as:

```text
POST https://YOUR-CRM-DOMAIN/api/integrations/sentry/incidents
```

Required behavior:

- Accept the normalized incident JSON.
- Enforce a unique index or upsert on `source + event_id`.
- Return `200`, `201`, or `202` for success.
- Return within one second if called synchronously; otherwise queue the work.
- Store `issue_id` separately so multiple events can be grouped under one Sentry issue.
- Preserve `sentry_url` as the primary link back to diagnostic details.
- Record the forwarding status and last error in Medcamp for retry/audit purposes.

### Suggested CRM Mapping

| CRM field | Normalized field |
| --- | --- |
| External reference | `event_id` |
| Incident group | `issue_id` |
| Subject | `title` |
| Description | `message` |
| Source | `source` (`sentry`) |
| Severity | `level` |
| Environment | `environment` |
| Occurred at | `occurred_at` |
| Diagnostic URL | `sentry_url` |
| Trace reference | `trace_id` |
| Status | New/Open on `action: created` |

Suggested severity mapping:

| Sentry level | CRM priority |
| --- | --- |
| `fatal` | Critical |
| `error` | High |
| `warning` | Medium |
| `info`, `debug` | Low |

## Chat Interface Contract

The chat interface should consume the normalized incident, not the full Sentry payload.

Recommended incident card:

```text
Sentry · ERROR · dev
RuntimeError: boom

Exception: RuntimeError — boom
Occurred: 22 Jul 2026, 07:01 UTC
Server: application-host
Issue: 7626195537

[Open in Sentry] [Open CRM Incident]
```

Required behavior:

- Deduplicate cards using `event_id`.
- Group repeated occurrences visually using `issue_id`.
- Show severity, environment, title, exception summary, occurred time, and server.
- Link to Sentry and the matching CRM incident.
- Do not display geographic/user information by default.
- Do not display module lists, request headers, cookies, authorization values, or complete payloads.
- Route production `fatal`/`error` events to the operational incident channel.
- Keep development/test events in a separate technical channel or suppress them.

For Medcamp's built-in chat UI, add a dedicated system-message/card type rather than inserting the incident as ordinary user text.

## Forwarding Reliability

When Medcamp forwarding is implemented, add delivery-state fields or a related table for each destination:

- `crm_status`: `pending`, `sent`, or `failed`
- `crm_attempts`
- `crm_last_attempt_at`
- `crm_last_error`
- `crm_record_id`
- `chat_status`: `pending`, `sent`, or `failed`
- `chat_attempts`
- `chat_last_attempt_at`
- `chat_last_error`
- `chat_message_id`

Use a supervised background worker with exponential backoff. Never make the Sentry webhook wait for CRM or chat network calls.

## Test Procedure

1. Trigger a safe test exception in the Medcamp development environment.
2. Confirm Sentry displays the event.
3. Confirm Sentry's webhook delivery receives HTTP `202`.
4. Confirm a row exists in `sentry_webhook_deliveries`.
5. Open `/admin/sentry-webhooks` and verify the structured incident view.
6. Confirm exactly one CRM incident exists for the Sentry `event_id`.
7. Retry the same payload and confirm no duplicate CRM incident is created.
8. Confirm one chat card appears with working Sentry and CRM links.
9. Confirm sensitive payload fields do not appear in the chat card.
10. Test a CRM/chat outage and confirm Medcamp records the failure and retries without losing the original delivery.

## Activation Checklist

- [ ] Production Medcamp webhook URL is configured in Sentry.
- [ ] Required Sentry error webhook events are enabled.
- [ ] Sentry test delivery returns HTTP `202`.
- [ ] Medcamp database delivery is visible to an admin.
- [ ] CRM endpoint is deployed and authenticated.
- [ ] CRM uses `event_id` idempotency/upsert behavior.
- [ ] Medcamp-to-CRM forwarding and retries are deployed.
- [ ] Chat incident card is implemented.
- [ ] Chat uses `event_id` deduplication and `issue_id` grouping.
- [ ] Sentry and CRM links work from chat.
- [ ] Production and development notification routing is separated.
- [ ] Sensitive fields are excluded from chat.
- [ ] Rate limiting or source restrictions protect the unauthenticated Medcamp receiver.
- [ ] Operational owners have completed an end-to-end test.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Sentry shows a timeout | Receiver must persist and respond quickly; move forwarding to background work. |
| Sentry gets `404` | Confirm `/api/webhooks/sentry` and the deployed Medcamp base URL. |
| Sentry gets `422` | Check database availability and the Medcamp application logs. |
| HTTP `202` but inbox is empty | Confirm the deployed application and admin UI use the same database. |
| Duplicate CRM incidents | Add a unique constraint/upsert on `source + event_id`. |
| Chat floods on repeated errors | Group by `issue_id` and deduplicate individual `event_id` values. |
| Links do not open | Preserve `data.error.web_url`; do not construct Sentry URLs manually. |
| Sensitive data appears in chat | Use only the normalized contract and remove user/request context. |

## Definition of Active

The integration is active only when a real test event completes this path:

```text
Medcamp error → Sentry event → Medcamp webhook row → CRM incident → Chat incident card
```

Record the test event ID, CRM record ID, chat message ID, test date, and tester name as deployment evidence.
