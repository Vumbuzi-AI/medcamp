defmodule MedcampWeb.TriageComponents do
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext

  alias Phoenix.LiveView.JS
  import MedcampWeb.CoreComponents

  attr :triage, :map, required: true

  @doc """
  The vitals a clinician reads off a single triage, as a plain grid.

  Shared by the camp overview's triage popup and the doctor note form's
  triage tab so the two never drift apart.
  """
  def triage_vitals_grid(assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm">
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">Date</span>
          <span class="font-medium">{@triage.date}</span>
        </div>
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">Time</span>
          <span class="font-medium">{@triage.time || "-"}</span>
        </div>
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">Temperature</span>
          <span class="font-medium">{@triage.temperature || "-"} °C</span>
        </div>
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">Blood Pressure</span>
          <span class="font-medium">{@triage.blood_pressure || "-"}</span>
        </div>
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">Pulse Rate</span>
          <span class="font-medium">{@triage.pulse_rate || "-"} bpm</span>
        </div>
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">O2 Saturation</span>
          <span class="font-medium">{@triage.oxygen_saturation || "-"} %</span>
        </div>
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">Weight</span>
          <span class="font-medium">{@triage.weight || "-"} kg</span>
        </div>
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">Height</span>
          <span class="font-medium">{@triage.height || "-"} cm</span>
        </div>
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">BMI</span>
          <span class="font-medium">{@triage.bmi || "-"}</span>
        </div>
        <div class="bg-slate-50 rounded p-2">
          <span class="text-slate-500 block">Emergency</span>
          <span class={[
            "font-medium",
            @triage.emergency_scale == "High" && "text-red-600",
            @triage.emergency_scale == "Medium" && "text-amber-600",
            @triage.emergency_scale == "Low" && "text-green-600"
          ]}>
            {@triage.emergency_scale || "-"}
          </span>
        </div>
      </div>
      <div :if={@triage.allergies} class="mt-3 bg-red-50 rounded p-2 text-sm">
        <span class="text-red-600 font-medium">Allergies: </span>
        <span class="text-red-800">{@triage.allergies}</span>
      </div>
      <div :if={@triage.triage_notes} class="mt-2 bg-slate-50 rounded p-2 text-sm">
        <span class="text-slate-500 font-medium">Notes: </span>
        <span>{@triage.triage_notes}</span>
      </div>
    </div>
    """
  end

  def triages_table(assigns) do
    # Callers that only render a patient's own triages (e.g. the camp-link home
    # page) don't compute a separate `count` - derive it from the rows.
    assigns = assign_new(assigns, :count, fn -> length(assigns[:triages] || []) end)

    ~H"""
    <div class="bg-white rounded-lg border border-slate-100 p-4">
      <.header
        :if={Map.get(assigns, :show_header, true)}
        class="text-brand-primary border-b border-slate-100 pb-4 mb-4"
      >
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-brand-accent"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M16 8v8m-4-5v5m-4-2v2m-2 4h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
            />
          </svg>
          Triages
        </div>
        <:actions>
          <.link :if={@show_new_link} patch={@new_triage_url}>
            <.button class="bg-brand-accent hover:bg-brand-accent-dark">
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                New Triage
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>

      <%= if @count == 0 do %>
        <.blank_state
          icon_path="M16 8v8m-4-5v5m-4-2v2m-2 4h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
          title="No triages"
          description={
            if Map.get(assigns, :show_clear_filters, false),
              do: "No triages match the current filters.",
              else: "No triage information has been recorded yet."
          }
        >
          <:actions :if={Map.get(assigns, :show_clear_filters, false)}>
            <button phx-click="clear_filters" class="text-xs text-brand-accent hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>
      <% else %>
        <.data_table
          id="triages"
          rows={@triages}
          row_click={
            if assigns[:row_click],
              do: @row_click,
              else: fn triage -> JS.navigate("#{@route_prefix}/#{triage.id}/edit") end
          }
          row_id={&"triages-#{&1.id}"}
        >
          <:col :let={triage} label="Date">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-brand-accent"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              <span class="text-slate-700">{triage.date}</span>
            </div>
          </:col>

          <:col :let={triage} label="Temperature">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-brand-50 text-brand-primary font-medium">
                {triage.temperature} °C
              </span>
            </div>
          </:col>

          <:col :let={triage} label="Blood Pressure">
            <div class="py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-brand-50 text-brand-primary font-medium">
                {triage.blood_pressure} mmHg
              </span>
            </div>
          </:col>

          <:col :let={triage} label="Pulse Rate">
            <div class="py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-brand-50 text-brand-primary font-medium">
                {triage.pulse_rate} bpm
              </span>
            </div>
          </:col>

          <:col :let={triage} label="Oxygen Saturation">
            <div class="py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-brand-50 text-brand-primary font-medium">
                {triage.oxygen_saturation}%
              </span>
            </div>
          </:col>

          <:col :let={triage} label="Height">
            <div class="py-3">
              <span class="text-slate-700">{triage.height} cm</span>
            </div>
          </:col>

          <:col :let={triage} label="Weight">
            <div class="py-3">
              <span class="text-slate-700">{triage.weight} kg</span>
            </div>
          </:col>

          <:col :let={triage} label="BMI">
            <div class="py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-brand-50 text-brand-primary font-medium">
                {triage.bmi}
              </span>
            </div>
          </:col>

          <:action :let={triage}>
            <.link
              patch={"#{@route_prefix}/#{triage.id}/edit"}
              class="flex items-center text-brand-accent hover:text-brand-primary"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                />
              </svg>
              View
            </.link>
          </:action>
        </.data_table>
      <% end %>
    </div>
    """
  end
end
