defmodule RinhaDeBackend.Payments.Workers.PaymentProcessWorker do
  use GenServer, restart: :transient

  alias RinhaDeBackend.Payments.Workers.ServicesStatus
  alias RinhaDeBackend.Payments.Integrations.PaymentService
  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Repo

  def start_link(payment) do
    GenServer.start_link(__MODULE__, {payment, 0})
  end

  def init(payment) do
    Process.send_after(self(), :process, 0)
    {:ok, payment}
  end

  def handle_info(:process, {payment, 0}) do
    ServicesStatus.get_status()
    |> handle_services_status()
    |> case do
      :default ->
        process_for_service(:default, {payment, 0})

      _ ->
        Process.send_after(self(), :process, 5000)
        {:noreply, {payment, 1}}
    end
  end

  def handle_info(:process, {payment, retry}) do
    ServicesStatus.get_status()
    |> handle_services_status()
    |> case do
      :none ->
        Process.send_after(self(), :process, 5000)
        {:noreply, {payment, retry + 1}}

      service ->
        process_for_service(service, {payment, retry})
    end
  end

  def handle_info(:stop, _) do
    {:stop, :normal, nil}
  end

  defp process_for_service(service, {payment, retry}) do
    service
    |> PaymentService.do_payment(payment)
    |> case do
      :ok ->
        update_payment(payment, service)
        send(self(), :stop)
        {:noreply, :end}

      :error ->
        Process.send_after(self(), :process, 5000)
        {:noreply, {payment, retry + 1}}
    end
  end

  defp handle_services_status(%{default: %{failing: false, min_response_time: delay}})
       when delay <= 5000 do
    :default
  end

  defp handle_services_status(%{fallback: %{failing: false, min_response_time: delay}})
       when delay <= 5000 do
    :fallback
  end

  defp handle_services_status(_), do: :none

  defp update_payment(%{correlation_id: cid, amount: amount}, service) do
    %Payments{correlation_id: cid}
    |> Payments.changeset(%{status: :APPROVED, service_name: to_string(service), amount: amount})
    |> Repo.update()
  end
end
