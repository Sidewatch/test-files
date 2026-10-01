#![allow(dead_code, unused_variables, unused_imports, unused_mut, clippy::all)]
#![warn(missing_docs)]
//! # Inventory showcase
//!
//! Inner doc comment for the crate: a warehouse inventory library.
//!
//! ```
//! let total = 1 + 1;
//! ```

/*! Inner block doc comment for the crate. */

// ── Comments ──
// A line comment. TODO: persist the catalogue. FIXME: overflow on restock.
/* A block comment
   /* with a nested block comment */
   spanning lines. */

/// Outer doc comment for the next item.
/** Block doc comment for the next item. */

// ── Imports ──
use std::collections::{BTreeMap, HashMap, HashSet};
use std::fmt::{self, Debug, Display};
use std::io::{self, Read, Write};
use std::ops::{Add, Deref, Index, Mul};
use std::rc::Rc;
use std::sync::{Arc, Mutex};
use std::cell::RefCell;
use std::marker::PhantomData;

extern crate core;

// ── Constants and statics ──
/// Maximum number of items a single order may contain.
const MAX_ITEMS: u32 = 100;
const GREETING: &str = "Welcome to the warehouse";
const PRIMES: [u32; 4] = [2, 3, 5, 7];
static COUNTER: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);
static mut LEGACY: i32 = 0;

// ── Literals ──
fn literals() {
    let int = 42;
    let negative = -7i32;
    let typed: u64 = 1_000_000u64;
    let hex = 0xFF_u8;
    let octal = 0o755;
    let binary = 0b1010_0101;
    let float = 3.14_f64;
    let exponent = 1.5e-3;
    let big_exponent = 6.022E23_f32;
    let no_fraction = 1.;
    let usize_lit = 10usize;
    let i128_lit: i128 = 170141183460469231731687303715884105727;
    let boolean = true && !false;
    let character = 'x';
    let escaped_char = '\n';
    let quote_char = '\'';
    let unicode_char = '\u{1F4E6}';
    let hex_char = '\x41';
    let byte = b'a';
    let byte_escape = b'\n';
    let string = "A string with \"quotes\", a \\ backslash, \t tab, \x41 hex, \u{1F4E6} unicode.";
    let multi_line = "line one
line two";
    let continued = "continued \
                     on the next line";
    let raw = r"C:\raw\path";
    let raw_hashes = r#"raw with "quotes" inside"#;
    let raw_more = r##"raw with "# inside"##;
    let bytes = b"byte string \x00\xff";
    let raw_bytes = br#"raw bytes "here""#;
    let c_string = c"nul-terminated";
    let unit = ();
    let tuple = (1, "two", 3.0);
    let array = [1, 2, 3];
    let repeated = [0u8; 16];
    let slice = &array[1..];
    let ranges = (1..5, 1..=5, ..5, 5.., ..=5, ..);
}

// ── Attributes and derives ──
#[derive(Debug, Clone, PartialEq, Default)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[repr(C)]
struct Product {
    name: String,
    price: f64,
    #[doc = "Units in stock"]
    quantity: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
struct Money(f64);

#[derive(Debug)]
struct Marker<T> {
    _phantom: PhantomData<T>,
}

struct Unit;

#[derive(Debug)]
#[non_exhaustive]
#[repr(u8)]
enum Status {
    Pending,
    Paid(f64) = 5,
    Cancelled { reason: String, refund: bool } = 6,
    Shipped = 10,
}

#[repr(u8)]
#[derive(Clone, Copy)]
enum Level {
    Low = 1,
    High = 10,
}

union IntOrFloat {
    i: u32,
    f: f32,
}

type Catalog = HashMap<String, Product>;
type Result<T> = std::result::Result<T, StockError>;

// ── Errors ──
#[derive(Debug)]
enum StockError {
    OutOfStock(String),
    Invalid { sku: String, qty: i64 },
    Io(io::Error),
}

impl fmt::Display for StockError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            StockError::OutOfStock(sku) => write!(f, "out of stock: {sku}"),
            StockError::Invalid { sku, qty } => write!(f, "invalid {} x{}", sku, qty),
            StockError::Io(e) => write!(f, "io: {e}"),
        }
    }
}

impl std::error::Error for StockError {}

impl From<io::Error> for StockError {
    fn from(e: io::Error) -> Self {
        StockError::Io(e)
    }
}

// ── Traits and generics ──
trait Describe {
    const KIND: &'static str;
    type Output: Display;

    fn describe(&self) -> Self::Output;

    fn shout(&self) -> String {
        self.describe().to_string().to_uppercase()
    }
}

trait Shape: Debug + Send {
    fn area(&self) -> f64;
}

impl Describe for Product {
    const KIND: &'static str = "product";
    type Output = String;

