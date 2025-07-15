defmodule RinhaDeBackend.Payments do
  alias RinhaDeBackend.Repo
  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Payments.Workers.PaymentProcessSupervisor

  def new_payment(%{"correlationId" => cid, "amount" => amount}) do
    data = %{correlation_id: cid, amount: amount, status: :PENDING}

    %Payments{correlation_id: cid}
    |> Payments.changeset(data)
    |> then(fn changeset ->
      case Payments.get_errors_message(changeset) do
        nil ->
          changeset
          |> Repo.insert()
          |> case do
            {:ok, changeset} ->
              data
              |> Map.put(:inserted_at, Map.get(changeset, :inserted_at))
              |> tap(&PaymentProcessSupervisor.process(&1))
              |> then(&%{data: &1})

            _ ->
              :server_error
          end

        error ->
          error
      end
    end)
  end
end
