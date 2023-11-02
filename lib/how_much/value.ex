defmodule HowMuch.Value do
  require Logger
  import HowMuch.Utils

  defstruct record: %HowMuch.Record{},
            date: ~D[2000-01-01],
            price: %HowMuch.Pricing{},
            value: Money.new(:TWD, 120_000)

  @ex_money_float_round 8

  def calculate(asset_records, target_currency, until_date) do
    Enum.group_by(asset_records, &Map.get(&1, :name))
    |> Enum.flat_map(fn {_name, records} ->
      calculate_asset(records, target_currency, until_date)
    end)
  end

  def serialize(values, target_currency) do
    Enum.map(values, fn %{
                          record: %{name: name, symbol: symbol, amount: amount},
                          date: date,
                          price: %{price: price, currency: currency},
                          value: value
                        } ->
      %{
        "name" => name,
        "symbol" => symbol,
        "date" => date,
        "amount" => amount,
        "price" => price,
        "price_currency" => Atom.to_string(currency),
        "value" => Money.to_decimal(value) |> Decimal.to_float(),
        "currency" => Atom.to_string(target_currency)
      }
    end)
  end

  defp calculate_asset([], _target_currency, _until_date), do: []

  defp calculate_asset(asset_records, target_currency, until_date) do
    until_timestamp = unix_timestamp(until_date)

    sorted_records =
      Enum.map(asset_records, &({&1, unix_timestamp(&1.date)}))
      |> Enum.filter(&(elem(&1, 1) <= until_timestamp))
      |> Enum.uniq_by(&(elem(&1, 1)))
      |> Enum.sort_by(&(elem(&1, 1)))
      |> Enum.map(&(elem(&1, 0)))

    last_record = Enum.at(sorted_records, -1)

    Enum.zip(
      Enum.slice(sorted_records, 0..-2),
      Enum.slice(sorted_records, 1..-1)
    )
    |> Enum.flat_map(fn {record_a, record_b} ->
      dates_between_records(record_a, record_b)
    end)
    |> (&(&1 ++ dates_between_records(last_record, %{date: until_date}))).()
    |> Enum.map(fn {record, date} ->
      HowMuch.Pricing.price(record.symbol, date)
      |> (&calculate_value(record, date, &1, target_currency)).()
    end)
  end

  defp dates_between_records(record_a, record_b) do
    Enum.map(
      0..(Date.diff(record_b.date, record_a.date) - 1),
      fn d -> Date.add(record_a.date, d) end
    )
    |> Enum.map(fn date ->
      {record_a, date}
    end)
  end

  defp calculate_value(record, date, price, target_currency) do
    Float.round(record.amount * price.price, @ex_money_float_round)
    |> to_currency(price.currency, target_currency, date)
    |> (&if(record.debt, do: Money.mult!(&1, -1), else: &1)).()
    |> (&%HowMuch.Value{
          record: record,
          date: date,
          price: price,
          value: &1
        }).()
  end

  defp to_currency(amount, currency, target_currency, _date) when currency == target_currency do
    Money.from_float(target_currency, amount)
  end

  defp to_currency(amount, currency, target_currency, date) do
    with money <- Money.from_float(currency, amount),
         {:ok, target_currency_value} <-
           Money.to_currency(
             money,
             target_currency,
             Money.ExchangeRates.historic_rates(date)
           ) do
      target_currency_value
    else
      _ ->
        Logger.warning(
          "Convert currency from #{currency} to #{target_currency} on #{date} failed"
        )

        Money.new(target_currency, 0)
    end
  end
end