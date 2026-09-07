defmodule MedcampWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use MedcampWeb, :controller
      use MedcampWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt uploads)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: MedcampWeb.Layouts]

      use Gettext, backend: MedcampWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :app}

      require Logger

      unquote(html_helpers())
    end
  end

  def doctor_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :doctor}

      unquote(html_helpers())
    end
  end

  def shared_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :shared}

      unquote(html_helpers())
    end
  end

  def inventory_manager_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :inventory_manager}

      unquote(html_helpers())
    end
  end

  def lab_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :lab}

      unquote(html_helpers())
    end
  end

  def radiologist_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :radiologist}

      unquote(html_helpers())
    end
  end

  def support_staff_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :support_staff}

      unquote(html_helpers())
    end
  end

  def radiologist_each_patient_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :radiologist_each_patient}

      unquote(html_helpers())
    end
  end

  def nurse_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :nurse}

      unquote(html_helpers())
    end
  end

  def nurse_each_patient_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :nurse_each_patient}

      unquote(html_helpers())
    end
  end

  def pharmacist_each_patient_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :pharmacist_each_patient}

      unquote(html_helpers())
    end
  end

  def lab_each_patient_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :lab_each_patient}

      unquote(html_helpers())
    end
  end

  def admin_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :admin}

      unquote(html_helpers())
    end
  end

  def pharmacist_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :pharmacist}

      unquote(html_helpers())
    end
  end

  def reception_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :reception}

      unquote(html_helpers())
    end
  end

  def supplier_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :supplier}

      unquote(html_helpers())
    end
  end

  def procurement_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :procurement}

      unquote(html_helpers())
    end
  end

  def reception_each_patient_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :reception_each_patient}

      unquote(html_helpers())
    end
  end

  def each_patient_live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MedcampWeb.Layouts, :each_patient}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: MedcampWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import MedcampWeb.CoreComponents
      import MedcampWeb.PublicSiteComponents
      import MedcampWeb.SidebarComponents
      import MedcampWeb.PatientComponents
      import MedcampWeb.TriageComponents
      import MedcampWeb.DoctorNotesComponents
      import MedcampWeb.CommunityHealthSurveyComponents
      import MedcampWeb.LabResultComponents
      import MedcampWeb.DrugAllocationComponents
      import MedcampWeb.ScanComponents
      import MedcampWeb.ReferralsComponents
      import MedcampWeb.RadiologyComponents
      import MedcampWeb.AdmissionRequestsComponents
      import MedcampWeb.ProfileComponents
      import MedcampWeb.TelephoneComponents
      import MedcampWeb.WalletDepositComponents
      import MedcampWeb.InPatientComponents
      import MedcampWeb.StockAlertComponents
      import MedcampWeb.FormsComponents
      import MedcampWeb.DashboardComponents
      import MedcampWeb.MedicalCampReportComponents

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: MedcampWeb.Endpoint,
        router: MedcampWeb.Router,
        statics: MedcampWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
