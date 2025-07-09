defmodule RinhaDeBackend.Repo do
  use Ecto.Repo,
    otp_app: :rinha_de_backend,
    adapter: Ecto.Adapters.Postgres
end
