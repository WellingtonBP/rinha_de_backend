defmodule RinhaDeBackend.Payments.Schemas.Payments do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:correlation_id, :binary_id, autogenerate: false}
  @payment_status_values ~w(PENDING APPROVED)a
  @required_fields ~w(correlation_id status amount service_name)a
  @optional_fields ~w()a

  schema "payments" do
    field :status, Ecto.Enum, values: @payment_status_values
    field :amount, :decimal
    field :service_name, :string
    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = payment, attrs \\ %{}) do
    payment
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  def get_errors_message(changeset) do
    if changeset.valid? do
      nil
    else
      errors =
        changeset.errors
        |> Map.new(fn {key, {message, meta}} ->
          {key, interpolation(message, meta)}
        end)

      %{errors: errors}
    end
  end

  defp interpolation(message, meta) do
    ~r/(?<head>)%{[^}]+}(?<tail>)/
    |> Regex.split(message, on: [:head, :tail])
    |> Enum.reduce("", fn
      <<"%{" <> rest>>, acc ->
        key = String.trim_trailing(rest, "}") |> String.to_atom()
        value = Keyword.fetch!(meta, key)
        acc <> to_string(value)

      segment, acc ->
        acc <> segment
    end)
  end
end
