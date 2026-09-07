defmodule Medcamp.MinistryReporting.AIMappingAdvisor do
  @moduledoc """
  Uses AI to suggest mappings from local source labels to MOH report rows.

  Suggestions are advisory only. They never update a mapping, fill a cell, or
  submit a report. Candidate ids are validated against the form definition
  before being returned.
  """

  alias Medcamp.ArtificialIntelligence.OpenAI
  alias Medcamp.MinistryReporting

  @max_items 100
  @max_item_length 200

  def suggest(form_id, source_items, ai_client \\ OpenAI)

  def suggest(form_id, source_items, ai_client)
      when is_binary(form_id) and is_list(source_items) do
    with %{} = form <- MinistryReporting.get_form(form_id),
         {:ok, source_items} <- validate_source_items(source_items),
         candidates <- MinistryReporting.mapping_candidates(form),
         {:ok, payload} <- request_suggestions(form, source_items, candidates, ai_client) do
      {:ok, normalize_payload(payload, source_items, candidates)}
    else
      nil -> {:error, :unknown_form}
      {:error, _reason} = error -> error
    end
  end

  def suggest(_form_id, _source_items, _ai_client), do: {:error, :invalid_source_items}

  defp request_suggestions(form, source_items, candidates, ai_client) do
    system_prompt = """
    You assist a health-records officer with mapping aggregate source labels to
    rows in a Kenya Ministry of Health report. Return suggestions only.

    Rules:
    - Never invent a candidate id.
    - Use only the candidate rows supplied by the application.
    - If no candidate is a defensible semantic match, omit that source item.
    - Do not infer patient facts, counts, diagnoses, or clinical outcomes.
    - Confidence is a number from 0 to 1.
    - Every suggestion requires human review and must include a short reason.
    - Return JSON matching the supplied schema.
    """

    user_prompt =
      Jason.encode!(%{
        "report" => %{
          "id" => form["id"],
          "code" => form["code"],
          "title" => form["title"]
        },
        "source_items" => source_items,
        "candidate_rows" => candidates
      })

    opts = [response_schema: response_schema()]

    if function_exported?(ai_client, :request_json_to_gpt, 3) do
      ai_client.request_json_to_gpt(system_prompt, user_prompt, opts)
    else
      ai_client.request_json_to_gpt(system_prompt, user_prompt)
    end
  end

  defp normalize_payload(payload, source_items, candidates) do
    source_set = MapSet.new(source_items)
    candidate_map = Map.new(candidates, &{&1["candidate_id"], &1})

    suggestions =
      payload
      |> Map.get("suggestions", [])
      |> Enum.flat_map(fn suggestion ->
        source_item = Map.get(suggestion, "source_item")
        candidate_id = Map.get(suggestion, "candidate_id")

        with true <- MapSet.member?(source_set, source_item),
             %{} = candidate <- Map.get(candidate_map, candidate_id),
             confidence when is_number(confidence) <- Map.get(suggestion, "confidence"),
             reason when is_binary(reason) <- Map.get(suggestion, "reason") do
          [
            %{
              "source_item" => source_item,
              "candidate_id" => candidate_id,
              "candidate" => candidate,
              "confidence" => confidence |> max(0.0) |> min(1.0),
              "reason" => String.slice(reason, 0, 500),
              "requires_human_review" => true
            }
          ]
        else
          _ -> []
        end
      end)

    %{
      "suggestions" => suggestions,
      "advisory_only" => true,
      "applied" => false,
      "warning" =>
        "AI suggestions do not affect report totals until an approved deterministic mapping is implemented."
    }
  end

  defp validate_source_items(items) when length(items) <= @max_items do
    normalized =
      items
      |> Enum.filter(&is_binary/1)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.slice(&1, 0, @max_item_length))
      |> Enum.uniq()

    if normalized == [], do: {:error, :invalid_source_items}, else: {:ok, normalized}
  end

  defp validate_source_items(_items), do: {:error, :too_many_source_items}

  defp response_schema do
    %{
      "type" => "object",
      "properties" => %{
        "suggestions" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "source_item" => %{"type" => "string"},
              "candidate_id" => %{"type" => "string"},
              "confidence" => %{"type" => "number", "minimum" => 0, "maximum" => 1},
              "reason" => %{"type" => "string"}
            },
            "required" => ["source_item", "candidate_id", "confidence", "reason"],
            "additionalProperties" => false
          }
        }
      },
      "required" => ["suggestions"],
      "additionalProperties" => false
    }
  end
end
