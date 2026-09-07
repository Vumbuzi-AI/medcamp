defmodule Medcamp.BlogsTest do
  use Medcamp.DataCase, async: true

  import Medcamp.BlogsFixtures
  import Medcamp.AccountsFixtures

  alias Medcamp.Blogs

  describe "blog posts" do
    test "creates a blog post with ordered sections and a generated slug" do
      author = user_fixture(%{role: "doctor", name: "Dr. Writer"})

      attrs = %{
        "title" => "A Doctor's Guide to Follow-Up Visits",
        "slug" => "",
        "category" => "Patient Guide",
        "author_name" => author.name,
        "excerpt" => "Why follow-up visits matter after treatment.",
        "status" => "published",
        "author_id" => author.id,
        "sections" => %{
          "0" => %{
            "title" => "Start Here",
            "body" => "Follow-up visits help us check recovery.",
            "position" => "0"
          }
        },
        "sections_sort" => ["0"],
        "sections_drop" => [""]
      }

      assert {:ok, blog_post} = Blogs.create_blog_post(attrs)
      assert blog_post.slug == "a-doctor-s-guide-to-follow-up-visits"
      assert blog_post.status == "published"
      assert blog_post.published_at
      assert [%{title: "Start Here"}] = blog_post.sections
      assert Blogs.get_blog_post_by_slug(blog_post.slug).id == blog_post.id
    end

    test "lists published posts for the public site" do
      published_post = blog_post_fixture(%{"title" => "Published story"})
      _draft_post = blog_post_fixture(%{"title" => "Draft story", "status" => "draft"})

      posts = Blogs.list_public_blog_posts()

      assert Enum.any?(posts, &(&1.id == published_post.id))
      refute Enum.any?(posts, &(&1.title == "Draft story"))
    end
  end
end
