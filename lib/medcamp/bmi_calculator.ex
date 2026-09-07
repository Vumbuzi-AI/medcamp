defmodule BMICalculator do
  def calculate(height_cm, weight_kg) when height_cm > 0 and weight_kg > 0 do
    height_m = height_cm / 100

    bmi = weight_kg / (height_m * height_m)

    Float.round(bmi, 2)
  end

  def calculate(_, _) do
    nil
  end
end
