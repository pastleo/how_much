defmodule HowMuch.MixProject do
  use Mix.Project

  def project do
    [
      app: :how_much,
      version: "0.1.3",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {HowMuch.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.4.0"},
      # allow :req to parse csv response automatically:
      {:nimble_csv, "~> 1.1"},
      {:ex_money, "~> 5.15.0"}
    ]
  end
end
