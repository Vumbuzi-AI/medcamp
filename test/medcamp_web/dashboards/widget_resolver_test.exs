defmodule MedcampWeb.Dashboards.WidgetResolverTest do
  use ExUnit.Case, async: true

  alias MedcampWeb.Dashboards.WidgetResolver

  describe "summary_cards/1" do
    test "summary_cards/1 admin sees all 8 cards" do
      assert WidgetResolver.summary_cards("admin") == [
               :total_patients,
               :patient_visits,
               :revenue_collected,
               :appointments,
               :doctor_notes,
               :lab_tests_done,
               :active_system_users,
               :mpesa_transactions
             ]
    end

    test "doctor sees only clinical cards" do
      assert WidgetResolver.summary_cards("doctor") == [
               :patient_visits,
               :appointments,
               :doctor_notes,
               :lab_tests_done
             ]
    end

    test "reception sees only front-desk cards" do
      assert WidgetResolver.summary_cards("reception") == [
               :total_patients,
               :patient_visits,
               :appointments,
               :active_system_users
             ]
    end

    test "pharmacist sees pharmacy stock, dispensing, and allocation cards" do
      assert WidgetResolver.summary_cards("pharmacist") == [
               :drug_catalog,
               :pharmacy_stock_units,
               :pharmacy_stock_value,
               :drug_allocations,
               :dispensed_units,
               :dispensed_value,
               :pending_drug_allocations,
               :low_stock_items
             ]
    end

    test "an unknown role sees no cards" do
      assert WidgetResolver.summary_cards("finance") == []
    end
  end

  describe "analytics_tabs/1" do
    test "admin sees all three tabs" do
      assert WidgetResolver.analytics_tabs("admin") == [:revenue, :patients, :operations]
    end

    test "doctor and reception never see revenue" do
      assert WidgetResolver.analytics_tabs("doctor") == [:patients, :operations]
      assert WidgetResolver.analytics_tabs("reception") == [:patients, :operations]
      refute :revenue in WidgetResolver.analytics_tabs("doctor")
      refute :revenue in WidgetResolver.analytics_tabs("reception")
    end

    test "an unknown role sees no tabs" do
      assert WidgetResolver.analytics_tabs("finance") == []
    end
  end

  describe "default_analytics_tab/1" do
    test "admin defaults to revenue" do
      assert WidgetResolver.default_analytics_tab("admin") == :revenue
    end

    test "doctor and reception default to patients" do
      assert WidgetResolver.default_analytics_tab("doctor") == :patients
      assert WidgetResolver.default_analytics_tab("reception") == :patients
    end

    test "an unknown role has no default tab" do
      assert WidgetResolver.default_analytics_tab("finance") == nil
    end
  end
end
