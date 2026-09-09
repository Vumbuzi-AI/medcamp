defmodule Medcamp.Organisations do
  @moduledoc """
  The Organisations context - the tenants of the system.

  `organisations` is not itself a tenant table, so nothing here is filtered
  automatically by `Medcamp.Repo.prepare_query/3`. Every function therefore
  takes the organisation it is acting on explicitly, and the callers are
  either the superadmin console or an admin editing their own organisation.
  """

  import Ecto.Query, warn: false

  alias Medcamp.Repo
  alias Medcamp.Organisations.Organisation

  @doc "Every organisation, newest first. Superadmin only."
  def list_organisations do
    Repo.all(from o in Organisation, order_by: [desc: o.inserted_at])
  end

  @doc "Organisations that can still be logged into."
  def list_active_organisations do
    Repo.all(from o in Organisation, where: o.is_active == true, order_by: [asc: o.name])
  end

  def get_organisation!(id), do: Repo.get!(Organisation, id)

  def get_organisation(id) when is_integer(id) or is_binary(id), do: Repo.get(Organisation, id)
  def get_organisation(nil), do: nil

  def get_organisation_by_slug(slug), do: Repo.get_by(Organisation, slug: slug)

  @doc """
  The organisation a user belongs to, or `nil` for a user without one (a
  superadmin, or a session mid-login).
  """
  def get_user_organisation(%{organisation_id: org_id}), do: get_organisation(org_id)
  def get_user_organisation(_), do: nil

  @doc """
  Creates an organisation directly, from the superadmin console.

  Marked approved on creation - it was created by us, so there is nothing left
  to review. Self-serve signups go through `register_organisation/2` instead.
  """
  def create_organisation(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put_new("approved_at", DateTime.utc_now() |> DateTime.truncate(:second))

    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Superadmin edit: everything, including slug and active state."
  def update_organisation(%Organisation{} = organisation, attrs) do
    organisation
    |> Organisation.changeset(attrs)
    |> Repo.update()
  end

  @doc "Admin edit of their own organisation: profile and branding only."
  def update_profile(%Organisation{} = organisation, attrs) do
    organisation
    |> Organisation.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Self-serve signup: creates an organisation and its first admin together.

  Both in one transaction, so a rejected admin (a duplicate email, most
  likely) does not leave an empty organisation behind. The admin is created
  inside the new organisation's tenancy so the tenant stamp on the user row
  lands correctly.

  The organisation starts inactive; `approve/1` is what lets anyone log in.

  Returns `{:ok, %{organisation: org, admin: user}}` or
  `{:error, :organisation | :admin, changeset}`.
  """
  def register_organisation(org_attrs, admin_attrs) do
    Repo.transaction(fn ->
      with {:ok, organisation} <- create_pending_organisation(org_attrs),
           {:ok, admin} <- create_first_admin(organisation, admin_attrs) do
        %{organisation: organisation, admin: admin}
      else
        {:error, step, changeset} -> Repo.rollback({step, changeset})
      end
    end)
    |> case do
      {:ok, result} -> {:ok, result}
      {:error, {step, changeset}} -> {:error, step, changeset}
    end
  end

  defp create_pending_organisation(attrs) do
    %Organisation{}
    |> Organisation.signup_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, organisation} -> {:ok, organisation}
      {:error, changeset} -> {:error, :organisation, changeset}
    end
  end

  defp create_first_admin(organisation, attrs) do
    admin_attrs =
      %{
        "name" => attrs["name"] || organisation.contact_name,
        "email" => attrs["email"],
        "password" => attrs["password"],
        "role" => "admin"
      }
      # Only forward the confirmation when the caller actually collected one -
      # `validate_confirmation/2` fires the moment the key is present, even as nil.
      |> maybe_put("password_confirmation", attrs["password_confirmation"])

    result =
      Medcamp.Tenancy.with_org(organisation.id, fn ->
        Medcamp.Accounts.register_user(admin_attrs)
      end)

    case result do
      {:ok, admin} -> {:ok, admin}
      {:error, changeset} -> {:error, :admin, changeset}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @doc """
  Approves a pending organisation, letting its staff log in.

  Recording `approved_at` is what separates "never reviewed" from "reviewed,
  then suspended" - the two show a different message at the login screen.
  """
  def approve(%Organisation{} = organisation) do
    update_organisation(organisation, %{
      is_active: true,
      approved_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  @doc "Organisations that have signed up and are waiting to be reviewed."
  def list_pending_organisations do
    Repo.all(
      from o in Organisation,
        where: o.is_active == false and is_nil(o.approved_at),
        order_by: [asc: o.inserted_at]
    )
  end

  def pending?(%Organisation{is_active: false, approved_at: nil}), do: true
  def pending?(_), do: false

  @doc """
  Deactivates an organisation rather than deleting it - its clinical records
  are referenced by `on_delete: :restrict` throughout, and camp data is not
  something we throw away.
  """
  def deactivate_organisation(%Organisation{} = organisation) do
    update_organisation(organisation, %{is_active: false})
  end

  def activate_organisation(%Organisation{} = organisation) do
    approve(organisation)
  end

  def change_organisation(%Organisation{} = organisation, attrs \\ %{}) do
    Organisation.changeset(organisation, attrs)
  end

  def change_profile(%Organisation{} = organisation, attrs \\ %{}) do
    Organisation.profile_changeset(organisation, attrs)
  end

  @doc """
  The `--brand-*` declarations for an organisation, ready to drop into a
  `<style>` block. Falls back to the stock theme when there is no
  organisation in context (the login page, the public home page).
  """
  def brand_css(nil), do: brand_css(%Organisation{})

  def brand_css(%Organisation{} = organisation) do
    organisation
    |> Organisation.css_variables()
    |> Enum.map_join(" ", fn {var, value} -> "#{var}: #{value};" end)
  end

  @default_name "Medcamp"
  @default_logo "/images/logo.png"

  @doc "An organisation's name, or a neutral fallback when there isn't one."
  def display_name(%Organisation{name: name}) when is_binary(name) and name != "", do: name
  def display_name(_), do: @default_name

  @doc "An organisation's logo, or the stock one."
  def logo_path(%Organisation{logo: logo}) when is_binary(logo) and logo != "", do: logo
  def logo_path(_), do: @default_logo

  @doc "Up to two initials, for the badge shown when an organisation has no logo."
  def initials(%Organisation{name: name}) when is_binary(name) and name != "" do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.upcase(String.first(&1)))
  end

  def initials(_), do: "MC"
end
