defmodule MedcampWeb.ReceptionsPageFormLive.MedicalReport do
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
        <.form_header_centered title="Medical Report" />

        <%!-- Section A --%>
        <section class="mb-6">
          <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
            Section A: Personal Information
          </h2>
          <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full text-sm">
              <tbody class="divide-y divide-gray-100">
                <tr>
                  <td class="px-4 py-3 font-medium text-gray-600 w-52 bg-gray-50">Full Name</td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full outline-none text-sm bg-transparent border-b border-gray-200 focus:border-[#373896]"
                      placeholder="Patient's full name"
                    />
                  </td>
                </tr>
                <tr>
                  <td class="px-4 py-3 font-medium text-gray-600 bg-gray-50">Date of Birth</td>
                  <td class="px-4 py-3">
                    <div class="flex items-center gap-6">
                      <input
                        type="date"
                        class="outline-none text-sm bg-transparent border-b border-gray-200 focus:border-[#373896]"
                      />
                      <div class="flex items-center gap-4">
                        <span class="text-sm text-gray-600">Gender:</span>
                        <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                          <input type="radio" name="gender" value="male" class="accent-[#373896]" />
                          Male
                        </label>
                        <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                          <input type="radio" name="gender" value="female" class="accent-[#373896]" />
                          Female
                        </label>
                        <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                          <input type="radio" name="gender" value="other" class="accent-[#373896]" />
                          Other
                        </label>
                      </div>
                    </div>
                  </td>
                </tr>
                <tr>
                  <td class="px-4 py-3 font-medium text-gray-600 bg-gray-50">
                    National ID / Passport No.
                  </td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-64 outline-none text-sm bg-transparent border-b border-gray-200 focus:border-[#373896]"
                      placeholder="ID or Passport number"
                    />
                  </td>
                </tr>
                <tr>
                  <td class="px-4 py-3 font-medium text-gray-600 bg-gray-50">Contact No.</td>
                  <td class="px-4 py-3">
                    <input
                      type="tel"
                      class="w-64 outline-none text-sm bg-transparent border-b border-gray-200 focus:border-[#373896]"
                      placeholder="Phone number"
                    />
                  </td>
                </tr>
                <tr>
                  <td class="px-4 py-3 font-medium text-gray-600 bg-gray-50">Position Applied For</td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full outline-none text-sm bg-transparent border-b border-gray-200 focus:border-[#373896]"
                      placeholder="Job title / position"
                    />
                  </td>
                </tr>
                <tr>
                  <td class="px-4 py-3 font-medium text-gray-600 bg-gray-50">Department</td>
                  <td class="px-4 py-3">
                    <input
                      type="text"
                      class="w-full outline-none text-sm bg-transparent border-b border-gray-200 focus:border-[#373896]"
                      placeholder="Department name"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <%!-- Section B --%>
        <section class="mb-6">
          <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
            Section B: Medical History
            <span class="font-normal normal-case tracking-normal text-xs text-gray-500 ml-1">
              (To be completed by applicant)
            </span>
          </h2>
          <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full text-sm">
              <tbody class="divide-y divide-gray-100">
                <%= for condition <- [
                  "Hypertension / Heart Disease",
                  "Diabetes Mellitus",
                  "Asthma / Respiratory Illness",
                  "Tuberculosis",
                  "Epilepsy / Seizures",
                  "Mental Health Conditions",
                  "Hearing or Vision Problems",
                  "Any chronic illness / long-term medication"
                ] do %>
                  <tr class="hover:bg-gray-50">
                    <td class="px-4 py-2.5">
                      <div class="flex items-center gap-6">
                        <div class="flex items-center gap-3">
                          <label class="flex items-center gap-1.5 text-sm cursor-pointer text-green-700 font-medium">
                            <input
                              type="radio"
                              name={"hist_#{condition}"}
                              value="yes"
                              class="accent-green-600"
                            /> Yes
                          </label>
                          <label class="flex items-center gap-1.5 text-sm cursor-pointer text-gray-600">
                            <input
                              type="radio"
                              name={"hist_#{condition}"}
                              value="no"
                              class="accent-gray-500"
                            /> No
                          </label>
                        </div>
                        <span class="text-gray-700">{condition}</span>
                      </div>
                    </td>
                  </tr>
                <% end %>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-2.5">
                    <div class="flex items-center gap-3">
                      <span class="text-gray-700 font-medium">Allergies (Drug/Food/Other):</span>
                      <input
                        type="text"
                        class="flex-1 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="Specify any allergies"
                      />
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-2.5">
                    <div class="flex items-center gap-3">
                      <span class="text-gray-700 font-medium">
                        Past surgeries / Hospital admissions:
                      </span>
                      <input
                        type="text"
                        class="flex-1 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="Specify if any"
                      />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <%!-- Section C --%>
        <section class="mb-6">
          <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
            Section C: Physical Examination
            <span class="font-normal normal-case tracking-normal text-xs text-gray-500 ml-1">
              (By Physician)
            </span>
          </h2>
          <div class="border border-gray-200 rounded-lg overflow-hidden mb-4">
            <table class="w-full text-sm">
              <tbody>
                <tr class="divide-x divide-gray-200 border-b border-gray-200">
                  <td class="px-4 py-2.5 flex items-center gap-2">
                    <span class="text-gray-600 font-medium whitespace-nowrap">Height:</span>
                    <input
                      type="text"
                      class="w-20 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                      placeholder="cm"
                    />
                    <span class="text-gray-500 text-xs">cm</span>
                  </td>
                  <td class="px-4 py-2.5">
                    <div class="flex items-center gap-2">
                      <span class="text-gray-600 font-medium whitespace-nowrap">Weight:</span>
                      <input
                        type="text"
                        class="w-20 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="kg"
                      />
                      <span class="text-gray-500 text-xs">kg</span>
                    </div>
                  </td>
                  <td class="px-4 py-2.5">
                    <div class="flex items-center gap-2">
                      <span class="text-gray-600 font-medium">BMI:</span>
                      <input
                        type="text"
                        class="w-20 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="—"
                      />
                    </div>
                  </td>
                </tr>
                <tr class="divide-x divide-gray-200 border-b border-gray-200">
                  <td class="px-4 py-2.5">
                    <div class="flex items-center gap-2">
                      <span class="text-gray-600 font-medium whitespace-nowrap">Blood Pressure:</span>
                      <input
                        type="text"
                        class="w-24 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="mmHg"
                      />
                    </div>
                  </td>
                  <td class="px-4 py-2.5">
                    <div class="flex items-center gap-2">
                      <span class="text-gray-600 font-medium">Pulse:</span>
                      <input
                        type="text"
                        class="w-20 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="/min"
                      />
                    </div>
                  </td>
                  <td class="px-4 py-2.5">
                    <div class="flex items-center gap-2">
                      <span class="text-gray-600 font-medium">Temp:</span>
                      <input
                        type="text"
                        class="w-20 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="°C"
                      />
                    </div>
                  </td>
                </tr>
                <tr class="border-b border-gray-200">
                  <td colspan="3" class="px-4 py-2.5">
                    <div class="flex items-center gap-4 flex-wrap">
                      <span class="text-gray-600 font-medium">Vision: Left</span>
                      <input
                        type="text"
                        class="w-20 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="—"
                      />
                      <span class="text-gray-600">/ Right</span>
                      <input
                        type="text"
                        class="w-20 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="—"
                      />
                      <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                        <input type="checkbox" class="accent-[#373896]" /> With correction
                      </label>
                      <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                        <input type="checkbox" class="accent-[#373896]" /> Without correction
                      </label>
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
                <%= for system <- ["Hearing", "Chest / Lungs", "Cardiovascular", "Abdomen", "Musculoskeletal", "Neurological", "Skin"] do %>
                  <tr class="hover:bg-gray-50">
                    <td class="px-4 py-2.5 font-medium text-gray-700">{system}</td>
                    <td class="px-4 py-2.5">
                      <div class="flex items-center gap-3">
                        <label class="flex items-center gap-1.5 text-sm cursor-pointer text-green-700">
                          <input
                            type="radio"
                            name={"exam_#{system}"}
                            value="normal"
                            class="accent-green-600"
                          /> Normal
                        </label>
                        <label class="flex items-center gap-1.5 text-sm cursor-pointer text-red-700">
                          <input
                            type="radio"
                            name={"exam_#{system}"}
                            value="abnormal"
                            class="accent-red-500"
                          />
                          {if system == "Hearing", do: "Impaired", else: "Abnormal"}
                        </label>
                      </div>
                    </td>
                    <td class="px-4 py-2.5">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="—"
                      />
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </section>

        <%!-- Section D --%>
        <section class="mb-6">
          <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
            Section D: Laboratory Investigations
          </h2>
          <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full text-sm">
              <tbody class="divide-y divide-gray-100">
                <%= for {test, note} <- [
                  {"Complete Blood Count (CBC)", nil},
                  {"Urinalysis", nil},
                  {"Chest X-Ray", nil},
                  {"HIV Test", "*Confidential"},
                  {"Hepatitis B Surface Antigen", "*Confidential"}
                ] do %>
                  <tr class="hover:bg-gray-50">
                    <td class="px-4 py-2.5 font-medium text-gray-700 w-56">
                      {test}
                      <%= if note do %>
                        <span class="text-xs text-gray-400 ml-1">{note}</span>
                      <% end %>
                    </td>
                    <td class="px-4 py-2.5">
                      <div class="flex items-center gap-4">
                        <label class="flex items-center gap-1.5 text-sm cursor-pointer text-green-700">
                          <input
                            type="radio"
                            name={"lab_#{test}"}
                            value="normal"
                            class="accent-green-600"
                          /> Normal
                        </label>
                        <label class="flex items-center gap-1.5 text-sm cursor-pointer text-red-700">
                          <input
                            type="radio"
                            name={"lab_#{test}"}
                            value="abnormal"
                            class="accent-red-500"
                          /> Abnormal
                        </label>
                      </div>
                    </td>
                  </tr>
                <% end %>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-2.5 font-medium text-gray-700">Blood Sugar (FBS / RBS)</td>
                  <td class="px-4 py-2.5">
                    <div class="flex items-center gap-2">
                      <input
                        type="text"
                        class="w-24 border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="value"
                      />
                      <span class="text-gray-500 text-xs">mg/dl</span>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-2.5 font-medium text-gray-700">Other tests (if applicable)</td>
                  <td class="px-4 py-2.5">
                    <input
                      type="text"
                      class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                      placeholder="Specify other tests and results"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <p class="text-xs text-gray-400 mt-2 italic">
            *Confidential, handled per national guidelines.
          </p>
        </section>

        <%!-- Section E --%>
        <section class="mb-8">
          <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider bg-gray-100 rounded-lg px-4 py-2.5 mb-4">
            Section E: Fitness for Employment / Education
          </h2>
          <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full text-sm">
              <tbody class="divide-y divide-gray-100">
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3">
                    <label class="flex items-center gap-3 cursor-pointer">
                      <input type="radio" name="fitness" value="fit" class="w-4 h-4 accent-green-600" />
                      <span class="font-medium text-green-700">
                        Medically FIT for employment/education
                      </span>
                    </label>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3">
                    <div class="flex items-center gap-3 flex-wrap">
                      <label class="flex items-center gap-3 cursor-pointer">
                        <input
                          type="radio"
                          name="fitness"
                          value="temp_unfit"
                          class="w-4 h-4 accent-amber-500"
                        />
                        <span class="font-medium text-amber-700">
                          Temporarily UNFIT – Re-evaluation in
                        </span>
                      </label>
                      <input
                        type="text"
                        class="w-24 border-b border-gray-300 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="weeks/months"
                      />
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-4 py-3">
                    <label class="flex items-center gap-3 cursor-pointer">
                      <input
                        type="radio"
                        name="fitness"
                        value="perm_unfit"
                        class="w-4 h-4 accent-red-500"
                      />
                      <span class="font-medium text-red-700">
                        PERMANENTLY UNFIT for employment/education
                      </span>
                    </label>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="mb-8">
          <h2 class="text-sm font-bold text-gray-900 uppercase tracking-wider mb-3">
            Any Other Remarks
          </h2>
          <textarea
            rows="8"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
            placeholder="Additional remarks or observations..."
          ></textarea>
        </section>

        <div class="pt-6 border-t border-gray-200 grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-4">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Examining Doctor's Name
            </label>
            <input
              type="text"
              class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              placeholder="Full name"
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
          <div>
            <.signature_pad id="medrep-doctor-sig" label="Doctor's Signature" />
          </div>
          <div>
            <.official_stamp />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
