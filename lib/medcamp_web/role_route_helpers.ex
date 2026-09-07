defmodule MedcampWeb.RoleRouteHelpers do
  @moduledoc false

  def role_path(%{role: role}, suffix), do: role_path(role, suffix)
  def role_path(nil, suffix), do: normalize_suffix(suffix)

  def role_path(role, suffix) when is_binary(role) do
    role_prefix(role) <> normalize_suffix(suffix)
  end

  def role_path(_, suffix), do: normalize_suffix(suffix)

  defp normalize_suffix(suffix) when suffix in [nil, ""], do: ""
  defp normalize_suffix("/" <> _ = suffix), do: suffix
  defp normalize_suffix(suffix), do: "/" <> suffix

  defp role_prefix(role) do
    case role do
      "admin" -> "/admin"
      "doctor" -> "/doctor"
      "nurse" -> "/nurse"
      "reception" -> "/reception"
      "pharmacist" -> "/pharmacist"
      "labtechnician" -> "/lab"
      "radiologist" -> "/radiologist"
      "support staff" -> "/support_staff"
      "inventory_manager" -> "/inventory_manager"
      "supplier" -> "/supplier"
      _ -> ""
    end
  end
end
