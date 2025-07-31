defmodule RinhaDeBackend.Payments.Workers.ServicesStatus do
  use GenServer

  alias RinhaDeBackend.Payments.Schemas.PaymentServices
  alias RinhaDeBackend.Payments.Integrations.PaymentService
  alias RinhaDeBackend.Payments.Workers.PaymentProcess
  alias RinhaDeBackend.Repo

  def start_link(_), do: GenServer.start_link(__MODULE__, :no_args)

  def init(_) do
    schedule()

    {:ok,
     %{
       default: %{failing: false, min_response_time: 0},
       fallback: %{failing: false, min_response_time: 0}
     }}
  end

  def schedule do
    delay = 5000 + :rand.uniform(50)
    Process.send_after(self(), :run, delay)
  end

  def handle_info(:run, state) do
    schedule()

    Repo.transact(fn ->
      case try_lock() do
        true ->
          PaymentService.get_services_status()
          |> tap(fn new_state ->
            update_data(new_state, state)
            release_lock()
          end)
          |> then(&{:ok, &1})

        false ->
          {:ok, retrieve_data()}
      end
    end)
    |> then(fn {:ok, state} ->
      GenServer.cast(PaymentProcess, {:services_status, state})
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

  defp update_data(data, old) do
    Enum.each(data, fn
      {_service, :error} ->
        :error

      {service, %{failing: failing, min_response_time: min_response_time}} ->
        case old[service] do
          %{failing: ^failing, min_response_time: ^min_response_time} ->
            :not_update

          _ ->
            %{failing: failing, delay: min_response_time}
            |> then(&PaymentServices.changeset(%PaymentServices{name: to_string(service)}, &1))
            |> Repo.update()
        end
    end)
  end
end
