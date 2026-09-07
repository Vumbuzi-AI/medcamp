defmodule MedcampWeb.CoreComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MedcampWeb.CoreComponents

  describe "table/1 row details" do
    test "generates working, unique toggle targets when row_id is omitted" do
      html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: [
            %{name: "Ada", email: "ada@example.com"},
            %{name: "Lin", email: "lin@example.com"}
          ],
          visible_cols: 1,
          col: [
            %{label: "Name", inner_block: fn _, patient -> patient.name end},
            %{label: "Email", inner_block: fn _, patient -> patient.email end}
          ]
        )

      assert html =~ ~s(id="patients-row-0")
      assert html =~ ~s(id="patients-row-0-details")
      assert html =~ ~s(id="patients-row-1")
      assert html =~ ~s(id="patients-row-1-details")
      assert html =~ "#patients-row-0-details"
      assert html =~ ".row-details-chevron-patients-row-0"
      assert html =~ "#patients-row-1-details"
      assert html =~ ".row-details-chevron-patients-row-1"
    end

    test "uses a caller-provided row_id for the toggle target" do
      html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: [%{id: 42, name: "Ada", email: "ada@example.com"}],
          row_id: fn patient -> "patient-#{patient.id}" end,
          visible_cols: 1,
          col: [
            %{label: "Name", inner_block: fn _, patient -> patient.name end},
            %{label: "Email", inner_block: fn _, patient -> patient.email end}
          ]
        )

      assert html =~ ~s(id="patient-42")
      assert html =~ ~s(id="patient-42-details")
      assert html =~ "#patient-42-details"
      assert html =~ ".row-details-chevron-patient-42"
    end

    test "consumes LiveStream rows directly" do
      rows =
        Phoenix.LiveView.LiveStream.new(
          :patients,
          make_ref(),
          [%{id: 42, name: "Ada"}],
          []
        )

      html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: rows,
          col: [%{label: "Name", inner_block: fn _, {_id, patient} -> patient.name end}]
        )

      assert html =~ ~s(id="patients-42")
      assert html =~ "Ada"
    end

    test "consumes LiveStream rows directly when the table has expandable details" do
      rows =
        Phoenix.LiveView.LiveStream.new(
          :patients,
          make_ref(),
          [%{id: 42, name: "Ada", email: "ada@example.com"}],
          []
        )

      html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: rows,
          visible_cols: 1,
          col: [
            %{label: "Name", inner_block: fn _, {_id, patient} -> patient.name end},
            %{label: "Email", inner_block: fn _, {_id, patient} -> patient.email end}
          ]
        )

      assert html =~ ~s(id="patients-42")
      assert html =~ ~s(id="patients-42-details")
      assert html =~ "ada@example.com"
    end

    test "an expandable table renders no rows once a LiveStream has been consumed" do
      # This is why expandable tables must be fed a plain list: a stream's
      # inserts are only populated for the render right after `stream/4`, so
      # the next re-render that isn't a reset drops every row. Pinned here so
      # the reason the app avoids the combination stays documented.
      stream =
        Phoenix.LiveView.LiveStream.new(
          :patients,
          make_ref(),
          [%{id: 42, name: "Ada", email: "ada@example.com"}],
          []
        )

      consumed = %{stream | inserts: []}

      html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: consumed,
          visible_cols: 1,
          col: [
            %{label: "Name", inner_block: fn _, {_id, patient} -> patient.name end},
            %{label: "Email", inner_block: fn _, {_id, patient} -> patient.email end}
          ]
        )

      refute html =~ ~s(id="patients-42")
      # ...whereas a plain list survives any number of re-renders.
      list_html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: [%{id: 42, name: "Ada", email: "ada@example.com"}],
          row_id: &"patients-#{&1.id}",
          visible_cols: 1,
          col: [
            %{label: "Name", inner_block: fn _, patient -> patient.name end},
            %{label: "Email", inner_block: fn _, patient -> patient.email end}
          ]
        )

      assert list_html =~ ~s(id="patients-42")
      assert list_html =~ "ada@example.com"
    end

    test "only sets phx-update=stream when the table has no expand column" do
      rows = Phoenix.LiveView.LiveStream.new(:patients, make_ref(), [%{id: 1, name: "Ada"}], [])

      flat =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: rows,
          col: [%{label: "Name", inner_block: fn _, {_id, patient} -> patient.name end}]
        )

      assert flat =~ ~s(phx-update="stream")

      expandable =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: rows,
          visible_cols: 1,
          col: [
            %{label: "Name", inner_block: fn _, {_id, patient} -> patient.name end},
            %{label: "Email", inner_block: fn _, {_id, _patient} -> "x@example.com" end}
          ]
        )

      refute expandable =~ ~s(phx-update="stream")
    end

    test "an :action slot alone makes a table expandable" do
      html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: [%{id: 7, name: "Ada"}],
          row_id: &"patients-#{&1.id}",
          col: [%{label: "Name", inner_block: fn _, patient -> patient.name end}],
          action: [%{inner_block: fn _, patient -> "Delete #{patient.id}" end}]
        )

      assert html =~ "Details"
      assert html =~ ~s(id="patients-7-details")
      assert html =~ "Delete 7"
    end

    test "always_show pins the flagged columns and pushes the rest into the panel" do
      html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: [%{id: 7, name: "Ada", email: "ada@example.com"}],
          row_id: &"patients-#{&1.id}",
          col: [
            %{label: "Name", always_show: true, inner_block: fn _, p -> p.name end},
            %{label: "Email", inner_block: fn _, p -> p.email end}
          ]
        )

      # Only the flagged column gets a header; the other moves to the <dl> panel.
      assert html =~ ~s(<th)
      assert html =~ "Details"
      assert html =~ ~s(id="patients-7-details")
      assert html =~ "ada@example.com"
    end

    test "renders the empty_state tbody without dropping the headers" do
      html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: [],
          col: [%{label: "Name", inner_block: fn _, p -> p.name end}],
          empty_state: [%{inner_block: fn _, _ -> "No patients yet" end}]
        )

      assert html =~ "No patients yet"
      assert html =~ "Name"
    end

    test "treats an emptied LiveStream as empty for the empty_state" do
      rows = Phoenix.LiveView.LiveStream.new(:patients, make_ref(), [], [])

      html =
        render_component(&CoreComponents.table/1,
          id: "patients",
          rows: rows,
          col: [%{label: "Name", inner_block: fn _, {_id, p} -> p.name end}],
          empty_state: [%{inner_block: fn _, _ -> "No patients yet" end}]
        )

      assert html =~ "No patients yet"
    end
  end

  describe "flash/1" do
    test "renders the warning kind with its own title, icon, and amber styling" do
      html =
        render_component(&CoreComponents.flash/1,
          kind: :warning,
          title: "Notice",
          flash: %{"warning" => "You were signed out after 30 minutes of inactivity."}
        )

      assert html =~ "Notice"
      assert html =~ "You were signed out after 30 minutes of inactivity."
      assert html =~ "bg-amber-50"
      assert html =~ "ring-amber-500"
      assert html =~ "hero-exclamation-triangle-mini"
    end

    test "still renders the info kind as Success! styling" do
      html =
        render_component(&CoreComponents.flash/1,
          kind: :info,
          title: "Success!",
          flash: %{"info" => "Saved successfully"}
        )

      assert html =~ "Success!"
      assert html =~ "Saved successfully"
      assert html =~ "bg-emerald-50"
      assert html =~ "hero-information-circle-mini"
    end

    test "still renders the error kind" do
      html =
        render_component(&CoreComponents.flash/1,
          kind: :error,
          title: "Error!",
          flash: %{"error" => "Something broke"}
        )

      assert html =~ "Error!"
      assert html =~ "Something broke"
      assert html =~ "bg-rose-50"
      assert html =~ "hero-exclamation-circle-mini"
    end

    test "renders nothing when there is no message for that kind" do
      html =
        render_component(&CoreComponents.flash/1, kind: :warning, title: "Notice", flash: %{})

      refute html =~ "Notice"
    end
  end

  describe "flash_group/1" do
    test "renders info, warning, and error messages simultaneously when all three are set" do
      html =
        render_component(&CoreComponents.flash_group/1,
          flash: %{
            "info" => "all good",
            "warning" => "heads up",
            "error" => "it broke"
          }
        )

      assert html =~ "all good"
      assert html =~ "heads up"
      assert html =~ "it broke"
      assert html =~ "Success!"
      assert html =~ "Notice"
      assert html =~ "Error!"
    end
  end
end
