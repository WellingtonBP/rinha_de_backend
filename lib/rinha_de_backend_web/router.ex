defmodule RinhaDeBackendWeb.Router do
  use RinhaDeBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RinhaDeBackendWeb do
    pipe_through :api

    post "/payments", PaymentsController, :add_payment
    post "/purge-payments", PaymentsController, :purge_payments
    get "/payments-summary", PaymentsController, :summary
  end
end
