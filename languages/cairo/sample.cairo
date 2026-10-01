// Starknet warehouse inventory contract in Cairo 2.
// Line comments use double slashes.
// TODO: add pausable access control.
// FIXME: `restock` should emit a batch event.

/// Doc comment for the interface.
/// Describes warehouse stock operations.

// ── Imports ─────────────────────────────────────────────────────────
use starknet::ContractAddress;
use starknet::{get_caller_address, get_block_timestamp, get_contract_address};
use core::array::ArrayTrait;
use core::traits::{Into, TryInto};
use core::option::OptionTrait;
use core::integer::u256;
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};

// ── Constants and type aliases ──────────────────────────────────────
const MAX_ITEMS: u32 = 1_000;
const REORDER_POINT: u64 = 25;
const ADMIN_FELT: felt252 = 0x1234abcd;
const SHORT_STRING: felt252 = 'warehouse';
const LONG_STRING: ByteArray = "A longer byte-array string with \"escapes\" and \n newline";
type Quantity = u64;

// ── Enums with payloads ─────────────────────────────────────────────
#[derive(Drop, Serde, Copy, PartialEq, starknet::Store)]
enum Category {
    #[default]
    Tools,
    Parts,
    Fasteners,
}

#[derive(Drop, Serde, Clone)]
enum Command {
    Restock: (felt252, u64),
    Remove: felt252,
    Audit,
    Move: Transfer,
}

// ── Structs ─────────────────────────────────────────────────────────
#[derive(Drop, Serde, Copy, starknet::Store, Default)]
struct Item {
    sku: felt252,
    qty: u64,
    price: u128,
    category: Category,
}

#[derive(Drop, Serde, Copy)]
struct Transfer {
    from: ContractAddress,
    to: ContractAddress,
    sku: felt252,
    amount: u64,
}

// ── Traits and generics ─────────────────────────────────────────────
trait Summary<T> {
    fn summarize(self: @T) -> felt252;
}

impl ItemSummary of Summary<Item> {
    fn summarize(self: @Item) -> felt252 {
        *self.sku
    }
}

trait Shape<T, +Drop<T>> {
    fn area(self: @T) -> u64;
}

fn largest<T, +PartialOrd<T>, +Copy<T>, +Drop<T>>(a: T, b: T) -> T {
    if a > b { a } else { b }
}

// ── Interface ───────────────────────────────────────────────────────
#[starknet::interface]
trait IWarehouse<TContractState> {
    fn restock(ref self: TContractState, sku: felt252, amount: u64);
    fn remove(ref self: TContractState, sku: felt252) -> bool;
    fn stock_of(self: @TContractState, sku: felt252) -> u64;
    fn owner(self: @TContractState) -> ContractAddress;
}

// ── Contract ────────────────────────────────────────────────────────
#[starknet::contract]
mod Warehouse {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use super::{Item, Category, REORDER_POINT};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        stock: Map<felt252, u64>,
        items: Map<felt252, Item>,
        total: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Restocked: Restocked,
        LowStock: LowStock,
    }

    #[derive(Drop, starknet::Event)]
    struct Restocked {
        #[key]
        sku: felt252,
        amount: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct LowStock {
        #[key]
        sku: felt252,
        remaining: u64,
    }

    mod Errors {
        const NOT_OWNER: felt252 = 'Caller is not the owner';
        const EMPTY: felt252 = 'Out of stock';
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self.total.write(0);
    }

    #[abi(embed_v0)]
    impl WarehouseImpl of super::IWarehouse<ContractState> {
        fn restock(ref self: ContractState, sku: felt252, amount: u64) {
            assert(get_caller_address() == self.owner.read(), Errors::NOT_OWNER);
            assert!(amount > 0, "amount must be positive: {}", amount);
            let current = self.stock.entry(sku).read();
            self.stock.entry(sku).write(current + amount);
            self.total.write(self.total.read() + amount);
            self.emit(Restocked { sku, amount });
        }

        fn remove(ref self: ContractState, sku: felt252) -> bool {
            let current = self.stock.entry(sku).read();
            if current == 0 {
                return false;
            }
            self.stock.entry(sku).write(current - 1);
            if current - 1 < REORDER_POINT {
                self.emit(LowStock { sku, remaining: current - 1 });
            }
            true
        }

        fn stock_of(self: @ContractState, sku: felt252) -> u64 {
            self.stock.entry(sku).read()
        }

        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn only_owner(self: @ContractState) {
            assert(get_caller_address() == self.owner.read(), Errors::NOT_OWNER);
        }
    }
}

