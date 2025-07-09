defmodule RinhaDeBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RinhaDeBackendWeb.Telemetry,
      RinhaDeBackend.Repo,
      {DNSCluster, query: Application.get_env(:rinha_de_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RinhaDeBackend.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: RinhaDeBackend.Finch},
      # Start a worker by calling: RinhaDeBackend.Worker.start_link(arg)
      # {RinhaDeBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      RinhaDeBackendWeb.Endpoint
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
