defmodule RinhaDeBackend.Payments.Workers.PaymentProcess do
  use GenServer

  def start_link(workers_count),
    do: GenServer.start_link(__MODULE__, workers_count, name: __MODULE__)

  def init(workers_count) do
    1..workers_count
    |> Enum.each(fn _ ->
      RinhaDeBackend.Payments.Workers.PaymentProcessDynamicSupervisor.add_worker()
    end)

    {:ok, {0, :default, :queue.new(), false}}
  end

  def new(payment) do
    GenServer.cast(__MODULE__, {:new, payment})
  end

  def handle_call(:get, _, {_, :none, _, _} = s) do
    {:reply, :none, s}
  end

  def handle_call(:get, _, {dfc, :fallback, p, true}) do
    {:reply, :none, {dfc, :fallback, p, false}}
  end

  def handle_call(:get, _, {default_failing_count, service, payments, _}) do
    case :queue.out_r(payments) do
      {:empty, _} ->
        {:reply, :none, {default_failing_count, service, payments, false}}

      {{:value, payment}, remaining_payments} ->
        {:reply, {payment, service},
         {default_failing_count, service, remaining_payments, service == :fallback}}
    end
  end

  def handle_cast({:new, payment}, {default_failing_count, service, payments, delay_fallback}) do
    {:noreply, {default_failing_count, service, :queue.in(payment, payments), delay_fallback}}
  end

  def handle_cast(
        {:services_status, status},
        {default_failing_count, _, payments, delay_fallback}
      ) do
    {service, new_default_failing_count} = handle_services_status(status, default_failing_count)
    {:noreply, {new_default_failing_count, service, payments, delay_fallback}}
  end

  def handle_services_status(%{default: %{failing: false, min_response_time: delay}}, _)
      when delay <= 100 do
    {:default, 0}
  end

  def handle_services_status(_, default_failing_count)
      when default_failing_count < 1 do
    {:default, default_failing_count + 1}
  end

  def handle_services_status(
        %{fallback: %{failing: false, min_response_time: delay}},
        default_failing_count
      )
      when delay <= 50 do
    {:fallback, default_failing_count}
  end

  def handle_services_status(_, default_failing_count), do: {:none, default_failing_count}
end
