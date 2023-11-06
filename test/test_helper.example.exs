ExUnit.start()

defmodule HowMuchTestData do
  def target_currency, do: :TWD
  def until_time, do: Date.utc_today() |> HowMuch.Utils.unix_timestamp()

  def fiat_assets_data, do: []

  def debt_data, do: []

  def twse_stocks_data, do: []

  def firstrade_data, do: []
end
