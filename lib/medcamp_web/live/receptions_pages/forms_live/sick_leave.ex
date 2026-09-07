defmodule MedcampWeb.ReceptionsPageFormLive.SickLeave do
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
    <div class="max-w-3xl mx-auto">
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

      <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden print:shadow-none print:border-none">
        <div class="px-8 py-8">
          <.form_header_centered title="Sick Leave Sheet" />

          <p class="font-bold text-gray-900 mb-2 text-sm">TO WHOM IT MAY CONCERN</p>
          <p class="text-sm text-gray-700 mb-6">This is to certify that:</p>

          <div class="space-y-5 mb-6">
            <div class="flex flex-col md:flex-row md:items-end gap-2 md:gap-6">
              <div class="flex-1">
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  Patient Name
                </label>
                <input
                  type="text"
                  class="w-full border-b border-gray-400 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                  placeholder="Full name"
                />
              </div>
              <div class="md:w-32">
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  Age
                </label>
                <input
                  type="text"
                  class="w-full border-b border-gray-400 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                  placeholder="Age"
                />
              </div>
              <div class="md:w-36">
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  Gender
                </label>
                <select class="w-full border-b border-gray-400 focus:border-[#373896] outline-none py-1 text-sm bg-transparent">
                  <option value="">Select</option>
                  <option>Male</option>
                  <option>Female</option>
                  <option>Other</option>
                </select>
              </div>
            </div>

            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Identification Number (ID/Passport)
              </label>
              <input
                type="text"
                class="w-64 border-b border-gray-400 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="ID or Passport number"
              />
            </div>
          </div>

          <div class="bg-gray-50 rounded-lg p-4 mb-6 text-sm text-gray-700 leading-relaxed">
            Was examined and treated at this facility on
            <input
              type="date"
              class="inline border-b border-gray-400 focus:border-[#373896] outline-none mx-1 text-sm bg-transparent"
            /> and has been found to be <strong>medically unfit</strong>
            to attend
            <select class="inline border-b border-gray-400 focus:border-[#373896] outline-none mx-1 text-sm bg-transparent font-semibold">
              <option>work</option>
              <option>school</option>
              <option>work / school</option>
            </select>
            due to health reasons.
          </div>

          <p class="text-sm text-gray-700 mb-5">
            Accordingly, the patient is advised to refrain from
            <select class="inline border-b border-gray-400 focus:border-[#373896] outline-none mx-1 text-sm bg-transparent font-semibold">
              <option>work</option>
              <option>school</option>
              <option>work / school</option>
            </select>
            from:
          </p>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-x-6 gap-y-4 mb-6">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Start Date
              </label>
              <input
                type="date"
                class="w-full border-b border-gray-400 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                End Date
              </label>
              <input
                type="date"
                class="w-full border-b border-gray-400 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Total Days of Leave Recommended
              </label>
              <div class="flex items-center gap-2">
                <input
                  type="number"
                  min="1"
                  class="w-20 border-b border-gray-400 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                  placeholder="0"
                />
                <span class="text-sm text-gray-600">days</span>
              </div>
            </div>
          </div>

          <div class="mb-8">
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
              Remarks (if any)
            </label>
            <textarea
              rows="5"
              class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
              placeholder="Any additional remarks or medical notes..."
            ></textarea>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-5 mb-8 pt-6 border-t border-gray-200">
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Medical Officer / Clinician's Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-400 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Full name"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Date Issued
              </label>
              <input
                type="date"
                class="w-full border-b border-gray-400 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              />
            </div>
            <div>
              <.signature_pad id="sicklv-officer-sig" label="Medical Officer Signature" />
            </div>
            <div>
              <.official_stamp />
            </div>
          </div>

          <div class="border-t border-gray-200 pt-5 text-center space-y-1">
            <p class="text-sm font-semibold text-[#373896]">Glocal Healthcare Centre of Excellence</p>
            <div class="flex flex-wrap justify-center gap-x-4 gap-y-1 text-xs text-gray-500">
              <span class="flex items-center gap-1">
                <.icon name="hero-home" class="w-3 h-3" /> P.O Box 3243-00200, Nairobi Kenya
              </span>
              <span class="flex items-center gap-1">
                <.icon name="hero-map-pin" class="w-3 h-3" /> Mwalimu Sacco, Kisaju, Namanga Road
              </span>
              <span class="flex items-center gap-1">
                <.icon name="hero-phone" class="w-3 h-3" /> +254 70904200 / 709040299
              </span>
              <span class="flex items-center gap-1">
                <.icon name="hero-envelope" class="w-3 h-3" /> info@glocalhealthcentre.org
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
