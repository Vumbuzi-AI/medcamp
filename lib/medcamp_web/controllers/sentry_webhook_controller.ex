defmodule MedcampWeb.SentryWebhookController do
  use MedcampWeb, :controller

  alias Medcamp.SentryWebhooks

  @redacted_headers ["authorization", "cookie", "set-cookie"]

  def create(conn, payload) when is_map(payload) do
    case SentryWebhooks.create_delivery(delivery_attrs(conn, payload)) do
      {:ok, delivery} ->
        conn
        |> put_status(:accepted)
        |> json(%{ok: true, delivery_id: delivery.id})

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, error: "Webhook delivery could not be stored"})
    end
  end

  defp delivery_attrs(conn, payload) do
    %{
      resource: header(conn, "sentry-hook-resource") || payload["resource"],
      action: payload["action"],
      remote_ip: format_ip(conn.remote_ip),
      headers: inspectable_headers(conn.req_headers),
      payload: payload
    }
  end

  defp header(conn, name) do
    conn
    |> get_req_header(name)
    |> List.first()
  end

  defp inspectable_headers(headers) do
    Map.new(headers, fn {name, value} ->
      if String.downcase(name) in @redacted_headers do
        {name, "[REDACTED]"}
      else
        {name, value}
      end
    end)
  end

  defp format_ip(nil), do: nil
  defp format_ip(ip), do: ip |> :inet.ntoa() |> to_string()
end
