defmodule Medcamp.Blogs.BlogSection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blog_sections" do
    field :title, :string
    field :body, :string
    field :quote, :string
    field :image_url, :string
    field :image_alt, :string
    field :image_caption, :string
    field :position, :integer, default: 0

    belongs_to :blog_post, Medcamp.Blogs.BlogPost

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blog_section, attrs) do
    blog_section
    |> cast(attrs, [:title, :body, :quote, :image_url, :image_alt, :image_caption, :position])
    |> validate_required([:position])
    |> validate_content_presence()
  end

  defp validate_content_presence(changeset) do
    values =
      [:body, :quote, :image_url]
      |> Enum.map(&get_field(changeset, &1))
      |> Enum.map(&normalize_string/1)

    if Enum.any?(values, &(&1 != nil and &1 != "")) do
      changeset
    else
      add_error(changeset, :body, "add body text, a quote, or an image for this section")
    end
  end

  defp normalize_string(nil), do: nil
  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end
