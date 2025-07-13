defmodule RinhaDeBackendWeb.Router do
  use RinhaDeBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RinhaDeBackendWeb do
    pipe_through :api

    get "/healthcheck", PaymentsController, :payment_service_healthcheck
  end
end
