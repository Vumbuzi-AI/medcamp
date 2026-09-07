defmodule Medcamp.QualityAssurance.Chart do
  use Ecto.Schema
  import Ecto.Changeset

  @chart_types [
    "room_temperature",
    "fridge_temperature",
    "freezer_temperature",
    "electrolyte_analyzer",
    "hematology_analyzer",
    "biochemistry_analyzer",
    "centrifuge",
    "microscope",
    "bench_decontamination"
  ]

  schema "quality_assurance_charts" do
    field :chart_type, :string
    field :month, :integer
    field :year, :integer
    field :daily_entries, :map, default: %{}
    belongs_to :created_by, Medcamp.Accounts.User, foreign_key: :created_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chart, attrs) do
    chart
    |> cast(attrs, [:chart_type, :month, :year, :daily_entries, :created_by_id])
    |> validate_required([:chart_type, :month, :year])
    |> validate_inclusion(:chart_type, @chart_types)
    |> validate_inclusion(:month, 1..12)
    |> validate_number(:year, greater_than: 2020, less_than: 2100)
    |> unique_constraint([:chart_type, :month, :year], name: :unique_chart_per_month)
  end

  def chart_types, do: @chart_types

  def chart_type_label("room_temperature"), do: "Room Temperature Monitor Chart"
  def chart_type_label("fridge_temperature"), do: "Fridge Temperature Monitor Chart"
  def chart_type_label("freezer_temperature"), do: "Freezer Temperature Monitor Chart"
  def chart_type_label("electrolyte_analyzer"), do: "Electrolyte Analyzer Maintenance Chart"
  def chart_type_label("hematology_analyzer"), do: "Hematology Analyzer Maintenance Chart"
  def chart_type_label("biochemistry_analyzer"), do: "Biochemistry Analyzer Maintenance Chart"
  def chart_type_label("centrifuge"), do: "Centrifuge Maintenance Chart"
  def chart_type_label("microscope"), do: "Microscope Maintenance Chart"
  def chart_type_label("bench_decontamination"), do: "Bench Decontamination Chart"
  def chart_type_label(_), do: "Unknown Chart"

  def is_temperature_chart?(chart_type) do
    chart_type in ["room_temperature", "fridge_temperature", "freezer_temperature"]
  end

  def temperature_status_text("room_temperature") do
    "Temperature Status: Normal 18 - 25 °C | Low < 18 °C | High > 25 °C"
  end

  def temperature_status_text("fridge_temperature") do
    "Temperature Status: Normal 2 - 8 °C | Low < 2 °C | High > 8 °C"
  end

  def temperature_status_text("freezer_temperature") do
    "Temperature Status: Normal <= -15 °C | High > -15 °C"
  end

  def temperature_status_text(_) do
    "Temperature Status: Normal | Low | High"
  end

  def maintenance_tasks("electrolyte_analyzer") do
    [
      "Dust and clean surface",
      "Perform analyzer start-up/priming",
      "Perform probe cleansing",
      "Perform daily wash",
      "Run and review calibration",
      "Run and review controls",
      "Check the power supply"
    ]
  end

  def maintenance_tasks("hematology_analyzer") do
    [
      "Clean probe with methylated spirit",
      "Dust and clean surface of the equipment",
      "Check/empty waste",
      "Perform priming",
      "Run and review background",
      "Run and review control",
      "Check power supply"
    ]
  end

  def maintenance_tasks("biochemistry_analyzer") do
    [
      "Dust and clean surface",
      "Check water level",
      "Check/empty waste",
      "Perform analyzer start up/ priming",
      "Run and review background",
      "Run and review controls",
      "Check the power supply"
    ]
  end

  def maintenance_tasks("centrifuge") do
    [
      "Check the general cleanliness",
      "Check the cups",
      "Check the on/off knob",
      "Check speed knop",
      "Check the timer knob",
      "Ensure the stability of the machine",
      "Check the power supply"
    ]
  end

  def maintenance_tasks("microscope") do
    [
      "Check optics for damage",
      "Check coarse/fine adjustment",
      "Dust/clean components",
      "Clean external surfaces",
      "Remove oil",
      "Replace bulbs as needed",
      "Microscope covered after use"
    ]
  end

  def maintenance_tasks("bench_decontamination") do
    [
      "Check general cleanliness",
      "Wipe benches with 5% sodium hypochlorite",
      "General cleaning"
    ]
  end

  def maintenance_tasks(_), do: []
end
