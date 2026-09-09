defmodule MedcampWeb.Dashboards.WidgetResolverTest do
  use ExUnit.Case, async: true

  alias MedcampWeb.Dashboards.WidgetResolver

  describe "summary_cards/1" do
    test "admin sees the medical camp oversight cards" do
      assert WidgetResolver.summary_cards("admin") == [
               :total_patients,
               :patient_visits,
               :doctor_notes,
               :lab_tests_done,
               :active_system_users
             ]
    end

    test "doctor sees only clinical cards" do
      assert WidgetResolver.summary_cards("doctor") == [
               :patient_visits,
               :doctor_notes,
               :lab_tests_done
             ]
    end

    test "nurse sees registration and triage cards" do
      assert WidgetResolver.summary_cards("nurse") == [
               :triages_completed,
               :registrations
             ]
    end

    test "lab technician sees lab queue cards" do
      assert WidgetResolver.summary_cards("labtechnician") == [
               :lab_results,
               :completed_lab_reports,
               :pending_lab_results
             ]
    end

    test "pharmacist sees pharmacy stock, dispensing, and allocation cards" do
      assert WidgetResolver.summary_cards("pharmacist") == [
               :drug_catalog,
               :pharmacy_stock_units,
               :drug_allocations,
               :dispensed_units,
               :pending_drug_allocations,
               :low_stock_items
             ]
    end

    test "an unknown role sees no cards" do
      assert WidgetResolver.summary_cards("finance") == []
    end
  end

  describe "analytics_tabs/1" do
    test "admin sees non-billing camp analytics tabs" do
      assert WidgetResolver.analytics_tabs("admin") == [:patients, :operations]
    end

    test "doctor sees clinical analytics without revenue" do
      assert WidgetResolver.analytics_tabs("doctor") == [:patients, :operations]
      refute :revenue in WidgetResolver.analytics_tabs("doctor")
    end

    test "other camp roles do not have dashboard analytics tabs" do
      assert WidgetResolver.analytics_tabs("nurse") == []
      assert WidgetResolver.analytics_tabs("labtechnician") == []
      assert WidgetResolver.analytics_tabs("pharmacist") == []
    end

    test "an unknown role sees no tabs" do
      assert WidgetResolver.analytics_tabs("finance") == []
    end
  end

  describe "default_analytics_tab/1" do
    test "admin defaults to patients" do
      assert WidgetResolver.default_analytics_tab("admin") == :patients
    end

    test "doctor defaults to patients" do
      assert WidgetResolver.default_analytics_tab("doctor") == :patients
    end

    test "an unknown role has no default tab" do
      assert WidgetResolver.default_analytics_tab("finance") == nil
    end
  end
end
