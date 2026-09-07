defmodule MedcampWeb.ReceptionsPageFormLive.PrescriptionSheet do
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
        <.form_header_centered title="Prescription Sheet" />

        <section class="mb-7">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">
            Patient Information
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
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                Gender
              </label>
              <div class="flex gap-5">
                <label class="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="radio" name="gender" value="male" class="accent-[#373896]" /> Male
                </label>
                <label class="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="radio" name="gender" value="female" class="accent-[#373896]" /> Female
                </label>
              </div>
            </div>
            <div class="md:col-span-2">
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
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">Prescriber</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Prescriber's full name"
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
                Contact
              </label>
              <input
                type="tel"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Phone / extension"
              />
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-4">Prescription</h2>
          <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="w-full text-sm">
              <thead>
                <tr class="bg-[#373896] text-white">
                  <th class="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3">#</th>
                  <th class="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3">
                    Route
                  </th>
                  <th class="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3">
                    Medication
                  </th>
                  <th class="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3">
                    Strength
                  </th>
                  <th class="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3">
                    Frequency
                  </th>
                  <th class="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3">
                    Duration
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= for i <- 1..8 do %>
                  <tr class="hover:bg-gray-50">
                    <td class="px-4 py-2.5 text-gray-400 text-xs shrink-0">{i}.</td>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="e.g. Oral"
                      />
                    </td>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="Drug name"
                      />
                    </td>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="e.g. 500mg"
                      />
                    </td>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="e.g. BD"
                      />
                    </td>
                    <td class="px-3 py-2">
                      <input
                        type="text"
                        class="w-full border-b border-gray-200 focus:border-[#373896] outline-none text-sm bg-transparent"
                        placeholder="e.g. 5 days"
                      />
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </section>

        <section class="mb-8">
          <h2 class="text-sm font-bold text-[#373896] uppercase tracking-wider mb-3">
            Notes / Instructions
          </h2>
          <textarea
            rows="5"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
            placeholder="Special instructions, allergy notes, or additional directions for the patient..."
          ></textarea>
        </section>

        <div class="pt-6 border-t border-gray-200 w-80">
          <.signature_pad id="prescription-prescriber-sig" label="Prescriber Signature" />
        </div>
      </div>
    </div>
    """
  end
end
