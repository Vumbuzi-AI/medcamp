defmodule MedcampWeb.PharmacistsLive.DangerousDrugRegisterIndex do
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.Drugs

  @per_page 12

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :dangerous_drug_registers)
     |> assign(:page_title, "Dangerous Drug Register")
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:all_drugs, Drugs.list_register_drugs())
     |> paginate_drugs()}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:page, 1)
     |> paginate_drugs()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> paginate_drugs()}
  end

  defp paginate_drugs(socket) do
    filtered = filter_drugs(socket.assigns.all_drugs, socket.assigns.search)
    total_count = length(filtered)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    filtered_drugs =
      Enum.slice(filtered, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:filtered_drugs, filtered_drugs)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
        <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
          Dangerous Drug Register
        </.header>

        <div class="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div class="max-w-xl">
            <p class="text-sm text-gray-600">
              Open a monthly register only for drugs marked `In DDA` on the pharmacist drugs page.
              The register page keeps the month selector, removes the transaction number column, and
              leaves prescription reference optional when scripts are not numbered.
            </p>
          </div>

          <form phx-change="search" class="w-full md:w-80">
            <label class="block text-sm font-medium text-gray-700 mb-1">Find drug</label>
            <input
              type="text"
              name="search"
              value={@search}
              placeholder="Search by brand or generic name"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
            />
          </form>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
        <%= for drug <- @filtered_drugs do %>
          <.link
            navigate={~p"/pharmacist/dangerous_drug_registers/#{drug.id}"}
            class="block rounded-xl border border-orange-100 bg-gradient-to-br from-orange-50 via-white to-amber-50 p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <div class="flex items-start justify-between gap-3">
              <div>
                <h3 class="text-lg font-semibold text-slate-900">{Drugs.display_name(drug)}</h3>
                <p class="mt-2 text-sm text-slate-600">
                  {inventory_label(drug)}
                </p>
              </div>

              <div class="rounded-full bg-orange-100 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-orange-700">
                Register
              </div>
            </div>
          </.link>
        <% end %>
      </div>

      <%= if @filtered_drugs == [] do %>
        <div class="rounded-lg border border-dashed border-gray-300 bg-white p-8 text-center text-sm text-gray-500">
          No DDA drugs matched that search. Mark a drug as `In DDA` from the pharmacist drugs page
          first.
        </div>
      <% end %>

      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
      />
    </div>
    """
  end

  defp filter_drugs(drugs, search) do
    search = String.trim(search || "")

    if search == "" do
      drugs
    else
      query = String.downcase(search)

      Enum.filter(drugs, fn drug ->
        drug
        |> Drugs.display_name()
        |> String.downcase()
        |> String.contains?(query)
      end)
    end
  end

  defp inventory_label(drug) do
    inventory_received = drug.inventory_received

    cond do
      inventory_received && present?(inventory_received.type) && present?(inventory_received.uom) ->
        "#{inventory_received.type} • #{inventory_received.uom}"

      inventory_received && present?(inventory_received.type) ->
        inventory_received.type

      inventory_received && present?(inventory_received.uom) ->
        inventory_received.uom

      true ->
        "Open monthly register"
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_value), do: false
end
