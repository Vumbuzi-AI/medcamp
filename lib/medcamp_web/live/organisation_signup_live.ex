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

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Create your organisation")
     |> assign(:current_organisation, nil)
     |> assign(:submitted, false)
     |> assign_forms(%{}, %{}), layout: false}
  end

  @impl true
  def handle_event("validate", params, socket) do
    {:noreply, assign_org_form(socket, org_params(params), :validate)}
  end

  def handle_event("register", params, socket) do
    org_attrs = org_params(params)

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
    # A plain map rather than a User changeset: building one here would try to
    # stamp a tenant that does not exist yet. The real validation happens in
    # the transaction, and its changeset replaces this form on failure.
    |> assign(
      :admin_form,
      to_form(Enum.into(admin_attrs, %{"email" => "", "password" => ""}), as: "admin")
    )
  end

  defp assign_org_form(socket, org_attrs, action \\ nil) do
    changeset = Organisation.signup_changeset(%Organisation{}, org_attrs)
    assign(socket, :org_form, to_form(changeset, as: "organisation", action: action))
  end

  @impl true
  def render(%{submitted: true} = assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-brand-50 p-6">
      <div class="max-w-md rounded-2xl border border-brand-200 bg-white p-8 text-center shadow-sm">
        <h1 class="text-2xl font-bold text-brand-primary">Thanks — you're in the queue</h1>
        <p class="mt-3 text-sm text-grey">
          <strong>{@organisation.name}</strong>
          has been created and is waiting to be approved.
          We'll email <strong>{@organisation.email}</strong>
          as soon as it's active, and you can sign in with the administrator
          account you just set up.
        </p>
        <.link
          navigate={~p"/users/log_in"}
          class="mt-6 inline-block text-sm font-semibold text-brand-primary"
        >
          Back to sign in
        </.link>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-brand-50 py-12">
      <.flash_group flash={@flash} />

      <div class="mx-auto max-w-2xl px-6">
        <div class="text-center">
          <h1 class="text-3xl font-bold text-brand-primary">Create your organisation</h1>
          <p class="mt-2 text-sm text-grey">
            Your camp's patients, staff, stock and lab results stay entirely separate
            from every other organisation on Medcamp.
          </p>
        </div>

        <.form
          for={@org_form}
          id="organisation-signup-form"
          phx-change="validate"
          phx-submit="register"
          class="mt-8 space-y-8 rounded-2xl border border-brand-200 bg-white p-8 shadow-sm"
        >
          <section class="space-y-5">
            <h2 class="text-sm font-semibold uppercase tracking-wide text-grey">Organisation</h2>

            <.input field={@org_form[:name]} type="text" label="Organisation name" required />
            <.input field={@org_form[:email]} type="email" label="Organisation email" required />

            <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
              <.input field={@org_form[:phone_number]} type="text" label="Phone number" />
              <.input field={@org_form[:location]} type="text" label="Location" />
            </div>
          </section>

          <section class="space-y-5 border-t border-gray-100 pt-8">
            <h2 class="text-sm font-semibold uppercase tracking-wide text-grey">
              Administrator account
            </h2>
            <p class="-mt-3 text-xs text-grey">
              This is the account you'll sign in with. It can create the rest of your staff.
            </p>

            <.input field={@org_form[:contact_name]} type="text" label="Your name" required />
            <.input field={@admin_form[:email]} type="email" label="Your email" required />
            <.input field={@admin_form[:password]} type="password" label="Password" required />
          </section>

          <div class="flex items-center justify-between border-t border-gray-100 pt-6">
            <.link navigate={~p"/users/log_in"} class="text-sm text-grey hover:text-brand-primary">
              Already have an account?
            </.link>
            <.button phx-disable-with="Creating...">Create organisation</.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
