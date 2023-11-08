defmodule HowMuch.Record do
  defstruct name: "元大台灣50",
            symbol: "TWSE.0050",
            date: ~D[2000-01-01],
            amount: 1000,
            debt: false,
            tags: []

  # or %HowMuch.Record{ name: "玉山 台幣綜存", symbol: "TWD" ... }

  # for name, symbol and tag
  @field_re "[^: #]+"
  @column_re Regex.compile!("((#{@field_re}):)?(#{@field_re})(( *##{@field_re} *)*)")
  @tag_re Regex.compile!("##{@field_re}")

  @doc """
  data example: [
    ["", "bank1:TWD", "bank2:USD #fixed-deposit", "bank3:JPY #fixed-deposit"],
    ["2023-09-18", "10,000", "1,000.5", "25,000"],
    ["2023-09-19", "12,000", "2,000.0", "20,000"],
  ]
  """
  def from_table_data(data, options \\ []) do
    debt = Keyword.get(options, :debt, false)
    tags = Keyword.get(options, :tags, [])

    columns = from_table_data_columns(data)

    Enum.slice(data, 1..-1)
    |> Enum.flat_map(&from_table_data_row(&1, columns, debt, tags))
  end

  defp from_table_data_columns(data) do
    Enum.at(data, 0, [])
    |> Enum.slice(1..-1)
    |> Enum.map(fn column ->
      with matches when is_list(matches) <- Regex.run(@column_re, column) do
        Enum.slice(matches, 2..4)
        |> (fn
              ["", symbol, tags_part] -> {symbol, symbol, parse_tags_part(tags_part)}
              [name, symbol, tags_part] -> {name, symbol, parse_tags_part(tags_part)}
            end).()
      else
        _ -> nil
      end
    end)
  end

  defp parse_tags_part(tags_part_str) do
    Regex.scan(@tag_re, tags_part_str) |> List.flatten()
  end

  defp from_table_data_row(row, columns, debt, group_tags) do
    with {:ok, date} <- Date.from_iso8601(Enum.at(row, 0)),
         amounts <- Enum.slice(row, 1..length(columns)) do
      Enum.zip(amounts, columns)
      |> Enum.map(fn {amount_str, name_symbol} ->
        {table_data_parse_amount(amount_str), name_symbol}
      end)
      |> Enum.filter(&(is_float(elem(&1, 0)) and is_tuple(elem(&1, 1))))
      |> Enum.map(fn {amount, {name, symbol, tags}} ->
        %HowMuch.Record{
          name: name,
          symbol: symbol,
          date: date,
          amount: amount,
          debt: debt,
          tags: Enum.uniq(tags ++ group_tags)
        }
      end)
    else
      _ -> []
    end
  end

  defp table_data_parse_amount(nil), do: nil

  defp table_data_parse_amount(amount_str) do
    with {amount, _} <- String.replace(amount_str, ",", "") |> Float.parse() do
      amount
    else
      _ -> nil
    end
  end
end
