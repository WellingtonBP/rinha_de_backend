defmodule RinhaDeBackend.Payments.Integrations.PaymentService do
  def do_payment(service, %{correlation_id: cid, amount: amount, inserted_at: inserted_at}) do
    services()
    |> Map.get(service)
    |> then(
      &Finch.build(
        :post,
        "#{&1}/payments",
        [{"Content-Type", "application/json"}],
        JSON.encode!(%{"correlationId" => cid, "amount" => amount, "requestedAt" => inserted_at})
      )
    )
    |> Finch.request(RinhaDeBackend.Finch)
    |> case do
      {:ok, %Finch.Response{status: status}} when status in 200..299 ->
        :ok

      _ ->
        :error
    end
  end

  defp services do
    %{
      default: Application.get_env(:payment_services, :default_url),
      fallback: Application.get_env(:payment_services, :fallback_url)
    }
  end
end
