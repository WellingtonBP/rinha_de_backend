defmodule RinhaDeBackend.Payments.Workers.PaymentProcess do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)

  def init(_) do
    {:ok, {0, :default, :queue.new()}}
  end

  def new(payment) do
    GenServer.cast(__MODULE__, {:new, payment})
  end

  def handle_call(:get, _, {_, :none, _} = s) do
    {:reply, :none, s}
  end

  def handle_call(:get, _, {default_failing_count, service, payments}) do
    case :queue.out_r(payments) do
      {:empty, _} ->
        {:reply, :none, {default_failing_count, service, payments}}

      {{:value, payment}, remaining_payments} ->
        {:reply, {payment, service}, {default_failing_count, service, remaining_payments}}
    end
  end

  def handle_cast({:new, payment}, {default_failing_count, service, payments}) do
    {:noreply, {default_failing_count, service, :queue.in(payment, payments)}}
  end

  def handle_cast({:services_status, status}, {default_failing_count, _, payments}) do
    {service, new_default_failing_count} = handle_services_status(status, default_failing_count)
    {:noreply, {new_default_failing_count, service, payments}}
  end

  def handle_services_status(%{default: %{failing: false, min_response_time: delay}}, _)
      when delay <= 50 do
    {:default, 0}
  end

  def handle_services_status(_, default_failing_count)
      when default_failing_count <= 3 do
    {:default, default_failing_count + 1}
  end

  def handle_services_status(%{fallback: %{failing: false, min_response_time: delay}}, _)
      when delay <= 0 do
    {:fallback, 0}
  end

  def handle_services_status(_, _), do: {:none, 0}
end