    fn describe(&self) -> String {
        format!("{} @ {:.2}", self.name, self.price)
    }
}

impl Product {
    pub const DEFAULT_PRICE: f64 = 0.0;

    pub fn new(name: &str, price: f64) -> Self {
        Product {
            name: name.to_string(),
            price,
            quantity: 0,
        }
    }

    pub(crate) fn total_value(&self) -> f64 {
        self.price * self.quantity as f64
    }

    pub const fn is_empty(&self) -> bool {
        self.quantity == 0
    }

    unsafe fn raw_access(ptr: *const u32) -> u32 {
        *ptr
    }
}

impl Add for Money {
    type Output = Money;
    fn add(self, rhs: Money) -> Money {
        Money(self.0 + rhs.0)
    }
}

impl<T: Display> fmt::Display for Marker<T> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "marker")
    }
}

fn largest<T>(items: &[T]) -> Option<&T>
where
    T: PartialOrd,
{
    let mut best = items.first()?;
    for item in items {
        if item > best {
            best = item;
        }
    }
    Some(best)
}

fn boxed(items: Vec<Box<dyn Shape>>) -> impl Iterator<Item = f64> {
    items.into_iter().map(|s| s.area())
}

fn lifetimes<'a, 'b: 'a>(x: &'a str, y: &'b str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

fn higher_ranked<F>(f: F) where F: for<'a> Fn(&'a str) -> &'a str {
    let _ = f("x");
}

struct Wrapper<'a, T: 'a + ?Sized> {
    inner: &'a T,
}

impl<const N: usize> Marker<[u8; N]> {
    fn size(&self) -> usize { N }
}

// ── Macros ──
macro_rules! square {
    ($x:expr) => {
        $x * $x
    };
    ($x:expr, $($rest:expr),+) => {
        $x * $x + square!($($rest),+)
    };
}

macro_rules! make_struct {
    ($name:ident { $($field:ident : $ty:ty),* $(,)? }) => {
        struct $name { $($field: $ty),* }
    };
}

make_struct!(Bin { label: String, capacity: u32 });

// ── Functions, closures and control flow ──
fn restock(product: &mut Product, amount: u32) {
    product.quantity += amount;
}

fn classify(n: i32) -> &'static str {
    match n {
        i32::MIN..=-1 => "negative",
        0 => "zero",
        1 | 2 | 3 => "small",
        x if x % 2 == 0 => "even",
        4..=99 => "medium",
        _ => "large",
    }
}

fn patterns(status: Status, pair: (i32, i32), opt: Option<Product>) {
    match status {
        Status::Pending => println!("pending"),
        Status::Paid(amount) if amount > 100.0 => println!("big payment"),
        Status::Paid(amount) => println!("paid {amount}"),
        Status::Cancelled { reason, .. } => println!("cancelled: {reason}"),
        Status::Shipped => {}
    }

    let (a, b) = pair;
    let Product { name, price, .. } = Product::new("x", 1.0);
    if let Some(p) = opt {
        println!("{}", p.name);
    } else if let None = opt {
        println!("none");
    }
    let Some(first) = Some(1) else { return };
    while let Some(top) = Some(1) {
        break;
    }
    let msg @ ("hi" | "hello") = "hi" else { return };
    if let Status::Paid(_) | Status::Cancelled { .. } = Status::Paid(1.0) {}
    matches!(pair, (1, _) | (_, 1));
}

