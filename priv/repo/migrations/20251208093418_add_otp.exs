defmodule Medcamp.Repo.Migrations.AddOtp do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :current_otp, :string
      add :otp, :string
      add :otp_expires_at, :utc_datetime
    end
  end
end
