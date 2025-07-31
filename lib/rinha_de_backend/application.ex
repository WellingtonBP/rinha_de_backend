defmodule RinhaDeBackend.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RinhaDeBackend.Repo,
      {Finch,
       name: RinhaDeBackend.Finch,
       pools: %{
         :default => [size: 8, count: 1]
       }},
      RinhaDeBackendWeb.Endpoint,
      RinhaDeBackend.Payments.Workers.ServicesStatus,
      RinhaDeBackend.Payments.Workers.PaymentProcess,
      :poolboy.child_spec(:worker,
        name: {:local, :worker},
        worker_module: RinhaDeBackend.Payments.Workers.PaymentProcessPollboyWorker,
        size: 6,
        max_overflow: 2
      )
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
