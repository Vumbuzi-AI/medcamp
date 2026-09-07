defmodule MedcampWeb.ProcurementComponents do
  @moduledoc """
  Shared UI building blocks for the procurement portals.
  """

  use Phoenix.Component

  import MedcampWeb.CoreComponents

  alias Phoenix.LiveView.JS

  attr :steps, :list, default: []
  attr :current, :any, default: nil
  attr :document_ids, :map, default: %{}

  # def pipeline_tracker(assigns) do
  #   ~H"""
  #   <div class="overflow-x-auto rounded-2xl border border-slate-200 bg-white px-4 py-5 shadow-sm">
  #     <ol class="flex min-w-max items-start gap-3">
  #       <%= for {step, index} <- Enum.with_index(@steps, 1) do %>
  #         <% key = pipeline_step_key(step) %>
  #         <% state = pipeline_step_state(@steps, @current, key) %>
  #         <% document_ref = Map.get(@document_ids, key) || Map.get(@document_ids, to_string(key)) %>

  #         <li class="flex items-center gap-3">
  #           <div class="flex flex-col items-center gap-2 text-center">
  #             <div class={pipeline_step_circle_classes(state)}>
  #               <Heroicons.icon :if={state == :done} name="check" type="solid" class="h-4 w-4" />
  #               <span :if={state != :done} class="text-xs font-semibold">{index}</span>
  #             </div>

  #             <div class="space-y-1">
  #               <.link
  #                 :if={is_binary(document_ref)}
  #                 navigate={document_ref}
  #                 class="text-xs font-semibold text-slate-700 hover:text-[#373896]"
  #               >
  #                 {pipeline_step_label(step)}
  #               </.link>
  #               <p :if={!is_binary(document_ref)} class="text-xs font-semibold text-slate-700">
  #                 {pipeline_step_label(step)}
  #               </p>
  #               <p class="text-[11px] uppercase tracking-[0.18em] text-slate-400">
  #                 {pipeline_step_caption(state)}
  #               </p>
  #             </div>
  #           </div>

  #           <div
  #             :if={index < length(@steps)}
  #             class={["mt-5 h-px w-12 rounded-full md:w-20", pipeline_step_line_classes(state)]}
  #           />
  #         </li>
  #       <% end %>
  #     </ol>
  #   </div>
  #   """
  # end

  def pipeline_tracker(assigns) do
    ~H"""
    <div />
    """
  end

  attr :current, :any, default: nil
  attr :progress, :map, default: %{}

  def registration_stepper(assigns) do
    steps = registration_steps()
    assigns = assign(assigns, :steps, steps)

    ~H"""
    <div class="rounded-2xl border border-slate-200 bg-white px-4 py-5 shadow-sm">
      <div class="flex items-center justify-between gap-2">
        <%= for {step, index} <- Enum.with_index(@steps, 1) do %>
          <% state = registration_step_state(step, @current, @progress) %>

          <div class="flex flex-1 items-center gap-2">
            <div class="flex flex-col items-center gap-2 text-center">
              <div class={registration_dot_classes(state)}>
                <Heroicons.icon :if={state == :done} name="check" type="solid" class="h-4 w-4" />
                <span :if={state != :done} class="text-xs font-semibold">{index}</span>
              </div>
              <span class="max-w-16 text-[11px] font-medium text-slate-600 md:max-w-none">
                {pipeline_step_label(step)}
              </span>
            </div>

            <div
              :if={index < length(@steps)}
              class={["hidden h-px flex-1 rounded-full md:block", registration_line_classes(state)]}
            />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :status, :any, required: true

  def status_badge(assigns) do
    status = normalize_status(assigns.status)
    {label, classes} = status_meta(status)
    assigns = assign(assigns, status: status, label: label, classes: classes)

    ~H"""
    <span class={["inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold", @classes]}>
      {@label}
    </span>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :sub, :string, default: nil

  def stat_card(assigns) do
    ~H"""
    <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">{@label}</p>
      <p class="mt-3 text-3xl font-semibold text-slate-900">{@value}</p>
      <p :if={@sub} class="mt-2 text-sm text-slate-500">{@sub}</p>
    </div>
    """
  end

  attr :rfqs, :list, default: []

  def deadline_alert(assigns) do
    next_rfq =
      assigns.rfqs
      |> Enum.reject(&is_nil(&1.quote_deadline))
      |> Enum.sort_by(& &1.quote_deadline, Date)
      |> List.first()

    assigns =
      assigns
      |> assign(:next_rfq, next_rfq)
      |> assign(:days_remaining, deadline_days(next_rfq))
      |> assign(:alert_classes, deadline_alert_classes(deadline_days(next_rfq)))
      |> assign(:alert_label, deadline_alert_label(deadline_days(next_rfq)))

    ~H"""
    <div :if={@next_rfq} class={["rounded-2xl border px-4 py-3 shadow-sm", @alert_classes]}>
      <div class="flex items-start gap-3">
        <Heroicons.icon name="clock" type="outline" class="mt-0.5 h-5 w-5" />
        <div class="space-y-1">
          <p class="text-sm font-semibold">{@alert_label}</p>
          <p class="text-sm">
            {@next_rfq.reference} closes on {Calendar.strftime(@next_rfq.quote_deadline, "%d %b %Y")}.
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :attachments, :list, default: []
  attr :class, :string, default: nil

  def attachment_gallery(assigns) do
    ~H"""
    <div class={["mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-3", @class]}>
      <div
        :for={attachment <- @attachments}
        class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"
      >
        <% kind = attachment_kind(attachment) %>
        <% url = safe_attachment_url(Map.get(attachment, :path) || Map.get(attachment, "path")) %>
        <% label = Map.get(attachment, :label) || Map.get(attachment, "label") || "Attachment" %>

        <div class="h-44 bg-slate-50">
          <.link :if={url && kind == :image} href={url} target="_blank" class="block h-44 w-full">
            <img src={url} alt={label} loading="lazy" class="h-44 w-full object-cover" />
          </.link>

          <object
            :if={url && kind == :pdf}
            data={pdf_embed_src(url)}
            type="application/pdf"
            class="h-44 w-full"
          >
            <div class="flex h-44 w-full items-center justify-center text-sm text-slate-600">
              PDF preview unavailable
            </div>
          </object>

          <div
            :if={url && kind not in [:image, :pdf]}
            class="flex h-44 w-full items-center justify-center text-slate-500"
          >
            <Heroicons.icon name="paper-clip" type="outline" class="h-6 w-6" />
          </div>

          <div :if={!url} class="flex h-44 items-center justify-center text-sm text-slate-500">
            Preview unavailable
          </div>
        </div>

        <div class="flex items-center justify-between gap-3 px-4 py-3">
          <p class="min-w-0 truncate text-sm font-semibold text-slate-700">{label}</p>
          <.link
            :if={url}
            href={url}
            target="_blank"
            class="shrink-0 text-sm font-semibold text-[#373896] hover:underline"
          >
            Open
          </.link>
        </div>
      </div>
    </div>
    """
  end

  attr :type, :string, required: true
  attr :document, :map, default: nil
  attr :upload_ref, :any, default: nil

  def document_slot(assigns) do
    upload_entry = current_upload_entry(assigns.upload_ref)
    upload_errors = upload_entry && List.wrap(Map.get(upload_entry, :errors, []))
    assigns = assign(assigns, :upload_entry, upload_entry)
    assigns = assign(assigns, :upload_errors, upload_errors)

    ~H"""
    <div class={[
      "rounded-2xl border p-4 shadow-sm",
      document_slot_classes(@document, @upload_entry, @upload_errors)
    ]}>
      <div class="flex items-start justify-between gap-3">
        <div>
          <p class="text-sm font-semibold text-slate-900">{humanize_procurement_label(@type)}</p>
          <p class="mt-1 text-xs text-slate-500">
            {document_slot_caption(@document, @upload_entry, @upload_errors)}
          </p>
        </div>

        <.status_badge
          :if={@document}
          status={
            if(Map.get(@document, :verified) || Map.get(@document, "verified"),
              do: :approved,
              else: :pending
            )
          }
        />
      </div>

      <div :if={@upload_entry && Enum.empty?(@upload_errors)} class="mt-4 space-y-2">
        <div class="flex items-center justify-between text-sm text-slate-600">
          <span>{Map.get(@upload_entry, :client_name, "Uploading...")}</span>
          <span>{Map.get(@upload_entry, :progress, 0)}%</span>
        </div>
        <div class="h-2 rounded-full bg-slate-200">
          <div
            class="h-2 rounded-full bg-[#373896] transition-all"
            style={"width: #{Map.get(@upload_entry, :progress, 0)}%"}
          />
        </div>
      </div>

      <div :if={@document} class="mt-4 rounded-xl bg-white/70 px-3 py-2 text-sm text-slate-700">
        {Map.get(@document, :file_name) || Map.get(@document, "file_name") ||
          Map.get(@document, :original_filename) || Map.get(@document, "original_filename") ||
          "Document uploaded"}
      </div>

      <div :if={@upload_errors && @upload_errors != []} class="mt-4 text-sm text-rose-700">
        Upload failed. Please review the selected file and try again.
      </div>
    </div>
    """
  end

  defp attachment_kind(attachment) do
    ext =
      (Map.get(attachment, :label) || Map.get(attachment, "label") || "")
      |> Path.extname()
      |> case do
        "" ->
          (Map.get(attachment, :path) || Map.get(attachment, "path") || "")
          |> Path.extname()

        value ->
          value
      end
      |> String.downcase()

    cond do
      ext in ~w(.png .jpg .jpeg .gif .webp .svg) -> :image
      ext == ".pdf" -> :pdf
      true -> :other
    end
  end

  defp safe_attachment_url(url) when is_binary(url) do
    url = String.trim(url)

    if String.starts_with?(url, ["/", "http://", "https://"]) do
      url
    else
      nil
    end
  end

  defp safe_attachment_url(_), do: nil

  defp pdf_embed_src(nil), do: nil

  defp pdf_embed_src(url) do
    if String.contains?(url, "#") do
      url
    else
      url <> "#toolbar=0&navpanes=0&scrollbar=0"
    end
  end

  attr :score, :any, required: true

  def score_bar(assigns) do
    score = clamp_percentage(assigns.score)
    assigns = assign(assigns, :score_value, score)

    ~H"""
    <div class="flex items-center gap-3">
      <div class="h-2.5 flex-1 rounded-full bg-slate-200">
        <div
          class="h-2.5 rounded-full bg-gradient-to-r from-[#373896] to-[#6667ab]"
          style={"width: #{@score_value}%"}
        />
      </div>
      <span class="w-10 text-right text-sm font-semibold text-slate-700">{@score_value}%</span>
    </div>
    """
  end

  attr :eyebrow, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :cancel_path, :string, required: true
  attr :max_width, :string, default: "max-w-6xl"
  slot :actions
  slot :inner_block, required: true

  def portal_form_shell(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="rounded-xl border border-slate-200/80 bg-white px-6 py-4 shadow-sm">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="space-y-1">
            <p class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
              {@eyebrow}
            </p>
            <h1 class="text-xl font-semibold text-slate-900">{@title}</h1>
            <p :if={@subtitle} class="max-w-3xl text-sm leading-6 text-slate-500">{@subtitle}</p>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            {render_slot(@actions)}

            <.link
              navigate={@cancel_path}
              class="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
            >
              <Heroicons.icon name="x-mark" type="outline" class="h-4 w-4" /> Close
            </.link>
          </div>
        </div>
      </div>

      <div class="rounded-[1.75rem] border border-[#d2d3ff] bg-[#f8f8ff] p-3 shadow-sm sm:p-5">
        <div class={[
          "mx-auto w-full rounded-[1.75rem] border border-slate-200 bg-white p-5 shadow-xl shadow-slate-900/5 sm:p-6",
          @max_width
        ]}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :supplier, :map, required: true
  attr :on_remove, :any, default: nil
  attr :rest, :global

  def supplier_chip(assigns) do
    ~H"""
    <span class="inline-flex items-center gap-2 rounded-full border border-[#d2d3ff] bg-[#f0f0ff] px-3 py-1.5 text-sm text-[#373896]">
      <span class="font-medium">
        {Map.get(@supplier, :legal_name) || Map.get(@supplier, "legal_name") ||
          Map.get(@supplier, :name) || Map.get(@supplier, "name") || "Supplier"}
      </span>
      <button
        :if={@on_remove}
        type="button"
        phx-click={@on_remove}
        phx-value-id={Map.get(@supplier, :id) || Map.get(@supplier, "id")}
        class="rounded-full p-1 transition hover:bg-[#e7e7ff]"
        {@rest}
      >
        <Heroicons.icon name="x-mark" type="solid" class="h-4 w-4" />
      </button>
    </span>
    """
  end

  attr :item, :map, required: true
  attr :on_change, :any, required: true

  def condition_toggle(assigns) do
    current = current_condition(assigns.item)
    assigns = assign(assigns, :current_condition, current)

    ~H"""
    <div class="inline-flex rounded-full border border-slate-200 bg-slate-100 p-1">
      <%= for {label, value} <- [{"Accept", "accepted"}, {"Partial", "partial"}, {"Reject", "rejected"}] do %>
        <button
          type="button"
          phx-click={@on_change}
          phx-value-id={Map.get(@item, :id) || Map.get(@item, "id")}
          phx-value-condition={value}
          class={[
            "rounded-full px-3 py-1.5 text-xs font-semibold transition",
            condition_toggle_classes(@current_condition, value)
          ]}
        >
          {label}
        </button>
      <% end %>
    </div>
    """
  end

  attr :summary, :map, default: %{}

  def grn_summary_strip(assigns) do
    assigns =
      assigns
      |> assign(:accepted, map_value(assigns.summary, :accepted))
      |> assign(:partial, map_value(assigns.summary, :partial))
      |> assign(:quantity, map_value(assigns.summary, :quantity))
      |> assign(:value, map_value(assigns.summary, :value))

    ~H"""
    <div class="grid gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-4">
      <.summary_cell label="Accepted" value={@accepted} accent="text-emerald-700" />
      <.summary_cell label="Partial" value={@partial} accent="text-amber-700" />
      <.summary_cell label="Quantity" value={@quantity} accent="text-slate-800" />
      <.summary_cell label="Value" value={@value} accent="text-[#373896]" />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :body, :string, required: true
  attr :confirm_label, :string, default: "Confirm"
  attr :on_confirm, :any, default: %JS{}

  def confirmation_modal(assigns) do
    ~H"""
    <.modal id={@id}>
      <div class="space-y-4">
        <div class="space-y-2">
          <p class="text-sm font-semibold uppercase tracking-[0.25em] text-rose-500">
            Confirm action
          </p>
          <h3 class="text-2xl font-semibold text-slate-900">{@title}</h3>
          <p class="text-sm leading-6 text-slate-600">{@body}</p>
        </div>

        <div class="flex justify-end gap-3">
          <button
            type="button"
            phx-click={hide_modal(@id)}
            class="rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
          >
            Cancel
          </button>
          <button
            type="button"
            phx-click={@on_confirm}
            class="rounded-xl bg-rose-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-rose-700"
          >
            {@confirm_label}
          </button>
        </div>
      </div>
    </.modal>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :accent, :string, default: "text-slate-800"

  defp summary_cell(assigns) do
    ~H"""
    <div class="rounded-xl bg-slate-50 px-4 py-3">
      <p class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-400">{@label}</p>
      <p class={["mt-2 text-2xl font-semibold", @accent]}>{@value}</p>
    </div>
    """
  end

  defp registration_steps do
    [:company, :address, :contact, :bank, :documents, :directors, :review]
  end

  defp pipeline_step_key(step) when is_map(step),
    do: Map.get(step, :key) || Map.get(step, "key") || pipeline_step_label(step)

  defp pipeline_step_key(step) when is_atom(step), do: step
  defp pipeline_step_key(step) when is_binary(step), do: step
  defp pipeline_step_key(step), do: inspect(step)

  defp pipeline_step_label(step) when is_map(step),
    do:
      Map.get(step, :label) || Map.get(step, "label") ||
        humanize_procurement_label(pipeline_step_key(step))

  defp pipeline_step_label(step), do: humanize_procurement_label(step)

  defp registration_step_state(step, current, progress) do
    cond do
      progress[step] in [true, :done, "done"] -> :done
      to_string(step) == to_string(current) -> :current
      true -> :future
    end
  end

  defp registration_dot_classes(:done),
    do: "flex h-9 w-9 items-center justify-center rounded-full bg-[#6667ab] text-white"

  defp registration_dot_classes(:current),
    do:
      "flex h-9 w-9 items-center justify-center rounded-full border-2 border-[#373896] bg-white text-[#373896]"

  defp registration_dot_classes(:future),
    do:
      "flex h-9 w-9 items-center justify-center rounded-full border border-slate-300 bg-slate-50 text-slate-400"

  defp registration_line_classes(:done), do: "bg-[#6667ab]"
  defp registration_line_classes(_), do: "bg-slate-200"

  defp status_meta(nil), do: {"Unknown", "bg-slate-100 text-slate-700"}

  defp status_meta(status) do
    case status do
      "approved" -> {"Approved", "bg-emerald-100 text-emerald-700"}
      "accepted" -> {"Accepted", "bg-emerald-100 text-emerald-700"}
      "finalised" -> {"Finalised", "bg-emerald-100 text-emerald-700"}
      "received" -> {"Received", "bg-emerald-100 text-emerald-700"}
      "sent" -> {"Sent", "bg-sky-100 text-sky-700"}
      "submitted" -> {"Submitted", "bg-sky-100 text-sky-700"}
      "under_review" -> {"Under review", "bg-amber-100 text-amber-800"}
      "pending" -> {"Pending", "bg-amber-100 text-amber-800"}
      "pending_review" -> {"Pending review", "bg-amber-100 text-amber-800"}
      "pending_grn" -> {"Pending GRN", "bg-amber-100 text-amber-800"}
      "pending_approval" -> {"Pending approval", "bg-amber-100 text-amber-800"}
      "draft" -> {"Draft", "bg-slate-100 text-slate-700"}
      "acknowledged" -> {"Acknowledged", "bg-violet-100 text-violet-700"}
      "grn_confirmed" -> {"GRN confirmed", "bg-teal-100 text-teal-700"}
      "flagged" -> {"Flagged", "bg-rose-100 text-rose-700"}
      "rejected" -> {"Rejected", "bg-rose-100 text-rose-700"}
      "cancelled" -> {"Cancelled", "bg-rose-100 text-rose-700"}
      other -> {humanize_procurement_label(other), "bg-slate-100 text-slate-700"}
    end
  end

  defp deadline_days(nil), do: nil
  defp deadline_days(%{quote_deadline: nil}), do: nil
  defp deadline_days(%{quote_deadline: deadline}), do: Date.diff(deadline, Date.utc_today())

  defp deadline_alert_classes(days) when is_integer(days) and days <= 2,
    do: "border-rose-200 bg-rose-50 text-rose-700"

  defp deadline_alert_classes(days) when is_integer(days) and days <= 7,
    do: "border-amber-200 bg-amber-50 text-amber-800"

  defp deadline_alert_classes(_),
    do: "border-emerald-200 bg-emerald-50 text-emerald-700"

  defp deadline_alert_label(days) when is_integer(days) and days < 0, do: "Deadline passed"
  defp deadline_alert_label(0), do: "Closes today"
  defp deadline_alert_label(1), do: "Closes tomorrow"
  defp deadline_alert_label(days) when is_integer(days) and days <= 7, do: "Deadline approaching"
  defp deadline_alert_label(_), do: "Upcoming deadline"

  defp current_upload_entry(nil), do: nil
  defp current_upload_entry(%{entries: [entry | _]}), do: entry
  defp current_upload_entry(%{entries: []}), do: nil
  defp current_upload_entry(_), do: nil

  defp document_slot_classes(_document, entry, errors) when not is_nil(entry) and errors == [],
    do: "border-[#d2d3ff] bg-[#f0f0ff]"

  defp document_slot_classes(_document, _entry, errors) when is_list(errors) and errors != [],
    do: "border-rose-200 bg-rose-50"

  defp document_slot_classes(document, _entry, _errors) when not is_nil(document),
    do: "border-slate-200 bg-slate-50"

  defp document_slot_classes(_, _, _), do: "border-dashed border-slate-300 bg-white"

  defp document_slot_caption(_document, entry, errors) when not is_nil(entry) and errors == [],
    do: "Upload in progress"

  defp document_slot_caption(_document, _entry, errors) when is_list(errors) and errors != [],
    do: "Something went wrong while uploading"

  defp document_slot_caption(document, _entry, _errors) when not is_nil(document),
    do: "Document uploaded"

  defp document_slot_caption(_, _, _), do: "No file uploaded yet"

  defp clamp_percentage(value) when is_integer(value), do: value |> min(100) |> max(0)
  defp clamp_percentage(value) when is_float(value), do: value |> round() |> clamp_percentage()
  defp clamp_percentage(%Decimal{} = value), do: value |> Decimal.to_float() |> clamp_percentage()

  defp clamp_percentage(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> clamp_percentage(int)
      :error -> 0
    end
  end

  defp clamp_percentage(_), do: 0

  defp current_condition(item) do
    Map.get(item, :condition) || Map.get(item, "condition") ||
      Map.get(item, :overall_condition) || Map.get(item, "overall_condition") || "accepted"
  end

  defp condition_toggle_classes(current, value) when current == value,
    do: "bg-white text-slate-900 shadow-sm"

  defp condition_toggle_classes(_, "accepted"), do: "text-emerald-700 hover:text-emerald-800"
  defp condition_toggle_classes(_, "partial"), do: "text-amber-700 hover:text-amber-800"
  defp condition_toggle_classes(_, _), do: "text-rose-700 hover:text-rose-800"

  defp map_value(map, key) do
    Map.get(map, key) || Map.get(map, to_string(key)) || 0
  end

  defp normalize_status(status) when is_atom(status), do: Atom.to_string(status)
  defp normalize_status(status) when is_binary(status), do: status
  defp normalize_status(_), do: nil

  defp humanize_procurement_label(value) when is_atom(value),
    do: value |> Atom.to_string() |> humanize_procurement_label()

  defp humanize_procurement_label(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize_procurement_label(value), do: inspect(value)
end
