defmodule RinhaDeBackend.Payments do
  alias RinhaDeBackend.Repo
  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Payments.Workers.PaymentProcess

  import Ecto.Query

  def new_payment(%{"correlationId" => cid, "amount" => amount}) do
    %{correlation_id: cid, amount: amount}
    |> PaymentProcess.new()
  end

  def summary(params) do
    Payments
    |> select([p], {p.service_name, count(p.correlation_id), sum(p.amount)})
    |> maybe_filter_from(params[:from])
    |> maybe_filter_to(params[:to])
    |> group_by([p], p.service_name)
    |> Repo.all()
    |> then(fn result ->
      fallback = Enum.find(result, fn tuple -> elem(tuple, 0) == "fallback" end)
      default = Enum.find(result, fn tuple -> elem(tuple, 0) == "default" end)

      %{
        fallback: %{
          "totalRequests" => if(not is_nil(fallback), do: elem(fallback, 1), else: 0),
          "totalAmount" =>
            if(not is_nil(fallback), do: Decimal.to_float(elem(fallback, 2)), else: 0)
        },
        default: %{
          "totalRequests" => if(not is_nil(default), do: elem(default, 1), else: 0),
          "totalAmount" =>
            if(not is_nil(default), do: Decimal.to_float(elem(default, 2)), else: 0)
        }
      }
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