// ── Functions, control flow, expressions ────────────────────────────
fn fib(n: u32) -> u32 {
    if n <= 1 {
        n
    } else {
        fib(n - 1) + fib(n - 2)
    }
}

fn classify(qty: u64) -> felt252 {
    match qty {
        0 => 'empty',
        1 | 2 | 3 => 'scarce',
        4..=24 => 'low',
        _ => 'ok',
    }
}

#[inline(always)]
fn add_one(x: u32) -> u32 {
    x + 1
}

#[test]
#[should_panic(expected: ('empty',))]
fn test_classify() {
    assert(classify(0) == 'empty', 'wrong');
    panic!("forced failure");
}

fn main() -> u32 {
    // Variables and numbers
    let a: u8 = 255;
    let b: u16 = 0xFFFF;
    let c: u32 = 0b1010_1010;
    let d: u64 = 0o777;
    let e: u128 = 340_282_366_920_938_463_463_374_607_431_768_211_455;
    let f: u256 = 1_u256;
    let g = 42_u32;
    let h: felt252 = -1;
    let mut counter = 0;
    let tuple = (1, 'two', 3_u8);
    let (x, y, z) = tuple;
    let fixed: [u32; 3] = [1, 2, 3];
    let nothing = ();
    let flag: bool = true && !false || (1 == 1);

    // Arrays and spans
    let mut arr = ArrayTrait::new();
    arr.append(1);
    arr.append(2);
    let span = arr.span();
    let first = *span.at(0);
    let maybe = arr.get(5);
    let arr2: Array<u32> = array![1, 2, 3];

    // Operators
    counter += 1;
    counter -= 1;
    counter *= 2;
    counter /= 2;
    counter %= 3;
    let bits = (a & 0x0F) | (a ^ 0xF0);
    let shifted = b / 2_u16 * 3;
    let cmp = a >= 1 && b <= 10 || c != d;

    // Control flow
    let label = if counter > 0 { 'pos' } else { 'zero' };
    let mut i = 0;
    while i < 3 {
        i += 1;
    }
    loop {
        if i == 0 {
            break;
        }
        i -= 1;
    }
    for item in arr2.span() {
        let _ = *item;
    }
    let value = loop {
        break 7;
    };

    // Option, Result, pattern matching
    let opt: Option<u32> = Option::Some(5);
    match opt {
        Option::Some(v) => { let _ = v; },
        Option::None => {},
    }
    if let Option::Some(v) = opt {
        let _ = v;
    }
    let res: Result<u32, felt252> = Result::Ok(1);
    let unwrapped = res.unwrap();
    let cast: u64 = a.into();
    let back: u8 = cast.try_into().unwrap();
    let closure = |n: u32| -> u32 { n + 1 };
    let _ = closure(1);

    // Macros
    println!("value: {}", unwrapped);
    let msg = format!("{}-{}", 1, 2);
    assert_eq!(1, 1);
    assert_ne!(1, 2);

    add_one(fib(10)) + g
}

// ── Further constructs ──────────────────────────────────────────────
//! Inner doc comment for the enclosing module.
/// Outer doc comment for the function below.
/// Another line of documentation.

use core::num::traits::{Zero, One, Pow};
use core::dict::{Felt252Dict, Felt252DictTrait, Felt252DictEntryTrait};
use core::nullable::{Nullable, NullableTrait, match_nullable, FromNullableResult};
use core::box::{Box, BoxTrait};
use core::ec::{EcPoint, EcStateTrait};
use core::pedersen::PedersenTrait;
use core::keccak::keccak_u256s_le_inputs;
use core::sha256::compute_sha256_u32_array;
use core::circuit::*;
use core::panics::{Panic, PanicResult};
use core::result::ResultTrait as _;
use super::Shape as SuperShape;
pub use crate::utils::helper;
pub(crate) use self::inner::*;

pub mod inner {
    pub(crate) fn hidden() -> u8 { 1 }
    pub(self) fn private_ish() {}
}

pub const FLAGS: u8 = 0b1010_1010;
pub const MASKS: [u16; 3] = [0xFF, 0o77, 255];
const NEG: i128 = -170_141_183_460_469_231_731_687_303_715_884_105_728;
const SHORT_A: felt252 = 'a';
const EMPTY_SHORT: felt252 = '';
const ESCAPED: ByteArray = "line1\nline2\ttab\\ \"quote\" \x41";

pub type Pair<T> = (T, T);
type Callback = fn(u32) -> u32;

