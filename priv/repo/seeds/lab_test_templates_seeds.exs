# Run with: mix run priv/repo/seeds/lab_test_templates_seeds.exs

alias Medcamp.Repo
alias Medcamp.LabTestTemplates.{LabTestCategory, LabTestTemplate}

# =========================================================================
# CATEGORIES
# =========================================================================

categories = [
  %{name: "Blood Chemistry", description: "Blood chemistry and biochemistry tests", display_order: 1},
  %{name: "Haematology", description: "Complete blood count and related tests", display_order: 2},
  %{name: "Serology", description: "Antibody and antigen tests", display_order: 3},
  %{name: "Urinalysis", description: "Urine examination tests", display_order: 4},
  %{name: "Stool Analysis", description: "Stool examination tests", display_order: 5},
  %{name: "Microbiology", description: "Culture and sensitivity tests", display_order: 6},
  %{name: "Hormones", description: "Hormone level tests", display_order: 7},
  %{name: "Other", description: "Other laboratory tests", display_order: 8}
]

Enum.each(categories, fn cat ->
  %LabTestCategory{}
  |> LabTestCategory.changeset(cat)
  |> Repo.insert!(on_conflict: :nothing)
end)

IO.puts("✓ Inserted #{length(categories)} categories")

# Helper to get category ID
get_category_id = fn name ->
  Repo.get_by!(LabTestCategory, name: name).id
end

# =========================================================================
# TEST TEMPLATES
# =========================================================================

