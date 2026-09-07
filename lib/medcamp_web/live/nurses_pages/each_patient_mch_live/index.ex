defmodule MedcampWeb.NursesPages.EachPatientMchIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.Mch
  alias Medcamp.Patients

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :mch)
     |> assign(:sub_tab, :overview)
     |> assign(:show_edit_mother_modal, false)
     |> assign(:show_add_pregnancy_modal, false)
     |> assign(:show_add_child_modal, false)
     |> assign(:show_add_anc_visit_modal, false)
     |> assign(:show_record_delivery_modal, false)
     |> assign(:show_add_growth_modal, false)
     |> assign(:show_add_immunization_modal, false)
     |> assign(:show_add_developmental_milestone_modal, false)
     |> assign(:show_add_eye_assessment_modal, false)
     |> assign(:show_add_antenatal_profile_modal, false)
     |> assign(:show_add_physical_examination_modal, false)
     |> assign(:show_add_td_vaccination_modal, false)
     |> assign(:show_add_malaria_prophylaxis_modal, false)
     |> assign(:show_add_ifas_modal, false)
     |> assign(:show_add_deworming_maternal_modal, false)
     |> assign(:show_add_pnc_mother_visit_modal, false)
     |> assign(:show_add_pnc_baby_visit_modal, false)
     |> assign(:show_add_vitamin_a_modal, false)
     |> assign(:show_add_child_deworming_modal, false)
     |> assign(:show_edit_child_modal, false)
     |> assign(:show_edit_anc_visit_modal, false)
     |> assign(:show_edit_delivery_modal, false)
     |> assign(:show_edit_growth_modal, false)
     |> assign(:show_edit_immunization_modal, false)
     |> assign(:selected_pregnancy_id, nil)
     |> assign(:selected_child_id, nil)
     |> assign(:editing_anc_visit_id, nil)
     |> assign(:editing_delivery_id, nil)
     |> assign(:editing_growth_id, nil)
     |> assign(:editing_immunization_id, nil)}
  end

  @impl true
  def handle_params(%{"patient_id" => patient_id}, _url, socket) do
    patient = Patients.get_patient!(patient_id)
    summary = Mch.get_mch_summary_for_patient(patient_id)

    {:noreply,
     socket
     |> assign(:page_title, "Mother & Child Health")
     |> assign(:patient, patient)
     |> assign(:mch_summary, summary)
     |> assign(:patient_id, patient_id)
     |> maybe_assign_mother_form(summary)}
  end

  @impl true
  def handle_event("enroll_mch", _params, socket) do
    case Mch.get_or_create_mother_for_patient(socket.assigns.patient_id) do
      {:ok, _mother} ->
        summary = Mch.get_mch_summary_for_patient(socket.assigns.patient_id)

        {:noreply,
         socket
         |> put_flash(:info, "Patient enrolled in MCH program.")
         |> assign(:mch_summary, summary)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not enroll patient.")}
    end
  end

  @impl true
  def handle_event("set_sub_tab", %{"tab" => tab}, socket) do
    sub_tab =
      if tab in ["overview", "maternal", "children"],
        do: String.to_existing_atom(tab),
        else: :overview

    {:noreply, assign(socket, :sub_tab, sub_tab)}
  end

  @impl true
  def handle_event("open_edit_mother", _params, socket) do
    summary = socket.assigns.mch_summary
    form = to_form(Mch.change_mother(summary.mother))

    {:noreply,
     socket
     |> assign(:show_edit_mother_modal, true)
     |> assign(:mother_form, form)}
  end

  @impl true
  def handle_event("close_edit_mother", _params, socket) do
    {:noreply, assign(socket, :show_edit_mother_modal, false)}
  end

  @impl true
  def handle_event("validate_mother", %{"mother" => params}, socket) do
    form =
      socket.assigns.mch_summary.mother
      |> Mch.change_mother(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :mother_form, form)}
  end

  @impl true
  def handle_event("save_mother", %{"mother" => params}, socket) do
    mother = socket.assigns.mch_summary.mother

    case Mch.update_mother(mother, params) do
      {:ok, _} ->
        summary = Mch.get_mch_summary_for_patient(socket.assigns.patient_id)

        {:noreply,
         socket
         |> put_flash(:info, "Mother profile updated.")
         |> assign(:mch_summary, summary)
         |> assign(:show_edit_mother_modal, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:mother_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("open_add_pregnancy", _params, socket) do
    form =
      Mch.change_pregnancy(%Medcamp.Mch.Pregnancy{mother_id: socket.assigns.mch_summary.mother.id})
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_pregnancy_modal, true)
     |> assign(:pregnancy_form, form)}
  end

  @impl true
  def handle_event("close_add_pregnancy", _params, socket) do
    {:noreply, assign(socket, :show_add_pregnancy_modal, false)}
  end

  @impl true
  def handle_event("validate_pregnancy", %{"pregnancy" => params}, socket) do
    form =
      %Medcamp.Mch.Pregnancy{mother_id: socket.assigns.mch_summary.mother.id}
      |> Mch.change_pregnancy(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :pregnancy_form, form)}
  end

  @impl true
  def handle_event("save_pregnancy", %{"pregnancy" => params}, socket) do
    mother = socket.assigns.mch_summary.mother
    attrs = Map.put(params, "mother_id", mother.id)

    case Mch.create_pregnancy(attrs) do
      {:ok, _} ->
        summary = Mch.get_mch_summary_for_patient(socket.assigns.patient_id)

        {:noreply,
         socket
         |> put_flash(:info, "Pregnancy added.")
         |> assign(:mch_summary, summary)
         |> assign(:show_add_pregnancy_modal, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:pregnancy_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("open_add_child", _params, socket) do
    form =
      Mch.change_child(%Medcamp.Mch.Child{mother_id: socket.assigns.mch_summary.mother.id})
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_child_modal, true)
     |> assign(:child_form, form)}
  end

  @impl true
  def handle_event("close_add_child", _params, socket) do
    {:noreply, assign(socket, :show_add_child_modal, false)}
  end

  @impl true
  def handle_event("validate_child", %{"child" => params}, socket) do
    form =
      %Medcamp.Mch.Child{mother_id: socket.assigns.mch_summary.mother.id}
      |> Mch.change_child(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :child_form, form)}
  end

  @impl true
  def handle_event("save_child", %{"child" => params}, socket) do
    mother = socket.assigns.mch_summary.mother
    attrs = Map.put(params, "mother_id", mother.id)

    case Mch.create_child(attrs) do
      {:ok, _} ->
        summary = Mch.get_mch_summary_for_patient(socket.assigns.patient_id)

        {:noreply,
         socket
         |> put_flash(:info, "Child added.")
         |> assign(:mch_summary, summary)
         |> assign(:show_add_child_modal, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:child_form, to_form(changeset))}
    end
  end

  # ANC Visit
  @impl true
  def handle_event("open_add_anc_visit", %{"pregnancy-id" => pregnancy_id}, socket) do
    form =
      Mch.change_anc_visit(%Medcamp.Mch.AncVisit{pregnancy_id: String.to_integer(pregnancy_id)})
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_anc_visit_modal, true)
     |> assign(:selected_pregnancy_id, String.to_integer(pregnancy_id))
     |> assign(:anc_visit_form, form)}
  end

  @impl true
  def handle_event("close_add_anc_visit", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_anc_visit_modal, false)
     |> assign(:selected_pregnancy_id, nil)}
  end

  @impl true
  def handle_event("validate_anc_visit", %{"anc_visit" => params}, socket) do
    form =
      %Medcamp.Mch.AncVisit{pregnancy_id: socket.assigns.selected_pregnancy_id}
      |> Mch.change_anc_visit(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :anc_visit_form, form)}
  end

  @impl true
  def handle_event("save_anc_visit", %{"anc_visit" => params}, socket) do
    attrs = Map.put(params, "pregnancy_id", socket.assigns.selected_pregnancy_id)

    case Mch.create_anc_visit(attrs) do
      {:ok, _} ->
        summary = Mch.get_mch_summary_for_patient(socket.assigns.patient_id)

        {:noreply,
         socket
         |> put_flash(:info, "ANC visit recorded.")
         |> assign(:mch_summary, summary)
         |> assign(:show_add_anc_visit_modal, false)
         |> assign(:selected_pregnancy_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :anc_visit_form, to_form(changeset))}
    end
  end

  # Delivery
  @impl true
  def handle_event("open_record_delivery", %{"pregnancy-id" => pregnancy_id}, socket) do
    pregnancy_id = String.to_integer(pregnancy_id)

    form =
      Mch.change_delivery_with_child(%{}, pregnancy_id)
      |> to_form(as: "delivery")

    {:noreply,
     socket
     |> assign(:show_record_delivery_modal, true)
     |> assign(:selected_pregnancy_id, pregnancy_id)
     |> assign(:delivery_form, form)}
  end

  @impl true
  def handle_event("close_record_delivery", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_record_delivery_modal, false)
     |> assign(:selected_pregnancy_id, nil)}
  end

  @impl true
  def handle_event("validate_delivery", %{"delivery" => params}, socket) do
    form =
      Mch.change_delivery_with_child(params, socket.assigns.selected_pregnancy_id)
      |> Map.put(:action, :validate)
      |> to_form(as: "delivery")

    {:noreply, assign(socket, :delivery_form, form)}
  end

  @impl true
  def handle_event("save_delivery", %{"delivery" => params}, socket) do
    pregnancy_id = socket.assigns.selected_pregnancy_id
    mother_id = socket.assigns.mch_summary.mother.id

    attrs =
      params
      |> Map.put("child_name", params["child_name"] || "Baby")
      |> Map.put("sex", params["sex"])
      |> Map.put("pregnancy_id", pregnancy_id)

    case Mch.create_delivery_with_child(pregnancy_id, mother_id, attrs) do
      {:ok, {_child, _delivery}} ->
        summary = Mch.get_mch_summary_for_patient(socket.assigns.patient_id)

        {:noreply,
         socket
         |> put_flash(:info, "Delivery recorded and child added.")
         |> assign(:mch_summary, summary)
         |> assign(:show_record_delivery_modal, false)
         |> assign(:selected_pregnancy_id, nil)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not record delivery.")}
    end
  end

  # Growth Measurement
  @impl true
  def handle_event("open_add_growth", %{"child-id" => child_id}, socket) do
    form =
      Mch.change_growth_measurement(%Medcamp.Mch.GrowthMeasurement{
        child_id: String.to_integer(child_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_growth_modal, true)
     |> assign(:selected_child_id, String.to_integer(child_id))
     |> assign(:growth_form, form)}
  end

  @impl true
  def handle_event("close_add_growth", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_growth_modal, false)
     |> assign(:selected_child_id, nil)}
  end

  @impl true
  def handle_event("validate_growth", %{"growth_measurement" => params}, socket) do
    form =
      %Medcamp.Mch.GrowthMeasurement{child_id: socket.assigns.selected_child_id}
      |> Mch.change_growth_measurement(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :growth_form, form)}
  end

  @impl true
  def handle_event("save_growth", %{"growth_measurement" => params}, socket) do
    attrs = Map.put(params, "child_id", socket.assigns.selected_child_id)

    case Mch.create_growth_measurement(attrs) do
      {:ok, _} ->
        summary = Mch.get_mch_summary_for_patient(socket.assigns.patient_id)

        {:noreply,
         socket
         |> put_flash(:info, "Growth measurement recorded.")
         |> assign(:mch_summary, summary)
         |> assign(:show_add_growth_modal, false)
         |> assign(:selected_child_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :growth_form, to_form(changeset))}
    end
  end

  # Immunization
  @impl true
  def handle_event("open_add_immunization", %{"child-id" => child_id}, socket) do
    form =
      Mch.change_immunization(%Medcamp.Mch.Immunization{child_id: String.to_integer(child_id)})
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_immunization_modal, true)
     |> assign(:selected_child_id, String.to_integer(child_id))
     |> assign(:immunization_form, form)}
  end

  @impl true
  def handle_event("close_add_immunization", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_immunization_modal, false)
     |> assign(:selected_child_id, nil)}
  end

  @impl true
  def handle_event("validate_immunization", %{"immunization" => params}, socket) do
    form =
      %Medcamp.Mch.Immunization{child_id: socket.assigns.selected_child_id}
      |> Mch.change_immunization(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :immunization_form, form)}
  end

  @impl true
  def handle_event("save_immunization", %{"immunization" => params}, socket) do
    attrs = Map.put(params, "child_id", socket.assigns.selected_child_id)

    case Mch.create_immunization(attrs) do
      {:ok, _} ->
        summary = Mch.get_mch_summary_for_patient(socket.assigns.patient_id)

        {:noreply,
         socket
         |> put_flash(:info, "Immunization recorded.")
         |> assign(:mch_summary, summary)
         |> assign(:show_add_immunization_modal, false)
         |> assign(:selected_child_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :immunization_form, to_form(changeset))}
    end
  end

  # Developmental milestones
  @impl true
  def handle_event("open_add_developmental_milestone", %{"child-id" => child_id}, socket) do
    form =
      Mch.change_developmental_milestone(%Medcamp.Mch.DevelopmentalMilestone{
        child_id: String.to_integer(child_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_developmental_milestone_modal, true)
     |> assign(:selected_child_id, String.to_integer(child_id))
     |> assign(:developmental_milestone_form, form)}
  end

  @impl true
  def handle_event("close_add_developmental_milestone", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_developmental_milestone_modal, false)
     |> assign(:selected_child_id, nil)}
  end

  @impl true
  def handle_event(
        "validate_developmental_milestone",
        %{"developmental_milestone" => params},
        socket
      ) do
    form =
      %Medcamp.Mch.DevelopmentalMilestone{child_id: socket.assigns.selected_child_id}
      |> Mch.change_developmental_milestone(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :developmental_milestone_form, form)}
  end

  @impl true
  def handle_event("save_developmental_milestone", %{"developmental_milestone" => params}, socket) do
    attrs = Map.put(params, "child_id", socket.assigns.selected_child_id)

    case Mch.create_developmental_milestone(attrs) do
      {:ok, _milestone} ->
        {:noreply,
         socket
         |> put_flash(:info, "Developmental milestone recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_developmental_milestone_modal, false)
         |> assign(:selected_child_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :developmental_milestone_form, to_form(changeset))}
    end
  end

  # Eye assessments
  @impl true
  def handle_event("open_add_eye_assessment", %{"child-id" => child_id}, socket) do
    form =
      Mch.change_eye_assessment(%Medcamp.Mch.EyeAssessment{
        child_id: String.to_integer(child_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_eye_assessment_modal, true)
     |> assign(:selected_child_id, String.to_integer(child_id))
     |> assign(:eye_assessment_form, form)}
  end

  @impl true
  def handle_event("close_add_eye_assessment", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_eye_assessment_modal, false)
     |> assign(:selected_child_id, nil)}
  end

  @impl true
  def handle_event("validate_eye_assessment", %{"eye_assessment" => params}, socket) do
    form =
      %Medcamp.Mch.EyeAssessment{child_id: socket.assigns.selected_child_id}
      |> Mch.change_eye_assessment(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :eye_assessment_form, form)}
  end

  @impl true
  def handle_event("save_eye_assessment", %{"eye_assessment" => params}, socket) do
    attrs = Map.put(params, "child_id", socket.assigns.selected_child_id)

    case Mch.create_eye_assessment(attrs) do
      {:ok, _assessment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Eye assessment recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_eye_assessment_modal, false)
         |> assign(:selected_child_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :eye_assessment_form, to_form(changeset))}
    end
  end

  # Antenatal Profile
  @impl true
  def handle_event("open_add_antenatal_profile", %{"pregnancy-id" => pregnancy_id}, socket) do
    form =
      Mch.change_antenatal_profile(%Medcamp.Mch.AntenatalProfile{
        pregnancy_id: String.to_integer(pregnancy_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_antenatal_profile_modal, true)
     |> assign(:selected_pregnancy_id, String.to_integer(pregnancy_id))
     |> assign(:antenatal_profile_form, form)}
  end

  @impl true
  def handle_event("close_add_antenatal_profile", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_antenatal_profile_modal, false)
     |> assign(:selected_pregnancy_id, nil)}
  end

  @impl true
  def handle_event("validate_antenatal_profile", %{"antenatal_profile" => params}, socket) do
    form =
      %Medcamp.Mch.AntenatalProfile{pregnancy_id: socket.assigns.selected_pregnancy_id}
      |> Mch.change_antenatal_profile(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :antenatal_profile_form, form)}
  end

  @impl true
  def handle_event("save_antenatal_profile", %{"antenatal_profile" => params}, socket) do
    attrs = Map.put(params, "pregnancy_id", socket.assigns.selected_pregnancy_id)

    case Mch.create_antenatal_profile(attrs) do
      {:ok, _profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Antenatal profile recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_antenatal_profile_modal, false)
         |> assign(:selected_pregnancy_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :antenatal_profile_form, to_form(changeset))}
    end
  end

  # Physical Examination
  @impl true
  def handle_event("open_add_physical_examination", %{"pregnancy-id" => pregnancy_id}, socket) do
    form =
      Mch.change_physical_examination(%Medcamp.Mch.PhysicalExamination{
        pregnancy_id: String.to_integer(pregnancy_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_physical_examination_modal, true)
     |> assign(:selected_pregnancy_id, String.to_integer(pregnancy_id))
     |> assign(:physical_examination_form, form)}
  end

  @impl true
  def handle_event("close_add_physical_examination", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_physical_examination_modal, false)
     |> assign(:selected_pregnancy_id, nil)}
  end

  @impl true
  def handle_event("validate_physical_examination", %{"physical_examination" => params}, socket) do
    form =
      %Medcamp.Mch.PhysicalExamination{pregnancy_id: socket.assigns.selected_pregnancy_id}
      |> Mch.change_physical_examination(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :physical_examination_form, form)}
  end

  @impl true
  def handle_event("save_physical_examination", %{"physical_examination" => params}, socket) do
    attrs = Map.put(params, "pregnancy_id", socket.assigns.selected_pregnancy_id)

    case Mch.create_physical_examination(attrs) do
      {:ok, _exam} ->
        {:noreply,
         socket
         |> put_flash(:info, "Physical examination recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_physical_examination_modal, false)
         |> assign(:selected_pregnancy_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :physical_examination_form, to_form(changeset))}
    end
  end

  # Preventive services
  @impl true
  def handle_event("open_add_td_vaccination", _params, socket) do
    form =
      Mch.change_td_vaccination(%Medcamp.Mch.TdVaccination{
        mother_id: socket.assigns.mch_summary.mother.id
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_td_vaccination_modal, true)
     |> assign(:td_vaccination_form, form)}
  end

  @impl true
  def handle_event("close_add_td_vaccination", _params, socket) do
    {:noreply, assign(socket, :show_add_td_vaccination_modal, false)}
  end

  @impl true
  def handle_event("validate_td_vaccination", %{"td_vaccination" => params}, socket) do
    form =
      %Medcamp.Mch.TdVaccination{mother_id: socket.assigns.mch_summary.mother.id}
      |> Mch.change_td_vaccination(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :td_vaccination_form, form)}
  end

  @impl true
  def handle_event("save_td_vaccination", %{"td_vaccination" => params}, socket) do
    attrs = Map.put(params, "mother_id", socket.assigns.mch_summary.mother.id)

    case Mch.create_td_vaccination(attrs) do
      {:ok, _td} ->
        {:noreply,
         socket
         |> put_flash(:info, "TD vaccination recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_td_vaccination_modal, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :td_vaccination_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("open_add_malaria_prophylaxis", %{"pregnancy-id" => pregnancy_id}, socket) do
    form =
      Mch.change_malaria_prophylaxis(%Medcamp.Mch.MalariaProphylaxis{
        pregnancy_id: String.to_integer(pregnancy_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_malaria_prophylaxis_modal, true)
     |> assign(:selected_pregnancy_id, String.to_integer(pregnancy_id))
     |> assign(:malaria_prophylaxis_form, form)}
  end

  @impl true
  def handle_event("close_add_malaria_prophylaxis", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_malaria_prophylaxis_modal, false)
     |> assign(:selected_pregnancy_id, nil)}
  end

  @impl true
  def handle_event("validate_malaria_prophylaxis", %{"malaria_prophylaxis" => params}, socket) do
    form =
      %Medcamp.Mch.MalariaProphylaxis{pregnancy_id: socket.assigns.selected_pregnancy_id}
      |> Mch.change_malaria_prophylaxis(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :malaria_prophylaxis_form, form)}
  end

  @impl true
  def handle_event("save_malaria_prophylaxis", %{"malaria_prophylaxis" => params}, socket) do
    attrs = Map.put(params, "pregnancy_id", socket.assigns.selected_pregnancy_id)

    case Mch.create_malaria_prophylaxis(attrs) do
      {:ok, _dose} ->
        {:noreply,
         socket
         |> put_flash(:info, "Malaria prophylaxis recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_malaria_prophylaxis_modal, false)
         |> assign(:selected_pregnancy_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :malaria_prophylaxis_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("open_add_ifas", %{"pregnancy-id" => pregnancy_id}, socket) do
    form =
      Mch.change_ifas_supplement(%Medcamp.Mch.IfasSupplement{
        pregnancy_id: String.to_integer(pregnancy_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_ifas_modal, true)
     |> assign(:selected_pregnancy_id, String.to_integer(pregnancy_id))
     |> assign(:ifas_form, form)}
  end

  @impl true
  def handle_event("close_add_ifas", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_ifas_modal, false)
     |> assign(:selected_pregnancy_id, nil)}
  end

  @impl true
  def handle_event("validate_ifas", %{"ifas_supplement" => params}, socket) do
    form =
      %Medcamp.Mch.IfasSupplement{pregnancy_id: socket.assigns.selected_pregnancy_id}
      |> Mch.change_ifas_supplement(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :ifas_form, form)}
  end

  @impl true
  def handle_event("save_ifas", %{"ifas_supplement" => params}, socket) do
    attrs = Map.put(params, "pregnancy_id", socket.assigns.selected_pregnancy_id)

    case Mch.create_ifas_supplement(attrs) do
      {:ok, _ifas} ->
        {:noreply,
         socket
         |> put_flash(:info, "Iron and folate supplementation recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_ifas_modal, false)
         |> assign(:selected_pregnancy_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :ifas_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("open_add_deworming_maternal", %{"pregnancy-id" => pregnancy_id}, socket) do
    form =
      Mch.change_deworming_maternal(%Medcamp.Mch.DewormingMaternal{
        pregnancy_id: String.to_integer(pregnancy_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_deworming_maternal_modal, true)
     |> assign(:selected_pregnancy_id, String.to_integer(pregnancy_id))
     |> assign(:deworming_maternal_form, form)}
  end

  @impl true
  def handle_event("close_add_deworming_maternal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_deworming_maternal_modal, false)
     |> assign(:selected_pregnancy_id, nil)}
  end

  @impl true
  def handle_event("validate_deworming_maternal", %{"deworming_maternal" => params}, socket) do
    form =
      %Medcamp.Mch.DewormingMaternal{pregnancy_id: socket.assigns.selected_pregnancy_id}
      |> Mch.change_deworming_maternal(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :deworming_maternal_form, form)}
  end

  @impl true
  def handle_event("save_deworming_maternal", %{"deworming_maternal" => params}, socket) do
    attrs = Map.put(params, "pregnancy_id", socket.assigns.selected_pregnancy_id)

    case Mch.create_deworming_maternal(attrs) do
      {:ok, _deworming} ->
        {:noreply,
         socket
         |> put_flash(:info, "Maternal deworming recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_deworming_maternal_modal, false)
         |> assign(:selected_pregnancy_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :deworming_maternal_form, to_form(changeset))}
    end
  end

  # Postnatal care
  @impl true
  def handle_event("open_add_pnc_mother_visit", _params, socket) do
    form =
      Mch.change_pnc_mother_visit(%Medcamp.Mch.PncMotherVisit{
        mother_id: socket.assigns.mch_summary.mother.id
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_pnc_mother_visit_modal, true)
     |> assign(:pnc_mother_visit_form, form)}
  end

  @impl true
  def handle_event("close_add_pnc_mother_visit", _params, socket) do
    {:noreply, assign(socket, :show_add_pnc_mother_visit_modal, false)}
  end

  @impl true
  def handle_event("validate_pnc_mother_visit", %{"pnc_mother_visit" => params}, socket) do
    form =
      %Medcamp.Mch.PncMotherVisit{mother_id: socket.assigns.mch_summary.mother.id}
      |> Mch.change_pnc_mother_visit(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :pnc_mother_visit_form, form)}
  end

  @impl true
  def handle_event("save_pnc_mother_visit", %{"pnc_mother_visit" => params}, socket) do
    attrs = Map.put(params, "mother_id", socket.assigns.mch_summary.mother.id)

    case Mch.create_pnc_mother_visit(attrs) do
      {:ok, _visit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Mother postnatal visit recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_pnc_mother_visit_modal, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :pnc_mother_visit_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("open_add_pnc_baby_visit", %{"child-id" => child_id}, socket) do
    form =
      Mch.change_pnc_baby_visit(%Medcamp.Mch.PncBabyVisit{
        child_id: String.to_integer(child_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_pnc_baby_visit_modal, true)
     |> assign(:selected_child_id, String.to_integer(child_id))
     |> assign(:pnc_baby_visit_form, form)}
  end

  @impl true
  def handle_event("close_add_pnc_baby_visit", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_pnc_baby_visit_modal, false)
     |> assign(:selected_child_id, nil)}
  end

  @impl true
  def handle_event("validate_pnc_baby_visit", %{"pnc_baby_visit" => params}, socket) do
    form =
      %Medcamp.Mch.PncBabyVisit{child_id: socket.assigns.selected_child_id}
      |> Mch.change_pnc_baby_visit(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :pnc_baby_visit_form, form)}
  end

  @impl true
  def handle_event("save_pnc_baby_visit", %{"pnc_baby_visit" => params}, socket) do
    attrs = Map.put(params, "child_id", socket.assigns.selected_child_id)

    case Mch.create_pnc_baby_visit(attrs) do
      {:ok, _visit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Baby postnatal visit recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_pnc_baby_visit_modal, false)
         |> assign(:selected_child_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :pnc_baby_visit_form, to_form(changeset))}
    end
  end

  # Child supplements
  @impl true
  def handle_event("open_add_vitamin_a", %{"child-id" => child_id}, socket) do
    form =
      Mch.change_vitamin_a_supplement(%Medcamp.Mch.VitaminASupplement{
        child_id: String.to_integer(child_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_vitamin_a_modal, true)
     |> assign(:selected_child_id, String.to_integer(child_id))
     |> assign(:vitamin_a_form, form)}
  end

  @impl true
  def handle_event("close_add_vitamin_a", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_vitamin_a_modal, false)
     |> assign(:selected_child_id, nil)}
  end

  @impl true
  def handle_event("validate_vitamin_a", %{"vitamin_a_supplement" => params}, socket) do
    form =
      %Medcamp.Mch.VitaminASupplement{child_id: socket.assigns.selected_child_id}
      |> Mch.change_vitamin_a_supplement(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :vitamin_a_form, form)}
  end

  @impl true
  def handle_event("save_vitamin_a", %{"vitamin_a_supplement" => params}, socket) do
    attrs = Map.put(params, "child_id", socket.assigns.selected_child_id)

    case Mch.create_vitamin_a_supplement(attrs) do
      {:ok, _supplement} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vitamin A supplementation recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_vitamin_a_modal, false)
         |> assign(:selected_child_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :vitamin_a_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("open_add_child_deworming", %{"child-id" => child_id}, socket) do
    form =
      Mch.change_child_deworming(%Medcamp.Mch.ChildDeworming{
        child_id: String.to_integer(child_id)
      })
      |> to_form()

    {:noreply,
     socket
     |> assign(:show_add_child_deworming_modal, true)
     |> assign(:selected_child_id, String.to_integer(child_id))
     |> assign(:child_deworming_form, form)}
  end

  @impl true
  def handle_event("close_add_child_deworming", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_child_deworming_modal, false)
     |> assign(:selected_child_id, nil)}
  end

  @impl true
  def handle_event("validate_child_deworming", %{"child_deworming" => params}, socket) do
    form =
      %Medcamp.Mch.ChildDeworming{child_id: socket.assigns.selected_child_id}
      |> Mch.change_child_deworming(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :child_deworming_form, form)}
  end

  @impl true
  def handle_event("save_child_deworming", %{"child_deworming" => params}, socket) do
    attrs = Map.put(params, "child_id", socket.assigns.selected_child_id)

    case Mch.create_child_deworming(attrs) do
      {:ok, _deworming} ->
        {:noreply,
         socket
         |> put_flash(:info, "Child deworming recorded.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_add_child_deworming_modal, false)
         |> assign(:selected_child_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :child_deworming_form, to_form(changeset))}
    end
  end

  # Edit Child
  @impl true
  def handle_event("open_edit_child", %{"child-id" => child_id}, socket) do
    child = Mch.get_child!(child_id)
    form = to_form(Mch.change_child(child))

    {:noreply,
     socket
     |> assign(:show_edit_child_modal, true)
     |> assign(:selected_child_id, child.id)
     |> assign(:edit_child_form, form)}
  end

  @impl true
  def handle_event("close_edit_child", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_edit_child_modal, false)
     |> assign(:selected_child_id, nil)}
  end

  @impl true
  def handle_event("validate_edit_child", %{"child" => params}, socket) do
    child = Mch.get_child!(socket.assigns.selected_child_id)

    form =
      child
      |> Mch.change_child(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :edit_child_form, form)}
  end

  @impl true
  def handle_event("save_edit_child", %{"child" => params}, socket) do
    child = Mch.get_child!(socket.assigns.selected_child_id)

    case Mch.update_child(child, params) do
      {:ok, _} ->
        summary = Mch.get_mch_summary_for_patient(socket.assigns.patient_id)

        {:noreply,
         socket
         |> put_flash(:info, "Child updated.")
         |> assign(:mch_summary, summary)
         |> assign(:show_edit_child_modal, false)
         |> assign(:selected_child_id, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :edit_child_form, to_form(changeset))}
    end
  end

  # Edit ANC Visit
  @impl true
  def handle_event("open_edit_anc_visit", %{"anc-visit-id" => id}, socket) do
    anc_visit = Mch.get_anc_visit!(id)
    form = to_form(Mch.change_anc_visit(anc_visit))

    {:noreply,
     socket
     |> assign(:show_edit_anc_visit_modal, true)
     |> assign(:editing_anc_visit_id, String.to_integer(id))
     |> assign(:edit_anc_visit_form, form)}
  end

  @impl true
  def handle_event("close_edit_anc_visit", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_edit_anc_visit_modal, false)
     |> assign(:editing_anc_visit_id, nil)}
  end

  @impl true
  def handle_event("validate_edit_anc_visit", %{"anc_visit" => params}, socket) do
    anc_visit = Mch.get_anc_visit!(socket.assigns.editing_anc_visit_id)
    form = anc_visit |> Mch.change_anc_visit(params) |> Map.put(:action, :validate) |> to_form()
    {:noreply, assign(socket, :edit_anc_visit_form, form)}
  end

  @impl true
  def handle_event("save_edit_anc_visit", %{"anc_visit" => params}, socket) do
    anc_visit = Mch.get_anc_visit!(socket.assigns.editing_anc_visit_id)

    case Mch.update_anc_visit(anc_visit, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "ANC visit updated.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_edit_anc_visit_modal, false)
         |> assign(:editing_anc_visit_id, nil)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :edit_anc_visit_form, to_form(cs))}
    end
  end

  # Edit Delivery
  @impl true
  def handle_event("open_edit_delivery", %{"delivery-id" => id}, socket) do
    delivery = Mch.get_delivery!(id)
    form = to_form(Mch.change_delivery(delivery))

    {:noreply,
     socket
     |> assign(:show_edit_delivery_modal, true)
     |> assign(:editing_delivery_id, String.to_integer(id))
     |> assign(:edit_delivery_form, form)}
  end

  @impl true
  def handle_event("close_edit_delivery", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_edit_delivery_modal, false)
     |> assign(:editing_delivery_id, nil)}
  end

  @impl true
  def handle_event("validate_edit_delivery", %{"delivery" => params}, socket) do
    delivery = Mch.get_delivery!(socket.assigns.editing_delivery_id)
    form = delivery |> Mch.change_delivery(params) |> Map.put(:action, :validate) |> to_form()
    {:noreply, assign(socket, :edit_delivery_form, form)}
  end

  @impl true
  def handle_event("save_edit_delivery", %{"delivery" => params}, socket) do
    delivery = Mch.get_delivery!(socket.assigns.editing_delivery_id)

    case Mch.update_delivery(delivery, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Delivery updated.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_edit_delivery_modal, false)
         |> assign(:editing_delivery_id, nil)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :edit_delivery_form, to_form(cs))}
    end
  end

  # Edit Growth
  @impl true
  def handle_event("open_edit_growth", %{"growth-id" => id}, socket) do
    growth = Mch.get_growth_measurement!(id)
    form = to_form(Mch.change_growth_measurement(growth))

    {:noreply,
     socket
     |> assign(:show_edit_growth_modal, true)
     |> assign(:editing_growth_id, String.to_integer(id))
     |> assign(:edit_growth_form, form)}
  end

  @impl true
  def handle_event("close_edit_growth", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_edit_growth_modal, false)
     |> assign(:editing_growth_id, nil)}
  end

  @impl true
  def handle_event("validate_edit_growth", %{"growth_measurement" => params}, socket) do
    growth = Mch.get_growth_measurement!(socket.assigns.editing_growth_id)

    form =
      growth |> Mch.change_growth_measurement(params) |> Map.put(:action, :validate) |> to_form()

    {:noreply, assign(socket, :edit_growth_form, form)}
  end

  @impl true
  def handle_event("save_edit_growth", %{"growth_measurement" => params}, socket) do
    growth = Mch.get_growth_measurement!(socket.assigns.editing_growth_id)

    case Mch.update_growth_measurement(growth, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Growth measurement updated.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_edit_growth_modal, false)
         |> assign(:editing_growth_id, nil)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :edit_growth_form, to_form(cs))}
    end
  end

  # Edit Immunization
  @impl true
  def handle_event("open_edit_immunization", %{"immunization-id" => id}, socket) do
    immunization = Mch.get_immunization!(id)
    form = to_form(Mch.change_immunization(immunization))

    {:noreply,
     socket
     |> assign(:show_edit_immunization_modal, true)
     |> assign(:editing_immunization_id, String.to_integer(id))
     |> assign(:edit_immunization_form, form)}
  end

  @impl true
  def handle_event("close_edit_immunization", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_edit_immunization_modal, false)
     |> assign(:editing_immunization_id, nil)}
  end

  @impl true
  def handle_event("validate_edit_immunization", %{"immunization" => params}, socket) do
    immunization = Mch.get_immunization!(socket.assigns.editing_immunization_id)

    form =
      immunization |> Mch.change_immunization(params) |> Map.put(:action, :validate) |> to_form()

    {:noreply, assign(socket, :edit_immunization_form, form)}
  end

  @impl true
  def handle_event("save_edit_immunization", %{"immunization" => params}, socket) do
    immunization = Mch.get_immunization!(socket.assigns.editing_immunization_id)

    case Mch.update_immunization(immunization, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Immunization updated.")
         |> assign(:mch_summary, Mch.get_mch_summary_for_patient(socket.assigns.patient_id))
         |> assign(:show_edit_immunization_modal, false)
         |> assign(:editing_immunization_id, nil)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, :edit_immunization_form, to_form(cs))}
    end
  end

  defp maybe_assign_mother_form(socket, %{mother: mother}) do
    assign(socket, :mother_form, to_form(Mch.change_mother(mother)))
  end

  defp maybe_assign_mother_form(socket, nil), do: socket

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.mch_header patient={@patient} mch_summary={@mch_summary} />

      <%= if @mch_summary do %>
        <.mch_tabs sub_tab={@sub_tab} />

        <div class="mt-6">
          <%= case @sub_tab do %>
            <% :overview -> %>
              <.mch_overview mch_summary={@mch_summary} patient_id={@patient_id} />
            <% :maternal -> %>
              <.mch_maternal mch_summary={@mch_summary} patient_id={@patient_id} />
            <% :children -> %>
              <.mch_children mch_summary={@mch_summary} patient_id={@patient_id} />
          <% end %>
        </div>

        <.edit_mother_modal :if={@show_edit_mother_modal} form={@mother_form} />
        <.add_pregnancy_modal :if={@show_add_pregnancy_modal} form={@pregnancy_form} />
        <.add_child_modal :if={@show_add_child_modal} form={@child_form} />
        <.add_anc_visit_modal :if={@show_add_anc_visit_modal} form={@anc_visit_form} />
        <.record_delivery_modal :if={@show_record_delivery_modal} form={@delivery_form} />
        <.add_growth_modal :if={@show_add_growth_modal} form={@growth_form} />
        <.add_immunization_modal :if={@show_add_immunization_modal} form={@immunization_form} />
        <.add_developmental_milestone_modal
          :if={@show_add_developmental_milestone_modal}
          form={@developmental_milestone_form}
        />
        <.add_eye_assessment_modal :if={@show_add_eye_assessment_modal} form={@eye_assessment_form} />
        <.add_antenatal_profile_modal
          :if={@show_add_antenatal_profile_modal}
          form={@antenatal_profile_form}
        />
        <.add_physical_examination_modal
          :if={@show_add_physical_examination_modal}
          form={@physical_examination_form}
        />
        <.add_td_vaccination_modal :if={@show_add_td_vaccination_modal} form={@td_vaccination_form} />
        <.add_malaria_prophylaxis_modal
          :if={@show_add_malaria_prophylaxis_modal}
          form={@malaria_prophylaxis_form}
        />
        <.add_ifas_modal :if={@show_add_ifas_modal} form={@ifas_form} />
        <.add_deworming_maternal_modal
          :if={@show_add_deworming_maternal_modal}
          form={@deworming_maternal_form}
        />
        <.add_pnc_mother_visit_modal
          :if={@show_add_pnc_mother_visit_modal}
          form={@pnc_mother_visit_form}
          delivery_options={delivery_options(@mch_summary)}
        />
        <.add_pnc_baby_visit_modal
          :if={@show_add_pnc_baby_visit_modal}
          form={@pnc_baby_visit_form}
          pnc_options={pnc_mother_visit_options(@mch_summary)}
        />
        <.add_vitamin_a_modal :if={@show_add_vitamin_a_modal} form={@vitamin_a_form} />
        <.add_child_deworming_modal
          :if={@show_add_child_deworming_modal}
          form={@child_deworming_form}
        />
        <.edit_child_modal :if={@show_edit_child_modal} form={@edit_child_form} />
        <.edit_anc_visit_modal :if={@show_edit_anc_visit_modal} form={@edit_anc_visit_form} />
        <.edit_delivery_modal :if={@show_edit_delivery_modal} form={@edit_delivery_form} />
        <.edit_growth_modal :if={@show_edit_growth_modal} form={@edit_growth_form} />
        <.edit_immunization_modal :if={@show_edit_immunization_modal} form={@edit_immunization_form} />
      <% else %>
        <.mch_enroll_prompt patient={@patient} patient_id={@patient_id} />
      <% end %>
    </div>
    """
  end

  defp mch_header(assigns) do
    ~H"""
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="flex items-center gap-4">
        <div class="flex h-12 w-12 items-center justify-center rounded-lg bg-[#373896]/10">
          <Heroicons.icon name="heart" type="outline" class="h-6 w-6 text-[#373896]" />
        </div>
        <div>
          <h1 class="text-xl font-semibold text-slate-900">Mother & Child Health</h1>
          <p class="text-sm text-slate-500">
            MOH 216 — Antenatal, delivery & child health (0–5 years)
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp mch_tabs(assigns) do
    ~H"""
    <div class="flex gap-2 border-b border-slate-200">
      <button
        phx-click="set_sub_tab"
        phx-value-tab="overview"
        class={[
          "px-4 py-2 text-sm font-medium rounded-t-lg transition-colors",
          @sub_tab == :overview && "bg-[#e8e8ff] text-[#373896]",
          @sub_tab != :overview && "text-slate-600 hover:bg-slate-100"
        ]}
      >
        Overview
      </button>
      <button
        phx-click="set_sub_tab"
        phx-value-tab="maternal"
        class={[
          "px-4 py-2 text-sm font-medium rounded-t-lg transition-colors",
          @sub_tab == :maternal && "bg-[#e8e8ff] text-[#373896]",
          @sub_tab != :maternal && "text-slate-600 hover:bg-slate-100"
        ]}
      >
        ANC & Delivery
      </button>
      <button
        phx-click="set_sub_tab"
        phx-value-tab="children"
        class={[
          "px-4 py-2 text-sm font-medium rounded-t-lg transition-colors",
          @sub_tab == :children && "bg-[#e8e8ff] text-[#373896]",
          @sub_tab != :children && "text-slate-600 hover:bg-slate-100"
        ]}
      >
        Child Health
      </button>
    </div>
    """
  end

  defp mch_enroll_prompt(assigns) do
    ~H"""
    <div class="rounded-xl border border-dashed border-slate-300 bg-slate-50/50 p-12 text-center">
      <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-slate-200">
        <Heroicons.icon name="user-plus" type="outline" class="h-8 w-8 text-slate-500" />
      </div>
      <h3 class="mt-4 text-lg font-medium text-slate-900">Enroll in MCH Program</h3>
      <p class="mx-auto mt-2 max-w-md text-sm text-slate-600">
        This patient is not yet in the Mother & Child Health program. Enroll to track antenatal care,
        deliveries, postnatal care, and child health (0–5 years).
      </p>
      <button
        phx-click="enroll_mch"
        class="mt-6 rounded-lg bg-[#6667ab] px-4 py-2 text-sm font-medium text-white hover:bg-[#5556a0] transition-colors"
      >
        Enroll Patient in MCH
      </button>
    </div>
    """
  end

  defp mch_overview(assigns) do
    ~H"""
    <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100">
            <Heroicons.icon name="queue-list" type="outline" class="h-5 w-5 text-amber-600" />
          </div>
          <div>
            <p class="text-sm font-medium text-slate-500">Pregnancies</p>
            <p class="text-2xl font-semibold text-slate-900">
              {length(@mch_summary.pregnancies)}
            </p>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-100">
            <Heroicons.icon name="user-group" type="outline" class="h-5 w-5 text-emerald-600" />
          </div>
          <div>
            <p class="text-sm font-medium text-slate-500">Children (0–5 yrs)</p>
            <p class="text-2xl font-semibold text-slate-900">
              {length(@mch_summary.children)}
            </p>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-sky-100">
            <Heroicons.icon name="beaker" type="outline" class="h-5 w-5 text-sky-600" />
          </div>
          <div>
            <p class="text-sm font-medium text-slate-500">ANC Visits</p>
            <p class="text-2xl font-semibold text-slate-900">
              {total_anc_visits(@mch_summary.pregnancies)}
            </p>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-100">
            <Heroicons.icon name="calendar-days" type="outline" class="h-5 w-5 text-indigo-600" />
          </div>
          <div>
            <p class="text-sm font-medium text-slate-500">Active Pregnancy</p>
            <p class="text-lg font-semibold text-slate-900">
              <%= if @mch_summary.active_pregnancy do %>
                <span class="text-emerald-600">Yes</span>
                <%= if @mch_summary.active_pregnancy.edd do %>
                  — EDD: {format_date(@mch_summary.active_pregnancy.edd)}
                <% end %>
              <% else %>
                <span class="text-slate-400">None</span>
              <% end %>
            </p>
          </div>
        </div>
      </div>
    </div>

    <.mother_profile_panel mch_summary={@mch_summary} />

    <.mch_journey mch_summary={@mch_summary} patient_id={@patient_id} />
    """
  end

  defp mch_journey(assigns) do
    ~H"""
    <div class="mt-8 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-slate-900">MCH Journey</h3>
      <p class="mt-1 text-sm text-slate-500">
        Complete timeline — pregnancies, ANC visits, deliveries, and child health
      </p>

      <%= if Enum.empty?(@mch_summary.pregnancies) and Enum.empty?(@mch_summary.children) do %>
        <p class="mt-6 text-sm text-slate-500">
          No journey recorded yet. Add a pregnancy or child to begin.
        </p>
      <% else %>
        <div class="mt-6 space-y-8">
          <.journey_pregnancies pregnancies={@mch_summary.pregnancies} patient_id={@patient_id} />

          <%= if Enum.any?(@mch_summary.children) and Enum.empty?(@mch_summary.pregnancies) do %>
            <.journey_children_standalone children={@mch_summary.children} patient_id={@patient_id} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp journey_pregnancies(assigns) do
    ~H"""
    <div :for={pregnancy <- @pregnancies} class="relative border-l-2 border-slate-200 pl-6">
      <div class="absolute -left-[9px] top-2 h-4 w-4 rounded-full bg-[#6667ab]" />
      <div class="rounded-lg border border-slate-100 bg-slate-50/50 p-4">
        <div class="flex items-center gap-2">
          <span class="font-medium text-slate-900">Pregnancy</span>
          <span class={[
            "rounded-full px-2 py-0.5 text-xs font-medium",
            pregnancy.status == "active" && "bg-emerald-100 text-emerald-700",
            pregnancy.status != "active" && "bg-slate-200 text-slate-600"
          ]}>
            {pregnancy.status}
          </span>
          <%= if pregnancy.lmp do %>
            <span class="text-sm text-slate-500">LMP: {format_date(pregnancy.lmp)}</span>
          <% end %>
          <%= if pregnancy.edd do %>
            <span class="text-sm text-slate-500">EDD: {format_date(pregnancy.edd)}</span>
          <% end %>
        </div>

        <.journey_anc_visits pregnancy={pregnancy} patient_id={@patient_id} />
        <.journey_deliveries pregnancy={pregnancy} />
      </div>
    </div>
    """
  end

  defp anc_visits_detail(assigns) do
    assigns =
      assign(
        assigns,
        :anc_visits_sorted,
        Enum.sort_by(
          assigns.pregnancy.anc_visits || [],
          &(&1.visit_date || ~D[1900-01-01]),
          {:asc, Date}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@anc_visits_sorted)} ANC visit(s)
      </summary>
      <%= if @anc_visits_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No ANC visits recorded.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Contact</th>
                <th class="py-2 pr-4 text-slate-500">Date</th>
                <th class="py-2 pr-4 text-slate-500">Gest (w)</th>
                <th class="py-2 pr-4 text-slate-500">Weight</th>
                <th class="py-2 pr-4 text-slate-500">BP</th>
                <th class="py-2 pr-4 text-slate-500">Hb</th>
                <th class="py-2 pr-4 text-slate-500">MUAC</th>
                <th class="py-2 pr-4 text-slate-500">FHR</th>
                <th class="py-2 pr-4 text-slate-500">Next</th>
                <th class="py-2 w-12"></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={visit <- @anc_visits_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">{visit.contact_number || "—"}</td>
                <td class="py-2 pr-4">
                  {(visit.visit_date && format_date(visit.visit_date)) || "—"}
                </td>
                <td class="py-2 pr-4">{visit.gestation_weeks || "—"}</td>
                <td class="py-2 pr-4">{(visit.weight_kg && "#{visit.weight_kg} kg") || "—"}</td>
                <td class="py-2 pr-4">
                  {if visit.bp_systolic && visit.bp_diastolic,
                    do: "#{visit.bp_systolic}/#{visit.bp_diastolic}",
                    else: "—"}
                </td>
                <td class="py-2 pr-4">{visit.haemoglobin || "—"}</td>
                <td class="py-2 pr-4">{(visit.muac_cm && "#{visit.muac_cm} cm") || "—"}</td>
                <td class="py-2 pr-4">{visit.foetal_heart_rate || "—"}</td>
                <td class="py-2 pr-4">
                  {(visit.next_visit_date && format_date(visit.next_visit_date)) || "—"}
                </td>
                <td class="py-2">
                  <button
                    phx-click="open_edit_anc_visit"
                    phx-value-anc-visit-id={visit.id}
                    class="text-xs text-[#6667ab] hover:underline"
                  >
                    Edit
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp child_growth_detail(assigns) do
    assigns =
      assign(
        assigns,
        :growth_sorted,
        Enum.sort_by(
          assigns.child.growth_measurements || [],
          &(&1.measurement_date || ~D[1900-01-01]),
          {:desc, Date}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@growth_sorted)} growth record(s)
      </summary>
      <%= if @growth_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No growth records.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Date</th>
                <th class="py-2 pr-4 text-slate-500">Age (mo)</th>
                <th class="py-2 pr-4 text-slate-500">Weight</th>
                <th class="py-2 pr-4 text-slate-500">Length/Ht</th>
                <th class="py-2 pr-4 text-slate-500">Head circ.</th>
                <th class="py-2 pr-4 text-slate-500">MUAC</th>
                <th class="py-2 pr-4 text-slate-500">Status</th>
                <th class="py-2 pr-4 text-slate-500">Next</th>
                <th class="py-2 w-12"></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={g <- @growth_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">
                  {(g.measurement_date && format_date(g.measurement_date)) || "—"}
                </td>
                <td class="py-2 pr-4">{g.age_months || "—"}</td>
                <td class="py-2 pr-4">{(g.weight_kg && "#{g.weight_kg} kg") || "—"}</td>
                <td class="py-2 pr-4">{(g.length_height_cm && "#{g.length_height_cm} cm") || "—"}</td>
                <td class="py-2 pr-4">
                  {(g.head_circumference_cm && "#{g.head_circumference_cm} cm") || "—"}
                </td>
                <td class="py-2 pr-4">{(g.muac_cm && "#{g.muac_cm} cm") || "—"}</td>
                <td class="py-2 pr-4">{g.nutritional_status || "—"}</td>
                <td class="py-2 pr-4">
                  {(g.next_visit_date && format_date(g.next_visit_date)) || "—"}
                </td>
                <td class="py-2">
                  <button
                    phx-click="open_edit_growth"
                    phx-value-growth-id={g.id}
                    class="text-xs text-[#6667ab] hover:underline"
                  >
                    Edit
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp child_immunizations_detail(assigns) do
    assigns =
      assign(
        assigns,
        :immunizations_sorted,
        Enum.sort_by(
          assigns.child.immunizations || [],
          &(&1.date_given || ~D[1900-01-01]),
          {:asc, Date}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@immunizations_sorted)} immunization(s)
      </summary>
      <%= if @immunizations_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No immunizations recorded.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Vaccine</th>
                <th class="py-2 pr-4 text-slate-500">Dose</th>
                <th class="py-2 pr-4 text-slate-500">Scheduled age</th>
                <th class="py-2 pr-4 text-slate-500">Date given</th>
                <th class="py-2 pr-4 text-slate-500">Batch</th>
                <th class="py-2 pr-4 text-slate-500">AEFI</th>
                <th class="py-2 pr-4 text-slate-500">Next</th>
                <th class="py-2 w-12"></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={imm <- @immunizations_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">{imm.vaccine_name || "—"}</td>
                <td class="py-2 pr-4">{imm.dose_number || "—"}</td>
                <td class="py-2 pr-4">{imm.scheduled_age || "—"}</td>
                <td class="py-2 pr-4">{(imm.date_given && format_date(imm.date_given)) || "—"}</td>
                <td class="py-2 pr-4">{imm.batch_number || "—"}</td>
                <td class="py-2 pr-4">
                  <%= if imm.adverse_event do %>
                    {imm.adverse_event_description || "Reported"}
                  <% else %>
                    No
                  <% end %>
                </td>
                <td class="py-2 pr-4">
                  {(imm.next_visit_date && format_date(imm.next_visit_date)) || "—"}
                </td>
                <td class="py-2">
                  <button
                    phx-click="open_edit_immunization"
                    phx-value-immunization-id={imm.id}
                    class="text-xs text-[#6667ab] hover:underline"
                  >
                    Edit
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp journey_anc_visits(assigns) do
    assigns =
      assign(
        assigns,
        :anc_visits_sorted,
        Enum.sort_by(
          assigns.pregnancy.anc_visits || [],
          &(&1.visit_date || ~D[1900-01-01]),
          {:asc, Date}
        )
      )

    ~H"""
    <details class="mt-3">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        {length(@anc_visits_sorted)} ANC visit(s)
      </summary>
      <%= if @anc_visits_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No ANC visits recorded.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Contact</th>
                <th class="py-2 pr-4 text-slate-500">Date</th>
                <th class="py-2 pr-4 text-slate-500">Gest (w)</th>
                <th class="py-2 pr-4 text-slate-500">Weight</th>
                <th class="py-2 pr-4 text-slate-500">BP</th>
                <th class="py-2 pr-4 text-slate-500">Hb</th>
                <th class="py-2 pr-4 text-slate-500">MUAC</th>
                <th class="py-2 pr-4 text-slate-500">FHR</th>
                <th class="py-2 pr-4 text-slate-500">Next</th>
                <th class="py-2 w-12"></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={visit <- @anc_visits_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">{visit.contact_number || "—"}</td>
                <td class="py-2 pr-4">
                  {(visit.visit_date && format_date(visit.visit_date)) || "—"}
                </td>
                <td class="py-2 pr-4">{visit.gestation_weeks || "—"}</td>
                <td class="py-2 pr-4">{(visit.weight_kg && "#{visit.weight_kg} kg") || "—"}</td>
                <td class="py-2 pr-4">
                  {if visit.bp_systolic && visit.bp_diastolic,
                    do: "#{visit.bp_systolic}/#{visit.bp_diastolic}",
                    else: "—"}
                </td>
                <td class="py-2 pr-4">{visit.haemoglobin || "—"}</td>
                <td class="py-2 pr-4">{(visit.muac_cm && "#{visit.muac_cm} cm") || "—"}</td>
                <td class="py-2 pr-4">{visit.foetal_heart_rate || "—"}</td>
                <td class="py-2 pr-4">
                  {(visit.next_visit_date && format_date(visit.next_visit_date)) || "—"}
                </td>
                <td class="py-2">
                  <button
                    phx-click="open_edit_anc_visit"
                    phx-value-anc-visit-id={visit.id}
                    class="text-xs text-[#6667ab] hover:underline"
                  >
                    Edit
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="mt-2">
          <button
            phx-click="open_add_anc_visit"
            phx-value-pregnancy-id={assigns.pregnancy.id}
            class="text-xs font-medium text-[#6667ab] hover:text-[#5556a0]"
          >
            + Add ANC Visit
          </button>
        </div>
      <% end %>
    </details>
    """
  end

  defp journey_deliveries(assigns) do
    deliveries = assigns.pregnancy.deliveries || []
    assigns = assign(assigns, :deliveries_with_child, Enum.filter(deliveries, & &1.child_id))

    ~H"""
    <%= if @deliveries_with_child != [] do %>
      <div class="mt-3 space-y-2">
        <p class="text-sm font-medium text-slate-600">Deliveries</p>
        <div
          :for={delivery <- @deliveries_with_child}
          class="ml-2 rounded border border-slate-100 bg-white p-3"
        >
          <div class="flex items-center justify-between flex-wrap gap-2">
            <div>
              <span class="font-medium text-slate-900">
                {if delivery.child, do: delivery.child.name || "Baby", else: "Baby"}
                <%= if delivery.child && delivery.child.sex do %>
                  ({delivery.child.sex})
                <% end %>
              </span>
              <span class="ml-2 text-sm text-slate-500">
                {(delivery.delivery_date && format_date(delivery.delivery_date)) || "—"}
                <%= if delivery.birth_weight_grams do %>
                  · {delivery.birth_weight_grams}g
                <% end %>
                <%= if delivery.mode_of_delivery do %>
                  · {delivery.mode_of_delivery}
                <% end %>
              </span>
            </div>
            <button
              phx-click="open_edit_delivery"
              phx-value-delivery-id={delivery.id}
              class="text-xs text-slate-600 hover:underline"
            >
              Edit Delivery
            </button>
          </div>
          <%= if delivery.child do %>
            <.journey_child_health child={delivery.child} />
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp journey_child_health(assigns) do
    ~H"""
    <div class="mt-2 space-y-2">
      <div class="flex gap-2">
        <button
          phx-click="open_edit_child"
          phx-value-child-id={@child.id}
          class="text-xs font-medium text-slate-600 hover:underline"
        >
          Edit Child
        </button>
        <button
          phx-click="open_add_growth"
          phx-value-child-id={@child.id}
          class="text-xs font-medium text-[#6667ab] hover:underline"
        >
          + Growth
        </button>
        <button
          phx-click="open_add_immunization"
          phx-value-child-id={@child.id}
          class="text-xs font-medium text-[#6667ab] hover:underline"
        >
          + Immunization
        </button>
        <button
          phx-click="open_add_developmental_milestone"
          phx-value-child-id={@child.id}
          class="text-xs font-medium text-[#6667ab] hover:underline"
        >
          + Milestone
        </button>
        <button
          phx-click="open_add_eye_assessment"
          phx-value-child-id={@child.id}
          class="text-xs font-medium text-slate-600 hover:underline"
        >
          + Eye Check
        </button>
        <button
          phx-click="open_add_pnc_baby_visit"
          phx-value-child-id={@child.id}
          class="text-xs font-medium text-slate-600 hover:underline"
        >
          + PNC
        </button>
      </div>
      <.child_growth_detail child={@child} />
      <.child_immunizations_detail child={@child} />
      <.developmental_milestones_detail child={@child} />
      <.eye_assessments_detail child={@child} />
      <.pnc_baby_visits_detail child={@child} />
      <.vitamin_a_detail child={@child} />
      <.child_deworming_detail child={@child} />
    </div>
    """
  end

  defp journey_children_standalone(assigns) do
    ~H"""
    <div class="relative border-l-2 border-slate-200 pl-6">
      <div class="absolute -left-[9px] top-2 h-4 w-4 rounded-full bg-emerald-500" />
      <div class="rounded-lg border border-slate-100 bg-slate-50/50 p-4">
        <p class="font-medium text-slate-900">Children (added directly)</p>
        <div :for={child <- @children} class="mt-2 rounded border border-slate-100 bg-white p-3">
          <div class="flex items-center justify-between">
            <span class="font-medium text-slate-900">{child.name || "Unnamed"}</span>
            <span class="text-sm text-slate-500">
              {(child.date_of_birth && format_date(child.date_of_birth)) || "—"}
              <%= if child.birth_weight_grams do %>
                · {child.birth_weight_grams}g
              <% end %>
            </span>
          </div>
          <.journey_child_health child={child} />
        </div>
      </div>
    </div>
    """
  end

  defp mother_profile_panel(assigns) do
    patient = assigns.mch_summary.mother.patient
    mother = assigns.mch_summary.mother

    assigns =
      assigns
      |> assign(:patient_name, patient_full_name(patient))
      |> assign(:patient_phone, patient && patient.phone_number)
      |> assign(:mother, mother)

    ~H"""
    <div class="mt-8 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="flex items-center justify-between gap-3">
        <div>
          <h3 class="text-lg font-semibold text-slate-900">Maternal Profile</h3>
          <p class="mt-1 text-sm text-slate-500">
            Core identity, ANC details, next-of-kin, and facility information.
          </p>
        </div>
        <button
          phx-click="open_edit_mother"
          class="rounded-lg bg-[#6667ab] px-3 py-1.5 text-sm font-medium text-white hover:bg-[#5556a0] transition-colors"
        >
          Edit Profile
        </button>
      </div>

      <dl class="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Mother</dt>
          <dd class="mt-1 text-sm text-slate-900">{@patient_name}</dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Contact</dt>
          <dd class="mt-1 text-sm text-slate-900">{@patient_phone || "—"}</dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Gravida / Parity</dt>
          <dd class="mt-1 text-sm text-slate-900">
            {@mother.gravida || "—"} / {@mother.parity || "—"}
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Height</dt>
          <dd class="mt-1 text-sm text-slate-900">
            <%= if @mother.height_cm do %>
              {@mother.height_cm} cm
            <% else %>
              —
            <% end %>
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">LMP</dt>
          <dd class="mt-1 text-sm text-slate-900">
            {(@mother.lmp && format_date(@mother.lmp)) || "—"}
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">EDD</dt>
          <dd class="mt-1 text-sm text-slate-900">
            {(@mother.edd && format_date(@mother.edd)) || "—"}
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">
            Gestation by Date
          </dt>
          <dd class="mt-1 text-sm text-slate-900">{gestation_weeks_label(@mother.lmp)}</dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">ANC / PNC Number</dt>
          <dd class="mt-1 text-sm text-slate-900">
            {join_present([@mother.anc_number, @mother.pnc_number], " / ")}
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">
            Marital / Education
          </dt>
          <dd class="mt-1 text-sm text-slate-900">
            {join_present([@mother.marital_status, @mother.education_level], " / ")}
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">County / Ward</dt>
          <dd class="mt-1 text-sm text-slate-900">
            {join_present([@mother.county, @mother.subcounty, @mother.ward], " / ")}
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Physical Address</dt>
          <dd class="mt-1 text-sm text-slate-900">
            {join_present([@mother.town_village, @mother.physical_address], ", ")}
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Next of Kin</dt>
          <dd class="mt-1 text-sm text-slate-900">
            {join_present(
              [@mother.next_of_kin_name, @mother.next_of_kin_relationship, @mother.next_of_kin_phone],
              " · "
            )}
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Facility</dt>
          <dd class="mt-1 text-sm text-slate-900">
            {join_present([@mother.health_facility_name, @mother.kmhfl_code], " · ")}
          </dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">TD Doses</dt>
          <dd class="mt-1 text-sm text-slate-900">{length(@mother.td_vaccinations || [])}</dd>
        </div>
        <div>
          <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">
            PNC Mother Visits
          </dt>
          <dd class="mt-1 text-sm text-slate-900">{length(@mother.pnc_mother_visits || [])}</dd>
        </div>
      </dl>
    </div>
    """
  end

  defp antenatal_profiles_detail(assigns) do
    assigns =
      assign(
        assigns,
        :profiles_sorted,
        Enum.sort_by(
          assigns.pregnancy.antenatal_profiles || [],
          & &1.inserted_at,
          {:desc, DateTime}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@profiles_sorted)} antenatal profile(s)
      </summary>
      <%= if @profiles_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No antenatal profiles recorded.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Recorded</th>
                <th class="py-2 pr-4 text-slate-500">Hb</th>
                <th class="py-2 pr-4 text-slate-500">Blood Group</th>
                <th class="py-2 pr-4 text-slate-500">Rhesus</th>
                <th class="py-2 pr-4 text-slate-500">Urinalysis</th>
                <th class="py-2 pr-4 text-slate-500">HIV</th>
                <th class="py-2 pr-4 text-slate-500">Syphilis</th>
                <th class="py-2 pr-4 text-slate-500">Hep B</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={profile <- @profiles_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">{format_datetime_date(profile.inserted_at)}</td>
                <td class="py-2 pr-4">{profile.haemoglobin_hb || "—"}</td>
                <td class="py-2 pr-4">{profile.blood_group || "—"}</td>
                <td class="py-2 pr-4">{profile.rhesus_factor || "—"}</td>
                <td class="py-2 pr-4">{profile.urinalysis || "—"}</td>
                <td class="py-2 pr-4">{profile.hiv_status || "—"}</td>
                <td class="py-2 pr-4">{profile.syphilis_status || "—"}</td>
                <td class="py-2 pr-4">{profile.hepatitis_b_status || "—"}</td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp physical_examinations_detail(assigns) do
    assigns =
      assign(
        assigns,
        :exams_sorted,
        Enum.sort_by(
          assigns.pregnancy.physical_examinations || [],
          &(&1.examination_date || ~D[1900-01-01]),
          {:desc, Date}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@exams_sorted)} physical examination(s)
      </summary>
      <%= if @exams_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No physical examinations recorded.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Date</th>
                <th class="py-2 pr-4 text-slate-500">BP</th>
                <th class="py-2 pr-4 text-slate-500">Pulse</th>
                <th class="py-2 pr-4 text-slate-500">CVS</th>
                <th class="py-2 pr-4 text-slate-500">Respiratory</th>
                <th class="py-2 pr-4 text-slate-500">Breasts</th>
                <th class="py-2 pr-4 text-slate-500">Abdomen</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={exam <- @exams_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">
                  {(exam.examination_date && format_date(exam.examination_date)) || "—"}
                </td>
                <td class="py-2 pr-4">{format_bp(exam.bp_systolic, exam.bp_diastolic)}</td>
                <td class="py-2 pr-4">{exam.pulse_rate || "—"}</td>
                <td class="py-2 pr-4">{exam.cvs_notes || "—"}</td>
                <td class="py-2 pr-4">{exam.respiratory_notes || "—"}</td>
                <td class="py-2 pr-4">{exam.breasts_notes || "—"}</td>
                <td class="py-2 pr-4">{exam.abdomen_notes || "—"}</td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp maternal_supports_detail(assigns) do
    assigns =
      assigns
      |> assign(
        :malaria_sorted,
        Enum.sort_by(
          assigns.pregnancy.malaria_prophylaxis || [],
          &{&1.dose_number || 0, &1.date_given || ~D[1900-01-01]}
        )
      )
      |> assign(
        :ifas_sorted,
        Enum.sort_by(
          assigns.pregnancy.ifas_supplements || [],
          &{&1.contact_number || 0, &1.date_given || ~D[1900-01-01]}
        )
      )
      |> assign(
        :deworming_sorted,
        Enum.sort_by(
          assigns.pregnancy.deworming_maternal || [],
          &(&1.date_given || ~D[1900-01-01]),
          {:desc, Date}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View preventive services
      </summary>
      <div class="mt-3 grid gap-4 lg:grid-cols-3">
        <div class="rounded-lg border border-slate-200 p-4">
          <div class="flex items-center justify-between gap-2">
            <h5 class="text-sm font-semibold text-slate-900">Malaria Prophylaxis (IPT)</h5>
            <button
              phx-click="open_add_malaria_prophylaxis"
              phx-value-pregnancy-id={@pregnancy.id}
              class="text-xs font-medium text-[#6667ab] hover:underline"
            >
              + Add
            </button>
          </div>
          <ul class="mt-3 space-y-2 text-sm">
            <li
              :for={dose <- @malaria_sorted}
              class="flex items-center justify-between rounded-md bg-slate-50 px-3 py-2"
            >
              <span>Dose {dose.dose_number || "—"}</span>
              <span class="text-slate-500">
                {(dose.date_given && format_date(dose.date_given)) || "—"}
              </span>
            </li>
            <li :if={@malaria_sorted == []} class="text-slate-500">No IPT doses recorded.</li>
          </ul>
        </div>

        <div class="rounded-lg border border-slate-200 p-4">
          <div class="flex items-center justify-between gap-2">
            <h5 class="text-sm font-semibold text-slate-900">Iron & Folate (IFAS)</h5>
            <button
              phx-click="open_add_ifas"
              phx-value-pregnancy-id={@pregnancy.id}
              class="text-xs font-medium text-[#6667ab] hover:underline"
            >
              + Add
            </button>
          </div>
          <ul class="mt-3 space-y-2 text-sm">
            <li :for={issue <- @ifas_sorted} class="rounded-md bg-slate-50 px-3 py-2">
              <div class="flex items-center justify-between">
                <span>
                  Contact {issue.contact_number || "—"} · {issue.tablets_issued || "—"} tabs
                </span>
                <span class="text-slate-500">
                  {(issue.date_given && format_date(issue.date_given)) || "—"}
                </span>
              </div>
              <div class="mt-1 text-xs text-slate-500">
                Gestation: {issue.gestation_weeks || "—"} weeks
              </div>
            </li>
            <li :if={@ifas_sorted == []} class="text-slate-500">No IFAS records.</li>
          </ul>
        </div>

        <div class="rounded-lg border border-slate-200 p-4">
          <div class="flex items-center justify-between gap-2">
            <h5 class="text-sm font-semibold text-slate-900">Maternal Deworming</h5>
            <button
              phx-click="open_add_deworming_maternal"
              phx-value-pregnancy-id={@pregnancy.id}
              class="text-xs font-medium text-[#6667ab] hover:underline"
            >
              + Add
            </button>
          </div>
          <ul class="mt-3 space-y-2 text-sm">
            <li
              :for={dose <- @deworming_sorted}
              class="flex items-center justify-between rounded-md bg-slate-50 px-3 py-2"
            >
              <span>{dose.medication || "Deworming"}</span>
              <span class="text-slate-500">
                {(dose.date_given && format_date(dose.date_given)) || "—"}
              </span>
            </li>
            <li :if={@deworming_sorted == []} class="text-slate-500">
              No maternal deworming records.
            </li>
          </ul>
        </div>
      </div>
    </details>
    """
  end

  defp pnc_mother_visits_detail(assigns) do
    assigns =
      assign(
        assigns,
        :pnc_visits_sorted,
        Enum.sort_by(
          assigns.mother.pnc_mother_visits || [],
          &{&1.visit_number || 0, &1.visit_date || ~D[1900-01-01]}
        )
      )

    ~H"""
    <%= if @pnc_visits_sorted == [] do %>
      <p class="mt-4 text-sm text-slate-500">No mother postnatal visits recorded.</p>
    <% else %>
      <div class="mt-4 overflow-x-auto">
        <table class="min-w-full text-sm">
          <thead>
            <tr class="border-b border-slate-200 text-left">
              <th class="py-2 pr-4 text-slate-500">Visit</th>
              <th class="py-2 pr-4 text-slate-500">Date</th>
              <th class="py-2 pr-4 text-slate-500">BP</th>
              <th class="py-2 pr-4 text-slate-500">Temp</th>
              <th class="py-2 pr-4 text-slate-500">General</th>
              <th class="py-2 pr-4 text-slate-500">Breast</th>
              <th class="py-2 pr-4 text-slate-500">Uterus</th>
              <th class="py-2 pr-4 text-slate-500">FP Method</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={visit <- @pnc_visits_sorted} class="border-b border-slate-100">
              <td class="py-2 pr-4">{visit.visit_number || "—"}</td>
              <td class="py-2 pr-4">{(visit.visit_date && format_date(visit.visit_date)) || "—"}</td>
              <td class="py-2 pr-4">{format_bp(visit.bp_systolic, visit.bp_diastolic)}</td>
              <td class="py-2 pr-4">{visit.temperature || "—"}</td>
              <td class="py-2 pr-4">{visit.general_condition || "—"}</td>
              <td class="py-2 pr-4">{visit.breast_condition || "—"}</td>
              <td class="py-2 pr-4">{visit.uterus_involution || "—"}</td>
              <td class="py-2 pr-4">
                <%= if visit.fp_counseling_done do %>
                  {visit.fp_method || "Counseled"}
                <% else %>
                  —
                <% end %>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    <% end %>
    """
  end

  defp pnc_baby_visits_detail(assigns) do
    assigns =
      assign(
        assigns,
        :pnc_baby_sorted,
        Enum.sort_by(
          assigns.child.pnc_baby_visits || [],
          &(&1.visit_date || ~D[1900-01-01]),
          {:asc, Date}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@pnc_baby_sorted)} baby postnatal visit(s)
      </summary>
      <%= if @pnc_baby_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No baby postnatal visits recorded.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Date</th>
                <th class="py-2 pr-4 text-slate-500">General</th>
                <th class="py-2 pr-4 text-slate-500">Temp</th>
                <th class="py-2 pr-4 text-slate-500">Breaths/min</th>
                <th class="py-2 pr-4 text-slate-500">Exclusive BF</th>
                <th class="py-2 pr-4 text-slate-500">Cord Status</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={visit <- @pnc_baby_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">
                  {(visit.visit_date && format_date(visit.visit_date)) || "—"}
                </td>
                <td class="py-2 pr-4">{visit.general_condition || "—"}</td>
                <td class="py-2 pr-4">{visit.temperature || "—"}</td>
                <td class="py-2 pr-4">{visit.breaths_per_minute || "—"}</td>
                <td class="py-2 pr-4">{yes_no(visit.exclusive_breastfeeding)}</td>
                <td class="py-2 pr-4">{visit.umbilical_cord_status || "—"}</td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp vitamin_a_detail(assigns) do
    assigns =
      assign(
        assigns,
        :vitamin_a_sorted,
        Enum.sort_by(
          assigns.child.vitamin_a_supplements || [],
          &{&1.age_months || 0, &1.date_given || ~D[1900-01-01]}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@vitamin_a_sorted)} vitamin A dose(s)
      </summary>
      <%= if @vitamin_a_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No vitamin A doses recorded.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Date</th>
                <th class="py-2 pr-4 text-slate-500">Age (months)</th>
                <th class="py-2 pr-4 text-slate-500">Dose (IU)</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={dose <- @vitamin_a_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">{(dose.date_given && format_date(dose.date_given)) || "—"}</td>
                <td class="py-2 pr-4">{dose.age_months || "—"}</td>
                <td class="py-2 pr-4">{dose.dose_iu || "—"}</td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp child_deworming_detail(assigns) do
    assigns =
      assign(
        assigns,
        :deworming_sorted,
        Enum.sort_by(
          assigns.child.child_deworming || [],
          &{&1.age_months || 0, &1.date_given || ~D[1900-01-01]}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@deworming_sorted)} child deworming record(s)
      </summary>
      <%= if @deworming_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No child deworming records.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Date</th>
                <th class="py-2 pr-4 text-slate-500">Age (months)</th>
                <th class="py-2 pr-4 text-slate-500">Medication</th>
                <th class="py-2 pr-4 text-slate-500">Dosage (mg)</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={dose <- @deworming_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">{(dose.date_given && format_date(dose.date_given)) || "—"}</td>
                <td class="py-2 pr-4">{dose.age_months || "—"}</td>
                <td class="py-2 pr-4">{dose.medication || "—"}</td>
                <td class="py-2 pr-4">{dose.dosage_mg || "—"}</td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp developmental_milestones_detail(assigns) do
    assigns =
      assign(
        assigns,
        :milestones_sorted,
        Enum.sort_by(
          assigns.child.developmental_milestones || [],
          &{&1.assessment_date || ~D[1900-01-01], &1.milestone_name || ""},
          :desc
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@milestones_sorted)} developmental milestone record(s)
      </summary>
      <%= if @milestones_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No developmental milestones recorded.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Date</th>
                <th class="py-2 pr-4 text-slate-500">Milestone</th>
                <th class="py-2 pr-4 text-slate-500">Expected Age</th>
                <th class="py-2 pr-4 text-slate-500">Achieved</th>
                <th class="py-2 pr-4 text-slate-500">Status</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={milestone <- @milestones_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">
                  {(milestone.assessment_date && format_date(milestone.assessment_date)) || "—"}
                </td>
                <td class="py-2 pr-4">{milestone.milestone_name || "—"}</td>
                <td class="py-2 pr-4">{milestone.expected_age_range || "—"}</td>
                <td class="py-2 pr-4">
                  <%= if milestone.age_achieved_months do %>
                    {milestone.age_achieved_months} months
                  <% else %>
                    —
                  <% end %>
                </td>
                <td class="py-2 pr-4">{milestone.status || "—"}</td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp eye_assessments_detail(assigns) do
    assigns =
      assign(
        assigns,
        :eye_assessments_sorted,
        Enum.sort_by(
          assigns.child.eye_assessments || [],
          &(&1.assessment_date || ~D[1900-01-01]),
          {:desc, Date}
        )
      )

    ~H"""
    <details class="mt-2">
      <summary class="cursor-pointer text-sm font-medium text-[#6667ab] hover:text-[#5556a0]">
        View {length(@eye_assessments_sorted)} eye assessment(s)
      </summary>
      <%= if @eye_assessments_sorted == [] do %>
        <p class="mt-2 ml-2 text-sm text-slate-500">No eye assessments recorded.</p>
      <% else %>
        <div class="mt-2 overflow-x-auto">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="border-b border-slate-200 text-left">
                <th class="py-2 pr-4 text-slate-500">Date</th>
                <th class="py-2 pr-4 text-slate-500">Age</th>
                <th class="py-2 pr-4 text-slate-500">TEO Given</th>
                <th class="py-2 pr-4 text-slate-500">Pupil</th>
                <th class="py-2 pr-4 text-slate-500">Follows Objects</th>
                <th class="py-2 pr-4 text-slate-500">Squint</th>
                <th class="py-2 pr-4 text-slate-500">Referred</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={assessment <- @eye_assessments_sorted} class="border-b border-slate-100">
                <td class="py-2 pr-4">
                  {(assessment.assessment_date && format_date(assessment.assessment_date)) || "—"}
                </td>
                <td class="py-2 pr-4">{assessment.age_at_assessment || "—"}</td>
                <td class="py-2 pr-4">{yes_no(assessment.teo_given)}</td>
                <td class="py-2 pr-4">{assessment.pupil_color || "—"}</td>
                <td class="py-2 pr-4">{yes_no(assessment.follows_objects)}</td>
                <td class="py-2 pr-4">{yes_no(assessment.has_squint)}</td>
                <td class="py-2 pr-4">{yes_no(assessment.referred)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </details>
    """
  end

  defp special_care_reference_panel(assigns) do
    reasons = [
      "Birth weight below 2.5 kg",
      "Birth less than 2 years after last birth",
      "Fifth child or more",
      "Teenage mother",
      "Multiple birth",
      "HIV exposed infant",
      "Child with disability or developmental delays",
      "Orphan or abuse / neglect concerns"
    ]

    assigns = assign(assigns, :special_care_reasons, reasons)

    ~H"""
    <div class="rounded-xl border border-amber-200 bg-amber-50/60 p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-amber-900">Reasons For Special Care</h3>
      <p class="mt-1 text-sm text-amber-800">
        Reference checklist adapted from the updated handbook screen to guide counselling and referral.
      </p>
      <div class="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        <div
          :for={reason <- @special_care_reasons}
          class="rounded-lg border border-amber-100 bg-white px-4 py-3 text-sm text-slate-700"
        >
          {reason}
        </div>
      </div>
    </div>
    """
  end

  defp eye_red_flags_panel(assigns) do
    checks = [
      {"Pupil exam", "White pupil should be referred urgently."},
      {"Following objects", "No response suggests reduced vision or delayed tracking."},
      {"Squint", "Persistent squint requires review and referral."},
      {"Other warning signs", "Any unusual discharge, swelling, trauma, or caregiver concern."}
    ]

    assigns = assign(assigns, :eye_checks, checks)

    ~H"""
    <div class="rounded-xl border border-indigo-200 bg-indigo-50/50 p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-indigo-900">Early Eye Problem Identification</h3>
      <p class="mt-1 text-sm text-indigo-800">
        Important child eye checks surfaced from the updated HTML for first-contact review.
      </p>
      <div class="mt-4 grid gap-3 md:grid-cols-2">
        <div
          :for={{title, note} <- @eye_checks}
          class="rounded-lg border border-indigo-100 bg-white p-4"
        >
          <p class="text-sm font-semibold text-slate-900">{title}</p>
          <p class="mt-1 text-sm text-slate-500">{note}</p>
        </div>
      </div>
    </div>
    """
  end

  defp hei_follow_up_panel(assigns) do
    schedule = [
      {"ARV prophylaxis", "NVP syrup for 12 weeks, AZT syrup for 6 weeks, CTX from 6 weeks"},
      {"6 weeks", "1st DNA PCR and prophylaxis review"},
      {"6 months", "2nd DNA PCR"},
      {"12 months", "3rd DNA PCR"},
      {"18 months", "Final antibody test"}
    ]

    assigns = assign(assigns, :hei_schedule, schedule)

    ~H"""
    <div class="rounded-xl border border-sky-200 bg-sky-50/60 p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-sky-900">HIV Exposed Infant Follow-Up</h3>
      <p class="mt-1 text-sm text-sky-800">
        Quick follow-up guide from the updated MCH content for prophylaxis and testing timelines.
      </p>
      <div class="mt-4 overflow-x-auto">
        <table class="min-w-full text-sm">
          <thead>
            <tr class="border-b border-sky-200 text-left">
              <th class="py-2 pr-4 text-sky-800">Stage</th>
              <th class="py-2 pr-4 text-sky-800">Expected action</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{stage, action} <- @hei_schedule} class="border-b border-sky-100">
              <td class="py-2 pr-4 font-medium text-slate-900">{stage}</td>
              <td class="py-2 pr-4 text-slate-600">{action}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp food_groups_panel(assigns) do
    groups = [
      {"Grains & starches", "Maize, wheat, sorghum, millet, cassava, potatoes"},
      {"Vegetables", "Kales, spinach, pumpkin leaves, amaranth"},
      {"Proteins", "Meat, fish, eggs, beans, lentils, nuts"},
      {"Dairy", "Milk, yoghurt, cheese, mala"}
    ]

    assigns = assign(assigns, :food_groups, groups)

    ~H"""
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-slate-900">Food Groups For Healthy Eating</h3>
      <p class="mt-1 text-sm text-slate-500">
        Feeding support section added from the updated HTML so counselling is easier during review.
      </p>
      <div class="mt-4 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <div :for={{name, examples} <- @food_groups} class="rounded-lg border border-slate-200 p-4">
          <p class="text-sm font-semibold text-slate-900">{name}</p>
          <p class="mt-2 text-sm text-slate-500">{examples}</p>
        </div>
      </div>
    </div>
    """
  end

  defp danger_signs_panel(assigns) do
    danger_signs = [
      {"Severe abdominal pain", "Persistent abdominal pain during pregnancy or after delivery"},
      {"Vaginal bleeding", "Any bleeding before or after childbirth"},
      {"Severe headache", "Persistent headache or signs of hypertension"},
      {"Blurred vision", "Visual changes or flashes"},
      {"Swelling of face or hands", "Sudden swelling can be a warning sign"},
      {"Breathlessness", "Difficulty breathing or chest discomfort"},
      {"Reduced fetal movement", "Baby moving less than usual"},
      {"Water breaking early", "Premature rupture of membranes"}
    ]

    assigns = assign(assigns, :danger_signs, danger_signs)

    ~H"""
    <div class="rounded-xl border border-rose-200 bg-rose-50/50 p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-rose-900">Danger Signs During Pregnancy</h3>
      <p class="mt-1 text-sm text-rose-700">
        Quick reference from the handbook. If any of these appear, refer or escalate immediately.
      </p>
      <div class="mt-4 grid gap-3 md:grid-cols-2">
        <div
          :for={{title, note} <- @danger_signs}
          class="rounded-lg border border-rose-100 bg-white p-4"
        >
          <p class="text-sm font-semibold text-slate-900">{title}</p>
          <p class="mt-1 text-sm text-slate-500">{note}</p>
        </div>
      </div>
    </div>
    """
  end

  defp kepi_schedule_panel(assigns) do
    schedule = [
      {"At birth", "BCG, OPV 0"},
      {"6 weeks", "OPV 1, Penta 1, PCV 10 1, Rota 1"},
      {"10 weeks", "OPV 2, Penta 2, PCV 10 2, Rota 2"},
      {"14 weeks", "OPV 3, Penta 3, PCV 10 3, IPV"},
      {"9 months", "Measles-Rubella 1, Yellow Fever"},
      {"18 months", "Measles-Rubella 2"},
      {"10 years", "HPV 1"},
      {"6 months after HPV 1", "HPV 2"}
    ]

    assigns = assign(assigns, :schedule, schedule)

    ~H"""
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-slate-900">Immunization Schedule Reference</h3>
      <p class="mt-1 text-sm text-slate-500">
        KEPI-aligned quick guide to compare recorded vaccines with the expected schedule.
      </p>
      <div class="mt-4 overflow-x-auto">
        <table class="min-w-full text-sm">
          <thead>
            <tr class="border-b border-slate-200 text-left">
              <th class="py-2 pr-4 text-slate-500">Age</th>
              <th class="py-2 pr-4 text-slate-500">Expected vaccines</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{age, vaccines} <- @schedule} class="border-b border-slate-100">
              <td class="py-2 pr-4 font-medium text-slate-900">{age}</td>
              <td class="py-2 pr-4 text-slate-600">{vaccines}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp milestone_reference_panel(assigns) do
    milestones = [
      {"Social smile", "4-6 weeks"},
      {"Head holding / control", "1-3 months"},
      {"Turns towards sound", "2-3 months"},
      {"Grasps toy", "2-3 months"},
      {"Sitting", "5-9 months"},
      {"Standing", "7-13 months"},
      {"Walking", "12-18 months"},
      {"Talking (words)", "19-24 months"}
    ]

    assigns = assign(assigns, :milestones, milestones)

    ~H"""
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-slate-900">Developmental Milestones Reference</h3>
      <p class="mt-1 text-sm text-slate-500">
        The updated HTML includes milestone checkpoints with normal limits, so this table mirrors that quick screening guide.
      </p>
      <div class="mt-4 overflow-x-auto">
        <table class="min-w-full text-sm">
          <thead>
            <tr class="border-b border-slate-200 text-left">
              <th class="py-2 pr-4 text-slate-500">Milestone</th>
              <th class="py-2 pr-4 text-slate-500">Normal limit</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{milestone, age_range} <- @milestones} class="border-b border-slate-100">
              <td class="py-2 pr-4 font-medium text-slate-900">{milestone}</td>
              <td class="py-2 pr-4 text-slate-600">{age_range}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-4 text-sm text-amber-700">
        Refer for further assessment if a milestone is delayed beyond the normal age limit.
      </p>
    </div>
    """
  end

  defp feeding_guide_panel(assigns) do
    guide = [
      {"0-6 months",
       "Breastfeed within 1 hour after birth, give colostrum, feed at least 8 times in 24 hours, and give no other foods or fluids."},
      {"6-9 months",
       "Continue breastfeeding, give thick porridge or mashed foods, include animal-source foods, and aim for 2-3 meals plus 1-2 snacks."},
      {"9-12 months",
       "Offer family foods, give about half a cup each meal, provide 3-4 meals plus 1-2 snacks, and support the child during feeding."},
      {"12-24 months",
       "Provide varied family foods, continue breastfeeding as often as the child wants, and target 3-4 meals plus 1-2 snacks."},
      {"2-5 years",
       "Give at least one full cup at meals, keep variety high, and use responsive feeding during meals."}
    ]

    assigns = assign(assigns, :guide, guide)

    ~H"""
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <h3 class="text-lg font-semibold text-slate-900">Feeding Guide</h3>
      <p class="mt-1 text-sm text-slate-500">
        Expanded counselling messages from the updated HTML, kept in the app’s standard reference-card style.
      </p>
      <div class="mt-4 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <div :for={{age, advice} <- @guide} class="rounded-lg border border-slate-200 p-4">
          <p class="text-sm font-semibold text-slate-900">{age}</p>
          <p class="mt-2 text-sm text-slate-500">{advice}</p>
        </div>
      </div>
      <div class="mt-4 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">
        Key message: add one spoonful of extra oil or fat to food, include milk and fruits daily, and encourage eye contact and talking during meals.
      </div>
    </div>
    """
  end

  defp mch_maternal(assigns) do
    ~H"""
    <div class="space-y-6">
      <.mother_profile_panel mch_summary={@mch_summary} />

      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between gap-3">
          <div>
            <h3 class="text-lg font-semibold text-slate-900">
              Preventive Services & Postnatal Follow-Up
            </h3>
            <p class="mt-1 text-sm text-slate-500">
              Tetanus vaccination, malaria prevention, IFAS, deworming, and postnatal maternal review.
            </p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button
              phx-click="open_add_td_vaccination"
              class="rounded-lg border border-[#6667ab] px-3 py-1.5 text-sm font-medium text-[#6667ab] hover:bg-[#e8e8ff] transition-colors"
            >
              Add TD Dose
            </button>
            <button
              phx-click="open_add_pnc_mother_visit"
              class="rounded-lg bg-[#6667ab] px-3 py-1.5 text-sm font-medium text-white hover:bg-[#5556a0] transition-colors"
            >
              Add PNC Visit
            </button>
          </div>
        </div>

        <div class="mt-6 grid gap-4 lg:grid-cols-2">
          <div class="rounded-lg border border-slate-200 p-4">
            <h4 class="text-sm font-semibold text-slate-900">Tetanus Diphtheria Schedule</h4>
            <ul class="mt-3 space-y-2 text-sm">
              <li
                :for={dose_number <- 1..5}
                class="flex items-center justify-between rounded-md bg-slate-50 px-3 py-2"
              >
                <span>TD {dose_number}</span>
                <span class="text-slate-500">
                  {find_td_date(@mch_summary.mother.td_vaccinations || [], dose_number)}
                </span>
              </li>
            </ul>
          </div>

          <div class="rounded-lg border border-slate-200 p-4">
            <h4 class="text-sm font-semibold text-slate-900">Mother Postnatal Visits</h4>
            <p class="mt-1 text-sm text-slate-500">
              Tracks blood pressure, temperature, uterus involution, breastfeeding and family planning counselling.
            </p>
            <.pnc_mother_visits_detail mother={@mch_summary.mother} />
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-semibold text-slate-900">Pregnancies</h3>
            <p class="mt-1 text-sm text-slate-500">
              Handbook-aligned ANC, antenatal profile, physical examination, delivery, and pregnancy support records.
            </p>
          </div>
          <button
            phx-click="open_add_pregnancy"
            class="rounded-lg bg-[#6667ab] px-3 py-1.5 text-sm font-medium text-white hover:bg-[#5556a0] transition-colors"
          >
            Add Pregnancy
          </button>
        </div>
        <%= if Enum.empty?(@mch_summary.pregnancies) do %>
          <p class="mt-4 text-sm text-slate-500">No pregnancies recorded.</p>
        <% else %>
          <ul class="mt-4 divide-y divide-slate-100">
            <li :for={pregnancy <- @mch_summary.pregnancies} class="py-4">
              <div class="flex items-center justify-between flex-wrap gap-2">
                <div>
                  <span class="font-medium text-slate-900">
                    Pregnancy — EDD: {(pregnancy.edd && format_date(pregnancy.edd)) || "—"}
                  </span>
                  <span class={[
                    "ml-2 rounded-full px-2 py-0.5 text-xs font-medium",
                    pregnancy.status == "active" && "bg-emerald-100 text-emerald-700",
                    pregnancy.status != "active" && "bg-slate-100 text-slate-600"
                  ]}>
                    {pregnancy.status}
                  </span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="text-sm text-slate-500">
                    {length(pregnancy.anc_visits || [])} ANC visits
                  </span>
                  <button
                    phx-click="open_add_antenatal_profile"
                    phx-value-pregnancy-id={pregnancy.id}
                    class="rounded-lg border border-slate-300 px-2 py-1 text-xs font-medium text-slate-600 hover:bg-slate-100 transition-colors"
                  >
                    Antenatal Profile
                  </button>
                  <button
                    phx-click="open_add_physical_examination"
                    phx-value-pregnancy-id={pregnancy.id}
                    class="rounded-lg border border-slate-300 px-2 py-1 text-xs font-medium text-slate-600 hover:bg-slate-100 transition-colors"
                  >
                    Physical Exam
                  </button>
                  <button
                    phx-click="open_add_anc_visit"
                    phx-value-pregnancy-id={pregnancy.id}
                    class="rounded-lg border border-[#6667ab] px-2 py-1 text-xs font-medium text-[#6667ab] hover:bg-[#e8e8ff] transition-colors"
                  >
                    Add ANC Visit
                  </button>
                  <%= if pregnancy.status == "active" do %>
                    <button
                      phx-click="open_record_delivery"
                      phx-value-pregnancy-id={pregnancy.id}
                      class="rounded-lg bg-[#6667ab] px-2 py-1 text-xs font-medium text-white hover:bg-[#5556a0] transition-colors"
                    >
                      Record Delivery
                    </button>
                  <% end %>
                </div>
              </div>
              <div class="mt-3 rounded-lg bg-slate-50 p-4">
                <div class="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
                  <div>
                    <p class="text-xs uppercase tracking-wide text-slate-500">ANC Number</p>
                    <p class="mt-1 text-sm font-medium text-slate-900">
                      {pregnancy.anc_number || @mch_summary.mother.anc_number || "—"}
                    </p>
                  </div>
                  <div>
                    <p class="text-xs uppercase tracking-wide text-slate-500">LMP</p>
                    <p class="mt-1 text-sm font-medium text-slate-900">
                      {(pregnancy.lmp && format_date(pregnancy.lmp)) || "—"}
                    </p>
                  </div>
                  <div>
                    <p class="text-xs uppercase tracking-wide text-slate-500">EDD</p>
                    <p class="mt-1 text-sm font-medium text-slate-900">
                      {(pregnancy.edd && format_date(pregnancy.edd)) || "—"}
                    </p>
                  </div>
                  <div>
                    <p class="text-xs uppercase tracking-wide text-slate-500">Gestation by Date</p>
                    <p class="mt-1 text-sm font-medium text-slate-900">
                      {gestation_weeks_label(pregnancy.lmp)}
                    </p>
                  </div>
                </div>
              </div>
              <.anc_visits_detail pregnancy={pregnancy} />
              <.antenatal_profiles_detail pregnancy={pregnancy} />
              <.physical_examinations_detail pregnancy={pregnancy} />
              <.maternal_supports_detail pregnancy={pregnancy} />
              <.journey_deliveries pregnancy={pregnancy} />
            </li>
          </ul>
        <% end %>
      </div>

      <.danger_signs_panel />
    </div>
    """
  end

  defp mch_children(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-semibold text-slate-900">Children (0–5 years)</h3>
            <p class="mt-1 text-sm text-slate-500">
              Child profile, growth monitoring, immunizations, postnatal care, vitamin A, and deworming.
            </p>
          </div>
          <button
            phx-click="open_add_child"
            class="rounded-lg bg-[#6667ab] px-3 py-1.5 text-sm font-medium text-white hover:bg-[#5556a0] transition-colors"
          >
            Add Child
          </button>
        </div>
        <%= if Enum.empty?(@mch_summary.children) do %>
          <p class="mt-4 text-sm text-slate-500">No children recorded.</p>
        <% else %>
          <ul class="mt-4 divide-y divide-slate-100">
            <li :for={child <- @mch_summary.children} class="py-4">
              <div class="flex items-center justify-between flex-wrap gap-3">
                <div>
                  <p class="font-medium text-slate-900">{child.name || "Unnamed"}</p>
                  <p class="text-sm text-slate-500">
                    DOB: {(child.date_of_birth && format_date(child.date_of_birth)) || "—"}
                    <%= if child.sex do %>
                      · {child.sex}
                    <% end %>
                    <%= if child.birth_weight_grams do %>
                      · {child.birth_weight_grams}g
                    <% end %>
                  </p>
                </div>
                <div class="flex flex-wrap items-center gap-2">
                  <button
                    phx-click="open_edit_child"
                    phx-value-child-id={child.id}
                    class="rounded-lg border border-slate-300 px-2 py-1 text-xs font-medium text-slate-600 hover:bg-slate-100 transition-colors"
                  >
                    Edit Child
                  </button>
                  <button
                    phx-click="open_add_growth"
                    phx-value-child-id={child.id}
                    class="rounded-lg border border-[#6667ab] px-2 py-1 text-xs font-medium text-[#6667ab] hover:bg-[#e8e8ff] transition-colors"
                  >
                    Add Growth
                  </button>
                  <button
                    phx-click="open_add_immunization"
                    phx-value-child-id={child.id}
                    class="rounded-lg bg-[#6667ab] px-2 py-1 text-xs font-medium text-white hover:bg-[#5556a0] transition-colors"
                  >
                    Add Immunization
                  </button>
                  <button
                    phx-click="open_add_developmental_milestone"
                    phx-value-child-id={child.id}
                    class="rounded-lg border border-[#6667ab] px-2 py-1 text-xs font-medium text-[#6667ab] hover:bg-[#e8e8ff] transition-colors"
                  >
                    Add Milestone
                  </button>
                  <button
                    phx-click="open_add_eye_assessment"
                    phx-value-child-id={child.id}
                    class="rounded-lg border border-slate-300 px-2 py-1 text-xs font-medium text-slate-600 hover:bg-slate-100 transition-colors"
                  >
                    Add Eye Check
                  </button>
                  <button
                    phx-click="open_add_pnc_baby_visit"
                    phx-value-child-id={child.id}
                    class="rounded-lg border border-slate-300 px-2 py-1 text-xs font-medium text-slate-600 hover:bg-slate-100 transition-colors"
                  >
                    Add PNC
                  </button>
                  <button
                    phx-click="open_add_vitamin_a"
                    phx-value-child-id={child.id}
                    class="rounded-lg border border-slate-300 px-2 py-1 text-xs font-medium text-slate-600 hover:bg-slate-100 transition-colors"
                  >
                    Add Vitamin A
                  </button>
                  <button
                    phx-click="open_add_child_deworming"
                    phx-value-child-id={child.id}
                    class="rounded-lg border border-slate-300 px-2 py-1 text-xs font-medium text-slate-600 hover:bg-slate-100 transition-colors"
                  >
                    Add Deworming
                  </button>
                </div>
              </div>

              <div class="mt-3 rounded-lg bg-slate-50 p-4">
                <div class="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
                  <div>
                    <p class="text-xs uppercase tracking-wide text-slate-500">Birth Order</p>
                    <p class="mt-1 text-sm font-medium text-slate-900">{child.birth_order || "—"}</p>
                  </div>
                  <div>
                    <p class="text-xs uppercase tracking-wide text-slate-500">Gestation at Birth</p>
                    <p class="mt-1 text-sm font-medium text-slate-900">
                      {(child.gestation_at_birth_weeks && "#{child.gestation_at_birth_weeks} weeks") ||
                        "—"}
                    </p>
                  </div>
                  <div>
                    <p class="text-xs uppercase tracking-wide text-slate-500">
                      Immunization Register
                    </p>
                    <p class="mt-1 text-sm font-medium text-slate-900">
                      {child.immunization_register_number || "—"}
                    </p>
                  </div>
                  <div>
                    <p class="text-xs uppercase tracking-wide text-slate-500">Guardian</p>
                    <p class="mt-1 text-sm font-medium text-slate-900">
                      {join_present([child.guardian_name, child.guardian_phone], " · ")}
                    </p>
                  </div>
                </div>
              </div>

              <.child_growth_detail child={child} />
              <.child_immunizations_detail child={child} />
              <.developmental_milestones_detail child={child} />
              <.eye_assessments_detail child={child} />
              <.pnc_baby_visits_detail child={child} />
              <.vitamin_a_detail child={child} />
              <.child_deworming_detail child={child} />
            </li>
          </ul>
        <% end %>
      </div>

      <.special_care_reference_panel />
      <.kepi_schedule_panel />
      <.hei_follow_up_panel />
      <.milestone_reference_panel />
      <.eye_red_flags_panel />
      <.feeding_guide_panel />
      <.food_groups_panel />
    </div>
    """
  end

  defp edit_mother_modal(assigns) do
    ~H"""
    <.modal id="edit-mother-modal" show on_cancel={JS.push("close_edit_mother")}>
      <div id="edit-mother-content">
        <h2 id="edit-mother-title" class="text-lg font-semibold text-slate-900">
          Edit Mother Profile
        </h2>
        <.simple_form
          for={@form}
          phx-change="validate_mother"
          phx-submit="save_mother"
          id="mother-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:gravida]} type="number" label="Gravida" />
            <.input field={@form[:parity]} type="number" label="Parity" />
            <.input field={@form[:height_cm]} type="number" label="Height (cm)" step="0.1" />
            <.input field={@form[:anc_number]} type="text" label="ANC Number" />
            <.input field={@form[:pnc_number]} type="text" label="PNC Number" />
            <.input field={@form[:lmp]} type="date" label="Last Menstrual Period" />
            <.input field={@form[:edd]} type="date" label="Expected Date of Delivery" />
            <.input field={@form[:marital_status]} type="text" label="Marital Status" />
            <.input field={@form[:education_level]} type="text" label="Education Level" />
            <.input field={@form[:county]} type="text" label="County" />
            <.input field={@form[:subcounty]} type="text" label="Subcounty" />
            <.input field={@form[:ward]} type="text" label="Ward" />
            <.input field={@form[:town_village]} type="text" label="Town / Village" />
            <.input field={@form[:physical_address]} type="text" label="Physical Address" />
            <.input field={@form[:next_of_kin_name]} type="text" label="Next of Kin Name" />
            <.input
              field={@form[:next_of_kin_relationship]}
              type="text"
              label="Next of Kin Relationship"
            />
            <.input field={@form[:next_of_kin_phone]} type="text" label="Next of Kin Phone" />
            <.input field={@form[:health_facility_name]} type="text" label="Health Facility" />
            <.input field={@form[:kmhfl_code]} type="text" label="KMHFL Code" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_edit_mother"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_pregnancy_modal(assigns) do
    ~H"""
    <.modal id="add-pregnancy-modal" show on_cancel={JS.push("close_add_pregnancy")}>
      <div id="add-pregnancy-content">
        <h2 id="add-pregnancy-title" class="text-lg font-semibold text-slate-900">Add Pregnancy</h2>
        <.simple_form
          for={@form}
          phx-change="validate_pregnancy"
          phx-submit="save_pregnancy"
          id="pregnancy-form"
        >
          <.input field={@form[:lmp]} type="date" label="Last Menstrual Period (LMP)" />
          <.input field={@form[:edd]} type="date" label="Expected Date of Delivery (EDD)" />
          <.input
            field={@form[:status]}
            type="select"
            label="Status"
            options={[Active: "active", Completed: "completed", Miscarriage: "miscarriage"]}
          />
          <.input field={@form[:anc_number]} type="text" label="ANC Number" />
          <:actions>
            <button
              type="button"
              phx-click="close_add_pregnancy"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Add Pregnancy</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_child_modal(assigns) do
    ~H"""
    <.modal id="add-child-modal" show on_cancel={JS.push("close_add_child")}>
      <div id="add-child-content">
        <h2 id="add-child-title" class="text-lg font-semibold text-slate-900">Add Child</h2>
        <.simple_form for={@form} phx-change="validate_child" phx-submit="save_child" id="child-form">
          <.input field={@form[:name]} type="text" label="Name" />
          <.input
            field={@form[:sex]}
            type="select"
            label="Sex"
            options={[Male: "Male", Female: "Female"]}
            prompt="Select"
          />
          <.input field={@form[:date_of_birth]} type="date" label="Date of Birth" />
          <.input
            field={@form[:gestation_at_birth_weeks]}
            type="number"
            label="Gestation at Birth (weeks)"
          />
          <.input field={@form[:birth_weight_grams]} type="number" label="Birth Weight (g)" />
          <.input field={@form[:birth_length_cm]} type="number" label="Birth Length (cm)" step="0.1" />
          <.input
            field={@form[:head_circumference_cm]}
            type="number"
            label="Head Circumference (cm)"
            step="0.1"
          />
          <.input field={@form[:place_of_birth]} type="text" label="Place of Birth" />
          <.input field={@form[:birth_order]} type="number" label="Birth Order" />
          <.input field={@form[:guardian_name]} type="text" label="Guardian Name" />
          <.input field={@form[:guardian_phone]} type="text" label="Guardian Phone" />
          <.input
            field={@form[:immunization_register_number]}
            type="text"
            label="Immunization Register #"
          />
          <.input field={@form[:cwc_number]} type="text" label="CWC Number" />
          <:actions>
            <button
              type="button"
              phx-click="close_add_child"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Add Child</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp edit_child_modal(assigns) do
    ~H"""
    <.modal id="edit-child-modal" show on_cancel={JS.push("close_edit_child")}>
      <div id="edit-child-content">
        <h2 class="text-lg font-semibold text-slate-900">Edit Child</h2>
        <.simple_form
          for={@form}
          phx-change="validate_edit_child"
          phx-submit="save_edit_child"
          id="edit-child-form"
        >
          <.input field={@form[:name]} type="text" label="Name" />
          <.input
            field={@form[:sex]}
            type="select"
            label="Sex"
            options={[Male: "Male", Female: "Female"]}
            prompt="Select"
          />
          <.input field={@form[:date_of_birth]} type="date" label="Date of Birth" />
          <.input field={@form[:birth_weight_grams]} type="number" label="Birth Weight (g)" />
          <.input field={@form[:birth_length_cm]} type="number" label="Birth Length (cm)" step="0.1" />
          <.input
            field={@form[:head_circumference_cm]}
            type="number"
            label="Head Circumference (cm)"
            step="0.1"
          />
          <.input
            field={@form[:gestation_at_birth_weeks]}
            type="number"
            label="Gestation at Birth (weeks)"
          />
          <.input field={@form[:place_of_birth]} type="text" label="Place of Birth" />
          <.input field={@form[:birth_order]} type="number" label="Birth Order" />
          <.input field={@form[:guardian_name]} type="text" label="Guardian Name" />
          <.input field={@form[:guardian_phone]} type="text" label="Guardian Phone" />
          <.input
            field={@form[:immunization_register_number]}
            type="text"
            label="Immunization Register #"
          />
          <.input field={@form[:cwc_number]} type="text" label="CWC Number" />
          <.input field={@form[:health_facility_name]} type="text" label="Health Facility" />
          <.input field={@form[:kmhfl_code]} type="text" label="KMHFL Code" />
          <:actions>
            <button
              type="button"
              phx-click="close_edit_child"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp edit_anc_visit_modal(assigns) do
    ~H"""
    <.modal id="edit-anc-visit-modal" show on_cancel={JS.push("close_edit_anc_visit")}>
      <div id="edit-anc-visit-content">
        <h2 class="text-lg font-semibold text-slate-900">Edit ANC Visit</h2>
        <.simple_form
          for={@form}
          phx-change="validate_edit_anc_visit"
          phx-submit="save_edit_anc_visit"
          id="edit-anc-visit-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:contact_number]} type="number" label="Contact #" />
            <.input field={@form[:visit_date]} type="date" label="Visit Date" />
            <.input field={@form[:weight_kg]} type="number" label="Weight (kg)" step="0.01" />
            <.input field={@form[:gestation_weeks]} type="number" label="Gestation (weeks)" />
            <.input field={@form[:bp_systolic]} type="number" label="BP Systolic" />
            <.input field={@form[:bp_diastolic]} type="number" label="BP Diastolic" />
            <.input field={@form[:haemoglobin]} type="number" label="Haemoglobin (g/dL)" step="0.1" />
            <.input field={@form[:muac_cm]} type="number" label="MUAC (cm)" step="0.1" />
            <.input field={@form[:urine_test]} type="text" label="Urine Test" />
            <.input field={@form[:pallor]} type="checkbox" label="Pallor" />
            <.input field={@form[:fundal_height]} type="number" label="Fundal Height (cm)" step="0.1" />
            <.input field={@form[:presentation]} type="text" label="Presentation" />
            <.input field={@form[:lie]} type="text" label="Lie" />
            <.input field={@form[:foetal_heart_rate]} type="number" label="FHR" />
            <.input field={@form[:foetal_movement]} type="text" label="Foetal Movement" />
            <.input field={@form[:next_visit_date]} type="date" label="Next Visit Date" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_edit_anc_visit"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp edit_delivery_modal(assigns) do
    ~H"""
    <.modal id="edit-delivery-modal" show on_cancel={JS.push("close_edit_delivery")}>
      <div id="edit-delivery-content">
        <h2 class="text-lg font-semibold text-slate-900">Edit Delivery</h2>
        <.simple_form
          for={@form}
          phx-change="validate_edit_delivery"
          phx-submit="save_edit_delivery"
          id="edit-delivery-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:delivery_date]} type="date" label="Delivery Date" />
            <.input field={@form[:delivery_time]} type="time" label="Delivery Time" />
            <.input
              field={@form[:duration_of_pregnancy_weeks]}
              type="number"
              label="Gestation (weeks)"
            />
            <.input
              field={@form[:mode_of_delivery]}
              type="select"
              label="Mode"
              options={[Normal: "Normal", Cesarean: "Cesarean", Assisted: "Assisted"]}
              prompt="Select"
            />
            <.input field={@form[:birth_weight_grams]} type="number" label="Birth Weight (g)" />
            <.input
              field={@form[:birth_length_cm]}
              type="number"
              label="Birth Length (cm)"
              step="0.1"
            />
            <.input
              field={@form[:head_circumference_cm]}
              type="number"
              label="Head Circumference (cm)"
              step="0.1"
            />
            <.input field={@form[:place_of_childbirth]} type="text" label="Place of Birth" />
            <.input field={@form[:conducted_by]} type="text" label="Conducted By" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_edit_delivery"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp edit_growth_modal(assigns) do
    ~H"""
    <.modal id="edit-growth-modal" show on_cancel={JS.push("close_edit_growth")}>
      <div id="edit-growth-content">
        <h2 class="text-lg font-semibold text-slate-900">Edit Growth Measurement</h2>
        <.simple_form
          for={@form}
          phx-change="validate_edit_growth"
          phx-submit="save_edit_growth"
          id="edit-growth-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:measurement_date]} type="date" label="Date" />
            <.input field={@form[:age_months]} type="number" label="Age (months)" />
            <.input field={@form[:weight_kg]} type="number" label="Weight (kg)" step="0.01" />
            <.input
              field={@form[:length_height_cm]}
              type="number"
              label="Length/Height (cm)"
              step="0.1"
            />
            <.input
              field={@form[:head_circumference_cm]}
              type="number"
              label="Head Circumference (cm)"
              step="0.1"
            />
            <.input field={@form[:muac_cm]} type="number" label="MUAC (cm)" step="0.1" />
            <.input
              field={@form[:nutritional_status]}
              type="select"
              label="Status"
              options={[
                Normal: "Normal",
                Underweight: "Underweight",
                Stunted: "Stunted",
                Wasted: "Wasted"
              ]}
              prompt="Select"
            />
            <.input field={@form[:next_visit_date]} type="date" label="Next Visit" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_edit_growth"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp edit_immunization_modal(assigns) do
    ~H"""
    <.modal id="edit-immunization-modal" show on_cancel={JS.push("close_edit_immunization")}>
      <div id="edit-immunization-content">
        <h2 class="text-lg font-semibold text-slate-900">Edit Immunization</h2>
        <.simple_form
          for={@form}
          phx-change="validate_edit_immunization"
          phx-submit="save_edit_immunization"
          id="edit-immunization-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:vaccine_name]} type="text" label="Vaccine" />
            <.input field={@form[:dose_number]} type="number" label="Dose #" />
            <.input field={@form[:scheduled_age]} type="text" label="Scheduled Age" />
            <.input field={@form[:date_given]} type="date" label="Date Given" />
            <.input field={@form[:batch_number]} type="text" label="Batch #" />
            <.input field={@form[:next_visit_date]} type="date" label="Next Visit" />
            <.input field={@form[:adverse_event]} type="checkbox" label="AEFI reported" />
            <.input field={@form[:adverse_event_description]} type="text" label="AEFI Description" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_edit_immunization"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_anc_visit_modal(assigns) do
    ~H"""
    <.modal id="add-anc-visit-modal" show on_cancel={JS.push("close_add_anc_visit")}>
      <div id="add-anc-visit-content">
        <h2 class="text-lg font-semibold text-slate-900">Add ANC Visit</h2>
        <.simple_form
          for={@form}
          phx-change="validate_anc_visit"
          phx-submit="save_anc_visit"
          id="anc-visit-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:contact_number]} type="number" label="Contact #" />
            <.input field={@form[:visit_date]} type="date" label="Visit Date" />
            <.input field={@form[:weight_kg]} type="number" label="Weight (kg)" step="0.01" />
            <.input field={@form[:gestation_weeks]} type="number" label="Gestation (weeks)" />
            <.input field={@form[:bp_systolic]} type="number" label="BP Systolic" />
            <.input field={@form[:bp_diastolic]} type="number" label="BP Diastolic" />
            <.input field={@form[:haemoglobin]} type="number" label="Haemoglobin (g/dL)" step="0.1" />
            <.input field={@form[:muac_cm]} type="number" label="MUAC (cm)" step="0.1" />
            <.input field={@form[:urine_test]} type="text" label="Urine Test" />
            <.input field={@form[:pallor]} type="checkbox" label="Pallor" />
            <.input field={@form[:fundal_height]} type="number" label="Fundal Height (cm)" step="0.1" />
            <.input field={@form[:presentation]} type="text" label="Presentation" />
            <.input field={@form[:lie]} type="text" label="Lie" />
            <.input field={@form[:foetal_heart_rate]} type="number" label="FHR" />
            <.input field={@form[:foetal_movement]} type="text" label="Foetal Movement" />
            <.input field={@form[:next_visit_date]} type="date" label="Next Visit Date" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_anc_visit"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save ANC Visit</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp record_delivery_modal(assigns) do
    ~H"""
    <.modal id="record-delivery-modal" show on_cancel={JS.push("close_record_delivery")}>
      <div id="record-delivery-content">
        <h2 class="text-lg font-semibold text-slate-900">Record Delivery</h2>
        <.simple_form
          for={@form}
          phx-change="validate_delivery"
          phx-submit="save_delivery"
          id="delivery-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:child_name]} type="text" label="Baby Name" />
            <.input
              field={@form[:sex]}
              type="select"
              label="Sex"
              options={[Male: "Male", Female: "Female"]}
              prompt="Select"
            />
            <.input field={@form[:delivery_date]} type="date" label="Delivery Date" />
            <.input field={@form[:delivery_time]} type="time" label="Delivery Time" />
            <.input
              field={@form[:duration_of_pregnancy_weeks]}
              type="number"
              label="Gestation (weeks)"
            />
            <.input
              field={@form[:mode_of_delivery]}
              type="select"
              label="Mode"
              options={[Normal: "Normal", Cesarean: "Cesarean", Assisted: "Assisted"]}
              prompt="Select"
            />
            <.input field={@form[:birth_weight_grams]} type="number" label="Birth Weight (g)" />
            <.input
              field={@form[:birth_length_cm]}
              type="number"
              label="Birth Length (cm)"
              step="0.1"
            />
            <.input
              field={@form[:head_circumference_cm]}
              type="number"
              label="Head Circumference (cm)"
              step="0.1"
            />
            <.input field={@form[:place_of_childbirth]} type="text" label="Place of Birth" />
            <.input field={@form[:birth_order]} type="number" label="Birth Order" />
            <.input field={@form[:conducted_by]} type="text" label="Conducted By" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_record_delivery"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Record Delivery</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_growth_modal(assigns) do
    ~H"""
    <.modal id="add-growth-modal" show on_cancel={JS.push("close_add_growth")}>
      <div id="add-growth-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Growth Measurement</h2>
        <.simple_form
          for={@form}
          phx-change="validate_growth"
          phx-submit="save_growth"
          id="growth-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:measurement_date]} type="date" label="Date" />
            <.input field={@form[:age_months]} type="number" label="Age (months)" />
            <.input field={@form[:weight_kg]} type="number" label="Weight (kg)" step="0.01" />
            <.input
              field={@form[:length_height_cm]}
              type="number"
              label="Length/Height (cm)"
              step="0.1"
            />
            <.input
              field={@form[:head_circumference_cm]}
              type="number"
              label="Head Circumference (cm)"
              step="0.1"
            />
            <.input field={@form[:muac_cm]} type="number" label="MUAC (cm)" step="0.1" />
            <.input
              field={@form[:nutritional_status]}
              type="select"
              label="Status"
              options={[
                Normal: "Normal",
                Underweight: "Underweight",
                Stunted: "Stunted",
                Wasted: "Wasted"
              ]}
              prompt="Select"
            />
            <.input field={@form[:next_visit_date]} type="date" label="Next Visit" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_growth"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_immunization_modal(assigns) do
    ~H"""
    <.modal id="add-immunization-modal" show on_cancel={JS.push("close_add_immunization")}>
      <div id="add-immunization-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Immunization</h2>
        <.simple_form
          for={@form}
          phx-change="validate_immunization"
          phx-submit="save_immunization"
          id="immunization-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input
              field={@form[:vaccine_name]}
              type="select"
              label="Vaccine"
              options={vaccine_options()}
              prompt="Select"
            />
            <.input field={@form[:dose_number]} type="number" label="Dose #" />
            <.input
              field={@form[:scheduled_age]}
              type="text"
              label="Scheduled Age (e.g. At birth, 6 weeks)"
            />
            <.input field={@form[:date_given]} type="date" label="Date Given" />
            <.input field={@form[:batch_number]} type="text" label="Batch #" />
            <.input field={@form[:next_visit_date]} type="date" label="Next Visit" />
            <.input field={@form[:adverse_event]} type="checkbox" label="AEFI reported" />
            <.input field={@form[:adverse_event_description]} type="text" label="AEFI Description" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_immunization"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_developmental_milestone_modal(assigns) do
    ~H"""
    <.modal
      id="add-developmental-milestone-modal"
      show
      on_cancel={JS.push("close_add_developmental_milestone")}
    >
      <div id="add-developmental-milestone-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Developmental Milestone</h2>
        <.simple_form
          for={@form}
          phx-change="validate_developmental_milestone"
          phx-submit="save_developmental_milestone"
          id="developmental-milestone-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:assessment_date]} type="date" label="Assessment Date" />
            <.input field={@form[:milestone_name]} type="text" label="Milestone" />
            <.input field={@form[:expected_age_range]} type="text" label="Expected Age Range" />
            <.input field={@form[:age_achieved_months]} type="number" label="Age Achieved (months)" />
            <.input
              field={@form[:status]}
              type="select"
              label="Status"
              options={[
                "Within time": "within_time",
                Delayed: "delayed",
                Monitoring: "monitoring"
              ]}
              prompt="Select"
            />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_developmental_milestone"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save Milestone</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_eye_assessment_modal(assigns) do
    ~H"""
    <.modal id="add-eye-assessment-modal" show on_cancel={JS.push("close_add_eye_assessment")}>
      <div id="add-eye-assessment-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Eye Assessment</h2>
        <.simple_form
          for={@form}
          phx-change="validate_eye_assessment"
          phx-submit="save_eye_assessment"
          id="eye-assessment-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:assessment_date]} type="date" label="Assessment Date" />
            <.input
              field={@form[:age_at_assessment]}
              type="text"
              label="Age At Assessment"
              placeholder="e.g. At birth, 6 weeks"
            />
            <.input field={@form[:teo_given]} type="checkbox" label="TEO given" />
            <.input
              field={@form[:pupil_color]}
              type="select"
              label="Pupil Color"
              options={[Black: "black", White: "white"]}
              prompt="Select"
            />
            <.input field={@form[:follows_objects]} type="checkbox" label="Follows objects" />
            <.input field={@form[:has_squint]} type="checkbox" label="Squint present" />
            <.input field={@form[:other_problems]} type="checkbox" label="Other eye problems" />
            <.input field={@form[:referred]} type="checkbox" label="Referred" />
            <.input
              field={@form[:other_problems_description]}
              type="text"
              label="Other Problem Description"
            />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_eye_assessment"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save Eye Assessment</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_antenatal_profile_modal(assigns) do
    ~H"""
    <.modal id="add-antenatal-profile-modal" show on_cancel={JS.push("close_add_antenatal_profile")}>
      <div id="add-antenatal-profile-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Antenatal Profile</h2>
        <.simple_form
          for={@form}
          phx-change="validate_antenatal_profile"
          phx-submit="save_antenatal_profile"
          id="antenatal-profile-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:haemoglobin_hb]} type="number" label="Hb (g/dL)" step="0.1" />
            <.input
              field={@form[:blood_group]}
              type="select"
              label="Blood Group"
              options={[A: "A", B: "B", AB: "AB", O: "O"]}
              prompt="Select"
            />
            <.input
              field={@form[:rhesus_factor]}
              type="select"
              label="Rhesus Factor"
              options={[Positive: "Positive", Negative: "Negative"]}
              prompt="Select"
            />
            <.input field={@form[:urinalysis]} type="text" label="Urinalysis" />
            <.input field={@form[:blood_rbs]} type="number" label="Blood RBS" step="0.1" />
            <.input field={@form[:tb_screening_date]} type="date" label="TB Screening Date" />
            <.input field={@form[:tb_screening_outcome]} type="text" label="TB Outcome" />
            <.input field={@form[:triple_test_date]} type="date" label="Triple Test Date" />
            <.input
              field={@form[:hiv_status]}
              type="select"
              label="HIV Status"
              options={[
                Reactive: "Reactive",
                "Non-Reactive": "Non-Reactive",
                "Not Tested": "Not Tested",
                Inconclusive: "Inconclusive"
              ]}
              prompt="Select"
            />
            <.input
              field={@form[:syphilis_status]}
              type="select"
              label="Syphilis Status"
              options={[
                Reactive: "Reactive",
                "Non-Reactive": "Non-Reactive",
                "Not Tested": "Not Tested"
              ]}
              prompt="Select"
            />
            <.input
              field={@form[:hepatitis_b_status]}
              type="select"
              label="Hepatitis B Status"
              options={[
                Reactive: "Reactive",
                "Non-Reactive": "Non-Reactive",
                "Not Tested": "Not Tested"
              ]}
              prompt="Select"
            />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_antenatal_profile"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save Profile</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_physical_examination_modal(assigns) do
    ~H"""
    <.modal
      id="add-physical-examination-modal"
      show
      on_cancel={JS.push("close_add_physical_examination")}
    >
      <div id="add-physical-examination-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Physical Examination</h2>
        <.simple_form
          for={@form}
          phx-change="validate_physical_examination"
          phx-submit="save_physical_examination"
          id="physical-examination-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:examination_date]} type="date" label="Examination Date" />
            <.input field={@form[:bp_systolic]} type="number" label="BP Systolic" />
            <.input field={@form[:bp_diastolic]} type="number" label="BP Diastolic" />
            <.input field={@form[:pulse_rate]} type="number" label="Pulse Rate" />
            <.input field={@form[:cvs_notes]} type="text" label="Cardiovascular Findings" />
            <.input field={@form[:respiratory_notes]} type="text" label="Respiratory Findings" />
            <.input field={@form[:breasts_notes]} type="text" label="Breast Findings" />
            <.input field={@form[:abdomen_notes]} type="text" label="Abdominal Findings" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_physical_examination"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save Examination</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_td_vaccination_modal(assigns) do
    ~H"""
    <.modal id="add-td-vaccination-modal" show on_cancel={JS.push("close_add_td_vaccination")}>
      <div id="add-td-vaccination-content">
        <h2 class="text-lg font-semibold text-slate-900">Add TD Vaccination</h2>
        <.simple_form
          for={@form}
          phx-change="validate_td_vaccination"
          phx-submit="save_td_vaccination"
          id="td-vaccination-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:dose_number]} type="number" label="Dose Number" min="1" max="5" />
            <.input field={@form[:date_given]} type="date" label="Date Given" />
            <.input field={@form[:next_visit]} type="date" label="Next Visit" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_td_vaccination"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save TD Dose</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_malaria_prophylaxis_modal(assigns) do
    ~H"""
    <.modal
      id="add-malaria-prophylaxis-modal"
      show
      on_cancel={JS.push("close_add_malaria_prophylaxis")}
    >
      <div id="add-malaria-prophylaxis-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Malaria Prophylaxis</h2>
        <.simple_form
          for={@form}
          phx-change="validate_malaria_prophylaxis"
          phx-submit="save_malaria_prophylaxis"
          id="malaria-prophylaxis-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:dose_number]} type="number" label="Dose Number" />
            <.input field={@form[:date_given]} type="date" label="Date Given" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_malaria_prophylaxis"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save IPT Dose</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_ifas_modal(assigns) do
    ~H"""
    <.modal id="add-ifas-modal" show on_cancel={JS.push("close_add_ifas")}>
      <div id="add-ifas-content">
        <h2 class="text-lg font-semibold text-slate-900">Add IFAS Record</h2>
        <.simple_form for={@form} phx-change="validate_ifas" phx-submit="save_ifas" id="ifas-form">
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:contact_number]} type="number" label="Contact Number" />
            <.input field={@form[:gestation_weeks]} type="number" label="Gestation (weeks)" />
            <.input field={@form[:tablets_issued]} type="number" label="Tablets Issued" />
            <.input field={@form[:date_given]} type="date" label="Date Given" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_ifas"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save IFAS</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_deworming_maternal_modal(assigns) do
    ~H"""
    <.modal id="add-deworming-maternal-modal" show on_cancel={JS.push("close_add_deworming_maternal")}>
      <div id="add-deworming-maternal-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Maternal Deworming</h2>
        <.simple_form
          for={@form}
          phx-change="validate_deworming_maternal"
          phx-submit="save_deworming_maternal"
          id="deworming-maternal-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:medication]} type="text" label="Medication" />
            <.input field={@form[:date_given]} type="date" label="Date Given" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_deworming_maternal"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save Deworming</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_pnc_mother_visit_modal(assigns) do
    ~H"""
    <.modal id="add-pnc-mother-visit-modal" show on_cancel={JS.push("close_add_pnc_mother_visit")}>
      <div id="add-pnc-mother-visit-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Mother PNC Visit</h2>
        <.simple_form
          for={@form}
          phx-change="validate_pnc_mother_visit"
          phx-submit="save_pnc_mother_visit"
          id="pnc-mother-visit-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input
              field={@form[:delivery_id]}
              type="select"
              label="Related Delivery"
              options={@delivery_options}
              prompt="Optional"
            />
            <.input field={@form[:visit_number]} type="number" label="Visit Number" />
            <.input field={@form[:visit_date]} type="date" label="Visit Date" />
            <.input field={@form[:bp_systolic]} type="number" label="BP Systolic" />
            <.input field={@form[:bp_diastolic]} type="number" label="BP Diastolic" />
            <.input field={@form[:temperature]} type="number" label="Temperature" step="0.1" />
            <.input field={@form[:general_condition]} type="text" label="General Condition" />
            <.input field={@form[:breast_condition]} type="text" label="Breast Condition" />
            <.input field={@form[:uterus_involution]} type="text" label="Uterus Involution" />
            <.input field={@form[:haemoglobin]} type="number" label="Haemoglobin" step="0.1" />
            <.input field={@form[:fp_counseling_done]} type="checkbox" label="FP Counseling Done" />
            <.input field={@form[:fp_method]} type="text" label="FP Method" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_pnc_mother_visit"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save PNC Visit</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_pnc_baby_visit_modal(assigns) do
    ~H"""
    <.modal id="add-pnc-baby-visit-modal" show on_cancel={JS.push("close_add_pnc_baby_visit")}>
      <div id="add-pnc-baby-visit-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Baby PNC Visit</h2>
        <.simple_form
          for={@form}
          phx-change="validate_pnc_baby_visit"
          phx-submit="save_pnc_baby_visit"
          id="pnc-baby-visit-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input
              field={@form[:pnc_mother_visit_id]}
              type="select"
              label="Linked Mother PNC Visit"
              options={@pnc_options}
              prompt="Optional"
            />
            <.input field={@form[:visit_date]} type="date" label="Visit Date" />
            <.input field={@form[:general_condition]} type="text" label="General Condition" />
            <.input field={@form[:temperature]} type="number" label="Temperature" step="0.1" />
            <.input field={@form[:breaths_per_minute]} type="number" label="Breaths per Minute" />
            <.input
              field={@form[:exclusive_breastfeeding]}
              type="checkbox"
              label="Exclusive Breastfeeding"
            />
            <.input field={@form[:umbilical_cord_status]} type="text" label="Umbilical Cord Status" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_pnc_baby_visit"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save PNC Visit</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_vitamin_a_modal(assigns) do
    ~H"""
    <.modal id="add-vitamin-a-modal" show on_cancel={JS.push("close_add_vitamin_a")}>
      <div id="add-vitamin-a-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Vitamin A Supplement</h2>
        <.simple_form
          for={@form}
          phx-change="validate_vitamin_a"
          phx-submit="save_vitamin_a"
          id="vitamin-a-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:date_given]} type="date" label="Date Given" />
            <.input field={@form[:age_months]} type="number" label="Age (months)" />
            <.input field={@form[:dose_iu]} type="number" label="Dose (IU)" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_vitamin_a"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save Vitamin A</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp add_child_deworming_modal(assigns) do
    ~H"""
    <.modal id="add-child-deworming-modal" show on_cancel={JS.push("close_add_child_deworming")}>
      <div id="add-child-deworming-content">
        <h2 class="text-lg font-semibold text-slate-900">Add Child Deworming</h2>
        <.simple_form
          for={@form}
          phx-change="validate_child_deworming"
          phx-submit="save_child_deworming"
          id="child-deworming-form"
        >
          <div class="grid gap-4 sm:grid-cols-2">
            <.input field={@form[:date_given]} type="date" label="Date Given" />
            <.input field={@form[:age_months]} type="number" label="Age (months)" />
            <.input field={@form[:medication]} type="text" label="Medication" />
            <.input field={@form[:dosage_mg]} type="number" label="Dosage (mg)" />
          </div>
          <:actions>
            <button
              type="button"
              phx-click="close_add_child_deworming"
              class="text-sm text-slate-600 hover:text-slate-800"
            >
              Cancel
            </button>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save Deworming</.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp vaccine_options do
    [
      BCG: "BCG",
      "OPV 0": "OPV 0",
      "OPV 1": "OPV 1",
      "OPV 2": "OPV 2",
      "OPV 3": "OPV 3",
      IPV: "IPV",
      "Penta 1": "Penta 1",
      "Penta 2": "Penta 2",
      "Penta 3": "Penta 3",
      "PCV 10 1": "PCV 10 1",
      "PCV 10 2": "PCV 10 2",
      "PCV 10 3": "PCV 10 3",
      "Measles 1": "Measles 1",
      "Measles 2": "Measles 2",
      "Yellow Fever": "Yellow Fever",
      "HPV 1": "HPV 1",
      "HPV 2": "HPV 2"
    ]
  end

  defp total_anc_visits(pregnancies) do
    pregnancies
    |> Enum.map(&length(&1.anc_visits || []))
    |> Enum.sum()
  end

  defp find_td_date(td_vaccinations, dose_number) do
    td_vaccinations
    |> Enum.find(&(&1.dose_number == dose_number))
    |> case do
      nil -> "—"
      td -> (td.date_given && format_date(td.date_given)) || "—"
    end
  end

  defp gestation_weeks_label(nil), do: "—"

  defp gestation_weeks_label(lmp) do
    weeks = div(max(Date.diff(Date.utc_today(), lmp), 0), 7)
    "#{weeks} weeks"
  end

  defp patient_full_name(nil), do: "—"

  defp patient_full_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&is_nil_or_empty/1)
    |> Enum.join(" ")
    |> case do
      "" -> "—"
      value -> value
    end
  end

  defp join_present(values, separator) do
    values
    |> Enum.reject(&is_nil_or_empty/1)
    |> Enum.join(separator)
    |> case do
      "" -> "—"
      value -> value
    end
  end

  defp is_nil_or_empty(nil), do: true
  defp is_nil_or_empty(""), do: true
  defp is_nil_or_empty(_value), do: false

  defp format_bp(nil, nil), do: "—"
  defp format_bp(sys, dia), do: "#{sys || "—"}/#{dia || "—"}"

  defp yes_no(true), do: "Yes"
  defp yes_no(false), do: "No"
  defp yes_no(nil), do: "—"

  defp format_datetime_date(nil), do: "—"
  defp format_datetime_date(datetime), do: Calendar.strftime(datetime, "%d %b %Y")

  defp delivery_options(nil), do: []

  defp delivery_options(mch_summary) do
    mch_summary.pregnancies
    |> Enum.flat_map(&(&1.deliveries || []))
    |> Enum.map(fn delivery ->
      {delivery_option_label(delivery), delivery.id}
    end)
  end

  defp delivery_option_label(delivery) do
    date = (delivery.delivery_date && format_date(delivery.delivery_date)) || "Undated"
    baby = (delivery.child && delivery.child.name) || "Delivery"
    "#{date} - #{baby}"
  end

  defp pnc_mother_visit_options(nil), do: []

  defp pnc_mother_visit_options(mch_summary) do
    mch_summary.mother.pnc_mother_visits
    |> Enum.map(fn visit ->
      {"Visit #{visit.visit_number || "—"} - #{(visit.visit_date && format_date(visit.visit_date)) || "Undated"}",
       visit.id}
    end)
  end

  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%d %b %Y")
end
