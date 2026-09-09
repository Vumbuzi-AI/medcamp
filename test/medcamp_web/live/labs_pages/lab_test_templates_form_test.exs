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
            "ref_range_text" => "12-16 g/dL",
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
end
