defmodule RinhaDeBackend.Application do
  use Application

  @impl true
  def start(_type, _args) do
    workers_count = String.to_integer(System.get_env("WORKERS_COUNT", "6"))

    children = [
      RinhaDeBackend.Repo,
      RinhaDeBackend.Payments.Workers.PaymentProcessDynamicSupervisor,
      {Finch,
       name: RinhaDeBackend.Finch,
       pools: %{
         :default => [size: workers_count, count: 1]
       }},
      RinhaDeBackendWeb.Endpoint,
      RinhaDeBackend.Payments.Workers.ServicesStatus,
      {RinhaDeBackend.Payments.Workers.PaymentProcess, workers_count}
    ]

    opts = [strategy: :one_for_one, name: RinhaDeBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    RinhaDeBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
