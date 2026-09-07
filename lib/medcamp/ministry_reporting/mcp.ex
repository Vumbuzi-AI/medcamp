defmodule Medcamp.MinistryReporting.MCP do
  @moduledoc """
  Protocol handler for the read-only Ministry Reporting MCP server.

  The stdio transport is provided by `mix medcamp.mcp.reporting`. Keeping the
  protocol handler separate makes the tool contract testable without starting
  another HTTP listener or exposing patient-level records.
  """

  alias Medcamp.MinistryReporting
  alias Medcamp.MinistryReporting.AIMappingAdvisor

  @server_info %{"name" => "medcamp-ministry-reporting", "version" => "0.1.0"}

  def handle(%{"jsonrpc" => "2.0", "method" => "initialize", "id" => id} = request) do
    protocol_version = get_in(request, ["params", "protocolVersion"]) || "2025-03-26"

    response(id, %{
      "protocolVersion" => protocol_version,
      "capabilities" => %{"tools" => %{"listChanged" => false}},
      "serverInfo" => @server_info,
      "instructions" =>
        "Inspect every MOH report schema, generate approved deterministic aggregates where supported, and request advisory AI mapping suggestions. This server is read-only, never returns patient-level data, and never applies AI suggestions."
    })
  end

  def handle(%{"jsonrpc" => "2.0", "method" => "ping", "id" => id}),
    do: response(id, %{})

  def handle(%{"jsonrpc" => "2.0", "method" => "tools/list", "id" => id}) do
    response(id, %{"tools" => tools()})
  end

  def handle(%{
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "id" => id,
        "params" => %{"name" => "list_moh_reports"}
      }) do
    reports =
      MinistryReporting.forms()
      |> Enum.map(fn form ->
        capability = MinistryReporting.report_capability(form["id"])

        %{
          "id" => form["id"],
          "code" => form["code"],
          "title" => form["title"],
          "auto_fill_supported" => MinistryReporting.auto_fill_supported?(form["id"]),
          "capability" => capability
        }
      end)

    tool_response(id, %{"reports" => reports})
  end

  def handle(%{
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "id" => id,
        "params" => %{
          "name" => "get_moh_report_schema",
          "arguments" => %{"form_id" => form_id}
        }
      }) do
    case MinistryReporting.get_form(form_id) do
      nil ->
        tool_error_response(id, "Unknown MOH report id.")

      form ->
        tool_response(id, %{
          "form_id" => form_id,
          "code" => form["code"],
          "title" => form["title"],
          "meta_fields" => form["meta_fields"] || [],
          "mapping_candidates" => MinistryReporting.mapping_candidates(form),
          "capability" => MinistryReporting.report_capability(form_id)
        })
    end
  end

  def handle(%{
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "id" => id,
        "params" => %{
          "name" => "suggest_moh_mappings",
          "arguments" => %{"form_id" => form_id, "source_items" => source_items}
        }
      }) do
    case AIMappingAdvisor.suggest(form_id, source_items) do
      {:ok, suggestions} ->
        tool_response(id, Map.put(suggestions, "form_id", form_id))

      {:error, reason} ->
        tool_error_response(id, ai_error_message(reason))
    end
  end

  def handle(%{
        "jsonrpc" => "2.0",
        "method" => "tools/call",
        "id" => id,
        "params" => %{
          "name" => "generate_moh_report",
          "arguments" => %{
            "form_id" => form_id,
            "date_from" => date_from,
            "date_to" => date_to
          }
        }
      }) do
    case MinistryReporting.auto_fill(form_id, date_from, date_to) do
      {:ok, report} ->
        tool_response(id, %{
          "form_id" => form_id,
          "date_from" => date_from,
          "date_to" => date_to,
          "values" => report.values,
          "summary" => report.summary
        })

      {:error, reason} ->
        tool_error_response(id, error_message(reason))
    end
  end

  def handle(%{"jsonrpc" => "2.0", "method" => "notifications/" <> _method}),
    do: :notification

  def handle(%{"jsonrpc" => "2.0", "id" => id}),
    do: error_response(id, -32_601, "Method not found")

  def handle(_request), do: error_response(nil, -32_600, "Invalid Request")

  defp tools do
    [
      %{
        "name" => "list_moh_reports",
        "description" =>
          "List every MOH report and its deterministic, partial, or schema-only readiness.",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{},
          "additionalProperties" => false
        }
      },
      %{
        "name" => "get_moh_report_schema",
        "description" =>
          "Get metadata, approved readiness, and valid mapping candidate rows for any MOH report.",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "form_id" => %{"type" => "string", "description" => "MOH form identifier"}
          },
          "required" => ["form_id"],
          "additionalProperties" => false
        }
      },
      %{
        "name" => "generate_moh_report",
        "description" =>
          "Generate aggregate report field values for an inclusive date range. Returns no patient-level data and does not save or submit a report.",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "form_id" => %{
              "type" => "string",
              "description" => "MOH form identifier, currently moh_706 or moh_710"
            },
            "date_from" => %{
              "type" => "string",
              "format" => "date",
              "description" => "Inclusive start date in YYYY-MM-DD format"
            },
            "date_to" => %{
              "type" => "string",
              "format" => "date",
              "description" => "Inclusive end date in YYYY-MM-DD format"
            }
          },
          "required" => ["form_id", "date_from", "date_to"],
          "additionalProperties" => false
        }
      },
      %{
        "name" => "suggest_moh_mappings",
        "description" =>
          "Ask AI to suggest MOH row mappings for aggregate source labels. Suggestions are validated, advisory-only, and never applied to report totals.",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "form_id" => %{"type" => "string", "description" => "MOH form identifier"},
            "source_items" => %{
              "type" => "array",
              "description" =>
                "Aggregate labels such as test, vaccine, service, commodity, or diagnosis names. Do not send patient identifiers.",
              "items" => %{"type" => "string", "maxLength" => 200},
              "minItems" => 1,
              "maxItems" => 100
            }
          },
          "required" => ["form_id", "source_items"],
          "additionalProperties" => false
        }
      }
    ]
  end

  defp response(id, result), do: %{"jsonrpc" => "2.0", "id" => id, "result" => result}

  defp error_response(id, code, message) do
    %{
      "jsonrpc" => "2.0",
      "id" => id,
      "error" => %{"code" => code, "message" => message}
    }
  end

  defp tool_response(id, data) do
    response(id, %{
      "content" => [%{"type" => "text", "text" => Jason.encode!(data)}],
      "structuredContent" => data
    })
  end

  defp tool_error_response(id, message) do
    response(id, %{
      "content" => [%{"type" => "text", "text" => message}],
      "isError" => true
    })
  end

  defp error_message(:unsupported_form), do: "Automatic filling is not mapped for that form."
  defp error_message(:invalid_date), do: "Dates must use YYYY-MM-DD format."
  defp error_message(:invalid_range), do: "date_from must be on or before date_to."
  defp error_message(reason), do: "Unable to generate report: #{inspect(reason)}"

  defp ai_error_message(:unknown_form), do: "Unknown MOH report id."
  defp ai_error_message(:invalid_source_items), do: "Provide at least one aggregate source label."
  defp ai_error_message(:too_many_source_items), do: "At most 100 source labels are allowed."
  defp ai_error_message(reason) when is_binary(reason), do: reason
  defp ai_error_message(reason), do: "AI mapping suggestion failed: #{inspect(reason)}"
end
