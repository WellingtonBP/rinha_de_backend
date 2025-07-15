defmodule RinhaDeBackendWeb.PaymentsController do
  use RinhaDeBackendWeb, :controller

  alias RinhaDeBackend.Payments

  def add_payment(conn, %{"correlationId" => _, "amount" => _} = body) do
    body
    |> Payments.new_payment()
    |> case do
      :server_error ->
        conn
        |> put_status(500)
        |> json(%{})

      %{errors: _} = e ->
        conn
        |> put_status(400)
        |> json(e)

      response ->
        json(conn, response)
    end
  end

  def add_payment(conn, _) do
    conn
    |> put_status(400)
    |> json(%{errors: "invalid request"})
  end
end
