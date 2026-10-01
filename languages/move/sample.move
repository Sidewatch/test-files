// Move 2.2 (Aptos) / Move 2024 (Sui) — syntax showcase: inventory resources, events, generics and tests.
/* A block comment
   over several lines. */
/// Doc comment for the module.
/// Stores per-account stock counters.
// TODO: add pagination to the listing view
// FIXME: bound the bump amount

#[allow(unused_use)]
module sample::inventory {
    // ── Imports ──
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account;
    friend sample::admin;

    // ── Constants ──
    const E_NOT_INITIALIZED: u64 = 1;
    const E_EMPTY: u64 = 0x2;
    const MAX: u64 = 1_000_000;
    const SMALL: u8 = 255u8;
    const WIDE: u128 = 340282366920938463463374607431768211455;
    const BIG: u256 = 1u256;
    const FLAG: bool = true;
    const OFF: bool = false;
    const ADMIN: address = @0x1;
    const NAMED: address = @sample;
    const NAME: vector<u8> = b"inventory";
    const RAW: vector<u8> = x"48656c6c6f";
    const MSG: vector<u8> = b"line\nbreak \"quoted\" \\ back \x41";

    // ── Structs and abilities ──
    struct Counter has key, store {
        value: u64,
        bumps: u64,
    }

    struct Item has copy, drop, store {
        sku: String,
        qty: u64,
        tags: vector<String>,
    }

    struct Pair<T: copy + drop, phantom U> has copy, drop {
        first: T,
        second: T,
    }

    struct Wrapper<phantom T> has drop {}

    #[event]
    struct Restocked has drop, store {
        sku: String,
        amount: u64,
    }

    enum Status has copy, drop {
        Pending,
        Paid { amount: u64 },
        Shipped(u64, address),
    }

    struct Tuple(u64, bool) has copy, drop;

    // ── Functions ──
    public entry fun init(account: &signer) {
        move_to(account, Counter { value: 0, bumps: 0 });
    }

    public entry fun bump(account: &signer, by: u64) acquires Counter {
        let addr = signer::address_of(account);
        assert!(exists<Counter>(addr), E_NOT_INITIALIZED);
        let c = borrow_global_mut<Counter>(addr);
        c.value = if (c.value + by > MAX) { MAX } else { c.value + by };
        c.bumps = c.bumps + 1;
    }

    #[view]
    public fun value(addr: address): u64 acquires Counter {
        borrow_global<Counter>(addr).value
    }

    public(friend) fun admin_reset(addr: address) acquires Counter {
        let Counter { value: _, bumps: _ } = move_from<Counter>(addr);
    }

    public(package) fun internal_only(): u64 { 7 }

    native fun hash(data: vector<u8>): vector<u8>;

    inline fun twice(x: u64): u64 { x * 2 }

    fun first<T: copy + drop>(v: &vector<T>): Option<T> {
        if (vector::is_empty(v)) option::none() else option::some(*vector::borrow(v, 0))
    }

    fun swap<T>(a: &mut T, b: &mut T) {
        let tmp = a;
        let _ = tmp;
    }

    // ── Expressions and control flow ──
    fun arithmetic(a: u64, b: u64): u64 {
        let sum = a + b;
        let diff = a - b;
        let prod = a * b;
        let quot = a / b;
        let rem = a % b;
        let shl = a << 2;
        let shr = a >> 1;
        let band = a & b;
        let bor = a | b;
        let bxor = a ^ b;
        let cast = (a as u128);
        let narrow = (cast as u8);
        let lt = a < b && a <= b || a > b;
        let ne = a != b;
        let eq = a == b;
        let ge = a >= b;
        let neg = !lt;
        let _ = (sum, diff, prod, quot, rem, shl, shr, band, bor, bxor, narrow, ne, eq, ge, neg);
        a
    }

    fun loops(limit: u64): u64 {
        let i = 0;
        let total = 0;
        while (i < limit) {
            i = i + 1;
            if (i % 2 == 0) continue;
            if (i > 50) break;
            total = total + i;
        };
        loop {
            total = total + 1;
            if (total > 100) break
        };
        'outer: loop {
            loop { break 'outer; }
        };
        total
    }

    fun matching(s: Status): u64 {
        match (s) {
            Status::Pending => 0,
            Status::Paid { amount } if (amount > 100) => amount,
            Status::Paid { amount: _ } => 1,
            Status::Shipped(n, _addr) => n,
        }
    }

