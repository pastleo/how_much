defmodule HowMuch.Record do
  defstruct name: "元大台灣50", symbol: "TWSE.0050", date: ~D[2000-01-01], amount: 1000, debt: false
  # or %HowMuch.Record{ name: "玉山 台幣綜存", symbol: "TWD" ... }

  @doc """
  data example: [
    ["", "TWSE.0050", "TWSE.2330"],
    ["2023-08-16", "1000", "2000"],
    ["2023-09-12", "1000", "3000"],
  ]
  """
  def from_table_data(data), do: from_table_data(data, false)

  def from_table_data(data, debt) do
    columns = from_table_data_columns(data)

    Enum.slice(data, 1..-1)
    |> Enum.flat_map(&from_table_data_row(&1, columns, debt))
  end

  defp from_table_data_columns(data) do
    Enum.at(data, 0)
    |> Enum.slice(1..-1)
    |> Enum.map(&String.split(&1, ":", parts: 2))
    |> Enum.map(fn
      [symbol] -> {symbol, symbol}
      [name, symbol] -> {name, symbol}
    end)
  end

  defp from_table_data_row(row, columns, debt) do
    with {:ok, date} <- Date.from_iso8601(Enum.at(row, 0)),
         amounts <- Enum.slice(row, 1..length(columns)) do
      Enum.zip(amounts, columns)
      |> Enum.map(fn {amount_str, name_symbol} ->
        {table_data_parse_amount(amount_str), name_symbol}
      end)
      |> Enum.filter(&is_float(elem(&1, 0)))
      |> Enum.map(fn {amount, {name, symbol}} ->
        %HowMuch.Record{
          name: name,
          symbol: symbol,
          date: date,
          amount: amount,
          debt: debt
        }
      end)
    else
      _ -> []
    end
  end

  defp table_data_parse_amount(nil), do: nil

  defp table_data_parse_amount(amount_str) do
    with {amount, _} <- Float.parse(amount_str) do
      amount
    else
      _ -> nil
    end
  end
end
