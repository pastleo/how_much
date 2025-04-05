defmodule HowMuchTest do
  use ExUnit.Case
  doctest HowMuch

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

  @tag timeout: :infinity
  test "calculate" do
    fiat_assets_records =
      fiat_assets_data()
      |> HowMuch.Record.from_table_data(tags: ["#fiat"])

    debt_records =
      debt_data()
      |> HowMuch.Record.from_table_data(debt: true)

    twse_stocks_assets_records =
      twse_stocks_data()
      |> HowMuch.Record.from_table_data()

    firstrade_assets_records =
      firstrade_data()
      |> HowMuch.Record.from_table_data()

    # IO.inspect({
    #   fiat_assets_records,
    #   debt_records,
    #   twse_stocks_assets_records,
    #   firstrade_assets_records,
    # })

    all_assets_values_serialized =
      (fiat_assets_records
         ++ twse_stocks_assets_records
         ++ firstrade_assets_records
         ++ debt_records
      )
      |> HowMuch.Value.calculate(target_currency(), until_time())
      |> HowMuch.Value.serialize(target_currency())

    IO.inspect(all_assets_values_serialized)
    IO.puts("length of all_assets_values_serialized: #{length(all_assets_values_serialized)}")

    assert HowMuch.hello() == :world
  end
end
