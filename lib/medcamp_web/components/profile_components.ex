defmodule MedcampWeb.ProfileComponents do
  use Phoenix.Component

  import MedcampWeb.CoreComponents

  def profile_section(assigns) do
    assigns =
      assigns
      |> assign(:initials, user_initials(assigns.current_user))
      |> assign(:role_label, role_label(assigns.current_user.role))

    ~H"""
    <div class="-m-4 min-h-screen bg-slate-50 p-4 sm:-m-6 sm:p-6">
      <.form
        for={@form}
        id="profile-form"
        phx-submit="save-profile"
        phx-change="validate-profile"
        class="mx-auto max-w-6xl space-y-6"
      >
        <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-7">
          <div class="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <h1 class="text-2xl font-bold tracking-[-0.01em] text-slate-900 sm:text-3xl">
                Profile Information
              </h1>
              <p class="mt-2 max-w-2xl text-sm leading-relaxed text-slate-500">
                Keep your staff profile current for camp coordination, clinical records,
                and activity reports.
              </p>
            </div>

            <div class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Role</p>
              <p class="mt-1 text-sm font-semibold text-brand-primary">{@role_label}</p>
            </div>
          </div>
        </section>

        <div class="grid gap-6 xl:grid-cols-[340px_minmax(0,1fr)]">
          <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <div class="flex items-start gap-3">
              <div class="grid h-11 w-11 shrink-0 place-items-center rounded-full border border-slate-200 bg-slate-50 text-brand-primary">
                <Heroicons.icon name="identification" type="outline" class="h-6 w-6" />
              </div>
              <div>
                <h2 class="text-lg font-semibold text-slate-900">Profile photo</h2>
                <p class="mt-1 text-sm leading-relaxed text-slate-500">
                  This photo appears in staff-facing screens and audit context.
                </p>
              </div>
            </div>

            <div
              class="mt-6 flex flex-col items-center rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-5 py-6 text-center"
              phx-drop-target={@uploads.image.ref}
            >
              <label for="profile_image_input" class="group cursor-pointer">
                <span class="relative block">
                  <%= if @current_user.image do %>
                    <img
                      src={@current_user.image}
                      alt="Profile photo"
                      class="h-28 w-28 rounded-full border border-brand-200 bg-white object-cover shadow-sm"
                    />
                  <% else %>
                    <span class="flex h-28 w-28 items-center justify-center rounded-full bg-brand-primary text-2xl font-bold text-white shadow-sm">
                      {@initials}
                    </span>
                  <% end %>

                  <span class="absolute inset-0 flex items-center justify-center rounded-full bg-slate-950/45 text-xs font-semibold text-white opacity-0 transition-opacity group-hover:opacity-100">
                    Change
                  </span>
                </span>

                <span class="mt-4 block text-sm font-semibold text-brand-primary">
                  Upload profile photo
                </span>
                <span class="mt-1 block text-xs text-slate-500">PNG or JPEG, under 5 MB</span>
                <.live_file_input upload={@uploads.image} class="hidden" />
              </label>

              <div
                :for={entry <- @uploads.image.entries}
                class="mt-5 w-full rounded-xl border border-slate-200 bg-white p-3"
              >
                <div class="flex items-center justify-between gap-3 text-left">
                  <p class="min-w-0 truncate text-sm font-medium text-slate-700">
                    {entry.client_name}
                  </p>
                  <span class="shrink-0 text-xs font-semibold text-brand-primary">
                    {entry.progress}%
                  </span>
                </div>
                <div class="mt-2 h-2 overflow-hidden rounded-full bg-brand-100">
                  <div
                    style={"width: #{entry.progress}%"}
                    class="h-full rounded-full bg-brand-primary transition-all duration-500"
                  >
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <div class="flex items-start gap-3 border-b border-slate-100 pb-5">
              <div class="grid h-11 w-11 shrink-0 place-items-center rounded-full border border-slate-200 bg-slate-50 text-brand-primary">
                <Heroicons.icon name="user-circle" type="outline" class="h-6 w-6" />
              </div>
              <div>
                <h2 class="text-lg font-semibold text-slate-900">Staff details</h2>
                <p class="mt-1 text-sm leading-relaxed text-slate-500">
                  These details help identify who recorded clinical notes, triage,
                  lab results, dispensing, and admin actions.
                </p>
              </div>
            </div>

            <div class="mt-6 space-y-5">
              <.input field={@form[:email]} disabled type="email" label="Email" />

              <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
                <.input field={@form[:name]} type="text" label="Name" />
                <.input field={@form[:license_number]} type="text" label="License number" />
                <.input field={@form[:phone_number]} type="text" label="Phone number" />
                <.input field={@form[:id_number]} type="text" label="ID number" />
              </div>

              <.input
                field={@form[:experience]}
                type="textarea"
                label="Experience"
                placeholder="Relevant camp, clinical, laboratory, pharmacy, or operations experience"
              />
            </div>
          </section>
        </div>

        <div class="flex flex-col gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
          <p class="text-sm text-slate-500">
            Changes update your staff profile across this medical camp workspace.
          </p>
          <.button phx-disable-with="Saving...">Save profile</.button>
        </div>
      </.form>
    </div>
    """
  end

  defp user_initials(%{name: name}) when is_binary(name) and name != "" do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.upcase(String.first(&1)))
  end

  defp user_initials(%{email: email}) when is_binary(email) and email != "" do
    email
    |> String.first()
    |> String.upcase()
  end

  defp user_initials(_), do: "U"

  defp role_label("labtechnician"), do: "Lab technician"
  defp role_label(role) when is_binary(role), do: String.capitalize(role)
  defp role_label(_), do: "Staff"
end
