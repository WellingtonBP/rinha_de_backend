defmodule RinhaDeBackend.Payments.Workers.PaymentProcessSupervisor do
  use DynamicSupervisor

  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def process(payment) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {RinhaDeBackend.Payments.Workers.PaymentProcessWorker, payment}
      )

    pid
  end
end