    fun vectors() {
        let v = vector[1, 2, 3];
        let w = vector::empty<u64>();
        vector::push_back(&mut w, 10);
        let _ = v[0];
        for (i in 0..3) { let _ = i; };
        v.for_each(|x| { let _ = x; });
        let p = Pair<u64, bool> { first: 1, second: 2 };
        let Pair { first, second } = p;
        let _ = first + second;
    }

    fun aborting(flag: bool) {
        if (!flag) abort E_EMPTY;
        assert!(flag, 42);
        assert!(flag);
    }

    spec aborting {
        aborts_if !flag with E_EMPTY;
        ensures true;
    }

    spec module {
        pragma verify = true;
        invariant forall a: address: exists<Counter>(a) ==> global<Counter>(a).value <= MAX;
    }

    // ── More declarations and expressions ──
    public struct Wrapped<T: store> has store { inner: T }
    struct Phantom<phantom T> has drop {}
    struct Empty has drop {}
    const ADDRS: vector<address> = vector[@0x1, @0x42, @sample];
    const NESTED: vector<vector<u8>> = vector[b"a", b"b"];
    const U16_V: u16 = 65_535u16;
    const U32_V: u32 = 0xFFFF_FFFFu32;
    const U64_V: u64 = 0x1_0000u64;
    const U128_V: u128 = 1u128;

    entry fun entry_only() {}
    public(friend) native fun native_friend(): u64;
    fun mutable_refs(v: &mut vector<u64>, r: &u64, s: &signer): (u64, bool) {
        let mut_ref = &mut *v;
        vector::push_back(mut_ref, *r);
        let (a, b) = (1, true);
        let (x, _) = (a, b);
        (x, b)
    }

    fun macros_and_lambdas(v: vector<u64>): u64 {
        let total = 0;
        v.do_ref!(|x| total = total + *x);
        let doubled = v.map!(|x| x * 2);
        let found = v.any!(|x| *x > 3);
        vector::length(&doubled) + (if (found) 1 else 0) + total
    }

    macro fun apply($f: |u64| -> u64, $x: u64): u64 { $f($x) }

    public fun use_labels(): u64 {
        let i = 0;
        'a: {
            while (i < 10) {
                if (i == 5) return 'a i;
                i = i + 1;
            };
            0
        }
    }

    fun type_ops<T: drop + copy>(x: T): T {
        let _y: vector<T> = vector[];
        let _z = (x: T);
        x
    }

    fun byte_ops(): vector<u8> {
        let b = b"hello\n\x41";
        let h = x"0a0B";
        let _ = h;
        b
    }

    fun mathy(a: u64, b: u64): u64 {
        let v = a + b * 2 - (a / (b | 1)) % 7;
        v = v << 1 >> 1;
        v = v & 0xFF | 0x10 ^ 0b1;
        let ok = !(v == 0) && (v != 1) || v < 2 && v <= 3 && v > 1 && v >= 0;
        if (ok) v else { abort 7 }
    }

    fun unpack_all(i: Item) {
        let Item { sku, qty: q, tags: _ } = i;
        let _ = (sku, q);
    }

    fun use_fun_decl() {
        let v = vector[1u64, 2];
        let _ = v.length();
        let _ = &v[0];
    }

    // ── Specification language ──
    spec mathy {
        pragma opaque;
        pragma aborts_if_is_partial;
        requires a > 0;
        modifies global<Counter>(@sample);
        aborts_if a + b > MAX_U64 with 1;
        ensures result == a + b * 2;
        ensures [abstract] result >= 0;
        let old_v = old(global<Counter>(@sample).value);
        include SomeSchema { x: a };
    }

    spec schema SomeSchema {
        x: u64;
        requires x > 0;
        ensures x > 0;
    }

    spec Counter {
        invariant value <= MAX;
        invariant update value >= old(value);
    }

    spec fun spec_helper(x: u64): u64 { x + 1 }
    spec module { axiom spec_helper(0) == 1; apply schema SomeSchema { x: 1 } to *mathy*; }
    spec struct Item { invariant qty <= MAX; }
    spec native fun spec_native(x: u64): bool;

    // ── Tests ──
    #[test(account = @0x1)]
    fun bump_twice(account: &signer) acquires Counter {
        init(account);
        bump(account, 2); bump(account, 3);
        assert!(value(signer::address_of(account)) == 5, 0);
    }

    #[test]
    #[expected_failure(abort_code = E_EMPTY, location = Self)]
    fun fails() {
        aborting(false);
    }

    #[test_only]
    use std::debug;
}

