defmodule HowMuch.Pricing.YahooFinance do
  @moduledoc """
  ref: https://github.com/mtanca/YahooFinanceElixir/blob/master/lib/historical.ex
  """

  def req_pricings("YH." <> stock_symbol, date) do
    request_with_crumb =
      Req.get!("https://finance.yahoo.com/quote/#{stock_symbol}/history")

    crumb = request_with_crumb.body |> extract_crumb() |> format_crumb()

    start_date_unix =
      Date.add(date, -(date.day + 1))
      |> (&Date.from_erl!({&1.year, &1.month, 1})).()
      |> HowMuch.Utils.unix_timestamp()

    end_date =
      Date.days_in_month(date)
      |> (&Date.from_erl!({date.year, date.month, &1})).()

    end_date_unix = HowMuch.Utils.unix_timestamp(end_date)

    [header | rows] =
      Req.get!(
        "https://query1.finance.yahoo.com/v7/finance/download/#{stock_symbol}?period1=#{start_date_unix}&period2=#{end_date_unix}&interval=1d&events=history&crumb=#{crumb}"
      ).body

    Enum.map(rows, fn row ->
      Enum.zip(header, row)
      |> Enum.into(%{})
    end)
    |> Enum.map(fn row ->
      %HowMuch.Pricing{
        symbol: "YH.#{stock_symbol}",
        date: Map.get(row, "Date") |> Date.from_iso8601() |> elem(1),
        price: Map.get(row, "Close") |> Float.parse() |> elem(0),
        currency: currency(stock_symbol)
      }
    end)
    |> HowMuch.Pricing.sort_fill_pricings(end_date)
  end

  defp extract_crumb(reponse_body) do
    crumb = Regex.scan(~r/"crumb":"(.+?)"/, reponse_body)

    crumb
    |> List.last()
    |> Enum.at(1)
  end

  defp format_crumb(crumb) do
    cond do
      String.contains?(crumb, "002F") -> String.replace(crumb, "\\u002F", "/")
      true -> crumb
    end
  end

  defp currency(stock_symbol) do
    case String.split(stock_symbol, ".", parts: 2) do
      [_symbol, "TWO"] -> :TWD
      _ -> :USD
    end
  end
end
