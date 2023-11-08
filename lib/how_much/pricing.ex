defmodule HowMuch.Pricing do
  use GenServer
  require Logger
  import HowMuch.Utils

  defstruct symbol: "TWSE.0050", date: ~D[2000-01-01], price: 120, currency: :TWD

  @price_call_timeout 60000
  @ets_table :how_much_pricings

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
    last_close_price_date = yesterday()

    if unix_timestamp(date) < unix_timestamp(last_close_price_date) do
      GenServer.call(HowMuch.Pricing, {:price, stock, date}, @price_call_timeout)
    else
      GenServer.call(HowMuch.Pricing, {:price, stock, last_close_price_date}, @price_call_timeout)
    end
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
    pricing = fetch_pricing(symbol, date)

    if pricing do
      {:reply, pricing, state}
    else
      pricings = req_pricings(symbol, date)
      update_table(pricings)

      {
        :reply,
        fetched_pricings(pricings, symbol, date),
        state
      }
    end
  end

  @impl true
  def terminate(_reason, _state) do
    :dets.close(@ets_table)
  end

  defp fetch_pricing("TWD", date) do
    %{symbol: "TWD", date: date, price: 1, currency: :TWD}
  end

  defp fetch_pricing("USD", date) do
    %{symbol: "USD", date: date, price: 1, currency: :USD}
  end

  defp fetch_pricing("JPY", date) do
    %{symbol: "JPY", date: date, price: 1, currency: :JPY}
  end

  defp fetch_pricing(symbol, date) do
    key = table_key(symbol, date)

    case :dets.lookup(@ets_table, key) do
      [{^key, value}] ->
        value

      [] ->
        Logger.debug("no pricing in dets for #{symbol} on #{date}, will need to fetch...")
        nil
    end
  end

  defp table_key(symbol, date) do
    "#{symbol}@#{unix_timestamp(date) |> Integer.to_string()}"
  end

  defp update_table(pricings) do
    Enum.each(pricings, fn pricing ->
      :dets.insert(@ets_table, {
        table_key(pricing.symbol, pricing.date),
        pricing
      })
    end)

    :dets.sync(@ets_table)
  end

  defp fetched_pricings(pricings, symbol, date) do
    Enum.find(pricings, &(&1.symbol == symbol and &1.date == date))
    |> case do
      nil ->
        Logger.warning("pricing not found for #{symbol} on #{date}, price: 0, currency: :TWD")
        %HowMuch.Pricing{symbol: symbol, date: date, price: 0, currency: :TWD}

      found_pricing ->
        found_pricing
    end
  end

  # Utils

  def sort_fill_pricings([], _fill_until_date), do: []

  def sort_fill_pricings(pricings, fill_until_date) do
    sorted_pricings = sort_pricings_by_date(pricings)
    first_pricing = Enum.at(sorted_pricings, 0)
    end_pricing = Enum.at(sorted_pricings, -1)

    end_date =
      Enum.max_by([fill_until_date, end_pricing.date], &unix_timestamp/1)

    sorted_pricings_map = pricings_map(sorted_pricings)

    Enum.map(
      1..Date.diff(end_date, first_pricing.date),
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
    |> (&sort_pricings_by_date(&1 ++ sorted_pricings)).()
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
