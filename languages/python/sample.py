#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# type: ignore
"""Warehouse inventory showcase for Python syntax highlighting.

Module docstring spanning several lines.
TODO: split into packages.
FIXME: the retry loop never backs off.
"""

from __future__ import annotations

# ── Imports ──
import abc
import asyncio
import contextlib
import dataclasses
import enum
import functools
import itertools
import json
import math
import os.path as osp
import re
import sys
from collections import defaultdict, namedtuple, OrderedDict
from dataclasses import dataclass, field
from typing import (
    Any, Callable, ClassVar, Final, Generic, Literal, Optional, Protocol, TypeVar, Union, overload,
)
from . import sibling
from .. import parent as parent_module
from .pkg.mod import (name1 as alias1, name2)
from os import *  # noqa: F403

# ── Constants and numbers ──
MAX_RETRIES: Final = 3
PI = 3.14159
INT_BIG = 1_000_000
HEX = 0xFF_EA
OCT = 0o755
BIN = 0b1010_0101
FLOAT_EXP = 1.5e-3
FLOAT_BIG = 6.022E23
DOT_ONLY = .5
TRAILING_DOT = 5.
COMPLEX = 3 + 4j
IMAG = 2.5J
INF = float("inf")
NAN = float("nan")
NOTHING = None
YES, NO = True, False
ELLIPSIS = ...
NOT_IMPL = NotImplemented

# ── Strings ──
single = 'single quoted with "double" inside'
double = "double quoted with 'single' inside \n \t \\ \" \' \x41 \u00e9 \U0001F4E6 \N{BULLET} \101 \
continued"
triple_single = '''triple single
spanning lines'''
triple_double = """triple double
spanning lines with "quotes" inside"""
raw = r"C:\new\table \d+ no escapes"
raw_single = r'\n'
byte_str = b"bytes \x00\xff"
raw_bytes = rb'\x00 raw bytes'
bytes_br = Rb"\d"
unicode_prefix = u"unicode"
name, qty, price = "widget", 4, 9.99
fstring = f"{name!r:>10} x{qty} = {qty * price:,.2f} {{literal braces}} {price=}"
fstring_nested = f"{'nested ' + name.upper()} {qty:0{qty}d} {name!s} {name!a}"
fstring_multi = f"""
  total: {qty * price:.2f}
  items: {", ".join(str(i) for i in range(3))}
"""
raw_f = rf"\d{{3}}-{qty}"
implicit = "adjacent " "string " 'concatenation'
percent = "%s has %d items costing %.2f" % (name, qty, price)
formatted = "{} has {:>5} items {name}".format(name, qty, name=name)

# ── Regex ──
SKU_RE = re.compile(r"^(?P<prefix>[A-Z]{2})-(?P<num>\d{4})$", re.IGNORECASE | re.VERBOSE)

# ── Operators ──
a, b = 7, 3
arith = a + b - a * b / a // b % b ** 2
unary = -a + +b + ~a
bits = (a & b) | (a ^ b) << 2 >> 1
compare = a < b <= a == b != a >= b > a
logic = (a and b) or not a
identity = a is b or a is not b
membership = a in [1, 2] or a not in (3, 4)
matmul = a @ b if False else 0
a += 1; a -= 1; a *= 2; a /= 2; a //= 2; a %= 5; a **= 2
a &= 3; a |= 4; a ^= 1; a <<= 1; a >>= 1
if (n := len(name)) > 3:
    walrus = n
ternary = "big" if a > 3 else "small"
chained = 1 < a < 10

# ── Collections ──
lst = [1, 2, 3, *range(4, 6)]
tup = (1, "two", 3.0)
single_tuple = (1,)
empty_tuple = ()
st = {1, 2, 3}
dct = {"sku": "AC-1001", "qty": 25, **{"extra": True}}
slicing = lst[1:3], lst[::2], lst[-1], lst[:-1], lst[::-1]
list_comp = [x * 2 for x in range(10) if x % 2 == 0]
nested_comp = [(x, y) for x in range(3) for y in range(3) if x != y]
set_comp = {x % 3 for x in range(10)}
dict_comp = {k: v for k, v in zip("abc", range(3))}
gen_exp = sum(x * x for x in range(10))
first, *rest = lst
(x1, y1), z1 = (1, 2), 3
swap = (a, b) = (b, a)

# ── Decorators and functions ──
T = TypeVar("T")
K = TypeVar("K", bound="Comparable")


def timed(fn: Callable[..., T]) -> Callable[..., T]:
    """Decorator that logs the call."""
    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        print(f"calling {fn.__name__}")
        return fn(*args, **kwargs)
    return wrapper


def decorator_with_args(retries: int = MAX_RETRIES, *, backoff: float = 1.0):
    def deco(fn):
        return fn
    return deco


@timed
@decorator_with_args(retries=5, backoff=0.5)
def average_price(orders: list[Order], /, default: float = 0.0, *args: int, flag: bool = False, **kwargs: Any) -> float:
    """Return the mean price.

    Args:
        orders: the orders.
        default: returned when empty.

    Returns:
        The mean.

    :param orders: sphinx style
    :returns: float
    """
    subtotal = 0.0
    for order in orders:
        subtotal += order.total()
    count = len(orders)
    if count == 0:
        return default
    return subtotal / count


