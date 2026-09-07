defmodule MedcampWeb.Website.BlogLive do
  use Phoenix.LiveView, layout: false
  import MedcampWeb.PublicSiteComponents

  alias Medcamp.Blogs

  @page_title "Blogs & Insights | GHCE — Quality Care at Kisaju"
  @body_class "bg-gradient-to-b from-[#cfd0fb] via-[#e9ebff] to-white antialiased"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, @page_title)
     |> assign(:body_class, @body_class)
     |> assign(:selected_post, nil)
     |> assign(:related_posts, [])
     |> assign(:all_posts, Blogs.list_public_blog_posts())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case params["slug"] do
      nil ->
        {:noreply,
         socket
         |> assign(:selected_post, nil)
         |> assign(:related_posts, [])
         |> assign(:page_title, @page_title)}

      slug ->
        case Blogs.get_public_blog_post_by_slug(slug) do
          nil ->
            {:noreply,
             socket
             |> assign(:selected_post, nil)
             |> assign(:related_posts, [])
             |> assign(:page_title, @page_title)}

          post ->
            {:noreply,
             socket
             |> assign(:selected_post, post)
             |> assign(:related_posts, Blogs.related_public_blog_posts(post))
             |> assign(:page_title, page_title_for(post))}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="top" class={["min-h-screen", public_page_background_class()]}>
      <.public_navbar current_page={:blog} />
      <script
        src="https://gs1kenya.org/embed/chatbot.js"
        data-product-id="4"
        data-api-key="public"
        data-api-base="https://gs1kenya.org"
        async
      >
      </script>

      <main :if={is_nil(@selected_post)}>
        <.list_hero />
        <.list_articles posts={@all_posts} />
        <.appointment_section />
      </main>

      <main :if={@selected_post}>
        <.post_detail post={@selected_post} related={@related_posts} />
      </main>

      <.public_footer current_page={:blog} />

      <a
        href="#top"
        aria-label="Back to top"
        class="fixed bottom-4 right-4 z-40 flex h-10 w-10 items-center justify-center rounded-md border border-[#cfd0fb] bg-white no-underline shadow-lg hover:bg-[#cfd0fb] sm:bottom-5 sm:right-5 sm:h-11 sm:w-11"
      >
        <svg
          viewBox="0 0 24 24"
          aria-hidden="true"
          class="h-5 w-5"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="m18 15-6-6-6 6" />
        </svg>
      </a>
    </div>
    """
  end

  defp list_hero(assigns) do
    ~H"""
    <section class="overflow-hidden border-b border-[#cfd0fb] bg-white">
      <div class="mx-auto grid max-w-7xl gap-10 px-4 py-16 sm:px-6 md:py-20 lg:grid-cols-[0.9fr_1.1fr] lg:px-8">
        <div class="flex flex-col justify-center">
          <p class="text-sm font-bold uppercase tracking-wide">
            GHCE Knowledge Hub
          </p>
          <h1 class="mt-4 max-w-3xl text-4xl font-bold leading-[1.04] sm:text-5xl lg:text-6xl">
            Blogs &amp; Insights
          </h1>
          <p class="mt-6 max-w-2xl text-base leading-7 sm:text-lg sm:leading-8">
            Visit our knowledge hub for the latest insights and updates in healthcare.
          </p>
          <div class="mt-8 flex flex-col gap-3 sm:flex-row">
            <a
              href="#articles"
              class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-[#cfd0fb] px-6 py-3 font-semibold no-underline shadow-sm hover:bg-white"
            >
              Explore Articles
            </a>
            <a
              href="#appointment"
              class="inline-flex items-center justify-center rounded-md border border-[#cfd0fb] bg-white px-6 py-3 font-semibold no-underline hover:bg-[#cfd0fb]"
            >
              Book Appointment
            </a>
          </div>
        </div>
        <div class="relative min-h-[280px] sm:min-h-[360px]">
          <img
            src="/images/public/african-clinician-research.png"
            alt="African clinician reviewing healthcare research on a laptop"
            class="h-full min-h-[280px] w-full rounded-lg object-cover shadow-2xl sm:min-h-[360px]"
          />
          <div class="absolute bottom-4 left-4 right-4 rounded-lg bg-white p-4 shadow-xl backdrop-blur sm:bottom-5 sm:left-auto sm:right-5 sm:w-80 sm:p-5">
            <p class="text-sm font-semibold uppercase">Clear medical guidance</p>
            <p class="mt-2 text-xl font-bold sm:text-2xl">
              Practical answers for everyday health decisions
            </p>
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :posts, :list, required: true

  defp list_articles(assigns) do
    ~H"""
    <section id="articles" class="py-16 sm:py-20">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-3xl text-center">
          <p class="text-sm font-bold uppercase tracking-wide">Featured Articles</p>
          <h2 class="mt-3 text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
            Healthcare insights you can use today.
          </h2>
          <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
            Read concise, clinician-informed guidance on symptoms, prevention, nutrition, mental health, and daily wellness.
          </p>
        </div>

        <div :if={@posts == []} class="mt-16 text-center">
          No articles published yet. Check back soon.
        </div>

        <div :if={@posts != []} class="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          <article
            :for={post <- @posts}
            class="overflow-hidden rounded-lg border border-[#cfd0fb] bg-white shadow-sm"
          >
            <a href={"/post/#{post.slug}"} class="group block no-underline">
              <img
                :if={post.hero_image_url}
                src={post.hero_image_url}
                alt={post.hero_image_alt || post.title}
                class="h-56 w-full object-cover transition duration-300 group-hover:scale-[1.03]"
                loading="lazy"
              />
              <div class="p-5">
                <div class="flex items-center gap-2 text-sm font-semibold">
                  <svg
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                    class="h-4 w-4"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M8 2v4" />
                    <path d="M16 2v4" />
                    <rect x="3" y="4" width="18" height="18" rx="2" />
                    <path d="M3 10h18" />
                  </svg>
                  {published_label(post)}
                </div>
                <h3 class="mt-3 text-2xl font-bold leading-tight group-hover:opacity-80">
                  {post.title}
                </h3>
                <p :if={present?(post.excerpt)} class="mt-3 leading-7">
                  {post.excerpt}
                </p>
                <span class="mt-5 inline-flex items-center gap-2 font-semibold">
                  Read article
                  <svg
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                    class="h-4 w-4"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M5 12h14" />
                    <path d="m12 5 7 7-7 7" />
                  </svg>
                </span>
              </div>
            </a>
          </article>
        </div>
      </div>
    </section>
    """
  end

  attr :post, :map, required: true
  attr :related, :list, required: true

  defp post_detail(assigns) do
    ~H"""
    <section class="overflow-hidden border-b border-[#cfd0fb] bg-white">
      <div class="mx-auto max-w-3xl px-4 py-16 text-center sm:px-6 md:py-20 lg:px-8">
        <p :if={present?(@post.category)} class="text-sm font-bold uppercase tracking-wide">
          {@post.category}
        </p>
        <h1 class="mt-4 text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
          {@post.title}
        </h1>
        <div class="mt-6 flex flex-col items-center justify-center gap-2 text-sm md:flex-row md:gap-6">
          <span :if={present?(@post.author_name)}>{@post.author_name}</span>
          <span :if={present?(@post.author_name)} class="hidden h-5 w-px bg-[#cfd0fb] md:block">
          </span>
          <span>{published_label(@post)}</span>
        </div>
      </div>
    </section>

    <section class="py-12 sm:py-16">
      <div class="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <div :if={@post.hero_image_url} class="overflow-hidden rounded-lg shadow-sm">
          <img
            src={@post.hero_image_url}
            alt={@post.hero_image_alt || @post.title}
            class="h-64 w-full object-cover sm:h-[300px] md:h-[460px]"
          />
        </div>

        <article class="mt-10 space-y-8 text-base leading-7 sm:text-lg sm:leading-8">
          <p :if={present?(@post.intro)} class="text-lg leading-7 sm:text-xl sm:leading-8">
            {@post.intro}
          </p>

          <section :for={section <- @post.sections} class="space-y-5">
            <h2 :if={present?(section.title)} class="text-3xl font-bold leading-tight">
              {section.title}
            </h2>
            <blockquote
              :if={present?(section.quote)}
              class={[
                "rounded-lg border-l-4 border-[#cfd0fb] px-6 py-5",
                public_surface_background_class()
              ]}
            >
              "{section.quote}"
            </blockquote>
            <p :for={paragraph <- paragraphs(section.body)}>{paragraph}</p>
            <figure :if={present?(section.image_url)} class="overflow-hidden rounded-lg">
              <img
                src={section.image_url}
                alt={section.image_alt || section.title || @post.title}
                class="w-full object-cover"
              />
              <figcaption :if={present?(section.image_caption)} class="bg-white px-5 py-4 text-sm">
                {section.image_caption}
              </figcaption>
            </figure>
          </section>
        </article>

        <div class="mt-12 border-t border-[#cfd0fb] pt-8">
          <a
            href="/blog"
            class="inline-flex items-center gap-2 font-semibold no-underline hover:opacity-80"
          >
            <svg
              viewBox="0 0 24 24"
              aria-hidden="true"
              class="h-4 w-4"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="m12 19-7-7 7-7" />
              <path d="M19 12H5" />
            </svg>
            Back to all articles
          </a>
        </div>
      </div>
    </section>

    <section :if={@related != []} class="bg-white py-16 sm:py-20">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <h2 class="text-center text-2xl font-bold sm:text-3xl lg:text-4xl">
          More from GHCE
        </h2>
        <div class="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          <article
            :for={post <- @related}
            class="overflow-hidden rounded-lg border border-[#cfd0fb] bg-white shadow-sm"
          >
            <a href={"/post/#{post.slug}"} class="group block no-underline">
              <img
                :if={post.hero_image_url}
                src={post.hero_image_url}
                alt={post.title}
                class="h-56 w-full object-cover transition group-hover:scale-[1.03]"
                loading="lazy"
              />
              <div class="p-5">
                <p class="text-sm font-semibold">{published_label(post)}</p>
                <h3 class="mt-3 text-xl font-bold leading-snug group-hover:opacity-80">
                  {post.title}
                </h3>
                <p :if={present?(post.excerpt)} class="mt-3 leading-7">
                  {post.excerpt}
                </p>
              </div>
            </a>
          </article>
        </div>
      </div>
    </section>
    """
  end

  defp appointment_section(assigns) do
    ~H"""
    <section id="appointment" class="bg-white py-16 sm:py-20">
      <div class="mx-auto grid max-w-7xl gap-10 px-4 sm:px-6 lg:grid-cols-[0.85fr_1.15fr] lg:px-8">
        <div>
          <p class="text-sm font-bold uppercase tracking-wide">Book a Visit</p>
          <h2 class="mt-3 text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">
            Schedule your appointment today
          </h2>
          <p class="mt-4 text-base leading-7 sm:text-lg sm:leading-8">
            Book your appointment today and get the expert care you deserve.
          </p>
          <div class="mt-8 space-y-4">
            <a
              :for={phone <- public_phone_contacts()}
              href={phone.href}
              class="flex items-center gap-3 rounded-lg border border-[#cfd0fb] bg-white p-4 font-semibold no-underline hover:bg-[#cfd0fb]"
            >
              <svg
                viewBox="0 0 24 24"
                aria-hidden="true"
                class="h-5 w-5"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.8 19.8 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.18 2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.35 1.9.66 2.81a2 2 0 0 1-.45 2.11L8.05 9.91a16 16 0 0 0 6.04 6.04l1.27-1.27a2 2 0 0 1 2.11-.45c.91.31 1.85.53 2.81.66A2 2 0 0 1 22 16.92Z" />
              </svg>
              {phone.display}
            </a>
            <a
              href="mailto:info@glocalhealthcentre.org"
              class="flex items-center gap-3 rounded-lg border border-[#cfd0fb] bg-white p-4 font-semibold no-underline hover:bg-[#cfd0fb]"
            >
              <svg
                viewBox="0 0 24 24"
                aria-hidden="true"
                class="h-5 w-5"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <rect x="3" y="5" width="18" height="14" rx="2" />
                <path d="m3 7 9 6 9-6" />
              </svg>
              info@glocalhealthcentre.org
            </a>
          </div>
        </div>

        <form
          action="#"
          method="get"
          class="rounded-lg border border-[#cfd0fb] bg-white p-5 shadow-sm sm:p-8"
        >
          <div class="grid gap-5 sm:grid-cols-2">
            <label class="block">
              <span class="text-sm font-semibold">First Name</span>
              <input
                required
                name="first-name"
                type="text"
                placeholder="First Name"
                class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
              />
            </label>
            <label class="block">
              <span class="text-sm font-semibold">Last Name</span>
              <input
                required
                name="last-name"
                type="text"
                placeholder="Last Name"
                class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
              />
            </label>
            <label class="block">
              <span class="text-sm font-semibold">Email Address</span>
              <input
                required
                name="email"
                type="email"
                placeholder="Enter your email"
                class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
              />
            </label>
            <label class="block">
              <span class="text-sm font-semibold">Phone Number</span>
              <input
                required
                name="phone"
                type="tel"
                placeholder="+254 7XX XXX XXX"
                class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
              />
            </label>
            <label class="block">
              <span class="text-sm font-semibold">Service Type</span>
              <select
                required
                name="service"
                class="mt-2 w-full rounded-md border border-[#cfd0fb] bg-white px-4 py-3 outline-none focus:border-[#cfd0fb]"
              >
                <option value="">Personalized Care</option>
                <option value="outpatient">Outpatient</option>
                <option value="emergency">Emergency</option>
              </select>
            </label>
            <label class="block">
              <span class="text-sm font-semibold">Date &amp; Time</span>
              <input
                name="date"
                type="date"
                class="mt-2 w-full rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
              />
            </label>
          </div>
          <label class="mt-5 block">
            <span class="text-sm font-semibold">Message</span>
            <textarea
              required
              name="message"
              rows="5"
              placeholder="Write your message..."
              class="mt-2 w-full resize-none rounded-md border border-[#cfd0fb] px-4 py-3 outline-none focus:border-[#cfd0fb]"
            ></textarea>
          </label>
          <button
            type="submit"
            class="mt-6 inline-flex w-full items-center justify-center rounded-md border border-[#cfd0fb] bg-[#cfd0fb] px-6 py-3 font-semibold shadow-sm hover:bg-white sm:w-auto"
          >
            Book Appointment
          </button>
        </form>
      </div>
    </section>
    """
  end

  defp paragraphs(nil), do: []

  defp paragraphs(body) when is_binary(body) do
    body
    |> String.split(~r/\n\s*\n/, trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp paragraphs(_body), do: []

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_value), do: true

  defp published_label(post), do: Blogs.format_published_at(post.published_at) || "Coming Soon"

  defp page_title_for(post), do: "#{post.title} | GHCE — Quality Care at Kisaju"
end
