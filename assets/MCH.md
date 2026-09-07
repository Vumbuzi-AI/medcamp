# Kenya Mother & Child Health Handbook - Phoenix LiveView Project Context

## Overview

This document provides context for building a Phoenix LiveView application that digitizes Kenya's Mother & Child Health Handbook (MOH 216, Revised September 2020). The handbook is used throughout pregnancy, childbirth, and until the child reaches 5 years old.

---

## 1. APPLICATION STRUCTURE

### 1.1 Main Sections (Maps to Two Primary Sections in Handbook)

```
SECTION 1: Maternal Health (ANC, Childbirth, Postnatal Care)
SECTION 2: Child Health Monitoring (Birth to 5 years)
```

### 1.2 Core Modules to Build

```elixir
# Suggested Phoenix context modules
- Accounts (Users: Mothers, Fathers, Health Workers, CHVs)
- Maternal (Pregnancy tracking, ANC visits, Delivery, Postnatal)
- Child (Growth monitoring, Immunization, Development milestones)
- Appointments (Scheduling, Reminders)
- Education (Health information content from handbook)
```

---

## 2. MATERNAL PROFILE DATA STRUCTURES

### 2.1 Mother Registration Schema

```elixir
schema "mothers" do
  field :name, :string
  field :age, :integer
  field :gravida, :integer  # Total number of pregnancies
  field :parity, :integer   # Number of viable births
  field :height_cm, :decimal
  field :weight_kg, :decimal
  field :lmp, :date         # Last Menstrual Period
  field :edd, :date         # Expected Date of Delivery
  field :marital_status, :string
  field :education_level, :string
  field :telephone, :string

  # Address fields (Kenya administrative structure)
  field :county, :string
  field :subcounty, :string
  field :ward, :string
  field :town_village, :string
  field :estate_house_no, :string
  field :physical_address, :string

  # Next of Kin
  field :next_of_kin_name, :string
  field :next_of_kin_relationship, :string
  field :next_of_kin_phone, :string

  # Health facility info
  field :health_facility_name, :string
  field :kmhfl_code, :string  # Kenya Master Health Facility List
  field :anc_number, :string
  field :pnc_number, :string

  timestamps()
end
```

### 2.2 Medical & Surgical History

```elixir
schema "medical_histories" do
  belongs_to :mother, Mother

  field :surgical_operations, :string
  field :has_diabetes, :boolean, default: false
  field :has_hypertension, :boolean, default: false
  field :blood_transfusion_history, :string
  field :tuberculosis_history, :string
  field :drug_allergies, {:array, :string}
  field :other_allergies, {:array, :string}

  # Family history
  field :family_history_twins, :boolean
  field :family_history_tb, :boolean

  timestamps()
end
```

### 2.3 Previous Pregnancies

```elixir
schema "previous_pregnancies" do
  belongs_to :mother, Mother

  field :pregnancy_order, :integer  # 1st, 2nd, 3rd, etc.
  field :year, :integer
  field :anc_visits_count, :integer
  field :place_of_childbirth, :string
  field :gestation_weeks, :integer
  field :duration_of_labour, :string
  field :mode_of_delivery, :string  # Normal, C-Section, etc.
  field :birth_weight_grams, :integer
  field :sex, :string
  field :outcome, :string  # Live birth, Stillbirth, etc.
  field :puerperium, :string  # Postpartum period complications

  timestamps()
end
```

---

## 3. ANTENATAL CARE (ANC) TRACKING

### 3.1 Physical Examination (First Visit)

```elixir
schema "physical_examinations" do
  belongs_to :pregnancy, Pregnancy

  field :examination_date, :date
  field :bp_systolic, :integer
  field :bp_diastolic, :integer
  field :pulse_rate, :integer
  field :cvs_notes, :string    # Cardiovascular system
  field :respiratory_notes, :string
  field :breasts_notes, :string
  field :abdomen_notes, :string
  field :external_genitalia_notes, :string
  field :discharge_or_ulcer, :string

  timestamps()
end
```

### 3.2 Antenatal Profile (Lab Tests)

```elixir
schema "antenatal_profiles" do
  belongs_to :pregnancy, Pregnancy

  field :haemoglobin_hb, :decimal
  field :blood_group, :string      # A, B, AB, O
  field :rhesus_factor, :string    # Positive, Negative
  field :urinalysis, :string
  field :blood_rbs, :decimal       # Random Blood Sugar

  # TB Screening
  field :tb_screening_date, :date
  field :tb_screening_outcome, :string  # Negative, Positive
  field :ipt_date_given, :date     # Isoniazid Preventive Therapy
  field :ipt_next_visit, :date

  # Obstetric Ultrasound
  field :ultrasound_1_date, :date
  field :ultrasound_1_gestation, :integer
  field :ultrasound_2_date, :date
  field :ultrasound_2_gestation, :integer

  # Triple Testing (HIV/Syphilis/Hepatitis B)
  field :triple_test_date, :date
  field :hiv_status, :string       # Reactive, Non-Reactive, Not Tested, Inconclusive
  field :syphilis_status, :string
  field :hepatitis_b_status, :string
  field :hiv_retest_date, :date

  # Partner Testing
  field :couple_testing_done, :boolean
  field :partner_hiv_status, :string

  timestamps()
end
```

### 3.3 ANC Visit Schedule (8 Contacts Recommended)

```elixir
# Timing of ANC Contacts as per WHO/Kenya guidelines
@anc_schedule [
  %{contact: 1, timing: "Up to 12 weeks", gestation_weeks: 12},
  %{contact: "1a", timing: "13-16 weeks", gestation_weeks: 16},
  %{contact: 2, timing: "20 weeks", gestation_weeks: 20},
  %{contact: 3, timing: "26 weeks", gestation_weeks: 26},
  %{contact: 4, timing: "30 weeks", gestation_weeks: 30},
  %{contact: 5, timing: "34 weeks", gestation_weeks: 34},
  %{contact: 6, timing: "36 weeks", gestation_weeks: 36},
  %{contact: 7, timing: "38 weeks", gestation_weeks: 38},
  %{contact: 8, timing: "40 weeks", gestation_weeks: 40}
]
```

### 3.4 Present Pregnancy Visits

