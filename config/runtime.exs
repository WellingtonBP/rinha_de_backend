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
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    ssl: false

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :rinha_de_backend, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :rinha_de_backend, RinhaDeBackendWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    server: true
end
