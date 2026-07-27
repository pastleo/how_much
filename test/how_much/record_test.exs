defmodule HowMuch.RecordTest do
  use ExUnit.Case, async: true

  test "parses an inline value multiplier and price currency override" do
    data = [
      ["", "some-gold:YH.GC=F(0.64xTWD) #tag-1 #tag-2"],
      ["2026-07-21", "2.5"]
    ]

    assert [record] = HowMuch.Record.from_table_data(data)
    assert record.name == "some-gold"
    assert record.symbol == "YH.GC=F"
    assert record.tags == ["#tag-1", "#tag-2"]
    assert record.amount == 2.5
    assert record.value_multiplier == 0.64
    assert record.price_currency_override == :TWD
  end

  test "defaults the value multiplier and price currency override" do
    data = [
      ["", "bank3:JPY #fixed-deposit"],
      ["2026-07-21", "100"]
    ]

    assert [%HowMuch.Record{value_multiplier: 1.0, price_currency_override: nil}] =
             HowMuch.Record.from_table_data(data)
  end

  test "rejects a malformed inline modifier" do
    data = [
      ["", "some-gold:YH.GC=F(0.64xZZZ) #tag-1"],
      ["2026-07-21", "2.5"]
    ]

    assert HowMuch.Record.from_table_data(data) == []
  end
end