```elixir
schema "anc_visits" do
  belongs_to :pregnancy, Pregnancy

  field :contact_number, :integer
  field :visit_date, :date
  field :urine_test, :string
  field :muac_cm, :decimal      # Mid-Upper Arm Circumference
  field :bp_systolic, :integer
  field :bp_diastolic, :integer
  field :haemoglobin, :decimal
  field :pallor, :boolean
  field :gestation_weeks, :integer
  field :fundal_height, :decimal
  field :presentation, :string   # Cephalic, Breech, etc.
  field :lie, :string            # Longitudinal, Transverse
  field :foetal_heart_rate, :integer
  field :foetal_movement, :string
  field :next_visit_date, :date
  field :weight_kg, :decimal

  timestamps()
end
```

---

## 4. PREVENTIVE SERVICES

### 4.1 Tetanus Diphtheria (TD) Vaccination

```elixir
schema "td_vaccinations" do
  belongs_to :mother, Mother

  field :dose_number, :integer  # 1-5
  field :date_given, :date
  field :next_visit, :date

  timestamps()
end

# TD Schedule Rules:
# - 1st injection: First ANC visit
# - 2nd injection: 4 weeks after 1st, but 2 weeks before childbirth
# - 3rd injection: 6 months after 2nd
# - 4th injection: 1 year after 3rd or subsequent pregnancy
# - 5th injection: 1 year after 4th or subsequent pregnancy
# - 5 doses protect throughout childbearing years
# - Restart from TD-1 only if >10 years between 1st and 2nd pregnancy
```

### 4.2 Malaria Prophylaxis (IPTp-SP)

```elixir
schema "malaria_prophylaxis" do
  belongs_to :pregnancy, Pregnancy

  field :dose_number, :integer  # 1-6
  field :timing_weeks, :integer
  field :date_given, :date
  field :next_visit, :date

  timestamps()
end

# IPTp Schedule (SP at 4-week intervals from 13 weeks to term):
@iptp_schedule [
  %{dose: 1, timing: "13-16 weeks"},
  %{dose: 2, timing: "20 weeks"},
  %{dose: 3, timing: "26 weeks"},
  %{dose: 4, timing: "30 weeks"},
  %{dose: 5, timing: "34 weeks"},
  # No SP at 36 weeks if last dose <1 month ago
  %{dose: 6, timing: "38 weeks (if no dose in past month)"}
]
```

### 4.3 Iron and Folic Acid Supplementation (IFAS)

```elixir
schema "ifas_supplements" do
  belongs_to :pregnancy, Pregnancy

  field :contact_number, :integer
  field :gestation_weeks, :integer
  field :tablets_issued, :integer
  field :date_given, :date

  timestamps()
end

# IFAS Schedule (270 tablets total, 1 tablet/day with meals):
@ifas_schedule [
  %{contact: nil, weeks: "Up to 12", tablets: 60},
  %{contact: 1, weeks: "12", tablets: 56},
  %{contact: 2, weeks: "20", tablets: 42},
  %{contact: 3, weeks: "26", tablets: 28},
  %{contact: 4, weeks: "30", tablets: 28},
  %{contact: 5, weeks: "34", tablets: 14},
  %{contact: 6, weeks: "36", tablets: 14},
  %{contact: 7, weeks: "38", tablets: 14},
  %{contact: 8, weeks: "40", tablets: 14}
]

# Combined tablet: 60mg Iron + 400μg Folic Acid
```

### 4.4 Deworming

```elixir
# Mebendazole 500mg given once in the 2nd trimester
schema "deworming_maternal" do
  belongs_to :pregnancy, Pregnancy

  field :date_given, :date
  field :medication, :string, default: "Mebendazole 500mg"

  timestamps()
end
```

---

## 5. DANGER SIGNS (Critical Alert System)

### 5.1 Danger Signs During Pregnancy

```elixir
@danger_signs_pregnancy [
  "vaginal_bleeding",
  "severe_abdominal_pain",
  "severe_headache",
  "fever",
  "pale",
  "swelling_face_hands",
  "breaking_water",
  "convulsions_fits",
  "reduced_no_fetal_movement"
]

# Implement as alert/notification system in LiveView
# Should trigger immediate action recommendation
```

### 5.2 Danger Signs After Childbirth (Mother)

```elixir
@danger_signs_postpartum_mother [
  "heavy_bleeding",
  "fever",
  "severe_headache",
  "foul_smelling_vaginal_discharge",
  "fits_convulsions"
]
```

### 5.3 Danger Signs (Baby)

```elixir
@danger_signs_baby [
  "stops_breastfeeding_well",
  "difficult_fast_breathing",
  "feels_hot_or_unusually_cold",
  "becomes_less_active",
  "body_becomes_yellow"  # Jaundice - eyes, palms, soles
]
```

---

## 6. CHILDBIRTH RECORD

```elixir
schema "deliveries" do
  belongs_to :pregnancy, Pregnancy
  belongs_to :child, Child

  field :delivery_date, :date
  field :delivery_time, :time
  field :duration_of_pregnancy_weeks, :integer
  field :mode_of_delivery, :string  # Normal, C-Section, Assisted

  # Mother HIV status at delivery
  field :hiv_tested, :boolean
  field :hiv_status, :string

  # Baby placement
  field :skin_to_skin_immediately, :boolean

  # APGAR Scores
  field :apgar_1min, :integer
  field :apgar_5min, :integer
  field :apgar_10min, :integer
  field :resuscitation_done, :boolean

  # Complications
  field :blood_loss_ml, :integer
  field :pre_eclampsia, :boolean
  field :eclampsia, :boolean
  field :pph, :boolean  # Postpartum Hemorrhage
  field :obstructed_labour, :boolean
  field :meconium_stained_liquor_grade, :integer  # 0,1,2,3

  field :condition_of_mother, :string

  # Birth attendant
  field :conducted_by, :string  # Nurse, Midwife, Clinical Officer, Doctor

  # Medications given
  field :mother_oxytocin, :boolean
  field :mother_misoprostol, :boolean
  field :mother_carbetocin, :boolean
  field :mother_haart_regimen, :string

  field :baby_chx, :boolean     # Chlorhexidine 7.1%
  field :baby_vit_k, :boolean
  field :baby_teo, :boolean     # Tetracycline Eye Ointment
  field :baby_arv_prophylaxis, :string

  # Baby measurements
  field :birth_weight_grams, :integer
  field :birth_length_cm, :decimal
  field :head_circumference_cm, :decimal

  field :place_of_childbirth, :string
  field :health_facility_name, :string
  field :early_breastfeeding_within_1hr, :boolean

  timestamps()
end
```

