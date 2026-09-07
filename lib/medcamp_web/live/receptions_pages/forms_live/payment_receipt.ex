defmodule MedcampWeb.ReceptionsPageFormLive.PaymentReceipt do
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
    <div class="max-w-2xl mx-auto">
      <div class="flex items-center justify-between mb-6 print:hidden">
        <a href="/forms" class="flex items-center gap-1 text-sm text-gray-500 hover:text-[#373896]">
          <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Forms
        </a>
        <button
          type="button"
          onclick="window.print()"
          class="flex items-center gap-2 px-4 py-2 bg-[#373896] text-white rounded-lg text-sm font-medium hover:bg-[#2d2d7a] transition-colors"
        >
          <.icon name="hero-printer" class="w-4 h-4" /> Print Receipt
        </button>
      </div>

      <div class="bg-white border-2 border-gray-300 rounded-xl shadow-sm overflow-hidden print:shadow-none print:border-2 print:border-gray-400">
        <div class="px-8 py-6">
          <.form_header_centered title="Payment Receipt" />
        </div>

        <div class="px-6 py-4 bg-white border-b border-gray-200 text-xs text-gray-500 space-y-0.5">
          <p>+254-726776293 / 739 371657</p>
          <p>info@glocalhealthcentre.org</p>
          <p>P.O BOX 3243-00200 Nairobi Kenya</p>
          <p>Mwalimu Sacco Kisaju, Namanga Road</p>
        </div>

        <div class="px-6 py-6">
          <div class="flex justify-between items-center mb-8">
            <div class="flex items-center gap-3">
              <span class="text-sm font-semibold text-gray-600">Receipt No:</span>
              <input
                type="text"
                class="border-b border-gray-400 focus:border-[#373896] outline-none text-sm bg-transparent w-36"
                placeholder="Receipt number"
              />
            </div>
            <div class="flex items-center gap-3">
              <span class="text-sm font-semibold text-gray-600">Date:</span>
              <input
                type="date"
                class="border-b border-gray-400 focus:border-[#373896] outline-none text-sm bg-transparent"
              />
            </div>
          </div>

          <div class="space-y-5 mb-8">
            <div class="flex items-center border-b border-gray-300 pb-3">
              <span class="text-sm font-bold text-[#373896] w-44 shrink-0">Received From</span>
              <input
                type="text"
                class="flex-1 border-b border-gray-400 focus:border-[#373896] outline-none text-sm bg-transparent ml-2"
                placeholder="Patient or payer name"
              />
            </div>
            <div class="flex items-center border-b border-gray-300 pb-3">
              <span class="text-sm font-bold text-[#373896] w-44 shrink-0">Amount in Words</span>
              <input
                type="text"
                class="flex-1 border-b border-gray-400 focus:border-[#373896] outline-none text-sm bg-transparent ml-2"
                placeholder="e.g. Five Hundred Shillings Only"
              />
            </div>
            <div class="flex items-center border-b border-gray-300 pb-3">
              <span class="text-sm font-bold text-[#373896] w-44 shrink-0">Being Payment Of</span>
              <input
                type="text"
                class="flex-1 border-b border-gray-400 focus:border-[#373896] outline-none text-sm bg-transparent ml-2"
                placeholder="Description of service/payment"
              />
            </div>
            <div class="flex items-center border-b border-gray-300 pb-3">
              <span class="text-sm font-bold text-[#373896] w-44 shrink-0">Printed By</span>
              <input
                type="text"
                class="flex-1 border-b border-gray-400 focus:border-[#373896] outline-none text-sm bg-transparent ml-2"
                placeholder="Staff name"
              />
            </div>
          </div>

          <div class="flex justify-end mb-8">
            <div class="text-right">
              <p class="text-xs font-bold text-gray-500 uppercase tracking-widest mb-2">Amount</p>
              <div class="border-2 border-gray-300 rounded-lg w-48 px-4 py-3 flex items-center justify-between gap-2">
                <span class="text-sm font-semibold text-gray-500">KES</span>
                <input
                  type="text"
                  class="flex-1 text-right text-xl font-bold text-gray-900 outline-none bg-transparent"
                  placeholder="0.00"
                />
              </div>
            </div>
          </div>

          <div class="text-center">
            <p class="text-sm font-bold text-[#373896] italic">Thank you for visiting GHC-E</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
