defmodule Medcamp.Organisations.Organisation do
  @moduledoc """
  A tenant. Every clinical record in the system belongs to exactly one, and
  the profile here is what the UI wears: the name and logo in the sidebar,
  the letterhead on a printed lab report, and the accent colour the whole
  theme is derived from.
  """

  use Ecto.Schema
  import Ecto.Changeset

  # Interpolated into a <style> block in the root layout, so anything that is
  # not literally a hex colour is refused here rather than sanitised later.
  @hex_color ~r/^#[0-9a-fA-F]{6}$/
  @slug_format ~r/^[a-z0-9]+(-[a-z0-9]+)*$/

  schema "organisations" do
    field :name, :string
    field :slug, :string
    field :email, :string
    field :phone_number, :string
    field :location, :string
    field :logo, :string
    field :primary_color, :string, default: "#373896"
    field :accent_color, :string, default: "#6667ab"
    field :is_active, :boolean, default: true
    field :approved_at, :utc_datetime
    field :contact_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  A self-serve signup.

  Lands inactive and unapproved: a tenant that can hold patient records does
  not come into existence without someone looking at it first. The slug is
  derived from the name rather than asked for, since the person signing up has
  no reason to care what it is.
  """
  def signup_changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name, :email, :phone_number, :location, :contact_name])
    |> validate_required([:name, :email, :contact_name])
    |> put_slug_from_name()
    |> put_change(:is_active, false)
    |> put_change(:approved_at, nil)
    |> validate_format(:slug, @slug_format, message: "must contain some letters or numbers")
    |> unique_constraint(:slug)
    |> shared_validations()
  end

  defp put_slug_from_name(changeset) do
    case get_field(changeset, :slug) do
      nil -> put_change(changeset, :slug, slugify(get_field(changeset, :name)))
      _already_set -> changeset
    end
  end

  @doc """
  Turns an organisation name into a URL-safe slug, with a short random suffix
  so two "Nairobi Health Camp" signups do not collide.
  """
  def slugify(nil), do: nil

  def slugify(name) do
    base =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    suffix =
      100_000
      |> :rand.uniform()
      |> Integer.to_string(36)
      |> String.downcase()

    case base do
      "" -> "org-#{suffix}"
      base -> "#{String.slice(base, 0, 40)}-#{suffix}"
    end
  end

  @doc """
  Creating an organisation. The slug is permanent once set - it is how a
  tenant is referred to outside the database.
  """
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [
      :name,
      :slug,
      :email,
      :phone_number,
      :location,
      :contact_name,
      :logo,
      :primary_color,
      :accent_color,
      :is_active,
      :approved_at
    ])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, @slug_format,
      message: "must be lowercase letters, numbers and hyphens"
    )
    |> validate_length(:slug, min: 2, max: 60)
    |> unique_constraint(:slug)
    |> shared_validations()
  end

  @doc """
  Editing an organisation's own profile, from the admin panel. Same fields
  minus `slug` and `is_active`, which only a superadmin may change.
  """
  def profile_changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [
      :name,
      :email,
      :phone_number,
      :location,
      :logo,
      :primary_color,
      :accent_color
    ])
    |> validate_required([:name])
    |> shared_validations()
  end

  defp shared_validations(changeset) do
    changeset
    |> validate_length(:name, min: 2, max: 120)
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+\.[^@,;\s]+$/,
      message: "must be a valid email address"
    )
    |> validate_format(:primary_color, @hex_color, message: "must be a hex colour like #1D3557")
    |> validate_format(:accent_color, @hex_color, message: "must be a hex colour like #1D3557")
  end

  @doc """
  The `--brand-*` CSS variables the theme is built from.

  An organisation picks two colours; the four tints behind them (selected nav
  item, hover background, ring) are derived here so nobody has to choose seven
  hex codes that go together. The tints keep the primary colour's hue and are
  placed at fixed lightnesses, which is what makes the derivation work for a
  teal or maroon brand as well as the stock indigo.
  """
  def css_variables(%__MODULE__{} = organisation) do
    primary = organisation.primary_color || "#373896"
    accent = organisation.accent_color || "#6667ab"

    %{
      "--brand-primary" => primary,
      "--brand-accent" => accent,
      "--brand-accent-dark" => darken(accent, 0.12),
      "--brand-50" => tint(primary, 0.97),
      "--brand-100" => tint(primary, 0.95),
      "--brand-200" => tint(primary, 0.91),
      "--brand-300" => tint(primary, 0.895)
    }
  end

  # Same hue, high saturation, pushed to `lightness`. The saturation floor
  # keeps the tints from washing out to grey when the brand colour is muted.
  defp tint(hex, lightness) do
    {h, s, _l} = to_hsl(hex)
    from_hsl(h, max(s, 0.85), lightness)
  end

  defp darken(hex, amount) do
    {h, s, l} = to_hsl(hex)
    from_hsl(h, s, max(l - amount, 0.0))
  end

  defp to_hsl("#" <> hex) do
    [r, g, b] =
      hex
      |> String.graphemes()
      |> Enum.chunk_every(2)
      |> Enum.map(fn pair -> pair |> Enum.join() |> String.to_integer(16) end)
      |> Enum.map(&(&1 / 255))

    max_c = Enum.max([r, g, b])
    min_c = Enum.min([r, g, b])
    delta = max_c - min_c
    l = (max_c + min_c) / 2

    s = if delta == 0, do: 0.0, else: delta / (1 - abs(2 * l - 1))

    h =
      cond do
        delta == 0 -> 0.0
        max_c == r -> 60 * :math.fmod((g - b) / delta + 6, 6)
        max_c == g -> 60 * ((b - r) / delta + 2)
        true -> 60 * ((r - g) / delta + 4)
      end

    {h, s, l}
  end

  defp from_hsl(h, s, l) do
    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs(:math.fmod(h / 60, 2) - 1))
    m = l - c / 2

    {r, g, b} =
      cond do
        h < 60 -> {c, x, 0.0}
        h < 120 -> {x, c, 0.0}
        h < 180 -> {0.0, c, x}
        h < 240 -> {0.0, x, c}
        h < 300 -> {x, 0.0, c}
        true -> {c, 0.0, x}
      end

    [r, g, b]
    |> Enum.map_join(fn channel ->
      ((channel + m) * 255)
      |> round()
      |> min(255)
      |> max(0)
      |> Integer.to_string(16)
      |> String.pad_leading(2, "0")
    end)
    |> then(&("#" <> &1))
  end
end
