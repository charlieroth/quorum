defmodule Quorum.MixProject do
  use Mix.Project

  def project do
    [
      app: :quorum,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Quorum.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_pubsub, "~> 2.1"},
      {:libcluster, "~> 3.3"},
      {:libring, "~> 1.6"},
      {:uniq, "~> 0.6.1"}
    ]
  end
end
