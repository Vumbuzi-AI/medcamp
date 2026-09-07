defmodule MedcampWeb.SentryWebhooksLiveTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Medcamp.AccountsFixtures
  alias Medcamp.Repo
  alias Medcamp.SentryWebhooks.Delivery
  alias MedcampWeb.ConnCase

  test "an admin can inspect a stored webhook payload", %{conn: conn} do
    delivery =
      Repo.insert!(%Delivery{
        resource: "error",
        action: "created",
        headers: %{"sentry-hook-resource" => "error"},
        payload: %{
          "action" => "created",
          "actor" => %{"name" => "Sentry", "type" => "application"},
          "data" => %{
            "error" => %{
              "event_id" => "event-123",
              "issue_id" => "issue-456",
              "title" => "RuntimeError: boom",
              "level" => "error",
              "environment" => "dev",
              "platform" => "elixir",
              "metadata" => %{"value" => "boom"},
              "sdk" => %{"name" => "sentry-elixir", "version" => "10.2.1"},
              "exception" => %{
                "values" => [
                  %{
                    "type" => "RuntimeError",
                    "value" => "boom",
                    "mechanism" => %{"handled" => true, "type" => "generic"}
                  }
                ]
              },
              "tags" => [["environment", "dev"], ["level", "error"]]
            }
          }
        }
      })

    admin = AccountsFixtures.user_fixture(%{"role" => "admin"})
    conn = ConnCase.log_in_user(conn, admin)

    {:ok, view, html} = live(conn, ~p"/admin/sentry-webhooks")
    assert html =~ "Sentry Webhook Inbox"
    assert html =~ "event-123"

    detail_html =
      view
      |> element("#delivery-#{delivery.id} button", "Inspect payload")
      |> render_click()

    assert detail_html =~ "RuntimeError: boom"
    assert detail_html =~ "Exception details"
    assert detail_html =~ "Event references"
    assert detail_html =~ "sentry-elixir"
    refute detail_html =~ "JSON payload"

    assert has_element?(view, "#sentry-webhook-detail[role=dialog]")

    view
    |> element("#sentry-webhook-detail button", "Close")
    |> render_click()

    refute has_element?(view, "#sentry-webhook-detail")
  end

  test "the webhook inbox requires an authenticated admin", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/users/log_in"}}} =
             live(conn, ~p"/admin/sentry-webhooks")
  end
end
