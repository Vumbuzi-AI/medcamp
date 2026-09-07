defmodule Medcamp.Repo.Migrations.CreateBlogs do
  use Ecto.Migration

  def change do
    create table(:blog_posts) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :category, :string, null: false
      add :author_name, :string, null: false
      add :excerpt, :text, null: false
      add :intro, :text
      add :hero_image_url, :text
      add :hero_image_alt, :string
      add :status, :string, null: false, default: "draft"
      add :published_at, :utc_datetime
      add :is_featured, :boolean, null: false, default: false
      add :author_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blog_posts, [:slug])
    create index(:blog_posts, [:status])
    create index(:blog_posts, [:author_id])
    create index(:blog_posts, [:published_at])

    create table(:blog_sections) do
      add :title, :string
      add :body, :text
      add :quote, :text
      add :image_url, :text
      add :image_alt, :string
      add :image_caption, :text
      add :position, :integer, null: false, default: 0
      add :blog_post_id, references(:blog_posts, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:blog_sections, [:blog_post_id])
    create index(:blog_sections, [:blog_post_id, :position])
  end
end