templates = [
  # ---------------------------------------------------------------------------
  # CALCIUM TEST
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

  # ---------------------------------------------------------------------------
  # FASTING BLOOD SUGAR
  # ---------------------------------------------------------------------------
  %{
    name: "Fasting Blood Sugar",
    short_name: "FBS",
    category_name: "Blood Chemistry",
    field_definitions: [
      %{
        name: "fbs",
        label: "Fasting Blood Sugar",
        type: "number",
        unit: "mmol/L",
        ref_range_min: 3.8,
        ref_range_max: 5.5,
        ref_range_text: "3.8 – 5.5 mmol/L",
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # RANDOM BLOOD SUGAR
  # ---------------------------------------------------------------------------
  %{
    name: "Random Blood Sugar",
    short_name: "RBS",
    category_name: "Blood Chemistry",
    field_definitions: [
      %{
        name: "rbs",
        label: "Random Blood Sugar",
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

  # ---------------------------------------------------------------------------
  # FULL HAEMOGRAM TEST (FBC)
  # ---------------------------------------------------------------------------
  %{
    name: "Full Haemogram Test (FBC)",
    short_name: "FBC",
    category_name: "Haematology",
    field_definitions: [
      %{name: "wbc", label: "WBC", type: "number", unit: "10^9/l", ref_range_text: "5 - 10 10^9/l", ref_range_min: 5, ref_range_max: 10, required: true, display_order: 1},
      %{name: "lym", label: "LYM", type: "number", unit: "10^9/l", ref_range_text: "1 - 3 10^9/l", ref_range_min: 1, ref_range_max: 3, required: true, display_order: 2},
      %{name: "lym_percent", label: "LYM%", type: "number", unit: "%", ref_range_text: "20 - 50 %", ref_range_min: 20, ref_range_max: 50, required: true, display_order: 3},
      %{name: "mid", label: "MID", type: "number", unit: "10^9/l", ref_range_text: "0.1 - 1.5 10^9/l", ref_range_min: 0.1, ref_range_max: 1.5, required: true, display_order: 4},
      %{name: "mid_percent", label: "MID%", type: "number", unit: "%", ref_range_text: "2 - 10 %", ref_range_min: 2, ref_range_max: 10, required: true, display_order: 5},
      %{name: "gra", label: "GRA", type: "number", unit: "10^9/l", ref_range_text: "2 - 8 10^9/l", ref_range_min: 2, ref_range_max: 8, required: true, display_order: 6},
      %{name: "gra_percent", label: "GRA%", type: "number", unit: "%", ref_range_text: "40 - 70 %", ref_range_min: 40, ref_range_max: 70, required: true, display_order: 7},
      %{name: "hgb", label: "HGB", type: "number", unit: "g/dl", ref_range_text: "11.5 - 16.5g/dl", ref_range_min: 11.5, ref_range_max: 16.5, required: true, display_order: 8},
      %{name: "mch", label: "MCH", type: "number", unit: "pg", ref_range_text: "25 - 33 pg", ref_range_min: 25, ref_range_max: 33, required: true, display_order: 9},
      %{name: "mchc", label: "MCHC", type: "number", unit: "g/dl", ref_range_text: "31 - 34 g/dl", ref_range_min: 31, ref_range_max: 34, required: true, display_order: 10},
      %{name: "rbc", label: "RBC", type: "number", unit: "10^12/l", ref_range_text: "4 - 5.2 10^12/l", ref_range_min: 4, ref_range_max: 5.2, required: true, display_order: 11},
      %{name: "mcv", label: "MCV", type: "number", unit: "fl", ref_range_text: "78 - 94 fl", ref_range_min: 78, ref_range_max: 94, required: true, display_order: 12},
      %{name: "hct", label: "HCT", type: "number", unit: "%", ref_range_text: "35 - 45 %", ref_range_min: 35, ref_range_max: 45, required: true, display_order: 13},
      %{name: "rdw", label: "RDW", type: "number", unit: "%", ref_range_text: "11 - 16 %", ref_range_min: 11, ref_range_max: 16, required: true, display_order: 14},
      %{name: "plt", label: "PLT", type: "number", unit: "10^9/l", ref_range_text: "150 - 450 10^9/l", ref_range_min: 150, ref_range_max: 450, required: true, display_order: 15},
      %{name: "mpv", label: "MPV", type: "number", unit: "fl", ref_range_text: "7 - 11fl", ref_range_min: 7, ref_range_max: 11, required: true, display_order: 16}
    ]
  },

  # ---------------------------------------------------------------------------
  # LIVER FUNCTION TEST (LFT)
  # ---------------------------------------------------------------------------
  %{
    name: "Liver Function Test",
    short_name: "LFT",
    category_name: "Blood Chemistry",
    field_definitions: [
      %{name: "ast", label: "AST", type: "number", unit: "U/L", ref_range_text: "5 – 40 U/L", ref_range_min: 5, ref_range_max: 40, required: true, display_order: 1},
      %{name: "alt", label: "ALT", type: "number", unit: "U/L", ref_range_text: "5 – 40 U/L", ref_range_min: 5, ref_range_max: 40, required: true, display_order: 2},
      %{name: "alp", label: "ALP", type: "number", unit: "U/L", ref_range_text: "30 – 110 U/L", ref_range_min: 30, ref_range_max: 110, required: true, display_order: 3},
      %{name: "albumin", label: "Albumin", type: "number", unit: "g/L", ref_range_text: "25 – 55 g/L", ref_range_min: 25, ref_range_max: 55, required: true, display_order: 4},
      %{name: "t_bilirubin", label: "T.Bilirubin", type: "number", unit: "umol/L", ref_range_text: "3 – 23 umol/L", ref_range_min: 3, ref_range_max: 23, required: true, display_order: 5},
      %{name: "d_bilirubin", label: "D.Bilirubin", type: "number", unit: "umol/L", ref_range_text: "0 - 5.1 umol/L", ref_range_min: 0, ref_range_max: 5.1, required: true, display_order: 6},
      %{name: "ggt", label: "GGT", type: "number", unit: "U/L", ref_range_text: "10 - 55 U/L", ref_range_min: 10, ref_range_max: 55, required: true, display_order: 7}
    ]
  },

  # ---------------------------------------------------------------------------
  # RENAL FUNCTION TEST (RFT)
  # ---------------------------------------------------------------------------
  %{
    name: "Renal Function Test",
    short_name: "RFT",
    category_name: "Blood Chemistry",
    field_definitions: [
      %{name: "urea", label: "Urea", type: "number", unit: "mmol/L", ref_range_text: "1.7 – 8.3mmol/L", ref_range_min: 1.7, ref_range_max: 8.3, required: true, display_order: 1},
      %{name: "creatinine", label: "Creatinine", type: "number", unit: "mmol/L", ref_range_text: "35-120mmol/L", ref_range_min: 35, ref_range_max: 120, required: true, display_order: 2},
      %{name: "sodium", label: "Sodium", type: "number", unit: "mmol/L", ref_range_text: "135-150 mmol/L", ref_range_min: 135, ref_range_max: 150, required: true, display_order: 3},
      %{name: "potassium", label: "Potassium", type: "number", unit: "mmol/L", ref_range_text: "3.5 – 5.5mmol/L", ref_range_min: 3.5, ref_range_max: 5.5, required: true, display_order: 4},
      %{name: "chloride", label: "Chloride", type: "number", unit: "mmol/L", ref_range_text: "95 – 115mmol/L", ref_range_min: 95, ref_range_max: 115, required: true, display_order: 5}
    ]
  },

  # ---------------------------------------------------------------------------
  # URIC ACID
  # ---------------------------------------------------------------------------
  %{
    name: "Uric Acid",
    short_name: "UA",
    category_name: "Blood Chemistry",
    field_definitions: [
      %{
        name: "uric_acid",
        label: "Uric Acid",
        type: "number",
        unit: "umol/L",
        ref_range_min: 200,
        ref_range_max: 420,
        ref_range_text: "200 – 420 umol/L",
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # HIV TEST
  # ---------------------------------------------------------------------------
  %{
    name: "HIV Test",
    short_name: "HIV",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "hiv_test",
        label: "HIV Test",
        type: "select",
        options: ["Negative", "Positive", "Indeterminate"],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # H.PYLORI ANTIGEN TEST
  # ---------------------------------------------------------------------------
  %{
    name: "H.Pylori Antigen Test",
    short_name: "H.Pylori",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "h_pylori_test",
        label: "H.PYLORI TEST",
        type: "select",
        options: ["Negative", "Positive"],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # VDRL TEST
  # ---------------------------------------------------------------------------
  %{
    name: "VDRL Test",
    short_name: "VDRL",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "vdrl_test",
        label: "VDRL Test",
        type: "select",
        options: ["Non-Reactive", "Reactive", "Weakly Reactive"],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # HEPATITIS B TEST
  # ---------------------------------------------------------------------------
  %{
    name: "Hepatitis B Test",
    short_name: "HBsAg",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "hbsag_test",
        label: "HBsAg Test",
        type: "select",
        options: ["Negative", "Positive"],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # MALARIA RDT
  # ---------------------------------------------------------------------------
  %{
    name: "Malaria RDT",
    short_name: "mRDT",
    category_name: "Serology",
    field_definitions: [
      %{
        name: "malaria_rdt",
        label: "Malaria RDT",
        type: "select",
        options: ["Negative", "Positive (P. falciparum)", "Positive (P. vivax)", "Positive (Mixed)"],
        required: true,
        display_order: 1
      }
    ]
  },

  # ---------------------------------------------------------------------------
  # SALMONELLA TEST
  # ---------------------------------------------------------------------------
  %{
    name: "Salmonella Test (Widal)",
    short_name: "Widal",
    category_name: "Serology",
    field_definitions: [
      %{name: "typhi_o", label: "S. Typhi O", type: "text", display_order: 1},
      %{name: "typhi_h", label: "S. Typhi H", type: "text", display_order: 2},
      %{name: "paratyphi_a_o", label: "S. Paratyphi A O", type: "text", display_order: 3},
      %{name: "paratyphi_a_h", label: "S. Paratyphi A H", type: "text", display_order: 4},
      %{name: "paratyphi_b_o", label: "S. Paratyphi B O", type: "text", display_order: 5},
      %{name: "paratyphi_b_h", label: "S. Paratyphi B H", type: "text", display_order: 6}
    ]
  },

  # ---------------------------------------------------------------------------
  # ROUTINE URINALYSIS
  # ---------------------------------------------------------------------------
  %{
    name: "Routine Urinalysis",
    short_name: "Urinalysis",
    category_name: "Urinalysis",
    field_definitions: [
      # Physical examination
      %{name: "appearance", label: "Appearance", type: "text", section: "Physical", display_order: 1},
      %{name: "color", label: "Color", type: "text", section: "Physical", display_order: 2},

      # Chemical examination
      %{name: "leukocytes", label: "Leukocytes", type: "text", section: "Chemical", display_order: 3},
      %{name: "bilirubin", label: "Bilirubin", type: "text", section: "Chemical", display_order: 4},
      %{name: "ketones", label: "Ketones", type: "text", section: "Chemical", display_order: 5},
      %{name: "nitrites", label: "Nitrites", type: "text", section: "Chemical", display_order: 6},
      %{name: "blood", label: "Blood", type: "text", section: "Chemical", display_order: 7},
      %{name: "protein", label: "Protein", type: "text", section: "Chemical", display_order: 8},
      %{name: "ph", label: "PH", type: "number", ref_range_text: "4.5 - 7.5", ref_range_min: 4.5, ref_range_max: 7.5, section: "Chemical", display_order: 9},
      %{name: "sg", label: "S.G", type: "text", section: "Chemical", display_order: 10},
      %{name: "glucose", label: "Glucose", type: "text", section: "Chemical", display_order: 11},

      # Microscopy
      %{name: "wbc_pus_cells", label: "Wbc (Pus cells)", type: "text", section: "Urine Microscopy", display_order: 12},
      %{name: "rbcs", label: "RBCs", type: "text", section: "Urine Microscopy", display_order: 13},
      %{name: "yeast_cells", label: "Yeast Cells", type: "text", section: "Urine Microscopy", display_order: 14},
      %{name: "trichomonas_vaginalis", label: "Trichomonas Vaginalis", type: "text", section: "Urine Microscopy", display_order: 15},
      %{name: "crystals", label: "Crystals", type: "text", section: "Urine Microscopy", display_order: 16},
      %{name: "casts", label: "Casts", type: "text", section: "Urine Microscopy", display_order: 17},
      %{name: "epithelial_cells", label: "Epithelial Cells", type: "text", section: "Urine Microscopy", display_order: 18},
      %{name: "parasites", label: "Parasites", type: "text", section: "Urine Microscopy", display_order: 19}
    ]
  },

  # ---------------------------------------------------------------------------
  # STOOL FOR OVA AND CYSTS
  # ---------------------------------------------------------------------------
  %{
    name: "Stool for Ova/Cysts",
    short_name: "Stool O/C",
    category_name: "Stool Analysis",
    field_definitions: [
      %{name: "appearance", label: "Appearance", type: "text", section: "Physical", display_order: 1},
      %{name: "cysts", label: "Cysts", type: "text", section: "Stool Microscopy", display_order: 2},
      %{name: "ova", label: "Ova", type: "text", section: "Stool Microscopy", display_order: 3},
      %{name: "pus_cells", label: "Pus Cells", type: "text", section: "Stool Microscopy", display_order: 4},
      %{name: "yeast_cells", label: "Yeast Cells", type: "text", section: "Stool Microscopy", display_order: 5},
      %{name: "blood", label: "Blood", type: "text", section: "Stool Microscopy", display_order: 6},
      %{name: "others", label: "Others", type: "text", section: "Stool Microscopy", display_order: 7}
    ]
  },

  # ---------------------------------------------------------------------------
  # HVS TEST
  # ---------------------------------------------------------------------------
  %{
    name: "HVS Test",
    short_name: "HVS",
    category_name: "Microbiology",
    field_definitions: [
      %{name: "hvs_wet_prep", label: "HVS WET PREP", type: "text", display_order: 1},
      %{name: "hvs_gram_stain", label: "HVS GRAM STAIN", type: "text", display_order: 2}
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
IO.puts("\n🎉 Lab test templates seeded successfully!")
