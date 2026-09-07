defmodule MedcampWeb.MealEntryLive.Index do
  use MedcampWeb, :live_view

  alias Medcamp.StaffMeals
  alias Medcamp.StaffMeals.StaffMealSupply

  # How long the confirmation modal stays up before the user is signed out.
  @auto_logout_after :timer.seconds(4)

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Add Staff Meal")

    socket =
      if socket.assigns.meal_entry_user do
        socket
        |> assign(:saved_meal, nil)
        |> assign_new_form()
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"staff_meal_supply" => params}, socket) do
    changeset =
      %StaffMealSupply{}
      |> StaffMeals.change_staff_meal_supply(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"staff_meal_supply" => params}, socket) do
    params = Map.put(params, "user_id", socket.assigns.meal_entry_user.id)

    case StaffMeals.create_staff_meal_supply(params) do
      {:ok, supply} ->
        Process.send_after(self(), :logout, @auto_logout_after)
        {:noreply, assign(socket, :saved_meal, supply)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_info(:logout, socket) do
    {:noreply, redirect(socket, to: ~p"/meals/logout")}
  end

  defp assign_new_form(socket) do
    changeset =
      StaffMeals.change_staff_meal_supply(
        %StaffMealSupply{},
        StaffMealSupply.current_supply_defaults()
      )

    assign(socket, :form, to_form(changeset))
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%a, %d %b %Y")
  defp format_date(_), do: "-"

  @impl true
  def render(%{meal_entry_user: nil} = assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-[#eef0ff] via-white to-white px-4 py-10">
      <div class="mx-auto w-full max-w-sm">
        <div class="rounded-3xl border border-indigo-100 bg-white p-7 shadow-xl shadow-indigo-100/50">
          <div class="text-center">
            <div class="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-[#eef0ff]">
              <.icon name="hero-cake" class="h-7 w-7 text-[#373896]" />
            </div>
            <h1 class="mt-5 text-2xl font-bold text-slate-900">Staff Meal Entry</h1>
            <p class="mt-2 text-sm leading-6 text-slate-500">
              Enter your 4-digit support staff PIN to sign in and record a meal.
            </p>
          </div>

          <form action={~p"/meals/session"} method="post" class="mt-8 space-y-5">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

            <label class="block">
              <span class="mb-2 block text-sm font-medium text-slate-700">Your PIN</span>
              <input
                type="text"
                name="otp"
                maxlength="4"
                inputmode="numeric"
                pattern="[0-9]{4}"
                placeholder="_ _ _ _"
                autofocus
                class="w-full rounded-2xl border border-slate-300 px-5 py-4 text-center text-3xl tracking-[0.55em] text-slate-900 shadow-sm outline-none transition focus:border-indigo-500 focus:ring-4 focus:ring-indigo-100"
              />
            </label>

            <button
              type="submit"
              class="inline-flex w-full items-center justify-center rounded-2xl bg-[#373896] px-4 py-4 text-base font-semibold text-white transition hover:bg-[#2f307e] focus:outline-none focus:ring-4 focus:ring-indigo-200"
            >
              Sign in
            </button>
          </form>
        </div>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-[#eef0ff] via-white to-white px-4 py-8">
      <div class="mx-auto w-full max-w-sm space-y-5">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-medium uppercase tracking-wide text-slate-500">Signed in as</p>
            <p class="text-base font-semibold text-slate-900">{@meal_entry_user.name}</p>
          </div>
          <.link
            href={~p"/meals/logout"}
            class="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-100"
          >
            Sign out
          </.link>
        </div>

        <div class="rounded-3xl border border-indigo-100 bg-white p-6 shadow-xl shadow-indigo-100/50">
          <h1 class="text-xl font-bold text-slate-900">Record a meal</h1>
          <p class="mt-1 text-sm text-slate-500">Enter today's meal delivery details.</p>

          <.form for={@form} phx-change="validate" phx-submit="save" class="mt-6 space-y-4">
            <.input field={@form[:supplied_on]} type="date" label="Date" />

            <.input
              field={@form[:meal_type]}
              type="select"
              label="Meal"
              options={StaffMealSupply.meal_type_options()}
            />

            <.input field={@form[:plates]} type="number" min="1" label="Plates supplied" />

            <.input
              field={@form[:price_per_plate]}
              type="number"
              min="0"
              label="Price per plate (KES)"
            />

            <.input
              field={@form[:notes]}
              type="textarea"
              label="Notes (optional)"
              placeholder="Any remarks about this delivery"
            />

            <.button class="w-full bg-[#373896] py-3 text-base hover:bg-[#2f307e]">
              Save meal
            </.button>
          </.form>
        </div>
      </div>

      <div
        :if={@saved_meal}
        class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 px-4"
      >
        <div class="w-full max-w-xs rounded-3xl bg-white p-7 text-center shadow-2xl">
          <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-emerald-100">
            <.icon name="hero-check-circle" class="h-10 w-10 text-emerald-600" />
          </div>
          <h2 class="mt-5 text-xl font-bold text-slate-900">Meal recorded</h2>
          <p class="mt-2 text-sm text-slate-600">
            {StaffMealSupply.meal_type_label(@saved_meal.meal_type)} · {@saved_meal.plates} plates
            <span class="block text-xs text-slate-400">{format_date(@saved_meal.supplied_on)}</span>
          </p>

          <p class="mt-5 flex items-center justify-center gap-2 text-xs font-medium text-slate-400">
            <.icon name="hero-arrow-path" class="h-4 w-4 animate-spin" /> Signing you out…
          </p>

          <.link
            href={~p"/meals/logout"}
            class="mt-4 inline-flex w-full items-center justify-center rounded-2xl bg-[#373896] px-4 py-3 text-sm font-semibold text-white hover:bg-[#2f307e]"
          >
            Done
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
