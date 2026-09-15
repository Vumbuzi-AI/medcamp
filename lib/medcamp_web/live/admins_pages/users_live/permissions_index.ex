defmodule MedcampWeb.AdminUsersLive.PermissionsIndex do
  @moduledoc """
  Per-user panel permissions - the sidebar of the user's role, laid out
  as the same groups they see, with a checkbox per panel.

  Ticking a box controls both halves at once: the panel appears in their
  sidebar *and* its routes open up. Unticking hides the link and closes
  the URL (`MedcampWeb.Plugs.RequirePanelPermission`), so the two can never
  disagree.

  Boxes are pre-checked to reflect current effective access (the role
  default with any override applied). Toggling a box back to match the
  role default removes the override rather than leaving a redundant one.
  """

  use MedcampWeb, :admin_live_view

  alias Medcamp.Accounts
  alias Medcamp.Authorization
  alias MedcampWeb.SidebarCatalog

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = Accounts.get_user!(id)

    {:ok,
     socket
     |> assign(:active_tab, :users)
     |> assign(:page_title, "Permissions - #{user.name}")
     |> assign(:user, user)
     |> load_groups()}
  end

  # One entry per sidebar group of the user's role, each tab annotated
  # with whether the user currently has it and where that came from.
  defp load_groups(socket) do
    user = socket.assigns.user
    allowed = Authorization.effective_permissions(user)

    overrides_by_slug =
      user
      |> Authorization.list_user_overrides()
      |> Map.new(&{&1.permission.slug, &1})

    role_defaults = MapSet.new(Authorization.list_role_permissions(user.role))

    groups =
      user.role
      |> SidebarCatalog.tab_groups()
      |> Enum.map(fn group ->
        tabs =
          Enum.map(group.tabs, fn tab ->
            slug = SidebarCatalog.permission_slug(user.role, tab.tab_name)

            %{
              name: tab.name,
              icon: tab.icon,
              url: tab.url,
              slug: slug,
              granted: MapSet.member?(allowed, slug),
              role_default: MapSet.member?(role_defaults, slug),
              override: overrides_by_slug[slug]
            }
          end)

        %{key: group.key, name: group.name, icon: group.icon, tabs: tabs}
      end)

    groups =
      groups ++
        shared_panel_groups(user, allowed, role_defaults, overrides_by_slug) ++
        patient_record_group(user, allowed, role_defaults, overrides_by_slug)

    socket
    |> assign(:groups, groups)
    |> assign(:granted_count, Enum.count(Enum.flat_map(groups, & &1.tabs), & &1.granted))
    |> assign(:total_count, Enum.count(Enum.flat_map(groups, & &1.tabs)))
  end

  # Sidebars this role is given on top of its own - reception and admin
  # both get the inventory manager's - listed under their owning role's
  # slugs, which is what the shared sidebar renders and the router checks.
  defp shared_panel_groups(user, allowed, role_defaults, overrides_by_slug) do
    user.role
    |> SidebarCatalog.shared_tabs()
    |> Enum.chunk_by(& &1.group_name)
    |> Enum.map(fn tabs ->
      first = hd(tabs)

      %{
        key: "#{first.role}-#{first.group_key}",
        name: first.group_name,
        icon: first.icon,
        tabs:
          Enum.map(tabs, fn tab ->
            %{
              name: tab.name,
              icon: tab.icon,
              url: tab.url,
              slug: tab.slug,
              granted: MapSet.member?(allowed, tab.slug),
              role_default: MapSet.member?(role_defaults, tab.slug),
              override: overrides_by_slug[tab.slug]
            }
          end)
      }
    end)
  end

  # The per-patient sidebar - the sections a user sees once they open a
  # patient - is a flat list rather than grouped, so it gets one group of
  # its own at the end.
  defp patient_record_group(user, allowed, role_defaults, overrides_by_slug) do
    case SidebarCatalog.all_patient_tabs(user.role) do
      [] ->
        []

      tabs ->
        [
          %{
            key: "patient-record",
            name: "Patient Record",
            icon: "user",
            tabs:
              Enum.map(tabs, fn tab ->
                %{
                  name: tab.name,
                  icon: tab.icon,
                  url: patient_tab_url(tab.url),
                  slug: tab.slug,
                  granted: MapSet.member?(allowed, tab.slug),
                  role_default: MapSet.member?(role_defaults, tab.slug),
                  override: overrides_by_slug[tab.slug]
                }
              end)
          }
        ]
    end
  end

  @impl true
  def handle_event("toggle_permission", %{"slug" => slug, "granted" => granted}, socket) do
    desired_granted? = granted == "true"

    case Authorization.toggle_user_permission(
           socket.assigns.user,
           slug,
           desired_granted?,
           socket.assigns.current_user
         ) do
      {:ok, _} ->
        {:noreply, socket |> load_groups() |> put_flash(:info, "Access updated.")}

      {:error, :permission_not_found} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "#{slug} has no permission row yet - it needs a PanelSync migration."
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update #{slug}.")}
    end
  end

  # all_patient_tabs/1 builds URLs against a placeholder patient id of 0;
  # show the shape of the route instead of a patient who does not exist.
  defp patient_tab_url(url), do: String.replace(url, "/0", "/:patient_id")

  defp source_label(%{override: nil, role_default: true}), do: "role default"
  defp source_label(%{override: nil, role_default: false}), do: "not granted to role"

  defp source_label(%{override: override}) do
    who = (override.granted_by && override.granted_by.name) || "an admin"
    verb = if override.effect == "grant", do: "granted", else: "denied"
    "#{verb} by #{who}, #{format_datetime_kenya(override.granted_at)}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 px-6 py-5">
        <.page_header
          icon_path="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
          title={"Panels - #{@user.name}"}
          subtitle={"Role: #{@user.role} — #{@granted_count} of #{@total_count} panels enabled"}
        >
          <:actions>
            <.link
              navigate={~p"/admin/users"}
              class="inline-flex items-center gap-2 rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              Back to Users
            </.link>
          </:actions>
        </.page_header>

        <p class="text-sm text-slate-500 mb-6">
          These are the panels in the {@user.role} sidebar. Unticking one hides it from this
          user's sidebar and blocks its pages if they type the URL directly. Toggling a box back
          to what the role would already give removes the override, so this user goes back to
          inheriting from their role.
        </p>

        <div
          :if={@groups == []}
          class="rounded-lg border border-dashed border-slate-200 px-4 py-8 text-center"
        >
          <p class="text-sm text-slate-500">
            The {@user.role} role has no permission-controlled sidebar panels.
          </p>
        </div>

        <div class="space-y-6">
          <section :for={group <- @groups}>
            <div class="flex items-center gap-2 mb-2">
              <h3 class="text-sm font-semibold text-slate-900">{group.name}</h3>
              <span class="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-bold text-slate-500">
                {Enum.count(group.tabs, & &1.granted)}/{length(group.tabs)}
              </span>
            </div>

            <div class="divide-y divide-slate-100 border border-slate-100 rounded-lg overflow-hidden">
              <div :for={tab <- group.tabs} class="flex items-center gap-4 px-4 py-3 bg-white">
                <input
                  type="checkbox"
                  id={"permission-#{tab.slug}"}
                  checked={tab.granted}
                  phx-click="toggle_permission"
                  phx-value-slug={tab.slug}
                  phx-value-granted={to_string(!tab.granted)}
                  class="h-4 w-4 rounded border-slate-300 text-brand-primary focus:ring-brand-accent"
                />
                <label for={"permission-#{tab.slug}"} class="flex-1 min-w-0 cursor-pointer">
                  <p class="text-sm font-medium text-slate-900">{tab.name}</p>
                  <p class="text-xs text-slate-400">{tab.url}</p>
                </label>
                <div class="text-right shrink-0">
                  <span
                    :if={tab.override}
                    class="inline-flex items-center rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-medium text-amber-700 ring-1 ring-amber-600/20"
                  >
                    Overridden
                  </span>
                  <p class="text-xs text-slate-500 mt-1">{source_label(tab)}</p>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end
end
