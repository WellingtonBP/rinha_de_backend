defmodule RinhaDeBackend.Payments.Workers.ServicesStatus do
  use GenServer

  alias RinhaDeBackend.Payments.Schemas.PaymentServices
  alias RinhaDeBackend.Payments.Integrations.PaymentService
  alias RinhaDeBackend.Repo

  def start_link(_), do: GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)

  def init(_) do
    schedule()

    {:ok,
     %{
       default: %{failing: false, min_response_time: 0},
       fallback: %{failing: false, min_response_time: 0}
     }}
  end

  def get_status do
    GenServer.call(__MODULE__, :get, :infinity)
  end

  def schedule do
    Process.send_after(self(), :run, 5001)
  end

  def handle_call(:get, _, state) do
    {:reply, state, state}
  end

  def handle_info(:run, _) do
    Repo.transact(fn ->
      case try_lock() do
        true ->
          PaymentService.get_services_status()
          |> tap(fn new_state ->
            update_data(new_state)
            release_lock()
          end)
          |> then(&{:ok, &1})

        false ->
          {:ok, retrieve_data()}
      end
    end)
    |> then(fn {:ok, state} ->
      schedule()
      {:noreply, state}
    end)
  end

  defp try_lock do
    case Repo.query("SELECT pg_try_advisory_lock(1)") do
      {:ok, %{rows: [[true]]}} -> true
      _ -> false
    end
  end

  defp release_lock do
    Repo.query("SELECT pg_advisory_unlock(1)")
  end

  defp retrieve_data do
    Repo.all(PaymentServices)
    |> Enum.map(fn %PaymentServices{name: name, failing: failing, delay: delay} ->
      {:"#{name}",
       %{
         failing: failing,
         min_response_time: delay
       }}
    end)
    |> Enum.into(%{})
  end

  defp update_data(data) do
    Enum.each(data, fn
      {_service, :error} ->
        :error

      {service, %{failing: failing, min_response_time: min_response_time}} ->
        %{failing: failing, delay: min_response_time}
        |> then(&PaymentServices.changeset(%PaymentServices{name: to_string(service)}, &1))
        |> Repo.update()
    end)
  end
end
