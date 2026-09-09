defmodule MedcampWeb.TriageComponents do
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext

  alias Phoenix.LiveView.JS
  import MedcampWeb.CoreComponents

  def triages_table(assigns) do
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
