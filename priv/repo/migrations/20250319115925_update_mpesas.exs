defmodule Medcamp.Repo.Migrations.UpdateMpesas do
  use Ecto.Migration

  def change do
    alter table(:mpesas) do
      add :is_successful, :boolean, default: false
      add :checkout_request_id, :string
      add :merchant_request_id, :string
      add :result_code, :integer
    end
  end
end
