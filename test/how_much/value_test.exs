defmodule HowMuch.ValueTest do
  use ExUnit.Case

  test "applies and serializes the record value multiplier" do
    record = %HowMuch.Record{
      name: "allocated-cash",
      symbol: "TWD",
      date: ~D[2026-07-21],
      amount: 100.0,
      value_multiplier: 0.64
    }

    assert [serialized] =
             [record]
             |> HowMuch.Value.calculate(:TWD, ~U[2026-07-21 00:00:00Z])
             |> HowMuch.Value.serialize(:TWD)

    assert serialized["amount"] == 100.0
    assert serialized["price"] == 1
    assert serialized["value_multiplier"] == 0.64
    assert serialized["value"] == 64.0
  end

  test "raises when an asset has multiple records on the same date" do
    records = [
      %HowMuch.Record{name: "cash", symbol: "TWD", date: ~D[2026-07-21], amount: 100.0},
      %HowMuch.Record{name: "cash", symbol: "TWD", date: ~D[2026-07-21], amount: 200.0}
    ]

    assert_raise ArgumentError,
                 ~s(multiple records found for asset "cash" on 2026-07-21),
                 fn ->
                   HowMuch.Value.calculate(records, :TWD, ~U[2026-07-21 00:00:00Z])
                 end
  end
end
