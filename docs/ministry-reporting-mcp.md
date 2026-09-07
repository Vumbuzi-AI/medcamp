# Ministry Reporting MCP

Medcamp includes a local, read-only MCP server for aggregate Ministry of Health
reporting. It never returns patient-level records and it does not save or submit
official reports.

Start it from the project directory:

```sh
MIX_ENV=prod mix compile
MIX_ENV=prod mix medcamp.mcp.reporting
```

Compile once before adding the server to an MCP host so Mix build messages
cannot appear on the protocol's stdout stream.

Example MCP host configuration:

```json
{
  "mcpServers": {
    "medcamp-ministry-reporting": {
      "command": "mix",
      "args": ["medcamp.mcp.reporting"],
      "cwd": "/absolute/path/to/medcamp",
      "env": {
        "MIX_ENV": "prod"
      }
    }
  }
}
```

## Automatic Codex startup

This repository includes `.codex/config.toml`, which automatically launches the
reporting server in `MIX_ENV=dev` whenever Codex opens this trusted project. The
server is marked as required, so Codex reports a startup failure instead of
silently continuing without the reporting tools.

After cloning the repository or changing the MCP configuration:

1. Trust the project when Codex prompts.
2. Restart Codex (or restart the IDE extension).
3. Use `/mcp` to confirm that `medcamp_ministry_reporting` is connected.

Codex ignores project-level MCP configuration for untrusted repositories.

The server exposes:

- `list_moh_reports` — lists every report and its readiness.
- `get_moh_report_schema` — returns valid row candidates and readiness for any
  report, including reports that are still manual.
- `generate_moh_report` — accepts `form_id`, `date_from`, and `date_to` and
  returns a map keyed by the HTML form cell IDs.
- `suggest_moh_mappings` — uses AI to suggest mappings for aggregate source
  labels. Suggestions are validated against real rows, marked for human review,
  and never applied automatically.

Supported reports:

- MOH 706 — counts come only from completed or verified structured lab entries
  with approved mappings.
- MOH 710 — fills Section A grand totals from recorded immunizations, vitamin A
  supplements, maternal TD vaccinations, adverse events, and relevant child eye
  assessments. Static/outreach splits and stock logistics remain manual because
  those attributes are not currently recorded.

Unknown source names are listed in `summary.unmatched_tests` and are not guessed
into a report cell.

## AI configuration and safety

Set `OPENAI_API_KEY` to enable `suggest_moh_mappings`. Local Mix commands,
including `mix phx.server` and `mix medcamp.mcp.reporting`, automatically load the
Git-ignored `.env` file. Production and release environments must provide the
key through their process environment. The reporting server starts and
deterministic tools work without it.

Only aggregate labels such as test, vaccine, commodity, service, or diagnosis
names should be sent to the AI tool. Do not send patient names, identifiers,
free-text notes, or row-level patient data.

AI is advisory only:

1. The model can select only candidate rows supplied from `forms.json`.
2. The server discards invented candidate IDs and invalid source labels.
3. Every returned suggestion has `requires_human_review: true`.
4. Suggestions never change mappings, values, saved reports, or submissions.

The OpenAI call uses a strict JSON Schema response format, followed by
application-side validation of source labels and candidate IDs. See OpenAI's
[Structured Outputs guide](https://developers.openai.com/api/docs/guides/structured-outputs).

The `/admin/reporting` screen calls the same reporting engine directly, so its
date-range Auto-fill button and the MCP tool always produce the same totals.
