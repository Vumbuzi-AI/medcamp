defmodule Medcamp.Blogs do
  @moduledoc """
  The Blogs context.
  """

  import Ecto.Query, warn: false

  alias Medcamp.Blogs.BlogPost
  alias Medcamp.Repo

  def list_blog_posts do
    BlogPost
    |> preload([:author, :sections])
    |> order_by([blog_post], desc: blog_post.published_at, desc: blog_post.inserted_at)
    |> Repo.all()
  end

  def list_published_blog_posts(opts \\ []) do
    limit = Keyword.get(opts, :limit)

    BlogPost
    |> where([blog_post], blog_post.status == "published")
    |> preload([:author, :sections])
    |> order_by([blog_post], desc: blog_post.published_at, desc: blog_post.inserted_at)
    |> maybe_limit(limit)
    |> Repo.all()
  end

  def get_blog_post!(id) do
    BlogPost
    |> preload([:author, :sections])
    |> Repo.get!(id)
  end

  def get_blog_post_by_slug(slug) when is_binary(slug) do
    BlogPost
    |> where([blog_post], blog_post.slug == ^slug)
    |> preload([:author, :sections])
    |> Repo.one()
  end

  def get_blog_post_by_slug(_slug), do: nil

  def create_blog_post(attrs \\ %{}, opts \\ []) do
    %BlogPost{}
    |> BlogPost.changeset(attrs)
    |> Repo.audited_insert(opts)
  end

  def update_blog_post(%BlogPost{} = blog_post, attrs, opts \\ []) do
    blog_post
    |> BlogPost.changeset(attrs)
    |> Repo.audited_update(opts)
  end

  def delete_blog_post(%BlogPost{} = blog_post, opts \\ []) do
    Repo.audited_delete(blog_post, opts)
  end

  def change_blog_post(%BlogPost{} = blog_post, attrs \\ %{}) do
    BlogPost.changeset(blog_post, attrs)
  end

  def list_public_blog_posts(opts \\ []) do
    list_published_blog_posts(opts)
  end

  def get_public_blog_post_by_slug(slug) do
    BlogPost
    |> where([blog_post], blog_post.slug == ^slug and blog_post.status == "published")
    |> preload([:author, :sections])
    |> Repo.one()
  end

  def featured_public_blog_post do
    list_public_blog_posts(limit: 1)
    |> List.first()
  end

  def related_public_blog_posts(post, limit \\ 3) do
    slug = Map.get(post, :slug)

    list_public_blog_posts()
    |> Enum.reject(&(Map.get(&1, :slug) == slug))
    |> Enum.take(limit)
  end

  def format_published_at(%DateTime{} = published_at) do
    Calendar.strftime(published_at, "%B %Y")
  end

  def format_published_at(nil), do: nil
  def format_published_at(value) when is_binary(value), do: value

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)
end
