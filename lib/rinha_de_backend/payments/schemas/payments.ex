defmodule RinhaDeBackend.Payments.Schemas.Payments do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:correlation_id, :binary_id, autogenerate: false}

  schema "payments" do
    field :amount, :decimal
    field :service_name, :string
    field :inserted_at, :utc_datetime_usec
  end

  def changeset(%__MODULE__{} = payment, attrs \\ %{}) do
    payment
    |> cast(attrs, [:amount, :service_name, :inserted_at])
  end
end
