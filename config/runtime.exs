import Config

if config_env() == :prod do
  database_url =
    System.get_env("DB_CONN_URL") ||
      raise """
      environment variable DB_CONN_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :rinha_de_backend, RinhaDeBackend.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("WORKERS_COUNT", "7")) + 1,
    ssl: false,
    stacktrace: false,
    show_sensitive_data_on_connection_error: false

  config :rinha_de_backend, RinhaDeBackendWeb.Endpoint,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: 4000
    ],
    server: true
end

config :payment_services,
  default_url: System.get_env("PAYMENT_SERVICE_URL_DEFAULT"),
  fallback_url: System.get_env("PAYMENT_SERVICE_URL_FALLBACK")
