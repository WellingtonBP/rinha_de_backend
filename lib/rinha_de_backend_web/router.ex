defmodule RinhaDeBackendWeb.Router do
  use RinhaDeBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RinhaDeBackendWeb do
    pipe_through :api

    post "/payments", PaymentsController, :add_payment
    get "/payments-summary", PaymentsController, :summary
  end
end
