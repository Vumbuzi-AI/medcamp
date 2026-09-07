defmodule MedcampWeb.StaffMealLive.Shared do
  @moduledoc """
  Shared LiveView behaviour for the staff meals page.

  Reception and support staff both manage the same per-date record of meals
  supplied by the food vendor; only the surrounding panel (sidebar/layout)
  differs. Each role's module pulls in its own layout via `use MedcampWeb,
  :<role>_live_view` and then `use MedcampWeb.StaffMealLive.Shared` to inherit the
  identical mount/event logic. The markup lives in
  `MedcampWeb.StaffMealComponents` so it can be reused without `~H` hygiene issues.
  """

  defmacro __using__(_opts) do
    quote do
      alias Medcamp.StaffMeals
      alias Medcamp.StaffMeals.StaffMealSupply

      @per_page 10

      @impl true
      def mount(_params, _session, socket) do
        {:ok,
         socket
         |> assign(:active_tab, :staff_meals)
         |> assign(:page_title, "Staff Meals")
         |> assign(:filter_date_from, "")
         |> assign(:filter_date_to, "")
         |> assign(:filter_meal_type, "")
         |> assign(:filter_search, "")
         |> assign(:today, Date.utc_today())
         |> assign(:page, 1)
         |> assign(:per_page, @per_page)
         |> assign(:editing_id, nil)
         |> assign(:show_form, false)
         |> assign_new_form()
         |> load_supplies()}
      end

      @impl true
      def handle_event("open_new", _params, socket) do
        {:noreply,
         socket
         |> assign(:editing_id, nil)
         |> assign(:show_form, true)
         |> assign_new_form()}
      end

      def handle_event("validate", %{"staff_meal_supply" => params}, socket) do
        changeset =
          socket
          |> editing_struct()
          |> StaffMeals.change_staff_meal_supply(params)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, :form, to_form(changeset))}
      end

      def handle_event("save", %{"staff_meal_supply" => params}, socket) do
        params = Map.put(params, "user_id", socket.assigns.current_user.id)

        result =
          case socket.assigns.editing_id do
            nil -> StaffMeals.create_staff_meal_supply(params)
            _id -> StaffMeals.update_staff_meal_supply(editing_struct(socket), params)
          end

        case result do
          {:ok, _supply} ->
            message =
              if socket.assigns.editing_id, do: "Delivery updated.", else: "Delivery recorded."

            {:noreply,
             socket
             |> put_flash(:info, message)
             |> assign(:editing_id, nil)
             |> assign(:show_form, false)
             |> assign_new_form()
             |> load_supplies()}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
      end

      def handle_event("edit", %{"id" => id}, socket) do
        supply = StaffMeals.get_staff_meal_supply!(id)

        {:noreply,
         socket
         |> assign(:editing_id, supply.id)
         |> assign(:show_form, true)
         |> assign(:form, to_form(StaffMeals.change_staff_meal_supply(supply)))}
      end

      def handle_event("cancel_edit", _params, socket) do
        {:noreply,
         socket
         |> assign(:editing_id, nil)
         |> assign(:show_form, false)
         |> assign_new_form()}
      end

      def handle_event("delete", %{"id" => id}, socket) do
        id
        |> StaffMeals.get_staff_meal_supply!()
        |> StaffMeals.delete_staff_meal_supply()

        {:noreply,
         socket
         |> put_flash(:info, "Delivery removed.")
         |> assign(:editing_id, nil)
         |> assign(:show_form, false)
         |> assign_new_form()
         |> load_supplies()}
      end

      def handle_event("filter", %{"filters" => filters}, socket) do
        {:noreply,
         socket
         |> assign(:filter_date_from, Map.get(filters, "date_from", "") |> String.trim())
         |> assign(:filter_date_to, Map.get(filters, "date_to", "") |> String.trim())
         |> assign(:filter_meal_type, Map.get(filters, "meal_type", "") |> String.trim())
         |> assign(:page, 1)
         |> load_supplies()}
      end

      def handle_event("search", %{"search" => term}, socket) do
        {:noreply,
         socket
         |> assign(:filter_search, String.trim(term))
         |> assign(:page, 1)
         |> load_supplies()}
      end

      def handle_event("paginate", %{"page" => page}, socket) do
        {:noreply,
         socket
         |> assign(:page, max(1, String.to_integer(page)))
         |> load_supplies()}
      end

      def handle_event("clear_filters", _params, socket) do
        {:noreply,
         socket
         |> assign(:filter_date_from, "")
         |> assign(:filter_date_to, "")
         |> assign(:filter_meal_type, "")
         |> assign(:filter_search, "")
         |> assign(:page, 1)
         |> load_supplies()}
      end

      @impl true
      def render(assigns) do
        MedcampWeb.StaffMealComponents.staff_meals_page(assigns)
      end

      defp load_supplies(socket) do
        all_supplies =
          StaffMeals.list_staff_meal_supplies(
            date_from: socket.assigns.filter_date_from,
            date_to: socket.assigns.filter_date_to,
            meal_type: socket.assigns.filter_meal_type,
            search: socket.assigns.filter_search
          )

        total_count = length(all_supplies)
        total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
        page = min(max(1, socket.assigns.page || 1), total_pages)

        supplies =
          Enum.slice(all_supplies, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

        socket
        |> assign(:page, page)
        |> assign(:total_count, total_count)
        |> assign(:total_pages, total_pages)
        |> assign(:supplies, supplies)
        |> assign(:summary, StaffMeals.summarize(all_supplies))
      end

      defp assign_new_form(socket) do
        changeset =
          StaffMeals.change_staff_meal_supply(
            %StaffMealSupply{},
            StaffMealSupply.current_supply_defaults()
          )

        assign(socket, :form, to_form(changeset))
      end

      defp editing_struct(%{assigns: %{editing_id: nil}}), do: %StaffMealSupply{}

      defp editing_struct(%{assigns: %{editing_id: id}}),
        do: StaffMeals.get_staff_meal_supply!(id)
    end
  end
end
