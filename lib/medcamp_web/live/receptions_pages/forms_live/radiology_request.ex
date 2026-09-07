defmodule MedcampWeb.ReceptionsPageFormLive.RadiologyRequest do
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
        <.form_header_centered title="Radiology Request Form" />

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              1
            </span>
            Patient Details
          </h2>
          <div class="ml-8 grid grid-cols-1 md:grid-cols-3 gap-x-6 gap-y-4">
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Full Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Patient's full name"
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
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Phone Number
              </label>
              <input
                type="tel"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Phone number"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Patient ID
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Hospital / Patient ID"
              />
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              2
            </span>
            Clinical Information
          </h2>
          <div class="ml-8">
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Provisional Diagnosis / Clinical History
            </label>
            <textarea
              rows="5"
              class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
              placeholder="Enter provisional diagnosis and relevant clinical history..."
            ></textarea>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              3
            </span>
            Radiology Investigation Requested
          </h2>
          <div class="ml-8 space-y-5">
            <div class="border border-gray-100 rounded-lg p-4 hover:border-[#373896]/30 transition-colors">
              <label class="flex items-center gap-2 text-sm font-semibold text-gray-700 cursor-pointer mb-3">
                <input type="checkbox" class="w-4 h-4 accent-[#373896]" /> X-Ray
              </label>
              <div class="flex flex-wrap gap-4 ml-6">
                <%= for sub <- ["Chest", "Abdomen", "Spine", "Limbs"] do %>
                  <label class="flex items-center gap-1.5 text-sm text-gray-600 cursor-pointer">
                    <input type="checkbox" class="w-3.5 h-3.5 accent-[#373896]" /> {sub}
                  </label>
                <% end %>
                <div class="flex items-center gap-2">
                  <span class="text-sm text-gray-600">Other:</span>
                  <input
                    type="text"
                    class="border-b border-gray-300 focus:border-[#373896] outline-none text-sm bg-transparent w-32"
                    placeholder="specify"
                  />
                </div>
              </div>
            </div>

            <div class="border border-gray-100 rounded-lg p-4 hover:border-[#373896]/30 transition-colors">
              <label class="flex items-center gap-2 text-sm font-semibold text-gray-700 cursor-pointer mb-3">
                <input type="checkbox" class="w-4 h-4 accent-[#373896]" /> Ultrasound
              </label>
              <div class="flex flex-wrap gap-4 ml-6">
                <%= for sub <- ["Abdomen", "Pelvis", "OB Scan", "Doppler"] do %>
                  <label class="flex items-center gap-1.5 text-sm text-gray-600 cursor-pointer">
                    <input type="checkbox" class="w-3.5 h-3.5 accent-[#373896]" /> {sub}
                  </label>
                <% end %>
                <div class="flex items-center gap-2">
                  <span class="text-sm text-gray-600">Other:</span>
                  <input
                    type="text"
                    class="border-b border-gray-300 focus:border-[#373896] outline-none text-sm bg-transparent w-32"
                    placeholder="specify"
                  />
                </div>
              </div>
            </div>

            <div class="border border-gray-100 rounded-lg p-4 hover:border-[#373896]/30 transition-colors">
              <label class="flex items-center gap-2 text-sm font-semibold text-gray-700 cursor-pointer mb-3">
                <input type="checkbox" class="w-4 h-4 accent-[#373896]" /> CT Scan
              </label>
              <div class="flex flex-wrap gap-4 ml-6">
                <%= for sub <- ["Head", "Chest", "Abdomen/Pelvis", "Contrast", "Non-contrast"] do %>
                  <label class="flex items-center gap-1.5 text-sm text-gray-600 cursor-pointer">
                    <input type="checkbox" class="w-3.5 h-3.5 accent-[#373896]" /> {sub}
                  </label>
                <% end %>
                <div class="mt-2 w-full flex items-center gap-2">
                  <span class="text-sm text-gray-600">Other:</span>
                  <input
                    type="text"
                    class="flex-1 border-b border-gray-300 focus:border-[#373896] outline-none text-sm bg-transparent"
                    placeholder="specify"
                  />
                </div>
              </div>
            </div>

            <div class="border border-gray-100 rounded-lg p-4 hover:border-[#373896]/30 transition-colors">
              <label class="flex items-center gap-2 text-sm font-semibold text-gray-700 cursor-pointer mb-3">
                <input type="checkbox" class="w-4 h-4 accent-[#373896]" /> MRI
              </label>
              <div class="flex flex-wrap gap-4 ml-6">
                <%= for sub <- ["Brain", "Spine", "Joints", "Contrast", "Non-contrast"] do %>
                  <label class="flex items-center gap-1.5 text-sm text-gray-600 cursor-pointer">
                    <input type="checkbox" class="w-3.5 h-3.5 accent-[#373896]" /> {sub}
                  </label>
                <% end %>
                <div class="mt-2 w-full flex items-center gap-2">
                  <span class="text-sm text-gray-600">Other:</span>
                  <input
                    type="text"
                    class="flex-1 border-b border-gray-300 focus:border-[#373896] outline-none text-sm bg-transparent"
                    placeholder="specify"
                  />
                </div>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <label class="flex items-center gap-2 text-sm font-semibold text-gray-700 cursor-pointer shrink-0">
                <input type="checkbox" class="w-4 h-4 accent-[#373896]" /> Other Imaging:
              </label>
              <input
                type="text"
                class="flex-1 border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Specify other imaging requested"
              />
            </div>
          </div>
        </section>

        <section class="mb-7">
          <h2 class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-[#373896] text-white text-xs font-bold flex items-center justify-center shrink-0">
              5
            </span>
            Requesting Clinician Details
          </h2>
          <div class="ml-8 grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
            <div>
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
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Signature &amp; Date
              </label>
              <div class="flex gap-4 items-end">
                <div class="w-48 h-12 border border-dashed border-gray-300 rounded-lg flex items-center justify-center text-xs text-gray-400 shrink-0">
                  Clinician signature
                </div>
                <input
                  type="date"
                  class="flex-1 border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                />
              </div>
            </div>
          </div>
        </section>

        <section class="pt-6 border-t border-gray-200">
          <h2 class="text-sm font-bold text-gray-800 mb-5 flex items-center gap-2">
            <span class="w-6 h-6 rounded-full bg-gray-500 text-white text-xs font-bold flex items-center justify-center shrink-0">
              6
            </span>
            For Radiology Department Use Only
          </h2>
          <div class="ml-8 grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Report Number
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-gray-500 outline-none py-1 text-sm bg-transparent"
                placeholder="Report No."
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Date &amp; Time Done
              </label>
              <input
                type="datetime-local"
                class="w-full border-b border-gray-300 focus:border-gray-500 outline-none py-1 text-sm bg-transparent"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Radiographer / Radiologist
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-gray-500 outline-none py-1 text-sm bg-transparent"
                placeholder="Name of radiographer/radiologist"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Findings
              </label>
              <textarea
                rows="5"
                class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-gray-500 outline-none resize-y bg-transparent"
                placeholder="Radiological findings..."
              ></textarea>
            </div>
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Remarks
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-gray-500 outline-none py-1 text-sm bg-transparent"
                placeholder="Additional remarks"
              />
            </div>
          </div>
        </section>
      </div>
    </div>
    """
  end
end
