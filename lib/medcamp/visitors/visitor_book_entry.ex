defmodule Medcamp.Visitors.VisitorBookEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @utc_offset_seconds 3 * 60 * 60

  schema "visitor_book_entries" do
    field :visitor_name, :string
    field :phone_number, :string
    field :person_to_see, :string
    field :purpose, :string
    field :message, :string
    field :visited_on, :date
    field :visited_at, :time

    belongs_to :user, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @required_fields [:visitor_name, :message, :visited_on, :visited_at, :user_id]
  @optional_fields [:phone_number, :person_to_see, :purpose]

  def changeset(visitor_book_entry, attrs) do
    attrs = with_visit_defaults(attrs)

    visitor_book_entry
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:visitor_name, min: 2, max: 120)
    |> validate_length(:phone_number, max: 30)
    |> validate_length(:person_to_see, max: 120)
    |> validate_length(:purpose, max: 160)
    |> validate_length(:message, min: 3, max: 2_000)
    |> foreign_key_constraint(:user_id)
  end

  def current_visit_defaults do
    local_now = current_local_datetime()

    %{
      "visited_on" => local_now |> DateTime.to_date() |> Date.to_string(),
      "visited_at" =>
        local_now |> DateTime.to_time() |> Time.truncate(:second) |> Calendar.strftime("%H:%M")
    }
  end

  defp with_visit_defaults(attrs) when is_map(attrs) do
    defaults = current_visit_defaults()

    attrs
    |> put_default_attr("visited_on", defaults["visited_on"])
    |> put_default_attr("visited_at", defaults["visited_at"])
  end

  defp current_local_datetime do
    DateTime.utc_now()
    |> DateTime.add(@utc_offset_seconds, :second)
    |> DateTime.truncate(:second)
  end

  defp put_default_attr(attrs, key, default) do
    atom_key = String.to_existing_atom(key)
    string_value = Map.get(attrs, key)
    atom_value = Map.get(attrs, atom_key)

    cond do
      string_value not in [nil, ""] -> attrs
      atom_value not in [nil, ""] -> attrs
      Map.has_key?(attrs, atom_key) -> Map.put(attrs, atom_key, default)
      true -> Map.put(attrs, key, default)
    end
  end
end
