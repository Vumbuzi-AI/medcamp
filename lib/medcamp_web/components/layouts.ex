defmodule MedcampWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use MedcampWeb, :controller` and
  `use MedcampWeb, :live_view`.
  """
  use MedcampWeb, :html

  embed_templates "layouts/*"

  @doc """
  The current organisation's display name, or a neutral fallback on the pages
  that have no organisation in context (login, the public home page).
  """
  def organisation_name(assigns),
    do: Medcamp.Organisations.display_name(assigns[:current_organisation])

  @doc "The current organisation's logo path, or the stock one."
  def organisation_logo(assigns),
    do: Medcamp.Organisations.logo_path(assigns[:current_organisation])

  @doc """
  Up to two initials for an organisation, for the square badge shown next to
  the name when there is no logo.
  """
  defdelegate organisation_initials(organisation), to: Medcamp.Organisations, as: :initials
end
