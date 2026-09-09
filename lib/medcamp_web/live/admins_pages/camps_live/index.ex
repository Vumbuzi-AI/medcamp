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
     |> load_camps()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:camp, %Camp{})
    |> assign(:form, to_form(Camps.change_camp(%Camp{}), as: "camp"))
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
  def handle_event("validate", %{"camp" => params}, socket) do
    changeset = Camps.change_camp(socket.assigns.camp, params)
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
    case Camps.create_camp(params) do
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
  defp load_camps(socket) do
    camps = Camps.list_camps()

    socket
    |> assign(:camps, camps)
    |> assign(:camp_options, camps)
    |> assign(:active_camp, Enum.find(camps, & &1.is_active))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.page_header
        title="Camps"
        subtitle="The events your organisation runs. New records are stamped with the active camp."
        icon_path="M3 21h18M5 21V7l7-4 7 4v14M9 21v-6h6v6"
      >
        <:actions>
          <.link patch={~p"/admin/camps/new"}>
            <.button>New camp</.button>
          </.link>
        </:actions>
      </.page_header>

      <div
        :if={is_nil(@active_camp)}
        class="mb-4 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800"
      >
        No camp is active. Work recorded now is not attributed to any camp, and will not appear
        when the reports are filtered to one.
      </div>

      <.table id="camps" rows={@camps} visible_cols={4}>
        <:col :let={camp} label="Camp" always_show>
          <div class="font-medium text-slate-900">{camp.name}</div>
          <div :if={camp.description} class="text-sm text-slate-500">{camp.description}</div>
        </:col>
        <:col :let={camp} label="Location" always_show>{camp.location || "—"}</:col>
        <:col :let={camp} label="Dates" always_show>{Camp.date_range(camp) || "—"}</:col>
        <:col :let={camp} label="Status" always_show>
          <span
            :if={camp.is_active}
            class="rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-medium text-emerald-800"
          >
            Active
          </span>
          <span :if={!camp.is_active} class="text-sm text-slate-500">Inactive</span>
        </:col>
        <:col :let={camp} label="Records">{Camps.record_count(camp)}</:col>

        <:action :let={camp}>
          <.link
            :if={!camp.is_active}
            phx-click="activate"
            phx-value-id={camp.id}
            class="text-brand-primary hover:underline"
          >
            Set active
          </.link>
          <.link
            :if={camp.is_active}
            phx-click="deactivate"
            class="text-amber-700 hover:underline"
            data-confirm="New records will not be attributed to any camp until you activate one. Continue?"
          >
            Deactivate
          </.link>
        </:action>
        <:action :let={camp}>
          <.link patch={~p"/admin/camps/#{camp.id}/edit"} class="text-slate-700 hover:underline">
            Edit
          </.link>
        </:action>
        <:action :let={camp}>
          <.link
            phx-click="delete"
            phx-value-id={camp.id}
            data-confirm="Delete this camp?"
            class="text-red-600 hover:underline"
          >
            Delete
          </.link>
        </:action>

        <:empty_state>
          <tr>
            <td colspan="6" class="px-6 py-10 text-center text-sm text-slate-500">
              No camps yet. Create one to start attributing work to it.
            </td>
          </tr>
        </:empty_state>
      </.table>

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
          <.input field={@form[:start_date]} type="date" label="Start date" />
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
    </div>
    """
  end
end
