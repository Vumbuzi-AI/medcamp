defmodule Medcamp.QualityAssurance.ChartTest do
  use ExUnit.Case, async: true

  alias Medcamp.QualityAssurance.Chart

  describe "chart types" do
    test "freezer temperature is an accepted temperature chart" do
      assert "freezer_temperature" in Chart.chart_types()
      assert Chart.chart_type_label("freezer_temperature") == "Freezer Temperature Monitor Chart"
      assert Chart.is_temperature_chart?("freezer_temperature")

      changeset =
        Chart.changeset(%Chart{}, %{
          chart_type: "freezer_temperature",
          month: 5,
          year: 2026,
          daily_entries: %{}
        })

      assert changeset.valid?
    end

    test "temperature status text is chart-specific" do
      assert Chart.temperature_status_text("room_temperature") =~ "Normal 18 - 25 °C"
      assert Chart.temperature_status_text("fridge_temperature") =~ "Normal 2 - 8 °C"
      assert Chart.temperature_status_text("freezer_temperature") =~ "Normal <= -15 °C"
    end
  end
end
