defmodule RinhaDeBackend.Release do
  @moduledoc """
  Runtime tasks for application release.
  That's includes run ecto migrations and another setup tasks.
  """

  @app :rinha_de_backend
  @repo RinhaDeBackend.Repo

  def migrate do
    load_app()
    Ecto.Migrator.run(@repo, :up, all: true)
  end

  def rollback(version) do
    load_app()
    Ecto.Migrator.run(@repo, :down, to: version)
  end

  defp load_app do
    Application.load(@app)
    Application.ensure_all_started(@app)
  end
end
