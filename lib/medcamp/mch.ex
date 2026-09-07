defmodule Medcamp.Mch do
  @moduledoc """
  Mother & Child Health (MCH) context - digitizing Kenya's MOH 216 Handbook.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.Mch.{Mother, Pregnancy, Child, AncVisit, AntenatalProfile, PhysicalExamination}
  alias Medcamp.Mch.{TdVaccination, MalariaProphylaxis, IfasSupplement, DewormingMaternal}
  alias Medcamp.Mch.{Delivery, PncMotherVisit, PncBabyVisit}
  alias Medcamp.Mch.{GrowthMeasurement, Immunization, VitaminASupplement, ChildDeworming}
  alias Medcamp.Mch.{DevelopmentalMilestone, EyeAssessment}

  defp pregnancy_preloads do
    [
      :anc_visits,
      :antenatal_profiles,
      :physical_examinations,
      :malaria_prophylaxis,
      :ifas_supplements,
      :deworming_maternal,
      deliveries: [child: child_preloads()]
    ]
  end

  defp child_preloads do
    [
      :growth_measurements,
      :immunizations,
      :pnc_baby_visits,
      :vitamin_a_supplements,
      :child_deworming,
      :developmental_milestones,
      :eye_assessments
    ]
  end

  # Mother
  def get_or_create_mother_for_patient(patient_id) do
    case get_mother_by_patient_id(patient_id) do
      nil -> create_mother(%{patient_id: patient_id})
      mother -> {:ok, mother}
    end
  end

  def get_mother_by_patient_id(patient_id) do
    Mother
    |> where([m], m.patient_id == ^patient_id)
    |> preload([
      :patient,
      :td_vaccinations,
      pnc_mother_visits: [:delivery, :pnc_baby_visits]
    ])
    |> Repo.one()
  end

  def get_mother!(id) do
    Repo.get!(Mother, id)
    |> Repo.preload([
      :patient,
      :td_vaccinations,
      pnc_mother_visits: [:delivery, :pnc_baby_visits]
    ])
  end

  def change_mother(%Mother{} = mother, attrs \\ %{}), do: Mother.changeset(mother, attrs)

  def update_mother(%Mother{} = mother, attrs),
    do: mother |> Mother.changeset(attrs) |> Repo.update()

  def create_mother(attrs), do: %Mother{} |> Mother.changeset(attrs) |> Repo.insert()

  # Pregnancy
  def list_pregnancies_for_mother(mother_id) do
    Pregnancy
    |> where([p], p.mother_id == ^mother_id)
    |> order_by([p], desc: p.inserted_at)
    |> preload(^pregnancy_preloads())
    |> Repo.all()
  end

  def get_pregnancy!(id),
    do: Repo.get!(Pregnancy, id) |> Repo.preload([:mother] ++ pregnancy_preloads())

  def change_pregnancy(%Pregnancy{} = p, attrs \\ %{}), do: Pregnancy.changeset(p, attrs)
  def create_pregnancy(attrs), do: %Pregnancy{} |> Pregnancy.changeset(attrs) |> Repo.insert()

  def update_pregnancy(%Pregnancy{} = p, attrs),
    do: p |> Pregnancy.changeset(attrs) |> Repo.update()

  # Child
  def list_children_for_mother(mother_id) do
    Child
    |> where([c], c.mother_id == ^mother_id)
    |> order_by([c], desc: c.date_of_birth)
    |> preload(^child_preloads())
    |> Repo.all()
  end

  def get_child!(id), do: Repo.get!(Child, id) |> Repo.preload([:mother] ++ child_preloads())
  def change_child(%Child{} = c, attrs \\ %{}), do: Child.changeset(c, attrs)
  def create_child(attrs), do: %Child{} |> Child.changeset(attrs) |> Repo.insert()
  def update_child(%Child{} = c, attrs), do: c |> Child.changeset(attrs) |> Repo.update()

  # ANC
  def list_anc_visits_for_pregnancy(pregnancy_id) do
    AncVisit
    |> where([a], a.pregnancy_id == ^pregnancy_id)
    |> order_by([a], asc: a.visit_date)
    |> Repo.all()
  end

  def create_anc_visit(attrs), do: %AncVisit{} |> AncVisit.changeset(attrs) |> Repo.insert()
  def get_anc_visit!(id), do: Repo.get!(AncVisit, id)
  def change_anc_visit(%AncVisit{} = a, attrs \\ %{}), do: AncVisit.changeset(a, attrs)

  def update_anc_visit(%AncVisit{} = a, attrs),
    do: a |> AncVisit.changeset(attrs) |> Repo.update()

  # Antenatal profile
  def list_antenatal_profiles_for_pregnancy(pregnancy_id) do
    AntenatalProfile
    |> where([p], p.pregnancy_id == ^pregnancy_id)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  def create_antenatal_profile(attrs),
    do: %AntenatalProfile{} |> AntenatalProfile.changeset(attrs) |> Repo.insert()

  def get_antenatal_profile!(id), do: Repo.get!(AntenatalProfile, id)

  def change_antenatal_profile(%AntenatalProfile{} = profile, attrs \\ %{}),
    do: AntenatalProfile.changeset(profile, attrs)

  def update_antenatal_profile(%AntenatalProfile{} = profile, attrs),
    do: profile |> AntenatalProfile.changeset(attrs) |> Repo.update()

  # Physical examination
  def list_physical_examinations_for_pregnancy(pregnancy_id) do
    PhysicalExamination
    |> where([e], e.pregnancy_id == ^pregnancy_id)
    |> order_by([e], desc: e.examination_date)
    |> Repo.all()
  end

  def create_physical_examination(attrs),
    do: %PhysicalExamination{} |> PhysicalExamination.changeset(attrs) |> Repo.insert()

  def get_physical_examination!(id), do: Repo.get!(PhysicalExamination, id)

  def change_physical_examination(%PhysicalExamination{} = exam, attrs \\ %{}),
    do: PhysicalExamination.changeset(exam, attrs)

  def update_physical_examination(%PhysicalExamination{} = exam, attrs),
    do: exam |> PhysicalExamination.changeset(attrs) |> Repo.update()

  # Preventive services
  def list_td_vaccinations_for_mother(mother_id) do
    TdVaccination
    |> where([t], t.mother_id == ^mother_id)
    |> order_by([t], asc: t.dose_number, asc: t.date_given)
    |> Repo.all()
  end

  def create_td_vaccination(attrs),
    do: %TdVaccination{} |> TdVaccination.changeset(attrs) |> Repo.insert()

  def get_td_vaccination!(id), do: Repo.get!(TdVaccination, id)

  def change_td_vaccination(%TdVaccination{} = td, attrs \\ %{}),
    do: TdVaccination.changeset(td, attrs)

  def update_td_vaccination(%TdVaccination{} = td, attrs),
    do: td |> TdVaccination.changeset(attrs) |> Repo.update()

  def list_malaria_prophylaxis_for_pregnancy(pregnancy_id) do
    MalariaProphylaxis
    |> where([m], m.pregnancy_id == ^pregnancy_id)
    |> order_by([m], asc: m.dose_number, asc: m.date_given)
    |> Repo.all()
  end

  def create_malaria_prophylaxis(attrs),
    do: %MalariaProphylaxis{} |> MalariaProphylaxis.changeset(attrs) |> Repo.insert()

  def get_malaria_prophylaxis!(id), do: Repo.get!(MalariaProphylaxis, id)

  def change_malaria_prophylaxis(%MalariaProphylaxis{} = prophylaxis, attrs \\ %{}),
    do: MalariaProphylaxis.changeset(prophylaxis, attrs)

  def update_malaria_prophylaxis(%MalariaProphylaxis{} = prophylaxis, attrs),
    do: prophylaxis |> MalariaProphylaxis.changeset(attrs) |> Repo.update()

  def list_ifas_supplements_for_pregnancy(pregnancy_id) do
    IfasSupplement
    |> where([i], i.pregnancy_id == ^pregnancy_id)
    |> order_by([i], asc: i.contact_number, asc: i.date_given)
    |> Repo.all()
  end

  def create_ifas_supplement(attrs),
    do: %IfasSupplement{} |> IfasSupplement.changeset(attrs) |> Repo.insert()

  def get_ifas_supplement!(id), do: Repo.get!(IfasSupplement, id)

  def change_ifas_supplement(%IfasSupplement{} = supplement, attrs \\ %{}),
    do: IfasSupplement.changeset(supplement, attrs)

  def update_ifas_supplement(%IfasSupplement{} = supplement, attrs),
    do: supplement |> IfasSupplement.changeset(attrs) |> Repo.update()

  def list_deworming_maternal_for_pregnancy(pregnancy_id) do
    DewormingMaternal
    |> where([d], d.pregnancy_id == ^pregnancy_id)
    |> order_by([d], desc: d.date_given)
    |> Repo.all()
  end

  def create_deworming_maternal(attrs),
    do: %DewormingMaternal{} |> DewormingMaternal.changeset(attrs) |> Repo.insert()

  def get_deworming_maternal!(id), do: Repo.get!(DewormingMaternal, id)

  def change_deworming_maternal(%DewormingMaternal{} = deworming, attrs \\ %{}),
    do: DewormingMaternal.changeset(deworming, attrs)

  def update_deworming_maternal(%DewormingMaternal{} = deworming, attrs),
    do: deworming |> DewormingMaternal.changeset(attrs) |> Repo.update()

  # Delivery - creates child and delivery in one transaction
  def create_delivery_with_child(pregnancy_id, mother_id, attrs) do
    child_attrs = %{
      "mother_id" => mother_id,
      "name" => attrs["child_name"] || "Baby",
      "sex" => attrs["sex"],
      "date_of_birth" => attrs["delivery_date"],
      "gestation_at_birth_weeks" => attrs["duration_of_pregnancy_weeks"],
      "birth_weight_grams" => attrs["birth_weight_grams"],
      "birth_length_cm" => attrs["birth_length_cm"],
      "head_circumference_cm" => attrs["head_circumference_cm"],
      "place_of_birth" => attrs["place_of_childbirth"],
      "birth_order" => attrs["birth_order"]
    }

    delivery_attrs = %{
      "pregnancy_id" => pregnancy_id,
      "delivery_date" => attrs["delivery_date"],
      "delivery_time" => attrs["delivery_time"],
      "duration_of_pregnancy_weeks" => attrs["duration_of_pregnancy_weeks"],
      "mode_of_delivery" => attrs["mode_of_delivery"],
      "birth_weight_grams" => attrs["birth_weight_grams"],
      "birth_length_cm" => attrs["birth_length_cm"],
      "head_circumference_cm" => attrs["head_circumference_cm"],
      "place_of_childbirth" => attrs["place_of_childbirth"],
      "conducted_by" => attrs["conducted_by"]
    }

    Repo.transaction(fn ->
      {:ok, child} = create_child(child_attrs)
      delivery_with_child = Map.put(delivery_attrs, "child_id", child.id)
      {:ok, delivery} = create_delivery(delivery_with_child)
      pregnancy = Repo.get!(Pregnancy, pregnancy_id)
      update_pregnancy(pregnancy, %{status: "completed"})
      {child, delivery}
    end)
  end

  def create_delivery(attrs), do: %Delivery{} |> Delivery.changeset(attrs) |> Repo.insert()
  def get_delivery!(id), do: Repo.get!(Delivery, id) |> Repo.preload(:child)
  def change_delivery(%Delivery{} = d, attrs \\ %{}), do: Delivery.changeset(d, attrs)
  def update_delivery(%Delivery{} = d, attrs), do: d |> Delivery.changeset(attrs) |> Repo.update()

  # Schemaless changeset for delivery + child form (creates both in one action)
  def change_delivery_with_child(attrs, pregnancy_id) when is_integer(pregnancy_id) do
    types = %{
      pregnancy_id: :integer,
      delivery_date: :date,
      delivery_time: :string,
      duration_of_pregnancy_weeks: :integer,
      mode_of_delivery: :string,
      birth_weight_grams: :integer,
      birth_length_cm: :decimal,
      head_circumference_cm: :decimal,
      place_of_childbirth: :string,
      conducted_by: :string,
      child_name: :string,
      sex: :string,
      birth_order: :integer
    }

    attrs = (attrs || %{}) |> Map.put("pregnancy_id", pregnancy_id)

    {%{}, types}
    |> Ecto.Changeset.cast(attrs, [
      :pregnancy_id,
      :delivery_date,
      :delivery_time,
      :duration_of_pregnancy_weeks,
      :mode_of_delivery,
      :birth_weight_grams,
      :birth_length_cm,
      :head_circumference_cm,
      :place_of_childbirth,
      :conducted_by,
      :child_name,
      :sex,
      :birth_order
    ])
    |> Ecto.Changeset.validate_required([:pregnancy_id, :delivery_date, :child_name, :sex])
  end

  def list_deliveries_for_pregnancy(pregnancy_id) do
    Delivery
    |> where([d], d.pregnancy_id == ^pregnancy_id)
    |> preload(:child)
    |> Repo.all()
  end

  # Postnatal care
  def list_pnc_mother_visits_for_mother(mother_id) do
    PncMotherVisit
    |> where([v], v.mother_id == ^mother_id)
    |> order_by([v], asc: v.visit_number, asc: v.visit_date)
    |> preload([:delivery, :pnc_baby_visits])
    |> Repo.all()
  end

  def create_pnc_mother_visit(attrs),
    do: %PncMotherVisit{} |> PncMotherVisit.changeset(attrs) |> Repo.insert()

  def get_pnc_mother_visit!(id),
    do: Repo.get!(PncMotherVisit, id) |> Repo.preload([:delivery, :pnc_baby_visits])

  def change_pnc_mother_visit(%PncMotherVisit{} = visit, attrs \\ %{}),
    do: PncMotherVisit.changeset(visit, attrs)

  def update_pnc_mother_visit(%PncMotherVisit{} = visit, attrs),
    do: visit |> PncMotherVisit.changeset(attrs) |> Repo.update()

  def list_pnc_baby_visits_for_child(child_id) do
    PncBabyVisit
    |> where([v], v.child_id == ^child_id)
    |> order_by([v], asc: v.visit_date)
    |> Repo.all()
  end

  def create_pnc_baby_visit(attrs),
    do: %PncBabyVisit{} |> PncBabyVisit.changeset(attrs) |> Repo.insert()

  def get_pnc_baby_visit!(id), do: Repo.get!(PncBabyVisit, id)

  def change_pnc_baby_visit(%PncBabyVisit{} = visit, attrs \\ %{}),
    do: PncBabyVisit.changeset(visit, attrs)

  def update_pnc_baby_visit(%PncBabyVisit{} = visit, attrs),
    do: visit |> PncBabyVisit.changeset(attrs) |> Repo.update()

  # Growth
  def list_growth_measurements_for_child(child_id) do
    GrowthMeasurement
    |> where([g], g.child_id == ^child_id)
    |> order_by([g], desc: g.measurement_date)
    |> Repo.all()
  end

  def create_growth_measurement(attrs),
    do: %GrowthMeasurement{} |> GrowthMeasurement.changeset(attrs) |> Repo.insert()

  def get_growth_measurement!(id), do: Repo.get!(GrowthMeasurement, id)

  def change_growth_measurement(%GrowthMeasurement{} = g, attrs \\ %{}),
    do: GrowthMeasurement.changeset(g, attrs)

  def update_growth_measurement(%GrowthMeasurement{} = g, attrs),
    do: g |> GrowthMeasurement.changeset(attrs) |> Repo.update()

  # Immunization
  def list_immunizations_for_child(child_id) do
    Immunization
    |> where([i], i.child_id == ^child_id)
    |> order_by([i], asc: i.date_given)
    |> Repo.all()
  end

  def create_immunization(attrs),
    do: %Immunization{} |> Immunization.changeset(attrs) |> Repo.insert()

  def get_immunization!(id), do: Repo.get!(Immunization, id)
  def change_immunization(%Immunization{} = i, attrs \\ %{}), do: Immunization.changeset(i, attrs)

  def update_immunization(%Immunization{} = i, attrs),
    do: i |> Immunization.changeset(attrs) |> Repo.update()

  # Developmental milestones
  def list_developmental_milestones_for_child(child_id) do
    DevelopmentalMilestone
    |> where([m], m.child_id == ^child_id)
    |> order_by([m], asc: m.assessment_date, asc: m.milestone_name)
    |> Repo.all()
  end

  def create_developmental_milestone(attrs),
    do: %DevelopmentalMilestone{} |> DevelopmentalMilestone.changeset(attrs) |> Repo.insert()

  def get_developmental_milestone!(id), do: Repo.get!(DevelopmentalMilestone, id)

  def change_developmental_milestone(%DevelopmentalMilestone{} = milestone, attrs \\ %{}),
    do: DevelopmentalMilestone.changeset(milestone, attrs)

  def update_developmental_milestone(%DevelopmentalMilestone{} = milestone, attrs),
    do: milestone |> DevelopmentalMilestone.changeset(attrs) |> Repo.update()

  # Eye assessments
  def list_eye_assessments_for_child(child_id) do
    EyeAssessment
    |> where([a], a.child_id == ^child_id)
    |> order_by([a], desc: a.assessment_date, desc: a.inserted_at)
    |> Repo.all()
  end

  def create_eye_assessment(attrs),
    do: %EyeAssessment{} |> EyeAssessment.changeset(attrs) |> Repo.insert()

  def get_eye_assessment!(id), do: Repo.get!(EyeAssessment, id)

  def change_eye_assessment(%EyeAssessment{} = assessment, attrs \\ %{}),
    do: EyeAssessment.changeset(assessment, attrs)

  def update_eye_assessment(%EyeAssessment{} = assessment, attrs),
    do: assessment |> EyeAssessment.changeset(attrs) |> Repo.update()

  # Child supplements
  def list_vitamin_a_supplements_for_child(child_id) do
    VitaminASupplement
    |> where([v], v.child_id == ^child_id)
    |> order_by([v], asc: v.age_months, asc: v.date_given)
    |> Repo.all()
  end

  def create_vitamin_a_supplement(attrs),
    do: %VitaminASupplement{} |> VitaminASupplement.changeset(attrs) |> Repo.insert()

  def get_vitamin_a_supplement!(id), do: Repo.get!(VitaminASupplement, id)

  def change_vitamin_a_supplement(%VitaminASupplement{} = supplement, attrs \\ %{}),
    do: VitaminASupplement.changeset(supplement, attrs)

  def update_vitamin_a_supplement(%VitaminASupplement{} = supplement, attrs),
    do: supplement |> VitaminASupplement.changeset(attrs) |> Repo.update()

  def list_child_deworming_for_child(child_id) do
    ChildDeworming
    |> where([d], d.child_id == ^child_id)
    |> order_by([d], asc: d.age_months, asc: d.date_given)
    |> Repo.all()
  end

  def create_child_deworming(attrs),
    do: %ChildDeworming{} |> ChildDeworming.changeset(attrs) |> Repo.insert()

  def get_child_deworming!(id), do: Repo.get!(ChildDeworming, id)

  def change_child_deworming(%ChildDeworming{} = deworming, attrs \\ %{}),
    do: ChildDeworming.changeset(deworming, attrs)

  def update_child_deworming(%ChildDeworming{} = deworming, attrs),
    do: deworming |> ChildDeworming.changeset(attrs) |> Repo.update()

  # Full MCH data for patient (nurse view)
  def get_mch_summary_for_patient(patient_id) do
    mother = get_mother_by_patient_id(patient_id)

    if mother do
      pregnancies = list_pregnancies_for_mother(mother.id)
      children = list_children_for_mother(mother.id)

      active_pregnancy =
        Enum.find(pregnancies, fn p -> p.status == "active" end)

      %{
        mother: mother,
        pregnancies: pregnancies,
        children: children,
        active_pregnancy: active_pregnancy
      }
    else
      nil
    end
  end
end
