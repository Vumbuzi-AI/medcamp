defmodule Medcamp.Departments do
  @moduledoc """
  The Departments context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.Departments.Department

  def list_departments do
    Repo.all(from d in Department, order_by: [asc: d.name])
  end

  def list_departments_for_selection do
    Repo.all(from d in Department, order_by: [asc: d.name], select: {d.name, d.id})
  end

  def list_departments_for_selection_with_admin_or_reception do
    Repo.all(
      from d in Department,
        where: d.name in ["Admin", "Reception"] or is_nil(d.name),
        order_by: [asc: d.name],
        select: {d.name, d.id}
    )
  end

  def list_departments_for_nursing_requisition do
    Repo.all(
      from d in Department,
        where: d.name in ["Admin", "Reception"],
        order_by: [asc: d.name],
        select: {d.name, d.id}
    )
  end

  def get_department!(id), do: Repo.get!(Department, id)

  def get_department_by_name(name) do
    Repo.get_by(Department, name: name)
  end

  def create_department(attrs \\ %{}) do
    %Department{}
    |> Department.changeset(attrs)
    |> Repo.insert()
  end

  def update_department(%Department{} = department, attrs) do
    department
    |> Department.changeset(attrs)
    |> Repo.update()
  end

  def change_department(%Department{} = department, attrs \\ %{}) do
    Department.changeset(department, attrs)
  end
end
