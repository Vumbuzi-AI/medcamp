defmodule MedcampWeb.ReceptionsPageFormLive.PatientReferral do
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
        <.form_header_centered title="Patient Referral Form" />

        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-4 mb-6">
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
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Referral Time
            </label>
            <input
              type="time"
              class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
            />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Referral To
            </label>
            <input
              type="text"
              class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              placeholder="Facility or department name"
            />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Focal Person
            </label>
            <input
              type="text"
              class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              placeholder="Contact person"
            />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Location
            </label>
            <input
              type="text"
              class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              placeholder="Facility location"
            />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Phone
            </label>
            <input
              type="tel"
              class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              placeholder="Contact phone"
            />
          </div>
          <div class="md:col-span-2">
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Email
            </label>
            <input
              type="email"
              class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              placeholder="Contact email"
            />
          </div>
        </div>

        <div class="bg-[#e7e7ff] rounded-lg p-4 mb-6">
          <p class="text-xs font-semibold text-[#373896] uppercase tracking-wide mb-3">
            Referring From
          </p>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-3 text-sm">
            <div>
              <p class="text-[#373896] font-semibold mb-1">Glocal Healthcare Centre of Excellence</p>
            </div>
            <div></div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Referring Dr.
              </label>
              <input
                type="text"
                class="w-full border-b border-[#373896]/40 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Doctor's name"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Phone
              </label>
              <input
                type="tel"
                class="w-full border-b border-[#373896]/40 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Doctor's phone"
              />
            </div>
            <div>
              <p class="text-[#373896] text-sm font-medium">Kisaju, Mwalimu Park, Kajiado County</p>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Email
              </label>
              <input
                type="email"
                class="w-full border-b border-[#373896]/40 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Doctor's email"
              />
            </div>
          </div>
        </div>

        <section class="mb-6">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-3">
            Patient Information
          </h2>
          <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full text-sm">
              <tbody class="divide-y divide-gray-100">
                <tr class="divide-x divide-gray-100">
                  <td class="px-3 py-2.5 bg-gray-50 font-medium text-gray-600 w-36">Full Name:</td>
                  <td class="px-3 py-2.5">
                    <input
                      type="text"
                      class="w-full outline-none text-sm bg-transparent"
                      placeholder="Patient's full name"
                    />
                  </td>
                  <td class="px-3 py-2.5 bg-gray-50 font-medium text-gray-600 w-20">Phone:</td>
                  <td class="px-3 py-2.5">
                    <input
                      type="tel"
                      class="w-full outline-none text-sm bg-transparent"
                      placeholder="Phone"
                    />
                  </td>
                </tr>
                <tr class="divide-x divide-gray-100">
                  <td class="px-3 py-2.5 bg-gray-50 font-medium text-gray-600">Date of Birth:</td>
                  <td class="px-3 py-2.5">
                    <input type="date" class="outline-none text-sm bg-transparent" />
                  </td>
                  <td class="px-3 py-2.5 bg-gray-50 font-medium text-gray-600">Gender:</td>
                  <td class="px-3 py-2.5">
                    <div class="flex gap-3">
                      <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                        <input type="radio" name="pt_gender" value="male" class="accent-[#373896]" />
                        Male
                      </label>
                      <label class="flex items-center gap-1.5 text-sm cursor-pointer">
                        <input type="radio" name="pt_gender" value="female" class="accent-[#373896]" />
                        Female
                      </label>
                    </div>
                  </td>
                </tr>
                <tr class="divide-x divide-gray-100">
                  <td class="px-3 py-2.5 bg-gray-50 font-medium text-gray-600">Address:</td>
                  <td class="px-3 py-2.5">
                    <input
                      type="text"
                      class="w-full outline-none text-sm bg-transparent"
                      placeholder="Home address"
                    />
                  </td>
                  <td class="px-3 py-2.5 bg-gray-50 font-medium text-gray-600">Next of Kin:</td>
                  <td class="px-3 py-2.5">
                    <input
                      type="text"
                      class="w-full outline-none text-sm bg-transparent"
                      placeholder="Next of kin name"
                    />
                  </td>
                </tr>
                <tr>
                  <td class="px-3 py-2.5 bg-gray-50 font-medium text-gray-600">
                    Accompanied by care provider:
                  </td>
                  <td colspan="3" class="px-3 py-2.5">
                    <div class="flex gap-4">
                      <label class="flex items-center gap-2 text-sm cursor-pointer">
                        <input type="radio" name="accompanied" value="yes" class="accent-[#373896]" />
                        Yes
                      </label>
                      <label class="flex items-center gap-2 text-sm cursor-pointer">
                        <input type="radio" name="accompanied" value="no" class="accent-[#373896]" />
                        No
                      </label>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="mb-6">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-3">Vital Signs</h2>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <%= for {label, placeholder} <- [{"BP", "mmHg"}, {"Weight", "kg"}, {"Pulse", "bpm"}, {"SPO2", "%"}] do %>
              <div>
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  {label}
                </label>
                <input
                  type="text"
                  class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                  placeholder={placeholder}
                />
              </div>
            <% end %>
            <div class="md:col-span-4">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Any Other
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Other vital signs or observations"
              />
            </div>
          </div>
        </section>

        <section class="mb-5">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-2">
            Clinical History
          </h2>
          <textarea
            rows="5"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
            placeholder="Relevant clinical history..."
          ></textarea>
        </section>

        <section class="mb-5">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-2">
            Primary Diagnoses
          </h2>
          <textarea
            rows="5"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
            placeholder="Primary diagnosis/diagnoses..."
          ></textarea>
        </section>

        <section class="mb-5">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-2">
            Tests Conducted
          </h2>
          <textarea
            rows="5"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
            placeholder="Tests conducted and results..."
          ></textarea>
        </section>

        <section class="mb-5">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-2">
            Treatments Initiated
          </h2>
          <div class="flex gap-4 items-start">
            <textarea
              rows="5"
              class="flex-1 border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
              placeholder="Treatments given before referral..."
            ></textarea>
            <label class="flex items-center gap-2 text-sm cursor-pointer mt-3 shrink-0">
              <input type="checkbox" class="w-4 h-4 accent-[#373896]" /> Ongoing
            </label>
          </div>
        </section>

        <section class="mb-8">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-2">
            Reason for Referral
          </h2>
          <textarea
            rows="5"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
            placeholder="Reason(s) for referring this patient..."
          ></textarea>
        </section>

        <div class="border-t border-gray-200 pt-5 text-center space-y-1">
          <p class="text-xs text-red-500 italic font-medium">Attach relevant patient information</p>
          <p class="text-sm font-bold text-[#373896] italic">Global Standards, Local Care</p>
        </div>
      </div>
    </div>
    """
  end
end
