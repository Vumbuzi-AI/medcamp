# Run with: mix run priv/repo/seeds/anc_extra.exs
#
# This file contains:
# 1. ANC (Antenatal Care) Profile - consolidated 8 tests
# 2. Hemoglobin Test (standalone)
# 3. Pregnancy Test (standalone)
# 4. Calcium Test (standalone)

alias Medcamp.Repo
alias Medcamp.LabTestTemplates.{LabTestCategory, LabTestTemplate}

# Helper to get category ID
get_category_id = fn name ->
  Repo.get_by!(LabTestCategory, name: name).id
end

# =========================================================================
# TEST TEMPLATES
# =========================================================================

templates = [
  # ===========================================================================
  # STANDALONE TESTS
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 1. HEMOGLOBIN TEST (Standalone)
  # ---------------------------------------------------------------------------
  %{
    name: "Hemoglobin Test",
    short_name: "HGB",
    category_name: "Haematology",
    field_definitions: [
      %{
        name: "hemoglobin",
        label: "Hemoglobin Test",
        type: "number",
        unit: "g/dl",
        ref_range_min: 12.5,
        ref_range_max: 16.5,
        ref_range_text: "12.5-16.5 g/dl",
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # 2. PREGNANCY TEST (Standalone)
  # ---------------------------------------------------------------------------
  %{
    name: "Pregnancy Test",
    short_name: "UPT",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "pregnancy_test",
        label: "Pregnancy Test",
        type: "select",
        options: ["Negative", "Positive"],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # 3. CALCIUM TEST (Standalone)
  # ---------------------------------------------------------------------------
  %{
    name: "Calcium Test",
    short_name: "Ca",
    category_name: "Blood Chemistry",
    field_definitions: [
      %{
        name: "calcium",
        label: "Calcium Test",
        type: "number",
        unit: "mmol/L",
        ref_range_min: 2.12,
        ref_range_max: 2.62,
        ref_range_text: "2.12 - 2.62 mmol/L",
        required: true,
        display_order: 1
      }
    ]
  },

  # ===========================================================================
  # ANC PROFILE (8 TESTS CONSOLIDATED)
  # ===========================================================================
  # Tests included:
  # 1. Hemoglobin
  # 2. HIV Test
  # 3. ABO Grouping & Rhesus Factor
  # 4. Hepatitis B (HBsAg)
  # 5. VDRL Test
  # 6. Urinalysis
  # 7. Random Blood Sugar (RBS)
  # 8. Hemoglobin Test
  # ---------------------------------------------------------------------------
  %{
    name: "ANC Profile",
    short_name: "ANC",
    category_name: "Other",
    field_definitions: [
      # -------------------------------------------------------------------------
      # 1. HEMOGLOBIN
      # -------------------------------------------------------------------------
      %{
        name: "hemoglobin",
        label: "Hemoglobin",
        type: "number",
        unit: "g/dl",
        ref_range_min: 12.5,
        ref_range_max: 16.5,
        ref_range_text: "12.5-16.5 g/dl",
        section: "1. Haematology",
        required: true,
        display_order: 1
      },

      # -------------------------------------------------------------------------
      # 2. HIV TEST
      # -------------------------------------------------------------------------
      %{
        name: "hiv_test",
        label: "HIV Test",
        type: "select",
        options: ["Negative", "Positive", "Indeterminate"],
        section: "2. HIV Screening",
        required: true,
        display_order: 2
      },

      # -------------------------------------------------------------------------
      # 3. ABO GROUPING AND RHESUS FACTOR
      # -------------------------------------------------------------------------
      %{
        name: "blood_type",
        label: "Blood Type",
        type: "select",
        options: ["A", "B", "AB", "O"],
        section: "3. Blood Grouping",
        required: true,
        display_order: 3
      },
      %{
        name: "rhesus_factor",
        label: "Rhesus Factor",
        type: "select",
        options: ["Positive", "Negative"],
        section: "3. Blood Grouping",
        required: true,
        display_order: 4
      },

      # -------------------------------------------------------------------------
      # 4. HEPATITIS B TEST
      # -------------------------------------------------------------------------
      %{
        name: "hbsag_test",
        label: "HBsAg Test",
        type: "select",
        options: ["Negative", "Positive"],
        section: "4. Hepatitis B Screening",
        required: true,
        display_order: 5
      },

      # -------------------------------------------------------------------------
      # 5. VDRL TEST
      # -------------------------------------------------------------------------
      %{
        name: "vdrl_test",
        label: "VDRL Test",
        type: "select",
        options: ["Non-Reactive", "Reactive", "Weakly Reactive"],
        section: "5. Syphilis Screening",
        required: true,
        display_order: 6
      },

      # -------------------------------------------------------------------------
      # 6. URINALYSIS
      # -------------------------------------------------------------------------
      # Physical examination
      %{name: "urine_appearance", label: "Appearance", type: "text", section: "6. Urinalysis - Physical", display_order: 7},
      %{name: "urine_color", label: "Color", type: "text", section: "6. Urinalysis - Physical", display_order: 8},

      # Chemical examination
      %{name: "urine_leukocytes", label: "Leukocytes", type: "text", section: "6. Urinalysis - Chemical", display_order: 9},
      %{name: "urine_bilirubin", label: "Bilirubin", type: "text", section: "6. Urinalysis - Chemical", display_order: 10},
      %{name: "urine_ketones", label: "Ketones", type: "text", section: "6. Urinalysis - Chemical", display_order: 11},
      %{name: "urine_nitrites", label: "Nitrites", type: "text", section: "6. Urinalysis - Chemical", display_order: 12},
      %{name: "urine_blood", label: "Blood", type: "text", section: "6. Urinalysis - Chemical", display_order: 13},
      %{name: "urine_protein", label: "Protein", type: "text", section: "6. Urinalysis - Chemical", display_order: 14},
      %{name: "urine_ph", label: "PH", type: "number", ref_range_text: "4.5 - 7.5", ref_range_min: 4.5, ref_range_max: 7.5, section: "6. Urinalysis - Chemical", display_order: 15},
      %{name: "urine_sg", label: "S.G", type: "text", section: "6. Urinalysis - Chemical", display_order: 16},
      %{name: "urine_glucose", label: "Glucose", type: "text", section: "6. Urinalysis - Chemical", display_order: 17},

      # Microscopy
      %{name: "urine_wbc_pus_cells", label: "Wbc (Pus cells)", type: "text", section: "6. Urinalysis - Microscopy", display_order: 18},
      %{name: "urine_rbcs", label: "RBCs", type: "text", section: "6. Urinalysis - Microscopy", display_order: 19},
      %{name: "urine_yeast_cells", label: "Yeast Cells", type: "text", section: "6. Urinalysis - Microscopy", display_order: 20},
      %{name: "urine_trichomonas", label: "Trichomonas Vaginalis", type: "text", section: "6. Urinalysis - Microscopy", display_order: 21},
      %{name: "urine_crystals", label: "Crystals", type: "text", section: "6. Urinalysis - Microscopy", display_order: 22},
      %{name: "urine_casts", label: "Casts", type: "text", section: "6. Urinalysis - Microscopy", display_order: 23},
      %{name: "urine_epithelial_cells", label: "Epithelial Cells", type: "text", section: "6. Urinalysis - Microscopy", display_order: 24},
      %{name: "urine_parasites", label: "Parasites", type: "text", section: "6. Urinalysis - Microscopy", display_order: 25},

      # -------------------------------------------------------------------------
      # 7. RANDOM BLOOD SUGAR
      # -------------------------------------------------------------------------
      %{
        name: "rbs",
        label: "Random Blood Sugar",
        type: "number",
        unit: "mmol/L",
        ref_range_min: 3.8,
        ref_range_max: 7.5,
        ref_range_text: "3.8 – 7.5 mmol/L",
        section: "7. Blood Sugar",
        required: true,
        display_order: 26
      },

      # -------------------------------------------------------------------------
      # 8. HEMOGLOBIN TEST (HB)
      # -------------------------------------------------------------------------
      %{
        name: "hb_test",
        label: "HB Test",
        type: "number",
        unit: "g/dl",
        ref_range_min: 12.5,
        ref_range_max: 16.5,
        ref_range_text: "12.5-16.5 g/dl",
        section: "8. HB Test",
        required: true,
        display_order: 27
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

IO.puts("✓ Inserted #{length(templates)} test templates")
IO.puts("\n🎉 Templates seeded successfully!")
IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("STANDALONE TESTS:")
IO.puts(String.duplicate("=", 50))
IO.puts("  1. Hemoglobin Test (HGB)")
IO.puts("  2. Pregnancy Test (UPT)")
IO.puts("  3. Calcium Test (Ca)")
IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("ANC PROFILE (8 TESTS):")
IO.puts(String.duplicate("=", 50))
IO.puts("  1. Hemoglobin")
IO.puts("  2. HIV Test")
IO.puts("  3. ABO Grouping & Rhesus Factor")
IO.puts("  4. Hepatitis B (HBsAg)")
IO.puts("  5. VDRL Test")
IO.puts("  6. Urinalysis (Physical, Chemical, Microscopy)")
IO.puts("  7. Random Blood Sugar (RBS)")
IO.puts("  8. HB Test")
