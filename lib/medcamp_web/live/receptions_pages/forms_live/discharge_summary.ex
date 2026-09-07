defmodule MedcampWeb.ReceptionsPageFormLive.DischargeSummary do
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
        <.form_header_centered title="Discharge Summary" />

        <div class="flex justify-end mb-6">
          <div class="flex items-center gap-3">
            <label class="text-xs font-semibold text-gray-500 uppercase tracking-wide">Date</label>
            <input
              type="date"
              class="border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
            />
          </div>
        </div>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              1
            </span>
            Patient Details
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-x-6 gap-y-4 ml-8">
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Patient full name"
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
                Sex
              </label>
              <div class="flex gap-4 mt-2">
                <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                  <input type="radio" name="sex" value="male" class="accent-[#373896]" /> Male
                </label>
                <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                  <input type="radio" name="sex" value="female" class="accent-[#373896]" /> Female
                </label>
              </div>
            </div>
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Residence
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Home address / residence"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Tel
              </label>
              <input
                type="tel"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Phone number"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Next of Kin
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Next of kin name"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Next of Kin Tel
              </label>
              <input
                type="tel"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Phone number"
              />
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              2
            </span>
            Admission Details
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4 ml-8">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Date of Admission
              </label>
              <input
                type="date"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Time of Admission
              </label>
              <input
                type="time"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                Mode of Admission
              </label>
              <div class="flex gap-5">
                <label class="flex items-center gap-2 text-sm cursor-pointer">
                  <input
                    type="radio"
                    name="admission_mode"
                    value="emergency"
                    class="accent-[#373896]"
                  /> Emergency
                </label>
                <label class="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="radio" name="admission_mode" value="elective" class="accent-[#373896]" />
                  Elective
                </label>
                <label class="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="radio" name="admission_mode" value="referral" class="accent-[#373896]" />
                  Referral
                </label>
              </div>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Referring Facility (if any)
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Name of referring facility"
              />
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              3
            </span>
            Clinical Summary
          </h2>
          <textarea
            rows="8"
            class="ml-8 w-[calc(100%-2rem)] border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
            placeholder="Brief history, examination findings, investigations done, and management given..."
          ></textarea>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              4
            </span>
            Diagnosis
          </h2>
          <div class="ml-8 space-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                a) Diagnosis on Admission
              </label>
              <textarea
                rows="5"
                class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
                placeholder="Primary and secondary diagnoses on admission..."
              ></textarea>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                b) Diagnosis on Discharge
              </label>
              <textarea
                rows="5"
                class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
                placeholder="Primary and secondary diagnoses on discharge..."
              ></textarea>
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              5
            </span>
            Condition at Discharge
          </h2>
          <div class="ml-8 space-y-4">
            <div class="flex flex-wrap gap-6">
              <%= for condition <- ["Stable", "Improved", "Unchanged", "Referred"] do %>
                <label class="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="checkbox" class="w-4 h-4 accent-[#373896]" /> {condition}
                </label>
              <% end %>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Remarks
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Additional remarks on condition..."
              />
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              6
            </span>
            Discharge Medications
          </h2>
          <div class="ml-8">
            <div class="border border-gray-200 rounded-lg overflow-hidden">
              <table class="w-full text-sm">
                <thead>
                  <tr class="bg-gray-50 border-b border-gray-200">
                    <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-2.5">
                      #
                    </th>
                    <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-2.5">
                      Medication
                    </th>
                    <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-2.5">
                      Dose
                    </th>
                    <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-2.5">
                      Frequency
                    </th>
                    <th class="text-left text-xs font-semibold text-gray-600 uppercase tracking-wide px-4 py-2.5">
                      Duration
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <%= for i <- 1..5 do %>
                    <tr>
                      <td class="px-4 py-2 text-gray-400 text-xs">{i}.</td>
                      <td class="px-4 py-2">
                        <input
                          type="text"
                          class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                          placeholder="Drug name"
                        />
                      </td>
                      <td class="px-4 py-2">
                        <input
                          type="text"
                          class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                          placeholder="e.g. 500mg"
                        />
                      </td>
                      <td class="px-4 py-2">
                        <input
                          type="text"
                          class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                          placeholder="e.g. TDS"
                        />
                      </td>
                      <td class="px-4 py-2">
                        <input
                          type="text"
                          class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                          placeholder="e.g. 7 days"
                        />
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              7
            </span>
            Health Education
          </h2>
          <textarea
            rows="8"
            class="ml-8 w-[calc(100%-2rem)] border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
            placeholder="Health education and advice given to the patient on discharge..."
          ></textarea>
        </section>

        <section class="mb-8">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              8
            </span>
            Follow-Up Plan
          </h2>
          <div class="ml-8 grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Follow-up Clinic
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Name of clinic / facility"
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

        <section class="pt-6 border-t border-gray-200">
          <h2 class="text-sm font-bold text-gray-800 mb-5 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              9
            </span>
            Discharged By
          </h2>
          <div class="ml-8 grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-5">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Full name"
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
            <div class="space-y-3">
              <.signature_pad id="discharge-doctor-sig" label="Signature" />
              <.official_stamp />
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
      </div>
    </div>
    """
  end
end
