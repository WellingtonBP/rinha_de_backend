defmodule RinhaDeBackend.Payments.Workers.PaymentProcessPollboyWorker do
  use GenServer

  alias RinhaDeBackend.Payments.Integrations.PaymentService
  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Repo

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({payment, service}, _, state) do
    payment_with_date_and_service =
      DateTime.utc_now()
      |> then(&Map.put(payment, :inserted_at, &1))
      |> Map.put(:service_name, to_string(service))

    result =
      service
      |> PaymentService.do_payment(payment_with_date_and_service)
      |> case do
        :error ->
          nil

        :ok ->
          tap(payment_with_date_and_service, &insert_payments([&1]))
      end

    {:reply, result, state}
  end

  def insert_payments(payments) do
    Repo.insert_all(Payments, payments)
  end
end
