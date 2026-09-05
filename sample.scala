// Scala — tree-sitter grammar vendored (tree-sitter/tree-sitter-scala v0.26.0)
package com.example.inventory

import scala.collection.mutable
import scala.util.{Try, Success, Failure}

/** An item held in stock. */
case class Item(name: String, price: Double, quantity: Int = 1)

sealed trait StockEvent
case class Added(item: Item) extends StockEvent
case class Removed(name: String) extends StockEvent

object Inventory {
  val MaxItems: Int = 100
  private val items = mutable.Map.empty[String, Item]

  def add(item: Item): Either[String, Item] =
    if (items.size >= MaxItems) Left(s"inventory full (${items.size})")
    else { items(item.name) = item; Right(item) }

  def total: Double = items.values.map(i => i.price * i.quantity).sum

  def describe(event: StockEvent): String = event match {
    case Added(Item(name, price, qty)) => f"added $name%s x$qty ($$${price}%.2f)"
    case Removed(name)                 => s"removed $name"
  }

  @main def run(): Unit = {
    for (n <- 1 to 3) add(Item(s"widget-$n", n * 9.99, n))
    println(s"total = ${total}")   // string interpolation + method call
  }
}
