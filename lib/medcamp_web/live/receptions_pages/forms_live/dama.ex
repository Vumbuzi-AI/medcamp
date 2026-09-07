defmodule MedcampWeb.ReceptionsPageFormLive.Dama do
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
        <div class="flex items-center gap-3">
          <a href="/forms" class="flex items-center gap-1 text-sm text-gray-500 hover:text-[#373896]">
            <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Forms
          </a>
        </div>
        <button
          type="button"
          onclick="window.print()"
          class="flex items-center gap-2 px-4 py-2 bg-[#373896] text-white rounded-lg text-sm font-medium hover:bg-[#2d2d7a] transition-colors"
        >
          <.icon name="hero-printer" class="w-4 h-4" /> Print Form
        </button>
      </div>

      <div
        id="dama-form"
        class="bg-white border border-gray-200 rounded-xl shadow-sm p-8 print:shadow-none print:border-none print:p-0"
      >
        <.form_header_centered title="Discharge Against Medical Advice (DAMA) Form" />

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Hospital / Clinic Name
            </label>
            <input
              type="text"
              class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              placeholder="Enter hospital name"
            />
          </div>
          <div>
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
              Address / Contact
            </label>
            <input
              type="text"
              class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              placeholder="Enter address and contact"
            />
          </div>
        </div>

        <section class="mb-8">
          <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4 flex items-center gap-2">
            <span class="w-1 h-4 bg-[#373896] rounded-full inline-block"></span> Patient Information
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-5">
            <div>
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
                Hospital / MRN Number
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="MRN / Hospital No."
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Date of Birth / Age
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="DD/MM/YYYY or Age"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Gender
              </label>
              <div class="flex gap-6 mt-2">
                <label class="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="radio" name="gender" value="male" class="accent-[#373896]" /> Male
                </label>
                <label class="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="radio" name="gender" value="female" class="accent-[#373896]" /> Female
                </label>
                <label class="flex items-center gap-2 text-sm cursor-pointer">
                  <input type="radio" name="gender" value="other" class="accent-[#373896]" /> Other
                </label>
              </div>
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Ward / Unit
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Ward or unit name"
              />
            </div>
            <div>
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Attending Physician
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Physician name"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Date &amp; Time of Admission
              </label>
              <input
                type="datetime-local"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              />
            </div>
          </div>
        </section>

        <section class="mb-8">
          <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4 flex items-center gap-2">
            <span class="w-1 h-4 bg-[#373896] rounded-full inline-block"></span>
            Statement of Refusal of Medical Advice
          </h2>
          <div class="bg-gray-50 rounded-lg p-4 text-sm text-gray-700 leading-relaxed mb-4">
            I,
            <input
              type="text"
              class="inline border-b border-gray-400 focus:border-[#373896] outline-none mx-1 w-48 text-sm bg-transparent"
              placeholder="patient / legal guardian name"
            />
            (patient / legal guardian), confirm that I have been informed of my medical condition and the recommended treatment, investigations, and/or continued hospitalization.
          </div>
          <div class="bg-gray-50 rounded-lg p-4 text-sm text-gray-700 leading-relaxed">
            I understand that my treating physician has advised me not to leave the hospital and has explained the possible risks of doing so. Despite this, I voluntarily choose to leave the hospital and refuse further medical care.
          </div>
        </section>

        <section class="mb-8">
          <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4 flex items-center gap-2">
            <span class="w-1 h-4 bg-rose-500 rounded-full inline-block"></span> Risks Explained
          </h2>
          <div class="bg-rose-50 rounded-lg p-4 text-sm text-rose-800 leading-relaxed">
            I acknowledge that refusing medical advice may result in worsening of my condition, serious complications, permanent disability, or death.
          </div>
        </section>

        <section class="mb-8">
          <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-3 flex items-center gap-2">
            <span class="w-1 h-4 bg-gray-400 rounded-full inline-block"></span>
            Reason for Leaving Against Medical Advice
            <span class="text-gray-400 font-normal normal-case tracking-normal text-xs">
              (Optional)
            </span>
          </h2>
          <textarea
            rows="5"
            class="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none resize-y bg-transparent"
            placeholder="State your reason for leaving..."
          ></textarea>
        </section>

        <section class="mb-8">
          <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-4 flex items-center gap-2">
            <span class="w-1 h-4 bg-[#373896] rounded-full inline-block"></span>
            Acknowledgment and Release
          </h2>
          <div class="bg-gray-50 rounded-lg p-4 text-sm text-gray-700 leading-relaxed">
            I accept full responsibility for my decision and release the hospital, physicians, nurses, and staff from any liability arising from my decision to leave against medical advice.
          </div>
        </section>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 pt-6 border-t border-gray-200">
          <section>
            <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-5 flex items-center gap-2">
              <span class="w-1 h-4 bg-[#373896] rounded-full inline-block"></span>
              Patient / Guardian Declaration
            </h2>
            <div class="space-y-5">
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
                  Relationship (if applicable)
                </label>
                <input
                  type="text"
                  class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                  placeholder="e.g. Spouse, Parent, Guardian"
                />
              </div>
              <.signature_pad id="dama-patient-sig" label="Signature" />
              <div>
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  Date &amp; Time
                </label>
                <input
                  type="datetime-local"
                  class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                />
              </div>
            </div>
          </section>

          <section>
            <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider mb-5 flex items-center gap-2">
              <span class="w-1 h-4 bg-gray-500 rounded-full inline-block"></span>
              Witness / Medical Staff
            </h2>
            <div class="space-y-5">
              <div>
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  Name &amp; Designation
                </label>
                <input
                  type="text"
                  class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                  placeholder="Name and designation"
                />
              </div>
              <.signature_pad id="dama-witness-sig" label="Signature" />
              <div>
                <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                  Date &amp; Time
                </label>
                <input
                  type="datetime-local"
                  class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                />
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end
end
