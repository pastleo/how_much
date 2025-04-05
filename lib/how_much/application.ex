defmodule HowMuch.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    HowMuch.Pricing.Fetcher.register(HowMuch.Pricing.Twse)
    HowMuch.Pricing.Fetcher.register(HowMuch.Pricing.YahooFinance)

    children = [
      HowMuch.Pricing,
      HowMuch.Pricing.YahooFinance
    ]

    opts = [strategy: :one_for_one, name: HowMuch.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
