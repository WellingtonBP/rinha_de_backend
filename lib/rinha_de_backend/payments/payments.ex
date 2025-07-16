defmodule RinhaDeBackend.Payments do
  alias RinhaDeBackend.Repo
  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Payments.Workers.PaymentProcessSupervisor

  import Ecto.Query

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

  def summary(params) do
    Payments
    |> select([p], {p.service_name, count(p.correlation_id), sum(p.amount)})
    |> maybe_filter_from(params[:from])
    |> maybe_filter_to(params[:to])
    |> where([p], p.status == :APPROVED)
    |> group_by([p], p.service_name)
    |> Repo.all()
    |> Enum.into(%{}, fn {service_name, total_requests, total_amount} ->
      {service_name, %{"totalRequests" => total_requests, "totalAmount" => total_amount}}
    end)
  end

  defp maybe_filter_from(query, nil), do: query

  defp maybe_filter_from(query, from) do
    where(query, [p], p.inserted_at >= ^from)
  end

  defp maybe_filter_to(query, nil), do: query

  defp maybe_filter_to(query, to) do
    where(query, [p], p.inserted_at <= ^to)
  end
end
