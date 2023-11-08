defmodule HowMuch.Pricing.Twse do
  @behaviour HowMuch.Pricing.Fetcher
  import HowMuch.Utils

  @symbol_prefix "TWSE."

  @impl true
  def symbol_prefix, do: @symbol_prefix

  @impl true
  def req_pricings(@symbol_prefix <> stock_symbol, date) do
    query_date_this_month =
      Date.from_erl!({date.year, date.month, 1})
      |> Calendar.strftime("%Y%m%d")

    query_date_prev_month =
      Date.add(date, -(date.day + 1))
      |> (&Date.from_erl!({&1.year, &1.month, 1})).()
      |> Calendar.strftime("%Y%m%d")

    fill_until_date =
      Date.days_in_month(date)
      |> (&Date.from_erl!({date.year, date.month, &1})).()
      |> (&Enum.min_by([&1, yesterday()], fn d -> unix_timestamp(d) end)).()

    Enum.flat_map([query_date_prev_month, query_date_this_month], fn query_date ->
      Req.get!(
        "https://www.twse.com.tw/exchangeReport/STOCK_DAY?response=json&date=#{query_date}&stockNo=#{stock_symbol}"
      ).body
      |> Map.get("data", [])
    end)
    |> Enum.map(fn row ->
      %HowMuch.Pricing{
        symbol: "#{@symbol_prefix}#{stock_symbol}",
        date: Enum.at(row, 0) |> parse_date(1911),
        price: Enum.at(row, 6) |> parse_price(),
        currency: :TWD
      }
    end)
    |> HowMuch.Pricing.sort_fill_pricings(fill_until_date)
  end

  defp parse_date(str, year_adj) do
    [roc_year_str, month_str, day_str] = String.trim(str) |> String.split("/")

    year =
      Integer.parse(roc_year_str)
      |> elem(0)
      |> (&(&1 + year_adj)).()

    month = Integer.parse(month_str) |> elem(0)
    day = Integer.parse(day_str) |> elem(0)

    Date.from_erl!({year, month, day})
  end

  defp parse_price(str) do
    Float.parse(str) |> elem(0)
  end
end
