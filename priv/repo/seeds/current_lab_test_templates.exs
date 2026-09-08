# Run with: mix run priv/repo/seeds/current_lab_test_templates.exs
#
# Keeps the template catalogue aligned with the lab tests seeded in
# priv/repo/seeds.exs. Safe to run repeatedly: records are upserted by name.

alias Medcamp.LabTestTemplates.{LabTestCategory, LabTestTemplate}
alias Medcamp.Repo

categories = [
  %{
    name: "Blood Chemistry",
    description: "Blood chemistry and biochemistry tests",
    display_order: 1
  },
  %{name: "Haematology", description: "Blood cell and haemoglobin tests", display_order: 2},
  %{name: "Serology", description: "Antigen and antibody screening tests", display_order: 3},
  %{
    name: "Urinalysis",
    description: "Physical, chemical and microscopic urine examination",
    display_order: 4
  },
  %{
    name: "Stool Analysis",
    description: "Stool microscopy and parasite examination",
    display_order: 5
  }
]

ensure_category = fn attrs ->
  case Repo.get_by(LabTestCategory, name: attrs.name) do
    nil ->
      %LabTestCategory{}
      |> LabTestCategory.changeset(attrs)
      |> Repo.insert!()

    category ->
      category
      |> LabTestCategory.changeset(attrs)
      |> Repo.update!()
  end
end

category_ids =
  categories
  |> Enum.map(fn category -> {category.name, ensure_category.(category).id} end)
  |> Map.new()

templates = [
  %{
    name: "Malaria RDT",
    short_name: "mRDT",
    category: "Serology",
    fields: [
      %{
        name: "malaria_result",
        label: "Malaria RDT result",
        type: "select",
        options: [
          "Negative",
          "Positive (P. falciparum)",
          "Positive (P. vivax)",
          "Positive (Mixed)"
        ],
        required: true,
        display_order: 1
      }
    ]
  },
  %{
    name: "Blood Sugar (RBS)",
    short_name: "RBS",
    category: "Blood Chemistry",
    fields: [
      %{
        name: "rbs",
        label: "Random blood sugar",
        type: "number",
        unit: "mmol/L",
        ref_range_min: 3.8,
        ref_range_max: 7.5,
        ref_range_text: "3.8 – 7.5 mmol/L",
        required: true,
        display_order: 1
      }
    ]
  },
  %{
    name: "Haemoglobin (Hb)",
    short_name: "Hb",
    category: "Haematology",
    fields: [
      %{
        name: "haemoglobin",
        label: "Haemoglobin",
        type: "number",
        unit: "g/dL",
        ref_range_min: 11.5,
        ref_range_max: 16.5,
        ref_range_text: "11.5 – 16.5 g/dL",
        required: true,
        display_order: 1
      }
    ]
  },
  %{
    name: "Full Blood Count",
    short_name: "FBC",
    category: "Haematology",
    fields: [
      %{
        name: "wbc",
        label: "WBC",
        type: "number",
        unit: "10^9/L",
        ref_range_min: 5,
        ref_range_max: 10,
        ref_range_text: "5 – 10 10^9/L",
        required: true,
        display_order: 1
      },
      %{
        name: "haemoglobin",
        label: "Haemoglobin",
        type: "number",
        unit: "g/dL",
        ref_range_min: 11.5,
        ref_range_max: 16.5,
        ref_range_text: "11.5 – 16.5 g/dL",
        required: true,
        display_order: 2
      },
      %{
        name: "platelets",
        label: "Platelets",
        type: "number",
        unit: "10^9/L",
        ref_range_min: 150,
        ref_range_max: 450,
        ref_range_text: "150 – 450 10^9/L",
        required: true,
        display_order: 3
      },
      %{
        name: "mcv",
        label: "MCV",
        type: "number",
        unit: "fL",
        ref_range_min: 78,
        ref_range_max: 94,
        ref_range_text: "78 – 94 fL",
        required: true,
        display_order: 4
      }
    ]
  },
  %{
    name: "Urinalysis",
    short_name: "Urinalysis",
    category: "Urinalysis",
    fields: [
      %{
        name: "appearance",
        label: "Appearance",
        type: "text",
        section: "Physical",
        display_order: 1
      },
      %{name: "colour", label: "Colour", type: "text", section: "Physical", display_order: 2},
      %{
        name: "leukocytes",
        label: "Leukocytes",
        type: "text",
        section: "Chemical",
        display_order: 3
      },
      %{name: "nitrites", label: "Nitrites", type: "text", section: "Chemical", display_order: 4},
      %{name: "protein", label: "Protein", type: "text", section: "Chemical", display_order: 5},
      %{name: "blood", label: "Blood", type: "text", section: "Chemical", display_order: 6},
      %{name: "glucose", label: "Glucose", type: "text", section: "Chemical", display_order: 7},
      %{
        name: "ph",
        label: "pH",
        type: "number",
        unit: "pH",
        ref_range_min: 4.5,
        ref_range_max: 7.5,
        ref_range_text: "4.5 – 7.5",
        section: "Chemical",
        display_order: 8
      },
      %{
        name: "microscopy",
        label: "Microscopy",
        type: "text",
        section: "Microscopy",
        display_order: 9
      }
    ]
  },
  %{
    name: "HIV Screening",
    short_name: "HIV",
    category: "Serology",
    fields: [
      %{
        name: "hiv_result",
        label: "HIV screening result",
        type: "select",
        options: ["Negative", "Positive", "Indeterminate"],
        required: true,
        display_order: 1
      }
    ]
  },
  %{
    name: "Pregnancy Test (HCG)",
    short_name: "HCG",
    category: "Serology",
    fields: [
      %{
        name: "pregnancy_result",
        label: "Pregnancy test result",
        type: "select",
        options: ["Negative", "Positive", "Indeterminate"],
        required: true,
        display_order: 1
      }
    ]
  },
  %{
    name: "Stool for Ova & Cysts",
    short_name: "Stool O/C",
    category: "Stool Analysis",
    fields: [
      %{
        name: "appearance",
        label: "Appearance",
        type: "text",
        section: "Physical",
        display_order: 1
      },
      %{name: "ova", label: "Ova", type: "text", section: "Microscopy", display_order: 2},
      %{name: "cysts", label: "Cysts", type: "text", section: "Microscopy", display_order: 3},
      %{name: "blood", label: "Blood", type: "text", section: "Microscopy", display_order: 4},
      %{
        name: "other_findings",
        label: "Other findings",
        type: "text",
        section: "Microscopy",
        display_order: 5
      }
    ]
  }
]

Enum.each(templates, fn template ->
  attrs = %{
    name: template.name,
    short_name: template.short_name,
    category_id: category_ids[template.category],
    field_definitions: template.fields,
    is_active: true
  }

  case Repo.get_by(LabTestTemplate, name: attrs.name) do
    nil ->
      %LabTestTemplate{}
      |> LabTestTemplate.changeset(attrs)
      |> Repo.insert!()

    existing ->
      existing
      |> LabTestTemplate.changeset(attrs)
      |> Repo.update!()
  end
end)

IO.puts("Seeded #{length(templates)} templates for the current lab test catalogue.")
