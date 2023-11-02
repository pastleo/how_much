defmodule HowMuch.MoneyExchangeRatesDets do
  @moduledoc """
  Money.ExchangeRates.Cache implementation for
  :dets
  """

  @behaviour Money.ExchangeRates.Cache

  @ets_table :exchange_rates

  require Logger
  require Money.ExchangeRates.Cache.EtsDets
  Money.ExchangeRates.Cache.EtsDets.define_common_functions()

  def init do
    {:ok, name} = :dets.open_file(
      @ets_table,
      file: Application.fetch_env!(:how_much, :money_exchange_rate_dets) |> String.to_charlist()
    )
    name
  end

  def terminate do
    :dets.close(@ets_table)
  end

  def get(key) do
    case :dets.lookup(@ets_table, key) do
      [{^key, value}] ->
        value
      [] ->
        Logger.debug("no exchange rate in dets for #{key}, will need to fetch...")
        nil
    end
  end

  def put(key, value) do
    :dets.insert(@ets_table, {key, value})
    :dets.sync(@ets_table)
    value
  end
end
