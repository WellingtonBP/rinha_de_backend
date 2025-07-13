defmodule RinhaDeBackend.Repo.Migrations.CreateServicesTable do
  use Ecto.Migration

  def up do
    create table(:payment_services, primary_key: false) do
      add(:name, :string, primary_key: true)
      add(:failing, :boolean)
      add(:delay, :integer)
    end

    execute("""
      INSERT INTO payment_services (name, failing, delay) VALUES ('default', false, 0), ('fallback', false, 0)
    """)
  end

  def down do
    drop table(:payment_services)
  end
end
