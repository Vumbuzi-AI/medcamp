defmodule MedcampWeb.ReceptionsPageFormLive.LabRequest do
  use MedcampWeb, :shared_live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :active_tab, :forms)}
  end

  @impl true
  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <div class="flex items-center justify-between mb-6 print:hidden">
        <a href="/forms" class="flex items-center gap-1 text-sm text-gray-500 hover:text-[#373896]">
          <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Forms
        </a>
        <button
          type="button"
          onclick="window.print()"
          class="flex items-center gap-2 px-4 py-2 bg-[#373896] text-white rounded-lg text-sm font-medium hover:bg-[#2d2d7a] transition-colors"
        >
          <.icon name="hero-printer" class="w-4 h-4" /> Print Form
        </button>
      </div>

      <div class="bg-white border border-gray-200 rounded-xl shadow-sm p-8 print:shadow-none print:border-none print:p-0">
        <.form_header_centered title="Laboratory Request Form" />

        <section class="mb-7">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">
            Patient Details
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-x-6 gap-y-4">
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Patient Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Full name"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Age
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Age"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Gender
              </label>
              <div class="flex gap-4 mt-2">
                <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                  <input type="radio" name="gender" value="male" class="accent-[#373896]" /> Male
                </label>
                <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                  <input type="radio" name="gender" value="female" class="accent-[#373896]" /> Female
                </label>
              </div>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Hospital No.
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Hospital / MRN No."
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Date
              </label>
              <input
                type="date"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              />
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">
            Clinician Information
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Clinician's full name"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Designation
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="e.g. Medical Officer"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Tel
              </label>
              <input
                type="tel"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Contact number"
              />
            </div>
            <div class="md:col-span-2">
              <.signature_pad id="lab-clinician-sig" label="Clinician Signature" />
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">
            Clinical Information
          </h2>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Presenting Symptoms / Provisional Diagnosis
            </label>
            <textarea
              rows="5"
              class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
              placeholder="Describe presenting symptoms and provisional diagnosis..."
            ></textarea>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">
            Laboratory Investigations Requested
          </h2>
          <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full text-sm">
              <thead>
                <tr class="bg-gray-50 border-b border-gray-200">
                  <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-3 w-1/3">
                    Test Category
                  </th>
                  <th class="text-center text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-3 w-16">
                    Tick
                  </th>
                  <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-3">
                    Specific Test(s) Requested
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 font-medium text-gray-700">Haematology</td>
                  <td class="px-4 py-3 text-center">
                    <input type="checkbox" class="w-4 h-4 accent-[#373896] cursor-pointer" />
                  </td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full border-b border-gray-200 focus:border-[#373896] outline-none py-0.5 text-sm bg-transparent"
                      placeholder="e.g. FBC, Blood Film"
                    />
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 font-medium text-gray-700">Biochemistry</td>
                  <td class="px-4 py-3 text-center">
                    <input type="checkbox" class="w-4 h-4 accent-[#373896] cursor-pointer" />
                  </td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full border-b border-gray-200 focus:border-[#373896] outline-none py-0.5 text-sm bg-transparent"
                      placeholder="e.g. LFT, RFT, Electrolytes"
                    />
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 font-medium text-gray-700">Microbiology</td>
                  <td class="px-4 py-3 text-center">
                    <input type="checkbox" class="w-4 h-4 accent-[#373896] cursor-pointer" />
                  </td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full border-b border-gray-200 focus:border-[#373896] outline-none py-0.5 text-sm bg-transparent"
                      placeholder="e.g. Culture &amp; Sensitivity"
                    />
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 font-medium text-gray-700">Parasitology</td>
                  <td class="px-4 py-3 text-center">
                    <input type="checkbox" class="w-4 h-4 accent-[#373896] cursor-pointer" />
                  </td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full border-b border-gray-200 focus:border-[#373896] outline-none py-0.5 text-sm bg-transparent"
                      placeholder="e.g. Malaria RDT, Stool MCS"
                    />
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 font-medium text-gray-700">Serology / Immunology</td>
                  <td class="px-4 py-3 text-center">
                    <input type="checkbox" class="w-4 h-4 accent-[#373896] cursor-pointer" />
                  </td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full border-b border-gray-200 focus:border-[#373896] outline-none py-0.5 text-sm bg-transparent"
                      placeholder="e.g. HIV, Hepatitis B/C, VDRL"
                    />
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 font-medium text-gray-700">Molecular / PCR</td>
                  <td class="px-4 py-3 text-center">
                    <input type="checkbox" class="w-4 h-4 accent-[#373896] cursor-pointer" />
                  </td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full border-b border-gray-200 focus:border-[#373896] outline-none py-0.5 text-sm bg-transparent"
                      placeholder="e.g. PCR COVID, TB GeneXpert"
                    />
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 font-medium text-gray-700">Blood Bank</td>
                  <td class="px-4 py-3 text-center">
                    <input type="checkbox" class="w-4 h-4 accent-[#373896] cursor-pointer" />
                  </td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full border-b border-gray-200 focus:border-[#373896] outline-none py-0.5 text-sm bg-transparent"
                      placeholder="e.g. Blood Group, X-match"
                    />
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3 font-medium text-gray-700">Other (Specify)</td>
                  <td class="px-4 py-3 text-center">
                    <input type="checkbox" class="w-4 h-4 accent-[#373896] cursor-pointer" />
                  </td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full border-b border-gray-200 focus:border-[#373896] outline-none py-0.5 text-sm bg-transparent"
                      placeholder="Specify test..."
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">
            Specimen Details
          </h2>
          <div class="space-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                Type of Specimen
              </label>
              <div class="flex flex-wrap gap-4">
                <%= for specimen <- ["Blood", "Urine", "Stool", "Sputum", "Swab", "CSF", "Tissue"] do %>
                  <label class="flex items-center gap-2 text-sm cursor-pointer">
                    <input type="checkbox" class="w-4 h-4 accent-[#373896]" /> {specimen}
                  </label>
                <% end %>
              </div>
              <div class="mt-3">
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  Other
                </label>
                <input
                  type="text"
                  class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                  placeholder="Specify other specimen type"
                />
              </div>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
              <div>
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  Specimen Collection Date &amp; Time
                </label>
                <input
                  type="datetime-local"
                  class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                />
              </div>
              <div>
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  Collected By
                </label>
                <input
                  type="text"
                  class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                  placeholder="Name of collector"
                />
              </div>
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">
            Results
            <span class="text-gray-400 font-normal normal-case tracking-normal text-xs ml-1">
              (Laboratory Use Only)
            </span>
          </h2>
          <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full text-sm">
              <thead>
                <tr class="bg-gray-50 border-b border-gray-200">
                  <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-3 py-3">
                    Test Performed
                  </th>
                  <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-3 py-3">
                    Result
                  </th>
                  <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-3 py-3">
                    Units / Reference Range
                  </th>
                  <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-3 py-3">
                    Remarks
                  </th>
                  <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-3 py-3">
                    Lab Officer
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= for _i <- 1..6 do %>
                  <tr>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                      />
                    </td>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                      />
                    </td>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                      />
                    </td>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                      />
                    </td>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                      />
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </section>

        <section>
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">
            Laboratory Verification
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-x-6 gap-y-4">
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Lab Personnel Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Full name"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Date Reported
              </label>
              <input
                type="date"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              />
            </div>
            <div class="md:col-span-3">
              <.signature_pad id="lab-officer-sig" label="Lab Officer Signature" />
            </div>
          </div>
        </section>
      </div>
    </div>
    """
  end
end
