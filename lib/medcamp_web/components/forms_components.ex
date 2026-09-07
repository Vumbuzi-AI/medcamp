defmodule MedcampWeb.FormsComponents do
  use Phoenix.Component

  alias Medcamp.PatientFormRecords.PatientFormRecord

  import MedcampWeb.CoreComponents, only: [icon: 1]

  @doc """
  Official GHCE logo banner header — horizontal strip with coloured background.
  Used by sick leave, payment receipt, and similar forms.
  """
  def form_header_banner(assigns) do
    ~H"""
    <div class="bg-[#c8cef0] px-8 py-5 flex items-center gap-5">
      <img src="/images/logo.png" alt="GHCE Logo" class="h-16 w-auto shrink-0" />
      <div>
        <p class="text-xs font-bold text-[#373896] uppercase tracking-widest">GHCE</p>
        <h2 class="text-lg font-extrabold text-[#373896] uppercase tracking-wide leading-tight">
          Glocal Healthcare Centre of Excellence
        </h2>
        <p class="text-xs text-[#373896]/70 italic">Global Standards, Local Care</p>
      </div>
    </div>
    """
  end

  @doc """
  Official GHCE logo centered header — stacked logo + org name + optional form title.
  Used by most printed forms. Pass `title` to show a form title below the org name.
  Features green border and professional centered layout matching GHCE branding.
  """
  attr :title, :string, default: ""

  def form_header_centered(assigns) do
    ~H"""
    <div class="flex flex-col items-center text-center mb-8  rounded-3xl py-8 px-6 bg-gradient-to-b from-gray-50 to-white print:border-gray-300">
      <img src="/images/logo.png" alt="GHCE Logo" class="h-24 w-auto mb-4" />
      <h2 class="text-lg font-bold text-[#373896] uppercase tracking-widest leading-tight">
        Glocal Healthcare Centre of Excellence
      </h2>
      <p class="text-sm text-[#373896]/60 italic font-medium mt-2">Global Standards, Local Care</p>
      <%= if @title != "" do %>
        <h1 class="text-xl font-bold text-[#373896] mt-4 uppercase tracking-wide">{@title}</h1>
      <% end %>
    </div>
    """
  end

  @doc """
  Official GHCE logo inline header — horizontal with logo + org name + subtitle.
  Used by patient referral and similar forms with a side-by-side layout.
  """
  attr :subtitle, :string, default: ""

  def form_header_inline(assigns) do
    ~H"""
    <div class="flex items-center gap-4 mb-8 border-b border-gray-200 pb-6">
      <img src="/images/logo.png" alt="GHCE Logo" class="h-14 w-auto shrink-0" />
      <div>
        <h2 class="text-base font-bold text-[#373896] uppercase tracking-wide">
          Glocal Healthcare Centre of Excellence
        </h2>
        <%= if @subtitle != "" do %>
          <h1 class="text-xl font-bold text-gray-900">{@subtitle}</h1>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Interactive e-signature pad backed by the SignaturePad JS hook.
  Each pad on a page must have a unique `id`.
  """
  attr :id, :string, required: true
  attr :label, :string, default: "Signature"
  attr :name, :string, default: nil
  attr :value, :string, default: ""

  def signature_pad(assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> assigns.id end)
      |> assign_new(:value, fn -> "" end)

    ~H"""
    <div class="space-y-1.5">
      <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide">
        {@label}
      </label>
      <div
        id={@id}
        phx-hook="SignaturePad"
        class="relative border border-gray-300 rounded-lg overflow-hidden bg-white group"
      >
        <canvas class="w-full h-24 touch-none cursor-crosshair block"></canvas>
        <input type="hidden" name={@name} value={@value} />
        <div class="absolute top-1.5 right-1.5 flex gap-1 print:hidden opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            type="button"
            data-undo
            class="px-2 py-0.5 text-xs bg-white border border-gray-200 rounded text-gray-500 hover:bg-gray-50 shadow-sm"
          >
            Undo
          </button>
          <button
            type="button"
            data-clear
            class="px-2 py-0.5 text-xs bg-white border border-gray-200 rounded text-red-400 hover:bg-red-50 shadow-sm"
          >
            Clear
          </button>
        </div>
        <p class="absolute bottom-1.5 left-2 text-[10px] text-gray-300 pointer-events-none print:hidden">
          Draw signature above
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Official GHC rectangular stamp — matches the physical ink stamp exactly.
  Double-border rectangle with hospital name and contact details.
  """
  def official_stamp(assigns) do
    ~H"""
    <div class="space-y-1.5">
      <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide">
        Official Stamp
      </label>
      <div class="select-none w-52">
        <svg viewBox="0 0 210 140" xmlns="http://www.w3.org/2000/svg" class="w-full h-auto">
          <rect
            x="2"
            y="2"
            width="206"
            height="136"
            rx="3"
            ry="3"
            fill="white"
            stroke="#1e3a8a"
            stroke-width="2.5"
          />
          <rect
            x="7"
            y="7"
            width="196"
            height="126"
            rx="2"
            ry="2"
            fill="none"
            stroke="#1e3a8a"
            stroke-width="1.5"
          />

          <text
            x="105"
            y="30"
            text-anchor="middle"
            font-family="Arial, Helvetica, sans-serif"
            font-size="13"
            font-weight="800"
            fill="#1e3a8a"
            letter-spacing="0.5"
          >
            GLOCAL HEALTHCARE
          </text>
          <text
            x="105"
            y="46"
            text-anchor="middle"
            font-family="Arial, Helvetica, sans-serif"
            font-size="13"
            font-weight="800"
            fill="#1e3a8a"
            letter-spacing="0.5"
          >
            CENTRE OF EXCELLENCE
          </text>

          <line x1="18" y1="52" x2="192" y2="52" stroke="#1e3a8a" stroke-width="1" />

          <text
            x="105"
            y="66"
            text-anchor="middle"
            font-family="Arial, Helvetica, sans-serif"
            font-size="9"
            fill="#1e3a8a"
          >
            P.O. Box 3243 - 00200, Nairobi
          </text>
          <text
            x="105"
            y="80"
            text-anchor="middle"
            font-family="Arial, Helvetica, sans-serif"
            font-size="9"
            fill="#1e3a8a"
          >
            T: +254 (20) 2385270 / 2318414
          </text>
          <text
            x="105"
            y="94"
            text-anchor="middle"
            font-family="Arial, Helvetica, sans-serif"
            font-size="9"
            fill="#1e3a8a"
          >
            M: +254 710 122252 / 735 965168
          </text>
          <text
            x="105"
            y="108"
            text-anchor="middle"
            font-family="Arial, Helvetica, sans-serif"
            font-size="9"
            fill="#1e3a8a"
          >
            E: info@glocalhealthcentre.org
          </text>
        </svg>
      </div>
    </div>
    """
  end

  @doc """
  Renders a read-only preview of a saved patient form record with print actions.
  """
  attr :record, :map, required: true
  attr :patient, :map, required: true
  attr :back_path, :string, required: true
  attr :save_event, :string, required: true
  attr :save_target, :any, default: nil

  def saved_form_preview(assigns) do
    assigns =
      assigns
      |> assign(:data, stringify_keys(assigns.record.form_data || %{}))
      |> assign(:patient_name, patient_display_name(assigns.patient))
      |> assign(:saved_at, Calendar.strftime(assigns.record.inserted_at, "%d %b %Y %H:%M"))

    ~H"""
    <div class="max-w-4xl mx-auto">
      <div class="flex items-center justify-between mb-6 print:hidden">
        <.link
          navigate={@back_path}
          class="flex items-center gap-1 text-sm text-gray-500 hover:text-[#373896]"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Form Records
        </.link>
        <button
          type="button"
          onclick="window.print()"
          class="flex items-center gap-2 px-4 py-2 bg-[#373896] text-white rounded-lg text-sm font-medium hover:bg-[#2d2d7a] transition-colors"
        >
          <.icon name="hero-printer" class="w-4 h-4" /> Print Form
        </button>
      </div>

      <div class="bg-white border border-gray-200 rounded-xl shadow-sm p-8 print:shadow-none print:border-none print:p-0">
        <%= case @record.form_type do %>
          <% "dama" -> %>
            <.saved_dama_preview data={@data} patient_name={@patient_name} />
          <% "lab_request" -> %>
            <.saved_lab_request_preview data={@data} patient_name={@patient_name} />
          <% "discharge_summary" -> %>
            <.saved_discharge_summary_preview data={@data} patient_name={@patient_name} />
          <% "radiology_request" -> %>
            <.saved_radiology_request_preview data={@data} patient_name={@patient_name} />
          <% "prescription_sheet" -> %>
            <.saved_prescription_sheet_preview data={@data} patient_name={@patient_name} />
          <% "sick_leave" -> %>
            <.saved_sick_leave_preview data={@data} patient_name={@patient_name} />
          <% "surgical_consent" -> %>
            <.saved_surgical_consent_preview data={@data} patient_name={@patient_name} />
          <% "blood_transfusion_consent" -> %>
            <.saved_blood_transfusion_consent_preview data={@data} patient_name={@patient_name} />
          <% "hiv_testing_consent" -> %>
            <.saved_hiv_testing_consent_preview data={@data} patient_name={@patient_name} />
          <% "medical_report" -> %>
            <.saved_medical_report_preview data={@data} patient_name={@patient_name} />
          <% "patient_referral" -> %>
            <.saved_patient_referral_preview data={@data} patient_name={@patient_name} />
          <% "payment_receipt" -> %>
            <.saved_payment_receipt_preview data={@data} patient_name={@patient_name} />
          <% _ -> %>
            <.generic_saved_details_preview record={@record} saved_at={@saved_at} />
        <% end %>
      </div>

      <.saved_form_editor
        record={@record}
        data={@data}
        save_event={@save_event}
        save_target={@save_target}
      />
    </div>
    """
  end

  attr :record, :map, required: true
  attr :data, :map, required: true
  attr :save_event, :string, required: true
  attr :save_target, :any, default: nil

  def saved_form_editor(assigns) do
    assigns =
      assigns
      |> assign(:editable_entries, editable_entries(assigns.record.form_type, assigns.data))
      |> assign(:signature_fields, signature_fields(assigns.record.form_type))

    ~H"""
    <section class="mt-8 rounded-xl border border-gray-200 bg-white p-6 shadow-sm print:hidden">
      <div class="mb-6">
        <h2 class="text-base font-semibold text-gray-900">Edit Saved Form</h2>
        <p class="mt-1 text-sm text-gray-500">
          Update the saved details, add signatures, then print the preview above.
        </p>
      </div>

      <form phx-submit={@save_event} phx-target={@save_target} class="space-y-6">
        <input type="hidden" name="record_id" value={@record.id} />

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <%= for entry <- @editable_entries do %>
            <div class={if entry.multiline, do: "md:col-span-2", else: ""}>
              <label class="mb-1 block text-sm font-medium text-gray-700">{entry.label}</label>

              <%= case input_kind(entry.value, entry.multiline) do %>
                <% :textarea -> %>
                  <textarea
                    name={"patient_form_record[form_data][#{entry.key}]"}
                    rows="4"
                    class="w-full rounded-lg border border-gray-300 p-3 text-sm focus:border-[#6667ab] outline-none"
                  >{entry.value}</textarea>
                <% :date -> %>
                  <input
                    type="date"
                    name={"patient_form_record[form_data][#{entry.key}]"}
                    value={entry.value}
                    class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                  />
                <% :datetime_local -> %>
                  <input
                    type="datetime-local"
                    name={"patient_form_record[form_data][#{entry.key}]"}
                    value={entry.value}
                    class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                  />
                <% :time -> %>
                  <input
                    type="time"
                    name={"patient_form_record[form_data][#{entry.key}]"}
                    value={entry.value}
                    class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                  />
                <% _ -> %>
                  <input
                    type="text"
                    name={"patient_form_record[form_data][#{entry.key}]"}
                    value={entry.value}
                    class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                  />
              <% end %>
            </div>
          <% end %>
        </div>

        <%= if @signature_fields != [] do %>
          <div class="border-t border-gray-200 pt-6">
            <h3 class="text-sm font-semibold uppercase tracking-wide text-gray-700">Signatures</h3>
            <div class="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
              <%= for {field, label} <- @signature_fields do %>
                <.signature_pad
                  id={"saved-record-#{@record.id}-#{field}"}
                  name={"patient_form_record[form_data][#{field}]"}
                  label={label}
                  value={Map.get(@data, field, "")}
                />
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="flex justify-end border-t border-gray-200 pt-4">
          <button
            type="submit"
            class="inline-flex items-center gap-2 rounded-lg bg-[#373896] px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-[#2d2d7a]"
          >
            <.icon name="hero-check" class="h-4 w-4" /> Save Changes
          </button>
        </div>
      </form>
    </section>
    """
  end

  attr :data, :map, required: true
  attr :patient_name, :string, default: ""

  def saved_dama_preview(assigns) do
    ~H"""
    <.form_header_centered title="Discharge Against Medical Advice (DAMA) Form" />

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
      <div>
        <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
          Hospital / Clinic Name
        </label>
        <.preview_inline_input value="Glocal Healthcare Centre of Excellence" />
      </div>
      <div>
        <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
          Address / Contact
        </label>
        <.preview_inline_input value="P.O. Box 3243 - 00200, Nairobi | +254 710 122252" />
      </div>
    </div>

    <section class="mb-8">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4 flex items-center gap-2">
        <span class="w-1 h-4 bg-[#373896] rounded-full inline-block"></span> Patient Information
      </h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-5">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Patient Name
          </label>
          <.preview_inline_input value={coalesce(@data["patient_name"], @patient_name)} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Hospital / MRN Number
          </label>
          <.preview_inline_input value={@data["mrn_number"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date of Birth / Age
          </label>
          <.preview_inline_input value={@data["dob_age"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Gender
          </label>
          <div class="flex gap-6 mt-2">
            <.preview_radio label="Male" checked={selected?(@data, "gender", "male")} />
            <.preview_radio label="Female" checked={selected?(@data, "gender", "female")} />
            <.preview_radio label="Other" checked={selected?(@data, "gender", "other")} />
          </div>
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Ward / Unit
          </label>
          <.preview_inline_input value={coalesce(@data["ward_unit"], @data["ward"])} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Attending Physician
          </label>
          <.preview_inline_input value={
            coalesce(@data["attending_physician"], @data["attending_staff"])
          } />
        </div>
        <div class="md:col-span-2">
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date &amp; Time of Admission
          </label>
          <.preview_inline_input value={format_field(@data["admission_datetime"])} />
        </div>
      </div>
    </section>

    <section class="mb-8">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4 flex items-center gap-2">
        <span class="w-1 h-4 bg-[#373896] rounded-full inline-block"></span>
        Statement of Refusal of Medical Advice
      </h2>
      <div class="bg-gray-50 rounded-lg p-4 text-sm text-gray-700 leading-relaxed mb-4">
        I,
        <span class="inline-block min-w-52 mx-1 align-middle">
          <.preview_inline_input value={
            coalesce(@data["declaration_name"], @data["patient_name"], @patient_name)
          } />
        </span>
        (patient / legal guardian), confirm that I have been informed of my medical condition and the recommended treatment, investigations, and/or continued hospitalization.
      </div>
      <div class="bg-gray-50 rounded-lg p-4 text-sm text-gray-700 leading-relaxed">
        I understand that my treating physician has advised me not to leave the hospital and has explained the possible risks of doing so. Despite this, I voluntarily choose to leave the hospital and refuse further medical care.
      </div>
    </section>

    <section class="mb-8">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4 flex items-center gap-2">
        <span class="w-1 h-4 bg-rose-500 rounded-full inline-block"></span> Risks Explained
      </h2>
      <div class="bg-rose-50 rounded-lg p-4 text-sm text-rose-800 leading-relaxed">
        I acknowledge that refusing medical advice may result in worsening of my condition, serious complications, permanent disability, or death.
      </div>
    </section>

    <section class="mb-8">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-3 flex items-center gap-2">
        <span class="w-1 h-4 bg-gray-400 rounded-full inline-block"></span>
        Reason for Leaving Against Medical Advice
      </h2>
      <.preview_textarea
        value={@data["reason_for_leaving"]}
        rows="5"
        class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
      />
    </section>

    <section class="mb-8">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4 flex items-center gap-2">
        <span class="w-1 h-4 bg-[#373896] rounded-full inline-block"></span>
        Acknowledgment and Release
      </h2>
      <div class="bg-gray-50 rounded-lg p-4 text-sm text-gray-700 leading-relaxed">
        I accept full responsibility for my decision and release the hospital, physicians, nurses, and staff from any liability arising from my decision to leave against medical advice.
      </div>
    </section>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-8 pt-6 border-t border-gray-200">
      <section>
        <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-5 flex items-center gap-2">
          <span class="w-1 h-4 bg-[#373896] rounded-full inline-block"></span>
          Patient / Guardian Declaration
        </h2>
        <div class="space-y-5">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Name
            </label>
            <.preview_inline_input value={
              coalesce(@data["declaration_name"], @data["patient_name"], @patient_name)
            } />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Relationship (if applicable)
            </label>
            <.preview_inline_input value={@data["declaration_relationship"]} />
          </div>
          <.preview_signature_line label="Signature" value={@data["declaration_signature"]} />
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Date &amp; Time
            </label>
            <.preview_inline_input value={format_field(@data["declaration_datetime"])} />
          </div>
        </div>
      </section>

      <section>
        <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-5 flex items-center gap-2">
          <span class="w-1 h-4 bg-gray-500 rounded-full inline-block"></span> Witness / Medical Staff
        </h2>
        <div class="space-y-5">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Name &amp; Designation
            </label>
            <.preview_inline_input value={@data["witness_name_designation"]} />
          </div>
          <.preview_signature_line label="Signature" value={@data["witness_signature"]} />
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Date &amp; Time
            </label>
            <.preview_inline_input value={format_field(@data["witness_datetime"])} />
          </div>
        </div>
      </section>
    </div>
    """
  end

  def saved_lab_request_preview(assigns) do
    ~H"""
    <.form_header_centered title="Laboratory Request Form" />

    <section class="mb-6">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Patient Name
          </label>
          <.preview_inline_input value={coalesce(@data["patient_name"], @patient_name)} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Age
          </label>
          <.preview_inline_input value={@data["age"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Gender
          </label>
          <div class="flex gap-6 mt-2">
            <.preview_radio label="Male" checked={selected?(@data, "gender", "male")} />
            <.preview_radio label="Female" checked={selected?(@data, "gender", "female")} />
            <.preview_radio label="Other" checked={selected?(@data, "gender", "other")} />
          </div>
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Hospital No.
          </label>
          <.preview_inline_input value={@data["hospital_no"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date
          </label>
          <.preview_inline_input value={format_field(@data["date"])} />
        </div>
      </div>
    </section>

    <section class="mb-6">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4">
        Clinician Information
      </h2>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Clinician Name
          </label>
          <.preview_inline_input value={@data["clinician_name"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Designation
          </label>
          <.preview_inline_input value={@data["clinician_designation"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Tel
          </label>
          <.preview_inline_input value={coalesce(@data["clinician_tel"], @data["urgency"])} />
        </div>
      </div>
    </section>

    <section class="mb-6">
      <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
        Clinical Information
      </label>
      <.preview_textarea
        value={coalesce(@data["presenting_symptoms"], @data["clinical_info"])}
        rows="4"
        class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
      />
    </section>

    <section class="mb-6">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4">
        Laboratory Investigations Requested
      </h2>
      <div class="border border-gray-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 text-gray-600 uppercase text-xs tracking-wide">
            <tr>
              <th class="px-4 py-3 text-left">Category</th>
              <th class="px-4 py-3 text-left">Tick</th>
              <th class="px-4 py-3 text-left">Specific Tests</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for {label, key} <- [
              {"Haematology", "haematology"},
              {"Biochemistry", "biochemistry"},
              {"Microbiology", "microbiology"},
              {"Parasitology", "parasitology"},
              {"Serology/Immunology", "serology"},
              {"Molecular/PCR", "molecular"},
              {"Blood Bank", "blood_bank"},
              {"Other", "other_investigations"}
            ] do %>
              <tr>
                <td class="px-4 py-3 font-medium text-gray-700">{label}</td>
                <td class="px-4 py-3"><.preview_checkbox checked={present?(@data[key])} /></td>
                <td class="px-4 py-3">
                  <.preview_inline_input value={value_or_blank(@data[key])} />
                </td>
              </tr>
            <% end %>
            <tr :if={present?(@data["investigations"])}>
              <td class="px-4 py-3 font-medium text-gray-700">Requested Tests</td>
              <td class="px-4 py-3"><.preview_checkbox checked={true} /></td>
              <td class="px-4 py-3"><.preview_inline_input value={@data["investigations"]} /></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section class="mb-6">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4">Specimen Details</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Specimen Types
          </label>
          <.preview_inline_input value={coalesce(@data["specimen_types"], @data["specimen_type"])} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Collected By
          </label>
          <.preview_inline_input value={@data["collected_by"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Collection Date & Time
          </label>
          <.preview_inline_input value={format_field(@data["specimen_collection_datetime"])} />
        </div>
      </div>
    </section>

    <section class="mb-6">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4">
        Results / Laboratory Use Only
      </h2>
      <div class="border border-gray-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 text-gray-600 uppercase text-xs tracking-wide">
            <tr>
              <th class="px-4 py-3 text-left">Test Performed</th>
              <th class="px-4 py-3 text-left">Result</th>
              <th class="px-4 py-3 text-left">Units / Range</th>
              <th class="px-4 py-3 text-left">Remarks</th>
            </tr>
          </thead>
          <tbody>
            <%= for _ <- 1..6 do %>
              <tr class="border-t border-gray-100">
                <td class="px-4 py-3"><.preview_inline_input value="" /></td>
                <td class="px-4 py-3"><.preview_inline_input value="" /></td>
                <td class="px-4 py-3"><.preview_inline_input value="" /></td>
                <td class="px-4 py-3"><.preview_inline_input value="" /></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </section>

    <section>
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4">
        Laboratory Verification
      </h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Lab Personnel Name
          </label>
          <.preview_inline_input value={@data["lab_personnel_name"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date Reported
          </label>
          <.preview_inline_input value={format_field(@data["date_reported"])} />
        </div>
      </div>
      <div class="mt-4">
        <.preview_signature_line label="Officer Signature" value={@data["officer_signature"]} />
      </div>
    </section>
    """
  end

  def saved_discharge_summary_preview(assigns) do
    ~H"""
    <.form_header_centered title="Discharge Summary" />
    <div class="flex justify-end mb-6">
      <div class="w-48">
        <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
          Date
        </label>
        <.preview_inline_input value={format_field(@data["date"])} />
      </div>
    </div>

    <section class="mb-6 ml-0 md:ml-8">
      <.numbered_heading number="1" title="Patient Details" />
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Patient Name
          </label>
          <.preview_inline_input value={coalesce(@data["patient_name"], @patient_name)} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Age
          </label>
          <.preview_inline_input value={@data["age"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Sex
          </label>
          <div class="flex gap-6 mt-2">
            <.preview_radio label="Male" checked={selected?(@data, "sex", "male")} /><.preview_radio
              label="Female"
              checked={selected?(@data, "sex", "female")}
            />
          </div>
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Residence
          </label>
          <.preview_inline_input value={@data["residence"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Tel
          </label>
          <.preview_inline_input value={@data["tel"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Next of Kin
          </label>
          <.preview_inline_input value={@data["next_of_kin"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Next of Kin Tel
          </label>
          <.preview_inline_input value={@data["nok_tel"]} />
        </div>
      </div>
    </section>

    <section class="mb-6 ml-0 md:ml-8">
      <.numbered_heading number="2" title="Admission Details" />
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Admission Date
          </label>
          <.preview_inline_input value={format_field(@data["admission_date"])} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Admission Time
          </label>
          <.preview_inline_input value={format_field(@data["admission_time"])} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Mode of Admission
          </label>
          <div class="flex flex-wrap gap-4 mt-2">
            <.preview_radio
              label="Emergency"
              checked={selected?(@data, "admission_mode", "emergency")}
            /><.preview_radio
              label="Elective"
              checked={selected?(@data, "admission_mode", "elective")}
            /><.preview_radio
              label="Referral"
              checked={selected?(@data, "admission_mode", "referral")}
            />
          </div>
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Referring Facility
          </label>
          <.preview_inline_input value={@data["referring_facility"]} />
        </div>
      </div>
    </section>

    <section class="mb-6 ml-0 md:ml-8">
      <.numbered_heading number="3" title="Clinical Summary" />
      <div class="mt-4">
        <.preview_textarea
          value={coalesce(@data["clinical_summary"], @data["treatment_summary"])}
          rows="4"
          class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
        />
      </div>
    </section>
    <section class="mb-6 ml-0 md:ml-8">
      <.numbered_heading number="4" title="Diagnosis" />
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Diagnosis on Admission
          </label>
          <.preview_textarea
            value={coalesce(@data["diagnosis_on_admission"], @data["diagnosis"])}
            rows="3"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
          />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Diagnosis on Discharge
          </label>
          <.preview_textarea
            value={@data["diagnosis_on_discharge"]}
            rows="3"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
          />
        </div>
      </div>
    </section>

    <section class="mb-6 ml-0 md:ml-8">
      <.numbered_heading number="5" title="Condition at Discharge" />
      <div class="mt-4 space-y-4">
        <div class="flex flex-wrap gap-4">
          <.preview_checkbox
            label="Stable"
            checked={
              selected?(@data, "condition_at_discharge", "stable") or
                selected?(@data, "condition_on_discharge", "stable")
            }
          />
          <.preview_checkbox
            label="Improved"
            checked={
              selected?(@data, "condition_at_discharge", "improved") or
                selected?(@data, "condition_on_discharge", "improved")
            }
          />
          <.preview_checkbox
            label="Unchanged"
            checked={
              selected?(@data, "condition_at_discharge", "unchanged") or
                selected?(@data, "condition_on_discharge", "unchanged")
            }
          />
          <.preview_checkbox
            label="Referred"
            checked={
              selected?(@data, "condition_at_discharge", "referred") or
                selected?(@data, "condition_on_discharge", "deteriorated")
            }
          />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Remarks
          </label>
          <.preview_inline_input value={@data["condition_remarks"]} />
        </div>
      </div>
    </section>

    <section class="mb-6 ml-0 md:ml-8">
      <.numbered_heading number="6" title="Discharge Medications" />
      <div class="mt-4 border border-gray-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 text-gray-600 uppercase text-xs tracking-wide">
            <tr>
              <th class="px-4 py-3 text-left">Medication</th>
              <th class="px-4 py-3 text-left">Dose</th>
              <th class="px-4 py-3 text-left">Frequency</th>
              <th class="px-4 py-3 text-left">Duration</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for i <- 1..5 do %>
              <tr>
                <td class="px-4 py-3"><.preview_inline_input value={@data["medication_#{i}"]} /></td>
                <td class="px-4 py-3"><.preview_inline_input value={@data["dose_#{i}"]} /></td>
                <td class="px-4 py-3"><.preview_inline_input value={@data["frequency_#{i}"]} /></td>
                <td class="px-4 py-3"><.preview_inline_input value={@data["duration_#{i}"]} /></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </section>

    <section class="mb-6 ml-0 md:ml-8">
      <.numbered_heading number="7" title="Health Education" />
      <div class="mt-4">
        <.preview_textarea
          value={coalesce(@data["health_education"], @data["follow_up"])}
          rows="3"
          class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
        />
      </div>
    </section>
    <section class="mb-6 ml-0 md:ml-8">
      <.numbered_heading number="8" title="Follow-Up Plan" />
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Follow-up Clinic
          </label>
          <.preview_inline_input value={@data["follow_up_clinic"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date
          </label>
          <.preview_inline_input value={format_field(@data["follow_up_date"])} />
        </div>
      </div>
    </section>

    <section class="ml-0 md:ml-8">
      <.numbered_heading number="9" title="Discharged By" />
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-4 items-start">
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Name
            </label>
            <.preview_inline_input value={
              coalesce(@data["discharged_by_name"], @data["medical_officer_name"])
            } />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Designation
            </label>
            <.preview_inline_input value={
              coalesce(@data["discharged_by_designation"], @data["designation"])
            } />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Date
            </label>
            <.preview_inline_input value={
              format_field(coalesce(@data["discharged_by_date"], @data["date_issued"]))
            } />
          </div>
          <.preview_signature_line label="Signature" value={@data["clinician_signature"]} />
        </div>
        <.official_stamp />
      </div>
    </section>
    """
  end

  def saved_radiology_request_preview(assigns) do
    ~H"""
    <.form_header_centered title="Radiology Request Form" />

    <section class="mb-6">
      <.numbered_heading number="1" title="Patient Details" />
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Full Name
          </label>
          <.preview_inline_input value={coalesce(@data["patient_name"], @patient_name)} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Age
          </label>
          <.preview_inline_input value={@data["age"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Gender
          </label>
          <div class="flex gap-6 mt-2">
            <.preview_radio label="Male" checked={selected?(@data, "gender", "male")} /><.preview_radio
              label="Female"
              checked={selected?(@data, "gender", "female")}
            /><.preview_radio label="Other" checked={selected?(@data, "gender", "other")} />
          </div>
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Phone Number
          </label>
          <.preview_inline_input value={@data["phone"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Patient ID
          </label>
          <.preview_inline_input value={@data["patient_id_number"]} />
        </div>
      </div>
    </section>
    <section class="mb-6">
      <.numbered_heading number="2" title="Clinical Information" />
      <div class="mt-4">
        <.preview_textarea
          value={coalesce(@data["clinical_history"], @data["clinical_info"])}
          rows="4"
          class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
        />
      </div>
    </section>
    <section class="mb-6">
      <.numbered_heading number="3" title="Radiology Investigation Requested" />
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
        <%= for {label, key} <- [{"X-Ray", "xray"}, {"Ultrasound", "ultrasound"}, {"CT Scan", "ct_scan"}, {"MRI", "mri"}] do %>
          <div class="border border-gray-200 rounded-lg p-4 space-y-2">
            <div class="flex items-center gap-2 text-sm font-semibold text-gray-700">
              <.preview_checkbox checked={present?(@data[key])} /><span>{label}</span>
            </div>
            <.preview_inline_input value={@data[key]} />
          </div>
        <% end %>
        <div class="border border-gray-200 rounded-lg p-4 space-y-2 md:col-span-2">
          <div class="flex items-center gap-2 text-sm font-semibold text-gray-700">
            <.preview_checkbox checked={present?(@data["other_imaging"])} /><span>Other Imaging</span>
          </div>
          <.preview_inline_input value={@data["other_imaging"]} />
        </div>
        <div class="border border-gray-200 rounded-lg p-4 space-y-2 md:col-span-2">
          <div class="text-sm font-semibold text-gray-700">Contrast</div>
          <div class="flex gap-6">
            <.preview_radio label="With Contrast" checked={selected?(@data, "contrast", "contrast")} /><.preview_radio
              label="Non-Contrast"
              checked={selected?(@data, "contrast", "non_contrast")}
            />
          </div>
        </div>
      </div>
    </section>
    <section class="mb-6">
      <.numbered_heading number="5" title="Requesting Clinician Details" />
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Name
          </label>
          <.preview_inline_input value={@data["clinician_name"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Designation
          </label>
          <.preview_inline_input value={@data["clinician_designation"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date
          </label>
          <.preview_inline_input value={
            format_field(coalesce(@data["clinician_date"], @data["urgency"]))
          } />
        </div>
      </div>
      <div class="mt-4">
        <.preview_signature_line label="Signature" value={@data["doctor_signature"]} />
      </div>
    </section>
    <section>
      <.numbered_heading number="6" title="For Radiology Department Use Only" />
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Report Number
          </label>
          <.preview_inline_input value={@data["report_number"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date & Time Done
          </label>
          <.preview_inline_input value={format_field(@data["datetime_done"])} />
        </div>
        <div class="md:col-span-2">
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Radiographer / Radiologist
          </label>
          <.preview_inline_input value={@data["radiographer_name"]} />
        </div>
        <div class="md:col-span-2">
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Findings
          </label>
          <.preview_textarea
            value={coalesce(@data["findings"], @data["investigation"])}
            rows="5"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
          />
        </div>
        <div class="md:col-span-2">
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Remarks
          </label>
          <.preview_textarea
            value={@data["remarks"]}
            rows="3"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
          />
        </div>
      </div>
    </section>
    """
  end

  def saved_prescription_sheet_preview(assigns) do
    ~H"""
    <.form_header_centered title="Prescription Sheet" />
    <section class="mb-6">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Patient Name
          </label>
          <.preview_inline_input value={coalesce(@data["patient_name"], @patient_name)} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Age
          </label>
          <.preview_inline_input value={@data["age"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Gender
          </label>
          <div class="flex gap-4 mt-2">
            <.preview_radio label="Male" checked={selected?(@data, "gender", "male")} /><.preview_radio
              label="Female"
              checked={selected?(@data, "gender", "female")}
            /><.preview_radio label="Other" checked={selected?(@data, "gender", "other")} />
          </div>
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date
          </label>
          <.preview_inline_input value={format_field(@data["date"])} />
        </div>
      </div>
    </section>
    <section class="mb-6">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Prescriber Name
          </label>
          <.preview_inline_input value={@data["prescriber_name"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Designation
          </label>
          <.preview_inline_input value={@data["prescriber_designation"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Contact
          </label>
          <.preview_inline_input value={@data["prescriber_contact"]} />
        </div>
      </div>
    </section>
    <section class="mb-6">
      <div class="border border-gray-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-[#373896] text-white uppercase text-xs tracking-wide">
            <tr>
              <th class="px-4 py-3 text-left">Route</th>
              <th class="px-4 py-3 text-left">Medication</th>
              <th class="px-4 py-3 text-left">Strength</th>
              <th class="px-4 py-3 text-left">Frequency</th>
              <th class="px-4 py-3 text-left">Duration</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for i <- 1..8 do %>
              <tr>
                <td class="px-4 py-3"><.preview_inline_input value={@data["route_#{i}"]} /></td>
                <td class="px-4 py-3">
                  <.preview_inline_input value={
                    coalesce(
                      @data["medication_#{i}"],
                      if(i == 1, do: @data["medications"], else: nil)
                    )
                  } />
                </td>
                <td class="px-4 py-3"><.preview_inline_input value={@data["strength_#{i}"]} /></td>
                <td class="px-4 py-3"><.preview_inline_input value={@data["frequency_#{i}"]} /></td>
                <td class="px-4 py-3"><.preview_inline_input value={@data["duration_#{i}"]} /></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </section>
    <section class="mb-6">
      <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
        Notes / Instructions
      </label>
      <.preview_textarea
        value={coalesce(@data["notes_instructions"], @data["instructions"])}
        rows="4"
        class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
      />
    </section>
    <.preview_signature_line label="Prescriber Signature" value={@data["prescriber_signature"]} />
    """
  end

  def saved_sick_leave_preview(assigns) do
    ~H"""
    <.form_header_centered title="Sick Leave Sheet" />
    <div class="space-y-6 text-sm text-gray-700">
      <p class="font-semibold uppercase tracking-wide text-center">To Whom It May Concern</p>
      <p class="leading-7">
        This is to certify that
        <span class="inline-block min-w-56 align-middle mx-1">
          <.preview_inline_input value={coalesce(@data["patient_name"], @patient_name)} />
        </span>
        age
        <span class="inline-block min-w-24 align-middle mx-1">
          <.preview_inline_input value={@data["age"]} />
        </span>
        gender
        <span class="inline-block min-w-24 align-middle mx-1">
          <.preview_inline_input value={@data["gender"]} />
        </span>
        with identification number
        <span class="inline-block min-w-48 align-middle mx-1">
          <.preview_inline_input value={@data["id_number"]} />
        </span>
        was examined on <span class="inline-block min-w-40 align-middle mx-1"><.preview_inline_input value={
            format_field(@data["examination_date"])
          } /></span>.
      </p>
      <p class="leading-7">
        The patient is medically unfit to attend
        <span class="inline-block min-w-32 align-middle mx-1">
          <.preview_inline_input value={coalesce(@data["unfit_for"], @data["refrain_from"])} />
        </span>
        and should refrain from
        <span class="inline-block min-w-32 align-middle mx-1">
          <.preview_inline_input value={coalesce(@data["refrain_from"], @data["unfit_for"])} />
        </span>
        from
        <span class="inline-block min-w-40 align-middle mx-1">
          <.preview_inline_input value={format_field(@data["start_date"])} />
        </span>
        to <span class="inline-block min-w-40 align-middle mx-1"><.preview_inline_input value={
            format_field(@data["end_date"])
          } /></span>.
      </p>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Total Leave Days Recommended
          </label>
          <.preview_inline_input value={@data["total_days"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Remarks
          </label>
          <.preview_textarea
            value={coalesce(@data["remarks"], @data["diagnosis"])}
            rows="3"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
          />
        </div>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6 border-t border-gray-200 items-start">
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Medical Officer / Clinician
            </label>
            <.preview_inline_input value={
              coalesce(
                @data["medical_officer_name"],
                @data["medical_officer"],
                @data["examining_doctor"]
              )
            } />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Date Issued
            </label>
            <.preview_inline_input value={format_field(@data["date_issued"])} />
          </div>
          <.preview_signature_line label="Signature" value={@data["patient_signature"]} />
        </div>
        <.official_stamp />
      </div>
      <div class="text-xs text-gray-500 border-t border-gray-200 pt-4 grid gap-1">
        <p>Glocal Healthcare Centre of Excellence</p>
        <p>P.O. Box 3243 - 00200, Nairobi</p>
        <p>+254 (20) 2385270 / 2318414 | info@glocalhealthcentre.org</p>
      </div>
    </div>
    """
  end

  def saved_surgical_consent_preview(assigns) do
    ~H"""
    <.form_header_centered title="Surgical Consent Form" />
    <div class="space-y-6 text-sm text-gray-700 leading-7">
      <p>
        I,
        <span class="inline-block min-w-56 align-middle mx-1">
          <.preview_inline_input value={coalesce(@data["patient_guardian_name"], @patient_name)} />
        </span>
        holder of ID / Passport No. <span class="inline-block min-w-40 align-middle mx-1"><.preview_inline_input value={
            @data["id_passport"]
          } /></span>,
        consent to Dr.
        <span class="inline-block min-w-48 align-middle mx-1">
          <.preview_inline_input value={coalesce(@data["doctor_name"], @data["surgeon"])} />
        </span>
        performing the procedure <span class="inline-block min-w-56 align-middle mx-1"><.preview_inline_input value={
            coalesce(@data["procedure_name"], @data["procedure"])
          } /></span>.
      </p>
      <ul class="space-y-2 list-disc list-inside text-gray-600">
        <li>
          The nature, risks, benefits, and alternatives of the procedure have been explained to me.
        </li>
        <li>I have had an opportunity to ask questions and all have been answered satisfactorily.</li>
        <li>I understand that no guarantee has been made as to the result of the procedure.</li>
        <li>I consent voluntarily and without coercion.</li>
      </ul>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 pt-6 border-t border-gray-200">
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Patient / Guardian Name
            </label>
            <.preview_inline_input value={coalesce(@data["patient_guardian_name"], @patient_name)} />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Date
            </label>
            <.preview_inline_input value={format_field(@data["patient_consent_date"])} />
          </div>
          <.preview_signature_line label="Patient Signature" value={@data["patient_signature"]} />
        </div>
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Witness Name
            </label>
            <.preview_inline_input value={@data["witness_name"]} />
          </div>
          <.preview_signature_line label="Witness Signature" value={@data["witness_signature"]} />
        </div>
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Doctor Name
            </label>
            <.preview_inline_input value={coalesce(@data["doctor_name"], @data["surgeon"])} />
          </div>
          <.preview_signature_line label="Doctor Signature" value={@data["doctor_signature"]} />
        </div>
      </div>
    </div>
    """
  end

  def saved_blood_transfusion_consent_preview(assigns) do
    ~H"""
    <.form_header_centered title="Blood Transfusion Consent Form" />
    <div class="space-y-6 text-sm text-gray-700 leading-7">
      <p>
        I,
        <span class="inline-block min-w-56 align-middle mx-1">
          <.preview_inline_input value={coalesce(@data["patient_guardian_name"], @patient_name)} />
        </span>
        holder of ID / Passport No. <span class="inline-block min-w-40 align-middle mx-1"><.preview_inline_input value={
            @data["id_passport"]
          } /></span>, hereby give informed consent for blood transfusion.
      </p>
      <ul class="space-y-2 list-disc list-inside text-red-600">
        <li>I understand the reason for the transfusion and the expected benefits.</li>
        <li>I understand the possible risks, complications, and available alternatives.</li>
        <li>I have had an opportunity to ask questions and all have been answered satisfactorily.</li>
      </ul>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 pt-6 border-t border-gray-200">
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Patient / Guardian Name
            </label>
            <.preview_inline_input value={coalesce(@data["patient_guardian_name"], @patient_name)} />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Date
            </label>
            <.preview_inline_input value={format_field(@data["patient_consent_date"])} />
          </div>
          <.preview_signature_line label="Patient Signature" value={@data["patient_signature"]} />
        </div>
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Witness Name
            </label>
            <.preview_inline_input value={@data["witness_name"]} />
          </div>
          <.preview_signature_line label="Witness Signature" value={@data["witness_signature"]} />
        </div>
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Doctor Name
            </label>
            <.preview_inline_input value={@data["doctor_name"]} />
          </div>
          <.preview_signature_line label="Doctor Signature" value={@data["doctor_signature"]} />
        </div>
      </div>
    </div>
    """
  end

  def saved_hiv_testing_consent_preview(assigns) do
    ~H"""
    <.form_header_centered title="HIV Testing Consent Form" />
    <div class="space-y-6 text-sm text-gray-700 leading-7">
      <p>
        I,
        <span class="inline-block min-w-56 align-middle mx-1">
          <.preview_inline_input value={coalesce(@data["patient_guardian_name"], @patient_name)} />
        </span>
        holder of ID / Passport No. <span class="inline-block min-w-40 align-middle mx-1"><.preview_inline_input value={
            @data["id_passport"]
          } /></span>, hereby give informed consent to undergo HIV testing.
      </p>
      <ul class="space-y-2 list-disc list-inside text-gray-600">
        <li>
          I have been provided with pre-test counseling and understand the implications of the test.
        </li>
        <li>I understand that the test results will be treated with strict confidentiality.</li>
        <li>I understand that post-test counseling will be provided after the results.</li>
      </ul>
      <div
        :if={
          present?(
            coalesce(@data["pre_test_counseling"], @data["counselor_name"], @data["counselor"])
          )
        }
        class="bg-gray-50 rounded-lg p-4"
      >
        <div :if={present?(@data["pre_test_counseling"])}>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Pre-Test Counseling Notes
          </label>
          <.preview_textarea
            value={@data["pre_test_counseling"]}
            rows="3"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
          />
        </div>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6 border-t border-gray-200">
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Patient / Guardian
            </label>
            <.preview_inline_input value={coalesce(@data["patient_guardian_name"], @patient_name)} />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Date
            </label>
            <.preview_inline_input value={
              format_field(coalesce(@data["patient_consent_date"], @data["consent_date"]))
            } />
          </div>
          <.preview_signature_line label="Patient Signature" value={@data["patient_signature"]} />
        </div>
        <div class="space-y-6">
          <div class="space-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Counselor Name
              </label>
              <.preview_inline_input value={coalesce(@data["counselor_name"], @data["counselor"])} />
            </div>
            <.preview_signature_line label="Counselor Signature" value={@data["counselor_signature"]} />
          </div>
          <div class="space-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Witness Name
              </label>
              <.preview_inline_input value={@data["witness_name"]} />
            </div>
            <.preview_signature_line label="Witness Signature" value={@data["witness_signature"]} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def saved_medical_report_preview(assigns) do
    ~H"""
    <.form_header_centered title="Medical Report" />
    <section class="mb-6">
      <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
        Section A: Personal Information
      </h2>
      <div class="border border-gray-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <tbody class="divide-y divide-gray-100">
            <.table_row label="Full Name">
              <.preview_inline_input value={coalesce(@data["full_name"], @patient_name)} />
            </.table_row>
            <.table_row label="Date of Birth">
              <div class="flex flex-wrap items-center gap-6">
                <.preview_inline_input value={format_field(@data["date_of_birth"])} class="w-48" />
                <div class="flex items-center gap-4">
                  <span class="text-sm text-gray-600">Gender:</span>
                  <.preview_radio label="Male" checked={selected?(@data, "gender", "male")} /><.preview_radio
                    label="Female"
                    checked={selected?(@data, "gender", "female")}
                  /><.preview_radio label="Other" checked={selected?(@data, "gender", "other")} />
                </div>
              </div>
            </.table_row>
            <.table_row label="National ID / Passport No.">
              <.preview_inline_input value={@data["id_passport"]} class="w-64" />
            </.table_row>
            <.table_row label="Contact No.">
              <.preview_inline_input value={@data["contact_no"]} class="w-64" />
            </.table_row>
            <.table_row label="Position Applied For">
              <.preview_inline_input value={@data["position_applied"]} />
            </.table_row>
            <.table_row label="Department">
              <.preview_inline_input value={@data["department"]} />
            </.table_row>
          </tbody>
        </table>
      </div>
    </section>
    <section class="mb-6">
      <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
        Section B: Medical History
      </h2>
      <div class="border border-gray-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <tbody class="divide-y divide-gray-100">
            <%= for {label, key} <- [{"Hypertension / Heart Disease", "hypertension"}, {"Diabetes Mellitus", "diabetes"}, {"Asthma / Respiratory Illness", "asthma"}, {"Tuberculosis", "tuberculosis"}, {"Epilepsy / Seizures", "epilepsy"}, {"Mental Health Conditions", "mental_health"}, {"Hearing or Vision Problems", "hearing_vision"}, {"Any chronic illness / long-term medication", "chronic_illness"}] do %>
              <tr class="hover:bg-gray-50">
                <td class="px-4 py-2.5">
                  <div class="flex items-center gap-6">
                    <div class="flex items-center gap-3">
                      <.preview_radio label="Yes" checked={selected?(@data, key, "yes")} /><.preview_radio
                        label="No"
                        checked={selected?(@data, key, "no")}
                      />
                    </div>
                    <span class="text-gray-700">{label}</span>
                  </div>
                </td>
              </tr>
            <% end %>
            <tr>
              <td class="px-4 py-2.5">
                <div class="flex items-center gap-3">
                  <span class="text-gray-700 font-medium">Allergies:</span>
                  <.preview_inline_input value={@data["allergies"]} class="flex-1" />
                </div>
              </td>
            </tr>
            <tr>
              <td class="px-4 py-2.5">
                <div class="flex items-center gap-3">
                  <span class="text-gray-700 font-medium">Past surgeries / admissions:</span>
                  <.preview_inline_input value={@data["past_surgeries"]} class="flex-1" />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
    <section class="mb-6">
      <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
        Section C: Physical Examination
      </h2>
      <div class="border border-gray-200 rounded-lg overflow-hidden mb-4">
        <table class="w-full text-sm">
          <tbody>
            <tr class="divide-x divide-gray-200 border-b border-gray-200">
              <td class="px-4 py-2.5">
                <div class="flex items-center gap-2">
                  <span class="text-gray-600 font-medium">Height:</span>
                  <.preview_inline_input value={@data["height"]} class="w-20" />
                  <span class="text-gray-500 text-xs">
                    cm
                  </span>
                </div>
              </td>
              <td class="px-4 py-2.5">
                <div class="flex items-center gap-2">
                  <span class="text-gray-600 font-medium">Weight:</span>
                  <.preview_inline_input value={@data["weight"]} class="w-20" />
                  <span class="text-gray-500 text-xs">
                    kg
                  </span>
                </div>
              </td>
              <td class="px-4 py-2.5">
                <div class="flex items-center gap-2">
                  <span class="text-gray-600 font-medium">BMI:</span>
                  <.preview_inline_input value={@data["bmi"]} class="w-20" />
                </div>
              </td>
            </tr>
            <tr class="divide-x divide-gray-200 border-b border-gray-200">
              <td class="px-4 py-2.5">
                <div class="flex items-center gap-2">
                  <span class="text-gray-600 font-medium">Blood Pressure:</span>
                  <.preview_inline_input value={@data["blood_pressure"]} class="w-24" />
                </div>
              </td>
              <td class="px-4 py-2.5">
                <div class="flex items-center gap-2">
                  <span class="text-gray-600 font-medium">Pulse:</span>
                  <.preview_inline_input value={@data["pulse"]} class="w-20" />
                </div>
              </td>
              <td class="px-4 py-2.5">
                <div class="flex items-center gap-2">
                  <span class="text-gray-600 font-medium">Temp:</span>
                  <.preview_inline_input value={@data["temperature"]} class="w-20" />
                </div>
              </td>
            </tr>
            <tr class="border-b border-gray-200">
              <td colspan="3" class="px-4 py-2.5">
                <div class="flex items-center gap-4 flex-wrap">
                  <span class="text-gray-600 font-medium">Vision: Left</span>
                  <.preview_inline_input value={@data["vision_left"]} class="w-20" />
                  <span class="text-gray-600">
                    / Right
                  </span>
                  <.preview_inline_input value={@data["vision_right"]} class="w-20" />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="border border-gray-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <thead>
            <tr class="bg-gray-50 border-b border-gray-200">
              <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-2.5">
                System
              </th>
              <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-2.5 w-48">
                Finding
              </th>
              <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-2.5">
                Remarks
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <%= for {label, key} <- [{"Hearing", "hearing_vision"}, {"Chest / Lungs", "asthma"}, {"Cardiovascular", "hypertension"}, {"Abdomen", "other_tests"}, {"Musculoskeletal", "other_tests"}, {"Neurological", "epilepsy"}, {"Skin", "other_tests"}] do %>
              <tr class="hover:bg-gray-50">
                <td class="px-4 py-2.5 font-medium text-gray-700">{label}</td>
                <td class="px-4 py-2.5">
                  <div class="flex items-center gap-3">
                    <.preview_radio
                      label="Normal"
                      checked={selected?(@data, key, "normal") or selected?(@data, key, "no")}
                    /><.preview_radio
                      label="Abnormal"
                      checked={selected?(@data, key, "abnormal") or selected?(@data, key, "yes")}
                    />
                  </div>
                </td>
                <td class="px-4 py-2.5"><.preview_inline_input value="" /></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </section>
    <section class="mb-6">
      <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
        Section D: Laboratory Investigations
      </h2>
      <div class="border border-gray-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <tbody class="divide-y divide-gray-100">
            <%= for {label, key} <- [{"Complete Blood Count (CBC)", "cbc"}, {"Urinalysis", "urinalysis"}, {"Chest X-Ray", "chest_xray"}] do %>
              <tr>
                <td class="px-4 py-2.5 font-medium text-gray-700">{label}</td>
                <td class="px-4 py-2.5">
                  <div class="flex gap-4">
                    <.preview_radio label="Normal" checked={selected?(@data, key, "normal")} /><.preview_radio
                      label="Abnormal"
                      checked={selected?(@data, key, "abnormal")}
                    />
                  </div>
                </td>
              </tr>
            <% end %>
            <tr>
              <td class="px-4 py-2.5 font-medium text-gray-700">Blood Sugar (FBS/RBS)</td>
              <td class="px-4 py-2.5">
                <.preview_inline_input value={@data["blood_sugar"]} class="w-40" />
              </td>
            </tr>
            <tr>
              <td class="px-4 py-2.5 font-medium text-gray-700">Other Tests</td>
              <td class="px-4 py-2.5"><.preview_inline_input value={@data["other_tests"]} /></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
    <section>
      <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
        Section E: Fitness for Employment / Education
      </h2>
      <div class="space-y-4">
        <div class="space-y-2">
          <.preview_radio
            label="Medically FIT for employment/education"
            checked={selected?(@data, "fitness_status", "fit")}
          /><.preview_radio
            label="Temporarily UNFIT – re-evaluation needed"
            checked={selected?(@data, "fitness_status", "temp_unfit")}
          /><.preview_radio
            label="PERMANENTLY UNFIT for employment/education"
            checked={selected?(@data, "fitness_status", "perm_unfit")}
          />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Re-evaluation Period
          </label>
          <.preview_inline_input value={@data["reevaluation_period"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Remarks
          </label>
          <.preview_textarea
            value={coalesce(@data["remarks"], @data["recommendation"])}
            rows="4"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
          />
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 pt-4">
          <div class="space-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Doctor's Name
              </label>
              <.preview_inline_input value={
                coalesce(@data["examining_doctor"], @data["medical_officer_name"])
              } />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Date
              </label>
              <.preview_inline_input value={
                format_field(coalesce(@data["examination_date"], @data["date_issued"]))
              } />
            </div>
            <.preview_signature_line label="Signature" value={@data["signature"]} />
          </div>
          <.official_stamp />
        </div>
      </div>
    </section>
    """
  end

  def saved_patient_referral_preview(assigns) do
    ~H"""
    <.form_header_centered title="Patient Referral Form" />
    <section class="mb-6">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date
          </label>
          <.preview_inline_input value={format_field(@data["date"])} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Referral Time
          </label>
          <.preview_inline_input value={format_field(@data["referral_time"])} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Referral To
          </label>
          <.preview_inline_input value={coalesce(@data["referral_to"], @data["referred_to"])} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Focal Person
          </label>
          <.preview_inline_input value={@data["focal_person"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Location
          </label>
          <.preview_inline_input value={@data["location"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Phone
          </label>
          <.preview_inline_input value={coalesce(@data["facility_phone"], @data["phone"])} />
        </div>
        <div class="md:col-span-2">
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Email
          </label>
          <.preview_inline_input value={coalesce(@data["facility_email"], @data["email"])} />
        </div>
      </div>
    </section>
    <section class="mb-6 bg-[#373896] text-white rounded-xl p-5">
      <p class="text-xs uppercase tracking-[0.2em] text-white/70 mb-3">Referring From</p>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-xs font-semibold text-white/70 uppercase tracking-wide mb-1">
            Referring Doctor
          </label>
          <.preview_filled_input value={coalesce(@data["referring_doctor"], @data["doctor_name"])} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-white/70 uppercase tracking-wide mb-1">
            Phone
          </label>
          <.preview_filled_input value={coalesce(@data["doctor_phone"], @data["phone"])} />
        </div>
        <div class="md:col-span-2">
          <label class="block text-xs font-semibold text-white/70 uppercase tracking-wide mb-1">
            Email
          </label>
          <.preview_filled_input value={coalesce(@data["doctor_email"], @data["email"])} />
        </div>
      </div>
    </section>
    <section class="mb-6">
      <div class="border border-gray-200 rounded-lg overflow-hidden">
        <table class="w-full text-sm">
          <tbody class="divide-y divide-gray-100">
            <.table_row label="Full Name">
              <.preview_inline_input value={coalesce(@data["patient_name"], @patient_name)} />
            </.table_row>
            <.table_row label="Phone">
              <.preview_inline_input value={@data["patient_phone"]} />
            </.table_row>
            <.table_row label="Date of Birth">
              <.preview_inline_input value={format_field(@data["date_of_birth"])} />
            </.table_row>
            <.table_row label="Gender">
              <div class="flex gap-4">
                <.preview_radio label="Male" checked={selected?(@data, "gender", "male")} /><.preview_radio
                  label="Female"
                  checked={selected?(@data, "gender", "female")}
                />
              </div>
            </.table_row>
            <.table_row label="Address">
              <.preview_inline_input value={@data["address"]} />
            </.table_row>
            <.table_row label="Next of Kin">
              <.preview_inline_input value={@data["next_of_kin"]} />
            </.table_row>
            <.table_row label="Accompanied by care provider">
              <div class="flex gap-4">
                <.preview_radio label="Yes" checked={selected?(@data, "accompanied", "yes")} /><.preview_radio
                  label="No"
                  checked={selected?(@data, "accompanied", "no")}
                />
              </div>
            </.table_row>
          </tbody>
        </table>
      </div>
    </section>
    <section class="mb-6">
      <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4">Vital Signs</h2>
      <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            BP
          </label>
          <.preview_inline_input value={@data["bp"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Weight
          </label>
          <.preview_inline_input value={@data["weight"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Pulse
          </label>
          <.preview_inline_input value={@data["pulse"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            SPO2
          </label>
          <.preview_inline_input value={@data["spo2"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Other
          </label>
          <.preview_inline_input value={@data["other"]} />
        </div>
      </div>
    </section>
    <section class="space-y-4">
      <div>
        <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
          Clinical History
        </label>
        <.preview_textarea
          value={@data["clinical_history"]}
          rows="4"
          class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
        />
      </div>
      <div>
        <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
          Primary Diagnoses
        </label>
        <.preview_textarea
          value={coalesce(@data["primary_diagnoses"], @data["reason"])}
          rows="3"
          class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
        />
      </div>
      <div>
        <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
          Tests Conducted
        </label>
        <.preview_textarea
          value={@data["tests_conducted"]}
          rows="3"
          class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
        />
      </div>
      <div>
        <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
          Treatments Initiated
        </label>
        <div class="space-y-2">
          <.preview_textarea
            value={coalesce(@data["treatments_initiated"], @data["current_management"])}
            rows="3"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
          /><.preview_checkbox
            label="Ongoing"
            checked={selected?(@data, "ongoing", "true") or selected?(@data, "ongoing", "yes")}
          />
        </div>
      </div>
      <div>
        <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
          Reason for Referral
        </label>
        <.preview_textarea
          value={coalesce(@data["reason_for_referral"], @data["reason"])}
          rows="3"
          class="w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"
        />
      </div>
    </section>
    """
  end

  def saved_payment_receipt_preview(assigns) do
    ~H"""
    <.form_header_centered title="Payment Receipt" />
    <div class="space-y-6 text-sm text-gray-700">
      <div class="text-center text-xs text-gray-500">
        P.O. Box 3243 - 00200, Nairobi | +254 710 122252 | info@glocalhealthcentre.org
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Receipt No.
          </label>
          <.preview_inline_input value={@data["receipt_no"]} />
        </div>
        <div>
          <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
            Date
          </label>
          <.preview_inline_input value={format_field(@data["date"])} />
        </div>
      </div>
      <div class="space-y-4">
        <.receipt_row label="Received From" value={@data["received_from"]} /><.receipt_row
          label="Amount in Words"
          value={@data["amount_in_words"]}
        /><.receipt_row label="Being Payment Of" value={@data["being_payment_of"]} /><.receipt_row
          label="Printed By"
          value={@data["printed_by"]}
        />
      </div>
      <div class="border-2 border-gray-300 rounded-xl p-6 flex justify-end items-end">
        <div class="text-right">
          <p class="text-xs uppercase tracking-wide text-gray-500 mb-2">Amount (KES)</p>
          <p class="text-3xl font-bold text-[#373896]">{value_or_blank(@data["amount"])}</p>
        </div>
      </div>
      <p class="text-center text-sm text-gray-500">Thank you for your payment.</p>
    </div>
    """
  end

  def saved_generic_consent_preview(assigns) do
    ~H"""
    <.form_header_centered title={@title} />
    <div class="space-y-6 text-sm text-gray-700">{render_slot(@inner_block)}</div>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  def saved_discrete_preview(assigns) do
    ~H"""
    <.form_header_centered title={@title} />
    {render_slot(@inner_block)}
    """
  end

  def saved_sick_simple_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_discrete_wrapper(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_hiv_simple_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_blood_simple_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_surgical_simple_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_discharge_simple_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_generic_named_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_generic_section(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_simple_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_blood_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_hiv_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_medical_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_generic_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_misc_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_misc_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_medical_report_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_patient_referral_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_payment_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_blood_transfusion_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_discharge_numbered_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_discharge_numbered_section(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_hiv_testing_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_numbered_wrapper(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_discharge_summary_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_patient_simple_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_simple_group_preview(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_blood_transfusion_consent_simple(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_hiv_testing_consent_simple(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  def saved_payment_receipt_simple(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :record, :map, required: true
  attr :saved_at, :string, required: true

  def generic_saved_details_preview(assigns) do
    assigns = assign(assigns, :entries, ordered_form_entries(assigns.record))

    ~H"""
    <.form_header_centered title={PatientFormRecord.form_label(@record.form_type)} />
    <div class="mb-6 text-sm text-gray-500">Saved on {@saved_at}</div>
    <%= if @entries == [] do %>
      <div class="rounded-xl border border-dashed border-gray-300 px-4 py-6 text-sm text-gray-500">
        No saved field values were found for this form.
      </div>
    <% else %>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <%= for entry <- @entries do %>
          <div class="rounded-xl border border-gray-200 px-4 py-3 break-inside-avoid-page">
            <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              {entry.label}
            </p>
            <p class="text-sm text-gray-900 whitespace-pre-wrap break-words">{entry.value}</p>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  defp ordered_form_entries(%PatientFormRecord{form_data: form_data}) when is_map(form_data) do
    form_data
    |> stringify_keys()
    |> Enum.reject(fn {_key, value} -> blank_value?(value) end)
    |> Enum.sort_by(fn {key, _value} -> field_label(key) end)
    |> Enum.map(fn {key, value} -> %{label: field_label(key), value: display_value(value)} end)
  end

  defp ordered_form_entries(_), do: []

  defp stringify_keys(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp blank_value?(nil), do: true
  defp blank_value?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank_value?(value) when is_list(value), do: value == []
  defp blank_value?(value) when is_map(value), do: map_size(value) == 0
  defp blank_value?(_value), do: false

  defp display_value(value) when is_binary(value) do
    value = String.trim(value)

    cond do
      match?({:ok, _date}, Date.from_iso8601(value)) ->
        {:ok, date} = Date.from_iso8601(value)
        Calendar.strftime(date, "%d %b %Y")

      Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/, value) ->
        case NaiveDateTime.from_iso8601(value <> ":00") do
          {:ok, datetime} -> Calendar.strftime(datetime, "%d %b %Y %H:%M")
          _ -> value
        end

      Regex.match?(~r/^\d{2}:\d{2}$/, value) ->
        case Time.from_iso8601(value <> ":00") do
          {:ok, time} -> Calendar.strftime(time, "%H:%M")
          _ -> value
        end

      true ->
        value
    end
  end

  defp display_value(true), do: "Yes"
  defp display_value(false), do: "No"
  defp display_value(value) when is_integer(value), do: Integer.to_string(value)
  defp display_value(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 2)
  defp display_value(value), do: to_string(value)

  defp field_label(key) do
    key
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &capitalize_word/1)
  end

  defp capitalize_word(word) do
    case Integer.parse(word) do
      {_, ""} -> word
      _ -> String.capitalize(word)
    end
  end

  defp patient_display_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.filter(&(is_binary(&1) and String.trim(&1) != ""))
    |> Enum.join(" ")
  end

  defp signature_fields("dama"),
    do: [
      {"declaration_signature", "Patient / Guardian Signature"},
      {"witness_signature", "Witness / Medical Staff Signature"}
    ]

  defp signature_fields("lab_request"),
    do: [
      {"clinician_signature", "Clinician Signature"},
      {"officer_signature", "Lab Officer Signature"}
    ]

  defp signature_fields("discharge_summary"), do: [{"doctor_signature", "Doctor Signature"}]
  defp signature_fields("radiology_request"), do: [{"clinician_signature", "Clinician Signature"}]

  defp signature_fields("prescription_sheet"),
    do: [{"prescriber_signature", "Prescriber Signature"}]

  defp signature_fields("sick_leave"), do: [{"officer_signature", "Medical Officer Signature"}]

  defp signature_fields("surgical_consent"),
    do: [
      {"patient_signature", "Patient Signature"},
      {"witness_signature", "Witness Signature"},
      {"doctor_signature", "Doctor Signature"}
    ]

  defp signature_fields("blood_transfusion_consent"),
    do: [
      {"patient_signature", "Patient Signature"},
      {"witness_signature", "Witness Signature"},
      {"doctor_signature", "Doctor Signature"}
    ]

  defp signature_fields("hiv_testing_consent"),
    do: [
      {"patient_signature", "Patient Signature"},
      {"counselor_signature", "Counselor Signature"},
      {"witness_signature", "Witness Signature"}
    ]

  defp signature_fields("medical_report"), do: [{"signature", "Doctor Signature"}]
  defp signature_fields("patient_referral"), do: [{"signature", "Signature"}]
  defp signature_fields(_form_type), do: []

  defp editable_entries(form_type, data) do
    signature_keys = signature_fields(form_type) |> Enum.map(&elem(&1, 0)) |> MapSet.new()

    data
    |> Enum.reject(fn {key, _value} -> MapSet.member?(signature_keys, key) end)
    |> Enum.map(fn {key, value} ->
      value = value |> value_or_blank() |> to_string()

      %{
        key: key,
        label: field_label(key),
        value: value,
        multiline: multiline_field?(key, value)
      }
    end)
    |> Enum.sort_by(& &1.label)
  end

  defp multiline_field?(key, value) do
    String.contains?(key, [
      "reason",
      "notes",
      "history",
      "diagnosis",
      "summary",
      "findings",
      "instruction",
      "treatment",
      "comment",
      "remark",
      "plan",
      "address"
    ]) or String.contains?(to_string(value), "\n") or String.length(to_string(value)) > 80
  end

  defp input_kind(_value, true), do: :textarea

  defp input_kind(value, false) do
    cond do
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, value) -> :date
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/, value) -> :datetime_local
      Regex.match?(~r/^\d{2}:\d{2}$/, value) -> :time
      true -> :text
    end
  end

  attr :value, :any, default: nil

  attr :class, :string,
    default:
      "w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"

  def preview_inline_input(assigns) do
    ~H"""
    <input type="text" readonly value={value_or_blank(@value)} class={@class} />
    """
  end

  attr :value, :any, default: nil
  attr :rows, :string, default: "3"

  attr :class, :string,
    default: "w-full border border-gray-200 rounded-lg p-3 text-sm bg-transparent"

  def preview_textarea(assigns) do
    ~H"""
    <textarea readonly rows={@rows} class={@class}>{value_or_blank(@value)}</textarea>
    """
  end

  attr :checked, :boolean, default: false
  attr :label, :string, default: nil

  def preview_checkbox(assigns) do
    ~H"""
    <label class="inline-flex items-center gap-2 text-sm text-gray-700">
      <input type="checkbox" checked={@checked} disabled class="accent-[#373896]" />
      <%= if @label do %>
        <span>{@label}</span>
      <% end %>
    </label>
    """
  end

  attr :checked, :boolean, default: false
  attr :label, :string, required: true

  def preview_radio(assigns) do
    ~H"""
    <label class="inline-flex items-center gap-2 text-sm text-gray-700">
      <input type="radio" checked={@checked} disabled class="accent-[#373896]" />
      <span>{@label}</span>
    </label>
    """
  end

  attr :label, :string, default: "Signature"
  attr :value, :string, default: ""

  def preview_signature_line(assigns) do
    ~H"""
    <div>
      <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
        {@label}
      </label>
      <div class="flex h-24 items-center justify-center rounded-lg border border-gray-300 bg-white p-2">
        <%= if is_binary(@value) and String.starts_with?(@value, "data:image") do %>
          <img src={@value} alt={@label} class="max-h-full max-w-full object-contain" />
        <% end %>
      </div>
    </div>
    """
  end

  attr :value, :any, default: nil

  def preview_filled_input(assigns) do
    ~H"""
    <input
      type="text"
      readonly
      value={value_or_blank(@value)}
      class="w-full rounded-lg border border-white/20 bg-white/10 px-3 py-2 text-sm text-white placeholder:text-white/50"
    />
    """
  end

  attr :number, :string, required: true
  attr :title, :string, required: true

  def numbered_heading(assigns) do
    ~H"""
    <div class="flex items-center gap-3">
      <div class="flex h-8 w-8 items-center justify-center rounded-full bg-[#373896] text-sm font-bold text-white">
        {@number}
      </div>
      <h2 class="text-sm font-bold uppercase tracking-wider text-gray-700">{@title}</h2>
    </div>
    """
  end

  attr :label, :string, required: true
  slot :inner_block, required: true

  def table_row(assigns) do
    ~H"""
    <tr>
      <td class="px-4 py-3 font-medium text-gray-600 w-52 bg-gray-50">{@label}</td>
      <td class="px-4 py-3">{render_slot(@inner_block)}</td>
    </tr>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, default: nil

  def receipt_row(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 md:flex-row md:items-center">
      <span class="text-sm font-bold text-[#373896] w-44 shrink-0">{@label}</span>
      <.preview_inline_input value={@value} />
    </div>
    """
  end

  defp value_or_blank(value) do
    value
    |> format_field()
    |> case do
      nil -> ""
      "" -> ""
      formatted -> formatted
    end
  end

  defp present?(value) do
    case value_or_blank(value) do
      "" -> false
      _ -> true
    end
  end

  defp coalesce(values) when is_list(values) do
    Enum.find_value(values, &non_blank/1)
  end

  defp coalesce(a, b), do: coalesce([a, b])
  defp coalesce(a, b, c), do: coalesce([a, b, c])

  defp non_blank(value) do
    case value_or_blank(value) do
      "" -> nil
      formatted -> formatted
    end
  end

  defp selected?(data, key, value), do: value_or_blank(data[key]) == value

  defp format_field(nil), do: nil
  defp format_field(value), do: display_value(value)
end
