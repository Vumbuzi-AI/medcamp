# Run with: mix run priv/repo/seeds/additional_lab_test_templates_seeds.exs
#
# This file contains additional lab test templates based on Glocal Healthcare
# Centre of Excellence templates. These tests complement the existing seeds.

alias Medcamp.Repo
alias Medcamp.LabTestTemplates.{LabTestCategory, LabTestTemplate}

# Helper to get category ID
get_category_id = fn name ->
  Repo.get_by!(LabTestCategory, name: name).id
end

# =========================================================================
# ADDITIONAL TEST TEMPLATES
# =========================================================================

templates = [
  # ---------------------------------------------------------------------------
  # ANTI STREPTOLYSIN O TEST (ASOT)
  # ---------------------------------------------------------------------------
  %{
    name: "Anti Streptolysin O Test",
    short_name: "ASOT",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "asot",
        label: "Anti Streptolysin O Test (ASOT)",
        type: "number",
        unit: "IU/mL",
        ref_range_min: 0,
        ref_range_max: 200,
        ref_range_text: "< 200 IU/mL",
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # BLOOD GROUPING AND RHESUS FACTOR
  # ---------------------------------------------------------------------------
  %{
    name: "ABO Grouping and Rhesus Factor",
    short_name: "Blood Group",
    category_name: "Haematology",
    field_definitions: [
      %{
        name: "blood_type",
        label: "Blood Type",
        type: "select",
        options: ["A", "B", "AB", "O"],
        required: true,
        display_order: 1
      },
      %{
        name: "rhesus_factor",
        label: "Rhesus Factor",
        type: "select",
        options: ["Positive", "Negative"],
        required: true,
        display_order: 2
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # H.PYLORI ANTIBODY TEST
  # ---------------------------------------------------------------------------
  %{
    name: "H.Pylori Antibody Test",
    short_name: "H.Pylori Ab",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "h_pylori_antibody",
        label: "H.Pylori Antibody Test",
        type: "select",
        options: ["Negative", "Positive"],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # LIPID PROFILE
  # ---------------------------------------------------------------------------
  %{
    name: "Lipid Profile",
    short_name: "Lipid",
    category_name: "Blood Chemistry",
    field_definitions: [
      %{
        name: "total_cholesterol",
        label: "Total Cholesterol",
        type: "number",
        unit: "mmol/L",
        ref_range_min: 0,
        ref_range_max: 5,
        ref_range_text: "0 - 5 mmol/L",
        required: true,
        display_order: 1
      },
      %{
        name: "ldl",
        label: "LDL",
        type: "number",
        unit: "mmol/L",
        ref_range_min: 0,
        ref_range_max: 0.26,
        ref_range_text: "0 - 0.26 mmol/L",
        required: true,
        display_order: 2
      },
      %{
        name: "hdl",
        label: "HDL",
        type: "number",
        unit: "mmol/L",
        ref_range_min: 1.55,
        ref_range_max: 2.0,
        ref_range_text: "1.55 - 2.0 mmol/L",
        required: true,
        display_order: 3
      },
      %{
        name: "triglycerides",
        label: "Triglycerides",
        type: "number",
        unit: "mmol/L",
        ref_range_min: 0,
        ref_range_max: 1.7,
        ref_range_text: "0 - 1.7 mmol/L",
        required: true,
        display_order: 4
      },
      %{
        name: "chol_ldl_ratio",
        label: "Chol/LDL Ratio",
        type: "number",
        unit: "mmol/L",
        ref_range_max: 4,
        ref_range_text: "<4 mmol/L",
        required: false,
        display_order: 5
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # MALARIA MICROSCOPY TEST (BLOOD SMEAR)
  # ---------------------------------------------------------------------------
  %{
    name: "Malaria Microscopy Test",
    short_name: "Malaria BS",
    category_name: "Microbiology",
    field_definitions: [
      %{
        name: "malaria_microscopy",
        label: "Malaria Microscopy Test (BS)",
        type: "select",
        options: [
          "No Malaria Parasites Seen",
          "P. falciparum (+)",
          "P. falciparum (++)",
          "P. falciparum (+++)",
          "P. vivax (+)",
          "P. vivax (++)",
          "P. vivax (+++)",
          "P. malariae (+)",
          "P. ovale (+)",
          "Mixed Species"
        ],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # RHEUMATOID FACTOR (RF)
  # ---------------------------------------------------------------------------
  %{
    name: "Rheumatoid Factor",
    short_name: "RF",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "rheumatoid_factor",
        label: "Rheumatoid Factor",
        type: "select",
        options: ["Negative", "Positive"],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # SALMONELLA ANTIBODY TEST
  # ---------------------------------------------------------------------------
  %{
    name: "Salmonella Antibody Test",
    short_name: "Salmonella Ab",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "salmonella_antibody",
        label: "Salmonella Antibody Test",
        type: "select",
        options: ["Negative", "Positive"],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # SALMONELLA ANTIGEN TEST
  # ---------------------------------------------------------------------------
  %{
    name: "Salmonella Antigen Test",
    short_name: "Salmonella Ag",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "salmonella_antigen",
        label: "Salmonella Antigen Test",
        type: "select",
        options: ["Negative", "Positive"],
        required: true,
        display_order: 1
      }
    ]
  }
]

# Insert templates
Enum.each(templates, fn template ->
  category_id = get_category_id.(template.category_name)

  template_data =
    template
    |> Map.delete(:category_name)
    |> Map.put(:category_id, category_id)

  %LabTestTemplate{}
  |> LabTestTemplate.changeset(template_data)
  |> Repo.insert!(on_conflict: :nothing)
end)

IO.puts("✓ Inserted #{length(templates)} additional test templates")
IO.puts("\n🎉 Additional lab test templates seeded successfully!")
IO.puts("\nTemplates added:")
Enum.each(templates, fn t -> IO.puts("  - #{t.name} (#{t.short_name})") end)