square = lambda x, y=2: x ** y
lambda_nested = lambda: (lambda z: z)


@overload
def parse(x: int) -> int: ...
@overload
def parse(x: str) -> str: ...
def parse(x):
    return x


# ── Classes ──
class Comparable(Protocol):
    def __lt__(self, other: Any) -> bool: ...


class Status(enum.Enum):
    PENDING = enum.auto()
    PAID = "paid"
    CANCELLED = 3


@dataclass(frozen=True, slots=True)
class Order:
    """A single customer order."""

    item: str
    quantity: int
    price: float
    tags: list[str] = field(default_factory=list)
    registry: ClassVar[dict[str, "Order"]] = {}

    def total(self) -> float:
        # line total
        return self.quantity * self.price

    @property
    def label(self) -> str:
        return f"{self.item} x{self.quantity}"

    @label.setter
    def label(self, value: str) -> None:
        raise AttributeError("read only")

    @staticmethod
    def parse(line: str) -> "Order":
        item, qty, price = line.split(",")
        return Order(item, int(qty), float(price))

    @classmethod
    def empty(cls) -> Order:
        return cls("", 0, 0.0)

    def __repr__(self) -> str:
        return f"Order({self.item!r})"

    def __eq__(self, other: object) -> bool:
        return isinstance(other, Order) and self.item == other.item

    def __add__(self, other): return NotImplemented
    def __getitem__(self, key): return self.tags[key]
    def __enter__(self): return self
    def __exit__(self, *exc): return False


class Repository(abc.ABC, Generic[T]):
    __slots__ = ("_items",)
    _private = 1
    __mangled = 2

    def __init__(self) -> None:
        self._items: dict[str, T] = {}

    @abc.abstractmethod
    def get(self, key: str) -> Optional[T]: ...


class Meta(type):
    def __new__(mcs, name, bases, ns, **kw):
        return super().__new__(mcs, name, bases, ns)


class WithMeta(metaclass=Meta, flag=True):
    pass


Point = namedtuple("Point", ["x", "y"])

# ── Control flow ──
def control(orders: list[Order]) -> None:
    if not orders:
        pass
    elif len(orders) == 1:
        ...
    else:
        for i, order in enumerate(orders):
            if i % 2:
                continue
            if i > 10:
                break
        else:
            print("loop completed")

    n = 0
    while n < 3:
        n += 1
    else:
        print("while done")

    match orders:
        case []:
            print("empty")
        case [Order(item="widget") as first, *others] if others:
            print(first, others)
        case [Order(item=str() as item, quantity=int(q))] | [_, Order(item=item, quantity=q)]:
            print(item, q)
        case {"sku": str(sku), "qty": 0 | 1 as q, **rest}:
            print(sku, q, rest)
        case (1, 2) | [3, 4]:
            pass
        case "text" | 42 | 3.14 | None | True:
            pass
        case Status.PAID:
            pass
        case _:
            print("other")

    try:
        risky = 1 / 0
    except ZeroDivisionError as exc:
        print(exc)
    except (ValueError, TypeError):
        raise
    else:
        print("no error")
    finally:
        print("cleanup")

    try:
        pass
    except* OSError as eg:
        print(eg)

    try:
        raise RuntimeError("boom") from None
    except Exception as e:
        raise ValueError("wrapped") from e

    with open("data.json") as fh, contextlib.suppress(OSError):
        data = json.load(fh)
    with (open("a") as f1, open("b") as f2):
        pass

    assert n > 0, "n must be positive"
    del n
    global MAX_RETRIES
    print(*lst, sep=", ", end="\n", file=sys.stderr)
    return None


# ── Generators, async ──
def countdown(n: int):
    while n > 0:
        received = yield n
        n -= 1
    yield from range(3)
    return "done"


async def fetch(sku: str) -> dict:
    await asyncio.sleep(0.1)
    async with contextlib.AsyncExitStack() as stack:
        pass
    async for chunk in stream():
        print(chunk)
    results = [r async for r in stream()]
    return {"sku": sku, "results": results}


async def stream():
    yield 1


# ── Type hints ──
type Alias[X] = list[X] | None
def generic[X: (int, str)](x: X) -> X: return x
class Box[X]:
    value: X
Vector = list[float]
Json = Union[dict[str, "Json"], list["Json"], str, int, float, bool, None]
mode: Literal["r", "w"] = "r"
callback: Callable[[int, str], bool] | None = None


def main() -> None:
    orders = [
        Order("widget", 4, 2.50),
        Order("gadget", 2, 9.99),
    ]
    avg = average_price(orders)
    radius = math.sqrt(PI)
    print(f"Average price: {avg:.2f}, radius {radius}")
    print(osp.join("a", "b"), __file__, __doc__, __name__)


if __name__ == "__main__":
    main()
