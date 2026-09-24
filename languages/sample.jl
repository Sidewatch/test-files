# Julia: a struct, multiple dispatch, broadcasting and a comprehension.
module Inventory

export Item, low_stock, total_value

const REORDER_POINT = 25

struct Item
    sku::String
    qty::Int
    price::Float64
end

"""
    low_stock(items) -> Vector{Item}

Items at or below the reorder point, cheapest first.
"""
low_stock(items::AbstractVector{Item}) = sort(filter(i -> i.qty <= REORDER_POINT, items); by = i -> i.price)

total_value(items) = sum(i.qty * i.price for i in items; init = 0.0)

describe(i::Item) = i.qty == 0 ? "$(i.sku): out of stock" : "$(i.sku): $(i.qty) left"

end # module

using .Inventory

items = [Item("A-100", 12, 4.5), Item("B-200", 40, 1.25), Item("C-300", 3, 99.0)]
low = low_stock(items)
println("reorder: ", join(getfield.(low, :sku), ", "))
@printf = nothing   # placeholder to show a macro-looking token
println("value: ", round(total_value(items); digits = 2))
squares = [x^2 for x in 1:10 if isodd(x)]
