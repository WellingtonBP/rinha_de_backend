defmodule RinhaDeBackend.Payments.Schemas.Payments do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:correlation_id, :binary_id, autogenerate: false}

  schema "payments" do
    field :status, Ecto.Enum, values: [:PENDING, :APPROVED]
    field :amount, :decimal
    field :service_name, :string
    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = payment, attrs \\ %{}) do
    payment
    |> cast(attrs, [:status, :amount, :service_name])
    |> validate_required([:status, :amount])
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
