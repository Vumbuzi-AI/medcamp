defmodule Medcamp.Procurement.NotificationsTest do
  use Medcamp.DataCase, async: true

  alias Medcamp.Accounts.User
  alias Medcamp.Procurement.Notifications

  defmodule FakeMailer do
    def deliver(recipient, subject, body) do
      send(self(), {:delivered_email, recipient, subject, body})
      {:ok, :sent}
    end
  end

  test "notify persists the notification and sends an email to the user" do
    email = "user#{System.unique_integer([:positive])}@example.com"

    user =
      %User{}
      |> User.registration_changeset(%{
        name: "Procurement Reviewer",
        email: email,
        role: "procurement_officer",
        password: "hello world!",
        otp: "1234"
      })
      |> Repo.insert!()

    attrs = %{
      title: "New request for quotation: RFQ-2026-00001",
      body: "A new RFQ is ready for review.",
      resource_type: "rfq",
      resource_id: 42
    }

    assert {:ok, notif} = Notifications.notify(user.id, "rfq_issued", attrs, FakeMailer)
    assert notif.type == "rfq_issued"

    assert_receive {:delivered_email, ^email, subject, body}
    assert subject == attrs.title
    assert body =~ attrs.title
    assert body =~ attrs.body
    assert body =~ "Reference: rfq #42"
    assert body =~ "Open Medcamp to review the full details."
  end
end
