defmodule MedcampWeb.Dashboards.WidgetResolver do
  @moduledoc """
  Single source of truth for role -> visible dashboard summary cards and
  analytics tabs. Roles are the plain strings stored on `Medcamp.Accounts.User`
  (e.g. "admin", "doctor", "reception") — not atoms.
  """

  @summary_cards %{
    "admin" => [
      :total_patients,
      :patient_visits,
      :revenue_collected,
      :appointments,
      :doctor_notes,
      :lab_tests_done,
      :active_system_users,
      :mpesa_transactions
    ],
    "doctor" => [:patient_visits, :appointments, :doctor_notes, :lab_tests_done],
    "reception" => [:total_patients, :patient_visits, :appointments, :active_system_users],
    "nurse" => [:triages_completed, :nurse_procedures, :room_allocations],
    "labtechnician" => [:lab_results, :completed_lab_reports, :pending_lab_results],
    "pharmacist" => [
      :drug_catalog,
      :pharmacy_stock_units,
      :pharmacy_stock_value,
      :drug_allocations,
      :dispensed_units,
      :dispensed_value,
      :pending_drug_allocations,
      :low_stock_items
    ],
    "radiologist" => [
      :radiology_exams,
      :completed_radiology_reports,
      :pending_radiology_reports,
      :urgent_radiology_cases
    ],
    "inventory_manager" => [
      :inventory_items,
      :inventories_received,
      :inventories_issued,
      :stock_alerts
    ]
  }

  @analytics_tabs %{
    "admin" => [:revenue, :patients, :operations],
    "doctor" => [:patients, :operations],
    "reception" => [:patients, :operations],
    "nurse" => [],
    "labtechnician" => [],
    "pharmacist" => [],
    "radiologist" => [],
    "inventory_manager" => []
  }

  def summary_cards(role), do: Map.get(@summary_cards, role, [])
  def analytics_tabs(role), do: Map.get(@analytics_tabs, role, [])
  def default_analytics_tab(role), do: analytics_tabs(role) |> List.first()
end
