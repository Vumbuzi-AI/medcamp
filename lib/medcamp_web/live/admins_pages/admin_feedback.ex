defmodule MedcampWeb.AdminFeedbackLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Feedback

  @satisfaction_options [
    {"All", "all"},
    {"Very Satisfied", "very_satisfied"},
    {"Satisfied", "satisfied"},
    {"Neutral", "neutral"},
    {"Dissatisfied", "dissatisfied"},
    {"Very Dissatisfied", "very_dissatisfied"}
  ]

  @staff_helpful_options [
    {"All", "all"},
    {"Yes", "yes"},
    {"No", "no"},
    {"Other", "other"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    filter_opts =
      build_filter_opts(%{
        "date_from" => "",
        "date_to" => "",
        "satisfaction_level" => "all",
        "staff_helpful" => "all",
        "search" => ""
      })

    feedbacks = Feedback.list_patient_feedbacks(filter_opts)

    {:ok,
     socket
     |> assign(:feedbacks, feedbacks)
     |> assign(:active_tab, :feedback)
     |> assign(:selected_feedback, nil)
     |> assign(:filter_date_from, "")
     |> assign(:filter_date_to, "")
     |> assign(:filter_satisfaction_level, "all")
     |> assign(:filter_staff_helpful, "all")
     |> assign(:filter_search, "")
     |> assign(:satisfaction_options, @satisfaction_options)
     |> assign(:staff_helpful_options, @staff_helpful_options)}
  end

  @impl true
  def handle_event("view_feedback", %{"id" => id}, socket) do
    feedback = Enum.find(socket.assigns.feedbacks, &(&1.id == String.to_integer(id)))

    {:noreply,
     socket
     |> assign(:selected_feedback, feedback)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_feedback, nil)}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the current filters means a key absent from this submission
  # is left unchanged rather than reset.
  @impl true
  def handle_event("apply_filters", params, socket) do
    current = %{
      "date_from" => socket.assigns.filter_date_from,
      "date_to" => socket.assigns.filter_date_to,
      "satisfaction_level" => socket.assigns.filter_satisfaction_level,
      "staff_helpful" => socket.assigns.filter_staff_helpful,
      "search" => socket.assigns.filter_search
    }

    form = Map.merge(current, params["filters"] || %{})
    date_from = Map.get(form, "date_from", "") |> str_trim()
    date_to = Map.get(form, "date_to", "") |> str_trim()
    satisfaction = Map.get(form, "satisfaction_level", "all") |> str_trim()
    staff_helpful = Map.get(form, "staff_helpful", "all") |> str_trim()
    search = Map.get(form, "search", "") |> str_trim()

    filter_opts =
      build_filter_opts(%{
        "date_from" => date_from,
        "date_to" => date_to,
        "satisfaction_level" => satisfaction,
        "staff_helpful" => staff_helpful,
        "search" => search
      })

    feedbacks = Feedback.list_patient_feedbacks(filter_opts)

    {:noreply,
     socket
     |> assign(:feedbacks, feedbacks)
     |> assign(:filter_date_from, date_from)
     |> assign(:filter_date_to, date_to)
     |> assign(:filter_satisfaction_level, satisfaction)
     |> assign(:filter_staff_helpful, staff_helpful)
     |> assign(:filter_search, search)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    feedbacks = Feedback.list_patient_feedbacks()

    {:noreply,
     socket
     |> assign(:feedbacks, feedbacks)
     |> assign(:filter_date_from, "")
     |> assign(:filter_date_to, "")
     |> assign(:filter_satisfaction_level, "all")
     |> assign(:filter_staff_helpful, "all")
     |> assign(:filter_search, "")}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    default = if field in ["satisfaction_level", "staff_helpful"], do: "all", else: ""
    handle_event("apply_filters", %{"filters" => %{field => default}}, socket)
  end

  @impl true
  def handle_event("export_feedback", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Export functionality coming soon!")}
  end

  defp build_filter_opts(form) do
    []
    |> maybe_add(:date_from, form["date_from"])
    |> maybe_add(:date_to, form["date_to"])
    |> maybe_add(:satisfaction_level, form["satisfaction_level"], "all")
    |> maybe_add(:staff_helpful, form["staff_helpful"], "all")
    |> maybe_add(:search, form["search"])
  end

  defp maybe_add(opts, _key, nil), do: opts
  defp maybe_add(opts, _key, ""), do: opts
  defp maybe_add(opts, _key, "all"), do: opts

  defp maybe_add(opts, key, val) when is_binary(val) and byte_size(val) > 0,
    do: Keyword.put(opts, key, val)

  defp maybe_add(opts, _key, _), do: opts

  defp maybe_add(opts, _key, val, skip) when val == skip, do: opts
  defp maybe_add(opts, key, val, _skip), do: maybe_add(opts, key, val)

  defp count_active_filters(assigns) do
    [
      assigns.filter_date_from != "",
      assigns.filter_date_to != "",
      assigns.filter_satisfaction_level != "all",
      assigns.filter_staff_helpful != "all"
    ]
    |> Enum.count(& &1)
  end

  defp filter_chips(assigns) do
    [
      filter_chip(assigns.filter_date_from, "date_from", "From #{assigns.filter_date_from}"),
      filter_chip(assigns.filter_date_to, "date_to", "To #{assigns.filter_date_to}"),
      filter_chip(
        assigns.filter_satisfaction_level,
        "satisfaction_level",
        option_label(assigns.filter_satisfaction_level, @satisfaction_options),
        ["all"]
      ),
      filter_chip(
        assigns.filter_staff_helpful,
        "staff_helpful",
        option_label(assigns.filter_staff_helpful, @staff_helpful_options),
        ["all"]
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp option_label(value, options) do
    case Enum.find(options, fn {_label, v} -> v == value end) do
      {label, _v} -> label
      nil -> value
    end
  end

  defp str_trim(nil), do: ""
  defp str_trim(s) when is_binary(s), do: String.trim(s)
  defp str_trim(_), do: ""

  defp format_datetime(nil), do: "—"

  defp format_datetime(dt) do
    case dt do
      %DateTime{} -> Calendar.strftime(dt, "%Y-%m-%d %H:%M")
      _ -> to_string(dt)
    end
  end

  defp format_date(date) when is_nil(date), do: "—"
  defp format_date(%Date{} = d), do: Date.to_string(d)

  defp format_date(bin) when is_binary(bin) do
    case Date.from_iso8601(bin) do
      {:ok, d} -> Date.to_string(d)
      _ -> bin
    end
  end

  defp format_date(other), do: to_string(other)

  defp format_satisfaction_level(nil), do: "—"
  defp format_satisfaction_level("very_satisfied"), do: "Very Satisfied"
  defp format_satisfaction_level("satisfied"), do: "Satisfied"
  defp format_satisfaction_level("neutral"), do: "Neutral"
  defp format_satisfaction_level("dissatisfied"), do: "Dissatisfied"
  defp format_satisfaction_level("very_dissatisfied"), do: "Very Dissatisfied"
  defp format_satisfaction_level(other), do: other || "—"

  defp format_staff_helpful(nil), do: "—"
  defp format_staff_helpful("yes"), do: "Yes"
  defp format_staff_helpful("no"), do: "No"
  defp format_staff_helpful("other"), do: "Other"
  defp format_staff_helpful(other), do: other || "—"

  defp format_how_did_you_know(nil), do: "—"
  defp format_how_did_you_know(""), do: "—"

  defp format_how_did_you_know(raw) do
    raw
    |> String.split(~r/,\s*/)
    |> Enum.map(&format_how_did_you_know_item/1)
    |> Enum.join(", ")
  end

  defp format_how_did_you_know_item("billboard_flyers"), do: "Billboard, Flyers"
  defp format_how_did_you_know_item("medical_camp_radio"), do: "Medical Camp, Radio, Road Show"
  defp format_how_did_you_know_item("social_media"), do: "Social Media"
  defp format_how_did_you_know_item("referral"), do: "Referral"
  defp format_how_did_you_know_item("saw_hospital"), do: "Saw the Hospital"
  defp format_how_did_you_know_item("other"), do: "Other"
  defp format_how_did_you_know_item(s), do: s

  defp satisfaction_badge("very_satisfied"), do: "bg-green-100 text-green-800"
  defp satisfaction_badge("satisfied"), do: "bg-blue-100 text-blue-800"
  defp satisfaction_badge("neutral"), do: "bg-gray-100 text-gray-800"
  defp satisfaction_badge("dissatisfied"), do: "bg-yellow-100 text-yellow-800"
  defp satisfaction_badge("very_dissatisfied"), do: "bg-red-100 text-red-800"
  defp satisfaction_badge(_), do: "bg-gray-100 text-gray-800"

  defp service_rating_badge(r) when is_integer(r) and r >= 4, do: "bg-green-100 text-green-800"
  defp service_rating_badge(r) when is_integer(r) and r == 3, do: "bg-yellow-100 text-yellow-800"
  defp service_rating_badge(r) when is_integer(r) and r <= 2, do: "bg-red-100 text-red-800"
  defp service_rating_badge(_), do: "bg-gray-100 text-gray-800"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-8">
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
        <.page_header
          icon_path="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"
          title="Patient Feedback"
          subtitle="Search, filter and review patient feedback submissions."
        />

        <div class="flex flex-wrap items-center gap-3 mb-6">
          <form phx-change="apply_filters" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filter_search}
              placeholder="Search by name or suggestions"
            />
          </form>

          <.filter_drawer
            id="feedback-filters"
            title="Filter feedback"
            apply_event="apply_filters"
            clear_event="clear_filters"
            active_count={count_active_filters(assigns)}
          >
            <:group label="Date Range">
              <.date_range_fields
                from_name="filters[date_from]"
                to_name="filters[date_to]"
                from_value={@filter_date_from}
                to_value={@filter_date_to}
              />
            </:group>

            <:group label="Satisfaction and Staff">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Satisfaction</label>
                <select
                  name="filters[satisfaction_level]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <%= for {label, value} <- @satisfaction_options do %>
                    <option value={value} selected={@filter_satisfaction_level == value}>
                      {label}
                    </option>
                  <% end %>
                </select>
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Staff helpful</label>
                <select
                  name="filters[staff_helpful]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <%= for {label, value} <- @staff_helpful_options do %>
                    <option value={value} selected={@filter_staff_helpful == value}>{label}</option>
                  <% end %>
                </select>
              </div>
            </:group>

            <:chip
              :for={chip <- filter_chips(assigns)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>
        
    <!-- Stats -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div class="bg-blue-50 rounded-lg p-4 border border-blue-200">
            <div class="flex items-center">
              <Heroicons.icon name="document-text" type="outline" class="h-8 w-8 text-blue-600" />
              <div class="ml-3">
                <p class="text-sm font-medium text-blue-900">Total feedback</p>
                <p class="text-2xl font-bold text-blue-600">{length(@feedbacks)}</p>
              </div>
            </div>
          </div>
          <div class="bg-green-50 rounded-lg p-4 border border-green-200">
            <div class="flex items-center">
              <Heroicons.icon name="face-smile" type="outline" class="h-8 w-8 text-green-600" />
              <div class="ml-3">
                <p class="text-sm font-medium text-green-900">Satisfied / Very satisfied</p>
                <p class="text-2xl font-bold text-green-600">
                  {Enum.count(@feedbacks, &(&1.satisfaction_level in ["satisfied", "very_satisfied"]))}
                </p>
              </div>
            </div>
          </div>
          <div class="bg-slate-50 rounded-lg p-4 border border-purple-200">
            <div class="flex items-center">
              <Heroicons.icon name="hand-raised" type="outline" class="h-8 w-8 text-purple-600" />
              <div class="ml-3">
                <p class="text-sm font-medium text-purple-900">Staff helpful: Yes</p>
                <p class="text-2xl font-bold text-purple-600">
                  {Enum.count(@feedbacks, &(&1.staff_helpful == "yes"))}
                </p>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Table -->
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Submitted
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Satisfaction
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Service rating
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Staff helpful
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  How did you know
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for feedback <- @feedbacks do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="text-sm font-medium text-gray-900">
                      {feedback.name || "Anonymous"}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {format_datetime(feedback.inserted_at)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{satisfaction_badge(feedback.satisfaction_level)}"}>
                      {format_satisfaction_level(feedback.satisfaction_level)}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{service_rating_badge(feedback.service_quality_rating)}"}>
                      {if feedback.service_quality_rating,
                        do: "#{feedback.service_quality_rating}/5",
                        else: "—"}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {format_staff_helpful(feedback.staff_helpful)}
                  </td>
                  <td
                    class="px-6 py-4 max-w-[200px] truncate text-sm text-gray-600"
                    title={format_how_did_you_know(feedback.how_did_you_know)}
                  >
                    {format_how_did_you_know(feedback.how_did_you_know)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button
                      phx-click="view_feedback"
                      phx-value-id={feedback.id}
                      class="text-[#373896] hover:text-[#2a2a70] flex items-center gap-1"
                    >
                      <Heroicons.icon name="eye" type="outline" class="h-4 w-4" /> View
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>

          <.blank_state
            :if={length(@feedbacks) == 0}
            icon_path="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"
            title="No feedback found"
            description={
              if @filter_search != "" or count_active_filters(assigns) > 0,
                do: "No patient feedback matches your current filters.",
                else: "No patient feedback has been submitted yet."
            }
          >
            <:actions :if={@filter_search != "" or count_active_filters(assigns) > 0}>
              <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
                Clear filters
              </button>
            </:actions>
          </.blank_state>
        </div>
      </div>
      
    <!-- Detail modal -->
      <%= if @selected_feedback do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div class="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex justify-between items-center">
              <h3 class="text-lg font-semibold text-gray-900">
                Feedback — {@selected_feedback.name || "Anonymous"}
              </h3>
              <button phx-click="close_modal" class="text-gray-400 hover:text-gray-600">
                <Heroicons.icon name="x-mark" type="outline" class="h-6 w-6" />
              </button>
            </div>

            <div class="p-6 space-y-6">
              <div class="bg-gray-50 rounded-lg p-4">
                <h4 class="font-semibold text-gray-900 mb-3">Summary</h4>
                <div class="grid grid-cols-2 gap-4 text-sm">
                  <div><strong>Name:</strong> {@selected_feedback.name || "Anonymous"}</div>
                  <div>
                    <strong>Submitted:</strong> {format_datetime(@selected_feedback.inserted_at)}
                  </div>
                  <div>
                    <strong>Satisfaction:</strong> {format_satisfaction_level(
                      @selected_feedback.satisfaction_level
                    )}
                  </div>
                  <div>
                    <strong>Service rating:</strong> {if @selected_feedback.service_quality_rating,
                      do: "#{@selected_feedback.service_quality_rating}/5",
                      else: "—"}
                  </div>
                  <div>
                    <strong>Staff helpful:</strong> {format_staff_helpful(
                      @selected_feedback.staff_helpful
                    )}
                    <%= if @selected_feedback.staff_helpful == "other" and @selected_feedback.staff_helpful_other do %>
                      — {@selected_feedback.staff_helpful_other}
                    <% end %>
                  </div>
                  <div class="col-span-2">
                    <strong>How did you know about us:</strong> {format_how_did_you_know(
                      @selected_feedback.how_did_you_know
                    )}
                    <%= if @selected_feedback.how_did_you_know_other && String.contains?(@selected_feedback.how_did_you_know || "", "other") do %>
                      <span class="text-gray-600">— {@selected_feedback.how_did_you_know_other}</span>
                    <% end %>
                  </div>
                </div>
              </div>

              <%= if @selected_feedback.suggestions && String.trim(@selected_feedback.suggestions) != "" do %>
                <div class="bg-white border border-gray-200 rounded-lg p-4">
                  <h4 class="font-semibold text-gray-900 mb-2">Suggestions to improve</h4>
                  <p class="text-gray-700 whitespace-pre-wrap">{@selected_feedback.suggestions}</p>
                </div>
              <% end %>
              
    <!-- Legacy fields when present -->
              <%= if has_legacy_fields?(@selected_feedback) do %>
                <div class="bg-white border border-gray-200 rounded-lg p-4">
                  <h4 class="font-semibold text-gray-900 mb-3">Legacy information</h4>
                  <div class="grid grid-cols-2 gap-3 text-sm">
                    <%= if @selected_feedback.department do %>
                      <div>
                        <strong>Department:</strong> {String.upcase(@selected_feedback.department)}
                      </div>
                    <% end %>
                    <%= if @selected_feedback.visit_date do %>
                      <div>
                        <strong>Visit date:</strong> {format_date(@selected_feedback.visit_date)}
                      </div>
                    <% end %>
                    <%= if @selected_feedback.age do %>
                      <div><strong>Age:</strong> {@selected_feedback.age}</div>
                    <% end %>
                    <%= if @selected_feedback.gender do %>
                      <div>
                        <strong>Gender:</strong> {String.capitalize(@selected_feedback.gender)}
                      </div>
                    <% end %>
                    <%= if @selected_feedback.overall_satisfaction_rating do %>
                      <div>
                        <strong>Overall rating (legacy):</strong> {@selected_feedback.overall_satisfaction_rating}/5
                      </div>
                    <% end %>
                    <%= if @selected_feedback.liked_most do %>
                      <div class="col-span-2">
                        <strong>Liked most:</strong> {@selected_feedback.liked_most}
                      </div>
                    <% end %>
                    <%= if @selected_feedback.areas_to_improve do %>
                      <div class="col-span-2">
                        <strong>Areas to improve:</strong> {@selected_feedback.areas_to_improve}
                      </div>
                    <% end %>
                    <%= if @selected_feedback.other_comments do %>
                      <div class="col-span-2">
                        <strong>Other comments:</strong> {@selected_feedback.other_comments}
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp has_legacy_fields?(f) do
    f.department || f.visit_date || f.age || f.gender ||
      f.overall_satisfaction_rating || f.liked_most || f.areas_to_improve || f.other_comments
  end
end