---

## 7. POSTNATAL CARE (PNC)

### 7.1 PNC Visit Schedule

```elixir
@pnc_schedule [
  %{visit: 1, timing: "Within 48 hours"},
  %{visit: 2, timing: "1-2 weeks"},
  %{visit: 3, timing: "4-6 weeks"},
  %{visit: 4, timing: "4-6 months"}
]
```

### 7.2 PNC Mother Assessment

```elixir
schema "pnc_mother_visits" do
  belongs_to :mother, Mother
  belongs_to :delivery, Delivery

  field :visit_number, :integer
  field :visit_date, :date
  field :bp_systolic, :integer
  field :bp_diastolic, :integer
  field :temperature, :decimal
  field :pulse, :integer
  field :respiratory_rate, :integer
  field :general_condition, :string
  field :breast_condition, :string
  field :cs_scar_condition, :string
  field :uterus_involution, :string
  field :pelvic_exam, :string
  field :episiotomy_condition, :string
  field :lochia_smell, :string
  field :lochia_amount, :string
  field :lochia_colour, :string
  field :haemoglobin, :decimal

  # HIV Testing
  field :hiv_tested, :boolean
  field :hiv_status, :string
  field :on_haart, :boolean

  # Family Planning
  field :fp_counseling_done, :boolean
  field :fp_method, :string

  # Mental Health
  field :mental_health_screened, :boolean
  field :mental_health_notes, :string

  timestamps()
end
```

### 7.3 PNC Baby Assessment

```elixir
schema "pnc_baby_visits" do
  belongs_to :child, Child
  belongs_to :pnc_mother_visit, PncMotherVisit

  field :general_condition, :string
  field :temperature, :decimal
  field :breaths_per_minute, :integer
  field :exclusive_breastfeeding, :boolean
  field :positioning_correct, :boolean
  field :attachment_good, :boolean
  field :umbilical_cord_status, :string  # clean, dry, bleeding, infected
  field :irritable, :boolean
  field :other_problems, :string
  field :immunization_started, :boolean

  # For HIV Exposed Infants
  field :hei_arv_prophylaxis_given, :boolean
  field :cotrimoxazole_initiated, :boolean

  timestamps()
end
```

---

## 8. CHILD HEALTH MONITORING

### 8.1 Child Registration

```elixir
schema "children" do
  belongs_to :mother, Mother

  field :name, :string
  field :sex, :string
  field :date_of_birth, :date
  field :gestation_at_birth_weeks, :integer
  field :birth_weight_grams, :integer
  field :birth_length_cm, :decimal
  field :head_circumference_cm, :decimal
  field :birth_order, :integer  # 1st, 2nd, 3rd born
  field :birth_characteristics, :string  # twin/triplet, caesarian, etc.

  # Birth registration
  field :place_of_birth, :string
  field :birth_notification_number, :string
  field :birth_notification_date, :date
  field :birth_certificate_number, :string
  field :birth_registration_date, :date
  field :birth_registration_place, :string

  # Health facility
  field :immunization_register_number, :string
  field :cwc_number, :string  # Child Welfare Clinic
  field :health_facility_name, :string
  field :kmhfl_code, :string

  # Guardian info
  field :father_name, :string
  field :father_phone, :string
  field :guardian_name, :string
  field :guardian_phone, :string

  # Address
  field :county, :string
  field :subcounty, :string
  field :ward, :string
  field :town_village, :string
  field :estate_house_village, :string
  field :postal_address, :string

  timestamps()
end
```

### 8.2 Congenital Abnormalities Assessment

```elixir
schema "congenital_assessments" do
  belongs_to :child, Child

  field :assessment_date, :date
  field :assessment_timing, :string  # "within_48hrs", "at_6_weeks"

  # Head
  field :head_size, :string  # Normal, Micro cephalic, Hydrocephalic
  field :head_remarks, :string

  # Mouth and Gums
  field :mouth_normal, :boolean
  field :cleft_lip, :boolean
  field :cleft_palate, :boolean
  field :mouth_other, :string

  # Ears
  field :ears_normal, :boolean
  field :ears_abnormality, :string

  # Arms and Legs
  field :arms_normal, :boolean
  field :legs_normal, :boolean
  field :back_normal, :boolean
  field :club_foot, :boolean
  field :congenital_hip_dislocation, :boolean
  field :jointed_fingers_toes, :boolean
  field :extra_fingers_toes, :boolean
  field :limbs_other, :string

  # Muscle Tone
  field :muscle_tone_normal, :boolean
  field :floppiness, :boolean
  field :rigidity, :boolean

  # Joints
  field :joints_flexible, :boolean

  # Spine/Neck/Back
  field :spine_normal, :boolean
  field :spine_swellings, :boolean
  field :spine_protrusions, :boolean
  field :spine_sores_marks, :boolean

  # Body Movement
  field :body_movement_normal, :boolean
  field :floppy_when_lying, :boolean
  field :cerebral_palsy, :boolean

  # Abdominal Wall
  field :abdominal_wall_normal, :boolean
  field :abdominal_abnormality, :string

  # Genitalia
  field :genitalia_normal, :boolean
  field :genitalia_abnormality, :string

  # Anus
  field :anus_perforate, :boolean  # Normal

  field :other_abnormal_findings, :string

  timestamps()
end
```

### 8.3 Reasons for Special Care

```elixir
@special_care_reasons [
  "birth_weight_less_than_2500g",
  "birth_less_than_2_years_after_last",
  "fifth_child_or_more",
  "born_of_teenage_mother",
  "born_of_mentally_ill_mother",
  "developmental_delays",
  "sibling_undernourished",
  "multiple_births",
  "special_needs",
  "orphan_vulnerable",
  "disability",
  "hiv_exposed_infant",
  "child_abuse_neglect_history",
  "cleft_lip_palate"
]
```

