defmodule HowMuch.RecordTest do
  use ExUnit.Case, async: true

  test "parses tags and a trailing value multiplier" do
    data = [
      ["", "some-gold:YH.GC=F #tag-1 #tag-2 (0.64x)"],
      ["2026-07-21", "2.5"]
    ]

    assert [record] = HowMuch.Record.from_table_data(data)
    assert record.name == "some-gold"
    assert record.symbol == "YH.GC=F"
    assert record.tags == ["#tag-1", "#tag-2"]
    assert record.amount == 2.5
    assert record.value_multiplier == 0.64
  end

  test "defaults the value multiplier to one" do
    data = [
      ["", "bank3:JPY #fixed-deposit"],
      ["2026-07-21", "100"]
    ]

    assert [%HowMuch.Record{value_multiplier: 1.0}] =
             HowMuch.Record.from_table_data(data)
  end

  test "rejects a malformed value multiplier" do
    data = [
      ["", "some-gold:YH.GC=F #tag-1 (invalidx)"],
      ["2026-07-21", "2.5"]
    ]

    assert HowMuch.Record.from_table_data(data) == []
  end
end
