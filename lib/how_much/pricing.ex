defmodule HowMuch.Pricing do
  use GenServer
  require Logger
  import HowMuch.Utils

  defstruct symbol: "TWSE.0050", date: ~D[2000-01-01], price: 120, currency: :TWD

  @price_call_timeout 60000
  @ets_table :how_much_pricings
  @fiat_symbols %{"TWD" => :TWD, "USD" => :USD, "JPY" => :JPY}

  def req_pricings(symbol, date) do
    with module when not is_nil(module) <- HowMuch.Pricing.Fetcher.get_module(symbol) do
      apply(module, :req_pricings, [symbol, date])
    else
      _ ->
        Logger.warning("cannot find pricing fetcher module for #{symbol}")
        []
    end
  end

  # Client

  def start_link(_options) do
    GenServer.start_link(HowMuch.Pricing, nil, name: HowMuch.Pricing)
  end

  def stop() do
    GenServer.stop(HowMuch.Pricing)
  end

  def price(stock, date) do
    GenServer.call(HowMuch.Pricing, {:price, stock, date}, @price_call_timeout)
  end

  # Server

  @impl true
  def init(_args) do
    {:ok, name} =
      :dets.open_file(
        @ets_table,
        file: Application.fetch_env!(:how_much, :pricing_dets) |> String.to_charlist()
      )

    {:ok, name}
  end

  @impl true
  def handle_call({:price, symbol, date}, _from, state) do
    {:reply, handle_price_call(symbol, date), state}
  end

  @impl true
  def terminate(_reason, _state) do
    :dets.close(@ets_table)
  end

  defp handle_price_call(symbol, date) do
    with :continue <- fiat_symbol_pricing(symbol, date),
         :continue <- retrieve_pricing_from_dets(symbol, date),
         :continue <- req_pricings_update_table(symbol, date),
         :continue <- retrieve_latest_pricing_from_dets(symbol, date)
    do
      Logger.warning("HowMuch.Pricing: pricing not found for #{symbol} on #{date}, price: 0, currency: :TWD")
      %HowMuch.Pricing{symbol: symbol, date: date, price: 0, currency: :TWD}
    else
      pricing -> pricing
    end
  end

  defp fiat_symbol_pricing(symbol, date) do
    if Map.has_key?(@fiat_symbols, symbol) do
      %HowMuch.Pricing{
        symbol: symbol,
        date: date,
        price: 1,
        currency: Map.get(@fiat_symbols, symbol)
      }
    else
      :continue
    end
  end

  defp retrieve_pricing_from_dets(symbol, date) do
    key = table_key(symbol, date)

    case :dets.lookup(@ets_table, key) do
      [{^key, pricing}] -> pricing
      _ ->
        Logger.debug("HowMuch.Pricing: no pricing in dets for #{symbol} on #{date}, will need to fetch...")
        :continue
    end
  end

  defp req_pricings_update_table(symbol, date) do
    pricings =
      req_pricings(symbol, date)
      |> update_table()

    Enum.find(pricings, &(&1.symbol == symbol and &1.date == date))
    |> case do
      nil -> :continue
      pricing -> pricing
    end
  end

  defp retrieve_latest_pricing_from_dets(symbol, date) do
    key = table_latest_key(symbol)
    with [{^key, latest_pricing}] <- :dets.lookup(@ets_table, key),
         true <- unix_timestamp(latest_pricing.date) <= unix_timestamp(date)
    do
      Logger.debug("HowMuch.Pricing: using latest pricing in dets for #{symbol} on #{date}, price: #{latest_pricing.price}, currency: #{latest_pricing.currency}")
      latest_pricing
    else
      _ -> :continue
    end
  end

  defp table_key(symbol, date) do
    "#{symbol}@#{unix_timestamp(date) |> Integer.to_string()}"
  end
  defp table_latest_key(symbol) do
    "#{symbol}@latest"
  end

  defp update_table([]), do: []
  defp update_table(pricings) do
    {filled_pricings, end_pricing} = fill_pricings(pricings)

    update_table_each(filled_pricings)
    update_table_latest(end_pricing)

    :dets.sync(@ets_table)

    filled_pricings
  end

  defp update_table_each(filled_pricings) do
    Enum.each(filled_pricings, fn pricing ->
      :dets.insert(@ets_table, {
        table_key(pricing.symbol, pricing.date),
        pricing
      })
    end)
  end

  defp update_table_latest(end_pricing) do
    key = table_latest_key(end_pricing.symbol)

    case :dets.lookup(@ets_table, key) do
      [{^key, %{date: latest_date}}] ->
        unix_timestamp(latest_date) < unix_timestamp(end_pricing.date)
      _ -> true
    end
    |> if do
      :dets.insert(@ets_table, {key, end_pricing})
    end
  end

  defp fill_pricings(pricings) do
    sorted_pricings = sort_pricings_by_date(pricings)
    first_pricing = Enum.at(sorted_pricings, 0)
    end_pricing = Enum.at(sorted_pricings, -1)

    sorted_pricings_map = pricings_map(sorted_pricings)

    Enum.map(
      1..Date.diff(end_pricing.date, first_pricing.date),
      fn d -> Date.add(first_pricing.date, d) end
    )
    |> Enum.reduce(
      {[], first_pricing},
      fn date, {filling_pricings, last_pricing} ->
        if Map.has_key?(sorted_pricings_map, date) do
          {filling_pricings, Map.get(sorted_pricings_map, date)}
        else
          {[Map.put(last_pricing, :date, date) | filling_pricings], last_pricing}
        end
      end
    )
    |> elem(0)
    |> then(fn filled_pricings ->
      {filled_pricings ++ sorted_pricings, end_pricing}
    end)
  end

  defp sort_pricings_by_date(pricings) do
    Enum.sort_by(
      pricings,
      fn %{date: date} -> unix_timestamp(date) end
    )
  end

  defp pricings_map(pricings) do
    Enum.map(pricings, fn pricing -> {pricing.date, pricing} end)
    |> Map.new()
  end
end
