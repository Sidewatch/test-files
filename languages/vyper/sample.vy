# Vyper 0.4.3 — syntax showcase
# pragma version ^0.4.0
# @version ^0.4.0   (deprecated spelling of the version pragma, kept for highlighting)
# pragma evm-version cancun
# pragma nonreentrancy on
# ── Comments ───────────────────────────────────────────────
# Vyper: a warehouse stock ledger with an owner-only reset.
# TODO: add role-based access. FIXME: gas for the batch loop.

"""
@title Warehouse ledger
@author Acme Engineering
@notice Tracks stock counts per SKU hash.
@dev NatSpec docstring with tags.
"""

# ── Imports and interfaces ─────────────────────────────────
from ethereum.ercs import IERC20
from ethereum.ercs import IERC165 as ERC165
import ownable as ownable
from . import helpers
import lib.math as math

initializes: ownable
exports: ownable.owner

interface Oracle:
    def price(sku: bytes32) -> uint256: view
    def update(sku: bytes32, value: uint256): nonpayable
    def deposit(): payable

implements: IERC20

# ── Constants, immutables, storage ─────────────────────────
MAX: constant(uint256) = 1_000_000
REORDER_POINT: constant(uint256) = 25
RATIO: constant(decimal) = 0.75
NEGATIVE: constant(int128) = -42
HEX_VALUE: constant(uint256) = 0xFF
BINARY: constant(uint256) = 0b1010_1010
OCTAL: constant(uint256) = 0o755
SCIENTIFIC: constant(decimal) = 1.5e3
ZERO: constant(address) = empty(address)
NAME: constant(String[32]) = "Warehouse"
SALT: constant(Bytes[4]) = b"\x01\x02\x03\x04"
HASHED: constant(bytes32) = keccak256("Stock(address,uint256)")
FLAG: constant(bool) = True
LIMITS: constant(uint256[3]) = [1, 2, 3]

owner: public(immutable(address))
oracle: public(Oracle)
counts: HashMap[address, uint256]
nested: public(HashMap[bytes32, HashMap[address, uint256]])
names: DynArray[String[16], 10]
matrix: uint256[3][3]
total: public(uint256)
paused: public(bool)
stock: transient(uint256)
locked: public(uint256[MAX])

# ── Events, structs, enums, flags ──────────────────────────
event Bumped:
    who: indexed(address)
    by: uint256
    total: uint256

event Paused:
    flag: bool

event Empty:
    pass

struct Item:
    sku: bytes32
    qty: uint256
    price: decimal
    tags: DynArray[String[8], 4]

enum Status:
    PENDING
    PAID
    CANCELLED

flag Perm:
    READ
    WRITE
    EXEC

# ── Constructor ────────────────────────────────────────────
@deploy
@payable
def __init__(oracle_: address):
    owner = msg.sender
    self.oracle = Oracle(oracle_)
    self.total = 0

# ── Functions: decorators, args, returns ───────────────────
@external
@nonreentrant
def bump(by: uint256 = 1):
    next: uint256 = self.counts[msg.sender] + by
    assert next <= MAX, "too high"
    assert not self.paused, "paused"
    self.counts[msg.sender] = next
    self.total += by
    log Bumped(who=msg.sender, by=by, total=next)

@external
@view
def get(who: address) -> uint256:
    return self.counts[who]

@external
@view
def describe(item: Item) -> (String[32], uint256, decimal):
    return concat("sku:", "WGT"), item.qty, item.price

@internal
@pure
def _clamp(x: uint256, lo: uint256, hi: uint256) -> uint256:
    if x < lo:
        return lo
    elif x > hi:
        return hi
    else:
        return x

@internal
@view
def _is_owner(who: address) -> bool:
    return who == owner

@external
def reset(who: address):
    assert msg.sender == owner, "not owner"
    self.counts[who] = 0

@external
@payable
def __default__():
    raw_log([], b"")

# ── Control flow ───────────────────────────────────────────
@external
def batch(items: DynArray[Item, 16]) -> uint256:
    sum_: uint256 = 0
    for item: Item in items:
        if item.qty == 0:
            continue
        sum_ += item.qty
        if sum_ > MAX:
            break
    for i: uint256 in range(10):
        sum_ += i
    for i: uint256 in range(1, 5, bound=4):
        sum_ += i
    for x: uint256 in [1, 2, 3]:
        sum_ += x
    counter: uint256 = 0
    status: Status = Status.PENDING
    if status == Status.PAID or status in (Status.PENDING | Status.CANCELLED):
        counter += 1
    return sum_

