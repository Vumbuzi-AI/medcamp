defmodule MedcampWeb.ReceptionsPageFormLive.SurgicalConsent do
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

      <div class="bg-white border border-gray-200 rounded-xl shadow-sm p-8 print:shadow-none print:border-none print:p-0">
        <.form_header_centered title="Surgical Consent Form" />

        <div class="bg-gray-50 rounded-lg p-5 mb-6 text-sm text-gray-700 leading-loose">
          I,
          <input
            type="text"
            class="inline border-b border-gray-400 focus:border-[#373896] outline-none mx-1 w-44 text-sm bg-transparent"
            placeholder="Patient / Guardian name"
          />,
          of ID/Passport No:
          <input
            type="text"
            class="inline border-b border-gray-400 focus:border-[#373896] outline-none mx-1 w-36 text-sm bg-transparent"
            placeholder="ID/Passport No."
          />,
          hereby give my full consent to Dr.
          <input
            type="text"
            class="inline border-b border-gray-400 focus:border-[#373896] outline-none mx-1 w-40 text-sm bg-transparent"
            placeholder="Doctor's name"
          /> and his/her team to perform the following surgical procedure:
          <input
            type="text"
            class="inline border-b border-gray-400 focus:border-[#373896] outline-none mx-1 w-52 text-sm bg-transparent"
            placeholder="Name of procedure"
          />.
        </div>

        <p class="text-sm font-semibold text-gray-700 mb-3">I confirm that:</p>
        <ul class="space-y-3 mb-6 text-sm text-gray-700">
          <li class="flex items-start gap-2">
            <span class="text-[#373896] font-bold mt-0.5">–</span>
            The procedure, its purpose, risks, benefits, and possible complications have been clearly explained to me.
          </li>
          <li class="flex items-start gap-2">
            <span class="text-[#373896] font-bold mt-0.5">–</span>
            I have had the opportunity to ask questions, and all my questions have been answered to my satisfaction.
          </li>
          <li class="flex items-start gap-2">
            <span class="text-[#373896] font-bold mt-0.5">–</span>
            I understand that anesthesia may be administered and that this carries certain risks.
          </li>
          <li class="flex items-start gap-2">
            <span class="text-[#373896] font-bold mt-0.5">–</span>
            I understand that unforeseen conditions may require additional procedures.
          </li>
        </ul>

        <p class="text-sm text-gray-700 mb-8">
          I voluntarily give my consent for the above surgery to be performed.
        </p>

        <div class="space-y-5 pt-6 border-t border-gray-200">
          <div class="flex flex-col md:flex-row md:items-end gap-4">
            <div class="flex-1">
              <.signature_pad id="surgical-patient-sig" label="Patient's Signature" />
            </div>
            <div class="md:w-44">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Date
              </label>
              <input
                type="date"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
              />
            </div>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide">
                Witness Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Witness name"
              />
              <.signature_pad id="surgical-witness-sig" label="Witness Signature" />
            </div>
            <div class="space-y-2">
              <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide">
                Doctor's Name
              </label>
              <input
                type="text"
                class="w-full border-b border-gray-300 focus:border-[#373896] outline-none py-1 text-sm bg-transparent"
                placeholder="Doctor's name"
              />
              <.signature_pad id="surgical-doctor-sig" label="Doctor's Signature" />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