script {
    use sample::inventory;
    fun main(account: signer) {
        inventory::init(&account);
    }
}

// ── Legacy address block form (Move 1 style) ──
address 0x42 {
module legacy_style {
    use std::vector;
    use 0x1::signer;
    use 0x1::{vector as vec, option::Option};
    struct Old has key { n: u64 }
    public fun make(): Old { Old { n: 0 } }
    public fun peek(a: address): u64 acquires Old { borrow_global<Old>(a).n }
    fun unused(s: &signer) { let _ = signer::address_of(s); }
}
}

// ── Move 2 syntax: enums, receiver functions, index notation, labels, lambdas ──
#[lint::allow_unsafe_randomness]
module sample::modern {
    use std::vector;
    use std::string::{Self, String};
    use std::option::{Self as opt, Option};
    use sample::inventory::{Self, Counter as Ctr};
    use sample::inventory::Item;

    // Sui-style (Move 2024) alternative to the braces above, one per file: `module sample::modern;`
    // Sui-style imports: `use sui::object::{Self, UID};` and `use sui::tx_context::TxContext;`

    public enum Shape has copy, drop, store {
        Circle { radius: u64 },
        Rect { w: u64, h: u64 },
        Point,
        Poly(vector<u64>),
    }

    public struct Holder<T: store + drop> has key, store { inner: T, tags: vector<String> }
    public struct Coord(u64, u64) has copy, drop;

    // receiver-style (method) calls and `use fun`
    use fun area_of as Shape.area;
    public use fun shape_name as Shape.name;

    fun area_of(self: &Shape): u64 {
        match (self) {
            Shape::Circle { radius } => 3 * *radius * *radius,
            Shape::Rect { w, h } => *w * *h,
            Shape::Point => 0,
            Shape::Poly(points) => points.length(),
        }
    }

    fun shape_name(s: &Shape): String {
        match (s) {
            Shape::Circle { .. } => string::utf8(b"circle"),
            Shape::Rect { w: _, h: _ } | Shape::Poly(_) => string::utf8(b"polygon"),
            _ => string::utf8(b"other"),
        }
    }

    fun tests_of_variants(s: Shape): bool {
        s is Shape::Circle || s is Shape::Rect | Shape::Poly
    }

    fun index_notation(v: &mut vector<u64>, h: &mut Holder<u64>) {
        v[0] = v[1] + 1;
        let first = &mut v[0];
        *first = *first + 1;
        h.inner = h.inner + 1;
        let n = h.tags.length();
        let _ = n;
    }

    fun loops_and_lambdas(): u64 {
        let total = 0;
        for (i in 0..10) { total = total + i; };
        let evens = vector[1, 2, 3, 4].filter!(|x| *x % 2 == 0);
        let sum = evens.fold!(0, |acc, x| acc + x);
        let found: Option<u64> = evens.find!(|x| *x > 2);
        let _ = (sum, found);
        'search: loop {
            while (true) { break 'search; };
        };
        let value = 'blk: {
            if (total > 5) return 'blk 1;
            2
        };
        total + value
    }

    fun typed_and_casts(x: u8): u256 {
        let wide = (x as u256);
        let y: u16 = 1u16;
        let z = 100u32 + (y as u32);
        wide + (z as u256)
    }

    #[error]
    const E_BAD: vector<u8> = b"bad input";
    #[test, expected_failure(abort_code = 1)]
    fun fails_with_code() { abort 1 }
    #[test_only]
    fun helper_for_tests(): u64 { 7 }

    // ── Aptos Move 2.2 extras ──
    #[randomness]
    entry fun roll(_s: &signer) {}
    #[deprecated]
    public fun old_api() {}
    #[resource_group(scope = global)]
    struct Group {}
    #[resource_group_member(group = sample::modern::Group)]
    struct Member has key {}
    public inline fun inline_fn(x: u64): u64 { x + 1 }
    public fun with_signer(s: &signer): address { std::signer::address_of(s) }
    public fun closure_param(f: |u64| u64 has copy + drop, x: u64): u64 { f(x) }
}
