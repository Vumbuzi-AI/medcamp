defmodule MedcampWeb.SentryWebhooksLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.SentryWebhooks

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :sentry_webhooks)
     |> assign(:page_title, "Sentry Webhooks")
     |> assign(:selected_delivery, nil)
     |> load_deliveries()}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, load_deliveries(socket)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    selected = Enum.find(socket.assigns.deliveries, &(to_string(&1.id) == id))
    {:noreply, assign(socket, :selected_delivery, selected)}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :selected_delivery, nil)}
  end

  defp load_deliveries(socket) do
    deliveries = SentryWebhooks.list_deliveries()

    selected_delivery =
      case socket.assigns[:selected_delivery] do
        nil -> nil
        selected -> Enum.find(deliveries, &(&1.id == selected.id))
      end

    socket
    |> assign(:deliveries, deliveries)
    |> assign(:selected_delivery, selected_delivery)
  end

  defp delivery_title(delivery) do
    get_in(delivery.payload, ["data", "issue", "title"]) ||
      get_in(delivery.payload, ["data", "error", "title"]) ||
      get_in(delivery.payload, ["data", "event", "title"]) ||
      delivery.action || delivery.resource || "Sentry webhook"
  end

  defp delivery_reference(delivery) do
    get_in(delivery.payload, ["data", "issue", "shortId"]) ||
      get_in(delivery.payload, ["data", "issue", "id"]) ||
      get_in(delivery.payload, ["data", "error", "event_id"]) ||
      get_in(delivery.payload, ["data", "error", "issue_id"]) ||
      get_in(delivery.payload, ["data", "event", "event_id"]) ||
      "Delivery ##{delivery.id}"
  end

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%d %b %Y, %H:%M:%S UTC")
  end

  defp format_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> format_datetime(datetime)
      _error -> value
    end
  end

  defp format_datetime(value) when is_float(value) do
    value
    |> Kernel.*(1_000_000)
    |> round()
    |> DateTime.from_unix(:microsecond)
    |> case do
      {:ok, datetime} -> format_datetime(datetime)
      _error -> to_string(value)
    end
  end

  defp format_datetime(value), do: to_string(value)

  defp error_data(delivery) do
    get_in(delivery.payload, ["data", "error"]) ||
      get_in(delivery.payload, ["data", "event"]) ||
      get_in(delivery.payload, ["data", "issue"]) || %{}
  end

  defp actor(delivery), do: delivery.payload["actor"] || %{}

  defp error_message(delivery) do
    event = error_data(delivery)

    Enum.find(
      [event["message"], get_in(event, ["metadata", "value"])],
      &(is_binary(&1) and String.trim(&1) != "")
    )
  end

  defp exception_values(delivery) do
    delivery
    |> error_data()
    |> get_in(["exception", "values"])
    |> case do
      values when is_list(values) -> values
      _other -> []
    end
  end

  defp tags(delivery) do
    delivery
    |> error_data()
    |> Map.get("tags")
    |> Kernel.||([])
    |> Enum.flat_map(fn
      [key, value] -> [{to_string(key), to_string(value)}]
      %{"key" => key, "value" => value} -> [{to_string(key), to_string(value)}]
      _other -> []
    end)
  end

  defp tag_value(delivery, key) do
    case Enum.find(tags(delivery), fn {tag_key, _value} -> tag_key == key end) do
      {_key, value} -> value
      nil -> nil
    end
  end

  defp event_facts(delivery) do
    event = error_data(delivery)

    [
      {"Environment", event["environment"]},
      {"Level", event["level"]},
      {"Platform", event["platform"]},
      {"Occurred", format_optional_datetime(event["datetime"] || event["timestamp"])},
      {"Project ID", event["project"]},
      {"Server", tag_value(delivery, "server_name")}
    ]
    |> Enum.reject(fn {_label, value} -> value in [nil, ""] end)
  end

  defp format_optional_datetime(nil), do: nil
  defp format_optional_datetime(value), do: format_datetime(value)

  defp geo(delivery), do: get_in(error_data(delivery), ["user", "geo"]) || %{}
  defp trace(delivery), do: get_in(error_data(delivery), ["contexts", "trace"]) || %{}
  defp runtime(delivery), do: get_in(error_data(delivery), ["contexts", "runtime"]) || %{}
  defp operating_system(delivery), do: get_in(error_data(delivery), ["contexts", "os"]) || %{}

  defp sdk_label(delivery) do
    sdk = error_data(delivery)["sdk"] || %{}

    case Enum.join(Enum.reject([sdk["name"], sdk["version"]], &is_nil/1), " · ") do
      "" -> nil
      label -> label
    end
  end

  defp package_count(delivery) do
    case error_data(delivery)["modules"] do
      modules when is_map(modules) -> map_size(modules)
      _other -> 0
    end
  end

  defp sorted_headers(delivery), do: Enum.sort_by(delivery.headers, fn {key, _value} -> key end)

  defp external_url(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme} when scheme in ["http", "https"] -> url
      _other -> nil
    end
  end

  defp external_url(_url), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-5">
      <section class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <.page_header
            icon_path="M8.625 9.75a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375m-13.5 3.01c0 1.6 1.123 2.994 2.707 3.227 1.087.16 2.185.283 3.293.369V21l4.184-4.184a1.14 1.14 0 01.778-.332 48.294 48.294 0 005.83-.498c1.585-.233 2.708-1.626 2.708-3.228V5.507c0-1.621-1.152-3.025-2.757-3.228A48.394 48.394 0 0012 1.875c-2.071 0-4.1.13-6.057.404C4.338 2.482 3.186 3.886 3.186 5.507v7.252z"
            title="Sentry Webhook Inbox"
            subtitle="Review clean, structured details from Sentry error deliveries."
          />

          <button
            type="button"
            phx-click="refresh"
            class="inline-flex h-9 items-center justify-center rounded-md bg-[#373896] px-4 text-sm font-medium text-white hover:bg-[#2d2e7b]"
          >
            Refresh
          </button>
        </div>

        <div class="mt-4 rounded-lg border border-blue-200 bg-blue-50 p-4 text-sm text-blue-900">
          <p class="font-semibold">Webhook destination</p>
          <code class="mt-1 block break-all">POST {url(~p"/api/webhooks/sentry")}</code>
          <p class="mt-2">
            Configure this URL in the Sentry Custom Integration. Incoming JSON deliveries are stored automatically.
          </p>
        </div>
      </section>

      <section class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm">
        <div class="border-b border-gray-100 px-5 py-4">
          <h2 class="font-semibold text-gray-900">Recent deliveries</h2>
          <p class="mt-1 text-sm text-gray-500">
            Showing {length(@deliveries)} deliveries; records are retained for 30 days.
          </p>
        </div>

        <div :if={@deliveries == []} id="sentry-webhooks-empty" class="px-5 py-12 text-center">
          <p class="font-medium text-gray-700">No Sentry webhooks received yet</p>
          <p class="mt-1 text-sm text-gray-500">
            Send a test webhook from Sentry, then refresh this page.
          </p>
        </div>

        <div :if={@deliveries != []} class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-100 text-left text-sm">
            <thead class="bg-gray-50 text-xs uppercase tracking-wide text-gray-500">
              <tr>
                <th class="px-5 py-3 font-medium">Delivery</th>
                <th class="px-5 py-3 font-medium">Resource / action</th>
                <th class="px-5 py-3 font-medium">Received</th>
                <th class="px-5 py-3 font-medium">Source IP</th>
                <th class="px-5 py-3 text-right font-medium">Action</th>
              </tr>
            </thead>
            <tbody id="sentry-webhook-deliveries" class="divide-y divide-gray-100">
              <tr :for={delivery <- @deliveries} id={"delivery-#{delivery.id}"}>
                <td class="max-w-xl px-5 py-4">
                  <p class="font-mono text-xs font-semibold text-[#373896]">
                    {delivery_reference(delivery)}
                  </p>
                  <p class="mt-1 truncate font-medium text-gray-900">{delivery_title(delivery)}</p>
                </td>
                <td class="whitespace-nowrap px-5 py-4 text-gray-600">
                  <span class="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-medium text-indigo-700">
                    {delivery.resource || "unknown"}
                  </span>
                  <span class="ml-1 text-xs">{delivery.action || "—"}</span>
                </td>
                <td class="whitespace-nowrap px-5 py-4 text-gray-600">
                  {format_datetime(delivery.inserted_at)}
                </td>
                <td class="whitespace-nowrap px-5 py-4 font-mono text-xs text-gray-500">
                  {delivery.remote_ip || "—"}
                </td>
                <td class="whitespace-nowrap px-5 py-4 text-right">
                  <button
                    type="button"
                    phx-click="select"
                    phx-value-id={delivery.id}
                    class="text-sm font-medium text-[#373896] hover:underline"
                  >
                    Inspect payload
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <div
        :if={@selected_delivery}
        class="fixed inset-0 z-50 flex items-center justify-center bg-gray-950/60 p-4 backdrop-blur-sm"
        phx-window-keydown="close"
        phx-key="escape"
      >
        <section
          id="sentry-webhook-detail"
          role="dialog"
          aria-modal="true"
          aria-labelledby="sentry-webhook-detail-title"
          phx-click-away="close"
          class="max-h-[90vh] w-full max-w-6xl overflow-y-auto rounded-xl border border-gray-100 bg-white p-5 shadow-2xl"
        >
          <% event = error_data(@selected_delivery) %>
          <% exceptions = exception_values(@selected_delivery) %>
          <% event_tags = tags(@selected_delivery) %>
          <% event_actor = actor(@selected_delivery) %>
          <% event_geo = geo(@selected_delivery) %>
          <% event_trace = trace(@selected_delivery) %>
          <% event_runtime = runtime(@selected_delivery) %>
          <% event_os = operating_system(@selected_delivery) %>

          <div class="flex items-start justify-between gap-4">
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <span class="rounded-full bg-rose-100 px-2.5 py-1 text-xs font-semibold uppercase tracking-wide text-rose-700">
                  {event["level"] || @selected_delivery.resource || "event"}
                </span>
                <span class="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-medium text-indigo-700">
                  {@selected_delivery.action || "received"}
                </span>
                <span class="font-mono text-xs text-gray-400">Delivery #{@selected_delivery.id}</span>
              </div>
              <h2 id="sentry-webhook-detail-title" class="mt-3 text-xl font-semibold text-gray-900">
                {delivery_title(@selected_delivery)}
              </h2>
              <p :if={error_message(@selected_delivery)} class="mt-1 text-sm text-gray-600">
                {error_message(@selected_delivery)}
              </p>
              <p class="mt-2 text-xs text-gray-400">
                Received {format_datetime(@selected_delivery.inserted_at)}
              </p>
            </div>
            <button
              type="button"
              phx-click="close"
              class="rounded-md border border-gray-200 px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-50"
            >
              Close
            </button>
          </div>

          <div class="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
            <div
              :for={{label, value} <- event_facts(@selected_delivery)}
              class="rounded-lg border border-gray-100 bg-gray-50 p-3"
            >
              <p class="text-[11px] font-medium uppercase tracking-wide text-gray-400">{label}</p>
              <p class="mt-1 break-words text-sm font-semibold text-gray-800">{value}</p>
            </div>
          </div>

          <div class="mt-5 grid gap-4 lg:grid-cols-3">
            <section class="rounded-xl border border-rose-100 bg-rose-50/60 p-4 lg:col-span-2">
              <div class="flex items-center justify-between gap-3">
                <h3 class="text-sm font-semibold text-gray-900">Exception details</h3>
                <span class="text-xs text-gray-400">{length(exceptions)} exception(s)</span>
              </div>

              <div :if={exceptions == []} class="mt-3 text-sm text-gray-500">
                No exception object was included in this delivery.
              </div>

              <div
                :for={exception <- exceptions}
                class="mt-3 rounded-lg border border-rose-100 bg-white p-4"
              >
                <div class="flex flex-wrap items-center gap-2">
                  <span class="font-mono text-sm font-semibold text-rose-700">
                    {exception["type"] || "Exception"}
                  </span>
                  <span
                    :if={get_in(exception, ["mechanism", "handled"]) == true}
                    class="rounded-full bg-emerald-50 px-2 py-0.5 text-xs text-emerald-700"
                  >
                    Handled
                  </span>
                </div>
                <p class="mt-2 text-sm text-gray-700">{exception["value"] || "No message"}</p>
                <p :if={get_in(exception, ["mechanism", "type"])} class="mt-2 text-xs text-gray-400">
                  Mechanism: {get_in(exception, ["mechanism", "type"])}
                </p>
              </div>
            </section>

            <section class="rounded-xl border border-gray-100 p-4">
              <h3 class="text-sm font-semibold text-gray-900">Event references</h3>
              <dl class="mt-3 space-y-3 text-sm">
                <div>
                  <dt class="text-xs text-gray-400">Event ID</dt>
                  <dd class="mt-1 break-all font-mono text-xs text-gray-700">
                    {event["event_id"] || "—"}
                  </dd>
                </div>
                <div>
                  <dt class="text-xs text-gray-400">Issue ID</dt>
                  <dd class="mt-1 break-all font-mono text-xs text-gray-700">
                    {event["issue_id"] || "—"}
                  </dd>
                </div>
                <div>
                  <dt class="text-xs text-gray-400">SDK</dt>
                  <dd class="mt-1 text-gray-700">{sdk_label(@selected_delivery) || "—"}</dd>
                </div>
                <div>
                  <dt class="text-xs text-gray-400">Captured packages</dt>
                  <dd class="mt-1 text-gray-700">{package_count(@selected_delivery)}</dd>
                </div>
              </dl>

              <div class="mt-4 flex flex-wrap gap-2">
                <%= if url = external_url(event["web_url"]) do %>
                  <a
                    href={url}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="rounded-md bg-[#373896] px-3 py-2 text-xs font-medium text-white hover:bg-[#2d2e7b]"
                  >
                    Open in Sentry
                  </a>
                <% end %>
                <%= if url = external_url(event["url"]) do %>
                  <a
                    href={url}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="rounded-md border border-gray-200 px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50"
                  >
                    API event
                  </a>
                <% end %>
              </div>
            </section>
          </div>

          <section :if={event_tags != []} class="mt-4 rounded-xl border border-gray-100 p-4">
            <h3 class="text-sm font-semibold text-gray-900">Tags</h3>
            <div class="mt-3 flex flex-wrap gap-2">
              <span
                :for={{key, value} <- event_tags}
                class="rounded-md border border-gray-200 bg-gray-50 px-2.5 py-1.5 text-xs text-gray-600"
              >
                <span class="font-medium text-gray-800">{key}</span>: {value}
              </span>
            </div>
          </section>

          <div class="mt-4 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <section class="rounded-xl border border-gray-100 p-4">
              <h3 class="text-sm font-semibold text-gray-900">Actor</h3>
              <p class="mt-3 text-sm font-medium text-gray-700">{event_actor["name"] || "Sentry"}</p>
              <p class="mt-1 text-xs text-gray-400">{event_actor["type"] || "application"}</p>
            </section>
            <section class="rounded-xl border border-gray-100 p-4">
              <h3 class="text-sm font-semibold text-gray-900">Location</h3>
              <p class="mt-3 text-sm font-medium text-gray-700">
                {Enum.join(Enum.reject([event_geo["city"], event_geo["region"]], &is_nil/1), ", ")
                |> case do
                  "" -> "Not provided"
                  location -> location
                end}
              </p>
              <p class="mt-1 text-xs text-gray-400">{event_geo["country_code"] || "—"}</p>
            </section>
            <section class="rounded-xl border border-gray-100 p-4">
              <h3 class="text-sm font-semibold text-gray-900">Runtime</h3>
              <p class="mt-3 text-sm font-medium text-gray-700">{event_runtime["name"] || "—"}</p>
              <p class="mt-1 break-words text-xs text-gray-400">{event_runtime["version"] || "—"}</p>
            </section>
            <section class="rounded-xl border border-gray-100 p-4">
              <h3 class="text-sm font-semibold text-gray-900">Operating system</h3>
              <p class="mt-3 text-sm font-medium text-gray-700">{event_os["name"] || "—"}</p>
              <p class="mt-1 text-xs text-gray-400">{event_os["version"] || "—"}</p>
            </section>
          </div>

          <section :if={map_size(event_trace) > 0} class="mt-4 rounded-xl border border-gray-100 p-4">
            <h3 class="text-sm font-semibold text-gray-900">Trace</h3>
            <div class="mt-3 grid gap-3 sm:grid-cols-3">
              <div>
                <p class="text-xs text-gray-400">Trace ID</p>
                <p class="mt-1 break-all font-mono text-xs text-gray-700">
                  {event_trace["trace_id"] || "—"}
                </p>
              </div>
              <div>
                <p class="text-xs text-gray-400">Span ID</p>
                <p class="mt-1 break-all font-mono text-xs text-gray-700">
                  {event_trace["span_id"] || "—"}
                </p>
              </div>
              <div>
                <p class="text-xs text-gray-400">Status</p>
                <p class="mt-1 text-sm text-gray-700">{event_trace["status"] || "—"}</p>
              </div>
            </div>
          </section>

          <details class="mt-4 rounded-xl border border-gray-100 bg-gray-50">
            <summary class="cursor-pointer px-4 py-3 text-sm font-semibold text-gray-700">
              Delivery and request details
            </summary>
            <div class="border-t border-gray-100 bg-white px-4 py-3">
              <dl class="grid gap-x-6 gap-y-3 text-sm sm:grid-cols-2">
                <div>
                  <dt class="text-xs text-gray-400">Resource</dt>
                  <dd class="mt-1 text-gray-700">{@selected_delivery.resource || "—"}</dd>
                </div>
                <div>
                  <dt class="text-xs text-gray-400">Source IP</dt>
                  <dd class="mt-1 font-mono text-xs text-gray-700">
                    {@selected_delivery.remote_ip || "—"}
                  </dd>
                </div>
                <div :for={{key, value} <- sorted_headers(@selected_delivery)}>
                  <dt class="break-all text-xs text-gray-400">{key}</dt>
                  <dd class="mt-1 break-all font-mono text-xs text-gray-700">{value}</dd>
                </div>
              </dl>
            </div>
          </details>
        </section>
      </div>
    </div>
    """
  end
end
