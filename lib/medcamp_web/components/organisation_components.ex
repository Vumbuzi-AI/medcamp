defmodule MedcampWeb.OrganisationComponents do
  @moduledoc """
  Branding pieces shared by everything that gets printed or handed to a
  patient: lab reports, template previews, camp claim statements, patient
  cards.

  These render deep inside components that do not all carry the current user
  in their assigns, so the organisation is read from the process tenancy that
  `MedcampWeb.UserAuth` (or `MedcampWeb.PublicTenant`) established for the
  request. That is the same value every query on the page is scoped to, so a
  report can never end up with one organisation's data under another's
  letterhead.
  """

  use Phoenix.Component

  alias Medcamp.Organisations
  alias Medcamp.Tenancy

  @doc """
  The organisation this render belongs to, or `nil` outside a tenant.
  """
  def current_organisation do
    Organisations.get_organisation(Tenancy.current_org_id())
  end

  attr :organisation, :any, default: :from_tenancy

  @doc """
  The centred letterhead at the top of a printed report: logo, organisation
  name, and whatever contact details the organisation has filled in.
  """
  def letterhead(assigns) do
    assigns = resolve_organisation(assigns)

    ~H"""
    <div class="text-center py-8 print:py-6">
      <img
        src={Organisations.logo_path(@organisation)}
        alt={Organisations.display_name(@organisation)}
        class="mx-auto h-16 w-16 mb-4 object-contain"
      />
      <h1 class="text-2xl font-bold text-brand-primary tracking-wide mb-2 uppercase">
        {Organisations.display_name(@organisation)}
      </h1>
      <p :if={@organisation && @organisation.location} class="text-slate-800 text-base font-medium">
        {@organisation.location}
      </p>
      <p :if={@organisation && @organisation.phone_number} class="mt-1 text-base text-slate-700">
        Tel: {@organisation.phone_number}
      </p>
      <p :if={@organisation && @organisation.email} class="mt-1 text-base text-slate-700">
        {@organisation.email}
      </p>
    </div>
    """
  end

  attr :organisation, :any, default: :from_tenancy
  attr :subtitle, :string, default: nil

  @doc """
  The compact, left-aligned variant: logo beside the organisation name, with
  an optional line of context underneath.
  """
  def brand_mark(assigns) do
    assigns = resolve_organisation(assigns)

    ~H"""
    <div class="flex items-center gap-3">
      <img
        src={Organisations.logo_path(@organisation)}
        alt={Organisations.display_name(@organisation)}
        class="h-12 w-auto object-contain"
      />
      <div>
        <p class="font-medium text-slate-900">{Organisations.display_name(@organisation)}</p>
        <p :if={@subtitle} class="text-xs uppercase tracking-wide text-slate-500">{@subtitle}</p>
      </div>
    </div>
    """
  end

  defp resolve_organisation(%{organisation: :from_tenancy} = assigns),
    do: assign(assigns, :organisation, current_organisation())

  defp resolve_organisation(assigns), do: assigns
end
