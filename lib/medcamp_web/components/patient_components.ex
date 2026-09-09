defmodule MedcampWeb.PatientComponents do
  use Phoenix.Component

  import MedcampWeb.OrganisationComponents, only: [current_organisation: 0]
  use Gettext, backend: MedcampWeb.Gettext
  import MedcampWeb.CoreComponents
  alias Phoenix.LiveView.JS

  def patients_table(assigns) do
    ~H"""
    <.header :if={Map.get(assigns, :show_header, true)} class="text-brand-primary">
      Patients
      <:actions>
        <.link :if={@show_new_link} patch={@new_patient_url}>
          <.button class="bg-brand-accent hover:bg-brand-accent-dark">Add New Patient</.button>
        </.link>
      </:actions>
    </.header>

    <.blank_state
      :if={@count == 0}
      icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
      title="No patients"
      description={
        if Map.get(assigns, :filters_active, false),
          do: "No patients match the current filters.",
          else: "No patients have been registered yet."
      }
    >
      <:actions :if={Map.get(assigns, :filters_active, false)}>
        <button phx-click="clear_filters" class="text-xs text-brand-accent hover:underline">
          Clear filters
        </button>
      </:actions>
    </.blank_state>
    <.data_table
      :if={@count > 0}
      id="patients"
      rows={@patients}
      row_click={fn patient -> JS.navigate("#{@route_prefix}/#{patient.id}") end}
      row_id={&"patients-#{&1.id}"}
    >
      <:col :let={patient} label="">
        <div class="flex flex-col gap-1">
          <div>
            <.button class=" text-brand-primary hover:bg-brand-200 border-0 font-normal text-sm">
              Patient Code
            </.button>
          </div>
          <p class="text-slate-500 text-sm font-medium mt-1">GSRN: {patient.gsrn}</p>
        </div>
      </:col>
      <:col :let={patient} label="Name">
        {[
          patient.first_name,
          patient.middle_name,
          patient.last_name
        ]
        |> Enum.filter(&(&1 != nil))
        |> Enum.join(" ")}
      </:col>
      <:col :let={patient} label="Email">{patient.email}</:col>

      <:col :let={patient} label="Phone Number">{patient.phone_number}</:col>
      <:col :let={patient} label="National ID">{patient.national_id}</:col>
      <:col :let={patient} label="Gender">{patient.gender}</:col>

      <:action :let={patient}>
        <.link
          navigate={"#{@route_prefix}/#{patient.id}/edit"}
          class="text-brand-accent hover:text-brand-primary font-medium"
        >
          Edit
        </.link>
      </:action>
    </.data_table>
    """
  end

  def admin_patients_table(assigns) do
    ~H"""
    <.blank_state
      :if={@total_count == 0}
      icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
      title="No patients"
      description={
        if Map.get(assigns, :filters_active, false),
          do: "No patients match the current filters.",
          else: "No patients have been registered yet."
      }
    >
      <:actions :if={Map.get(assigns, :filters_active, false)}>
        <button phx-click="clear_filters" class="text-xs text-brand-accent hover:underline">
          Clear filters
        </button>
      </:actions>
    </.blank_state>
    <.data_table
      :if={@total_count > 0}
      id="patients"
      rows={@patients}
      row_click={fn patient -> JS.navigate("/admin/patients/#{patient.id}") end}
      row_id={&"patients-#{&1.id}"}
    >
      <:col :let={patient} label="">
        <div class="flex flex-col gap-1">
          <div>
            <.button class=" text-brand-primary hover:bg-brand-200 border-0 font-normal text-sm">
              Patient Code
            </.button>
          </div>
          <p class="text-slate-500 text-sm font-medium mt-1">GSRN: {patient.gsrn}</p>
        </div>
      </:col>
      <:col :let={patient} label="Name">
        {[
          patient.first_name,
          patient.middle_name,
          patient.last_name
        ]
        |> Enum.filter(&(&1 != nil))
        |> Enum.join(" ")}
      </:col>
      <:col :let={patient} label="Email">{patient.email} {patient.pin}</:col>
      <:col :let={patient} label="Pin">{patient.pin}</:col>

      <:col :let={patient} label="Phone Number">{patient.phone_number}</:col>
      <:col :let={patient} label="National ID">{patient.national_id}</:col>
      <:col :let={patient} label="Gender">{patient.gender}</:col>
    </.data_table>
    <.pagination
      page={@page}
      total_pages={@total_pages}
      total_count={@total_count}
      per_page={@per_page}
    />
    """
  end

  def patients_table_for_receptionists(assigns) do
    assigns =
      assign(
        assigns,
        :row_click,
        Map.get(assigns, :row_click, fn patient ->
          JS.navigate("#{assigns.route_prefix}/#{patient.id}/patient_overview")
        end)
      )

    assigns = assign(assigns, :show_print_code, Map.get(assigns, :show_print_code, false))

    ~H"""
    <div
      :if={Map.get(assigns, :show_header, true)}
      class="bg-white rounded-lg border border-slate-100 p-4"
    >
      <.header class="text-brand-primary border-b border-slate-100 pb-4 mb-4">
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
              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            />
          </svg>
          Patients
        </div>
        <:actions>
          <.link :if={@show_new_link} patch={@new_patient_url}>
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
                Add New Patient
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>
    </div>

    <.blank_state
      :if={@count == 0}
      icon_path="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
      title="No patients"
      description={
        if Map.get(assigns, :filters_active, false),
          do: "No patients match the current filters.",
          else: "No patients have been registered yet."
      }
    >
      <:actions :if={Map.get(assigns, :filters_active, false)}>
        <button phx-click="clear_filters" class="text-xs text-brand-accent hover:underline">
          Clear filters
        </button>
      </:actions>
    </.blank_state>
    <.data_table
      :if={@count > 0}
      id="patients"
      rows={@patients}
      row_click={@row_click}
      row_id={&"patients-#{&1.id}"}
    >
      <:col :let={patient} label="">
        <div class="flex flex-col gap-1">
          <button
            :if={@show_print_code}
            type="button"
            phx-click="show_patient_code"
            phx-value-patient_id={patient.id}
            class="w-fit rounded-md bg-brand-accent px-3 py-2 text-sm font-medium text-white hover:bg-brand-accent-dark"
          >
            Print code
          </button>
          <span :if={!@show_print_code} class="text-sm font-medium text-slate-500">Patient code</span>
          <p class="text-slate-500 text-sm font-medium mt-1">GSRN: {patient.gsrn}</p>
        </div>
      </:col>
      <:col :let={patient} label="Name">
        {[
          patient.first_name,
          patient.middle_name,
          patient.last_name
        ]
        |> Enum.filter(&(&1 != nil))
        |> Enum.join(" ")}
      </:col>
      <:col :let={patient} label="Email">{patient.email}</:col>

      <:col :let={patient} label="Phone Number">{patient.phone_number}</:col>
      <:col :let={patient} label="National ID">{patient.national_id}</:col>
      <:col :let={patient} label="Gender">{patient.gender}</:col>

      <:action :let={patient}>
        <button
          type="button"
          phx-click="send_pin"
          phx-value-patient_id={patient.id}
          data-confirm-message="Are you sure you want to send the PIN?"
          phx-disable-with="Sending..."
          aria-label={"Resend PIN to #{patient.first_name} #{patient.last_name}"}
          class="inline-flex items-center justify-center gap-1.5 rounded-md bg-brand-accent px-3 py-2 text-center text-sm font-medium text-white transition hover:bg-brand-primary focus:outline-none focus:ring-2 focus:ring-brand-accent focus:ring-offset-2 disabled:cursor-wait disabled:opacity-60"
        >
          <.icon name="hero-paper-airplane-mini" class="h-4 w-4" /> Resend PIN
        </button>
      </:action>
      <:action :let={patient}>
        <.link
          navigate={"#{@route_prefix}/#{patient.id}/patient_overview"}
          class="text-brand-accent hover:text-brand-primary font-medium"
        >
          Edit
        </.link>
      </:action>
    </.data_table>
    """
  end

  attr :show_birth_certificate, :boolean, default: true
  attr :show_insurance_details, :boolean, default: true
  attr :new_triage_url, :string, default: nil
  attr :patient, :map, required: true
  attr :form, :any, required: true
  attr :most_recent_triage, :any, default: nil
  attr :back_url, :string, required: true

  def patient_overview(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-slate-100 p-6">
      <div class="flex gap-2 text-brand-primary font-semibold items-center mb-6">
        <.link navigate={@back_url} class="hover:text-brand-accent transition-colors">
          <Heroicons.icon name="arrow-left" type="outline" class="h-5 w-5" />
        </.link>
        <p class="text-lg">
          Patient list / Patients Details / {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </p>
      </div>

      <div class="flex flex-col md:flex-row gap-6">
        <!-- Patient summary card -->
        <div class="w-full md:w-1/3 bg-[#f8f8ff] rounded-lg p-5 border border-slate-100">
          <div>
            <div id="my-downloadable-container" phx-hook="DownloadableDiv" class="relative rounded ">
              <div id="my-content-to-download" class="">
                <div class="  bg-white rounded-lg mx-auto my-5 p-4 border border-slate-200 relative overflow-hidden print:shadow-none print:m-0">
                  <div class="hidden"></div>

                  <div class="flex justify-between items-center w-[100%] border-b-2 border-brand-primary pb-2 mb-3">
                    <div class="text-brand-primary">
                      <div class="font-bold text-xs">
                        {Medcamp.Organisations.display_name(current_organisation())}
                      </div>
                      <div class="text-xs">Patient Identification Card</div>
                    </div>

                    <div>
                      <img
                        src={Medcamp.Organisations.logo_path(current_organisation())}
                        alt="Logo"
                        class="h-12 w-12 rounded-full object-contain"
                      />
                    </div>
                  </div>

                  <div class="flex justify-between">
                    <div class="flex-1">
                      <h2 class="text-base font-bold text-brand-primary m-0">
                        {[@patient.first_name, @patient.last_name]
                        |> Enum.filter(&(&1 != nil))
                        |> Enum.join(" ")}
                      </h2>
                      <p class="text-xs text-slate-600 mt-1 mb-2">
                        {@patient.gender}
                      </p>

                      <div class=" pt-2 flex justify-between gap-8 items-center">
                        <div class=" py-1 flex flex-col gap-0 text-xs rounded-full text-brand-primary font-medium">
                          <p>GSRN:</p>
                          <p>{@patient.gsrn}</p>
                        </div>

                        <input
                          type="text"
                          id="text"
                          value={"https://glocalhealthcentre.org/8018/#{@patient.gsrn}"}
                          class="hidden"
                        />
                      </div>
                    </div>
                    <div class="flex flex-col gap-1">
                      <div class="flex text-xs gap-0 items-center">
                        GS1 <span class="text-sm">&#174; </span>
                      </div>

                      <div class="w-[80px] h-[80px]">
                        <div
                          phx-hook="CardQrCode"
                          phx-update="ignore"
                          id="qrcode"
                          class="rounded-md  "
                        />
                      </div>
                    </div>
                  </div>

                  <div class="text-center text-slate-400 italic text-[8px] mt-2">
                    Please bring this card to all appointments
                  </div>
                </div>
              </div>

              <button
                data-download-trigger
                data-target-div="#my-content-to-download"
                data-filename="Card.png"
                class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
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
                    d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                  />
                </svg>
                Download Card
              </button>
              <button
                data-print-trigger
                data-target-div="#my-content-to-download"
                class="ml-2 inline-flex items-center rounded-md border border-brand-primary px-3 py-2 text-sm font-medium text-brand-primary hover:bg-brand-50"
              >
                <Heroicons.icon name="printer" type="outline" class="mr-1 h-4 w-4" /> Print Code
              </button>
            </div>
          </div>

          <div class="border-t border-slate-200 my-4"></div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
            <div>
              <p class="text-sm text-slate-500 mb-1">Phone Number</p>
              <p class="font-medium">{@patient.phone_number}</p>
            </div>

            <div>
              <p class="text-sm text-slate-500 mb-1">Date of Birth</p>
              <p class="font-medium">{@patient.date_of_birth}</p>
            </div>

            <div>
              <p class="text-sm text-slate-500 mb-1">Gender</p>
              <p class="font-medium">{@patient.gender}</p>
            </div>

            <div>
              <p class="text-sm text-slate-500 mb-1">National ID</p>
              <p class="font-medium">{@patient.national_id}</p>
              <a
                :if={@patient.national_id_document}
                href={@patient.national_id_document}
                download
                target="_blank"
                class="text-xs text-blue-600 hover:text-blue-800"
              >
                View document
              </a>
            </div>

            <div :if={@show_birth_certificate}>
              <p class="text-sm text-slate-500 mb-1">Birth Certificate Number</p>
              <p class="font-medium">{@patient.birth_certificate_number || "—"}</p>
              <a
                :if={@patient.birth_certificate_document}
                href={@patient.birth_certificate_document}
                download
                target="_blank"
                class="text-xs text-blue-600 hover:text-blue-800"
              >
                View document
              </a>
            </div>

            <div>
              <p class="text-sm text-slate-500 mb-1">Email</p>
              <p class="font-medium">{@patient.email}</p>
            </div>
          </div>
          <div>
            <p class="text-sm text-slate-500 mb-1">Residence</p>
            <p class="font-medium">{@patient.home_address}</p>
          </div>

          <div class="border-t border-slate-200 my-4"></div>

          <div class="mb-4">
            <h3 class="text-md font-semibold text-brand-primary mb-2">Emergency Contact</h3>
            <div class="grid grid-cols-1 gap-2">
              <div>
                <p class="text-sm text-slate-500 mb-1">Name</p>
                <p class="font-medium">{@patient.emergency_contact_name}</p>
              </div>
              <div>
                <p class="text-sm text-slate-500 mb-1">Phone</p>
                <p class="font-medium">{@patient.emergency_contact_phone_number}</p>
              </div>
              <div>
                <p class="text-sm text-slate-500 mb-1">Relationship</p>
                <p class="font-medium">{@patient.emergency_contact_relationship}</p>
              </div>
            </div>
          </div>

          <div class="border-t border-slate-200 my-4"></div>

          <div>
            <div :if={@show_insurance_details}>
              <h3 class="mb-2 text-md font-semibold text-brand-primary">
                Insurance Details
              </h3>

              <div class="grid grid-cols-1 gap-2">
                <div>
                  <p class="mb-1 text-sm text-slate-500">
                    Insurance Status
                  </p>

                  <p class="font-medium">
                    <%= if @patient.has_insurance do %>
                      <span class="text-green-600">Insured</span>
                    <% else %>
                      <span class="text-slate-600">Not Insured</span>
                    <% end %>
                  </p>
                </div>

                <%= if @patient.has_insurance do %>
                  <div>
                    <p class="mb-1 text-sm text-slate-500">
                      Insurance Scheme
                    </p>

                    <p class="font-medium">
                      {@patient.insurance_scheme}
                    </p>
                  </div>

                  <div>
                    <p class="mb-1 text-sm text-slate-500">
                      Insurance Number
                    </p>

                    <p class="font-medium">
                      {@patient.insurance_number}
                    </p>
                  </div>

                  <div>
                    <p class="mb-1 text-sm text-slate-500">
                      Cover Limit
                    </p>

                    <p class="font-medium">
                      KSh {@patient.insurance_cover_limit}
                    </p>
                  </div>
                <% end %>
              </div>
            </div>

            <div class="my-4 border-t border-slate-200"></div>

            <%= if Enum.empty?(@patient.documents) do %>
              <div class="rounded-lg border border-dashed border-slate-300 p-6 text-center">
                <Heroicons.icon
                  name="folder-open"
                  type="outline"
                  class="mx-auto h-10 w-10 text-slate-400"
                />

                <p class="mt-3 text-sm text-slate-500">
                  No patient documents have been uploaded.
                </p>
              </div>
            <% else %>
              <div class="grid grid-cols-1 gap-4">
                <%= for document <- @patient.documents do %>
                  <% document_url =
                    "/patients/#{@patient.id}/documents/#{document.document_type}" %>

                  <div class="flex gap-5 rounded-xl border border-slate-200 bg-slate-50 p-4">
                    <%= if String.starts_with?(document.content_type || "", "image/") do %>
                      <img
                        src={document_url}
                        alt={document.document_name}
                        class="h-28 w-28 rounded-lg border object-cover"
                      />
                    <% else %>
                      <div class="flex h-28 w-28 items-center justify-center rounded-lg border bg-white">
                        <Heroicons.icon
                          name="document-text"
                          type="outline"
                          class="h-12 w-12 text-brand-primary"
                        />
                      </div>
                    <% end %>

                    <div class="flex flex-1 flex-col justify-between">
                      <div>
                        <div class="flex items-center justify-between">
                          <h4 class="font-semibold capitalize text-brand-primary">
                            {document.document_type
                            |> Atom.to_string()
                            |> String.replace("_", " ")}
                          </h4>

                          <span class="rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-700">
                            Uploaded
                          </span>
                        </div>

                        <p class="mt-2 text-sm font-medium text-slate-700">
                          {document.document_name}
                        </p>

                        <p class="mt-1 text-xs text-slate-500">
                          {document.content_type}
                        </p>

                        <p class="mt-1 text-xs text-slate-400">
                          Uploaded {Calendar.strftime(document.inserted_at, "%d %b %Y %I:%M %p")}
                        </p>
                      </div>

                      <div class="mt-4 flex gap-2">
                        <a
                          href={document_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          class="rounded bg-brand-primary px-4 py-2 text-sm font-medium text-white transition hover:bg-[#2c2d75]"
                        >
                          View
                        </a>

                        <a
                          href={document_url <> "?download=true"}
                          class="rounded border border-brand-primary px-4 py-2 text-sm font-medium text-brand-primary transition hover:bg-brand-primary/10"
                        >
                          Download
                        </a>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <div class="w-full md:w-2/3">
          <div class="bg-white rounded-lg border border-slate-100 p-5">
            <h2 class="text-lg font-semibold text-brand-primary mb-4 flex items-center">
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
              Recent Vitals
            </h2>

            <%= if @most_recent_triage do %>
              <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-3  gap-4">
                <%= for vital <- recent_vitals(@most_recent_triage) do %>
                  <div class="flex flex-col p-4 rounded-lg bg-brand-50 border border-brand-100">
                    <p class="text-sm text-slate-600 mb-1">{vital.name}</p>
                    <p class="text-xl font-semibold text-brand-primary">{vital.value}</p>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="text-center py-6 bg-slate-50 rounded-lg border border-dashed border-slate-300">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="mx-auto h-12 w-12 text-slate-400"
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
                <h3 class="mt-2 text-sm font-medium text-slate-900">No vitals recorded</h3>
                <p class="mt-1 text-sm text-slate-500">
                  No triage information has been recorded for this patient yet.
                </p>
              </div>
            <% end %>
          </div>

          <div class="mt-6 flex flex-wrap justify-end gap-3">
            <.link
              :if={@new_triage_url}
              id="add-triage-details"
              navigate={@new_triage_url}
              class="inline-flex items-center rounded-lg bg-brand-primary px-4 py-2 text-sm font-semibold text-white hover:bg-brand-accent"
            >
              <Heroicons.icon name="plus" type="outline" class="h-4 w-4 mr-1" /> Add Triage Details
            </.link>
            <.button type="button" phx-click="edit_patient">
              <div class="flex items-center">
                <Heroicons.icon name="pencil-square" type="outline" class="h-4 w-4 mr-1" />
                Edit Patient
              </div>
            </.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def patient_overview_for_camp_details(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-slate-100 p-6">
      <div class="flex gap-2 text-brand-primary font-semibold items-center mb-6">
        <p class="text-lg">
          Patient list / Patients Details / {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </p>
      </div>

      <div
        :if={!assigns[:current_user] || assigns[:current_user].role != "nurse"}
        class="flex flex-col md:flex-row gap-6"
      >
        <div class="w-full">
          <div class="mt-4">
            <div class="w-full flex justify-end items-end">
              <.link navigate={"/8018/#{@patient.gsrn}/medical-camp/triages/new"}>
                <button class="bg-brand-accent text-white p-2 rounded-md py-2 my-4 hover:bg-brand-accent-dark">
                  Add New Triage
                </button>
              </.link>
            </div>
            <MedcampWeb.TriageComponents.triages_table
              route_prefix={"/8018/#{@patient.gsrn}/triages"}
              new_triage_url={"/8018/#{@patient.gsrn}/triages/new"}
              triages={@triages}
              show_new_link={false}
              row_click={assigns[:triage_row_click]}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def patient_overview_to_show_all(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-slate-100 p-6">
      <div class="flex gap-2 text-brand-primary font-semibold items-center mb-6">
        <.link navigate={@back_url} class="hover:text-brand-accent transition-colors">
          <Heroicons.icon name="arrow-left" type="outline" class="h-5 w-5" />
        </.link>
        <p class="text-lg">
          Patient list / Patients Details / {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </p>
      </div>

      <div class="flex flex-col md:flex-row gap-6">
        <!-- Patient summary card -->
        <div class="w-full md:w-1/3 bg-[#f8f8ff] rounded-lg p-5 border border-slate-100">
          <div>
            <div class="  bg-white rounded-lg mx-auto my-5 p-4 border border-slate-200 relative overflow-hidden print:shadow-none print:m-0">
              <div class="hidden"></div>

              <div class="flex justify-between items-center w-[100%] border-b-2 border-brand-primary pb-2 mb-3">
                <div class="text-brand-primary">
                  <div class="font-bold text-xs">
                    {Medcamp.Organisations.display_name(current_organisation())}
                  </div>
                  <div class="text-xs">Patient Identification Card</div>
                </div>

                <div>
                  <img
                    src={Medcamp.Organisations.logo_path(current_organisation())}
                    alt="Logo"
                    class="h-12 w-12 rounded-full object-contain"
                  />
                </div>
              </div>

              <div class="flex justify-between">
                <div class="flex-1">
                  <h2 class="text-base font-bold text-brand-primary m-0">
                    {[@patient.first_name, @patient.last_name]
                    |> Enum.filter(&(&1 != nil))
                    |> Enum.join(" ")}
                  </h2>
                  <p class="text-xs text-slate-600 mt-1 mb-2">
                    {@patient.gender}
                  </p>

                  <div class=" pt-2 flex justify-between gap-8 items-center">
                    <div class=" py-1 flex flex-col gap-0 text-xs rounded-full text-brand-primary font-medium">
                      <p>GSRN:</p>
                      <p>{@patient.gsrn}</p>
                    </div>

                    <input
                      type="text"
                      id="text"
                      value={"https://glocalhealthcentre.org/8018/#{@patient.gsrn}"}
                      class="hidden"
                    />
                  </div>
                </div>
                <div class="flex flex-col gap-1">
                  <div class="flex text-xs gap-0 items-center">
                    GS1 <span class="text-sm">&#174; </span>
                  </div>

                  <div class="w-[80px] h-[80px]">
                    <div phx-hook="CardQrCode" phx-update="ignore" id="qrcode" class="rounded-md  " />
                  </div>
                </div>
              </div>

              <div class="text-center text-slate-400 italic text-[8px] mt-2">
                Please bring this card to all appointments
              </div>
            </div>
          </div>

          <div class="border-t border-slate-200 my-4"></div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
            <div>
              <p class="text-sm text-slate-500 mb-1">Phone Number</p>
              <p class="font-medium">{@patient.phone_number}</p>
            </div>

            <div>
              <p class="text-sm text-slate-500 mb-1">Date of Birth</p>
              <p class="font-medium">{@patient.date_of_birth}</p>
            </div>

            <div>
              <p class="text-sm text-slate-500 mb-1">Gender</p>
              <p class="font-medium">{@patient.gender}</p>
            </div>

            <div>
              <p class="text-sm text-slate-500 mb-1">National ID</p>
              <p class="font-medium">{@patient.national_id}</p>
              <a
                :if={@patient.national_id_document}
                href={@patient.national_id_document}
                download
                target="_blank"
                class="text-xs text-blue-600 hover:text-blue-800"
              >
                View document
              </a>
            </div>

            <div>
              <p class="text-sm text-slate-500 mb-1">Birth Certificate Number</p>
              <p class="font-medium">{@patient.birth_certificate_number || "—"}</p>
              <a
                :if={@patient.birth_certificate_document}
                href={@patient.birth_certificate_document}
                download
                target="_blank"
                class="text-xs text-blue-600 hover:text-blue-800"
              >
                View document
              </a>
            </div>

            <div>
              <p class="text-sm text-slate-500 mb-1">Email</p>
              <p class="font-medium">{@patient.email}</p>
            </div>
          </div>
          <div>
            <p class="text-sm text-slate-500 mb-1">Residence</p>
            <p class="font-medium">{@patient.home_address}</p>
          </div>

          <div class="border-t border-slate-200 my-4"></div>

          <div class="mb-4">
            <h3 class="text-md font-semibold text-brand-primary mb-2">Emergency Contact</h3>
            <div class="grid grid-cols-1 gap-2">
              <div>
                <p class="text-sm text-slate-500 mb-1">Name</p>
                <p class="font-medium">{@patient.emergency_contact_name}</p>
              </div>
              <div>
                <p class="text-sm text-slate-500 mb-1">Phone</p>
                <p class="font-medium">{@patient.emergency_contact_phone_number}</p>
              </div>
              <div>
                <p class="text-sm text-slate-500 mb-1">Relationship</p>
                <p class="font-medium">{@patient.emergency_contact_relationship}</p>
              </div>
            </div>
          </div>

          <div class="border-t border-slate-200 my-4"></div>

          <div>
            <h3 class="text-md font-semibold text-brand-primary mb-2">Insurance Details</h3>
            <div class="grid grid-cols-1 gap-2">
              <div>
                <p class="text-sm text-slate-500 mb-1">Insurance Status</p>
                <p class="font-medium">
                  <%= if @patient.has_insurance do %>
                    <span class="text-green-600">Insured</span>
                  <% else %>
                    <span class="text-slate-600">Not Insured</span>
                  <% end %>
                </p>
              </div>

              <%= if @patient.has_insurance do %>
                <div>
                  <p class="text-sm text-slate-500 mb-1">Insurance Scheme</p>
                  <p class="font-medium">{@patient.insurance_scheme}</p>
                </div>
                <div>
                  <p class="text-sm text-slate-500 mb-1">Insurance Number</p>
                  <p class="font-medium">{@patient.insurance_number}</p>
                </div>
                <div>
                  <p class="text-sm text-slate-500 mb-1">Cover Limit</p>
                  <p class="font-medium">KSh {@patient.insurance_cover_limit}</p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Vitals section -->
        <div class="w-full md:w-2/3">
          <div class="bg-white rounded-lg border border-slate-100 p-5">
            <h2 class="text-lg font-semibold text-brand-primary mb-4 flex items-center">
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
              Recent Vitals
            </h2>

            <%= if @most_recent_triage do %>
              <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-3  gap-4">
                <%= for vital <- recent_vitals(@most_recent_triage) do %>
                  <div class="flex flex-col p-4 rounded-lg bg-brand-50 border border-brand-100">
                    <p class="text-sm text-slate-600 mb-1">{vital.name}</p>
                    <p class="text-xl font-semibold text-brand-primary">{vital.value}</p>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="text-center py-6 bg-slate-50 rounded-lg border border-dashed border-slate-300">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="mx-auto h-12 w-12 text-slate-400"
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
                <h3 class="mt-2 text-sm font-medium text-slate-900">No vitals recorded</h3>
                <p class="mt-1 text-sm text-slate-500">
                  No triage information has been recorded for this patient yet.
                </p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp recent_vitals(most_recent_triage) do
    [
      %{
        name: "Date",
        value: most_recent_triage.date
      },
      %{
        name: "Blood Pressure",
        value: most_recent_triage.blood_pressure
      },
      %{
        name: "Pulse Rate",
        value: most_recent_triage.pulse_rate
      },
      %{
        name: "Oxygen Saturation",
        value: most_recent_triage.oxygen_saturation
      },
      %{
        name: "Height",
        value: most_recent_triage.height
      },
      %{
        name: "Weight",
        value: most_recent_triage.weight
      },
      %{
        name: "BMI",
        value: most_recent_triage.bmi
      },
      %{
        name: "Allergies",
        value: most_recent_triage.allergies || "None"
      }
    ]
  end

  @doc """
  The GSRN wristband a receptionist issues at registration. Same layout as the
  GS1 identification card used elsewhere in the app (org lockup, Data Matrix,
  `(8018) <gsrn>` line), with download / print actions.

  `scan_url` is accepted for compatibility but the code encodes the GS1
  `8018<gsrn>` string, which every station scanner already resolves.
  """
  attr :patient, :map, required: true
  attr :id, :string, default: "patient-code-card"
  attr :scan_url, :string, default: nil

  def patient_code_card(assigns) do
    assigns = assign(assigns, :code_value, "8018#{assigns.patient.gsrn}")

    ~H"""
    <div id={@id <> "-wrap"} phx-hook="DownloadableDiv" class="space-y-4">
      <div
        id={@id}
        class="mx-auto w-full max-w-sm overflow-hidden rounded-lg border border-slate-200 bg-white p-4 print:m-0 print:shadow-none"
      >
        <div class="mb-3 flex items-center justify-between border-b-2 border-brand-primary pb-2">
          <div class="text-brand-primary">
            <div class="text-xs font-bold">
              {Medcamp.Organisations.display_name(current_organisation())}
            </div>
            <div class="text-xs">Patient wristband</div>
          </div>
          <img
            src={Medcamp.Organisations.logo_path(current_organisation())}
            alt="Logo"
            class="h-10 w-10 rounded-full object-contain"
          />
        </div>

        <div class="flex items-start gap-3">
          <div class="flex flex-col">
            <span class="flex items-center gap-0 text-xs">
              GS1 <span class="text-sm">&#174;</span>
            </span>
            <svg
              id={@id <> "-dm"}
              data-value={@code_value}
              phx-hook="datamatrix"
              phx-update="ignore"
              class="datamatrix"
              style="width: 70px; height: 70px;"
            >
            </svg>
          </div>
          <div class="flex min-w-0 flex-1 flex-col text-sm">
            <p class="truncate font-semibold text-slate-900">{code_card_name(@patient)}</p>
            <p class="text-slate-600">{@patient.date_of_birth || "—"}</p>
            <p class="text-slate-600">{card_age(@patient)} | {@patient.gender || "—"}</p>
          </div>
        </div>

        <div class="mt-3 border-b-2 border-black"></div>
        <p class="mt-2 font-mono text-xs font-bold text-slate-900">(8018) {@patient.gsrn}</p>
      </div>

      <div class="flex items-center justify-center gap-2 print:hidden">
        <button
          type="button"
          data-download-trigger
          data-target-div={"#" <> @id}
          data-filename={"wristband-" <> @patient.gsrn <> ".png"}
          class="rounded-full border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 transition-colors duration-150 hover:bg-slate-100"
        >
          Download
        </button>
        <button
          type="button"
          data-print-trigger
          data-target-div={"#" <> @id}
          class="rounded-full bg-[#0C2765] px-4 py-2 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
        >
          Print wristband
        </button>
      </div>
    </div>
    """
  end

  defp code_card_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp card_age(%{age: age}) when is_integer(age), do: "#{age}y"

  defp card_age(%{date_of_birth: %Date{} = dob}) do
    years = div(Date.diff(Date.utc_today(), dob), 365)
    "#{years}y"
  end

  defp card_age(_patient), do: "—"
end
