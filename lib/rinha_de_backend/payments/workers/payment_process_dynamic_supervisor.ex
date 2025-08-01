defmodule RinhaDeBackend.Payments.Workers.PaymentProcessDynamicSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_worker() do
    {:ok, _pid} =
      DynamicSupervisor.start_child(
        __MODULE__,
        RinhaDeBackend.Payments.Workers.PaymentProcessWorker
      )
  end
end