---

## 9. GROWTH MONITORING

### 9.1 Growth Measurements

```elixir
schema "growth_measurements" do
  belongs_to :child, Child

  field :measurement_date, :date
  field :age_months, :integer
  field :weight_kg, :decimal
  field :length_height_cm, :decimal
  field :head_circumference_cm, :decimal
  field :muac_cm, :decimal

  # Z-scores (calculated)
  field :weight_for_age_z, :decimal
  field :length_height_for_age_z, :decimal
  field :weight_for_length_height_z, :decimal

  # Status interpretation
  field :nutritional_status, :string  # Normal, Underweight, Stunted, Wasted

  field :next_visit_date, :date

  timestamps()
end
```

### 9.2 Z-Score Interpretation (WHO Standards)

```elixir
# Weight-for-Age and Length/Height-for-Age interpretation
@z_score_interpretation %{
  above_3: "Refer for further investigations",
  between_2_and_3: "Refer for nutritional counseling",
  between_1_and_2: "Watch - increasing trend good, decreasing is danger",
  between_neg1_and_1: "Normal - Good growth",
  between_neg2_and_neg1: "Watch - increasing trend good, decreasing is danger",
  between_neg3_and_neg2: "Danger - Refer for nutritional counseling",
  below_neg3: "Very Dangerous - May be ill, needs extra care"
}
```

### 9.3 Recommended Weight Gain (Pregnancy)

```elixir
# Total: 7-12 kg during pregnancy
@pregnancy_weight_gain %{
  first_trimester: "0.5 kg/month",
  second_trimester: "1-1.5 kg/month",
  third_trimester: "2-2.2 kg/month"
}
```

---

## 10. IMMUNIZATION SCHEDULE

### 10.1 Vaccination Schema

```elixir
schema "immunizations" do
  belongs_to :child, Child

  field :vaccine_name, :string
  field :dose_number, :integer
  field :scheduled_age, :string
  field :date_given, :date
  field :batch_number, :string
  field :next_visit_date, :date

  # For AEFI tracking
  field :adverse_event, :boolean
  field :adverse_event_description, :string
  field :manufacturer, :string
  field :manufacture_date, :date
  field :expiry_date, :date

  timestamps()
end
```

### 10.2 Kenya KEPI Schedule

```elixir
@immunization_schedule [
  # At Birth
  %{vaccine: "BCG", dose: nil, age: "At birth", route: "Intradermal left forearm",
    dose_amount: "0.05ml (<1yr) or 0.1ml (>1yr)"},
  %{vaccine: "OPV", dose: 0, age: "At birth or within 2 weeks", route: "Oral",
    dose_amount: "2 drops"},

  # 6 Weeks
  %{vaccine: "OPV", dose: 1, age: "6 weeks", route: "Oral", dose_amount: "2 drops"},
  %{vaccine: "Pentavalent (DPT-HepB-Hib)", dose: 1, age: "6 weeks",
    route: "IM left outer thigh", dose_amount: "0.5ml"},
  %{vaccine: "PCV10", dose: 1, age: "6 weeks",
    route: "IM right outer thigh", dose_amount: "0.5ml"},
  %{vaccine: "Rotavirus", dose: 1, age: "6 weeks", route: "Oral", dose_amount: "1.5ml"},

  # 10 Weeks
  %{vaccine: "OPV", dose: 2, age: "10 weeks", route: "Oral", dose_amount: "2 drops"},
  %{vaccine: "Pentavalent (DPT-HepB-Hib)", dose: 2, age: "10 weeks",
    route: "IM left outer thigh", dose_amount: "0.5ml"},
  %{vaccine: "PCV10", dose: 2, age: "10 weeks",
    route: "IM right outer thigh", dose_amount: "0.5ml"},
  %{vaccine: "Rotavirus", dose: 2, age: "10 weeks", route: "Oral", dose_amount: "1.5ml"},

  # 14 Weeks
  %{vaccine: "OPV", dose: 3, age: "14 weeks", route: "Oral", dose_amount: "2 drops"},
  %{vaccine: "Pentavalent (DPT-HepB-Hib)", dose: 3, age: "14 weeks",
    route: "IM left outer thigh", dose_amount: "0.5ml"},
  %{vaccine: "PCV10", dose: 3, age: "14 weeks",
    route: "IM right outer thigh", dose_amount: "0.5ml"},
  %{vaccine: "IPV", dose: 1, age: "14 weeks",
    route: "IM right outer thigh (2.5cm from PCV)", dose_amount: "0.5ml"},

  # 6 Months (only for outbreak or HEI)
  %{vaccine: "Measles-Rubella", dose: 0, age: "6 months (outbreak/HEI)",
    route: "SC right upper arm", dose_amount: "0.5ml"},

  # 9 Months
  %{vaccine: "Measles-Rubella", dose: 1, age: "9 months",
    route: "SC right upper arm", dose_amount: "0.5ml"},
  %{vaccine: "Yellow Fever", dose: 1, age: "9 months (selected counties)",
    route: "IM left deltoid", dose_amount: "0.5ml"},

  # 18 Months
  %{vaccine: "Measles-Rubella", dose: 2, age: "18 months",
    route: "SC right upper arm", dose_amount: "0.5ml"}
]
```

### 10.3 BCG Scar Check

```elixir
# BCG scar should be checked after vaccination
# If absent, repeat BCG vaccine
schema "bcg_scar_checks" do
  belongs_to :child, Child

  field :check_date, :date
  field :scar_present, :boolean
  field :repeat_date, :date

  timestamps()
end
```

---

## 11. VITAMIN A SUPPLEMENTATION

```elixir
schema "vitamin_a_supplements" do
  belongs_to :child, Child

  field :dose_iu, :integer
  field :age_months, :integer
  field :date_given, :date
  field :next_visit_date, :date

  timestamps()
end

@vitamin_a_schedule [
  %{age_months: 6, dose_iu: 100_000},
  %{age_months: 12, dose_iu: 200_000},
  %{age_months: 18, dose_iu: 200_000},
  %{age_months: 24, dose_iu: 200_000},
  %{age_months: 30, dose_iu: 200_000},
  %{age_months: 36, dose_iu: 200_000},
  %{age_months: 42, dose_iu: 200_000},
  %{age_months: 48, dose_iu: 200_000},
  %{age_months: 54, dose_iu: 200_000},
  %{age_months: 59, dose_iu: 200_000}
]

# Note: Don't give if <30 days since last dose
# For measles/Vit A deficiency: Day 0, 24hrs later, 14 days later
```

