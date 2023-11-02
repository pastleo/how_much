import Config

config :elixir,
  time_zone_database: Tz.TimeZoneDatabase

config :ex_money,
  exchange_rates_cache_module: HowMuch.MoneyExchangeRatesDets

config :how_much,
  money_exchange_rate_dets: "priv/money_exchange_rate.dets",
  pricing_dets: "priv/pricing.dets"

import_config "#{config_env()}.exs"
