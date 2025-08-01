defmodule RinhaDeBackend.Payments do
  alias RinhaDeBackend.Payments.Workers.PaymentProcess

  def new_payment(%{"correlationId" => cid, "amount" => amount}) do
    %{correlation_id: cid, amount: amount}
    |> PaymentProcess.new()
  end

  def summary(params) do
    Node.list([:this, :visible])
    |> :rpc.multicall(__MODULE__, :get_summary, [params])
    |> then(&Enum.reduce(elem(&1, 0), [], fn s, acc -> s ++ acc end))
    |> format_data()
  end

  def get_summary(params) do
    filters =
      [maybe_filter_from(params), maybe_filter_to(params)]
      |> Enum.reject(&is_nil/1)

    guard =
      case filters do
        [] ->
          []

        [one] ->
          [one]

        [first | rest] ->
          [
            Enum.reduce(rest, first, fn condition, acc ->
              {:andalso, acc, condition}
            end)
          ]
      end

    match_spec = [
      {
        {:"$1", :"$2", :"$3", :"$4"},
        guard,
        [:"$_"]
      }
    ]

    :ets.select(:payments, match_spec)
  end

  defp maybe_filter_from(%{"from" => fromstr} = _) do
    fromstr
    |> DateTime.from_iso8601()
    |> then(fn {:ok, from, _} ->
      {:>=, :"$4", DateTime.to_unix(from, :millisecond)}
    end)
  end

  defp maybe_filter_from(_) do
    nil
  end

  defp maybe_filter_to(%{"to" => tostr} = _) do
    tostr
    |> DateTime.from_iso8601()
    |> then(fn {:ok, to, _} ->
      {:"=<", :"$4", DateTime.to_unix(to, :millisecond)}
    end)
  end

  defp maybe_filter_to(_) do
    nil
  end

  defp format_data(data) do
    base = %{"totalRequests" => 0, "totalAmount" => 0}

    Enum.reduce(data, %{default: base, fallback: base}, fn
      {_, value, :default, _}, acc ->
        %{
          acc
          | default: %{
              acc[:default]
              | "totalRequests" => Map.get(acc[:default], "totalRequests") + 1,
                "totalAmount" => Map.get(acc[:default], "totalAmount") + value
            }
        }

      {_, value, :fallback, _}, acc ->
        %{
          acc
          | fallback: %{
              acc[:fallback]
              | "totalRequests" => Map.get(acc[:fallback], "totalRequests") + 1,
                "totalAmount" => Map.get(acc[:fallback], "totalAmount") + value
            }
        }
    end)
  end

  def purge_payments() do
    Node.list([:this, :visible])
    |> :rpc.multicall(__MODULE__, :do_purge_payments, [])
  end

  def do_purge_payments do
    :ets.delete_all_objects(:payments)
  end
end
