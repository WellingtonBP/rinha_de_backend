defmodule RinhaDeBackend.Payments.Integrations.PaymentService do
  def do_payment(service, body) do
    services()
    |> Map.get(service)
    |> then(&Finch.build(:post, "#{&1}/payments", [], JSON.encode!(body)))
    |> Finch.request(RinhaDeBackend.Finch)
    |> case do
      {:ok, %Finch.Response{status: status}} when status in 200..299 ->
        :ok

      _ ->
        :error
    end
  end

  def get_services_status() do
    services()
    |> Enum.map(fn {service, url} ->
      url
      |> then(&Finch.build(:get, "#{&1}/payments/service-health"))
      |> Finch.request(RinhaDeBackend.Finch)
      |> case do
        {:ok, %Finch.Response{status: 200, body: body}} ->
          {service, JSON.decode!(body)}

        _ ->
          {service, :error}
      end
    end)
    |> Enum.into(%{})
  end

  defp services do
    %{
      default: Application.get_env(:payment_services, :default_url),
      fallback: Application.get_env(:payment_services, :fallback_url)
    }
  end
end
