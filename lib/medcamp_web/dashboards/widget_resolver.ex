defmodule MedcampWeb.Dashboards.WidgetResolver do
  @moduledoc """
  Single source of truth for role -> visible dashboard summary cards and
  analytics tabs. Roles are the plain strings stored on `Medcamp.Accounts.User`
  ("admin", "doctor", "nurse", "labtechnician", "pharmacist") — not atoms.
  """

  @summary_cards %{
    "admin" => [
      :total_patients,
      :patient_visits,
      :doctor_notes,
      :lab_tests_done,
      :active_system_users
    ],
    "doctor" => [:patient_visits, :doctor_notes, :lab_tests_done],
    "nurse" => [:triages_completed, :registrations],
    "labtechnician" => [:lab_results, :completed_lab_reports, :pending_lab_results],
    "pharmacist" => [
      :drug_catalog,
      :pharmacy_stock_units,
      :drug_allocations,
      :dispensed_units,
      :pending_drug_allocations,
      :low_stock_items
    ]
  }

  @analytics_tabs %{
    "admin" => [:patients, :operations],
    "doctor" => [:patients, :operations],
    "nurse" => [],
    "labtechnician" => [],
    "pharmacist" => []
  }

  def summary_cards(role), do: Map.get(@summary_cards, role, [])
  def analytics_tabs(role), do: Map.get(@analytics_tabs, role, [])
  def default_analytics_tab(role), do: analytics_tabs(role) |> List.first()
end
