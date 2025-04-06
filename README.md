# HowMuch

Calculate how much assets and value I have.

## Usage on livebook

Add these lines to `Notebook dependencies and setup` to install package and set config:

```elixir
Application.put_all_env(
  handsontable: [
    license_key: "non-commercial-and-evaluation"
  ],
  ex_money: [
    open_exchange_rates_app_id: System.fetch_env!("LB_OPEN_EXCHANGE_RATES_APP_ID"),
    exchange_rates_cache_module: HowMuch.MoneyExchangeRatesDets,
    default_cldr_backend: HowMuch.Cldr
  ],
  how_much: [
    money_exchange_rate_dets: "/data/priv/money_exchange_rate.dets",
    pricing_dets: "/data/priv/pricing.dets"
  ]
)

File.mkdir_p!("/data/priv")

Mix.install([
  {:handsontable_kino_smartcell,
   git: "https://github.com/pastleo/handsontable_kino_smartcell.git", tag: "0.1.7"},
  {:how_much, git: "https://github.com/pastleo/how_much.git", tag: "0.1.5"},
  {:kino_explorer, "~> 0.1.11"},
  {:vega_lite, "~> 0.1.6"},
  {:kino_vega_lite, "~> 0.1.7"}
])

Pythonx.uv_init("""
[project]
name = "project"
version = "0.0.0"
requires-python = "==3.13.*"
dependencies = [
  "yfinance==0.2.55"
]
""")
```

And add `OPEN_EXCHANGE_RATES_APP_ID` to [secret](https://news.livebook.dev/hubs-and-secret-management---launch-week-1---day-3-3tMaJ2), visit [https://openexchangerates.org/](https://openexchangerates.org/) to get one

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `how_much` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:how_much, git: "https://github.com/pastleo/how_much.git", tag: "0.1.3"},
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

## Usage & Demo

[![Run in Livebook](https://livebook.dev/badge/v1/gray.svg)](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Fpastleo%2Fhow_much%2Fmain%2Fdemo.livemd)

> or see `test/how_much_test.exs` and `HowMuchTestData` in test helper.
