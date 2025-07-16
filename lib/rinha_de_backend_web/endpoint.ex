defmodule RinhaDeBackendWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :rinha_de_backend

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug RinhaDeBackendWeb.Router
end
