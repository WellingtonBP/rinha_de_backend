defmodule RinhaDeBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :rinha_de_backend,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        rinha_de_backend: [
          mode: :runtime,
          strip_beams: true
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {RinhaDeBackend.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.21"},
      {:finch, "~> 0.13"},
      {:jason, "~> 1.2"},
      {:bandit, "~> 1.5"}
    ]
  end
end