---

## 12. MICRONUTRIENT POWDERS (MNPs)

```elixir
schema "mnp_supplements" do
  belongs_to :child, Child

  field :age_months, :integer  # 6-23 months
  field :sachets_issued, :integer  # 10 per month
  field :date_issued, :date
  field :next_visit_date, :date

  timestamps()
end

# Usage instructions:
# - Give 1 sachet every 3rd day
# - Add to semi-solid food and mix
# - Add in warm (NOT hot) food
# - Eat within 30 minutes after mixing
# - Do not add to liquids or drinks
```

---

## 13. DEWORMING (Children)

```elixir
schema "child_deworming" do
  belongs_to :child, Child

  field :age_months, :integer
  field :medication, :string  # Albendazole
  field :dosage_mg, :integer  # 200mg (1-2yrs) or 400mg (>2yrs)
  field :date_given, :date
  field :next_visit_date, :date

  timestamps()
end

@deworming_schedule [
  # Every 6 months from 1 year to 5 years
  %{age_months: 12, dose_mg: 200},  # Half tablet
  %{age_months: 18, dose_mg: 200},
  %{age_months: 24, dose_mg: 400},  # Full tablet
  %{age_months: 30, dose_mg: 400},
  %{age_months: 36, dose_mg: 400},
  %{age_months: 42, dose_mg: 400},
  %{age_months: 48, dose_mg: 400},
  %{age_months: 54, dose_mg: 400},
  %{age_months: 59, dose_mg: 400}
]
```

---

## 14. DEVELOPMENTAL MILESTONES

```elixir
schema "developmental_milestones" do
  belongs_to :child, Child

  field :milestone_name, :string
  field :expected_age_range, :string
  field :age_achieved_months, :integer
  field :status, :string  # within_time, delayed
  field :assessment_date, :date

  timestamps()
end

@developmental_milestones [
  %{
    age_range: "0-2 months",
    milestones: [
      "Social smile",
      "Follows colourful object dangled before eyes"
    ]
  },
  %{
    age_range: "2-4 months",
    milestones: [
      "Holds head upright",
      "Follows object or face with eyes",
      "Turns head or responds to sound",
      "Smiles when you speak"
    ]
  },
  %{
    age_range: "4-6 months",
    milestones: [
      "Rolls over",
      "Reaches for and grasps objects with hand",
      "Takes objects to mouth",
      "Babbles (makes sounds)"
    ]
  },
  %{
    age_range: "6-9 months",
    milestones: [
      "Sits without support",
      "Moves object from one hand to the other",
      "Repeats syllables (bababa, mamama)"
    ]
  },
  %{
    age_range: "9-12 months",
    milestones: [
      "Takes steps with support",
      "Picks up small object with 2 fingers",
      "Says 2-3 words",
      "Imitates simple gestures (claps hands, bye)"
    ]
  },
  %{
    age_range: "12-18 months",
    milestones: [
      "Walks without support",
      "Drinks from a cup",
      "Says 7-10 words",
      "Points to some body parts on request"
    ]
  },
  %{
    age_range: "18-24 months",
    milestones: [
      "Kicks a ball",
      "Builds tower with 3 blocks or small boxes",
      "Points at pictures on request",
      "Speaks in short sentences"
    ]
  },
  %{
    age_range: "24+ months",
    milestones: [
      "Jumps",
      "Undresses and dresses themselves",
      "Says name, tells short story",
      "Interested in playing with other children"
    ]
  }
]
```

---

## 15. EYE CARE ASSESSMENT

```elixir
schema "eye_assessments" do
  belongs_to :child, Child

  field :assessment_date, :date
  field :age_at_assessment, :string  # at_birth, 6_months, 9_months, 18_months

  field :teo_given, :boolean  # Tetracycline Eye Ointment (at birth only)
  field :pupil_color, :string  # black (normal), white (refer urgently)
  field :follows_objects, :boolean
  field :has_squint, :boolean
  field :other_problems, :boolean
  field :other_problems_description, :string
  field :referred, :boolean

  timestamps()
end
```

---

## 16. DENTAL HEALTH

### 16.1 Baby Teeth Development Record

```elixir
schema "teeth_development" do
  belongs_to :child, Child

  field :tooth_type, :string
  field :normal_age_range, :string
  field :age_observed_months, :integer
  field :date_observed, :date

  timestamps()
end

@teeth_eruption_schedule [
  %{tooth: "Lower Incisor", age_range: "4-10 months"},
  %{tooth: "Upper Incisor", age_range: "6-12 months"},
  %{tooth: "Lower Canine", age_range: "12-23 months"},
  %{tooth: "Upper Canine", age_range: "12-23 months"},
  %{tooth: "Lower First Molar", age_range: "12-18 months"},
  %{tooth: "Upper First Molar", age_range: "12-18 months"},
  %{tooth: "Lower Second Molar", age_range: "24-30 months"},
  %{tooth: "Upper Second Molar", age_range: "24-30 months"}
]
```

### 16.2 Dental Care Recommendations

```elixir
# For children
@toothpaste_amounts %{
  under_2_years: "rice-grain-sized smear",
  age_2_to_5: "pea-sized amount",
  over_5_years: "regular amount"
}

# Key points:
# - Clean teeth as soon as they appear
# - Brush twice daily (after breakfast, before bed)
# - Use fluoride toothpaste
# - Assist with brushing until 6-8 years old
# - First dental visit at age 1 year
# - Avoid teething gels/powders
# - Neonatal teeth (born with teeth) can be removed if causing breastfeeding pain
```

---

## 17. HIV EXPOSED INFANT (HEI) MANAGEMENT

### 17.1 HEI Identification and Testing

