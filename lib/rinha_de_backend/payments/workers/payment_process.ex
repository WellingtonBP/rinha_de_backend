defmodule RinhaDeBackend.Payments.Workers.PaymentProcess do
  use GenServer

  alias RinhaDeBackend.Payments.Workers.ServicesStatus
  alias RinhaDeBackend.Payments.Integrations.PaymentService
  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Repo

  def start_link(_), do: GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)

  def init(_) do
    Process.send_after(self(), :process, 1000)
    {:ok, {0, []}}
  end

  def new(payment) do
    GenServer.cast(__MODULE__, {:new, payment})
  end

  def handle_cast({:new, payment}, {default_failing_count, payments}) do
    {:noreply, {default_failing_count, [payment | payments]}}
  end

  def handle_info(:process, {default_failing_count, []}) do
    Process.send_after(self(), :process, 50)
    {:noreply, {default_failing_count, []}}
  end

  def handle_info(:process, {default_failing_count, payments}) do
    ServicesStatus.get_status()
    |> handle_services_status(default_failing_count)
    |> case do
      {:none, new_default_failing_count} ->
        Process.send_after(self(), :process, 250)
        {:noreply, {new_default_failing_count, payments}}

      {service, new_default_failing_count} ->
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

          {:noreply, {new_default_failing_count, filtered_payments}}
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

  defp handle_services_status(%{default: %{failing: false, min_response_time: delay}}, _)
       when delay <= 500 do
    {:default, 0}
  end

  defp handle_services_status(_, default_failing_count)
       when default_failing_count <= 20 do
    {:default, default_failing_count + 1}
  end

  defp handle_services_status(%{fallback: %{failing: false, min_response_time: delay}}, _)
       when delay <= 0 do
    {:fallback, 0}
  end

  defp handle_services_status(_, _), do: {:none, 0}

  def insert_payments(payments) do
    Repo.insert_all(Payments, payments)
  end
end
