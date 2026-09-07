defmodule MedcampWeb.FeedbackLive.Index do
  use MedcampWeb, :live_view

  alias Medcamp.Feedback
  alias Medcamp.Feedback.PatientFeedback

  @impl true
  def mount(_params, _session, socket) do
    changeset = Feedback.change_patient_feedback(%PatientFeedback{})

    {:ok,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))
     |> assign(:show_success_modal, false)
     |> assign(:selected_sources, [])}
  end

  @impl true
  def handle_event("toggle_source", %{"value" => value}, socket) do
    selected = socket.assigns.selected_sources

    new_selected =
      if value in selected do
        List.delete(selected, value)
      else
        [value | selected]
      end

    {:noreply, assign(socket, :selected_sources, new_selected)}
  end

  @impl true
  def handle_event("toggle_source", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"patient_feedback" => feedback_params}, socket) do
    changeset =
      %PatientFeedback{}
      |> Feedback.change_patient_feedback(feedback_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"patient_feedback" => feedback_params}, socket) do
    # Add selected sources to params
    feedback_params =
      Map.put(
        feedback_params,
        "how_did_you_know",
        Enum.join(socket.assigns.selected_sources, ", ")
      )

    case Feedback.create_patient_feedback(feedback_params) do
      {:ok, _feedback} ->
        {:noreply,
         socket
         |> assign(:show_success_modal, true)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> assign(:form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_success_modal, false)
     |> push_navigate(to: ~p"/")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-8">
      <.public_navbar />

      <div class="bg-white my-40 rounded-lg shadow-sm border border-gray-100 p-6 max-w-4xl mx-auto w-full">
        <div class="flex gap-2 text-[#373896] font-semibold items-center mb-6">
          <.link navigate="/" class="hover:text-[#6667ab] transition-colors">
            <Heroicons.icon name="arrow-left" type="outline" class="h-5 w-5" />
          </.link>
          <p class="text-lg">
            Patient Feedback Form
          </p>
        </div>
        
    <!-- Header Card -->
        <div class="bg-[#f8f8ff] rounded-lg p-5 shadow-sm border border-gray-100 mb-6">
          <div class="bg-white rounded-lg shadow-md p-4 border border-gray-200 relative overflow-hidden">
            <div class="absolute top-0 right-0 w-full h-full bg-gradient-to-br from-transparent to-[#e7e7ff] opacity-20 -z-10">
            </div>

            <div class="flex justify-between items-center w-[100%] border-b-2 border-[#373896] pb-2 mb-3">
              <div class="text-[#373896]">
                <div class="font-bold text-sm">GHC Excellence</div>
                <div class="text-sm">Patient Feedback Questionnaire</div>
              </div>

              <div>
                <img src="/images/logo.png" alt="Logo" class="h-12 w-12 rounded-full" />
              </div>
            </div>

            <p class="text-sm text-gray-600 leading-relaxed">
              Your feedback is important to us. It helps us improve the quality of
              care and services we provide. Please take a few minutes to complete this
              form. Your responses will remain confidential.
            </p>
          </div>
        </div>

        <p class="text-sm text-red-600 mb-6">* Indicates required question</p>
        
    <!-- Feedback Form -->
        <.simple_form for={@form} phx-change="validate" phx-submit="save" class="space-y-8">
          <!-- Reviewer Name -->
          <div class="bg-white rounded-lg p-6 border border-gray-200">
            <h3 class="text-base font-normal text-gray-900 mb-1">
              Your Name <span class="text-red-600">*</span>
            </h3>

            <.input
              field={@form[:name]}
              type="text"
              placeholder="Enter your full name"
              class="mt-4"
              required
            />
          </div>
          
    <!-- Question 1: How did you know about us? -->
          <div class="bg-white rounded-lg p-6 border border-gray-200">
            <h3 class="text-base font-normal text-gray-900 mb-4">
              How did you know about us?
            </h3>

            <div class="space-y-3">
              <%= for {label, value} <- [
                {"Billboard, Flyers", "billboard_flyers"},
                {"Medical Camp, Radio Station, Road Show", "medical_camp_radio"},
                {"Social Media (Whatsapp, Instagram, TikTok, FB)", "social_media"},
                {"Referral from Friend or Health Facility", "referral"},
                {"I saw the Hospital/Facility", "saw_hospital"}
              ] do %>
                <label class="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    value={value}
                    checked={value in @selected_sources}
                    phx-click="toggle_source"
                    phx-value-value={value}
                    class="h-4 w-4 text-[#373896] border-gray-300 rounded focus:ring-[#373896]"
                  />
                  <span class="text-sm text-gray-700 group-hover:text-gray-900">
                    {label}
                  </span>
                </label>
              <% end %>

              <div class="flex items-center gap-3">
                <input
                  type="checkbox"
                  value="other"
                  checked={"other" in @selected_sources}
                  phx-click="toggle_source"
                  phx-value-value="other"
                  class="h-4 w-4 text-[#373896] border-gray-300 rounded focus:ring-[#373896]"
                />
                <span class="text-sm text-gray-700">Other:</span>
              </div>
              <%= if "other" in @selected_sources do %>
                <.input
                  field={@form[:how_did_you_know_other]}
                  type="text"
                  class="ml-7 mt-2"
                  placeholder="Please specify"
                />
              <% end %>
            </div>
          </div>
          
    <!-- Question 2: How satisfied are you? (REQUIRED) -->
          <div class="bg-white rounded-lg p-6 border border-gray-200">
            <h3 class="text-base font-normal text-gray-900 mb-1">
              How satisfied are you with your recent experience? <span class="text-red-600">*</span>
            </h3>

            <div class="space-y-3 mt-4">
              <%= for {label, value} <- [
                {"Very Satisfied", "very_satisfied"},
                {"Satisfied", "satisfied"},
                {"Neutral", "neutral"},
                {"Dissatisfied", "dissatisfied"},
                {"Very Dissatisfied", "very_dissatisfied"}
              ] do %>
                <label class="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="radio"
                    name={"#{@form.name}[satisfaction_level]"}
                    value={value}
                    checked={Phoenix.HTML.Form.input_value(@form, :satisfaction_level) == value}
                    class="h-4 w-4 text-[#373896] border-gray-300 focus:ring-[#373896]"
                  />
                  <span class="text-sm text-gray-700 group-hover:text-gray-900">
                    {label}
                  </span>
                </label>
              <% end %>
            </div>
          </div>
          
    <!-- Question 3: Star Rating -->
          <div class="bg-white rounded-lg p-6 border border-gray-200">
            <h3 class="text-base font-normal text-gray-900 mb-4">
              How would you rate the quality of the service?
            </h3>

            <div class="flex items-center gap-6">
              <%= for rating <- 1..5 do %>
                <label class="flex flex-col items-center gap-2 cursor-pointer group">
                  <span class="text-sm text-gray-600">{rating}</span>
                  <input
                    type="radio"
                    name={"#{@form.name}[service_quality_rating]"}
                    value={rating}
                    checked={
                      to_string(Phoenix.HTML.Form.input_value(@form, :service_quality_rating)) ==
                        to_string(rating)
                    }
                    class="sr-only"
                  />
                  <Heroicons.icon
                    name="star"
                    type={
                      if to_string(Phoenix.HTML.Form.input_value(@form, :service_quality_rating)) ==
                           to_string(rating),
                         do: "solid",
                         else: "outline"
                    }
                    class={
                      "h-8 w-8 transition-colors " <>
                        if(
                          to_string(Phoenix.HTML.Form.input_value(@form, :service_quality_rating)) ==
                            to_string(rating),
                          do: "text-yellow-400",
                          else: "text-gray-400 group-hover:text-yellow-300"
                        )
                    }
                  />
                </label>
              <% end %>
            </div>
          </div>
          
    <!-- Question 4: Staff helpful? -->
          <div class="bg-white rounded-lg p-6 border border-gray-200">
            <h3 class="text-base font-normal text-gray-900 mb-4">
              Was our staff helpful and knowledgeable?
            </h3>

            <div class="space-y-3">
              <%= for {label, value} <- [
                {"Yes", "yes"},
                {"No", "no"}
              ] do %>
                <label class="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="radio"
                    name={"#{@form.name}[staff_helpful]"}
                    value={value}
                    checked={Phoenix.HTML.Form.input_value(@form, :staff_helpful) == value}
                    class="h-4 w-4 text-[#373896] border-gray-300 focus:ring-[#373896]"
                  />
                  <span class="text-sm text-gray-700 group-hover:text-gray-900">
                    {label}
                  </span>
                </label>
              <% end %>

              <div class="flex items-center gap-3">
                <input
                  type="radio"
                  name={"#{@form.name}[staff_helpful]"}
                  value="other"
                  checked={Phoenix.HTML.Form.input_value(@form, :staff_helpful) == "other"}
                  class="h-4 w-4 text-[#373896] border-gray-300 focus:ring-[#373896]"
                />
                <span class="text-sm text-gray-700">Other:</span>
              </div>
              <%= if Phoenix.HTML.Form.input_value(@form, :staff_helpful) == "other" do %>
                <.input
                  field={@form[:staff_helpful_other]}
                  type="text"
                  class="ml-7 mt-2"
                  placeholder="Please specify"
                />
              <% end %>
            </div>
          </div>
          
    <!-- Question 5: Suggestions -->
          <div class="bg-white rounded-lg p-6 border border-gray-200">
            <h3 class="text-base font-normal text-gray-900 mb-4">
              Any suggestions to help us improve?
            </h3>

            <.input
              field={@form[:suggestions]}
              type="textarea"
              placeholder="Your answer"
              rows="3"
              class="w-full"
            />
          </div>
          
    <!-- Submit Button -->
          <div class="flex justify-between items-center pt-6">
            <button
              type="submit"
              class="px-8 py-2.5 bg-teal-700 text-white font-medium rounded hover:bg-teal-800 transition-colors"
            >
              Submit
            </button>

            <div class="flex items-center gap-2">
              <div class="w-48 h-2 bg-teal-600 rounded-full"></div>
              <span class="text-sm text-gray-600">Page 1 of 1</span>
            </div>
          </div>

          <p class="text-xs text-gray-500 text-center pt-4">
            Never submit passwords through Google Forms.
          </p>
        </.simple_form>
      </div>

      <.footer_user />
      
    <!-- Success Modal -->
      <%= if @show_success_modal do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-white rounded-lg shadow-xl max-w-md w-full mx-4 transform transition-all">
            <div class="p-6 text-center">
              <!-- Success Icon -->
              <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-green-100 mb-4">
                <Heroicons.icon name="check" type="solid" class="h-8 w-8 text-green-600" />
              </div>
              
    <!-- Title -->
              <h3 class="text-lg font-semibold text-gray-900 mb-2">
                Thank You!
              </h3>
              
    <!-- Message -->
              <p class="text-sm text-gray-600 mb-6">
                Your feedback has been submitted successfully. We truly appreciate you taking the time to share your experience with us.
              </p>
              
    <!-- Action Button -->
              <button
                phx-click="close_modal"
                class="w-full bg-[#373896] text-white py-3 px-4 rounded-lg font-semibold hover:bg-[#2a2a70] transition-colors flex items-center justify-center gap-2"
              >
                <Heroicons.icon name="home" type="outline" class="h-5 w-5" /> Return to Home
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
