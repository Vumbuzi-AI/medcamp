defmodule MedcampWeb.SentryWebhookControllerTest do
  use MedcampWeb.ConnCase, async: true

  alias Medcamp.Repo
  alias Medcamp.SentryWebhooks.Delivery

  test "stores a Sentry webhook without authentication", %{conn: conn} do
    payload = %{
      "action" => "created",
      "data" => %{
        "error" => %{
          "event_id" => "cc332c52754c46f68f63848c896d874b",
          "issue_id" => "7626195537",
          "title" => "RuntimeError: boom"
        }
      }
    }

    conn =
      conn
      |> put_req_header("sentry-hook-resource", "error")
      |> post(~p"/api/webhooks/sentry", payload)

    assert %{"ok" => true, "delivery_id" => delivery_id} = json_response(conn, 202)

    delivery = Repo.get!(Delivery, delivery_id)
    assert delivery.resource == "error"
    assert delivery.action == "created"
    assert delivery.payload == payload
  end
end