```elixir
schema "hei_tracking" do
  belongs_to :child, Child

  field :exposure_confirmed, :boolean
  field :exposure_confirmed_date, :date

  # DNA PCR Tests
  field :dna_pcr_1_date, :date  # First contact after delivery or 6 weeks
  field :dna_pcr_1_result, :string
  field :dna_pcr_2_date, :date  # 6 months
  field :dna_pcr_2_result, :string
  field :dna_pcr_3_date, :date  # 12 months
  field :dna_pcr_3_result, :string

  # Antibody Tests
  field :antibody_18_months_date, :date
  field :antibody_18_months_result, :string
  field :antibody_24_months_date, :date
  field :antibody_24_months_result, :string

  # Final test 6 weeks after cessation of breastfeeding
  field :final_antibody_date, :date
  field :final_antibody_result, :string
  field :breastfeeding_cessation_date, :date

  timestamps()
end
```

### 17.2 HEI Prophylaxis

```elixir
schema "hei_prophylaxis" do
  belongs_to :child, Child

  # ARV Prophylaxis (AZT + NVP for 6 weeks, then NVP until 6 weeks after BF cessation)
  field :arv_start_date, :date
  field :arv_regimen, :string
  field :azT_end_date, :date  # 6 weeks
  field :nvp_continuation, :boolean
  field :nvp_end_date, :date

  # CTX Prophylaxis (from 6 weeks until 6 weeks after BF cessation)
  field :ctx_start_date, :date
  field :ctx_dose, :string  # "2.5ml OD, adjust per weight"
  field :ctx_end_date, :date

  # IPT
  field :ipt_eligible, :boolean
  field :ipt_start_date, :date

  timestamps()
end
```

---

## 18. PMTCT (Prevention of Mother to Child Transmission)

```elixir
schema "pmtct_interventions" do
  belongs_to :mother, Mother
  belongs_to :pregnancy, Pregnancy

  # ART for Mother
  field :art_start_date, :date
  field :art_regimen, :string

  # Viral Load Monitoring
  field :viral_load_date, :date
  field :viral_load_result, :string

  timestamps()
end

# Note: Continue HIV retesting until complete cessation of breastfeeding
# If reactive, start HAART immediately
```

---

## 19. FEEDING RECOMMENDATIONS

### 19.1 Breastfeeding Guidelines

```elixir
@breastfeeding_guidelines %{
  newborn_to_1_week: %{
    instructions: [
      "Skin-to-skin contact immediately after birth for at least 1 hour",
      "Initiate breastfeeding within first hour",
      "Give colostrum (first yellowish milk)",
      "Breastfeed on demand (at least 8 times in 24 hours)",
      "Low birth weight (<2500g): feed every 2-3 hours",
      "DO NOT give other foods - breast milk is all baby needs"
    ]
  },
  week_1_to_6_months: %{
    instructions: [
      "Breastfeed as often as child wants",
      "Look for hunger signs: fussing, lip movements, opening mouth",
      "At least 8 feeds in 24 hours",
      "Exclusive breastfeeding - no other foods or fluids"
    ]
  }
}
```

### 19.2 Complementary Feeding (6 months onwards)

```elixir
@complementary_feeding_schedule [
  %{
    age: "6 months",
    texture: "Thick porridge or well mashed/pureed foods",
    frequency: "2 meals + frequent breastfeeds",
    amount: "2 tablespoons, increase to 3 by 3rd-4th week",
    mnps: true
  },
  %{
    age: "7-8 months",
    texture: "Mashed family foods, finger foods from 8 months",
    frequency: "3 meals + frequent breastfeeds",
    amount: "Half (½) cup (250ml)",
    mnps: true
  },
  %{
    age: "9-11 months",
    texture: "Finely chopped or mashed, finger foods",
    frequency: "3 meals + 1 snack + frequent breastfeeds",
    amount: "¾ cup (250ml)",
    mnps: true
  },
  %{
    age: "1-2 years",
    texture: "Small soft pieces child can pick, chew, swallow",
    frequency: "3 meals + 2 snacks + frequent breastfeeds",
    amount: "1 cup (250ml)",
    mnps: true
  },
  %{
    age: "2-5 years",
    texture: "Small soft pieces",
    frequency: "3 meals + 2 snacks (may continue breastfeeding)",
    amount: "1½-2 cups (250ml)",
    mnps: false
  }
]
```

### 19.3 Seven Food Groups

```elixir
@seven_food_groups [
  "Grains, grain products and other starchy foods",
  "Legumes, pulses, nuts and seeds",
  "Dairy and dairy products",
  "Eggs",
  "Flesh foods (beef, poultry, fish, insects)",
  "Vitamin A rich fruits and vegetables",
  "Other fruits and vegetables"
]

# Recommendation: Feed child at least 4 of 7 food groups daily
# Continue breastfeeding for 2 years or beyond
```

### 19.4 Sick Child Feeding

```elixir
@sick_child_feeding %{
  during_illness: [
    "Encourage drinking and eating with patience",
    "Feed small amounts frequently",
    "Give foods the child likes",
    "Give variety of nutrient-rich foods",
    "Continue breastfeeding (ill children often breastfeed more)"
  ],
  during_recovery: [
    "Give extra breastfeeds",
    "Feed an extra meal",
    "Give extra amount of food",
    "Use extra rich foods",
    "Feed with extra patience and love"
  ]
}
```

---

## 20. FAMILY PLANNING

```elixir
schema "family_planning" do
  belongs_to :mother, Mother

  field :counseling_date, :date
  field :method_chosen, :string
  field :start_date, :date
  field :weight_kg, :decimal
  field :bp_systolic, :integer
  field :bp_diastolic, :integer
  field :remarks, :string

  timestamps()
end

# Key messages:
# - Space children at least 2 years between pregnancies
# - Can start FP immediately after childbirth
# - Visit FP clinic with partner to decide together
```

---

## 21. REPRODUCTIVE CANCER SCREENING

```elixir
schema "cancer_screenings" do
  belongs_to :mother, Mother

  field :screening_date, :date

  # Cervical Cancer
  field :cervical_exam_type, :string  # HPV, VIA, VIA/VILI, Pap Smear
  field :cervical_result, :string     # Negative, Positive, Suspicious
  field :cervical_treatment, :string  # Cryo, Thermoablation, LEEP, Referred

  # Breast Cancer
  field :breast_exam_type, :string    # CBE, Ultrasound
  field :breast_result, :string       # Normal, Benign Lump, Suspicious
  field :breast_treatment, :string    # FNA, Excision, Referred

  timestamps()
end

# First postnatal cervical screening: 6 weeks after childbirth
```

