import Config

config :ex_money,
  exchange_rates_cache_module: HowMuch.MoneyExchangeRatesDets,
  default_cldr_backend: HowMuch.Cldr

config :pythonx, :uv_init,
  pyproject_toml: """
  [project]
  name = "project"
  version = "0.0.0"
  requires-python = "==3.13.*"
  dependencies = [
    "yfinance==0.2.55"
  ]
  """

config :how_much,
  money_exchange_rate_dets: "priv/money_exchange_rate.dets",
  pricing_dets: "priv/pricing.dets"

import_config "#{config_env()}.exs"
