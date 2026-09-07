defmodule MedcampWeb.Procurement.PlaceholderLive do
  @moduledoc false

  use MedcampWeb, :html

  defmacro __using__(opts) do
    title = Keyword.fetch!(opts, :title)

    description =
      Keyword.get(opts, :description, "This screen will be built in a later procurement phase.")

    quote do
      use MedcampWeb, :procurement_live_view

      @impl true
      def mount(params, _session, socket) do
        {:ok,
         socket
         |> assign(:page_title, unquote(title))
         |> assign(:page_description, unquote(description))
         |> assign(:route_params, params)}
      end

      @impl true
      def render(assigns), do: MedcampWeb.Procurement.PlaceholderLive.render_page(assigns)
    end
  end

  def render_page(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl space-y-4 p-6">
      <div class="space-y-1">
        <h1 class="text-2xl font-semibold text-slate-900">{@page_title}</h1>
        <p class="text-sm text-slate-600">{@page_description}</p>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-sm font-medium text-slate-700">Phase 3 placeholder</p>
        <p class="mt-2 text-sm text-slate-600">
          Routing and role guards are wired up. The full procurement portal screens land in later phases.
        </p>
      </div>

      <div
        :if={map_size(@route_params) > 0}
        class="rounded-xl border border-slate-200 bg-slate-50 p-4"
      >
        <p class="text-sm font-medium text-slate-700">Route params</p>
        <pre class="mt-2 overflow-x-auto text-xs text-slate-600">{inspect(@route_params, pretty: true)}</pre>
      </div>
    </div>
    """
  end
end
