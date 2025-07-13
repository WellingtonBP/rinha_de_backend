defmodule RinhaDeBackend.Repo.Migrations.CreatePaymentsTable do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE payment_status AS ENUM ('PENDING', 'APPROVED')")

    create table(:payments, primary_key: false) do
      add(:correlation_id, :binary_id, primary_key: true)
      add(:status, :payment_status)
      add(:amount, :decimal)
      add(:service_name, :string)
      timestamps(type: :utc_datetime)
    end
  end

  def down do
    drop table(:payments)
    execute("DROP TYPE payment_status")
  end
end
