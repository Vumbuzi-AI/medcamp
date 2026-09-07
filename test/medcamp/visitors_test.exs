defmodule Medcamp.VisitorsTest do
  use Medcamp.DataCase

  alias Medcamp.Visitors

  describe "visitors paginated and count" do
    test "list_visitor_book_entries_paginated/1 accepts keyword lists and maps" do
      assert is_list(Visitors.list_visitor_book_entries_paginated(search: "test"))
      assert is_list(Visitors.list_visitor_book_entries_paginated(%{search: "test"}))
    end

    test "count_visitor_book_entries/1 accepts keyword lists and maps" do
      assert is_integer(Visitors.count_visitor_book_entries(search: "test"))
      assert is_integer(Visitors.count_visitor_book_entries(%{search: "test"}))
    end

    test "count_distinct_visitor_recorders/1 accepts keyword lists and maps" do
      assert is_integer(Visitors.count_distinct_visitor_recorders(search: "test"))
      assert is_integer(Visitors.count_distinct_visitor_recorders(%{search: "test"}))
    end
  end
end
