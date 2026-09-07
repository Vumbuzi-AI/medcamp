departments = [
  %{name: "Pharmacy", code: "PHARM"},
  %{name: "Nursing", code: "NURSE"},
  %{name: "Laboratory", code: "LAB"},
  %{name: "Reception", code: "RECEPTION"},
  %{name: "Doctor", code: "DOCTOR"},
  %{name: "Admin", code: "ADMIN"},
  %{name: "Support Staff", code: "SUPPORT"},
]

for attrs <- departments do
  case Medcamp.Repo.get_by(Medcamp.Departments.Department, code: attrs.code) do
    nil -> Medcamp.Departments.create_department(attrs)
    _ -> :ok
  end
end


# mix run priv/repo/seeds/departments_seeds.exs
