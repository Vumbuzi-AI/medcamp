defmodule Medcamp.Blogs.BlogPost do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft published archived)

  schema "blog_posts" do
    field :title, :string
    field :slug, :string
    field :category, :string
    field :author_name, :string
    field :excerpt, :string
    field :intro, :string
    field :hero_image_url, :string
    field :hero_image_alt, :string
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime
    field :is_featured, :boolean, default: false

    belongs_to :author, Medcamp.Accounts.User, foreign_key: :author_id

    has_many :sections, Medcamp.Blogs.BlogSection,
      on_replace: :delete,
      preload_order: [asc: :position, asc: :id]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blog_post, attrs) do
    attrs = normalize_published_at(attrs)

    blog_post
    |> cast(attrs, [
      :title,
      :slug,
      :category,
      :author_name,
      :excerpt,
      :intro,
      :hero_image_url,
      :hero_image_alt,
      :status,
      :published_at,
      :is_featured,
      :author_id
    ])
    |> normalize_slug()
    |> maybe_set_published_at()
    |> validate_required([:title, :slug, :category, :author_name, :excerpt, :status, :author_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:title, max: 255)
    |> validate_length(:slug, max: 255)
    |> validate_length(:category, max: 255)
    |> validate_length(:author_name, max: 255)
    |> unique_constraint(:slug)
    |> cast_assoc(:sections,
      with: &Medcamp.Blogs.BlogSection.changeset/2,
      sort_param: :sections_sort,
      drop_param: :sections_drop
    )
    |> validate_sections_present()
  end

  def statuses, do: @statuses

  defp normalize_published_at(attrs) when is_map(attrs) do
    attrs
    |> normalize_published_at_key("published_at")
    |> normalize_published_at_key(:published_at)
  end

  defp normalize_published_at(attrs), do: attrs

  defp normalize_published_at_key(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, value} -> put_normalized_published_at(attrs, key, value)
      :error -> attrs
    end
  end

  defp put_normalized_published_at(attrs, key, value) when is_binary(value) do
    value = String.trim(value)

    cond do
      value == "" ->
        Map.delete(attrs, key)

      true ->
        case datetime_local_to_utc(value) do
          {:ok, published_at} -> Map.put(attrs, key, published_at)
          :error -> attrs
        end
    end
  end

  defp put_normalized_published_at(attrs, _key, _value), do: attrs

  defp normalize_slug(changeset) do
    slug =
      changeset
      |> get_field(:slug)
      |> normalize_text()

    title =
      changeset
      |> get_field(:title)
      |> normalize_text()

    slug =
      cond do
        slug not in [nil, ""] -> slug
        title not in [nil, ""] -> title
        true -> nil
      end

    case slug do
      nil ->
        changeset

      value ->
        put_change(changeset, :slug, slugify(value))
    end
  end

  defp maybe_set_published_at(changeset) do
    status = get_field(changeset, :status)
    published_at = get_field(changeset, :published_at)

    if status == "published" and is_nil(published_at) do
      put_change(changeset, :published_at, DateTime.utc_now() |> DateTime.truncate(:second))
    else
      changeset
    end
  end

  defp validate_sections_present(changeset) do
    sections = get_field(changeset, :sections, [])

    if Enum.empty?(sections) do
      add_error(changeset, :sections, "add at least one section")
    else
      changeset
    end
  end

  defp normalize_text(nil), do: nil
  defp normalize_text(value) when is_binary(value), do: String.trim(value)
  defp normalize_text(value), do: value

  defp datetime_local_to_utc(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        {:ok, DateTime.truncate(datetime, :second)}

      {:error, _reason} ->
        with {:ok, naive_datetime} <- parse_datetime(value) do
          {:ok,
           naive_datetime
           |> NaiveDateTime.add(-3 * 60 * 60, :second)
           |> DateTime.from_naive!("Etc/UTC")
           |> DateTime.truncate(:second)}
        end
    end
  end

  defp parse_datetime(value) do
    value =
      if value =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/ do
        value <> ":00"
      else
        value
      end

    case NaiveDateTime.from_iso8601(value) do
      {:ok, naive_datetime} -> {:ok, NaiveDateTime.truncate(naive_datetime, :second)}
      {:error, _reason} -> :error
    end
  end

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end
end
