defmodule Medcamp.Camps.Schema do
  @moduledoc """
  Marks an Ecto schema as recording activity that happened at a camp.

      defmodule Medcamp.Triages.Triage do
        use Ecto.Schema
        use Medcamp.Tenancy.Schema
        use Medcamp.Camps.Schema

        schema "triages" do
          tenant_field()
          camp_field()
          ...
        end

        def changeset(triage, attrs) do
          triage
          |> cast(attrs, [...])
          |> put_org_id()
          |> put_camp_id()
        end
      end

  Unlike the organisation, the camp is optional: a record written while no
  camp is active simply has none. Tenancy is an isolation boundary and must
  never be missing; a camp is a label on when the work happened.

  The marker is what `Medcamp.Repo.prepare_query/3` looks for when deciding
  whether the current camp filter applies to a query.
  """

  defmacro __using__(_opts) do
    quote do
      import Medcamp.Camps.Schema, only: [camp_field: 0, put_camp_id: 1]

      @doc false
      def __camp_scoped__?, do: true
    end
  end

  @doc """
  The `camp_id` association. Call inside the `schema do` block.
  """
  defmacro camp_field do
    quote do
      belongs_to :camp, Medcamp.Camps.Camp
    end
  end

  @doc """
  Stamps the organisation's active camp onto a changeset.

  Only fills the field when it isn't already set, so a record loaded from the
  database keeps the camp it happened at through later edits - a lab result
  filled in on Monday still belongs to the weekend's camp.
  """
  def put_camp_id(changeset) do
    case Ecto.Changeset.get_field(changeset, :camp_id) do
      nil -> Ecto.Changeset.put_change(changeset, :camp_id, Medcamp.Camps.Scope.active_camp_id())
      _already_set -> changeset
    end
  end
end
