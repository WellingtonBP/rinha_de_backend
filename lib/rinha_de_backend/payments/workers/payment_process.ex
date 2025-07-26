defmodule RinhaDeBackend.Payments.Workers.PaymentProcess do
  use GenServer

  alias RinhaDeBackend.Payments.Workers.ServicesStatus
  alias RinhaDeBackend.Payments.Integrations.PaymentService
  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Repo

  def start_link(_), do: GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)

  def init(_) do
    Process.send_after(self(), :process, 1000)
    {:ok, []}
  end

  def new(payment) do
    GenServer.cast(__MODULE__, {:new, payment})
  end

  def handle_cast({:new, payment}, payments) do
    {:noreply, [payment | payments]}
  end

  def handle_info(:process, []) do
    Process.send_after(self(), :process, 50)
    {:noreply, []}
  end

  def handle_info(:process, payments) do
    ServicesStatus.get_status()
    |> handle_services_status()
    |> case do
      :none ->
        Process.send_after(self(), :process, 250)
        {:noreply, payments}

      service ->
        service
        |> process_for_service(payments)
        |> then(fn processed ->
          filtered_payments =
            if length(processed) == length(payments),
              do: [],
              else:
                Enum.filter(payments, fn payment ->
                  not Enum.any?(processed, fn processed_payment ->
                    Map.get(processed_payment, :correlation_id) ==
                      Map.get(payment, :correlation_id)
                  end)
                end)

          Process.send_after(self(), :process, 0)

          {:noreply, filtered_payments}
        end)
    end
  end

  def process_for_service(service, payments) do
    payments
    |> Task.async_stream(
      fn payment ->
        payment_with_date_and_service =
          DateTime.utc_now()
          |> then(&Map.put(payment, :inserted_at, &1))
          |> Map.put(:service_name, to_string(service))

        service
        |> PaymentService.do_payment(payment_with_date_and_service)
        |> case do
          :error ->
            nil

          :ok ->
            tap(
              payment_with_date_and_service,
              &insert_payments([&1])
            )
        end
      end,
      max_concurrency: 8
    )
    |> Enum.reduce([], fn
      {:ok, nil}, acc -> acc
      {:ok, payment}, acc -> [payment | acc]
    end)
  end

  defp handle_services_status(%{default: %{failing: false, min_response_time: delay}})
       when delay <= 0 do
    :default
  end

  defp handle_services_status(%{fallback: %{failing: false, min_response_time: delay}})
       when delay <= 0 do
    :fallback
  end

  defp handle_services_status(_), do: :none

  def insert_payments(payments) do
    Repo.insert_all(Payments, payments)
  end
end
