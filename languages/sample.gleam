// Gleam: a typed result pipeline over parsed prices.
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/io

pub type Item {
  Item(sku: String, pence: Int)
}

pub type ParseError {
  BadNumber(String)
  Missing
}

pub fn parse(line: String) -> Result(Item, ParseError) {
  case string.split(line, ",") {
    [sku, price] ->
      int.parse(price)
      |> result.map_error(fn(_) { BadNumber(price) })
      |> result.map(fn(p) { Item(sku, p) })
    _ -> Error(Missing)
  }
}

pub fn total(lines: List(String)) -> Int {
  lines
  |> list.filter_map(parse)
  |> list.map(fn(item) { item.pence })
  |> int.sum
}

pub fn main() {
  let lines = ["A-100,450", "B-200,oops", "C-300,9900"]
  io.println("total: " <> int.to_string(total(lines)))
}
