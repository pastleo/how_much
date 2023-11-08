# HowMuch

Calculate how much assets and value I have.

## Usage on livebook

Add these lines to `Notebook dependencies and setup` to install package and set config:

```elixir
Application.put_all_env(
  ex_money: [
    open_exchange_rates_app_id: System.fetch_env!("LB_OPEN_EXCHANGE_RATES_APP_ID"),
    exchange_rates_cache_module: HowMuch.MoneyExchangeRatesDets,
  ],
  how_much: [
    money_exchange_rate_dets: "priv/money_exchange_rate.dets",
    pricing_dets: "priv/pricing.dets"
  ]
)

File.mkdir_p!("priv")

Mix.install([
  {:how_much, git: "https://github.com/pastleo/how_much.git", tag: "0.1.1"},
])
```

And add `OPEN_EXCHANGE_RATES_APP_ID` to [secret](https://news.livebook.dev/hubs-and-secret-management---launch-week-1---day-3-3tMaJ2), visit [https://openexchangerates.org/](https://openexchangerates.org/) to get one

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `how_much` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:how_much, git: "https://github.com/pastleo/how_much.git", tag: "0.1.1"},
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/how_much>.

## Development

```bash
cp config/example.exs config/dev.exs
cp config/example.exs config/test.exs
cp test/test_helper.example.exs test/test_helper.exs
```

configure these files and run `mix test` or `iex -S mix` to iterate development

## Usage

see `test/how_much_test.exs`
