defmodule HowMuch.Record do
  defstruct name: "元大台灣50",
            symbol: "TWSE.0050",
            date: ~D[2000-01-01],
            amount: 1000,
            value_multiplier: 1.0,
            price_currency_override: nil,
            debt: false,
            tags: []

  # or %HowMuch.Record{ name: "玉山 台幣綜存", symbol: "TWD" ... }

  # for name, symbol and tag
  @field_re "[^: #()]+"
  @value_multiplier_re "[0-9]+(?:\\.[0-9]+)?"
  @column_re Regex.compile!(
               "^\\s*(?:(?<name>#{@field_re}):)?(?<symbol>#{@field_re})" <>
                 "(?:\\((?<value_multiplier>#{@value_multiplier_re})x" <>
                 "(?<price_currency>[A-Z]{3})\\))?" <>
                 "(?<tags>(?:\\s*##{@field_re})*)\\s*$"
             )
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

    Enum.slice(data, 1..-1//1)
    |> Enum.flat_map(&from_table_data_row(&1, columns, debt, tags))
    |> Enum.sort_by(& &1.date, Date)
  end

  defp from_table_data_columns(data) do
    Enum.at(data, 0, [])
    |> Enum.slice(1..-1//1)
    |> Enum.map(fn column ->
      case Regex.named_captures(@column_re, column) do
        %{
          "name" => name,
          "price_currency" => price_currency,
          "symbol" => symbol,
          "tags" => tags_part,
          "value_multiplier" => value_multiplier
        } ->
          with {:ok, price_currency_override} <- parse_price_currency(price_currency) do
            name = if name == "", do: symbol, else: name

            {name, symbol, parse_tags_part(tags_part), parse_value_multiplier(value_multiplier),
             price_currency_override}
          else
            _ -> nil
          end

        _ ->
          nil
      end
    end)
  end

  defp parse_tags_part(tags_part_str) do
    Regex.scan(@tag_re, tags_part_str) |> List.flatten()
  end

  defp parse_value_multiplier(""), do: 1.0

  defp parse_value_multiplier(value_multiplier_str) do
    {value_multiplier, ""} = Float.parse(value_multiplier_str)
    value_multiplier
  end

  defp parse_price_currency(""), do: {:ok, nil}
  defp parse_price_currency(price_currency), do: Money.validate_currency(price_currency)

  defp from_table_data_row(row, columns, debt, group_tags) do
    with {:ok, date} <- Date.from_iso8601(Enum.at(row, 0)),
         amounts <- Enum.slice(row, 1..length(columns)) do
      Enum.zip(amounts, columns)
      |> Enum.map(fn {amount_str, name_symbol} ->
        {table_data_parse_amount(amount_str), name_symbol}
      end)
      |> Enum.filter(&(is_float(elem(&1, 0)) and is_tuple(elem(&1, 1))))
      |> Enum.map(fn {amount, {name, symbol, tags, value_multiplier, price_currency_override}} ->
        %HowMuch.Record{
          name: name,
          symbol: symbol,
          date: date,
          amount: amount,
          value_multiplier: value_multiplier,
          price_currency_override: price_currency_override,
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
