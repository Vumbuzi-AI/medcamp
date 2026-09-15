defmodule MedcampWeb.AuthComponents do
  @moduledoc """
  Chrome for the pre-authentication pages — sign in, OTP, password reset,
  organisation signup. These are public surfaces, so they follow `docs/DESIGN.md`
  end to end: the fixed Tibasasa navy/cyan palette, Plus Jakarta Sans, hairline
  borders, no shadows, one colour transition.
  """
  use Phoenix.Component

  @doc """
  The two-panel auth layout: a bounded photo on the left with whitespace around
  it, the form beside it. No card. The image and its column are a fixed size, so
  switching between the pre-auth pages only re-renders the form.

  `width="wide"` widens the content column a little for a form with side-by-side
  fields (organisation signup); everything else keeps the default `"md"`.

      <.auth_split>
        <h1>...</h1>
        ...
      </.auth_split>
  """
  attr :width, :string, default: "md", values: ~w(md wide)
  slot :inner_block, required: true

  def auth_split(assigns) do
    ~H"""
    <div class="min-h-screen bg-white text-[#0C2765]">
      <div class="mx-auto flex min-h-screen w-[92%] max-w-7xl flex-col gap-8 py-6 lg:flex-row lg:items-stretch lg:gap-12 lg:py-8">
        <div class="hidden lg:block lg:w-[46%] lg:shrink-0">
          <img
            src="/images/public/african-care-coordination.png"
            alt="Clinicians reviewing a patient's record together"
            class="h-full w-full rounded-2xl border border-slate-200 object-cover"
          />
        </div>

        <div class="flex w-full flex-1 flex-col justify-center">
          <div class={[
            "mx-auto w-full",
            @width == "wide" && "max-w-lg",
            @width == "md" && "max-w-md"
          ]}>
            <a href="/" class="mb-8 flex items-center gap-2.5">
              <img src="/images/tibasasa-ai-logo.png" alt="Tibasasa" class="h-9 w-9 object-contain" />
              <span class="text-lg font-bold">Tibasasa</span>
            </a>

            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  `auth_split` plus a title / subtitle / footer, for the small auth forms.

      <.auth_shell title="Verify your login" subtitle="Enter the code we emailed.">
        <.simple_form ...>...</.simple_form>
        <:footer><.link href={~p"/users/log_in"}>Back to sign in</.link></:footer>
      </.auth_shell>
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  slot :inner_block, required: true
  slot :footer

  def auth_shell(assigns) do
    ~H"""
    <.auth_split>
      <h1 class="text-2xl font-bold tracking-[-0.01em]">{@title}</h1>
      <p :if={@subtitle} class="mt-2 text-sm leading-relaxed text-slate-600">{@subtitle}</p>

      <div class="mt-6">
        {render_slot(@inner_block)}
      </div>

      <div :if={@footer != []} class="mt-8 text-sm font-semibold text-slate-600">
        {render_slot(@footer)}
      </div>
    </.auth_split>
    """
  end

  @doc "Primary button in the Tibasasa treatment. Full width by default; `type=\"submit\"`."
  attr :label, :string, required: true
  attr :type, :string, default: "submit"
  attr :class, :string, default: "w-full"
  attr :rest, :global, include: ~w(form name value)

  def auth_submit(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "inline-flex items-center justify-center gap-2 rounded-full bg-[#0C2765] px-6 py-3",
        "text-base font-semibold text-white transition-colors duration-150 hover:bg-[#16418f]",
        "phx-submit-loading:opacity-75",
        @class
      ]}
      {@rest}
    >
      {@label}
    </button>
    """
  end
end
