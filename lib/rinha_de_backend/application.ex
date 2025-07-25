defmodule RinhaDeBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RinhaDeBackend.Repo,
      {Finch,
       name: RinhaDeBackend.Finch,
       pools: %{
         :default => [size: 30, count: 10]
       }},
      RinhaDeBackendWeb.Endpoint,
      RinhaDeBackend.Payments.Workers.ServicesStatus,
      RinhaDeBackend.Payments.Workers.PaymentProcess
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RinhaDeBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RinhaDeBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