---

## 22. BIRTH PLAN

```elixir
schema "birth_plans" do
  belongs_to :pregnancy, Pregnancy

  field :expected_date_of_childbirth, :date
  field :place_of_childbirth, :string
  field :health_facility_name, :string
  field :birth_attendant, :string
  field :health_facility_phone, :string
  field :support_person_name, :string
  field :transport_plan, :string
  field :blood_donor_name, :string
  field :financial_plan, :string

  timestamps()
end
```

---

## 23. FATHER'S INVOLVEMENT

The handbook emphasizes father's role in MCH. Consider creating engagement features:

```elixir
# Father's Support Checklist (can be tracked in app)
@fathers_support_checklist %{
  during_pregnancy: [
    "Help with house chores",
    "Ensure healthy eating (5 of 10 food groups daily)",
    "Accompany to ANC visits",
    "Get tested for STIs including HIV",
    "Create birth plan together",
    "Play and communicate with unborn baby",
    "Discuss family planning"
  ],
  during_childbirth: [
    "Ensure basic needs in house",
    "Arrange transport to health facility",
    "Ensure other children are cared for",
    "Provide emotional and physical support",
    "Encourage and build confidence",
    "Help with walking/squatting during contractions"
  ],
  after_childbirth: [
    "Support exclusive breastfeeding for 6 months",
    "Hold and care for baby (bonding)",
    "Help with rest by doing house chores",
    "Play and communicate with baby",
    "Avoid sexual contact until bleeding stops (~6 weeks)",
    "Accompany to postnatal care",
    "Watch for danger signs in mother and baby"
  ]
}
```

---

## 24. HEALTH EDUCATION CONTENT

Build an educational content module with this information:

### 24.1 Care During Pregnancy

```elixir
@pregnancy_care_tips [
  "Eat one extra meal every day during pregnancy",
  "Eat at least 5 of the 10 food groups everyday",
  "Drink plenty of water - at least 8 glasses (2 litres) per day",
  "Take iron and folic acid supplements (IFAS) everyday",
  "Avoid heavy work, rest more",
  "Sleep under a long lasting insecticidal net (LLIN)",
  "Go for ANC as soon as possible - attend 8 times during pregnancy",
  "Do regular non-strenuous exercises"
]
```

### 24.2 Ten Food Groups (for Healthy Eating)

```elixir
@ten_food_groups [
  "Grains, grain products, other starchy foods",
  "Legumes and pulses",
  "Nuts and seeds",
  "Dairy/milk products",
  "Eggs",
  "Flesh foods (beef, poultry, fish, organ meat, insects)",
  "Dark green vegetables",
  "Orange/yellow fleshed fruits and vegetables",
  "Other vegetables",
  "Other fruits"
]

# Eat at least 5 of 10 food groups each day
```

### 24.3 Breastfeeding Positioning & Attachment

```elixir
@correct_positioning_signs [
  "Baby's head and body is straight",
  "Baby facing mother with nose opposite nipple",
  "Baby's body close to mother's (tummy to tummy)",
  "Mother supporting infant's whole body (not just neck/shoulders)"
]

@good_attachment_signs [
  "Chin touching the breast",
  "Mouth wide open",
  "Lower lip turned outward",
  "More areola seen above than below the mouth"
]

@effective_suckling_signs [
  "Slow deep sucks, sometimes pausing",
  "Cheeks round when suckling",
  "Baby releases breast when finished or satisfied",
  "Mother feels relaxed"
]
```

---

## 25. HOSPITAL/CLINICAL RECORDS

```elixir
schema "hospital_admissions" do
  belongs_to :child, Child

  field :hospital_name, :string
  field :admission_number, :string
  field :admission_date, :date
  field :discharge_date, :date
  field :discharge_diagnosis, :string

  timestamps()
end

schema "special_clinical_attendance" do
  belongs_to :child, Child

  field :hospital_name, :string
  field :clinic_name, :string
  field :reason_for_attendance, :string
  field :drugs_prescribed, :string
  field :diagnosis, :string
  field :visit_date, :date

  timestamps()
end
```

---

## 26. WHEN TO RETURN IMMEDIATELY

Build alert triggers for these conditions:

```elixir
@return_immediately_any_sick_child [
  "Not able to drink or breastfeed",
  "Becomes sicker",
  "Develops fever"
]

@return_immediately_cough [
  "Fast breathing",
  "Difficult breathing"
]

@return_immediately_diarrhoea [
  "Blood in stool",
  "Drinking poorly"
]

@return_immediately_young_infant [
  "Breast feeding poorly",
  "Feels unusually cold/hot",
  "Palms and soles appear yellow"
]
```

---

## 27. FLUID MANAGEMENT FOR SICK CHILDREN

```elixir
@fluid_management %{
  any_sick_child: [
    "Breastfeed frequently and for longer at each feed",
    "Increase fluid: soup, rice water, yoghurt drinks, clean safe water",
    "(Only if not exclusively breastfeeding)"
  ],
  child_with_diarrhoea: %{
    non_exclusive_breastfeeding: [
      "Give ORS solution",
      "Food-based fluids: soup, rice water, yoghurt drink",
      "Clean and safe water",
      "Breastfeed more frequently and longer",
      "Continue extra fluids until diarrhoea stops",
      "Give zinc as advised until finished"
    ],
    exclusive_breastfeeding: [
      "Breastfeed more frequently and longer",
      "Give ORS solutions"
    ],
    vomiting: "Wait 10 minutes, then give small frequent sips"
  }
}
```

---

## 28. CARE FOR CHILD DEVELOPMENT

### 28.1 Play Activities by Age

