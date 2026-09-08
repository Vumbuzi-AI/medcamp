defmodule MedcampWeb.CampComponents do
  @moduledoc """
  The camp switcher that sits at the top of the admin layout.

  It sets a *viewing* filter: with a camp chosen, every camp-scoped table -
  visits, triages, notes, lab results, prescriptions, dispenses, stock
  received - shows only what happened at that camp, on every admin page at
  once. "All camps" is the default and the way back to the whole picture.

  It does not change which camp new records are written into. That is the
  organisation's active camp, set on `/admin/camps`, and it is shown here
  read-only so the two are never confused.
  """

  use Phoenix.Component
  use MedcampWeb, :verified_routes

  alias Medcamp.Camps.Camp

  attr :camps, :list, required: true, doc: "every camp in the organisation"
  attr :camp_filter, :any, default: nil, doc: "the camp currently being viewed, or nil for all"
  attr :active_camp, :any, default: nil, doc: "the camp new records are stamped with"

  def camp_switcher(assigns) do
    ~H"""
    <div :if={@camps != []} class="flex flex-wrap items-center justify-end gap-3 mb-4">
      <div class="text-xs text-slate-500">
        <span :if={@active_camp}>
          Recording into <span class="font-medium text-slate-700">{@active_camp.name}</span>
        </span>
        <span :if={is_nil(@active_camp)} class="text-amber-700">
          No active camp
        </span>
      </div>

      <form action={~p"/admin/camps/filter"} method="post" class="flex items-center gap-2">
        <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

        <label for="camp-filter" class="text-xs font-medium text-slate-600">Viewing</label>
        <select
          id="camp-filter"
          name="camp_id"
          onchange="this.form.requestSubmit()"
          class="rounded-lg border-slate-300 py-1.5 pl-3 pr-8 text-sm text-slate-800 focus:border-brand-primary focus:ring-brand-primary"
        >
          <option value="all" selected={is_nil(@camp_filter)}>All camps</option>
          <option
            :for={camp <- @camps}
            value={camp.id}
            selected={@camp_filter && @camp_filter.id == camp.id}
          >
            {camp.name}{if Camp.date_range(camp), do: " - #{Camp.date_range(camp)}"}
          </option>
        </select>

        <noscript>
          <button type="submit" class="rounded-lg bg-slate-800 px-2 py-1 text-xs text-white">
            Apply
          </button>
        </noscript>
      </form>
    </div>
    """
  end
end
