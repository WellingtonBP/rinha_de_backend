defmodule RinhaDeBackend.Payments.Workers.PaymentProcess do
  use GenServer

  alias RinhaDeBackend.Payments.Workers.ServicesStatus
  alias RinhaDeBackend.Payments.Integrations.PaymentService
  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Repo

  def start_link(_), do: GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)

  def init(_) do
    Process.send_after(self(), :process, 500)
    {:ok, []}
  end

  def new(payment) do
    GenServer.cast(__MODULE__, {:new, payment})
  end

  def handle_cast({:new, payment}, payments) do
    {:noreply, [payment | payments]}
  end

  def handle_info(:process, []) do
    Process.send_after(self(), :process, 0)
    {:noreply, []}
  end

  def handle_info(:process, payments) do
    ServicesStatus.get_status()
    |> handle_services_status()
    |> case do
      :none ->
        Process.send_after(self(), :process, 0)
        {:noreply, payments}

      service ->
        service
        |> process_for_service(payments)
        |> tap(&insert_payments/1)
        |> then(fn processed ->
          Process.send_after(self(), :process, 0)

          {:noreply, Enum.slice(payments, Kernel.length(processed), Kernel.length(payments))}
        end)
    end
  end

  def process_for_service(service, payments) do
    payments
    |> Enum.reduce_while([], fn payment, processed ->
      date = DateTime.truncate(DateTime.utc_now(), :second)
      payment_with_date = Map.put(payment, :inserted_at, date)

      service
      |> PaymentService.do_payment(payment_with_date)
      |> case do
        :error ->
          {:halt, processed}

        :ok ->
          {:cont, [Map.put(payment_with_date, :service_name, to_string(service)) | processed]}
      end
    end)
  end

  defp handle_services_status(%{default: %{failing: false, min_response_time: delay}})
       when delay <= 3000 do
    :default
  end

  defp handle_services_status(%{fallback: %{failing: false, min_response_time: delay}})
       when delay <= 3000 do
    :fallback
  end

  defp handle_services_status(_), do: :none

  defp insert_payments(payments) do
    Repo.insert_all(Payments, payments)
  end
end
