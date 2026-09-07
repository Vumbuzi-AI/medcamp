defmodule MedcampWeb.DoctorNotesComponents do
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext
  import MedcampWeb.CoreComponents
  alias Medcamp.ArtificialIntelligence.VoiceDictation
  alias Phoenix.LiveView.JS

  def doctor_note_tabs(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-1 mb-6">
      <div class="flex border-b border-gray-100">
        <%= for tab <- @tabs do %>
          <div
            phx-click="change-tab"
            phx-value-tab={tab.id}
            class={"px-4 py-3 text-sm font-medium cursor-pointer border-b-2 transition-colors " <>
            if(@current_tab == tab.id, do: "border-[#373896] text-[#373896]", else: "border-transparent text-gray-500 hover:text-[#6667ab]")}
          >
            <div class="flex items-center gap-1">
              <%= if tab.icon_name do %>
                <Heroicons.icon name={tab.icon_name} type="outline" class="h-4 w-4" />
              <% else %>
                {Phoenix.HTML.raw(tab.icon_markup)}
              <% end %>
              {tab.label}
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :add_note_click, :string, default: nil
  attr :new_note_url, :string, default: nil
  attr :route_prefix, :string, required: true
  attr :streams, :map, required: true
  attr :patient, :map, required: true
  attr :count, :integer, required: true

  def doctor_notes_table(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-[#373896] text-base border-b flex-col md:flex-row gap-6 border-gray-100 pb-4 mb-4">
        <div class="flex  items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <p class="text-sm">
            Doctor Notes for {[@patient.first_name, @patient.middle_name, @patient.last_name]
            |> Enum.filter(&(&1 != nil))
            |> Enum.join(" ")}
          </p>
        </div>
      </.header>

      <div class="mb-2">
        <%= if @add_note_click do %>
          <button
            type="button"
            phx-click={@add_note_click}
            class="inline-flex items-center gap-2 rounded-lg bg-[#6667ab] px-4 py-2 text-sm font-semibold text-white hover:bg-[#5556a0] focus:z-10"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4"
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
            Add Doctor Note
          </button>
        <% else %>
          <.link patch={@new_note_url || "#"}>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
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
                Add Doctor Note
              </div>
            </.button>
          </.link>
        <% end %>
      </div>

      <.blank_state
        :if={@count == 0}
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="No doctor notes found"
        description="No doctor notes have been recorded for this patient yet."
      />

      <.table
        :if={@count > 0}
        id="doctor_notes"
        rows={@doctor_notes}
        row_click={fn doctor_note -> JS.navigate("#{@route_prefix}/#{doctor_note.id}") end}
        row_id={&"doctor_notes-#{&1.id}"}
      >
        <:col :let={doctor_note} label="Doctor">
          <div class="flex items-center py-3">
            <span class="px-2 py-1 text-xs rounded-full bg-[#e7e7ff] text-[#373896] font-medium">
              Dr. {doctor_note.doctor.name}
            </span>
          </div>
        </:col>

        <:col :let={doctor_note} label="Date">
          <div class="flex items-center py-3">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4 mr-1 text-[#6667ab]"
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
            <div class="flex flex-col gap-2">
              <span class="text-gray-700">{doctor_note.date}</span>
              <span class="text-gray-700">{doctor_note.time}</span>
            </div>
          </div>
        </:col>

        <:col :let={doctor_note} label="Actions">
          <div class="flex items-center space-x-2 py-3">
            <.link
              navigate={"#{@route_prefix}/#{doctor_note.id}"}
              class="text-[#6667ab] hover:text-[#373896]"
            >
              <div class="flex items-center">
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
              </div>
            </.link>
          </div>
        </:col>
      </.table>
    </div>
    """
  end

  attr :route_prefix, :string, required: true
  attr :streams, :map, required: true
  attr :patient, :map, required: true
  attr :count, :integer, required: true

  def nurse_doctor_notes_table(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          Listing Doctor Notes for {[@patient.first_name, @patient.middle_name, @patient.last_name]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>
      </.header>

      <.blank_state
        :if={@count == 0}
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="No doctor notes found"
        description="No doctor notes have been recorded for this patient yet."
      />

      <.table
        :if={@count > 0}
        id="doctor_notes"
        rows={@doctor_notes}
        row_click={fn doctor_note -> JS.navigate("#{@route_prefix}/#{doctor_note.id}") end}
        row_id={&"doctor_notes-#{&1.id}"}
      >
        <:col :let={doctor_note} label="Doctor">
          <div class="flex items-center py-3">
            <span class="px-2 py-1 text-xs rounded-full bg-[#e7e7ff] text-[#373896] font-medium">
              Dr. {doctor_note.doctor.name}
            </span>
          </div>
        </:col>

        <:col :let={doctor_note} label="Date">
          <div class="flex items-center py-3">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4 mr-1 text-[#6667ab]"
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
            <span class="text-gray-700">{doctor_note.date}</span>
          </div>
        </:col>

        <:col :let={doctor_note} label="Time">
          <div class="flex items-center py-3">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4 mr-1 text-[#6667ab]"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span class="text-gray-700">{doctor_note.time}</span>
          </div>
        </:col>

        <:col :let={doctor_note} label="Reason">
          <div class="py-3 max-w-xs">
            <p class="text-gray-700 truncate" title={doctor_note.reason_for_consulatation}>
              {doctor_note.reason_for_consulatation}
            </p>
          </div>
        </:col>

        <:col :let={doctor_note} label="Diagnosis">
          <div class="py-3 flex items-center gap-2">
            <%= if doctor_note.diagnosis && doctor_note.diagnosis != "" do %>
              <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium whitespace-nowrap">
                {doctor_note.diagnosis}
              </span>
              <%= if Map.get(doctor_note, :diagnosis_icd_code) && doctor_note.diagnosis_icd_code != "" do %>
                <span class="text-xs text-gray-500 whitespace-nowrap">
                  ICD-11: {doctor_note.diagnosis_icd_code}
                </span>
              <% end %>
            <% else %>
              <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-500 font-medium">
                No diagnosis
              </span>
            <% end %>
          </div>
        </:col>

        <:col :let={doctor_note} label="Actions">
          <div class="flex items-center space-x-2 py-3">
            <.link
              navigate={"#{@route_prefix}/#{doctor_note.id}"}
              class="text-[#6667ab] hover:text-[#373896]"
            >
              <div class="flex items-center">
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
              </div>
            </.link>
          </div>
        </:col>
      </.table>
    </div>
    """
  end

  @doc """
  A textarea field with a voice-dictation mic button.

  Wraps `CoreComponents.input/1` (type `textarea`) and attaches the
  `VoiceInput` JS hook, which records audio, transcribes it via
  `/doctor/transcribe`, translates supported spoken languages to English, and
  inserts the English text into the field.
  """
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :placeholder, :string, default: nil
  attr :rows, :integer, default: 3
  attr :class, :string, default: nil

  def voice_textarea(assigns) do
    ~H"""
    <div id={"voice-#{@field.id}"} phx-hook="VoiceInput">
      <div data-role="voice-field-header" class="flex items-center gap-2">
        <.label for={@field.id}>{@label}</.label>
        <button
          type="button"
          data-role="voice-btn"
          title="Dictate in a supported language and translate to English"
          class="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-medium text-[#6667ab] transition-colors hover:bg-[#f0f0ff] disabled:opacity-60"
        >
          <Heroicons.icon name="microphone" type="outline" class="h-4 w-4" />
          <span data-role="voice-label">Dictate</span>
        </button>
      </div>
      <.input field={@field} type="textarea" placeholder={@placeholder} rows={@rows} class={@class} />

      <div
        data-role="voice-language-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby={"voice-language-title-#{@field.id}"}
        class="hidden fixed inset-0 z-50 flex items-center justify-center bg-slate-950/40 p-4"
      >
        <div class="w-full max-w-lg rounded-xl bg-white p-6 shadow-2xl" data-role="voice-dialog">
          <h3 id={"voice-language-title-#{@field.id}"} class="text-lg font-semibold text-[#373896]">
            Voice dictation
          </h3>
          <p class="mt-2 text-sm text-gray-600">
            Record, review, and edit the English text before adding it to the note.
          </p>

          <p
            data-role="voice-error"
            class="hidden mt-4 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700"
          >
          </p>

          <div data-role="voice-setup">
            <label
              class="mt-5 block text-sm font-medium text-gray-800"
              for={"voice-language-#{@field.id}"}
            >
              Spoken language
            </label>
            <select
              id={"voice-language-#{@field.id}"}
              data-role="voice-language"
              class="mt-2 block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm text-gray-900 focus:border-[#6667ab] focus:outline-none focus:ring-2 focus:ring-[#6667ab]/20"
            >
              <optgroup label="Kenyan languages">
                <option :for={{code, name} <- VoiceDictation.kenyan_languages()} value={code}>
                  {name}
                </option>
              </optgroup>
              <optgroup label="Other languages">
                <option :for={{code, name} <- VoiceDictation.other_languages()} value={code}>
                  {name}
                </option>
              </optgroup>
            </select>
            <p class="mt-2 text-xs text-gray-500">
              Experimental languages may be less accurate. Always review clinical details before saving.
            </p>

            <div class="mt-6 flex justify-end gap-3">
              <button
                type="button"
                data-role="voice-cancel"
                class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="button"
                data-role="voice-start"
                class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-medium text-white hover:bg-[#2f307f]"
              >
                Start dictating
              </button>
            </div>
          </div>

          <div data-role="voice-progress" class="hidden mt-6 text-center">
            <div class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-red-50 text-red-600">
              <svg class="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 11a7 7 0 01-14 0m7 7v3m-4 0h8M12 3a3 3 0 00-3 3v5a3 3 0 006 0V6a3 3 0 00-3-3z"
                />
              </svg>
            </div>
            <p data-role="voice-status" class="mt-4 text-sm font-medium text-gray-800">
              Recording…
            </p>
            <p class="mt-1 text-xs text-gray-500">Speak clearly and include punctuation naturally.</p>
            <div class="mt-6 flex justify-center gap-3">
              <button
                type="button"
                data-role="voice-progress-cancel"
                class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="button"
                data-role="voice-stop"
                class="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60"
              >
                Stop recording
              </button>
            </div>
          </div>

          <div data-role="voice-result" class="hidden mt-5">
            <label
              class="block text-sm font-medium text-gray-800"
              for={"voice-transcript-#{@field.id}"}
            >
              English transcription
            </label>
            <textarea
              id={"voice-transcript-#{@field.id}"}
              data-role="voice-transcript"
              rows="7"
              class="mt-2 block w-full resize-y rounded-lg border border-gray-300 px-3 py-2.5 text-sm text-gray-900 focus:border-[#6667ab] focus:outline-none focus:ring-2 focus:ring-[#6667ab]/20"
              placeholder="Your English transcription will appear here for review."
            ></textarea>
            <p class="mt-2 text-xs text-gray-500">
              Review clinical terms, medication names, doses, and negations before saving.
            </p>
            <div class="mt-6 flex flex-wrap justify-end gap-3">
              <button
                type="button"
                data-role="voice-retry"
                class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Record again
              </button>
              <button
                type="button"
                data-role="voice-result-cancel"
                class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="button"
                data-role="voice-save"
                class="rounded-lg bg-[#373896] px-4 py-2 text-sm font-medium text-white hover:bg-[#2f307f]"
              >
                Save to note
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def doctor_notes_form(assigns) do
    assigns =
      assigns
      |> assign_new(:icd_options, fn -> Medcamp.Icd11.options() end)
      |> assign_new(:draft_key, fn -> nil end)

    ~H"""
    <.simple_form
      for={@form}
      id="doctor_note-form"
      phx-change="validate"
      phx-submit="save"
      phx-hook={@draft_key && "DraftPersistence"}
      data-draft-key={@draft_key}
      class="space-y-6"
    >
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div class="flex items-center mb-6 pb-2 border-b border-gray-100">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            />
          </svg>
          <h2 class="text-lg font-semibold text-[#373896]">
            Consultation Details
          </h2>
        </div>

        <div class="mb-4 flex items-start gap-2 rounded-lg border border-amber-200 bg-amber-50 p-3">
          <Heroicons.icon
            name="information-circle"
            type="outline"
            class="h-5 w-5 flex-shrink-0 text-amber-600"
          />
          <p class="text-xs text-amber-800">
            This note's content may be sent to an AI service for the optional AI Review.
            Avoid including patient names, phone numbers, national ID numbers, or other
            identifying details in the fields below — describe findings clinically instead.
          </p>
        </div>

        <div class="space-y-5">
          <div class="grid grid-cols-1 gap-4">
            <.input
              field={@form[:date]}
              type="date"
              label="Date"
              class="focus:border-[#6667ab] focus:ring-[#6667ab]"
            />
            <input type="hidden" name={@form[:time].name} value={@form[:time].value} />
          </div>

          <div
            :if={@patient.gender == "Female"}
            class="bg-[#f8f8ff] p-4 rounded-lg border border-[#e7e7ff]"
          >
            <.input
              field={@form[:last_period_date]}
              type="date"
              label="Last period date"
              class="focus:border-[#6667ab] focus:ring-[#6667ab]"
            />
          </div>

          <.voice_textarea
            field={@form[:reason_for_consulatation]}
            label="Complaints"
            placeholder="Enter patient's symptoms and complaints..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <.voice_textarea
            field={@form[:clinical_notes]}
            label="Clinical Notes"
            placeholder="Enter any clinical notes or observations..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <.voice_textarea
            field={@form[:past_medical_history]}
            label="Past medical and Surgical history"
            placeholder="Enter the patient's past medical history..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <.voice_textarea
            field={@form[:symptoms]}
            label="Examinations"
            placeholder="Enter examination findings..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <.voice_textarea
            field={@form[:impression]}
            label="Impression"
            placeholder="Enter your impression based on the examination findings..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />
          <.voice_textarea
            field={@form[:management]}
            label="Management"
            placeholder="Enter planned lab
    and imaging investigations, medications to be prescribed/stopped/changed for the patient,
    minor/major surgical interventions planned, and admission."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />
          <.voice_textarea
            field={@form[:investigations]}
            label="Investigations"
            placeholder="Document any investigations performed or ordered..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">Diagnosis (ICD-11)</label>
            <select
              name="doctor_note[diagnosis_icd_code]"
              class="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-[#6667ab] focus:border-[#6667ab]"
            >
              <option value="">Select diagnosis code...</option>
              <%= for {label, code} <- @icd_options do %>
                <option value={code} selected={@form[:diagnosis_icd_code].value == code}>
                  {label}
                </option>
              <% end %>
            </select>
            <.voice_textarea
              field={@form[:diagnosis]}
              label="Diagnosis notes (optional)"
              placeholder="Add any additional diagnosis details..."
              rows={2}
              class="focus:border-[#6667ab] focus:ring-[#6667ab]"
            />
          </div>
        </div>
      </div>

      <div
        :if={@form.data.lab_imaging_request}
        class="bg-white rounded-lg shadow-sm border border-gray-200 p-6"
      >
        <div class="flex items-center mb-6 pb-2 border-b border-gray-100">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2"
            />
          </svg>
          <h2 class="text-lg font-semibold text-[#373896]">
            Lab & Imaging Request
          </h2>
        </div>

        <.input
          readonly
          field={@form[:lab_imaging_request]}
          type="textarea"
          label="Lab imaging request"
          rows={4}
          class="bg-gray-50"
        />
      </div>

      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div class="flex items-center mb-4 pb-2 border-b border-gray-100">
          <h2 class="text-lg font-semibold text-[#373896]">
            Doctor's Signature
          </h2>
        </div>

        <p class="mb-3 text-xs text-gray-500">
          Sign to certify this note. Signing is optional when saving a draft, but the note
          should be signed before it is treated as final.
        </p>

        <.signature_pad
          id="doctor_note-signature"
          label="Doctor's Signature"
          name={@form[:doctor_signature].name}
          value={@form[:doctor_signature].value}
        />

        <p :if={@form[:signed_at].value} class="mt-2 text-xs text-gray-400">
          Signed {Calendar.strftime(@form[:signed_at].value, "%d %b %Y, %H:%M")}
        </p>
      </div>

      <div class="flex justify-end">
        <.button
          phx-disable-with="Saving..."
          class="bg-[#6667ab] hover:bg-[#5556a0] px-5 py-2.5 flex items-center gap-2"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"
            />
          </svg>
          Save Doctor Note
        </.button>
      </div>
    </.simple_form>
    """
  end

  attr :editable, :boolean, default: false
  attr :patient, :map, required: true
  attr :form, :any, required: true
  attr :show_lab_imaging_request, :boolean, default: false

  def doctor_notes_form_for_nurse(assigns) do
    ~H"""
    <.simple_form
      for={@form}
      id="doctor_note-form"
      phx-change="validate"
      phx-submit="save"
      class="space-y-6"
    >
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div class="flex items-center mb-6 pb-2 border-b border-gray-100">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            />
          </svg>
          <h2 class="text-lg font-semibold text-[#373896]">
            Consultation Details
          </h2>
        </div>

        <div class="space-y-5">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input
              field={@form[:date]}
              type="date"
              disabled
              label="Date"
              class="focus:border-[#6667ab] focus:ring-[#6667ab]"
            />
            <.input
              field={@form[:time]}
              type="time"
              disabled
              label="Time"
              class="focus:border-[#6667ab] focus:ring-[#6667ab]"
            />
          </div>

          <div
            :if={@patient.gender == "Female"}
            class="bg-[#f8f8ff] p-4 rounded-lg border border-[#e7e7ff]"
          >
            <.input
              field={@form[:last_period_date]}
              type="date"
              disabled={!@editable}
              label="Last period date"
              class="focus:border-[#6667ab] focus:ring-[#6667ab]"
            />
          </div>

          <.input
            field={@form[:reason_for_consulatation]}
            type="textarea"
            label="Complaints"
            disabled={!@editable}
            placeholder="Enter patient's symptoms and complaints..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <.input
            field={@form[:clinical_notes]}
            type="textarea"
            disabled={!@editable}
            label="Clinical Notes"
            placeholder="Enter any clinical notes or observations..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <.input
            field={@form[:past_medical_history]}
            type="textarea"
            disabled={!@editable}
            label="Past medical and Surgical history"
            placeholder="Enter the patient's past medical history..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <.input
            field={@form[:symptoms]}
            disabled={!@editable}
            type="textarea"
            label="Examinations"
            placeholder="Enter examination findings..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <.input
            field={@form[:impression]}
            disabled={!@editable}
            type="textarea"
            label="Impression"
            placeholder="Enter your impression based on the examination findings..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />
          <.input
            field={@form[:management]}
            disabled={!@editable}
            type="textarea"
            label="Management"
            placeholder="Enter planned lab and imaging investigations, medications to be prescribed/stopped/changed for the patient, minor/major surgical interventions planned, and admission."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />
          <.input
            field={@form[:investigations]}
            disabled={!@editable}
            type="textarea"
            label="Investigations"
            placeholder="Document any investigations performed or ordered..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />

          <.input
            field={@form[:diagnosis]}
            disabled={!@editable}
            type="textarea"
            label="Diagnosis"
            placeholder="Enter your diagnosis based on the findings..."
            rows={3}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />
        </div>
      </div>

      <div
        :if={@form.data.lab_imaging_request}
        class="bg-white rounded-lg shadow-sm border border-gray-200 p-6"
      >
        <div class="flex items-center mb-6 pb-2 border-b border-gray-100">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2"
            />
          </svg>
          <h2 class="text-lg font-semibold text-[#373896]">
            Lab & Imaging Request
          </h2>
        </div>

        <.input
          readonly
          field={@form[:lab_imaging_request]}
          type="textarea"
          disabled
          label="Lab imaging request"
          rows={4}
          class="bg-gray-50"
        />
      </div>

      <div :if={@editable} class="flex items-center justify-end gap-3 pb-2">
        <button
          type="button"
          phx-click="toggle_edit"
          class="px-4 py-2 text-sm font-medium text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
        >
          Cancel
        </button>
        <button
          type="submit"
          class="inline-flex items-center gap-2 rounded-lg bg-[#373896] px-5 py-2 text-sm font-semibold text-white hover:bg-[#2a2b73] transition-colors"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"
            />
          </svg>
          Save Changes
        </button>
      </div>
    </.simple_form>
    """
  end

  attr :child_notes, :list, required: true
  attr :parent_note_id, :integer, required: true
  attr :current_user, :map, required: true
  attr :expanded_ids, :list, default: []

  def child_doctor_notes_section(assigns) do
    ~H"""
    <div class="mt-6 border-t border-gray-100 pt-4">
      <div class="flex items-center justify-between mb-3">
        <h3 class="text-sm font-semibold text-[#373896] flex items-center gap-2">
          <Heroicons.icon name="document-duplicate" type="outline" class="h-4 w-4" /> Sub-notes
          <span class="px-2 py-0.5 text-xs rounded-full bg-[#e7e7ff] text-[#373896]">
            {length(@child_notes)}
          </span>
        </h3>
        <button
          type="button"
          phx-click="open_add_sub_note"
          class="inline-flex items-center gap-1.5 rounded-lg bg-[#6667ab] px-3 py-1.5 text-xs font-semibold text-white hover:bg-[#5556a0] transition-colors"
        >
          <Heroicons.icon name="plus" type="outline" class="h-3.5 w-3.5" /> Add Sub-note
        </button>
      </div>

      <%= if @child_notes == [] do %>
        <div class="text-center py-6 text-gray-400 text-sm bg-gray-50 rounded-lg border border-dashed border-gray-200">
          No sub-notes yet. Add one to collaborate on this note.
        </div>
      <% else %>
        <div class="space-y-2">
          <%= for note <- @child_notes do %>
            <div class="border border-gray-200 rounded-lg overflow-hidden">
              <button
                type="button"
                phx-click="toggle_sub_note"
                phx-value-id={note.id}
                class="w-full flex items-center justify-between px-4 py-3 bg-gray-50 hover:bg-[#f0f0ff] transition-colors text-left"
              >
                <div class="flex items-center gap-3">
                  <Heroicons.icon name="document-text" type="outline" class="h-4 w-4 text-[#6667ab]" />
                  <div>
                    <span class="text-sm font-medium text-gray-800">
                      Dr. {note.doctor.name}
                    </span>
                    <span class="ml-2 text-xs text-gray-500">
                      {note.date} at {note.time}
                    </span>
                  </div>
                  <%= if note.diagnosis && note.diagnosis != "" do %>
                    <span class="px-2 py-0.5 text-xs rounded-full bg-green-100 text-green-700 font-medium">
                      {note.diagnosis}
                    </span>
                  <% end %>
                </div>
                <Heroicons.icon
                  name={if note.id in @expanded_ids, do: "chevron-up", else: "chevron-down"}
                  type="outline"
                  class="h-4 w-4 text-gray-400 flex-shrink-0"
                />
              </button>

              <div :if={note.id in @expanded_ids} class="px-4 py-4 bg-white border-t border-gray-100">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                  <div>
                    <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                      Doctor
                    </p>
                    <p class="text-sm text-gray-800">Dr. {note.doctor.name}</p>
                  </div>
                  <div>
                    <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                      Date & Time
                    </p>
                    <p class="text-sm text-gray-800">{note.date} at {note.time}</p>
                  </div>
                </div>

                <%= for {label, value} <- [
                  {"Complaints", note.reason_for_consulatation},
                  {"Clinical Notes", note.clinical_notes},
                  {"Past Medical & Surgical History", note.past_medical_history},
                  {"Examinations", note.symptoms},
                  {"Impression", note.impression},
                  {"Management", note.management},
                  {"Investigations", note.investigations},
                  {"Diagnosis", note.diagnosis}
                ], value && value != "" do %>
                  <div class="mb-3">
                    <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                      {label}
                    </p>
                    <p class="text-sm text-gray-700 whitespace-pre-wrap">{value}</p>
                  </div>
                <% end %>

                <%= if note.diagnosis_icd_code && note.diagnosis_icd_code != "" do %>
                  <div class="mb-3">
                    <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                      ICD-11 Code
                    </p>
                    <span class="px-2 py-0.5 text-xs rounded-full bg-gray-100 text-gray-700">
                      {note.diagnosis_icd_code}
                    </span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :form, :map, required: true
  attr :patient, :map, required: true

  def sub_doctor_note_form(assigns) do
    assigns = assign_new(assigns, :icd_options, fn -> Medcamp.Icd11.options() end)

    ~H"""
    <.simple_form
      for={@form}
      id="sub-doctor-note-form"
      phx-change="validate_sub_note"
      phx-submit="save_sub_note"
      class="space-y-4"
    >
      <div class="space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:date]}
            type="date"
            label="Date"
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />
          <.input
            field={@form[:time]}
            type="time"
            label="Time"
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />
        </div>

        <div
          :if={@patient.gender == "Female"}
          class="bg-[#f8f8ff] p-4 rounded-lg border border-[#e7e7ff]"
        >
          <.input
            field={@form[:last_period_date]}
            type="date"
            label="Last period date"
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />
        </div>

        <.input
          field={@form[:reason_for_consulatation]}
          type="textarea"
          label="Complaints"
          placeholder="Enter patient's symptoms and complaints..."
          rows={3}
          class="focus:border-[#6667ab] focus:ring-[#6667ab]"
        />

        <.input
          field={@form[:clinical_notes]}
          type="textarea"
          label="Clinical Notes"
          placeholder="Enter any clinical notes or observations..."
          rows={3}
          class="focus:border-[#6667ab] focus:ring-[#6667ab]"
        />

        <.input
          field={@form[:past_medical_history]}
          type="textarea"
          label="Past Medical & Surgical History"
          placeholder="Enter the patient's past medical history..."
          rows={3}
          class="focus:border-[#6667ab] focus:ring-[#6667ab]"
        />

        <.input
          field={@form[:symptoms]}
          type="textarea"
          label="Examinations"
          placeholder="Enter examination findings..."
          rows={3}
          class="focus:border-[#6667ab] focus:ring-[#6667ab]"
        />

        <.input
          field={@form[:impression]}
          type="textarea"
          label="Impression"
          placeholder="Enter your impression..."
          rows={3}
          class="focus:border-[#6667ab] focus:ring-[#6667ab]"
        />

        <.input
          field={@form[:management]}
          type="textarea"
          label="Management"
          placeholder="Enter management plan..."
          rows={3}
          class="focus:border-[#6667ab] focus:ring-[#6667ab]"
        />

        <.input
          field={@form[:investigations]}
          type="textarea"
          label="Investigations"
          placeholder="Document any investigations performed or ordered..."
          rows={3}
          class="focus:border-[#6667ab] focus:ring-[#6667ab]"
        />

        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">Diagnosis (ICD-11)</label>
          <select
            name="sub_doctor_note[diagnosis_icd_code]"
            class="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-[#6667ab] focus:border-[#6667ab]"
          >
            <option value="">Select diagnosis code...</option>
            <%= for {label, code} <- @icd_options do %>
              <option value={code} selected={@form[:diagnosis_icd_code].value == code}>
                {label}
              </option>
            <% end %>
          </select>
          <.input
            field={@form[:diagnosis]}
            type="textarea"
            label="Diagnosis notes (optional)"
            placeholder="Add any additional diagnosis details..."
            rows={2}
            class="focus:border-[#6667ab] focus:ring-[#6667ab]"
          />
        </div>
      </div>

      <div class="flex justify-end gap-3 pt-2">
        <.button
          phx-disable-with="Saving..."
          class="bg-[#6667ab] hover:bg-[#5556a0] px-5 py-2.5 flex items-center gap-2"
        >
          <Heroicons.icon name="document-plus" type="outline" class="h-4 w-4" /> Save Sub-note
        </.button>
      </div>
    </.simple_form>
    """
  end

  def doctor_notes_card(assigns) do
    ~H"""
    <.simple_form for={%{}} id="doctor_note-form">
      <div class="border-[#D0D5DD] border-[1px] rounded-md p-4">
        <p class="text-xl mb-4 font-semibold text-darkblue">
          Consultation Details
        </p>
        <div class="flex flex-col gap-3">
          <.input name="date" value={@doctor_note.date} readonly type="date" label="Date" />
          <.input
            value={@doctor_note.reason_for_consulatation}
            readonly
            name="date"
            type="textarea"
            label="Complaints"
          />
          <.input name="date" readonly value={@doctor_note.symptoms} type="textarea" label="Symptoms" />
        </div>
      </div>

      <div class="border-[#D0D5DD] border-[1px] rounded-md p-4">
        <p class="text-xl mb-4 font-semibold text-darkblue">
          Diagnosis & Treatment
        </p>
        <div class="flex flex-col gap-3">
          <.input
            readonly
            value={@doctor_note.prescribed_medication}
            type="textarea"
            name="date"
            label="Prescribed medication"
          />
          <.input
            type="textarea"
            readonly
            name="date"
            value={@doctor_note.lifestyle_recommendations}
            label="Lifestyle recommendations"
          />
        </div>
      </div>
    </.simple_form>
    """
  end
end
