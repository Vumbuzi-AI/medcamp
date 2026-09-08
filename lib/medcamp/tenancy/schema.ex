defmodule Medcamp.Tenancy.Schema do
  @moduledoc """
  Marks an Ecto schema as belonging to an organisation.

      defmodule Medcamp.Patients.Patient do
        use Ecto.Schema
        use Medcamp.Tenancy.Schema

        schema "patients" do
          tenant_field()
          ...
        end

        def changeset(patient, attrs) do
          patient
          |> cast(attrs, [...])
          |> put_org_id()
        end
      end

  The marker is what `Medcamp.Repo.prepare_query/3` looks for when deciding
  whether a query needs an organisation filter, so adding it to a schema is
  all it takes to bring that table under tenancy.
  """

  defmacro __using__(_opts) do
    quote do
      import Medcamp.Tenancy.Schema, only: [tenant_field: 0, put_org_id: 1]

      @doc false
      def __tenant__?, do: true
    end
  end

  @doc """
  The `organisation_id` association. Call inside the `schema do` block.
  """
  defmacro tenant_field do
    quote do
      belongs_to :organisation, Medcamp.Organisations.Organisation
    end
  end

  @doc """
  Stamps the current process's organisation onto a changeset.

  Only fills the field when it isn't already set, so a record loaded from the
  database keeps its own organisation through an update, and the superadmin
  console can create an organisation's first admin user by setting the id
  explicitly.
  """
  def put_org_id(changeset) do
    case Ecto.Changeset.get_field(changeset, :organisation_id) do
      nil ->
        Ecto.Changeset.put_change(changeset, :organisation_id, Medcamp.Tenancy.require_org_id!())

      _already_set ->
        changeset
    end
  end
end
