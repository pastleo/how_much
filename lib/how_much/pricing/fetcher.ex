defmodule HowMuch.Pricing.Fetcher do
  @moduledoc """

  example:

  ```elixir
  defmodule SomePricingFetcher do
    @behaviour HowMuch.Pricing.Fetcher

    @symbol_prefix "SOME."

    @impl true
    def symbol_prefix, do: @symbol_prefix

    @impl true
    def req_pricings(@symbol_prefix <> stock_symbol, date) do
      # ...
    end
  end
  ```
  """

  @callback symbol_prefix() :: String.t()
  @callback req_pricings(symbol :: String.t(), date :: Date.t()) :: [%HowMuch.Pricing{}]

  def register(module) do
    unless has_function?(module, :req_pricings, 2) do
      raise ArgumentError, "module #{inspect(module)} does not define req_pricings(symbol, date)"
    end

    get_modules()
    |> Map.put(apply(module, :symbol_prefix, []), module)
    |> put_modules()
  end

  def get_module(symbol) do
    get_modules()
    |> Enum.find(&String.starts_with?(symbol, elem(&1, 0)))
    |> (fn
          {_prefix, module} -> module
          _ -> nil
        end).()
  end

  @registry_key :fetcher_modules

  defp get_modules() do
    Application.get_env(:how_much, @registry_key, %{})
  end

  defp put_modules(modules) do
    Application.put_env(:how_much, @registry_key, modules)
  end

  defp has_function?(module, function, arity) do
    Code.ensure_loaded?(module) and function_exported?(module, function, arity)
  end
end
