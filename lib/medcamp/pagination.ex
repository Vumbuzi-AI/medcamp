defmodule Medcamp.Pagination do
  @moduledoc false

  @default_per_page 10

  def normalize_page(page) when is_integer(page) and page > 0, do: page

  def normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _rest} when value > 0 -> value
      _ -> 1
    end
  end

  def normalize_page(_), do: 1

  def normalize_per_page(per_page) when is_integer(per_page) and per_page > 0, do: per_page

  def normalize_per_page(per_page) when is_binary(per_page) do
    case Integer.parse(per_page) do
      {value, _rest} when value > 0 -> value
      _ -> @default_per_page
    end
  end

  def normalize_per_page(_), do: @default_per_page

  def total_pages(total_count, per_page) do
    per_page = normalize_per_page(per_page)
    total_count = max(total_count || 0, 0)

    max(div(total_count + per_page - 1, per_page), 1)
  end

  def page_window(page, total_count, per_page) do
    page = normalize_page(page)
    per_page = normalize_per_page(per_page)
    total_count = max(total_count || 0, 0)

    from =
      if total_count == 0 do
        0
      else
        min((page - 1) * per_page + 1, total_count)
      end

    to = min(page * per_page, total_count)
    {from, to}
  end
end
