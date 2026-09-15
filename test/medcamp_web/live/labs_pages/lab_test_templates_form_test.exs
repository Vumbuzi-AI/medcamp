defmodule MedcampWeb.LabPagesLabTestTemplateLive.FormTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.LabTestTemplates
  alias Medcamp.Tenancy

  setup %{conn: conn} do
    user = user_fixture(%{role: "labtechnician"})

    {:ok, category} =
      Tenancy.with_org(user.organisation_id, fn ->
        LabTestTemplates.create_category(%{name: "Haematology"})
      end)

    %{conn: log_in_user(conn, user), user: user, category: category}
  end

  test "builds a template from add-parameter rows without touching JSON", %{
    conn: conn,
    user: user,
    category: category
  } do
    {:ok, view, _html} = live(conn, ~p"/lab/lab_test_templates/new")

    view |> element("button", "Add parameter") |> render_click()

    view
    |> form("#template-form", %{
      "lab_test_template" => %{
        "name" => "Full Blood Count",
        "short_name" => "FBC",
        "category_id" => category.id,
        "fields" => %{
          "0" => %{
            "label" => "Hemoglobin (HGB)",
            "name" => "",
            "type" => "number",
            "unit" => "g/dL",
            "ref_range_min" => "12",
            "ref_range_max" => "16",
            "required" => "true"
          }
        }
      }
    })
    |> render_submit()

    template =
      Tenancy.with_org(user.organisation_id, fn ->
        LabTestTemplates.list_templates() |> Enum.find(&(&1.name == "Full Blood Count"))
      end)

    assert template
    assert [field] = template.field_definitions
    assert field["label"] == "Hemoglobin (HGB)"
    # field key auto-derived from the label
    assert field["name"] == "hemoglobin_hgb"
    assert field["ref_range_min"] == 12.0
    assert field["required"] == true
    assert field["display_order"] == 1
  end

  test "an existing template's definitions populate the builder rows", %{
    conn: conn,
    user: user,
    category: category
  } do
    {:ok, template} =
      Tenancy.with_org(user.organisation_id, fn ->
        LabTestTemplates.create_template(%{
          "name" => "Liver Panel",
          "short_name" => "LFT",
          "category_id" => category.id,
          "field_definitions" => [
            %{"name" => "alt", "label" => "ALT", "type" => "number", "unit" => "U/L"}
          ]
        })
      end)

    {:ok, view, _html} = live(conn, ~p"/lab/lab_test_templates/#{template.id}/edit")

    assert has_element?(view, ~s(input[name="lab_test_template[fields][0][label]"][value="ALT"]))
    refute render(view) =~ "No parameters yet"
  end

  test "the JSON fallback still accepts a pasted array", %{
    conn: conn,
    user: user,
    category: category
  } do
    {:ok, view, _html} = live(conn, ~p"/lab/lab_test_templates/new")

    view |> element("button", "Paste JSON instead") |> render_click()

    json = ~s([{"name":"glucose","label":"Glucose","type":"number","unit":"mmol/L"}])

    view
    |> form("#template-form", %{
      "lab_test_template" => %{
        "name" => "Metabolic",
        "short_name" => "META",
        "category_id" => category.id,
        "field_definitions_json" => json
      }
    })
    |> render_submit()

    template =
      Tenancy.with_org(user.organisation_id, fn ->
        LabTestTemplates.list_templates() |> Enum.find(&(&1.name == "Metabolic"))
      end)

    assert template
    assert [%{"name" => "glucose"}] = template.field_definitions
  end

  test "malformed JSON in the fallback surfaces an error instead of saving", %{
    conn: conn,
    category: category
  } do
    {:ok, view, _html} = live(conn, ~p"/lab/lab_test_templates/new")

    view |> element("button", "Paste JSON instead") |> render_click()

    html =
      view
      |> form("#template-form", %{
        "lab_test_template" => %{
          "name" => "Broken",
          "short_name" => "BRK",
          "category_id" => category.id,
          "field_definitions_json" => "{not json"
        }
      })
      |> render_submit()

    assert html =~ "bg-red-50"
    refute html =~ "Template created"
  end

  test "a JSON object (not an array) is rejected with a clear message", %{
    conn: conn,
    category: category
  } do
    {:ok, view, _html} = live(conn, ~p"/lab/lab_test_templates/new")

    view |> element("button", "Paste JSON instead") |> render_click()

    html =
      view
      |> form("#template-form", %{
        "lab_test_template" => %{
          "name" => "Object",
          "short_name" => "OBJ",
          "category_id" => category.id,
          "field_definitions_json" => "{}"
        }
      })
      |> render_submit()

    assert html =~ "Field definitions must be a JSON array"
  end

  test "an added blank parameter row survives a parent re-render (finding C-5)", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/lab_test_templates/new")

    view |> element("button", "Add parameter") |> render_click()
    view |> element("button", "Add parameter") |> render_click()

    assert has_element?(view, ~s(input[name="lab_test_template[fields][1][label]"]))

    # A parent event (the list search box) re-renders the LiveView and
    # re-invokes FormComponent.update/3 with the same template. The blank
    # second row must not be discarded.
    view
    |> form(~s(form[phx-change="search"]), %{"query" => "anything"})
    |> render_change()

    assert has_element?(view, ~s(input[name="lab_test_template[fields][1][label]"]))
  end

  test "toggle_json round-trips a builder row through JSON and back", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/lab/lab_test_templates/new")

    view |> element("button", "Add parameter") |> render_click()

    view
    |> form("#template-form", %{
      "lab_test_template" => %{
        "fields" => %{
          "0" => %{"label" => "Haemoglobin", "type" => "number", "unit" => "g/dL"}
        }
      }
    })
    |> render_change()

    json_view = view |> element("button", "Paste JSON instead") |> render_click()
    assert json_view =~ "Haemoglobin"

    builder_view = view |> element("button", "Back to builder") |> render_click()

    assert builder_view =~ ~s(value="Haemoglobin")
    assert has_element?(view, ~s(input[name="lab_test_template[fields][0][unit]"][value="g/dL"]))
  end
end
