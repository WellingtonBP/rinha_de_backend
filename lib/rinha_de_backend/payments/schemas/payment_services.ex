defmodule RinhaDeBackend.Payments.Schemas.PaymentServices do
  use Ecto.Schema

  @primary_key {:name, :string, autogenerate: false}

  schema "payment_services" do
    field :failing, :boolean
    field :delay, :integer
  end
end
