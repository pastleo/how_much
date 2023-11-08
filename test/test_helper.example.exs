ExUnit.start()

defmodule HowMuchTestData do
  def target_currency, do: :TWD
  def until_time, do: ~U[2023-09-20 03:14:18.490750Z]
  # def until_time, do: Date.utc_today() |> HowMuch.Utils.unix_timestamp()

  def fiat_assets_data,
    do: [
      ["", "bank1:TWD", "bank2:USD #fixed-deposit", "bank3:JPY #fixed-deposit"],
      ["2023-09-18", "10,000", "1,000.5", "25,000"],
      ["2023-09-19", "12,000", "2,000.0", "20,000"]
    ]

  def debt_data, do: []

  def twse_stocks_data,
    do: [
      ["", "TWSE.0050", "TWSE.2330"],
      ["2023-09-18", "1000", "2000", ""],
      ["2023-09-19", "1000", "3000", nil]
    ]

  def firstrade_data,
    do: [
      ["", "YH.VOO", ""],
      ["2023-09-18", "1"],
      ["2023-09-19", "2"]
    ]
end
