defmodule RinhaDeBackend.Repo.Migrations.CreatePaymentsTable do
  use Ecto.Migration

  def change do
    create table(:payments, primary_key: false) do
      add(:correlation_id, :binary_id, primary_key: true)
      add(:amount, :decimal)
      add(:service_name, :string)
      add(:inserted_at, :utc_datetime)
    end
  end
end
