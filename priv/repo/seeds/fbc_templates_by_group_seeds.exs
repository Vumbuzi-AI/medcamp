# Run with: mix run priv/repo/seeds/fbc_templates_by_group_seeds.exs
#
# This file contains Full Haemogram Test (FBC) templates tailored to specific
# patient groups so that reference ranges match the population being tested:
#
#   - Male (13+ yrs)
#   - Female (13+ yrs)
#   - Children (5-12 yrs)
#   - Babies (0-5 yrs)
#
# Reference ranges sourced from Glocal Healthcare Centre of Excellence
# laboratory report templates.

alias Medcamp.Repo
alias Medcamp.LabTestTemplates.{LabTestCategory, LabTestTemplate}

# Helper to get category ID
get_category_id = fn name ->
  Repo.get_by!(LabTestCategory, name: name).id
end

# =========================================================================
# FBC TEMPLATES BY PATIENT GROUP
# =========================================================================

templates = [
  # ---------------------------------------------------------------------------
  # FULL HAEMOGRAM TEST (FBC) - MALE (13+ YRS)
  # ---------------------------------------------------------------------------
  %{
    name: "Full Haemogram Test (FBC) - Male (13+ yrs)",
    short_name: "FBC - Male",
    category_name: "Haematology",
    field_definitions: [
      %{name: "wbc", label: "WBC", type: "number", unit: "10^9/l", ref_range_text: "5 - 10 10^9/l", ref_range_min: 5, ref_range_max: 10, required: true, display_order: 1},
      %{name: "lym", label: "LYM", type: "number", unit: "10^9/l", ref_range_text: "1 - 3 10^9/l", ref_range_min: 1, ref_range_max: 3, required: true, display_order: 2},
      %{name: "lym_percent", label: "LYM%", type: "number", unit: "%", ref_range_text: "20 - 50 %", ref_range_min: 20, ref_range_max: 50, required: true, display_order: 3},
      %{name: "mid", label: "MID", type: "number", unit: "10^9/l", ref_range_text: "0.1 - 1.5 10^9/l", ref_range_min: 0.1, ref_range_max: 1.5, required: true, display_order: 4},
      %{name: "mid_percent", label: "MID%", type: "number", unit: "%", ref_range_text: "2 - 10 %", ref_range_min: 2, ref_range_max: 10, required: true, display_order: 5},
      %{name: "gra", label: "GRA", type: "number", unit: "10^9/l", ref_range_text: "2 - 8 10^9/l", ref_range_min: 2, ref_range_max: 8, required: true, display_order: 6},
      %{name: "gra_percent", label: "GRA%", type: "number", unit: "%", ref_range_text: "40 - 70 %", ref_range_min: 40, ref_range_max: 70, required: true, display_order: 7},
      %{name: "hgb", label: "HGB", type: "number", unit: "g/dl", ref_range_text: "11.5 - 16.5 g/dl", ref_range_min: 11.5, ref_range_max: 16.5, required: true, display_order: 8},
      %{name: "mch", label: "MCH", type: "number", unit: "pg", ref_range_text: "25 - 33 pg", ref_range_min: 25, ref_range_max: 33, required: true, display_order: 9},
      %{name: "mchc", label: "MCHC", type: "number", unit: "g/dl", ref_range_text: "31 - 34 g/dl", ref_range_min: 31, ref_range_max: 34, required: true, display_order: 10},
      %{name: "rbc", label: "RBC", type: "number", unit: "10^12/l", ref_range_text: "4 - 5.2 10^12/l", ref_range_min: 4, ref_range_max: 5.2, required: true, display_order: 11},
      %{name: "mcv", label: "MCV", type: "number", unit: "fl", ref_range_text: "78 - 94 fl", ref_range_min: 78, ref_range_max: 94, required: true, display_order: 12},
      %{name: "hct", label: "HCT", type: "number", unit: "%", ref_range_text: "35 - 45 %", ref_range_min: 35, ref_range_max: 45, required: true, display_order: 13},
      %{name: "rdw", label: "RDW", type: "number", unit: "%", ref_range_text: "11 - 16 %", ref_range_min: 11, ref_range_max: 16, required: true, display_order: 14},
      %{name: "plt", label: "PLT", type: "number", unit: "10^9/l", ref_range_text: "150 - 450 10^9/l", ref_range_min: 150, ref_range_max: 450, required: true, display_order: 15},
      %{name: "mpv", label: "MPV", type: "number", unit: "fl", ref_range_text: "7 - 11 fl", ref_range_min: 7, ref_range_max: 11, required: true, display_order: 16}
    ]
  },

  # ---------------------------------------------------------------------------
  # FULL HAEMOGRAM TEST (FBC) - FEMALE (13+ YRS)
  # ---------------------------------------------------------------------------
  %{
    name: "Full Haemogram Test (FBC) - Female (13+ yrs)",
    short_name: "FBC - Female",
    category_name: "Haematology",
    field_definitions: [
      %{name: "wbc", label: "WBC", type: "number", unit: "10^9/l", ref_range_text: "4.0 - 11.1 10^9/l", ref_range_min: 4.0, ref_range_max: 11.1, required: true, display_order: 1},
      %{name: "lym", label: "LYM", type: "number", unit: "10^9/l", ref_range_text: "0.8 - 4.0 10^9/l", ref_range_min: 0.8, ref_range_max: 4.0, required: true, display_order: 2},
      %{name: "lym_percent", label: "LYM%", type: "number", unit: "%", ref_range_text: "20 - 40 %", ref_range_min: 20, ref_range_max: 40, required: true, display_order: 3},
      %{name: "mid", label: "MID", type: "number", unit: "10^9/l", ref_range_text: "0.1 - 1.5 10^9/l", ref_range_min: 0.1, ref_range_max: 1.5, required: true, display_order: 4},
      %{name: "mid_percent", label: "MID%", type: "number", unit: "%", ref_range_text: "3.0 - 15.0 %", ref_range_min: 3.0, ref_range_max: 15.0, required: true, display_order: 5},
      %{name: "gra", label: "GRA", type: "number", unit: "10^9/l", ref_range_text: "2.0 - 7.0 10^9/l", ref_range_min: 2.0, ref_range_max: 7.0, required: true, display_order: 6},
      %{name: "gra_percent", label: "GRA%", type: "number", unit: "%", ref_range_text: "50 - 70 %", ref_range_min: 50, ref_range_max: 70, required: true, display_order: 7},
      %{name: "hgb", label: "HGB", type: "number", unit: "g/dl", ref_range_text: "12.0 - 16.0 g/dl", ref_range_min: 12.0, ref_range_max: 16.0, required: true, display_order: 8},
      %{name: "mch", label: "MCH", type: "number", unit: "pg", ref_range_text: "27 - 34 pg", ref_range_min: 27, ref_range_max: 34, required: true, display_order: 9},
      %{name: "mchc", label: "MCHC", type: "number", unit: "g/dl", ref_range_text: "32 - 36 g/dl", ref_range_min: 32, ref_range_max: 36, required: true, display_order: 10},
      %{name: "rbc", label: "RBC", type: "number", unit: "10^12/l", ref_range_text: "3.5 - 5.5 10^12/l", ref_range_min: 3.5, ref_range_max: 5.5, required: true, display_order: 11},
      %{name: "mcv", label: "MCV", type: "number", unit: "fl", ref_range_text: "80 - 100 fl", ref_range_min: 80, ref_range_max: 100, required: true, display_order: 12},
      %{name: "hct", label: "HCT", type: "number", unit: "%", ref_range_text: "35 - 54 %", ref_range_min: 35, ref_range_max: 54, required: true, display_order: 13},
      %{name: "rdw", label: "RDW", type: "number", unit: "%", ref_range_text: "11 - 16 %", ref_range_min: 11, ref_range_max: 16, required: true, display_order: 14},
      %{name: "plt", label: "PLT", type: "number", unit: "10^9/l", ref_range_text: "140 - 450 10^9/l", ref_range_min: 140, ref_range_max: 450, required: true, display_order: 15},
      %{name: "mpv", label: "MPV", type: "number", unit: "fl", ref_range_text: "6.5 - 12 fl", ref_range_min: 6.5, ref_range_max: 12, required: true, display_order: 16}
    ]
  },

  # ---------------------------------------------------------------------------
  # FULL HAEMOGRAM TEST (FBC) - CHILDREN (5-12 YRS)
  # ---------------------------------------------------------------------------
  %{
    name: "Full Haemogram Test (FBC) - Children (5-12 yrs)",
    short_name: "FBC - Children",
    category_name: "Haematology",
    field_definitions: [
      %{name: "wbc", label: "WBC", type: "number", unit: "10^9/l", ref_range_text: "6.0 - 17.0 10^9/l", ref_range_min: 6.0, ref_range_max: 17.0, required: true, display_order: 1},
      %{name: "lym", label: "LYM", type: "number", unit: "10^9/l", ref_range_text: "3.0 - 9.5 10^9/l", ref_range_min: 3.0, ref_range_max: 9.5, required: true, display_order: 2},
      %{name: "lym_percent", label: "LYM%", type: "number", unit: "%", ref_range_text: "45.0 - 70.0 %", ref_range_min: 45.0, ref_range_max: 70.0, required: true, display_order: 3},
      %{name: "mid", label: "MID", type: "number", unit: "10^9/l", ref_range_text: "0.1 - 1.0 10^9/l", ref_range_min: 0.1, ref_range_max: 1.0, required: true, display_order: 4},
      %{name: "mid_percent", label: "MID%", type: "number", unit: "%", ref_range_text: "3.0 - 15.0 %", ref_range_min: 3.0, ref_range_max: 15.0, required: true, display_order: 5},
      %{name: "gra", label: "GRA", type: "number", unit: "10^9/l", ref_range_text: "1.5 - 7.5 10^9/l", ref_range_min: 1.5, ref_range_max: 7.5, required: true, display_order: 6},
      %{name: "gra_percent", label: "GRA%", type: "number", unit: "%", ref_range_text: "20.0 - 45.0 %", ref_range_min: 20.0, ref_range_max: 45.0, required: true, display_order: 7},
      %{name: "hgb", label: "HGB", type: "number", unit: "g/dl", ref_range_text: "11.0 - 13.5 g/dl", ref_range_min: 11.0, ref_range_max: 13.5, required: true, display_order: 8},
      %{name: "mch", label: "MCH", type: "number", unit: "pg", ref_range_text: "24 - 32 pg", ref_range_min: 24, ref_range_max: 32, required: true, display_order: 9},
      %{name: "mchc", label: "MCHC", type: "number", unit: "g/dl", ref_range_text: "32 - 36 g/dl", ref_range_min: 32, ref_range_max: 36, required: true, display_order: 10},
      %{name: "rbc", label: "RBC", type: "number", unit: "10^12/l", ref_range_text: "3.5 - 5.7 10^12/l", ref_range_min: 3.5, ref_range_max: 5.7, required: true, display_order: 11},
      %{name: "mcv", label: "MCV", type: "number", unit: "fl", ref_range_text: "74 - 87 fl", ref_range_min: 74, ref_range_max: 87, required: true, display_order: 12},
      %{name: "hct", label: "HCT", type: "number", unit: "%", ref_range_text: "28 - 45 %", ref_range_min: 28, ref_range_max: 45, required: true, display_order: 13},
      %{name: "rdw", label: "RDW", type: "number", unit: "%", ref_range_text: "11 - 16 %", ref_range_min: 11, ref_range_max: 16, required: true, display_order: 14},
      %{name: "plt", label: "PLT", type: "number", unit: "10^9/l", ref_range_text: "140 - 450 10^9/l", ref_range_min: 140, ref_range_max: 450, required: true, display_order: 15},
      %{name: "mpv", label: "MPV", type: "number", unit: "fl", ref_range_text: "6.5 - 12 fl", ref_range_min: 6.5, ref_range_max: 12, required: true, display_order: 16}
    ]
  },

  # ---------------------------------------------------------------------------
  # FULL HAEMOGRAM TEST (FBC) - BABIES (0-5 YRS)
  # ---------------------------------------------------------------------------
  %{
    name: "Full Haemogram Test (FBC) - Babies (0-5 yrs)",
    short_name: "FBC - Babies",
    category_name: "Haematology",
    field_definitions: [
      %{name: "wbc", label: "WBC", type: "number", unit: "10^9/l", ref_range_text: "6.0 - 17.0 10^9/l", ref_range_min: 6.0, ref_range_max: 17.0, required: true, display_order: 1},
      %{name: "lym", label: "LYM", type: "number", unit: "10^9/l", ref_range_text: "3.0 - 9.5 10^9/l", ref_range_min: 3.0, ref_range_max: 9.5, required: true, display_order: 2},
      %{name: "lym_percent", label: "LYM%", type: "number", unit: "%", ref_range_text: "45.0 - 70.0 %", ref_range_min: 45.0, ref_range_max: 70.0, required: true, display_order: 3},
      %{name: "mid", label: "MID", type: "number", unit: "10^9/l", ref_range_text: "0.1 - 1.0 10^9/l", ref_range_min: 0.1, ref_range_max: 1.0, required: true, display_order: 4},
      %{name: "mid_percent", label: "MID%", type: "number", unit: "%", ref_range_text: "3.0 - 15.0 %", ref_range_min: 3.0, ref_range_max: 15.0, required: true, display_order: 5},
      %{name: "gra", label: "GRA", type: "number", unit: "10^9/l", ref_range_text: "1.5 - 7.5 10^9/l", ref_range_min: 1.5, ref_range_max: 7.5, required: true, display_order: 6},
      %{name: "gra_percent", label: "GRA%", type: "number", unit: "%", ref_range_text: "20.0 - 45.0 %", ref_range_min: 20.0, ref_range_max: 45.0, required: true, display_order: 7},
      %{name: "hgb", label: "HGB", type: "number", unit: "g/dl", ref_range_text: "11.0 - 13.5 g/dl", ref_range_min: 11.0, ref_range_max: 13.5, required: true, display_order: 8},
      %{name: "mch", label: "MCH", type: "number", unit: "pg", ref_range_text: "24 - 32 pg", ref_range_min: 24, ref_range_max: 32, required: true, display_order: 9},
      %{name: "mchc", label: "MCHC", type: "number", unit: "g/dl", ref_range_text: "32 - 36 g/dl", ref_range_min: 32, ref_range_max: 36, required: true, display_order: 10},
      %{name: "rbc", label: "RBC", type: "number", unit: "10^12/l", ref_range_text: "3.5 - 5.7 10^12/l", ref_range_min: 3.5, ref_range_max: 5.7, required: true, display_order: 11},
      %{name: "mcv", label: "MCV", type: "number", unit: "fl", ref_range_text: "74 - 87 fl", ref_range_min: 74, ref_range_max: 87, required: true, display_order: 12},
      %{name: "hct", label: "HCT", type: "number", unit: "%", ref_range_text: "28 - 45 %", ref_range_min: 28, ref_range_max: 45, required: true, display_order: 13},
      %{name: "rdw", label: "RDW", type: "number", unit: "%", ref_range_text: "11 - 16 %", ref_range_min: 11, ref_range_max: 16, required: true, display_order: 14},
      %{name: "plt", label: "PLT", type: "number", unit: "10^9/l", ref_range_text: "140 - 450 10^9/l", ref_range_min: 140, ref_range_max: 450, required: true, display_order: 15},
      %{name: "mpv", label: "MPV", type: "number", unit: "fl", ref_range_text: "6.5 - 12 fl", ref_range_min: 6.5, ref_range_max: 12, required: true, display_order: 16}
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

IO.puts("✓ Inserted #{length(templates)} FBC templates by patient group")
IO.puts("\n🎉 FBC templates by group seeded successfully!")
IO.puts("\nTemplates added:")
Enum.each(templates, fn t -> IO.puts("  - #{t.name} (#{t.short_name})") end)
