"""Module for computing simple order statistics."""

import math
from dataclasses import dataclass

MAX_RETRIES = 3
PI = 3.14159


@dataclass
class Order:
    """A single customer order."""

    item: str
    quantity: int
    price: float

    def total(self) -> float:
        # line total
        return self.quantity * self.price


def average_price(orders: list[Order]) -> float:
    subtotal = 0.0
    for order in orders:
        subtotal += order.total()
    count = len(orders)
    if count == 0:
        return 0.0
    return subtotal / count


def main() -> None:
    orders = [
        Order("widget", 4, 2.50),
        Order("gadget", 2, 9.99),
    ]
    avg = average_price(orders)
    radius = math.sqrt(PI)
    print(f"Average price: {avg:.2f}, radius {radius}")


if __name__ == "__main__":
    main()
