defmodule Medcamp.ExpiryFilterTest do
  use ExUnit.Case, async: true

  alias Medcamp.ExpiryFilter

  @today ~D[2026-07-28]

  describe "normalize/1" do
    test "keeps known statuses and rejects anything else" do
      assert ExpiryFilter.normalize("expired") == "expired"
      assert ExpiryFilter.normalize(:not_expired) == "not_expired"
      assert ExpiryFilter.normalize(nil) == ""
      assert ExpiryFilter.normalize("has_expired_batches") == ""
      assert ExpiryFilter.normalize(42) == ""
    end
  end

  describe "to_range/2" do
    test "expired ends the day before today" do
      assert ExpiryFilter.to_range("expired", @today) == {nil, "2026-07-27"}
    end

    test "expiring windows start today and are inclusive of the last day" do
      assert ExpiryFilter.to_range("expiring_30", @today) == {"2026-07-28", "2026-08-26"}
      assert ExpiryFilter.to_range("expiring_90", @today) == {"2026-07-28", "2026-10-25"}
    end

    test "not_expired starts today and is open-ended" do
      assert ExpiryFilter.to_range("not_expired", @today) == {"2026-07-28", nil}
    end

    test "no status restricts nothing" do
      assert ExpiryFilter.to_range("", @today) == {nil, nil}
    end
  end

  describe "bounds/4" do
    test "a custom range alone is used as given" do
      assert ExpiryFilter.bounds("", "2026-01-01", "2026-03-01", @today) ==
               {"2026-01-01", "2026-03-01"}
    end

    test "a custom date narrows a preset, never widens it" do
      # 2026-01-01 is before the preset's start, so the preset start wins.
      assert ExpiryFilter.bounds("not_expired", "2026-01-01", "", @today) ==
               {"2026-07-28", nil}

      assert ExpiryFilter.bounds("not_expired", "2026-09-01", "", @today) ==
               {"2026-09-01", nil}

      assert ExpiryFilter.bounds("expiring_90", "", "2026-08-15", @today) ==
               {"2026-07-28", "2026-08-15"}
    end

    test "blank and malformed dates are ignored" do
      assert ExpiryFilter.bounds("", "", "", @today) == {nil, nil}
      assert ExpiryFilter.bounds("", "not-a-date", nil, @today) == {nil, nil}
    end
  end

  describe "matches?/4" do
    test "no filter matches everything, including a missing expiry" do
      assert ExpiryFilter.matches?(nil, "")
      assert ExpiryFilter.matches?("2020-01-01", "")
    end

    test "a missing or unparseable expiry matches no active filter" do
      refute ExpiryFilter.matches?(nil, "expired")
      refute ExpiryFilter.matches?("", "not_expired")
      refute ExpiryFilter.matches?("whenever", "expired")
    end

    test "classifies dates against the preset" do
      past = Date.add(Date.utc_today(), -1)
      soon = Date.add(Date.utc_today(), 10)
      far = Date.add(Date.utc_today(), 200)

      assert ExpiryFilter.matches?(past, "expired")
      refute ExpiryFilter.matches?(past, "not_expired")

      assert ExpiryFilter.matches?(soon, "expiring_30")
      assert ExpiryFilter.matches?(soon, "not_expired")
      refute ExpiryFilter.matches?(soon, "expired")

      refute ExpiryFilter.matches?(far, "expiring_90")
      assert ExpiryFilter.matches?(far, "not_expired")
    end

    test "applies the custom range on top of the preset" do
      soon = Date.add(Date.utc_today(), 10)
      cutoff = Date.to_iso8601(Date.add(Date.utc_today(), 5))

      refute ExpiryFilter.matches?(soon, "expiring_30", "", cutoff)
      assert ExpiryFilter.matches?(soon, "expiring_30", "", Date.to_iso8601(soon))
    end

    test "accepts the non-ISO expiry strings found on batches" do
      assert {:ok, ~D[2027-06-30]} = ExpiryFilter.parse("30/6/2027")
      assert ExpiryFilter.matches?("30/6/2027", "not_expired")
    end
  end
end
