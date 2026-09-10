defmodule MedcampWeb.AdminMedicalCampLive.CampScopeTest do
  @moduledoc """
  The medical camp dashboard scopes to the organisation's active camp via
  `camp_attendances`, not a fixed calendar window.
  """
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.CampAttendances
  alias Medcamp.Camps
  alias Medcamp.Patients
  alias Medcamp.Tenancy

  setup %{conn: conn} do
    admin = user_fixture(%{role: "admin"})
    %{conn: log_in_user(conn, admin), org_id: admin.organisation_id}
  end

  defp in_org(org_id, fun), do: Tenancy.with_org(org_id, fun)

  defp a_patient(org_id, name) do
    in_org(org_id, fn ->
      {:ok, patient} =
        Patients.create_patient(%{
          "first_name" => name,
          "last_name" => "Test",
          "gender" => "Female",
          "date_of_birth" => "1990-01-01",
          "phone_number" => "0712345678",
          "home_address" => "Nairobi",
          "creator_id" => user_fixture(%{role: "receptionist"}).id
        })

      patient
    end)
  end

  test "Camp.days/1 lists every calendar day in the range" do
    camp = %Camps.Camp{start_date: ~D[2026-05-01], end_date: ~D[2026-05-03]}
    assert Camps.Camp.days(camp) == [~D[2026-05-01], ~D[2026-05-02], ~D[2026-05-03]]

    assert Camps.Camp.days(%Camps.Camp{start_date: ~D[2026-05-01], end_date: nil}) ==
             [~D[2026-05-01]]

    assert Camps.Camp.days(%Camps.Camp{start_date: nil, end_date: nil}) == []
  end

  test "the dashboard counts only patients who attended the active camp", %{
    conn: conn,
    org_id: org_id
  } do
    {:ok, camp} = in_org(org_id, fn -> Camps.create_camp(%{name: "May Camp"}) end)

    attended_a = a_patient(org_id, "Amina")
    attended_b = a_patient(org_id, "Brian")
    _not_attended = a_patient(org_id, "Cleo")

    in_org(org_id, fn ->
      CampAttendances.record(attended_a.id, camp.id)
      CampAttendances.record(attended_b.id, camp.id)
    end)

    {:ok, view, html} = live(conn, ~p"/admin/medical_camp")

    # Header patient count is the camp roster, not every org patient.
    assert html =~ "2 patients"

    roster =
      view
      |> element("button[phx-value-tab='patient_data']")
      |> render_click()

    assert roster =~ "Amina"
    assert roster =~ "Brian"
    refute roster =~ "Cleo"
  end

  test "list_patients_for_camp_on/2 narrows to one camp day", %{org_id: org_id} do
    {:ok, camp} = in_org(org_id, fn -> Camps.create_camp(%{name: "Two Day Camp"}) end)
    patient = a_patient(org_id, "Dalia")

    in_org(org_id, fn -> CampAttendances.record(patient.id, camp.id) end)

    today = Date.utc_today()

    assert in_org(org_id, fn -> Patients.list_patients_for_camp_on(camp.id, today) end)
           |> Enum.map(& &1.id) == [patient.id]

    assert in_org(org_id, fn ->
             Patients.list_patients_for_camp_on(camp.id, Date.add(today, -30))
           end) == []
  end

  # A camp whose date range straddles today, so `Camp.days/1` yields > 1 day
  # and the day switcher renders.
  defp multi_day_camp(org_id) do
    today = Date.utc_today()

    in_org(org_id, fn ->
      {:ok, camp} =
        Camps.create_camp(%{
          "name" => "Multi Day Camp",
          "start_date" => Date.add(today, -1),
          "end_date" => Date.add(today, 1)
        })

      camp
    end)
  end

  describe "set_day_tab (C-2 guard)" do
    test "a valid ISO date filters the roster to that camp day", %{conn: conn, org_id: org_id} do
      camp = multi_day_camp(org_id)
      seen_today = a_patient(org_id, "Tabby")
      in_org(org_id, fn -> CampAttendances.record(seen_today.id, camp.id) end)

      {:ok, view, _html} = live(conn, ~p"/admin/medical_camp")

      # The roster only renders on the patient_data dashboard tab.
      view |> element("button[phx-value-tab='patient_data']") |> render_click()

      today_iso = Date.to_iso8601(Date.utc_today())
      tomorrow_iso = Date.to_iso8601(Date.add(Date.utc_today(), 1))

      today_html =
        view
        |> element("button[phx-click='set_day_tab'][phx-value-tab='#{today_iso}']")
        |> render_click()

      assert today_html =~ "Tabby"

      tomorrow_html =
        view
        |> element("button[phx-click='set_day_tab'][phx-value-tab='#{tomorrow_iso}']")
        |> render_click()

      refute tomorrow_html =~ "Tabby"
    end

    test "a foreign / invalid tab value is ignored without crashing", %{
      conn: conn,
      org_id: org_id
    } do
      _camp = multi_day_camp(org_id)
      {:ok, view, _html} = live(conn, ~p"/admin/medical_camp")

      # `Date.from_iso8601/1` fails, or the parsed date is not in `@camp_days`;
      # the handler's `else -> {:noreply, socket}` clause swallows both. If
      # this ever raises, note finding C-2 (unguarded String.to_* on
      # phx-value-* elsewhere in this LiveView).
      assert render_hook(view, "set_day_tab", %{"tab" => "not-a-date"})
      assert render_hook(view, "set_day_tab", %{"tab" => "1999-01-01"})
      assert render(view) =~ "Camp day"
    end
  end

  describe "the camp-day switcher" do
    test "renders only when the camp spans more than one day", %{conn: conn, org_id: org_id} do
      # Single-day camp: start_date only -> Camp.days/1 == [start_date].
      in_org(org_id, fn ->
        {:ok, _} =
          Camps.create_camp(%{"name" => "One Day", "start_date" => Date.utc_today()})
      end)

      {:ok, _view, html} = live(conn, ~p"/admin/medical_camp")
      refute html =~ "Camp day"
    end

    test "renders for a multi-day camp", %{conn: conn, org_id: org_id} do
      _camp = multi_day_camp(org_id)
      {:ok, _view, html} = live(conn, ~p"/admin/medical_camp")
      assert html =~ "Camp day"
    end

    test "renders for a dateless camp once attendance spans more than one day", %{
      conn: conn,
      org_id: org_id
    } do
      {:ok, camp} = in_org(org_id, fn -> Camps.create_camp(%{"name" => "Dateless Camp"}) end)
      assert Camps.Camp.days(camp) == []

      today = a_patient(org_id, "Today Person")
      yesterday = a_patient(org_id, "Yesterday Person")

      in_org(org_id, fn ->
        CampAttendances.record(today.id, camp.id)
        CampAttendances.record(yesterday.id, camp.id)
      end)

      # Backdate one attendance so the camp's activity covers two calendar days
      # even though the camp itself has no start/end date.
      import Ecto.Query

      from(a in Medcamp.Camps.CampAttendance,
        where: a.camp_id == ^camp.id and a.patient_id == ^yesterday.id
      )
      |> Medcamp.Repo.update_all(
        set: [
          first_seen_at: DateTime.utc_now() |> DateTime.add(-86_400) |> DateTime.truncate(:second)
        ]
      )

      {:ok, _view, html} = live(conn, ~p"/admin/medical_camp")
      assert html =~ "Camp day"
    end

    test "the day tabs follow the camp switcher, not the active camp", %{
      conn: conn,
      org_id: org_id
    } do
      # First camp created is auto-activated (its dates drive the strip by default).
      {:ok, _active} =
        in_org(org_id, fn ->
          Camps.create_camp(%{
            "name" => "Active May Camp",
            "start_date" => ~D[2026-05-04],
            "end_date" => ~D[2026-05-06]
          })
        end)

      # A second, non-active camp with a distinct window.
      {:ok, filtered} =
        in_org(org_id, fn ->
          Camps.create_camp(%{
            "name" => "Future Aug Camp",
            "start_date" => ~D[2026-08-10],
            "end_date" => ~D[2026-08-12]
          })
        end)

      # No filter -> the active camp's days.
      {:ok, _view, active_html} = live(conn, ~p"/admin/medical_camp")
      assert active_html =~ "04 May"
      refute active_html =~ "10 Aug"

      # Switcher set (session-backed) -> the *filtered* camp's days.
      filtered_conn =
        Plug.Conn.put_session(conn, MedcampWeb.UserAuth.camp_filter_session_key(), filtered.id)

      {:ok, _view, filtered_html} = live(filtered_conn, ~p"/admin/medical_camp")
      assert filtered_html =~ "10 Aug"
      assert filtered_html =~ "12 Aug"
      refute filtered_html =~ "04 May"
    end
  end

  describe "CSV export links and controller" do
    test "the export link carries ?day=all by default and ?day=<iso> once a day is picked", %{
      conn: conn,
      org_id: org_id
    } do
      camp = multi_day_camp(org_id)
      p = a_patient(org_id, "Export Person")
      in_org(org_id, fn -> CampAttendances.record(p.id, camp.id) end)

      {:ok, view, _html} = live(conn, ~p"/admin/medical_camp")

      # The export links live in the patient_data / downloads sections.
      on_patient_data =
        view |> element("button[phx-value-tab='patient_data']") |> render_click()

      assert on_patient_data =~ "export/patients?day=all"

      today_iso = Date.to_iso8601(Date.utc_today())

      picked =
        view
        |> element("button[phx-click='set_day_tab'][phx-value-tab='#{today_iso}']")
        |> render_click()

      assert picked =~ "export/patients?day=#{today_iso}"
    end

    test "the export controller serves a CSV for ?day=all and for ?day=<iso>", %{
      conn: conn,
      org_id: org_id
    } do
      camp = multi_day_camp(org_id)
      p = a_patient(org_id, "Csv Person")
      in_org(org_id, fn -> CampAttendances.record(p.id, camp.id) end)

      today_iso = Date.to_iso8601(Date.utc_today())

      for day <- ["all", today_iso] do
        resp = get(conn, "/admin/medical_camp/export/patients?day=#{day}")
        assert resp.status == 200
        assert get_resp_header(resp, "content-type") |> Enum.any?(&(&1 =~ "csv"))
      end
    end
  end

  describe "no active camp" do
    test "the dashboard renders its 'No active camp' fallback", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/medical_camp")

      assert html =~ "No active camp"
      assert html =~ "Activate a camp to see its dashboard"
    end
  end
end