```elixir
@play_activities [
  %{
    age: "Conception to Birth",
    activities: [
      "Gently rub belly",
      "Pat belly when baby kicks"
    ]
  },
  %{
    age: "Newborn to 1 week",
    activities: [
      "Skin to skin contact for bonding",
      "Use baby's name",
      "Gently soothe, stroke and hold baby"
    ]
  },
  %{
    age: "1 week to 6 months",
    activities: [
      "Let baby see, hear, feel, move freely",
      "Slowly move colourful things for baby to see and reach",
      "Examples: Shaker rattle, big ring on string"
    ]
  },
  %{
    age: "6-9 months",
    activities: [
      "Give clean, safe household things to handle, bang and drop",
      "Examples: Containers with lids, metal pot and spoon"
    ]
  },
  %{
    age: "9-12 months",
    activities: [
      "Hide attractive item under cloth or box",
      "See if child can look for it",
      "Play peek-a-boo"
    ]
  },
  %{
    age: "12 months to 2 years",
    activities: [
      "Give things to stack up and put into containers",
      "Examples: Nesting and stacking objects, containers, pegs"
    ]
  },
  %{
    age: "2 years and older",
    activities: [
      "Help child count, name and compare things",
      "Help child make simple play items",
      "Examples: Balls, dolls and cars"
    ]
  }
]
```

### 28.2 Communication Activities by Age

```elixir
@communication_activities [
  %{
    age: "Conception to Birth",
    activities: [
      "Both parents rub belly and talk to unborn baby",
      "Take time for relaxed breathing",
      "Sing soothing songs"
    ]
  },
  %{
    age: "Newborn to 1 week",
    activities: [
      "Look into baby's eyes and talk",
      "Breastfeeding is good time to talk"
    ]
  },
  %{
    age: "1 week to 6 months",
    activities: [
      "Smile, laugh and talk with child",
      "Copy baby's sounds and gestures"
    ]
  },
  %{
    age: "6-9 months",
    activities: [
      "Respond to child's sounds and interests",
      "Call child's name and see response"
    ]
  },
  %{
    age: "9-12 months",
    activities: [
      "Tell child names of things: items, people, animals",
      "Show how to say things with hands like 'bye-bye'"
    ]
  },
  %{
    age: "12 months to 2 years",
    activities: [
      "Ask simple questions",
      "Respond to child's attempts to talk",
      "Show and talk about nature, people and things"
    ]
  },
  %{
    age: "2 years and older",
    activities: [
      "Encourage child to talk and answer questions",
      "Tell stories, sing songs, play games together",
      "Use simple books with pictures"
    ]
  }
]
```

---

## 29. LIVEVIEW FEATURES TO CONSIDER

### 29.1 Real-time Dashboards

- Mother's ANC visit tracking with countdown to next appointment
- Child's immunization schedule with upcoming vaccines
- Growth chart visualization (real-time plotting)
- Danger sign alerts

### 29.2 Forms and Data Entry

- Multi-step ANC visit forms
- PNC assessment checklists
- Growth measurement entry with automatic z-score calculation
- Immunization recording with AEFI tracking

### 29.3 Educational Content

- Interactive developmental milestone tracker
- Feeding guide based on child's age
- Danger signs awareness with action recommendations
- Breastfeeding technique guides with images

### 29.4 Reminders and Notifications

- Upcoming ANC/PNC visits
- Immunization due dates
- Vitamin A supplementation schedule
- Growth monitoring monthly reminders

### 29.5 Reports

- Individual mother/child summary reports
- Immunization certificates
- Growth monitoring reports with charts
- PMTCT cascade tracking

---

## 30. ABBREVIATIONS REFERENCE

```elixir
@abbreviations %{
  "AEFI" => "Adverse Events Following Immunization",
  "ANC" => "Antenatal Clinic",
  "ARVs" => "Antiretrovirals",
  "AZT" => "Zidovudine",
  "BP" => "Blood Pressure",
  "CHX" => "Chlorhexidine",
  "CTX" => "Cotrimoxazole",
  "CWC" => "Child Welfare Clinic",
  "DBS" => "Dry Blood Spot",
  "EDD" => "Expected Date of Delivery",
  "FP" => "Family Planning",
  "Hb" => "Haemoglobin",
  "HEI" => "HIV Exposed Infant",
  "ICF" => "Intensified Case Finding",
  "IPT" => "Isoniazid Prophylaxis Therapy",
  "IPTp" => "Intermittent Preventive Treatment in Pregnancy",
  "KEPI" => "Kenya Expanded Program on Immunization",
  "KMC" => "Kangaroo Mother Care",
  "KMHFL" => "Kenya Master Health Facility Listing",
  "LLIN" => "Long Lasting Insecticidal Nets",
  "LMP" => "Last Menstrual Period",
  "MCH" => "Mother Child Health",
  "MNP" => "Micronutrients Powders",
  "MTCT" => "Mother To Child Transmission",
  "NVP" => "Nevirapine",
  "PMTCT" => "Prevention of Mother to Child Transmission",
  "PNC" => "Postnatal Care",
  "PrEP" => "Pre-Exposure Prophylaxis",
  "SP" => "Sulfadoxine/Pyrimethamine",
  "STI" => "Sexually Transmitted Infections",
  "TB" => "Tuberculosis",
  "TD" => "Tetanus and Diphtheria",
  "TEO" => "Tetracycline Eye Ointment"
}
```

---

## 31. KEY IMPLEMENTATION NOTES

1. **Data Privacy**: MCH data is highly sensitive. Implement proper authentication, authorization, and encryption.

2. **Offline Support**: Many health facilities in Kenya have intermittent connectivity. Consider offline-first approach with LiveView's phx-offline features or PWA capabilities.

3. **Multi-language**: The handbook is bilingual (English/Swahili). Consider internationalization from the start.

4. **Mobile-First**: Most users will access via mobile phones. Design responsive interfaces.

5. **Integration Points**:
   - Kenya's DHIS2 for health reporting
   - KMHFL for facility codes
   - National ID integration for civil registration

6. **Validation Rules**: Implement the medical protocols as business logic (e.g., no Vitamin A if <30 days since last dose, TD vaccination rules).

7. **Growth Charts**: Use WHO growth standards for z-score calculations. The handbook includes specific charts for boys and girls.

8. **Alert System**: Danger signs should trigger immediate visual alerts and potentially SMS notifications.

---

This context document should give your development team comprehensive understanding of the Kenya MCH Handbook domain to build an effective Phoenix LiveView application.
