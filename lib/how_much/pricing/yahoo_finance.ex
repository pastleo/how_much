defmodule HowMuch.Pricing.YahooFinance do
  @moduledoc """
  ref: https://github.com/mtanca/YahooFinanceElixir/blob/master/lib/historical.ex
  """
  @behaviour HowMuch.Pricing.Fetcher
  use GenServer

  require Logger

  @symbol_prefix "YH."

  @impl true
  def symbol_prefix, do: @symbol_prefix

  @impl true
  def req_pricings(@symbol_prefix <> stock_symbol, date) do
    GenServer.call(HowMuch.Pricing.YahooFinance, {:req_pricings, stock_symbol, date})
  end

  # GenServer
  def start_link(_options) do
    GenServer.start_link(HowMuch.Pricing.YahooFinance, nil, name: HowMuch.Pricing.YahooFinance)
  end

  @impl true
  def init(_) do
    {:ok, %{python_globals: nil}}
  end

  @impl true
  def handle_call({:req_pricings, stock_symbol, date}, _from, state) do
    handle_req_pricings(stock_symbol, date, state)
  end

  # ===

  defp handle_req_pricings(stock_symbol, date, %{python_globals: nil} = state) do
    Logger.debug("HowMuch.Pricing.YahooFinance: initializing python_globals...")

    Path.dirname(__ENV__.file)
    |> Path.join("yahoo_finance/yfinance.py")
    |> File.read!()
    |> Pythonx.eval(%{})
    |> then(fn {_, python_globals} ->
      Map.put(state, :python_globals, python_globals)
    end)
    |> then(fn new_state ->
       handle_req_pricings(stock_symbol, date, new_state)
    end)
  end
  defp handle_req_pricings(stock_symbol, date, %{python_globals: python_globals} = state) do
    {
      :reply,
      fetch_yfinance(stock_symbol, date, python_globals),
      state
    }
  end

  defp fetch_yfinance(stock_symbol, date, python_globals) do
    start_date = Date.add(date, -30) |> Date.to_iso8601()
    stock_currency = currency(stock_symbol)

    try do
      Pythonx.eval("fetch_tick_3mo(\"#{stock_symbol}\", \"#{start_date}\")", python_globals)
      |> elem(0)
      |> Pythonx.decode()
      |> Enum.map(fn {price_date, price} ->
        %HowMuch.Pricing{
          symbol: "#{@symbol_prefix}#{stock_symbol}",
          date: Date.from_iso8601!(price_date),
          price: price,
          currency: stock_currency
        }
      end)
    rescue
      error ->
        Logger.error("HowMuch.Pricing.YahooFinance.fetch_yfinance: #{inspect(error)}")
        []
    end
  end

  defp currency(stock_symbol) do
    case String.split(stock_symbol, ".", parts: 2) do
      [_symbol, "TW"] -> :TWD
      _ -> :USD
    end
  end
end
