defmodule RinhaDeBackendWeb.Router do
  use RinhaDeBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", RinhaDeBackendWeb do
    pipe_through :api
  end
end
