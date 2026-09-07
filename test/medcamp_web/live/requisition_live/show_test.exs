defmodule MedcampWeb.RequisitionLive.ShowTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.Departments
  alias Medcamp.Requisitions

  setup do
    admin = user_fixture(%{role: "admin"})
    requester = user_fixture(%{role: "reception"})

    {:ok, department} =
      Departments.create_department(%{name: "Pharmacy #{System.unique_integer()}"})

    {:ok, requisition} =
      Requisitions.create_requisition(%{
        "title" => "Amoxicillin restock",
        "description" => "Need additional stock for the ward.",
        "requested_by_id" => requester.id,
        "to_department_id" => department.id
      })

    %{admin: admin, requisition: requisition}
  end

  test "clicking Reject opens a modal instead of immediately rejecting", %{
    conn: conn,
    admin: admin,
    requisition: requisition
  } do
    conn = log_in_user(conn, admin)

    {:ok, view, _html} = live(conn, ~p"/admin/requisitions/#{requisition.id}")

    refute has_element?(view, "#reject-modal")

    view
    |> element("button", "Reject")
    |> render_click()

    assert has_element?(view, "#reject-modal")
    assert Requisitions.get_requisition!(requisition.id).status == "pending"
  end

  test "clicking Cancel closes the reject modal without rejecting the requisition", %{
    conn: conn,
    admin: admin,
    requisition: requisition
  } do
    conn = log_in_user(conn, admin)

    {:ok, view, _html} = live(conn, ~p"/admin/requisitions/#{requisition.id}")

    view |> element("button", "Reject") |> render_click()
    assert has_element?(view, "#reject-modal")

    view |> element("#reject-modal button", "Cancel") |> render_click()

    refute has_element?(view, "#reject-modal")
    assert Requisitions.get_requisition!(requisition.id).status == "pending"

    # Reopening after a cancel starts from a clean state (no leftover error).
    view |> element("button", "Reject") |> render_click()
    refute has_element?(view, "#reject-modal p.text-red-600")
  end

  test "submitting the reject modal without a reason is blocked and shows an error", %{
    conn: conn,
    admin: admin,
    requisition: requisition
  } do
    conn = log_in_user(conn, admin)

    {:ok, view, _html} = live(conn, ~p"/admin/requisitions/#{requisition.id}")

    view |> element("button", "Reject") |> render_click()

    html =
      view
      |> element("#reject-modal form")
      |> render_submit(%{"_id" => requisition.id, "rejection_reason" => ""})

    assert html =~ "is required when rejecting a requisition"
    assert has_element?(view, "#reject-modal")
    assert Requisitions.get_requisition!(requisition.id).status == "pending"
  end

  test "submitting the reject modal with a reason rejects the requisition, closes the modal, and shows the reason",
       %{conn: conn, admin: admin, requisition: requisition} do
    conn = log_in_user(conn, admin)

    {:ok, view, _html} = live(conn, ~p"/admin/requisitions/#{requisition.id}")

    view |> element("button", "Reject") |> render_click()

    html =
      view
      |> element("#reject-modal form")
      |> render_submit(%{
        "_id" => requisition.id,
        "rejection_reason" => "Insufficient stock available"
      })

    assert html =~ "Requisition rejected successfully"
    refute has_element?(view, "#reject-modal")
    assert has_element?(view, "p", "Insufficient stock available")

    updated = Requisitions.get_requisition!(requisition.id)
    assert updated.status == "rejected"
    assert updated.rejection_reason == "Insufficient stock available"
  end
end
