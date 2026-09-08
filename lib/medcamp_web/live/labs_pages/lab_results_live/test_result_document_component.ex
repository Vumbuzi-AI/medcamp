defmodule MedcampWeb.LabPagesLabResultLive.TestResultDocumentComponent do
  @moduledoc """
  Displays lab test results as a printable document/report format.
  Matches the template style from the uploaded screenshots.
  Optimized for printing with accurate layout and spacing.
  """
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white mt-4">
      <div :if={@show_header_actions} class="flex justify-between items-center mb-4 print:hidden">
        <.link
          :if={@back_to}
          navigate={@back_to}
          class="px-4 py-2 text-sm font-medium text-brand-accent bg-white border border-brand-accent rounded-lg hover:bg-gray-50 flex items-center transition-colors"
        >
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
              d="M10 19l-7-7m0 0l7-7m-7 7h18"
            />
          </svg>
          {@back_label}
        </.link>

        <button
          :if={@show_print_button}
          onclick="window.print()"
          class="px-4 py-2 text-sm font-medium text-white bg-brand-accent rounded-lg hover:bg-brand-accent-dark flex items-center shadow-sm transition-colors"
        >
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
              d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
            />
          </svg>
          Print Report
        </button>
      </div>
      
    <!-- Document Container -->
      <div
        class="bg-white mx-auto print:mx-0 print:w-full"
        style="max-width: 210mm;"
        id="lab-report-document"
      >
        <!-- Header with Logo -->
        <.letterhead />
        
    <!-- Patient Info Table -->
        <div class="px-8 print:px-6 mb-6">
          <table class="w-full border-collapse text-base">
            <tbody>
              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold w-[20%]">
                  Patient No:
                </td>
                <td class="border-2 border-gray-800 px-3 py-2 w-[30%]">{@patient.id}</td>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold w-[20%]">Lab Test No:</td>
                <td class="border-2 border-gray-800 px-3 py-2 w-[30%]">{@lab_result.id}</td>
              </tr>
              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Patient Name:</td>
                <td class="border-2 border-gray-800 px-3 py-2">{format_patient_name(@patient)}</td>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Requested On:</td>
                <td class="border-2 border-gray-800 px-3 py-2">
                  {format_date(@lab_result.inserted_at)}
                </td>
              </tr>
              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Gender:</td>
                <td class="border-2 border-gray-800 px-3 py-2">
                  {String.capitalize(@patient.gender || "")}
                </td>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Lab service Provider</td>
                <td class="border-2 border-gray-800 px-3 py-2">
                  {(@entry.performed_by && @entry.performed_by.name) || "-"}
                </td>
              </tr>
              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Age:</td>
                <td class="border-2 border-gray-800 px-3 py-2">
                  {calculate_age(@patient.date_of_birth)} years
                </td>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Referring Doctor:</td>
                <td class="border-2 border-gray-800 px-3 py-2">{@doctor.name}</td>
              </tr>
            </tbody>
          </table>
        </div>
        
    <!-- Laboratory Report Section -->
        <div class="px-8 print:px-6 pb-8">
          <h2 class="text-center text-2xl font-bold text-[#06b6d4] mb-6 tracking-wide">
            LABORATORY REPORT
          </h2>

          <table class="w-full border-collapse text-base">
            <!-- Investigation Header -->
            <thead>
              <tr>
                <td colspan="2" class="border-2 border-gray-800 px-3 py-2">
                  <span class="text-[#7c3aed] font-bold">Investigation:</span>
                  <span class="text-[#7c3aed] ml-1 font-semibold">{@template.name}</span>
                </td>
                <td colspan="2" class="border-2 border-gray-800 px-3 py-2 text-right">
                  <%= if @entry.sample_collected_on do %>
                    <div class="leading-tight">
                      <span class="text-[#7c3aed] font-bold">Sample collected on:</span>
                      <span class="text-gray-800 font-medium ml-1">
                        {format_date(@entry.sample_collected_on)}
                      </span>
                    </div>
                  <% end %>
                  <%= if @entry.test_performed_on do %>
                    <div class="leading-tight">
                      <span class="text-[#7c3aed] font-bold">Test Performed on:</span>
                      <span class="text-gray-800 font-medium ml-1">
                        {format_date(@entry.test_performed_on)}
                      </span>
                    </div>
                  <% end %>
                </td>
              </tr>
              <tr>
                <th class="border-2 border-gray-800 px-3 py-2.5 text-left text-[#06b6d4] font-bold">
                  Test_Name
                </th>
                <th class="border-2 border-gray-800 px-3 py-2.5 text-left text-[#06b6d4] font-bold">
                  Result
                </th>
                <th class="border-2 border-gray-800 px-3 py-2.5 text-left text-[#06b6d4] font-bold">
                  Ref. Ranges
                </th>
                <th class="border-2 border-gray-800 px-3 py-2.5 text-left text-[#06b6d4] font-bold w-20">
                  Flag
                </th>
              </tr>
            </thead>
            <tbody>
              <%= for {section, fields} <- @grouped_fields do %>
                <%= if section != "main" do %>
                  <tr>
                    <td
                      colspan="4"
                      class="border-2 border-gray-800 px-3 py-2 bg-gray-50 font-bold text-gray-800"
                    >
                      {section}
                    </td>
                  </tr>
                <% end %>

                <%= for field <- fields do %>
                  <% field_name = field["name"] || field[:name]
                  result_data = Map.get(@entry.results, field_name, %{})
                  value = result_data["value"]
                  flag = result_data["flag"]
                  note = result_data["note"]
                  unit = field["unit"] || field[:unit]
                  ref_range = field["ref_range_text"] || field[:ref_range_text]
                  ref_min = field["ref_range_min"] || field[:ref_range_min]
                  ref_max = field["ref_range_max"] || field[:ref_range_max]
                  has_ref_range? = ref_min || ref_max || ref_range %>
                  <tr>
                    <td class="border-2 border-gray-800 px-3 py-2 align-top">
                      {field["label"] || field[:label]}
                    </td>
                    <td class="border-2 border-gray-800 px-3 py-2 font-medium align-top">
                      <%= if value do %>
                        {value}
                        <%= if unit do %>
                          <span class="text-gray-600 font-normal ml-1">{unit}</span>
                        <% end %>
                      <% end %>
                      <%= if note && note != "" do %>
                        <div class="mt-1 text-xs italic text-gray-700 font-normal">
                          <span class="font-semibold not-italic">Note:</span> {note}
                        </div>
                      <% end %>
                    </td>
                    <td class="border-2 border-gray-800 px-3 py-2 align-top">{ref_range || ""}</td>
                    <td class={[
                      "border-2 border-gray-800 px-3 py-2 font-bold text-center align-top",
                      case flag do
                        "low" -> "text-blue-600"
                        "high" -> "text-red-600"
                        "normal" -> "text-green-600"
                        _ -> ""
                      end
                    ]}>
                      <%= case flag do %>
                        <% "low" -> %>
                          L
                        <% "high" -> %>
                          H
                        <% "normal" -> %>
                          <%= if has_ref_range? do %>
                            N
                          <% end %>
                        <% _ -> %>
                      <% end %>
                    </td>
                  </tr>
                <% end %>
              <% end %>
              
    <!-- Remarks row -->
              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold text-[#06b6d4]">Remarks</td>
                <td colspan="3" class="border-2 border-gray-800 px-3 py-2">
                  {@entry.remarks || ""}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
    <!-- Signatures Section -->
        <div class="px-8 print:px-6 pb-12 print:pb-8">
          <div class="flex justify-between items-end mt-12 print:mt-8">
            <div class="text-left">
              <p class="text-base font-bold text-[#06b6d4] mb-2 print:mb-12">Lab Technologist</p>
              <p class="text-sm text-gray-700">
                {(@entry.performed_by && @entry.performed_by.name) || ""}
              </p>
            </div>
          </div>
        </div>
        
    <!-- Status Badge -->
        <%= if @entry.status == "verified" do %>
          <div class="px-8 pb-4 print:hidden">
            <div class="flex justify-center">
              <span class="px-4 py-2 bg-green-100 text-green-800 rounded-lg font-medium text-sm flex items-center">
                <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                  />
                </svg>
                Verified on {format_datetime(@entry.verified_at)}
              </span>
            </div>
          </div>
        <% end %>
      </div>
      
    <!-- Print Styles -->
      <style>
        @media print {
        /* 1. Reset page settings */
        @page {
          size: A4;
          margin: 10mm;
        }

        /* 2. Hide common UI wrappers - adjust these selectors to match your app's layout */
        nav, aside, footer, .print\:hidden, button {
          display: none !important;
        }

        /* 3. Ensure the report container is visible and takes full width */
        #lab-report-document {
          display: block !important;
          visibility: visible !important;
          position: absolute !important;
          left: 0 !important;
          top: 0 !important;
          width: 100% !important;
          margin: 0 !important;
          padding: 0 !important;
          background: white !important;
          z-index: 9999;
        }

        /* 4. Fix table rendering */
        table {
          width: 100% !important;
          border-collapse: collapse !important;
          border: 2px solid #000 !important;
        }

        th, td {
          border: 1px solid #000 !important;
          padding: 8px !important;
        }

        /* 5. Force text colors to show up */
        .text-\[\#7c3aed\], h1 { color: #7c3aed !important; -webkit-print-color-adjust: exact; }
        .text-\[\#10b981\] { color: #10b981 !important; -webkit-print-color-adjust: exact; }
        .text-\[\#06b6d4\], h2 { color: #06b6d4 !important; -webkit-print-color-adjust: exact; }

        /* 6. Body cleanup */
        body {
          background: white !important;
          -webkit-print-color-adjust: exact !important;
          print-color-adjust: exact !important;
        }
        }
      </style>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    template = assigns.template

    grouped_fields =
      template.field_definitions
      |> Enum.sort_by(fn f -> f["display_order"] || f[:display_order] || 999 end)
      |> Enum.group_by(fn f -> f["section"] || f[:section] || "main" end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:back_to, fn -> "/lab/lab_results/#{assigns.lab_result.id}" end)
     |> assign_new(:back_label, fn -> "Back to Lab Results" end)
     |> assign_new(:show_print_button, fn -> true end)
     |> assign_new(:show_header_actions, fn -> true end)
     |> assign(:grouped_fields, grouped_fields)}
  end

  defp format_patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.filter(&(&1 != nil))
    |> Enum.join(" ")
  end

  defp calculate_age(nil), do: "-"

  defp calculate_age(date_of_birth) do
    Date.diff(Date.utc_today(), date_of_birth) |> div(365)
  end

  defp format_date(nil), do: "-"

  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%d/%m/%Y")
  end

  defp format_date(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y")
  end

  defp format_date(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y")
  end

  defp format_datetime(nil), do: "-"

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y at %H:%M")
  end
end
