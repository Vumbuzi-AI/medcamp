defmodule MedcampWeb.CampComponents do
  @moduledoc """
  The camp *view* selector, rendered in the toolbar of each camp-scoped admin
  page (and the medical-camp dashboard header).

  It sets a viewing filter: with a camp chosen, every camp-scoped table -
  visits, triages, notes, lab results, prescriptions, dispenses, stock
  received - shows only what happened at that camp, on every admin page at
  once (it is session-backed). "All camps" is the default.

  It does not change which camp new records are written into - that is the
  organisation's active camp, set on `/admin/camps`.
  """

  use Phoenix.Component
  use MedcampWeb, :verified_routes

  alias Medcamp.Camps.Camp

  attr :camps, :list, required: true, doc: "every camp in the organisation"
  attr :camp_filter, :any, default: nil, doc: "the camp currently being viewed, or nil for all"

  attr :tone, :string,
    default: "light",
    values: ~w(light on_dark),
    doc: "\"on_dark\" for the navy medical-camp header"

  attr :class, :string, default: nil

  @doc """
  Compact camp view selector. Session-backed (posts to `CampSessionController`),
  so the choice follows the admin across every page. Meant to sit inside a
  page's toolbar or header - not as a standalone bar - and carries no
  "recording into" copy: that is the active camp, shown on `/admin/camps`.
  """
  def camp_switcher(assigns) do
    ~H"""
    <form
      :if={@camps != []}
      action={~p"/admin/camps/filter"}
      method="post"
      class={[
        @tone == "on_dark" && "flex w-full items-center gap-2 sm:w-72",
        @tone == "light" && "inline-flex items-center gap-2",
        @class
      ]}
    >
      <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
      <label
        for="camp-filter"
        class={[
          "shrink-0 text-xs font-medium",
          @tone == "on_dark" && "text-white/80",
          @tone == "light" && "text-slate-500"
        ]}
      >
        Camp
      </label>
      <div class={["relative", @tone == "on_dark" && "flex-1"]}>
        <select
          id="camp-filter"
          name="camp_id"
          onchange="this.form.requestSubmit()"
          class={[
            "h-10 w-full appearance-none rounded-full border bg-white pl-4 pr-9 text-sm font-medium text-slate-900 transition-colors focus:outline-none focus:ring-0",
            @tone == "on_dark" && "border-transparent hover:bg-white/95",
            @tone == "light" && "rounded-md border-slate-300 font-normal focus:border-brand-accent"
          ]}
        >
          <option value="all" selected={is_nil(@camp_filter)}>All camps</option>
          <option
            :for={camp <- @camps}
            value={camp.id}
            selected={@camp_filter && @camp_filter.id == camp.id}
          >
            {camp.name}{if Camp.date_range(camp), do: " · #{Camp.date_range(camp)}"}
          </option>
        </select>
        <Heroicons.icon
          name="chevron-down"
          type="outline"
          class="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500"
        />
      </div>
      <noscript>
        <button type="submit" class="rounded-md bg-slate-800 px-2 py-1 text-xs text-white">Go</button>
      </noscript>
    </form>
    """
  end
end
