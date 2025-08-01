defmodule RinhaDeBackendWeb.PaymentsController do
  use RinhaDeBackendWeb, :controller

  alias RinhaDeBackend.Payments

  def add_payment(conn, body) do
    Payments.new_payment(body)
    send_resp(conn, 204, "")
  end

  def summary(conn, params) do
    params
    |> Payments.summary()
    |> then(fn data ->
      conn
      |> put_status(200)
      |> json(data)
    end)
  end

  def purge_payments(conn, _) do
    Payments.purge_payments()

    send_resp(conn, 204, "")
  end
end
