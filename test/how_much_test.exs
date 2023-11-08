defmodule HowMuchTest do
  use ExUnit.Case
  doctest HowMuch

  @tag timeout: :infinity
  test "calculate" do
    fiat_assets_records =
      HowMuchTestData.fiat_assets_data()
      |> HowMuch.Record.from_table_data(tags: ["#fiat"])

    debt_records =
      HowMuchTestData.debt_data()
      |> HowMuch.Record.from_table_data(debt: true)

    twse_stocks_assets_records =
      HowMuchTestData.twse_stocks_data()
      |> HowMuch.Record.from_table_data()

    firstrade_assets_records =
      HowMuchTestData.firstrade_data()
      |> HowMuch.Record.from_table_data()

    # IO.inspect({
    #   fiat_assets_records,
    #   debt_records,
    #   twse_stocks_assets_records,
    #   firstrade_assets_records,
    # })

    all_assets_values_serialized =
      (fiat_assets_records ++
         twse_stocks_assets_records ++ firstrade_assets_records ++ debt_records)
      |> HowMuch.Value.calculate(HowMuchTestData.target_currency(), HowMuchTestData.until_time())
      |> HowMuch.Value.serialize(HowMuchTestData.target_currency())

    IO.inspect(all_assets_values_serialized)
    IO.puts("length of all_assets_values_serialized: #{length(all_assets_values_serialized)}")

    assert HowMuch.hello() == :world
  end
end
