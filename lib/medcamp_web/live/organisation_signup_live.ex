defmodule MedcampWeb.OrganisationSignupLive do
  @moduledoc """
  Public self-serve signup: an organisation and its first admin, in one form.

  Nothing here runs inside a tenant - the organisation being created is what
  the tenant will be - so it touches only `organisations` (not a tenant table)
  and hands the admin creation to `Medcamp.Organisations.register_organisation/2`,
  which enters the new organisation before writing the user row.

  The organisation lands pending. Until a superadmin approves it, nobody can
  log in; `MedcampWeb.UserAuth.log_in_user/3` is what enforces that.
  """

  use MedcampWeb, :live_view

  alias Medcamp.Organisations
  alias Medcamp.Organisations.Organisation
  alias Medcamp.Validation

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Create your organisation")
     |> assign(:current_organisation, nil)
     |> assign(:submitted, false)
     |> assign(:step, 1)
     |> assign(:org_email_same, true)
     |> assign_forms(%{}, %{}), layout: false}
  end

  @impl true
  def handle_event("validate", params, socket) do
    same = email_same?(params)
    admin_params = Map.get(params, "admin", %{})

    {:noreply,
     socket
     |> assign(:org_email_same, same)
     |> assign_org_form(merged_org_params(org_params(params), admin_params, same), :validate)
     |> assign_admin_form(admin_params, :validate)}
  end

  # Step 1: hitting Enter or "Continue" moves to the admin-account step once the
  # organisation details are valid.
  def handle_event("next", _params, socket), do: {:noreply, advance(socket)}
  def handle_event("back", _params, socket), do: {:noreply, assign(socket, :step, 1)}

  def handle_event("register", _params, %{assigns: %{step: 1}} = socket) do
    {:noreply, advance(socket)}
  end

  def handle_event("register", params, socket) do
    admin_params = Map.get(params, "admin", %{})
    org_attrs = merged_org_params(org_params(params), admin_params, email_same?(params))

    case Organisations.register_organisation(org_attrs, admin_attrs(params, org_attrs)) do
      {:ok, %{organisation: organisation}} ->
        {:noreply, assign(socket, submitted: true, organisation: organisation)}

      {:error, :organisation, changeset} ->
        {:noreply,
         socket
         |> assign(:org_form, to_form(changeset, as: "organisation"))
         |> put_flash(:error, "Please check the organisation details below.")}

      {:error, :admin, changeset} ->
        {:noreply,
         socket
         |> assign(:admin_form, to_form(changeset, as: "admin"))
         |> put_flash(:error, "Please check the administrator details below.")}
    end
  end

  defp org_params(params), do: Map.get(params, "organisation", %{})

  # The "same as my email" checkbox is checked by default; it only sends a value
  # while ticked, so an absent key means the person wants a separate address.
  defp email_same?(params), do: Map.get(params, "email_same") == "true"

  # When the organisation reuses the admin's address, the org email field is not
  # shown, so fill it in from what they typed for their own account.
  defp merged_org_params(org_attrs, admin_attrs, true),
    do: Map.put(org_attrs, "email", Map.get(admin_attrs, "email", ""))

  defp merged_org_params(org_attrs, _admin_attrs, false), do: org_attrs

  # The person signing up gives their name once, on the organisation record as
  # the contact; it doubles as the admin account's name so they are not asked
  # for it twice.
  defp admin_attrs(params, org_attrs) do
    params
    |> Map.get("admin", %{})
    |> Map.put("name", Map.get(org_attrs, "contact_name"))
  end

  defp assign_forms(socket, org_attrs, admin_attrs) do
    socket
    |> assign_org_form(org_attrs)
    |> assign_admin_form(admin_attrs)
  end

  # A schemaless changeset for step 2's admin fields, so `phx-change` can show
  # friendly inline errors (bad email, short password, mismatched confirmation)
  # before the form is submitted. The authoritative check is still
  # `Accounts.register_user/1` inside the signup transaction, whose changeset
  # replaces this one on `{:error, :admin, _}`.
  defp assign_admin_form(socket, attrs, action \\ nil) do
    changeset =
      {%{}, %{email: :string, password: :string, password_confirmation: :string}}
      |> Ecto.Changeset.cast(attrs, [:email, :password, :password_confirmation])
      |> Validation.validate_email()
      |> Ecto.Changeset.validate_length(:password,
        min: 6,
        message: "must be at least 6 characters"
      )
      |> Ecto.Changeset.validate_confirmation(:password, message: "does not match the password")
      |> Map.put(:action, action)

    assign(socket, :admin_form, to_form(changeset, as: "admin"))
  end

  defp assign_org_form(socket, org_attrs, action \\ nil) do
    changeset = Organisation.signup_changeset(%Organisation{}, org_attrs)
    assign(socket, :org_form, to_form(changeset, as: "organisation", action: action))
  end

  # `phx-change="validate"` keeps `@org_form` current, so the organisation
  # changeset already reflects what the user typed. Advance if it is valid,
  # otherwise re-surface its errors on step 1.
  defp advance(socket) do
    changeset = socket.assigns.org_form.source

    # `contact_name` ("Your name") and `email` (defaulted from the admin's own
    # address) are both settled on step 2, so neither may block leaving step 1.
    if Keyword.drop(changeset.errors, [:contact_name, :email]) == [] do
      assign(socket, :step, 2)
    else
      assign(
        socket,
        :org_form,
        to_form(Map.put(changeset, :action, :validate), as: "organisation")
      )
    end
  end

  @impl true
  def render(%{submitted: true} = assigns) do
    ~H"""
    <.auth_split>
      <h1 class="text-2xl font-bold tracking-[-0.01em]">You're in the queue</h1>
      <p class="mt-3 text-sm leading-relaxed text-slate-600">
        <strong>{@organisation.name}</strong>
        has been added to the medical camp approval queue. We'll email
        <strong>{@organisation.email}</strong>
        once the camp workspace is active. The first administrator will then receive
        password setup instructions.
      </p>
      <.link
        navigate={~p"/users/log_in"}
        class="mt-8 inline-flex items-center justify-center rounded-full bg-[#0C2765] px-6 py-3 text-base font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]"
      >
        Back to sign in
      </.link>
    </.auth_split>
    """
  end

  def render(assigns) do
    ~H"""
    <.auth_split width="wide">
      <.flash_group flash={@flash} />

      <h1 class="text-2xl font-bold tracking-[-0.01em]">Create your organisation</h1>
      <p class="mt-2 text-sm leading-relaxed text-slate-600">
        Request a medical camp workspace so your team can register patients,
        run stations, and report on camp activity.
      </p>

      <div class="mt-6 flex items-center gap-3">
        <div class="flex flex-1 gap-2">
          <span class={["h-1 flex-1 rounded-full", (@step >= 1 && "bg-[#0C2765]") || "bg-slate-200"]}>
          </span>
          <span class={["h-1 flex-1 rounded-full", (@step >= 2 && "bg-[#0C2765]") || "bg-slate-200"]}>
          </span>
        </div>
        <span class="shrink-0 text-xs font-semibold text-slate-500">Step {@step} of 2</span>
      </div>

      <.form
        for={@org_form}
        id="organisation-signup-form"
        phx-change="validate"
        phx-submit="register"
        class="mt-8"
      >
        <div class={(@step == 1 && "space-y-5") || "hidden"}>
          <h2 class="text-base font-semibold text-[#0C2765]">Enter your organisation's details</h2>

          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <.input field={@org_form[:name]} type="text" label="Organisation name" />
            <.input field={@org_form[:phone_number]} type="text" label="Phone number" />
            <.input field={@org_form[:location]} type="text" label="Location" />
          </div>
        </div>

        <div class={(@step == 2 && "space-y-5") || "hidden"}>
          <h2 class="text-base font-semibold text-[#0C2765]">First camp administrator</h2>
          <p class="-mt-3 text-xs text-slate-500">
            This person will receive setup instructions and can add the rest of the camp staff.
          </p>

          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <.input field={@org_form[:contact_name]} type="text" label="Your name" />
            <.input field={@admin_form[:email]} type="email" label="Your email" />
          </div>

          <label class="flex items-start gap-3 rounded-xl border border-slate-200 bg-slate-50 p-4">
            <input type="hidden" name="email_same" value="false" />
            <input
              type="checkbox"
              name="email_same"
              value="true"
              checked={@org_email_same}
              class="mt-0.5 h-4 w-4 rounded border-slate-300 text-[#0C2765] focus:ring-[#52B2D8]"
            />
            <span class="text-sm text-slate-700">
              Use this as the organisation's contact email too
              <span class="mt-0.5 block text-xs text-slate-500">
                Camp approval and account notices are sent here. Uncheck to use a different address.
              </span>
            </span>
          </label>

          <div :if={not @org_email_same} class="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <.input field={@org_form[:email]} type="email" label="Organisation email" />
          </div>

          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <.input field={@admin_form[:password]} type="password" label="Password" />
            <.input
              field={@admin_form[:password_confirmation]}
              type="password"
              label="Confirm password"
            />
          </div>
        </div>

        <div :if={@step == 1} class="mt-8 flex items-center justify-between gap-4">
          <p class="text-sm text-slate-600">
            Already have an account?
            <.link
              navigate={~p"/users/log_in"}
              class="font-semibold text-[#0C2765] transition-colors duration-150 hover:text-[#52B2D8]"
            >
              Sign in
            </.link>
          </p>
          <.auth_submit type="button" phx-click="next" label="Continue" class="" />
        </div>

        <div :if={@step == 2} class="mt-8 flex items-center justify-between gap-4">
          <button
            type="button"
            phx-click="back"
            class="inline-flex items-center justify-center rounded-full border border-slate-300 px-6 py-3 text-base font-semibold text-[#0C2765] transition-colors duration-150 hover:border-[#52B2D8]"
          >
            Back
          </button>
          <.auth_submit label="Create organisation" phx-disable-with="Creating..." class="" />
        </div>
      </.form>
    </.auth_split>
    """
  end
end
