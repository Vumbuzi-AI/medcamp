defmodule Medcamp.BlogsFixtures do
  @moduledoc """
  Test helpers for the `Medcamp.Blogs` context.
  """

  alias Medcamp.Blogs
  alias Medcamp.AccountsFixtures

  def blog_post_fixture(attrs \\ %{}) do
    author =
      Map.get(attrs, :author) ||
        AccountsFixtures.user_fixture(%{role: "doctor", name: "Dr. Blog Author"})

    attrs =
      attrs
      |> Map.delete(:author)
      |> Enum.into(%{
        "title" => "Clinic safety updates",
        "category" => "Patient Safety",
        "author_name" => author.name,
        "excerpt" => "Important updates from the GHCE clinical team.",
        "intro" => "A short summary for patients and families.",
        "status" => "published",
        "published_at" => "2026-05-26T09:00:00",
        "author_id" => author.id,
        "sections" => %{
          "0" => %{
            "title" => "What changed",
            "body" => "We improved follow-up workflows to make care clearer.",
            "position" => "0"
          }
        },
        "sections_sort" => ["0"],
        "sections_drop" => [""]
      })

    {:ok, blog_post} = Blogs.create_blog_post(attrs)
    blog_post
  end
end
