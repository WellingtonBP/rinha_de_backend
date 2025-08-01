defmodule RinhaDeBackend.Payments.Workers.PaymentPersist do
  use GenServer

  alias RinhaDeBackend.Payments.Schemas.Payments
  alias RinhaDeBackend.Repo

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :persist, 1000)
    {:ok, []}
  end

  def handle_info(:persist, []) do
    Process.send_after(self(), :persist, 200)
    {:noreply, []}
  end

  def handle_info(:persist, payments) do
    Process.send_after(self(), :persist, 200)
    insert_payments(payments)
    {:noreply, []}
  end

  def handle_cast({:new, payment}, state) do
    {:noreply, [payment | state]}
  end

  defp insert_payments(payments) do
    Repo.insert_all(Payments, payments)
  end
end
