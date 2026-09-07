defmodule Medcamp.ObstetricCalculator do
  def calculate(lmp_date) do
    edd = Date.add(lmp_date, 280)

    conception_date = Date.add(lmp_date, 14)

    today = Date.utc_today()
    days_since_lmp = Date.diff(today, lmp_date)

    {weeks, remaining_days} = {div(days_since_lmp, 7), rem(days_since_lmp, 7)}
    current_gestational_age = "#{weeks} weeks #{remaining_days} days"

    first_trimester_end = Date.add(lmp_date, 12 * 7)

    second_trimester_end = Date.add(lmp_date, 24 * 7)

    trimester =
      cond do
        days_since_lmp < 0 -> 0
        days_since_lmp <= 12 * 7 -> 1
        days_since_lmp <= 24 * 7 -> 2
        true -> 3
      end

    viability_date = Date.add(lmp_date, 24 * 7)

    full_term_start = Date.add(lmp_date, 37 * 7)

    full_term_end = edd

    late_term_start = Date.add(lmp_date, 41 * 7)

    post_term_start = Date.add(lmp_date, 42 * 7)

    %{
      lmp: lmp_date,
      edd: edd,
      conception_date: conception_date,
      current_gestational_age: current_gestational_age,
      trimester: trimester,
      first_trimester_end: first_trimester_end,
      second_trimester_end: second_trimester_end,
      viability_date: viability_date,
      full_term_start: full_term_start,
      full_term_end: full_term_end,
      late_term_start: late_term_start,
      post_term_start: post_term_start
    }
  end
end
