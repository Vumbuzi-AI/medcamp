defmodule MedcampWeb.LabPagesLabTestTemplateLive.PreviewComponent do
  @moduledoc """
  Previews a lab test template in the standard laboratory report layout —
  the same layout used when viewing a completed lab test entry
  (see LabPagesLabResultLive.TestResultDocumentComponent).

  No patient, result or entry data is rendered; placeholders (—) are shown
  in patient/metadata cells and in the Result/Flag columns so lab staff can
  verify how a template will appear on a printed report before use.
  """
  use MedcampWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white mt-4">
      <div class="flex justify-between items-center mb-4 print:hidden">
        <div class="flex items-center gap-2 text-sm text-gray-600">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 text-brand-accent"
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
          <span class="font-medium">Template Preview</span>
          <span class="text-gray-400">— how this template appears on a lab report</span>
        </div>

        <button
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
          Print Preview
        </button>
      </div>

      <div
        class="bg-white mx-auto print:mx-0 print:w-full"
        style="max-width: 210mm;"
        id="lab-report-preview"
      >
        <.letterhead />

        <div class="px-8 print:px-6 mb-6">
          <table class="w-full border-collapse text-base">
            <tbody>
              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold w-[20%]">Patient No:</td>
                <td class="border-2 border-gray-800 px-3 py-2 w-[30%]">—</td>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold w-[20%]">Lab Test No:</td>
                <td class="border-2 border-gray-800 px-3 py-2 w-[30%]">—</td>
              </tr>
              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Patient Name:</td>
                <td class="border-2 border-gray-800 px-3 py-2">—</td>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Requested On:</td>
                <td class="border-2 border-gray-800 px-3 py-2">—</td>
              </tr>
              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Gender:</td>
                <td class="border-2 border-gray-800 px-3 py-2">—</td>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Lab service Provider</td>
                <td class="border-2 border-gray-800 px-3 py-2">—</td>
              </tr>
              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Age:</td>
                <td class="border-2 border-gray-800 px-3 py-2">—</td>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold">Referring Doctor:</td>
                <td class="border-2 border-gray-800 px-3 py-2">—</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="px-8 print:px-6 pb-8">
          <h2 class="text-center text-2xl font-bold text-[#06b6d4] mb-6 tracking-wide">
            LABORATORY REPORT
          </h2>

          <table class="w-full border-collapse text-base">
            <thead>
              <tr>
                <td colspan="2" class="border-2 border-gray-800 px-3 py-2">
                  <span class="text-[#7c3aed] font-bold">Investigation:</span>
                  <span class="text-[#7c3aed] ml-1 font-semibold">{@template.name}</span>
                </td>
                <td colspan="2" class="border-2 border-gray-800 px-3 py-2 text-right">
                  <div class="leading-tight">
                    <span class="text-[#7c3aed] font-bold">Sample collected on:</span>
                    <span class="text-gray-800 font-medium ml-1">—</span>
                  </div>
                  <div class="leading-tight">
                    <span class="text-[#7c3aed] font-bold">Test Performed on:</span>
                    <span class="text-gray-800 font-medium ml-1">—</span>
                  </div>
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
                  <% unit = field["unit"] || field[:unit]
                  ref_range = field["ref_range_text"] || field[:ref_range_text] %>
                  <tr>
                    <td class="border-2 border-gray-800 px-3 py-2">
                      {field["label"] || field[:label]}
                    </td>
                    <td class="border-2 border-gray-800 px-3 py-2 text-gray-400">
                      <%= if unit do %>
                        {unit}
                      <% else %>
                        —
                      <% end %>
                    </td>
                    <td class="border-2 border-gray-800 px-3 py-2">{ref_range || ""}</td>
                    <td class="border-2 border-gray-800 px-3 py-2"></td>
                  </tr>
                <% end %>
              <% end %>

              <tr>
                <td class="border-2 border-gray-800 px-3 py-2 font-bold text-[#06b6d4]">Remarks</td>
                <td colspan="3" class="border-2 border-gray-800 px-3 py-2"></td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="px-8 print:px-6 pb-12 print:pb-8">
          <div class="flex justify-between items-end mt-12 print:mt-8">
            <div class="text-left">
              <p class="text-base font-bold text-[#06b6d4] mb-2 print:mb-12">Lab Technologist</p>
              <p class="text-sm text-gray-700">—</p>
            </div>
          </div>
        </div>
      </div>

      <style>
        @media print {
        @page { size: A4; margin: 10mm; }
        nav, aside, footer, .print\:hidden, button { display: none !important; }
        #lab-report-preview {
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
        table { width: 100% !important; border-collapse: collapse !important; border: 2px solid #000 !important; }
        th, td { border: 1px solid #000 !important; padding: 8px !important; }
        .text-\[\#7c3aed\], h1 { color: #7c3aed !important; -webkit-print-color-adjust: exact; }
        .text-\[\#10b981\] { color: #10b981 !important; -webkit-print-color-adjust: exact; }
        .text-\[\#06b6d4\], h2 { color: #06b6d4 !important; -webkit-print-color-adjust: exact; }
        body { background: white !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
        }
      </style>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    grouped_fields =
      assigns.template.field_definitions
      |> Enum.sort_by(fn f -> f["display_order"] || f[:display_order] || 999 end)
      |> Enum.group_by(fn f -> f["section"] || f[:section] || "main" end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:grouped_fields, grouped_fields)}
  end
end
