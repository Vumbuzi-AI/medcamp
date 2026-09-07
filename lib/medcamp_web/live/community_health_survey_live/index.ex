defmodule MedcampWeb.CommunityHealthSurveyLive.Index do
  use MedcampWeb, :live_view

  alias Medcamp.CommunityHealthSurveys
  alias Medcamp.CommunityHealthSurveys.Response

  @impl true
  def mount(_params, _session, socket) do
    changeset =
      CommunityHealthSurveys.change_response(%Response{}, %{
        "survey_date" => Date.utc_today()
      })

    {:ok,
     socket
     |> assign(:body_class, "bg-white")
     |> assign(:page_title, "Community Health & Insurance Survey")
     |> assign(:submitted, false)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"response" => params}, socket) do
    changeset =
      %Response{}
      |> CommunityHealthSurveys.change_response(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"response" => params}, socket) do
    case CommunityHealthSurveys.create_response(params) do
      {:ok, _response} ->
        fresh_changeset =
          CommunityHealthSurveys.change_response(%Response{}, %{
            "survey_date" => Date.utc_today()
          })

        {:noreply,
         socket
         |> put_flash(:info, "Survey response saved.")
         |> assign(:submitted, true)
         |> assign_form(fresh_changeset)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  @impl true
  def handle_event("new_response", _params, socket) do
    changeset =
      CommunityHealthSurveys.change_response(%Response{}, %{
        "survey_date" => Date.utc_today()
      })

    {:noreply,
     socket
     |> assign(:submitted, false)
     |> assign_form(changeset)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="top" class={["min-h-screen", public_page_background_class()]}>
      <.public_navbar />

      <main class="pb-16 pt-8 sm:pt-10">
        <div class="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <div class="overflow-hidden rounded-[2rem] border border-[#d9defd] bg-white shadow-sm">
            <div class="border-b border-[#e4e6ff] bg-[#f8f8ff] px-6 py-6 sm:px-8">
              <h1 class="text-2xl font-bold tracking-tight text-[#373896] sm:text-3xl">
                Community Health & Insurance Survey
              </h1>
            </div>

            <%= if @submitted do %>
              <section class="px-6 py-12 sm:px-8">
                <div class="mx-auto max-w-xl rounded-[1.75rem] border border-[#d9defd] bg-[#f8f8ff] p-8 text-center">
                  <div class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-[#373896] text-white">
                    <Heroicons.icon name="check" type="solid" class="h-7 w-7" />
                  </div>
                  <h2 class="mt-5 text-2xl font-semibold text-[#373896]">Survey saved</h2>
                  <button
                    type="button"
                    phx-click="new_response"
                    class="mt-6 inline-flex items-center justify-center rounded-2xl bg-[#373896] px-5 py-3 text-sm font-semibold text-white transition hover:bg-[#2f3183]"
                  >
                    Add another response
                  </button>
                </div>
              </section>
            <% else %>
              <.form
                for={@form}
                phx-change="validate"
                phx-submit="save"
                class="space-y-5 px-6 py-6 sm:px-8 sm:py-8"
              >
                <div class="grid gap-5 md:grid-cols-3">
                  <.text_question
                    form={@form}
                    field={:surveyor_name}
                    label="Surveyor Name"
                    placeholder="Enter full name"
                    required
                  />
                  <.date_question form={@form} field={:survey_date} label="Date" required />
                  <.text_question
                    form={@form}
                    field={:house_number}
                    label="House Number / Block"
                    placeholder="House or block reference"
                    required
                  />
                </div>

                <section class="grid gap-5 lg:grid-cols-2">
                  <.question_card title="Q1. How many people live in this household?" required>
                    <:content>
                      <div class="grid gap-4 sm:grid-cols-2">
                        <.select_question
                          form={@form}
                          field={:adults_count}
                          label="Adults (18+)"
                          options={numeric_options()}
                          required
                        />
                        <.select_question
                          form={@form}
                          field={:children_count}
                          label="Children (<18)"
                          options={numeric_options()}
                          required
                        />
                      </div>
                      <div class="rounded-2xl mt-5 border border-[#d9defd] bg-[#f8f8ff] px-4 py-4">
                        <p class="text-xs font-semibold uppercase tracking-[0.16em] text-[#6667ab]">
                          Total household members
                        </p>
                        <p class="mt-3 text-3xl font-semibold text-[#373896]">
                          {input_value(@form, :total_household_members) || 0}
                        </p>
                      </div>
                    </:content>
                  </.question_card>

                  <.question_card
                    title="Q2. Does your household have any health insurance cover?"
                    required
                  >
                    <:content>
                      <.radio_group
                        form={@form}
                        field={:has_health_insurance}
                        options={Response.yes_no_options()}
                      />
                    </:content>
                  </.question_card>
                </section>

                <%= if input_value(@form, :has_health_insurance) == "Yes" do %>
                  <section class="grid gap-5 lg:grid-cols-2">
                    <.question_card
                      title="Q3. Which insurance cover does your household have?"
                      required
                    >
                      <:content>
                        <.checkbox_group
                          form={@form}
                          field={:insurance_covers}
                          options={Response.insurance_cover_options()}
                        />
                      </:content>
                    </.question_card>

                    <.question_card title="Q4. Which insurance provider(s) do you use?" required>
                      <:content>
                        <.checkbox_group
                          form={@form}
                          field={:insurance_providers}
                          options={Response.insurance_provider_options()}
                        />

                        <%= if "Other" in selected_values(@form, :insurance_providers) do %>
                          <div class="mt-4">
                            <.text_question
                              form={@form}
                              field={:insurance_provider_other}
                              label="Other provider"
                              placeholder="Enter provider name"
                            />
                          </div>
                        <% end %>
                      </:content>
                    </.question_card>
                  </section>
                <% end %>

                <section class="grid gap-5 lg:grid-cols-2">
                  <.question_card title="Q5. Which health facility do you normally visit when you need medical care?">
                    <:content>
                      <.radio_group
                        form={@form}
                        field={:preferred_facility_type}
                        options={Response.preferred_facility_options()}
                      />

                      <%= if input_value(@form, :preferred_facility_type) == "Other" do %>
                        <div class="mt-4">
                          <.text_question
                            form={@form}
                            field={:preferred_facility_other}
                            label="Other facility type"
                            placeholder="Enter facility type"
                          />
                        </div>
                      <% end %>

                      <div class="mt-4">
                        <.text_question
                          form={@form}
                          field={:preferred_facility_name}
                          label="Facility name (optional)"
                          placeholder="Facility name"
                        />
                      </div>
                    </:content>
                  </.question_card>

                  <.question_card
                    title="Q6. Why do you choose that facility?"
                    hint="Select up to 3 reasons"
                  >
                    <:content>
                      <.checkbox_group
                        form={@form}
                        field={:facility_choice_reasons}
                        options={Response.facility_choice_reason_options()}
                        max_selected={3}
                      />
                    </:content>
                  </.question_card>
                </section>

                <section class="grid gap-5 lg:grid-cols-2">
                  <.question_card title="Q7. Have you ever visited Glocal Healthcare Centre of Excellence?">
                    <:content>
                      <.radio_group
                        form={@form}
                        field={:visited_glocal}
                        options={Response.yes_no_options()}
                      />
                    </:content>
                  </.question_card>

                  <%= if input_value(@form, :visited_glocal) == "Yes" do %>
                    <.question_card title="Q8. If yes, how would you rate your experience?">
                      <:content>
                        <.radio_group
                          form={@form}
                          field={:glocal_experience_rating}
                          options={Response.experience_rating_options()}
                        />
                      </:content>
                    </.question_card>
                  <% else %>
                    <.question_card title="Q9. If no, what is the main reason?">
                      <:content>
                        <.radio_group
                          form={@form}
                          field={:glocal_non_visit_reason}
                          options={Response.non_visit_reason_options()}
                        />
                      </:content>
                    </.question_card>
                  <% end %>
                </section>

                <section class="grid gap-5 lg:grid-cols-2">
                  <.question_card title="Q10. Which services would your household most likely use?">
                    <:content>
                      <.checkbox_group
                        form={@form}
                        field={:likely_services}
                        options={Response.likely_service_options()}
                      />
                    </:content>
                  </.question_card>

                  <.question_card title="Q11. Does anyone in the household have any of the following conditions?">
                    <:content>
                      <.checkbox_group
                        form={@form}
                        field={:household_conditions}
                        options={Response.household_condition_options()}
                      />
                    </:content>
                  </.question_card>
                </section>

                <section class="grid gap-5 lg:grid-cols-2">
                  <.question_card title="Q12. Would you be interested in free or discounted community health screening programs?">
                    <:content>
                      <.radio_group
                        form={@form}
                        field={:interested_in_screenings}
                        options={Response.yes_no_options()}
                      />
                    </:content>
                  </.question_card>

                  <.question_card title="Q13. Would you like to receive health updates and offers from Glocal Healthcare Centre of Excellence?">
                    <:content>
                      <.radio_group
                        form={@form}
                        field={:wants_updates}
                        options={Response.yes_no_options()}
                      />
                    </:content>
                  </.question_card>
                </section>

                <%= if input_value(@form, :wants_updates) == "Yes" do %>
                  <section class="grid gap-5 lg:grid-cols-2">
                    <.question_card title="Q14. Preferred communication method">
                      <:content>
                        <.radio_group
                          form={@form}
                          field={:preferred_contact_method}
                          options={Response.preferred_contact_method_options()}
                        />
                      </:content>
                    </.question_card>

                    <.question_card title="Q15. Contact number">
                      <:content>
                        <.text_question
                          form={@form}
                          field={:contact_number}
                          label="Contact number"
                          placeholder="+254..."
                        />
                      </:content>
                    </.question_card>
                  </section>
                <% end %>

                <div class="flex justify-end border-t border-[#e4e6ff] pt-5">
                  <button
                    type="submit"
                    class="inline-flex items-center justify-center rounded-2xl bg-[#373896] px-6 py-3 text-sm font-semibold text-white transition hover:bg-[#2f3183]"
                  >
                    Save survey response
                  </button>
                </div>
              </.form>
            <% end %>
          </div>
        </div>
      </main>

      <.public_footer />
    </div>
    """
  end

  attr :title, :string, required: true
  attr :required, :boolean, default: false
  attr :hint, :string, default: nil
  slot :content, required: true

  defp question_card(assigns) do
    ~H"""
    <section class="rounded-[1.5rem] border border-[#d9defd] bg-white p-5 shadow-sm">
      <div class="mb-4">
        <h2 class="text-base font-semibold text-[#111827]">
          {@title}
          <span :if={@required} class="text-rose-500">*</span>
        </h2>
        <p :if={@hint} class="mt-1 text-sm text-[#6667ab]">{@hint}</p>
      </div>
      {render_slot(@content)}
    </section>
    """
  end

  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false

  defp text_question(assigns) do
    ~H"""
    <label class="block rounded-[1.5rem] border border-[#d9defd] bg-white p-5 shadow-sm">
      <span class="text-sm font-medium text-[#111827]">
        {@label}
        <span :if={@required} class="text-rose-500">*</span>
      </span>
      <input
        type="text"
        name={@form[@field].name}
        value={input_value(@form, @field) || ""}
        placeholder={@placeholder}
        class="mt-3 w-full rounded-2xl border border-[#d9defd] px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-[#6667ab] focus:ring-2 focus:ring-[#e4e6ff]"
      />
      <.field_errors field={@form[@field]} />
    </label>
    """
  end

  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :required, :boolean, default: false

  defp date_question(assigns) do
    ~H"""
    <label class="block rounded-[1.5rem] border border-[#d9defd] bg-white p-5 shadow-sm">
      <span class="text-sm font-medium text-[#111827]">
        {@label}
        <span :if={@required} class="text-rose-500">*</span>
      </span>
      <input
        type="date"
        name={@form[@field].name}
        value={format_date_value(input_value(@form, @field))}
        class="mt-3 w-full rounded-2xl border border-[#d9defd] px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-[#6667ab] focus:ring-2 focus:ring-[#e4e6ff]"
      />
      <.field_errors field={@form[@field]} />
    </label>
    """
  end

  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :options, :list, required: true
  attr :required, :boolean, default: false

  defp select_question(assigns) do
    ~H"""
    <label class="block">
      <span class="text-sm font-medium text-[#111827]">
        {@label}
        <span :if={@required} class="text-rose-500">*</span>
      </span>
      <select
        name={@form[@field].name}
        class="mt-3 w-full rounded-2xl border border-[#d9defd] bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-[#6667ab] focus:ring-2 focus:ring-[#e4e6ff]"
      >
        <%= for {label, value} <- @options do %>
          <option
            value={value}
            selected={to_string(input_value(@form, @field) || 0) == to_string(value)}
          >
            {label}
          </option>
        <% end %>
      </select>
      <.field_errors field={@form[@field]} />
    </label>
    """
  end

  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :options, :list, required: true

  defp radio_group(assigns) do
    ~H"""
    <div class="space-y-3">
      <%= for option <- @options do %>
        <label class="flex items-center gap-3 rounded-2xl border border-[#d9defd] px-4 py-3 transition hover:bg-[#f8f8ff]">
          <input
            type="radio"
            name={@form[@field].name}
            value={option}
            checked={input_value(@form, @field) == option}
            class="h-4 w-4 border-slate-300 text-[#373896] focus:ring-[#6667ab]"
          />
          <span class="text-sm text-slate-700">{option}</span>
        </label>
      <% end %>
      <.field_errors field={@form[@field]} />
    </div>
    """
  end

  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :options, :list, required: true
  attr :max_selected, :integer, default: nil

  defp checkbox_group(assigns) do
    ~H"""
    <div class="space-y-3">
      <input type="hidden" name={@form[@field].name <> "[]"} value="" />
      <%= for option <- @options do %>
        <% selected = selected_values(@form, @field) %>
        <% checked? = option in selected %>
        <% disabled? = @max_selected && length(selected) >= @max_selected && not checked? %>
        <label class={[
          "flex items-center gap-3 rounded-2xl border px-4 py-3 transition",
          disabled? && "cursor-not-allowed border-slate-100 bg-slate-50 text-slate-400",
          !disabled? && "border-[#d9defd] hover:bg-[#f8f8ff]"
        ]}>
          <input
            type="checkbox"
            name={@form[@field].name <> "[]"}
            value={option}
            checked={checked?}
            disabled={disabled?}
            class="h-4 w-4 rounded border-slate-300 text-[#373896] focus:ring-[#6667ab]"
          />
          <span class="text-sm">{option}</span>
        </label>
      <% end %>
      <.field_errors field={@form[@field]} />
    </div>
    """
  end

  attr :field, :any, required: true

  defp field_errors(assigns) do
    ~H"""
    <.error :for={msg <- Enum.map(@field.errors, &translate_error/1)}>
      {msg}
    </.error>
    """
  end

  defp numeric_options do
    [{"0", 0}, {"1", 1}, {"2", 2}, {"3", 3}, {"4", 4}, {"5+", 5}]
  end

  defp selected_values(form, field) do
    case input_value(form, field) do
      nil -> []
      values when is_list(values) -> values
      value -> [value]
    end
  end

  defp input_value(form, field), do: Phoenix.HTML.Form.input_value(form, field)

  defp format_date_value(%Date{} = date), do: Date.to_iso8601(date)
  defp format_date_value(value) when is_binary(value), do: value
  defp format_date_value(_), do: nil

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: :response))
  end
end