# ── Operators and builtins ─────────────────────────────────
@external
@view
def ops(a: uint256, b: uint256, d: decimal, h: bytes32, s: String[32]) -> uint256:
    r: uint256 = a + b - a * b // 2 % 7 ** 2
    r += 1
    r -= 1
    r *= 2
    r //= 2
    r %= 5
    r <<= 1
    r >>= 1
    r &= 0xF
    r |= 1
    r ^= 2
    bits: uint256 = ~a & b | a ^ b << 2 >> 1
    logic: bool = not (a > b) and (a < b) or (a >= b) or (a <= b) or (a == b) or (a != b)
    cast: uint256 = convert(d, uint256) + convert(True, uint256)
    mn: uint256 = min(a, b) + max(a, b) + abs(-3) if False else unsafe_add(a, b)
    sq: decimal = sqrt(d) + floor(d) + ceil(d)
    ln: uint256 = len(s) + len(b"abc") + as_wei_value(1, "ether") + block.timestamp + block.number
    me: address = self
    bal: uint256 = self.balance + msg.value + tx.gasprice + chain.id
    sig: bytes32 = keccak256(abi_encode(a, b)) ^ sha256(h)
    sel: Bytes[4] = method_id("bump(uint256)")
    ok: bool = isqrt(a) > 0 and uint256_addmod(a, b, 7) == 0 and pow_mod256(a, b) > 0
    a1: address = ecrecover(h, 27, 0x1, 0x2)
    data: Bytes[64] = slice(msg.data, 0, 4)
    hexs: String[10] = uint2str(a)
    z: uint256 = empty(uint256) + max_value(uint256) - min_value(uint8) + convert(max_value(int128), uint256)
    f: uint256 = floor(d * 2.5)
    return r + bits + z

# ── External calls, errors, misc ───────────────────────────
@external
def sync(sku: bytes32):
    price: uint256 = staticcall self.oracle.price(sku)
    extcall self.oracle.update(sku, price)
    success: bool = False
    response: Bytes[32] = b""
    success, response = raw_call(msg.sender, b"", max_outsize=32, value=0, revert_on_failure=False)
    if not success:
        raise "call failed"
    if price == 0:
        raise
    send(msg.sender, 0)
    pass

@external
def stop():
    assert msg.sender == owner  # unreachable message
    self.paused = True
    log Paused(flag=True)
    selfdestruct(owner)  # deprecated: EVM SELFDESTRUCT semantics changed

@external
@view
def tuple_demo() -> (uint256, uint256):
    a: uint256 = 0
    b: uint256 = 0
    a, b = 1, 2
    return a, b

# ── Types, decorators and storage forms not yet shown ──────
uses: ownable
ratio_public: public(constant(decimal)) = 1.5
small: uint8
medium: uint128
signed_small: int8
signed_big: int256
word: bytes32
short_word: bytes4
blob: Bytes[1024]
label: String[100]
flags: bool
addr: address
grid: public(uint256[4][4])
lookup: public(HashMap[address, HashMap[uint256, DynArray[uint256, 8]]])
named_items: public(DynArray[Item, 32])
packed_value: public(immutable(uint256))
last_status: public(Status)
perms: public(Perm)
guard: transient(bool)

@external
@nonpayable
@nonreentrant
def decorators() -> bool:
    return True

@external
@pure
@raw_return
def raw() -> Bytes[32]:
    return b"\x00"

@external
@view
def keyed_guard() -> uint256:
    return 0

# ── Built-in functions and environment variables ───────────
@external
@view
def environment() -> uint256:
    a: address = msg.sender
    b: uint256 = msg.value + msg.gas
    c: address = tx.origin
    d: uint256 = tx.gasprice
    e: address = block.coinbase
    f: uint256 = block.difficulty + block.prevrandao + block.gaslimit + block.basefee + block.number + block.timestamp
    g: bytes32 = block.prevhash
    h: bytes32 = blockhash(block.number - 1)
    i: uint256 = chain.id
    j: uint256 = self.balance
    k: address = self
    l: address = empty(address)
    m: uint256 = max_value(uint256)
    n: int128 = min_value(int128)
    o: decimal = epsilon(decimal)
    p: bytes32 = empty(bytes32)
    q: bytes32 = keccak256(b"data")
    r: bytes32 = sha256(b"data")
    s: bytes[32] = b"\x01\x02"
    t: uint256 = unsafe_sub(1, 1) + unsafe_mul(2, 2) + unsafe_div(4, 2) + unsafe_add(1, 1)
    u: uint256 = uint256_mulmod(2, 3, 5) + uint256_addmod(1, 2, 3) + pow_mod256(2, 8) + isqrt(16)
    v: uint256 = extract32(b"0123456789012345678901234567890123", 0, output_type=uint256)
    w: Bytes[100] = concat(b"a", b"b")
    x: uint256 = len(w) + convert(b"\x01", uint256) + convert(True, uint256) + convert(1, uint256)
    y: String[10] = uint2str(x)
    z: bool = a != empty(address) and (b > 0 or c == a)
    print("debug", a, b)
    return t + u + v + x

