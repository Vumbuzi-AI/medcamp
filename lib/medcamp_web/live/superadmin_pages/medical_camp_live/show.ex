defmodule MedcampWeb.SuperadminMedicalCampLive.Show do
  @moduledoc """
  Superadmin drilldown into a single organisation's medical camp dashboard.
  """

  use MedcampWeb, :superadmin_live_view

  alias Medcamp.Organisations
  alias Medcamp.Tenancy

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    organisation = Organisations.get_organisation!(id)
    Tenancy.put_org_id(organisation.id)

    {:ok,
     socket
     |> assign(:active_tab, :organisations)
     |> assign(:page_title, "#{organisation.name} Camp Dashboard")
     |> assign(:organisation, organisation)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    {Phoenix.Component.live_render(@socket, MedcampWeb.AdminMedicalCampLive.Index,
      id: "superadmin-medical-camp-#{@organisation.id}",
      session: %{
        "superadmin_org_id" => @organisation.id,
        "superadmin_organisation_name" => @organisation.name,
        "superadmin_back_path" => ~p"/superadmin/organisations",
        "report_path" => "/superadmin/organisations/#{@organisation.id}/medical-camp"
      }
    )}
    """
  end
end
