import Config

if config_env() == :prod do
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