@external
def create_things(target: address, blueprint: address):
    new1: address = create_minimal_proxy_to(target)
    new2: address = create_copy_of(target)
    new3: address = create_from_blueprint(blueprint, 1, 2, code_offset=3)
    new4: address = raw_create(b"bytecode")
    raw_revert(b"")

@external
def encode_decode(data: Bytes[64]):
    encoded: Bytes[64] = abi_encode(1, 2, method_id=method_id("f(uint256,uint256)"))
    first: uint256 = 0
    second: uint256 = 0
    first, second = abi_decode(data, (uint256, uint256))
    result: Bytes[128] = abi_encode(first)
    signed: address = ecrecover(keccak256(b"m"), 27, convert(1, uint256), convert(2, uint256))
    point: uint256[2] = ecadd([1, 2], [3, 4])
    scaled: uint256[2] = ecmul([1, 2], 3)
    sent: bool = raw_call(target_addr(), b"", value=1, gas=21000, max_outsize=0, is_delegate_call=False, is_static_call=False, revert_on_failure=True)

@internal
@view
def target_addr() -> address:
    return self

# ── Assertions, loops and conditionals ─────────────────────
@internal
def control(n: uint256) -> uint256:
    assert n > 0
    assert n < 100, "range"
    assert n != 7, UNREACHABLE
    if n == 1:
        pass
    elif n == 2:
        return 2
    else:
        raise "bad"
    total: uint256 = 0
    for i: uint256 in range(n, n + 3):
        total += i
    for i: int128 in range(-3, 3):
        total += convert(i, uint256) if i > 0 else 0
    for k: address in [msg.sender, self]:
        total += 1
    for v: uint256 in self.lookup[msg.sender][0]:
        total += v
    x: Status = Status.PENDING
    y: Perm = Perm.READ | Perm.WRITE
    ok: bool = Perm.READ in y and x != Status.PAID
    return total if ok else 0

@internal
def struct_demo() -> Item:
    item: Item = Item(sku=empty(bytes32), qty=1, price=1.5, tags=["a", "b"])
    item.qty += 1
    copy: Item = item
    arr: uint256[3] = [1, 2, 3]
    arr[0] = arr[1] + arr[2]
    tup: (uint256, bool) = (1, True)
    return copy

# ── Additions: modules, exports and remaining forms ────────
import erc20_lib
import ownable as own2
from ethereum.ercs import IERC721

initializes: erc20_lib[ownable := own2]
exports: (erc20_lib.transfer, erc20_lib.balanceOf, own2.owner)
exports: erc20_lib.__interface__

counter_: public(uint256)

@deploy
def __init__():
    own2.__init__()
    erc20_lib.__init__("Token", "TKN", 18, "Token", "1")

@external
def module_calls(to: address, amount: uint256) -> bool:
    own2._check_owner()
    return erc20_lib._transfer(msg.sender, to, amount)

@internal
@view
def _tiers(x: uint256) -> uint8:
    if x < 10:
        return 0
    elif x < 100:
        return 1
    return 2

@external
@view
def conditional(x: uint256) -> String[8]:
    label_: String[8] = "small" if x < 10 else "large"
    return label_

@external
def struct_events(who: address):
    log Bumped(who=who, by=1, total=2)
    log Bumped(who, 1, 2)
    item: Item = Item(sku=keccak256("a"), qty=0, price=0.0, tags=[])
    self.named_items.append(item)
    self.named_items.pop()
    last: Item = self.named_items[len(self.named_items) - 1]
    self.names = ["a", "b"]
    self.matrix[1][2] = 7
    self.counts[who] = max(self.counts[who], 1)
