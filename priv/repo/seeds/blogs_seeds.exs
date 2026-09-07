# Run with:
#
#   mix run priv/repo/seeds/blogs_seeds.exs

alias Medcamp.Accounts
alias Medcamp.Blogs
alias Medcamp.Blogs.DefaultPosts

blog_author_email = "website.blogs@glocalhealthcentre.org"

blog_author =
  case Accounts.get_user_by_email(blog_author_email) do
    nil ->
      {:ok, user} =
        Accounts.register_user(%{
          "email" => blog_author_email,
          "password" => "ChangeMe123!",
          "name" => "GHCE Clinical Team",
          "role" => "doctor"
        })

      user

    user ->
      user
  end

build_sections = fn post ->
  post.sections
  |> Enum.with_index()
  |> Map.new(fn {section, section_index} ->
    {Integer.to_string(section_index),
     %{
       "title" => section[:title],
       "body" => section[:body],
       "quote" => section[:quote],
       "image_url" => section[:image_url],
       "image_alt" => section[:image_alt],
       "image_caption" => section[:image_caption],
       "position" => Integer.to_string(section_index)
     }}
  end)
end

build_attrs = fn post, index ->
  sections = build_sections.(post)

  %{
    "title" => post.title,
    "slug" => post.slug,
    "category" => post.category,
    "author_name" => post.author_name,
    "excerpt" => post.excerpt,
    "intro" => post.intro,
    "hero_image_url" => post.hero_image_url,
    "hero_image_alt" => post.hero_image_alt,
    "status" => post.status,
    "published_at" => DateTime.to_iso8601(post.published_at),
    "is_featured" => index == 0,
    "author_id" => blog_author.id,
    "sections" => sections,
    "sections_sort" => Map.keys(sections),
    "sections_drop" => [""]
  }
end

DefaultPosts.list()
|> Enum.take(3)
|> Enum.with_index()
|> Enum.each(fn {post, index} ->
  attrs = build_attrs.(post, index)

  case Blogs.get_blog_post_by_slug(post.slug) do
    nil ->
      {:ok, _blog_post} = Blogs.create_blog_post(attrs)

    blog_post ->
      {:ok, _blog_post} = Blogs.update_blog_post(blog_post, attrs)
  end
end)
