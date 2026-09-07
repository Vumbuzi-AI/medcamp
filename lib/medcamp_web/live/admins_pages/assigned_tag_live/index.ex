defmodule MedcampWeb.AssignedTagLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.AssignedTags
  alias Medcamp.AssignedTags.AssignedTag

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :assigned_tags)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_assigned_tags()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Assigned tag")
    |> assign(:assigned_tag, AssignedTags.get_assigned_tag!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Assigned tag")
    |> assign(:assigned_tag, %AssignedTag{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Assigned tags")
    |> assign(:assigned_tag, nil)
  end

  @impl true
  def handle_info({MedcampWeb.AssignedTagLive.FormComponent, {:saved, assigned_tag}}, socket) do
    {:noreply, assign(socket, :assigned_tags, upsert(socket.assigns.assigned_tags, assigned_tag))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    assigned_tag = AssignedTags.get_assigned_tag!(id)
    {:ok, _} = AssignedTags.delete_assigned_tag(assigned_tag)

    {:noreply, load_assigned_tags(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_assigned_tags()}
  end

  defp load_assigned_tags(socket) do
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = AssignedTags.count_assigned_tags()
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    assigned_tags = AssignedTags.list_assigned_tags_paginated(page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:assigned_tags, assigned_tags)
  end

  # The table is expandable, so it renders eagerly rather than under
  # `phx-update="stream"` and must be fed a plain list. Replace the row in place
  # when it is already listed, otherwise prepend it.
  defp upsert(rows, row) do
    if Enum.any?(rows, &(&1.id == row.id)) do
      Enum.map(rows, &if(&1.id == row.id, do: row, else: &1))
    else
      [row | rows]
    end
  end
end
