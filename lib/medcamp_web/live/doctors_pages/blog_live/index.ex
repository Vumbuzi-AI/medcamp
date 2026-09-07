defmodule MedcampWeb.DoctorBlogLive.Index do
  use MedcampWeb, :doctor_live_view

  alias Medcamp.Blogs
  alias Medcamp.Blogs.BlogPost
  alias Medcamp.Blogs.BlogSection
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :blogs)
     |> assign_blog_posts()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"blog_post" => blog_post_params}, socket) do
    changeset =
      socket.assigns.blog_post
      |> Blogs.change_blog_post(blog_post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"blog_post" => blog_post_params}, socket) do
    blog_post_params =
      blog_post_params
      |> Map.put("author_id", socket.assigns.current_user.id)
      |> Map.put_new("author_name", socket.assigns.current_user.name || "GHCE Clinical Team")

    save_blog_post(socket, socket.assigns.live_action, blog_post_params)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    blog_post = Blogs.get_blog_post!(id)

    case Blogs.delete_blog_post(blog_post, audit_user_id: socket.assigns.current_user.id) do
      {:ok, _deleted_blog_post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Blog deleted successfully.")
         |> assign_blog_posts()
         |> push_patch(to: ~p"/doctor/blogs")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to delete this blog right now.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <section class="rounded-2xl bg-gradient-to-r from-sky-600 to-cyan-600 p-8 text-white shadow-lg">
        <div class="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p class="text-sm font-semibold uppercase tracking-[0.16em] text-white/75">
              Doctor Publishing
            </p>
            <h1 class="mt-3 text-3xl font-bold">Manage Website Blogs</h1>
            <p class="mt-3 max-w-2xl text-sm leading-6 text-white/85">
              Add blog stories that match the public website layout, including excerpts, hero
              images, and ordered content sections.
            </p>
          </div>

          <.link
            :if={@live_action == :index}
            navigate={~p"/doctor/blogs/new"}
            class="inline-flex items-center justify-center rounded-xl bg-white px-5 py-3 text-sm font-semibold text-sky-700 shadow-sm transition hover:-translate-y-0.5"
          >
            New Blog Post
          </.link>
        </div>
      </section>

      <%= if @live_action == :index do %>
        <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between gap-4 border-b border-slate-100 pb-4">
            <div>
              <h2 class="text-lg font-semibold text-slate-900">Saved Blogs</h2>
              <p class="text-sm text-slate-500">
                Public blog content is now driven from the database whenever posts exist.
              </p>
            </div>
            <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
              {length(@blog_posts)} posts
            </span>
          </div>

          <div :if={Enum.empty?(@blog_posts)} class="py-16 text-center text-slate-500">
            <p class="text-lg font-medium text-slate-700">No blogs yet</p>
            <p class="mt-2 text-sm">Create your first post on the dedicated blog page.</p>
          </div>

          <div :if={!Enum.empty?(@blog_posts)} class="mt-5 space-y-4">
            <div
              :for={blog_post <- @blog_posts}
              id={"blog-post-#{blog_post.id}"}
              class="rounded-2xl border border-slate-200 p-4 transition hover:border-sky-200 hover:shadow-sm"
            >
              <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <span class={status_badge_class(blog_post.status)}>
                      {String.capitalize(blog_post.status)}
                    </span>
                    <span
                      :if={blog_post.is_featured}
                      class="rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-700"
                    >
                      Featured
                    </span>
                  </div>
                  <h3 class="mt-3 text-lg font-semibold text-slate-900">{blog_post.title}</h3>
                  <p class="mt-1 text-sm text-slate-500">
                    {blog_post.category} • {blog_post.author_name} • {formatted_date(blog_post)}
                  </p>
                  <p class="mt-3 text-sm leading-6 text-slate-600">{blog_post.excerpt}</p>
                  <div class="mt-3 flex flex-wrap gap-3 text-xs font-medium text-slate-500">
                    <span>Slug: /post/{blog_post.slug}</span>
                    <span>{length(blog_post.sections)} sections</span>
                  </div>
                </div>

                <div class="flex flex-wrap items-center gap-3">
                  <a
                    :if={blog_post.status == "published"}
                    href={public_post_path(blog_post)}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="inline-flex items-center rounded-xl border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:border-sky-200 hover:text-sky-700"
                  >
                    View
                  </a>
                  <.link
                    navigate={~p"/doctor/blogs/#{blog_post.id}/edit"}
                    class="inline-flex items-center rounded-xl bg-slate-900 px-4 py-2 text-sm font-medium text-white transition hover:bg-slate-700"
                  >
                    Edit
                  </.link>
                  <button
                    type="button"
                    phx-click="delete"
                    phx-value-id={blog_post.id}
                    data-confirm="Delete this blog post?"
                    class="inline-flex items-center rounded-xl border border-rose-200 px-4 py-2 text-sm font-medium text-rose-600 transition hover:bg-rose-50"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          </div>
        </section>
      <% else %>
        <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex flex-col gap-4 border-b border-slate-100 pb-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h2 class="text-lg font-semibold text-slate-900">{@page_title}</h2>
              <p class="text-sm text-slate-500">
                Create the full blog on this page. Use image URLs only for the hero and section images.
              </p>
            </div>
            <.link
              navigate={~p"/doctor/blogs"}
              class="inline-flex items-center justify-center rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
            >
              Back to Blogs
            </.link>
          </div>

          <.simple_form
            for={@form}
            id="blog-post-form"
            phx-change="validate"
            phx-submit="save"
            class="mt-5 space-y-6"
          >
            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:title]} type="text" label="Title" required />
              <.input
                field={@form[:slug]}
                type="text"
                label="Slug"
                placeholder="auto-generated from title"
              />
              <.input field={@form[:category]} type="text" label="Category" required />
              <.input field={@form[:author_name]} type="text" label="Display Author" required />
            </div>

            <.input field={@form[:excerpt]} type="textarea" label="Excerpt" required rows="4" />
            <.input field={@form[:intro]} type="textarea" label="Intro" rows="4" />

            <div class="grid gap-4 md:grid-cols-2">
              <.input
                field={@form[:status]}
                type="select"
                label="Status"
                options={Enum.map(BlogPost.statuses(), &{String.capitalize(&1), &1})}
              />
              <.input field={@form[:published_at]} type="datetime-local" label="Published At" />
            </div>

            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:hero_image_alt]} type="text" label="Hero Image Alt Text" />
              <.input
                field={@form[:hero_image_url]}
                type="url"
                label="Hero Image URL"
                placeholder="https://..."
              />
            </div>

            <.input field={@form[:is_featured]} type="checkbox" label="Feature this post" />

            <div class="space-y-4">
              <div class="flex items-center justify-between gap-4">
                <div>
                  <h3 class="text-sm font-semibold text-slate-900">Sections</h3>
                  <p class="text-sm text-slate-500">
                    Each section can hold a heading, body text, a quote, and optional image URLs.
                  </p>
                </div>
                <button
                  type="button"
                  name="blog_post[sections_sort][]"
                  value="new"
                  phx-click={JS.dispatch("change")}
                  class="inline-flex items-center rounded-xl bg-sky-100 px-4 py-2 text-sm font-semibold text-sky-700 transition hover:bg-sky-200"
                >
                  Add Section
                </button>
              </div>

              <input type="hidden" name="blog_post[sections_drop][]" />

              <div :for={error <- @form[:sections].errors} class="text-sm text-rose-600">
                {translate_error(error)}
              </div>

              <div class="space-y-5">
                <.inputs_for :let={section_form} field={@form[:sections]}>
                  <div class="rounded-2xl border border-slate-200 p-4">
                    <div class="mb-4 flex items-center justify-between gap-3">
                      <h4 class="text-sm font-semibold text-slate-900">
                        Section {section_form.index + 1}
                      </h4>
                      <button
                        type="button"
                        name="blog_post[sections_drop][]"
                        value={section_form.index}
                        phx-click={JS.dispatch("change")}
                        class="inline-flex items-center rounded-xl border border-rose-200 px-3 py-2 text-xs font-semibold text-rose-600 transition hover:bg-rose-50"
                      >
                        Remove
                      </button>
                    </div>

                    <input type="hidden" name="blog_post[sections_sort][]" value={section_form.index} />
                    <input
                      type="hidden"
                      name={section_form[:position].name}
                      value={section_form.index}
                    />

                    <div class="space-y-4">
                      <.input field={section_form[:title]} type="text" label="Section Heading" />
                      <.input
                        field={section_form[:body]}
                        type="textarea"
                        label="Body"
                        rows="5"
                        placeholder="Use blank lines between paragraphs."
                      />
                      <.input field={section_form[:quote]} type="textarea" label="Quote" rows="3" />
                      <.input
                        field={section_form[:image_url]}
                        type="url"
                        label="Section Image URL"
                        placeholder="https://..."
                      />
                      <.input
                        field={section_form[:image_alt]}
                        type="text"
                        label="Section Image Alt Text"
                      />
                      <.input
                        field={section_form[:image_caption]}
                        type="text"
                        label="Section Image Caption"
                      />
                    </div>
                  </div>
                </.inputs_for>
              </div>
            </div>

            <:actions>
              <div class="flex w-full flex-col gap-3 sm:flex-row sm:justify-end">
                <.link
                  navigate={~p"/doctor/blogs"}
                  class="inline-flex items-center justify-center rounded-xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
                >
                  Cancel
                </.link>
                <.button
                  phx-disable-with="Saving..."
                  class="rounded-xl bg-slate-900 px-5 py-3 text-sm font-semibold text-white hover:bg-slate-700"
                >
                  Save Blog Post
                </.button>
              </div>
            </:actions>
          </.simple_form>
        </section>
      <% end %>
    </div>
    """
  end

  defp apply_action(socket, :new, _params) do
    blog_post = new_blog_post(socket.assigns.current_user)

    socket
    |> assign(:page_title, "New Blog Post")
    |> assign(:blog_post, blog_post)
    |> assign(:form, to_form(Blogs.change_blog_post(blog_post)))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    blog_post = Blogs.get_blog_post!(id)

    socket
    |> assign(:page_title, "Edit Blog Post")
    |> assign(:blog_post, blog_post)
    |> assign(:form, to_form(Blogs.change_blog_post(blog_post)))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Manage Website Blogs")
    |> assign(:blog_post, nil)
    |> assign(:form, nil)
  end

  defp assign_blog_posts(socket) do
    assign(socket, :blog_posts, Blogs.list_blog_posts())
  end

  defp save_blog_post(socket, :new, blog_post_params) do
    case Blogs.create_blog_post(blog_post_params, audit_user_id: socket.assigns.current_user.id) do
      {:ok, _blog_post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Blog created successfully.")
         |> assign_blog_posts()
         |> push_navigate(to: ~p"/doctor/blogs")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_blog_post(socket, :index, blog_post_params),
    do: save_blog_post(socket, :new, blog_post_params)

  defp save_blog_post(socket, :edit, blog_post_params) do
    case Blogs.update_blog_post(
           socket.assigns.blog_post,
           blog_post_params,
           audit_user_id: socket.assigns.current_user.id
         ) do
      {:ok, _blog_post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Blog updated successfully.")
         |> assign_blog_posts()
         |> push_navigate(to: ~p"/doctor/blogs")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp new_blog_post(current_user) do
    %BlogPost{
      author_id: current_user.id,
      author_name: current_user.name || "GHCE Clinical Team",
      status: "draft",
      sections: [%BlogSection{position: 0}]
    }
  end

  defp status_badge_class("published"),
    do: "rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-700"

  defp status_badge_class("archived"),
    do: "rounded-full bg-slate-200 px-3 py-1 text-xs font-semibold text-slate-600"

  defp status_badge_class(_status),
    do: "rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-700"

  defp formatted_date(blog_post) do
    Blogs.format_published_at(blog_post.published_at) || "Unscheduled"
  end

  defp public_post_path(blog_post), do: "/post/#{blog_post.slug}"
end
