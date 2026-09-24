// Odin: a struct, a procedure with multiple returns, and a dynamic array.
package sample

import "core:fmt"
import "core:slice"

REORDER_POINT :: 25

Item :: struct {
    sku:   string,
    qty:   int,
    price: f64,
}

low_stock :: proc(items: []Item) -> (low: [dynamic]Item, value: f64) {
    for it in items {
        value += f64(it.qty) * it.price
        if it.qty <= REORDER_POINT do append(&low, it)
    }
    slice.sort_by(low[:], proc(a, b: Item) -> bool { return a.price < b.price })
    return
}

main :: proc() {
    items := []Item{{"A-100", 12, 4.5}, {"B-200", 40, 1.25}, {"C-300", 3, 99.0}}
    low, value := low_stock(items)
    defer delete(low)

    for it, i in low {
        fmt.printf("%d. %s: %d left\n", i + 1, it.sku, it.qty)
    }
    fmt.printfln("value: %.2f", value)
}
