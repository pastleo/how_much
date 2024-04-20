defmodule HowMuch.Pricing.YahooFinance do
  @moduledoc """
  ref: https://github.com/mtanca/YahooFinanceElixir/blob/master/lib/historical.ex
  """
  @behaviour HowMuch.Pricing.Fetcher
  import HowMuch.Utils

  @symbol_prefix "YH."

  @impl true
  def symbol_prefix, do: @symbol_prefix

  @impl true
  def req_pricings(@symbol_prefix <> stock_symbol, date) do
    start_date_unix =
      Date.add(date, -(date.day + 1))
      |> (&Date.from_erl!({&1.year, &1.month, 1})).()
      |> HowMuch.Utils.unix_timestamp()

    end_date =
      Date.days_in_month(date)
      |> (&Date.from_erl!({date.year, date.month, &1})).()
      |> (&Enum.min_by([&1, yesterday()], fn d -> unix_timestamp(d) end)).()

    end_date_unix = HowMuch.Utils.unix_timestamp(end_date)

    [header | rows] =
      Req.get!(
        "https://query1.finance.yahoo.com/v7/finance/download/#{stock_symbol}?period1=#{start_date_unix}&period2=#{end_date_unix}&interval=1d&events=history"
      ).body

    Enum.map(rows, fn row ->
      Enum.zip(header, row)
      |> Enum.into(%{})
    end)
    |> Enum.map(fn row ->
      %HowMuch.Pricing{
        symbol: "#{@symbol_prefix}#{stock_symbol}",
        date: Map.get(row, "Date") |> Date.from_iso8601() |> elem(1),
        price: Map.get(row, "Close") |> Float.parse() |> elem(0),
        currency: currency(stock_symbol)
      }
    end)
    |> HowMuch.Pricing.sort_fill_pricings(end_date)
  end

  defp currency(stock_symbol) do
    case String.split(stock_symbol, ".", parts: 2) do
      [_symbol, "TWO"] -> :TWD
      _ -> :USD
    end
  end
end
