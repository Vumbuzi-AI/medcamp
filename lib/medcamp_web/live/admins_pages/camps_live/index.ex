defmodule MedcampWeb.AdminCampsLive.Index do
  @moduledoc """
  Where an admin sets up the camps their organisation runs and picks which
  one is active.

  The active camp is organisation state, not a per-user preference: changing
  it here changes what every nurse, doctor, lab tech and pharmacist's work is
  recorded against from that moment. The camp *filter* in the header is the
  separate, per-viewer thing - see `MedcampWeb.CampComponents.camp_switcher/1`.
  """

  use MedcampWeb, :admin_live_view

  alias Medcamp.Camps
  alias Medcamp.Camps.Camp

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :camps)
     |> assign(:page_title, "Camps")
     |> assign(:search, "")
     |> load_camps()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:camp, %Camp{})
    |> assign(:form, to_form(Camps.change_camp(%Camp{}, %{}, camp_form_opts(:new)), as: "camp"))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    camp = Camps.get_camp!(id)

    socket
    |> assign(:camp, camp)
    |> assign(:form, to_form(Camps.change_camp(camp), as: "camp"))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:camp, nil)
    |> assign(:form, nil)
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> load_camps()}
  end

  def handle_event("validate", %{"camp" => params}, socket) do
    changeset =
      Camps.change_camp(socket.assigns.camp, params, camp_form_opts(socket.assigns.live_action))

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate, as: "camp"))}
  end

  def handle_event("save", %{"camp" => params}, socket) do
    save_camp(socket, socket.assigns.live_action, params)
  end

  def handle_event("activate", %{"id" => id}, socket) do
    camp = Camps.get_camp!(id)
    {:ok, camp} = Camps.set_active_camp(camp)

    {:noreply,
     socket
     |> load_camps()
     |> put_flash(:info, "#{camp.name} is now the active camp.")}
  end

  def handle_event("deactivate", _params, socket) do
    :ok = Camps.clear_active_camp()

    {:noreply,
     socket
     |> load_camps()
     |> put_flash(
       :info,
       "No camp is active. New records will not be attributed to a camp until you activate one."
     )}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    case id |> Camps.get_camp!() |> Camps.delete_camp() do
      {:ok, _camp} ->
        {:noreply, socket |> load_camps() |> put_flash(:info, "Camp deleted.")}

      {:error, :camp_has_records} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "This camp already has records against it and cannot be deleted."
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not delete this camp.")}
    end
  end

  defp save_camp(socket, :new, params) do
    case Camps.create_camp(params, camp_form_opts(:new)) do
      {:ok, camp} ->
        {:noreply,
         socket
         |> load_camps()
         |> put_flash(:info, "#{camp.name} created.")
         |> push_patch(to: ~p"/admin/camps")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "camp"))}
    end
  end

  defp save_camp(socket, :edit, params) do
    case Camps.update_camp(socket.assigns.camp, params) do
      {:ok, camp} ->
        {:noreply,
         socket
         |> load_camps()
         |> put_flash(:info, "#{camp.name} updated.")
         |> push_patch(to: ~p"/admin/camps")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "camp"))}
    end
  end

  # Reloaded rather than patched in place because activating one camp changes
  # the row of whichever camp was active before it, not just the one clicked.
  # A camp created here must not start in the past; an existing camp can (it
  # started before today by now), and the DB / seeds stay permissive.
  defp camp_form_opts(:new), do: [reject_past_start: true]
  defp camp_form_opts(_), do: []

  defp today_iso, do: Date.utc_today() |> Date.to_iso8601()

  defp load_camps(socket) do
    all_camps = Camps.list_camps()
    term = socket.assigns[:search] |> to_string() |> String.trim() |> String.downcase()

    camps =
      if term == "" do
        all_camps
      else
        Enum.filter(all_camps, fn c ->
          String.contains?(String.downcase(c.name || ""), term) or
            String.contains?(String.downcase(c.location || ""), term)
        end)
      end

    socket
    |> assign(:camps, camps)
    |> assign(:camp_options, all_camps)
    |> assign(:active_camp, Enum.find(all_camps, & &1.is_active))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.list_page
      title="Camps"
      subtitle="The events your organisation runs. New records are stamped with the active camp."
      icon_path="M3 21h18M5 21V7l7-4 7 4v14M9 21v-6h6v6"
    >
      <:actions>
        <.link patch={~p"/admin/camps/new"}>
          <button class="inline-flex items-center gap-2 rounded-lg bg-brand-primary px-4 py-2 text-sm font-medium text-white hover:bg-[#2d2d7a]">
            <Heroicons.icon name="plus" type="outline" class="h-4 w-4" /> New camp
          </button>
        </.link>
      </:actions>

      <:toolbar>
        <form phx-change="search" class="flex-1">
          <.search_input name="search" value={@search} placeholder="Search by name or location" />
        </form>
      </:toolbar>

      <div
        :if={is_nil(@active_camp)}
        class="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800"
      >
        No camp is active. Work recorded now is not attributed to any camp, and will not appear
        when the reports are filtered to one.
      </div>

      <.blank_state
        :if={@camps == []}
        icon_path="M3 21h18M5 21V7l7-4 7 4v14M9 21v-6h6v6"
        title={if @search == "", do: "No camps yet", else: "No camps match your search"}
        description={
          if @search == "",
            do: "Create one to start attributing work to it.",
            else: "Try a different name or location."
        }
      />

      <.data_table :if={@camps != []} id="camps" rows={@camps} row_id={&"camp-#{&1.id}"}>
        <:col :let={camp} label="Camp">
          <div class="font-medium text-slate-900">{camp.name}</div>
          <div :if={camp.description} class="text-sm text-slate-500">{camp.description}</div>
        </:col>
        <:col :let={camp} label="Location">{camp.location || "—"}</:col>
        <:col :let={camp} label="Dates">{Camp.date_range(camp) || "—"}</:col>
        <:col :let={camp} label="Status">
          <span
            :if={camp.is_active}
            class="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-medium text-emerald-700 ring-1 ring-emerald-600/20"
          >
            <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span> Active
          </span>
          <span
            :if={!camp.is_active}
            class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600"
          >
            Inactive
          </span>
        </:col>
        <:col :let={camp} label="Records" align="right">{Camps.record_count(camp)}</:col>

        <:action :let={camp}>
          <.link
            :if={!camp.is_active}
            phx-click="activate"
            phx-value-id={camp.id}
            class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-brand-accent hover:bg-brand-50"
          >
            Set active
          </.link>
          <.link
            :if={camp.is_active}
            phx-click="deactivate"
            data-confirm-message="New records will not be attributed to any camp until you activate one. Continue?"
            class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-amber-700 hover:bg-amber-50"
          >
            Deactivate
          </.link>
          <.link
            patch={~p"/admin/camps/#{camp.id}/edit"}
            class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-100"
          >
            Edit
          </.link>
          <.link
            phx-click="delete"
            phx-value-id={camp.id}
            data-confirm-message="Delete this camp?"
            class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-red-600 hover:bg-red-50"
          >
            Delete
          </.link>
        </:action>
      </.data_table>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="camp-modal"
        show
        on_cancel={JS.patch(~p"/admin/camps")}
      >
        <.simple_form for={@form} as="camp" phx-change="validate" phx-submit="save">
          <h2 class="text-lg font-semibold text-gray-900">
            {if @live_action == :new, do: "New camp", else: "Edit camp"}
          </h2>

          <.input field={@form[:name]} type="text" label="Name" required />
          <.input field={@form[:location]} type="text" label="Location" />
          <.input
            field={@form[:start_date]}
            type="date"
            label="Start date"
            min={if @live_action == :new, do: today_iso()}
          />
          <.input field={@form[:end_date]} type="date" label="End date" />
          <.input field={@form[:description]} type="textarea" label="Description" />

          <:actions>
            <.link patch={~p"/admin/camps"} class="text-sm text-slate-600 hover:underline">
              Cancel
            </.link>
            <.button phx-disable-with="Saving...">Save camp</.button>
          </:actions>
        </.simple_form>
      </.modal>
    </.list_page>
    """
  end
end