#[derive(Drop, Copy, Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash, Serde, Default, starknet::Store)]
pub struct Point<T> {
    pub x: T,
    pub y: T,
}

pub enum Shape {
    Circle: u32,
    Rect: (u32, u32),
    Unit,
}

pub struct Wrapper<T, +Drop<T>> { value: T }
pub struct Unit;
pub struct Tuple(u8, u16);

impl PointAdd<T, +Add<T>, +Copy<T>, +Drop<T>> of Add<Point<T>> {
    fn add(lhs: Point<T>, rhs: Point<T>) -> Point<T> {
        Point { x: lhs.x + rhs.x, y: lhs.y + rhs.y }
    }
}

impl PointSerde of Serde<Point<u8>> {
    fn serialize(self: @Point<u8>, ref output: Array<felt252>) {
        output.append((*self.x).into());
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<Point<u8>> {
        Option::None
    }
}

pub trait Drawable<T> {
    const SIDES: u8;
    type Output;
    fn draw(self: @T) -> Self::Output;
    fn default_draw() -> u8 { 0 }
}

#[generate_trait]
impl ShapeImpl of ShapeTrait {
    fn area(self: @Shape) -> u32 {
        match self {
            Shape::Circle(r) => 3 * *r * *r,
            Shape::Rect((w, h)) => *w * *h,
            Shape::Unit => 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[available_gas(2000000)]
    fn it_works() {
        let p = Point { x: 1_u8, y: 2_u8 };
        let Point { x, y: py } = p;
        assert!(x == 1, "x was {}", x);
        assert!(py != 0);
        assert_eq!(x + py, 3_u8, "sum mismatch");
        assert_lt!(x, py);
        assert_le!(x, py);
        assert_gt!(py, x);
        assert_ge!(py, x);
    }

    #[test]
    #[ignore]
    fn skipped() {}

    #[test]
    #[should_panic]
    fn panics() { panic!("expected"); }
}

#[inline(never)]
#[must_use]
#[feature("negative-impls")]
#[allow(unused_variables)]
#[derive(Drop)]
fn attributes_demo<const N: usize>(arr: [u8; N]) -> u8 {
    let [a, b, ..] = arr;
    let _unused = 0;
    a + b
}

fn expressions() -> felt252 {
    let t: (u8, u16, felt252) = (1, 2, 3);
    let (a, _, c) = t;
    let nested = ((1, 2), [3, 4]);
    let sum: u32 = 0x1f_u32 + 0b11_u32 + 0o7_u32;
    let neg = -5_i32;
    let cast = 300_u16.try_into().unwrap_or(0_u8);
    let ranged = 0..10;
    let inclusive = 0..=10;
    let b: Box<u8> = BoxTrait::new(5);
    let unboxed = b.unbox();
    let mut dict: Felt252Dict<u64> = Default::default();
    dict.insert('k', 1);
    let v = dict.get('k');
    let n: Nullable<u8> = NullableTrait::new(1);
    let closure = |x| x + 1;
    let typed_closure = |x: u8, y: u8| -> u8 { x * y };
    let r#raw_ident = 1;
    let label = 'a long-ish short string';
    let result = match v {
        0 => 'zero',
        1 | 2 => 'small',
        x if x > 100 => 'big',
        _ => 'other',
    };
    let ok: Result<u8, felt252> = Ok(1);
    let q = ok?;
    let opt: Option<u8> = Some(1);
    let Some(inner) = opt else { return 0; };
    let mut i = 0_u8;
    while let Some(x) = opt {
        i += x;
        break;
    }
    let tup_index = t.0 + t.1.into();
    let arr_idx = array![1, 2, 3][1];
    let sp = array![1_u8].span();
    let bool_ops = true && false || !true ^ false;
    let bit_ops = (1_u8 & 2) | (3 ^ 4);
    let neg_lit = - (1_i8);
    let path = core::cmp::max(1_u8, 2_u8);
    let turbofish = Default::<u8>::default();
    let generic_call = largest::<u8>(1, 2);
    let _ = i + a.into() + c;
    let parens = (((1)));
    result
}

extern fn pedersen(a: felt252, b: felt252) -> felt252 implicits(Pedersen) nopanic;
extern type Array<T>;
extern fn array_new<T>() -> Array<T> nopanic;
fn nopanic_fn() -> u8 nopanic { 1 }
fn with_implicits() implicits(RangeCheck, GasBuiltin) {}
fn panicking() -> u8 { panic_with_felt252('oops') }
// TODO: replace the dictionary with a storage map.
