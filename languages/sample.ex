defmodule Inventory do
  @moduledoc "Stock levels and reorder suggestions."

  @reorder_point 25

  defstruct sku: nil, qty: 0, price: 0.0

  @doc "Items at or below the reorder point."
  @spec low_stock([%Inventory{}]) :: [%Inventory{}]
  def low_stock(items) do
    items
    |> Enum.filter(&(&1.qty <= @reorder_point))
    |> Enum.sort_by(& &1.price)
  end

  def total_value(items), do: Enum.reduce(items, 0.0, fn %{qty: q, price: p}, acc -> acc + q * p end)

  def describe(%Inventory{sku: sku, qty: 0}), do: "#{sku}: out of stock"
  def describe(%Inventory{sku: sku, qty: qty}) when qty < 5, do: "#{sku}: only #{qty} left"
  def describe(%Inventory{sku: sku}), do: "#{sku}: fine"
end

items = [%Inventory{sku: "A-100", qty: 12, price: 4.5}, %Inventory{sku: "C-300", qty: 3, price: 99.0}]

case Inventory.low_stock(items) do
  [] -> IO.puts("nothing to reorder")
  low -> IO.puts("reorder: " <> Enum.map_join(low, ", ", & &1.sku))
end

IO.puts(:io_lib.format("value ~.2f", [Inventory.total_value(items)]))
