defmodule Medcamp.Repo.Migrations.InsertLabTests do
  use Ecto.Migration

  def up do
    # Insert lab tests data
    execute """
    INSERT INTO lab_tests (name, price, inserted_at, updated_at) VALUES
    ('Full Haemogram (FHG)', 1000, NOW(), NOW()),
    ('Stool for Ova/Cyst', 300, NOW(), NOW()),
    ('Routine Urinalysis', 250, NOW(), NOW()),
    ('Random Blood Sugar', 200, NOW(), NOW()),
    ('Fasting Blood Sugar', 200, NOW(), NOW()),
    ('H. Pylori', 700, NOW(), NOW()),
    ('Salmonella Antigen', 700, NOW(), NOW()),
    ('Rheumatoid Factor (RF)', 500, NOW(), NOW()),
    ('ASOT', 500, NOW(), NOW()),
    ('ABO Grouping', 300, NOW(), NOW()),
    ('HIV', 250, NOW(), NOW()),
    ('UEC/Renal Function Test', 2000, NOW(), NOW()),
    ('Urea', 700, NOW(), NOW()),
    ('Creatinine', 700, NOW(), NOW()),
    ('Sodium', 700, NOW(), NOW()),
    ('Potassium', 700, NOW(), NOW()),
    ('Chloride', 700, NOW(), NOW()),
    ('Liver Function Tests', 2500, NOW(), NOW()),
    ('Albumin', 700, NOW(), NOW()),
    ('Alkaline Phosphatase', 700, NOW(), NOW()),
    ('Total Bilirubin', 700, NOW(), NOW()),
    ('Direct Bilirubin', 700, NOW(), NOW()),
    ('Alanine Aminotransferase', 700, NOW(), NOW()),
    ('Aspartate Aminotransferase', 700, NOW(), NOW()),
    ('Gamma-Glutamyl Transferase', 700, NOW(), NOW()),
    ('High Vaginal Swab', 650, NOW(), NOW()),
    ('Urethral Swab', 650, NOW(), NOW()),
    ('STI Package', 2000, NOW(), NOW()),
    ('Antenatal Tests', 2000, NOW(), NOW()),
    ('VDRL', 500, NOW(), NOW()),
    ('Hepatitis Surface Antigen', 600, NOW(), NOW()),
    ('Malaria Rapid', 400, NOW(), NOW()),
    ('Malaria Microscopic', 200, NOW(), NOW()),
    ('Potassium Hydroxide (KOH)', 500, NOW(), NOW()),
    ('ESR', 400, NOW(), NOW()),
    ('Calcium', 700, NOW(), NOW()),
    ('Uric Acid', 700, NOW(), NOW()),
    ('Lipid Profile', 2000, NOW(), NOW()),
    ('Total Cholesterol', 700, NOW(), NOW()),
    ('High Density Lipoprotein', 700, NOW(), NOW()),
    ('Triglycerides', 700, NOW(), NOW()),
    ('Haemoglobin Level', 500, NOW(), NOW())
    """
  end

  def down do
    # Remove the inserted lab tests
    execute """
    DELETE FROM lab_tests WHERE name IN (
      'Full Haemogram (FHG)',
      'Stool for Ova/Cyst',
      'Routine Urinalysis',
      'Random Blood Sugar',
      'Fasting Blood Sugar',
      'H. Pylori',
      'Salmonella Antigen',
      'Rheumatoid Factor (RF)',
      'ASOT',
      'ABO Grouping',
      'HIV',
      'UEC/Renal Function Test',
      'Urea',
      'Creatinine',
      'Sodium',
      'Potassium',
      'Chloride',
      'Liver Function Tests',
      'Albumin',
      'Alkaline Phosphatase',
      'Total Bilirubin',
      'Direct Bilirubin',
      'Alanine Aminotransferase',
      'Aspartate Aminotransferase',
      'Gamma-Glutamyl Transferase',
      'High Vaginal Swab',
      'Urethral Swab',
      'STI Package',
      'Antenatal Tests',
      'VDRL',
      'Hepatitis Surface Antigen',
      'Malaria Rapid',
      'Malaria Microscopic',
      'Potassium Hydroxide (KOH)',
      'ESR',
      'Calcium',
      'Uric Acid',
      'Lipid Profile',
      'Total Cholesterol',
      'High Density Lipoprotein',
      'Triglycerides',
      'Haemoglobin Level'
    )
    """
  end
end
