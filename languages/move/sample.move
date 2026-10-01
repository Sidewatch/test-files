// Move showcase: inventory resources, events, generics and tests.
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
