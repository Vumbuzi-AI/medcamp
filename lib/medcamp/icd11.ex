defmodule Medcamp.Icd11 do
  @moduledoc """
  Common ICD-11 codes for diagnosis. Returns a static list of code/title pairs
  for use in dropdowns. No API required.
  """

  @doc "Returns list of {label, code} for select options"
  def options do
    common_codes()
    |> Enum.map(fn {code, title} -> {"#{code} - #{title}", code} end)
    |> Enum.sort_by(fn {_label, code} -> code end)
  end

  @doc "Returns list of {code, title} tuples"
  def list do
    common_codes()
  end

  defp common_codes do
    [
      # Infectious diseases
      {"1A00", "Cholera"},
      {"1B50", "Plasmodium falciparum malaria"},
      {"1B51", "Plasmodium vivax malaria"},
      {"1B54", "Unspecified malaria"},
      {"1F00", "HIV disease"},
      {"1A0Z", "Typhoid fever"},
      {"1C10", "Tuberculosis of the respiratory system"},
      # Respiratory
      {"CA40", "Essential (primary) hypertension"},
      {"BA00", "Asthma"},
      {"CA42", "Pneumonia"},
      {"CA43", "Chronic obstructive pulmonary disease"},
      # Digestive
      {"DA64", "Acute gastroenteritis"},
      {"DA62", "Gastritis"},
      {"DA70", "Peptic ulcer disease"},
      # Skin
      {"EA80", "Atopic dermatitis"},
      {"EA90", "Urticaria"},
      {"1F28", "Herpes simplex"},
      # Musculoskeletal
      {"FB32", "Low back pain"},
      {"FA00", "Osteoarthritis"},
      {"FA10", "Rheumatoid arthritis"},
      # Endocrine
      {"5A10", "Type 2 diabetes mellitus"},
      {"5A11", "Type 1 diabetes mellitus"},
      {"5A00", "Hyperthyroidism"},
      {"5A01", "Hypothyroidism"},
      # Mental health
      {"6A70", "Depressive disorder"},
      {"6B40", "Generalised anxiety disorder"},
      # Pregnancy
      {"JA00", "Pregnancy"},
      {"JA41", "Anaemia in pregnancy"},
      # Symptoms
      {"ME04", "Fever"},
      {"MD94", "Headache"},
      {"ME11", "Cough"},
      {"MD12", "Abdominal pain"},
      {"ME25", "Fatigue"},
      # Injuries
      {"NA01", "Fracture of forearm"},
      {"NE20", "Superficial injury"},
      # Other common
      {"BA61", "Acute upper respiratory infection"},
      {"BA62", "Acute lower respiratory infection"},
      {"3B62", "Iron deficiency anaemia"},
      {"DA84", "Constipation"},
      {"DB98", "Urinary tract infection"},
      {"2B50", "Benign prostatic hyperplasia"},
      {"GC10", "Uncomplicated pregnancy"},
      {"4A42", "Epilepsy"}
    ]
  end
end
