defmodule RinhaDeBackendWeb.PaymentsController do
  use RinhaDeBackendWeb, :controller

  alias RinhaDeBackend.Payments.Integrations.PaymentService

  def payment_service_healthcheck(conn, _) do
    json(conn, PaymentService.get_services_status())
  end
end
