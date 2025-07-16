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

  def summary(conn, params) do
    case validate_summary_params(params) do
      :error ->
        conn
        |> put_status(400)
        |> json(%{errors: "invalid request"})

      parsed_params ->
        parsed_params
        |> Payments.summary()
        |> then(fn data ->
          conn
          |> put_status(200)
          |> json(data)
        end)
    end
  end

  defp validate_summary_params(%{"from" => fromstr, "to" => tostr})
       when not is_nil(fromstr) and not is_nil(tostr) do
    case {DateTime.from_iso8601(fromstr), DateTime.from_iso8601(tostr)} do
      {{:ok, from, _}, {:ok, to, _}} ->
        %{from: from, to: to}

      _ ->
        :error
    end
  end

  defp validate_summary_params(%{"from" => fromstr})
       when not is_nil(fromstr) do
    case DateTime.from_iso8601(fromstr) do
      {:ok, from, _} ->
        %{from: from}

      _ ->
        :error
    end
  end

  defp validate_summary_params(%{"to" => tostr})
       when not is_nil(tostr) do
    case DateTime.from_iso8601(tostr) do
      {:ok, to, _} ->
        %{to: to}

      _ ->
        :error
    end
  end

  defp validate_summary_params(_) do
    %{}
  end
end