fn control() -> Result<()> {
    let mut count = 0;
    'outer: loop {
        count += 1;
        for i in 0..10 {
            if i == 3 { continue 'outer; }
            if count > 5 { break 'outer; }
        }
    }
    let label_value = 'blk: {
        if count > 2 { break 'blk 1; }
        2
    };
    while count > 0 { count -= 1; }
    let x = if count == 0 { "zero" } else { "nonzero" };
    let val = loop { break 42; };
    let doubled: Vec<i32> = (1..=5).map(|n| n * 2).filter(|n| n % 4 == 0).collect();
    let add = |a: i32, b: i32| -> i32 { a + b };
    let move_closure = move || count + 1;
    let returns = (|| { return 5; })();
    let tupled = (1, 2).0 + (3, 4).1;
    let casted = 3.7_f64 as i32 as u8 as char;
    let r#type = "raw identifier";
    let shift = 1u32 << 4 >> 2 & 0xF | 0x1 ^ 0x2;
    let logic = !true || (false && true);
    let cmp = 1 < 2 && 2 <= 3 && 3 != 4 && 4 >= 3 && 3 > 2;
    let mut v = vec![1, 2, 3];
    v[0] += 1; v[1] -= 1; v[2] *= 2; v[0] /= 1; v[1] %= 5; v[2] <<= 1; v[0] >>= 1; v[1] &= 3; v[2] |= 4; v[0] ^= 1;
    let reference = &v;
    let mutable = &mut v;
    let deref = *mutable.first().unwrap();
    let question = Some(5).ok_or(StockError::OutOfStock("x".into()))?;
    let _ = async_block();
    unsafe { LEGACY += 1; }
    Ok(())
}

// ── Async ──
async fn fetch(sku: &str) -> Result<u32> {
    let value = lookup(sku).await?;
    Ok(value)
}

async fn lookup(_sku: &str) -> Result<u32> { Ok(1) }

fn async_block() -> impl std::future::Future<Output = u32> {
    async move { 5 }
}

// ── Modules ──
mod warehouse {
    pub mod bins {
        pub struct Bin { pub label: String }
        pub(super) fn secret() {}
    }
    pub use self::bins::Bin;
    use super::Product;
    #[cfg(test)]
    mod tests {
        use super::*;
        #[test]
        fn creates_bin() {
            assert_eq!(1 + 1, 2);
            assert!(true, "message {}", 1);
        }
        #[test]
        #[should_panic(expected = "boom")]
        fn panics() { panic!("boom"); }
    }
}

// ── Rare constructs ──
mod rare {
    use std::fmt::Debug as DebugTrait;
    use std::collections::hash_map::{self as hm, Entry};
    use std::io::Write as _;
    pub(in crate::rare) struct Scoped;
    pub(self) fn private_fn() {}
    pub(super) struct SuperVisible;

    extern "C" {
        fn abs(input: i32) -> i32;
        static environ: *const *const u8;
    }

    #[no_mangle]
    pub extern "C" fn exported(x: i32) -> i32 { x + 1 }

    pub extern "system" fn callback() {}

    unsafe trait Zeroable {}
    unsafe impl Zeroable for u32 {}

    trait Blanket { fn name(&self) -> String; }
    impl<T: DebugTrait + ?Sized> Blanket for T {
        fn name(&self) -> String { format!("{:?}", self) }
    }

    trait Container {
        type Item<'a> where Self: 'a;
        fn first<'a>(&'a self) -> Option<Self::Item<'a>>;
    }

    struct Buffer<const N: usize = 8> { data: [u8; N] }

    fn const_generic<const N: usize>(_: [u8; N]) -> usize { const { N * 2 } }

    fn dyn_objects(a: &dyn DebugTrait, b: Box<dyn Fn(i32) -> i32 + Send + 'static>, c: &mut dyn FnMut(), d: fn(u8) -> u8) {}

    fn anonymous_lifetime(s: &'_ str) -> impl Iterator<Item = &'_ str> + '_ { s.split(',') }

    fn raw_pointers() {
        let x = 5;
        let p = &x as *const i32;
        let m = &x as *const i32 as *mut i32;
        let raw = &raw const x;
        let mut y = 1; let raw_mut = &raw mut y;
        unsafe {
            let _ = *p;
            std::ptr::read(p);
        }
    }

    fn binding_modes() {
        let pair = (String::from("a"), 5);
        let (ref name, mut count) = pair;
        let (ref mut name2, _) = (String::new(), 1);
        let slice = [1, 2, 3, 4, 5];
        if let [first, .., last] = slice {}
        if let [head, rest @ ..] = &slice[..] {}
        if let [.., x, _] = slice {}
        match 5u8 {
            n @ 1..=9 => {}
            n @ (10 | 20) => {}
            _ => {}
        }
        let &(a, b) = &(1, 2);
        let box_like = Box::new(5);
        let Some(Some(z)) = Some(Some(1)) else { panic!() };
    }

    fn closures() {
        let a = |x: u8| x;
        let b = |x: i32| -> i32 { x };
        let c = move |x: &str| x.len();
        let d = async move |x: i32| x;
        let e = || async { 5 };
        let f: Box<dyn Fn() -> u8> = Box::new(|| 0);
        let g = const { 1 + 2 };
    }

    fn numbers() {
        let _ = (1e10f64, 0xFFu8, 1_f32, 0b1111_0000u8, 0o77i16, 1u128, 2.5e+3, 0.1e-2);
        let _ = (b'\\', b'\'', b'\x7f', '\0', '\\', '\t', '\r', "\0", b"\n\t\\\"");
        let _ = (f64::NAN, f64::INFINITY, f64::NEG_INFINITY, i32::MAX, u8::MIN, std::f64::consts::PI);
        let _ = (1..=10).rev().step_by(2);
        let _ = 5 as f32 / 2.0;
        let _ = -(-5i32).abs();
        let _ = !0u8;
        let _ = 7 % 3 == 1;
        let t = ((1, 2), 3);
        let _ = t.0.1;
    }

    macro_rules! counted {
        () => { 0usize };
        ($head:tt $($tail:tt)*) => { 1usize + counted!($($tail)*) };
    }

    macro_rules! with_kinds {
        ($i:ident, $e:expr, $t:ty, $p:pat, $s:stmt, $b:block, $l:literal, $lt:lifetime, $m:meta, $path:path, $vis:vis, $item:item) => {};
    }

    #[macro_export]
    macro_rules! exported_macro {
        ($($arg:tt)*) => { $crate::rare::exported($($arg)*) };
    }

    fn std_macros() {
        let _ = format!("{0} {1} {0} {name:>width$} {:.*}", 2, 3.14159, name = "n", width = 6);
        let _ = concat!("a", 1, true);
        let _ = stringify!(a + b);
        let _ = line!() + column!();
        let _ = file!();
        let _ = module_path!();
        let _ = option_env!("HOME");
        let _ = include_str!("sample.rs");
        let _ = include_bytes!("sample.rs");
        let _ = vec![0u8; 4];
        let _ = matches!(Some(1), Some(n) if n > 0);
        assert_ne!(1, 2);
        debug_assert_eq!(1, 1);
        debug_assert!(true);
        write!(std::io::sink(), "x").ok();
        writeln!(std::io::sink()).ok();
        print!("");
        eprint!("");
        let _ = thread_local_demo();
    }

    thread_local! {
        static LOCAL: std::cell::Cell<u32> = const { std::cell::Cell::new(0) };
    }

    fn thread_local_demo() -> u32 { LOCAL.with(|c| c.get()) }

    #[cfg(any(target_os = "macos", all(unix, not(target_os = "linux"))))]
    fn platform() {}

    #[inline(always)]
    #[must_use = "use the value"]
    #[deprecated(since = "1.0", note = "use something else")]
    #[allow(clippy::needless_return)]
    #[track_caller]
    fn annotated() -> u8 { return 1; }

    #[cfg(target_pointer_width = "64")]
    const WIDE: bool = true;
    #[cfg(not(target_pointer_width = "64"))]
    const WIDE: bool = false;

    type FnPtr = unsafe extern "C" fn(*const u8, usize) -> isize;
    type Never = fn() -> !;
    type Tuple3 = (u8, i16, f32);
    type Slice<'a> = &'a [u8];
    type Reference<'a> = &'a mut Vec<Option<Box<dyn Fn()>>>;

    fn diverges() -> ! { loop {} }

    struct Guard;
    impl Drop for Guard { fn drop(&mut self) {} }
    struct Wrapper2<T>(T);
    impl<T> std::ops::Deref for Wrapper2<T> { type Target = T; fn deref(&self) -> &T { &self.0 } }
    impl<T> std::ops::Index<usize> for Wrapper2<Vec<T>> { type Output = T; fn index(&self, i: usize) -> &T { &self.0[i] } }
    impl<T> IntoIterator for Wrapper2<Vec<T>> { type Item = T; type IntoIter = std::vec::IntoIter<T>; fn into_iter(self) -> Self::IntoIter { self.0.into_iter() } }
    impl PartialEq<u8> for Wrapper2<u8> { fn eq(&self, o: &u8) -> bool { self.0 == *o } }
    impl<T> Default for Wrapper2<T> where T: Default { fn default() -> Self { Wrapper2(T::default()) } }
    impl<T: Clone> Clone for Wrapper2<T> { fn clone(&self) -> Self { Self(self.0.clone()) } }
    impl<T> From<T> for Wrapper2<T> { fn from(t: T) -> Self { Self(t) } }
}

// ── Main ──
fn main() {
    let mut catalog: HashMap<String, Product> = HashMap::new();
    let widget = Product::new("Widget", 9.99);
    catalog.insert(widget.name.clone(), widget);

    if let Some(item) = catalog.get_mut("Widget") {
        restock(item, 25);
        println!("Total value: {:.2}", item.total_value());
    }

    println!("Order limit is {}", MAX_ITEMS);
    println!("{:>8} | {:<8} | {:^8} | {:08.3} | {:#x} | {:#b} | {:?} | {:#?}", "r", "l", "c", 3.14159, 255, 5, (1, 2), "dbg");
    eprintln!("to stderr");
    let shared = Arc::new(Mutex::new(0));
    let cell = Rc::new(RefCell::new(vec![1]));
    let handle = std::thread::spawn({
        let shared = Arc::clone(&shared);
        move || { *shared.lock().unwrap() += 1; }
    });
    handle.join().unwrap();
    let _ = (literals as fn(), control(), square!(2, 3), cfg!(debug_assertions));
    dbg!(&catalog.len());
    todo!();
    unimplemented!();
    unreachable!("never");
}
