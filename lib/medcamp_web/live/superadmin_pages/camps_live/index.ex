defmodule MedcampWeb.SuperadminCampsLive.Index do
  @moduledoc """
  Platform-wide view of every camp across every organisation. Mostly a
  read-only console - editing / activating a camp still happens inside its
  organisation (`/admin/camps`) - but a superadmin can create a camp here for
  any organisation, choosing the organisation from a picker; the create then
  runs inside that organisation's tenant just as the org admin's would.
  """

  use MedcampWeb, :superadmin_live_view

  alias Medcamp.Camps
  alias Medcamp.Camps.Camp
  alias Medcamp.Organisations
  alias Medcamp.Pagination
  alias Medcamp.Tenancy

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :camps)
     |> assign(:page_title, "Camps")
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:org_options, org_options())
     |> assign(:form, to_form(camp_form(%{}), as: "camp"))
     |> assign(:all_rows, Camps.list_all_camps_with_counts())
     |> filter()}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :page_title, page_title(socket.assigns.live_action))}
  end

  defp page_title(:new), do: "New camp"
  defp page_title(_), do: "Camps"

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> assign(:page, 1) |> filter()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, socket |> assign(:search, "") |> assign(:page, 1) |> filter()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, Pagination.normalize_page(page)) |> filter()}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {id, _} = Integer.parse(to_string(id))

    case Enum.find(socket.assigns.all_rows, fn {c, _} -> c.id == id end) do
      {camp, _count} ->
        result = Tenancy.with_org(camp.organisation_id, fn -> Camps.delete_camp(camp) end)

        socket =
          case result do
            {:ok, _} ->
              socket
              |> put_flash(:info, "#{camp.name} deleted.")
              |> assign(:all_rows, Camps.list_all_camps_with_counts())
              |> filter()

            {:error, :camp_has_records} ->
              put_flash(socket, :error, "#{camp.name} has records and can't be deleted.")

            {:error, _} ->
              put_flash(socket, :error, "Could not delete #{camp.name}.")
          end

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"camp" => params}, socket) do
    changeset = %{camp_form(params) | action: :validate}
    {:noreply, assign(socket, :form, to_form(changeset, as: "camp"))}
  end

  def handle_event("save", %{"camp" => params}, socket) do
    with {org_id, _} <- Integer.parse(to_string(params["organisation_id"])),
         camp_attrs = Map.drop(params, ["organisation_id"]),
         {:ok, camp} <-
           Tenancy.with_org(org_id, fn -> Camps.create_camp(camp_attrs, camp_opts()) end) do
      {:noreply,
       socket
       |> put_flash(:info, "#{camp.name} created for #{camp_org_name(org_id)}.")
       |> assign(:all_rows, Camps.list_all_camps_with_counts())
       |> assign(:search, "")
       |> assign(:page, 1)
       |> assign(:form, to_form(camp_form(%{}), as: "camp"))
       |> filter()
       |> push_patch(to: ~p"/superadmin/camps")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        merged =
          changeset
          |> Ecto.Changeset.cast(params, [:organisation_id])
          |> Ecto.Changeset.validate_required([:organisation_id])

        {:noreply, assign(socket, :form, to_form(%{merged | action: :insert}, as: "camp"))}

      _ ->
        {:noreply,
         assign(socket, :form, to_form(%{camp_form(params) | action: :validate}, as: "camp"))}
    end
  end

  # The org is a real cast field here so the picker keeps its value; the full
  # camp changeset only runs once one is chosen (else `put_org_id` would raise).
  defp camp_form(params) do
    base =
      %Camp{}
      |> Ecto.Changeset.cast(params, [:organisation_id])
      |> Ecto.Changeset.validate_required([:organisation_id])

    case Ecto.Changeset.get_field(base, :organisation_id) do
      org_id when is_integer(org_id) ->
        Tenancy.with_org(org_id, fn -> Camps.change_camp(%Camp{}, params, camp_opts()) end)
        |> Ecto.Changeset.cast(params, [:organisation_id])
        |> Ecto.Changeset.validate_required([:organisation_id])

      _ ->
        base
    end
  end

  defp camp_opts, do: [reject_past_start: true]

  defp org_options do
    Organisations.list_organisations()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp camp_org_name(org_id) do
    case Enum.find(org_options(), fn {_name, id} -> id == org_id end) do
      {name, _} -> name
      _ -> "the organisation"
    end
  end

  defp filter(socket) do
    term = socket.assigns.search |> to_string() |> String.trim() |> String.downcase()

    filtered =
      if term == "" do
        socket.assigns.all_rows
      else
        Enum.filter(socket.assigns.all_rows, fn {camp, _count} ->
          String.contains?(String.downcase(camp.name || ""), term) or
            String.contains?(String.downcase(org_name(camp)), term)
        end)
      end

    per_page = socket.assigns.per_page
    total_count = length(filtered)
    total_pages = Pagination.total_pages(total_count, per_page)
    page = Pagination.clamp_page(socket.assigns.page, total_pages)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:rows, Enum.slice(filtered, (page - 1) * per_page, per_page))
  end

  defp org_name(%{organisation: %{name: name}}) when is_binary(name), do: name
  defp org_name(_), do: ""

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-5">
      <.list_page
        icon_path="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"
        title="Camps"
        subtitle={"#{length(@all_rows)} camp#{if length(@all_rows) != 1, do: "s", else: ""} across all organisations"}
      >
        <:actions>
          <.link
            patch={~p"/superadmin/camps/new"}
            class="inline-flex shrink-0 items-center justify-center gap-2 rounded-full bg-[#0C2765] px-5 py-2.5 text-sm font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
          >
            <Heroicons.icon name="plus" type="outline" class="h-4 w-4" /> New camp
          </.link>
        </:actions>

        <:toolbar>
          <form phx-change="search" class="flex-1">
            <.search_input name="search" value={@search} placeholder="Search by camp or organisation" />
          </form>
        </:toolbar>

        <%= if @rows == [] do %>
          <.blank_state
            icon_path="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"
            title="No camps"
            description={
              if @search != "",
                do: "No camps match the search.",
                else: "No organisation has created a camp yet."
            }
          >
            <:actions :if={@search != ""}>
              <button phx-click="clear_filters" class="text-xs text-[#0C2765] hover:underline">
                Clear search
              </button>
            </:actions>
          </.blank_state>
        <% else %>
          <.data_table id="superadmin-camps" rows={@rows} row_id={fn {c, _} -> "camp-#{c.id}" end}>
            <:col :let={{camp, _count}} label="Camp">
              <p class="font-medium text-slate-900">{camp.name}</p>
              <p :if={camp.location} class="text-xs text-slate-500">{camp.location}</p>
            </:col>
            <:col :let={{camp, _count}} label="Organisation">
              <span class="text-slate-700">{org_name(camp)}</span>
            </:col>
            <:col :let={{camp, _count}} label="Status">
              <span
                :if={camp.is_active}
                class="inline-flex items-center gap-1 rounded-full bg-green-50 px-2.5 py-0.5 text-xs font-medium text-green-700 ring-1 ring-green-600/20"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-green-500"></span> Active
              </span>
              <span
                :if={!camp.is_active}
                class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600"
              >
                Inactive
              </span>
            </:col>
            <:col :let={{camp, _count}} label="Dates">
              <span class="text-sm text-slate-600">
                {Medcamp.Camps.Camp.date_range(camp) || "—"}
              </span>
            </:col>
            <:col :let={{_camp, count}} label="Records" align="right">
              <span class="font-semibold text-slate-900">{count}</span>
            </:col>
            <:action :let={{camp, count}}>
              <.link
                navigate={~p"/superadmin/camps/#{camp.id}"}
                class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-[#0C2765] transition-colors duration-150 hover:text-[#52B2D8]"
              >
                View
              </.link>
              <.link
                :if={count == 0}
                phx-click="delete"
                phx-value-id={camp.id}
                data-confirm-title={"Delete “#{camp.name}”?"}
                data-confirm-message="This camp has no records. Deleting it can't be undone."
                class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-rose-600 transition-colors duration-150 hover:text-rose-700"
              >
                Delete
              </.link>
            </:action>

            <:footer>
              <.pagination
                page={@page}
                total_pages={@total_pages}
                total_count={@total_count}
                per_page={@per_page}
              />
            </:footer>
          </.data_table>
        <% end %>
      </.list_page>

      <.modal
        :if={@live_action == :new}
        id="superadmin-camp-modal"
        show
        on_cancel={JS.patch(~p"/superadmin/camps")}
      >
        <.simple_form for={@form} as="camp" phx-change="validate" phx-submit="save">
          <h2 class="text-lg font-semibold text-[#0C2765]">New camp</h2>
          <p class="text-sm text-slate-500">
            Choose the organisation this camp belongs to. It is created inside that
            organisation just as its own admin would - the first camp an organisation
            has becomes its active one.
          </p>

          <.input
            field={@form[:organisation_id]}
            type="select"
            label="Organisation"
            prompt="Select organisation"
            options={@org_options}
            required
          />
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <.input field={@form[:name]} type="text" label="Name" required />
            <.input field={@form[:location]} type="text" label="Location" />
          </div>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <.input field={@form[:start_date]} type="date" label="Start date" />
            <.input field={@form[:end_date]} type="date" label="End date" />
          </div>
          <.input field={@form[:description]} type="textarea" label="Description" />

          <:actions>
            <.link patch={~p"/superadmin/camps"} class="text-sm text-slate-600 hover:underline">
              Cancel
            </.link>
            <.button phx-disable-with="Saving...">Create camp</.button>
          </:actions>
        </.simple_form>
      </.modal>
    </div>
    """
  end
end
