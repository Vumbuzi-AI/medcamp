defmodule Medcamp.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Medcamp.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Medcamp.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Medcamp.DataCase
    end
  end

  setup tags do
    Medcamp.DataCase.setup_sandbox(tags)
    {:ok, organisation: Medcamp.DataCase.setup_tenant()}
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Medcamp.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  Creates an organisation for the test and enters its tenancy.

  Tenant-scoped queries raise without an organisation (see
  `Medcamp.Repo.prepare_query/3`), so this is what lets the existing fixtures
  and tests carry on unchanged. A test that wants to prove isolation creates a
  second organisation with `Medcamp.OrganisationsFixtures.organisation_fixture/1`
  and switches between them with `Medcamp.Tenancy.with_org/2`.
  """
  def setup_tenant do
    organisation = Medcamp.OrganisationsFixtures.organisation_fixture()
    Medcamp.Tenancy.put_org_id(organisation.id)
    on_exit(fn -> Medcamp.Tenancy.clear_org_id() end)
    organisation
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
