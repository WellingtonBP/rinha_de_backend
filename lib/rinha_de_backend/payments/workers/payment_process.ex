defmodule RinhaDeBackend.Payments.Workers.PaymentProcess do
  use GenServer

  def start_link(workers_count),
    do: GenServer.start_link(__MODULE__, workers_count, name: __MODULE__)

  def init(workers_count) do
    1..workers_count
    |> Enum.each(fn _ ->
      RinhaDeBackend.Payments.Workers.PaymentProcessDynamicSupervisor.add_worker()
    end)

    {:ok, {0, :queue.new()}}
  end

  def new(payment) do
    GenServer.cast(__MODULE__, {:new, payment})
  end

  def handle_call(:get, _, {default_failing_count, payments}) do
    case :queue.out_r(payments) do
      {:empty, _} ->
        {:reply, :none, {default_failing_count, payments}}

      {{:value, payment}, remaining_payments} ->
        {:reply, {payment, default_failing_count >= 100, default_failing_count},
         {default_failing_count, remaining_payments}}
    end
  end

  def handle_cast({:new, payment}, {default_failing_count, payments}) do
    {:noreply, {default_failing_count, :queue.in(payment, payments)}}
  end

  def handle_cast(:increase_default_error, {default_failing_count, payments}) do
    {:noreply, {default_failing_count + 1, payments}}
  end

  def handle_cast(:reset_default_error, {_, payments}) do
    {:noreply, {0, payments}}
  end
end
