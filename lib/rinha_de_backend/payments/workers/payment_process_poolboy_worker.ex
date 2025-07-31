defmodule RinhaDeBackend.Payments.Workers.PaymentProcessPollboyWorker do
  use GenServer

  alias RinhaDeBackend.Payments.Integrations.PaymentService
  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Repo
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
        Process.send_after(self(), :process, 100)

      {payment, service} ->
        payment_with_date_and_service =
          DateTime.utc_now()
          |> then(&Map.put(payment, :inserted_at, &1))
          |> Map.put(:service_name, to_string(service))

        service
        |> PaymentService.do_payment(payment_with_date_and_service)
        |> case do
          :error ->
            GenServer.cast(PaymentProcess, {:new, payment})
            Process.send_after(self(), :process, 100)

          :ok ->
            insert_payments([payment_with_date_and_service])
            Process.send_after(self(), :process, 0)
        end
    end

    {:noreply, state}
  end

  def insert_payments(payments) do
    Repo.insert_all(Payments, payments)
  end
end
