defmodule HowMuch.MixProject do
  use Mix.Project

  def project do
    [
      app: :how_much,
      version: "0.1.4",
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
      {:httpoison, "~> 2.0"},
      {:ex_money, "~> 5.21"},
      {:pythonx, "~> 0.4.0"}
    ]
  end
end
