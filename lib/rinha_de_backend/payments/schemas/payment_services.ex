defmodule RinhaDeBackend.Payments.Schemas.PaymentServices do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:name, :string, autogenerate: false}

  schema "payment_services" do
    field :failing, :boolean
    field :delay, :integer
  end

  def changeset(%__MODULE__{} = payment_service, attrs \\ %{}) do
    payment_service
    |> cast(attrs, [:name, :failing, :delay])
    |> validate_required([:failing, :delay])
  end
end
