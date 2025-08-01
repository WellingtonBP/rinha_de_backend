defmodule RinhaDeBackend.Payments.Workers.PaymentProcessWorker do
  use GenServer

  alias RinhaDeBackend.Payments.Integrations.PaymentService
  alias RinhaDeBackend.Payments.Workers.PaymentProcess

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    Process.send_after(self(), :process, 0)
    {:ok, nil}
  end

  def handle_info(:process, state) do
    case GenServer.call(PaymentProcess, :get, :infinity) do
      :none ->
        :none

      {payment, try_fallback, count} ->
        case process_for_service(payment, :default) do
          :error when try_fallback ->
            {process_for_service(payment, :fallback), payment}

          :error ->
            GenServer.cast(PaymentProcess, :increase_default_error)
            {:error, payment}

          {:ok, payment_with_date_and_service} ->
            if count != 0, do: GenServer.cast(PaymentProcess, :reset_default_error)
            {{:ok, payment_with_date_and_service}, payment}
        end
    end
    |> then(fn
      {:error, payment} ->
        GenServer.cast(PaymentProcess, {:new, payment})
        Process.send_after(self(), :process, 500)

      {{:ok, payment_with_date_and_service}, _} ->
        insert_payment(payment_with_date_and_service)
        Process.send_after(self(), :process, 0)

      :none ->
        Process.send_after(self(), :process, 50)
    end)

    {:noreply, state}
  end

  defp process_for_service(payment, service) do
    payment_with_date_and_service =
      DateTime.utc_now()
      |> then(&Map.put(payment, :inserted_at, &1))
      |> Map.put(:service_name, service)

    case PaymentService.do_payment(service, payment_with_date_and_service) do
      :ok ->
        {:ok, payment_with_date_and_service}

      :error ->
        :error
    end
  end

  def insert_payment(payment) do
    :ets.insert(
      :payments,
      {Map.get(payment, :correlation_id), Map.get(payment, :amount),
       Map.get(payment, :service_name),
       DateTime.to_unix(Map.get(payment, :inserted_at), :millisecond)}
    )
  end
end
