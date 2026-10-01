#!/usr/bin/env rdmd
// ── Comments ──
// Line comment. TODO: shard the bins. FIXME: handle overflow.
/* Block comment
   across lines */
/+ Nesting block comment /+ nested +/ still a comment +/
/// Ddoc line comment.
/**
 * Ddoc block comment.
 *
 * Params:
 *     sku = the stock keeping unit
 *
 * Returns: the quantity on hand.
 *
 * Example:
 * ---
 * auto w = new Warehouse("north");
 * ---
 */
/++ Ddoc nesting comment. +/

// ── Module and imports ──
module acme.warehouse;

import std.stdio;
import std.algorithm : filter, map, sum, sort, canFind;
import std.array : array, appender, split;
import std.conv : to, text;
import std.range : iota, zip, take, retro;
import std.string : format, strip, toUpper;
import std.exception : enforce, assertThrown;
import std.traits : isNumeric, ReturnType;
import core.thread : Thread;
import core.atomic;
import core.stdc.stdlib : exit, EXIT_FAILURE;
import std.typecons;
import std.variant;
import std.datetime;
static import std.math;

// ── Version and debug ──
version (unittest) {
    enum testing = true;
} else version (Windows) {
    enum testing = false;
} else {
    enum testing = false;
}
debug (verbose) {
    enum verbose = true;
}
version (D_InlineAsm_X86_64) {}
version = Warehouse;

// ── Literals ──
enum int kDecimal = 1_000_000;
enum int kHex = 0xFF_EC;
enum int kBinary = 0b1010_1010;
enum int kOctal = 0o755;
enum uint kUnsigned = 42u;
enum long kLong = 42L;
enum ulong kBig = 18_446_744_073_709_551_615UL;
enum double kPi = 3.14159;
enum double kExp = 6.02e23;
enum double kNegExp = 1.5E-10;
enum float kFloat = 2.5f;
enum real kReal = 1.0L;
enum double kHexFloat = 0x1.8p1;
enum cdouble kComplex = 1.0 + 2.0i;
enum ifloat kImag = 3.0fi;
enum double kNaN = double.nan;
enum double kInf = double.infinity;
enum char kChar = 'a';
enum char kEscape = '\n';
enum char kHexEsc = '\x41';
enum dchar kUni = 'é';
enum dchar kUni2 = '\U0001F4E6';
enum char kOct = '\101';
enum bool kYes = true;
enum bool kNo = false;
enum typeof(null) kNull = null;

// ── Strings ──
immutable string plain = "Warehouse \"north\"\t\n";
immutable string wysiwyg = r"raw \n string";
immutable string backtick = `raw `;
immutable string hexString = x"48 65 6C 6C 6F";
immutable string delimited = q"(delimited (nested) string)";
immutable string delimited2 = q"[brackets]";
immutable string heredoc = q"EOS
heredoc line one
heredoc line two
EOS";
immutable string tokenString = q{auto x = 1; // token string};
immutable wstring wide = "wide"w;
immutable dstring dchars = "dchars"d;
immutable string entity = "café \&amp; \U0001F4E6";

// ── Enums, aliases ──
enum Category : ubyte { tools, fasteners, safety = 10, bulk }
enum Mode { fast = 1, slow }
alias Sku = string;
alias Prices = double[Sku];
alias Callback = void delegate(int);
alias Fn = int function(int);

// ── Structs, classes, interfaces ──
struct Item {
    string sku;
    int qty;
    double price = 0.0;
    Category cat;

    invariant { assert(qty >= 0, "qty never negative"); }

    this(string sku, int qty) {
        this.sku = sku;
        this.qty = qty;
    }

    ~this() {}

    double total() const pure nothrow @safe @nogc { return qty * price; }

    int opCmp(const Item rhs) const { return qty - rhs.qty; }
    Item opBinary(string op : "+")(Item rhs) { return Item(sku, qty + rhs.qty); }
    ref Item opOpAssign(string op)(int n) if (op == "+" || op == "-") {
        mixin("qty " ~ op ~ "= n;");
        return this;
    }
    int opIndex(size_t i) const { return qty; }
    int opApply(scope int delegate(ref int) dg) { return dg(qty); }
}

union Raw { int i; float f; }

interface Auditable {
    void audit();
    string id() const;
}

abstract class Base : Auditable {
    protected int count;
    private string name_;
    static int created;
    shared static this() { created = 0; }
    this(string name) { name_ = name; ++created; }
    abstract override void audit();
    string id() const { return name_; }
}

final class Bin : Base {
    this(string name) { super(name); }
    override void audit() { writeln("bin ", id); }
    @property int size() const { return count; }
    @property void size(int v) { count = v; }
}

// ── Templates and contracts ──
T clamp(T)(T value, T lo, T hi) pure nothrow @safe
if (isNumeric!T)
{
    return value < lo ? lo : value > hi ? hi : value;
}

template Square(T) {
    T square(T x) { return x * x; }
}

mixin template Counter() {
    int counter;
    void inc() { ++counter; }
}

class Stats { mixin Counter; }

struct Stack(T) {
    private T[] items;
    void push(T t) { items ~= t; }
    T pop() in (items.length > 0, "empty") out (r; r == r) do {
        auto r = items[$ - 1];
        items = items[0 .. $ - 1];
        return r;
    }
}

enum isItem(T) = is(T == Item);
static assert(isItem!Item);

// ── Functions ──
void deposit(ref Item item, int amount) in (amount > 0) do { item.qty += amount; }
int sum(int[] values...) { int s; foreach (v; values) s += v; return s; }
auto lazyEval(lazy int x) { return x + x; }
extern (C) int c_function(int x);
extern (D) nothrow @nogc void quick();
private void hidden() {}
package void pkg() {}
public void exposed() {}
shared int sharedCounter;
__gshared int gshared;
immutable int imm = 5;
const int cst = 6;
static int stat;
@system void unsafeOne() {}
@trusted void trustedOne() {}
@safe void safeOne() {}
pure @nogc nothrow int fast(int x) { return x; }
scope int scp;
inout(int)[] passThrough(inout(int)[] a) { return a; }

// ── Unit tests ──
unittest {
    assert(clamp(42, 0, 10) == 10);
    assertThrown(enforce(false, "fail"));
}

// ── Main ──
void main(string[] args) {
    auto acct = Item("A-100", 12);
    acct.price = 4.5;
    immutable evens = iota(1, 20).filter!(n => n % 2 == 0).map!(n => n * n).sum;
    writefln("%s has %.2f; even squares sum to %d", acct.sku, acct.total, evens);
    writeln(clamp(42, 0, 10));

    int[] arr = [1, 2, 3, 4];
    int[string] assoc = ["a": 1, "b": 2];
    int[3] fixed = [1, 2, 3];
    auto slice = arr[1 .. $];
    arr ~= 5;
    arr ~= [6, 7];
    auto joined = arr ~ [8];
    auto tup = tuple(1, "two", 3.0);
    Variant v = 42;

    int x = 10, y = 3;
    x += 1; x -= 1; x *= 2; x /= 2; x %= 5; x ^^= 2; x <<= 1; x >>= 1; x >>>= 1; x &= 7; x |= 1; x ^= 3;
    auto a = x ^^ y + x / y - x % y;
    auto b = x & y | x ^ y << 1 >> 1 >>> 1;
    auto c = !(x < y) && x >= y || x != y && x == y || x <= y;
    auto d = x is y;
    auto e = x !is y;
    auto f = "a" in assoc;
    auto g = "a" !in assoc;
    auto h = cast(double) x;
    auto i = cast(const) x;
    auto j = typeid(x);
    auto k = typeof(x).stringof;
    auto l = x.sizeof + int.max + int.min + double.epsilon;
    auto m = new Bin("B-1");
    auto n = new int[10];
    auto o = delegate int(int z) { return z; };
    auto p = (int z) => z * 2;
    auto q = function int(int z) { return z; };

    if (x > y) writeln("greater");
    else if (x == y) writeln("equal");
    else writeln("less");

    foreach (idx, val; arr) { if (idx == 1) continue; }
    foreach_reverse (val; arr) {}
    foreach (key, val; assoc) {}
    foreach (i; 0 .. 5) {}
    for (int z = 0; z < 3; z++) {}
    while (x-- > 0) { if (x == 5) break; }
    do { ++x; } while (x < 10);

    switch (x) {
        case 1: goto case 2;
        case 2: .. case 5: writeln("low"); break;
        case 6, 7: break;
        default: break;
    }
    final switch (Mode.fast) {
        case Mode.fast: break;
        case Mode.slow: break;
    }

    outer: foreach (a1; 0 .. 3) {
        foreach (b1; 0 .. 3) {
            if (b1 == 2) continue outer;
            if (a1 == 2) break outer;
        }
    }

    try {
        throw new Exception("bad bin");
    } catch (Exception ex) {
        writeln(ex.msg);
    } catch (Error err) {
        throw err;
    } finally {
        writeln("cleanup");
    }

    scope(exit) writeln("exit");
    scope(success) writeln("success");
    scope(failure) writeln("failure");

    with (acct) { qty = 1; }
    synchronized { sharedCounter++; }
    assert(x >= 0, "x non-negative");
    static if (is(int == int)) {}
    mixin("int dyn = 1;");
    asm { nop; }
    pragma(msg, "compile time");
    string file = __FILE__, func = __FUNCTION__;
    int line = __LINE__;
    auto date = __DATE__;
}

// ── Further constructs ──
import std.meta : AliasSeq, staticMap;
import std.parallelism : parallel, taskPool;
import core.simd;
import core.sync.mutex : Mutex;
import std.concurrency : spawn, send, receive, receiveOnly, thisTid, Tid;

version (LDC) { import ldc.attributes; }
version (GNU) {} else version (DigitalMars) {}
version (assert) {} else version (all) {} else version (none) {}
version (X86_64) enum arch = "x86_64";
debug enum debugging = true;
debug(1) pragma(msg, "debug level 1");
static if (__VERSION__ >= 2100) { enum modern = true; } else { enum modern = false; }
static foreach (i; 0 .. 3) { mixin("enum n", i, " = ", i, ";"); }
static foreach (T; AliasSeq!(int, long, double)) { T zero(T)() { return 0; } }

pragma(inline, true) int inlined(int x) { return x; }
pragma(lib, "m");
pragma(mangle, "c_name") extern(C) int renamed();
pragma(startaddress, inlined);

@nogc @safe pure nothrow:
int attributed_below(int x) { return x; }
@system:

@property int prop() { return 1; }
@disable this();
@("user attribute") struct UDA {}
@UDA struct Tagged {}
enum Marker;
@Marker int marked;
@safe @nogc const(char)[] nameOf(T)() { return T.stringof; }

class Outer {
    int x;
    class Inner { int y() { return x; } }
    static class Nested {}
    private struct Hidden {}
    protected abstract void hook();
    final void sealed() {}
    synchronized void locked() {}
    override string toString() const { return "Outer"; }
    alias x this;
    this(this) {}
    ~this() {}
    static this() {}
    static ~this() {}
    shared static ~this() {}
    unittest { assert(true); }
    typeof(this) clone() { return this; }
    auto opCall(int a) { return a; }
    T opCast(T)() { return T.init; }
    bool opEquals(Object o) { return true; }
    size_t toHash() const @safe pure nothrow { return 0; }
    int opDollar() { return 0; }
    int[] opSlice(size_t a, size_t b) { return null; }
    void opIndexAssign(int v, size_t i) {}
    bool opIn_r(string s) { return false; }
    void opDispatch(string name, A...)(A args) {}
    int opUnary(string op)() if (op == "-") { return 0; }
    int opBinaryRight(string op : "+")(int lhs) { return lhs; }
    int opEquals(const Outer) const { return 0; }
}

struct S {
    union { int i; float f; }
    struct { int a, b; }
    align(16) int aligned;
    align int dflt;
    int[4] fixed;
    enum anon = 5;
    static int counter;
    __gshared int gs;
    ref int refReturn() return { return i; }
    auto autoReturn() { return 1; }
    int scopeParam(scope int* p, return ref int r, out int o, lazy int l, in int i, const int c) { return 0; }
    void variadic(...) {}
    void typesafeVariadic(string[] args...) {}
}

void exotic() {
    int[] dyn = new int[](5);
    int[][] jagged = [[1], [2, 3]];
    int[string][string] nested;
    auto aa = ["a": 1, "b": 2];
    foreach (k, ref v; aa) v++;
    auto keys = aa.keys, values = aa.values;
    aa.remove("a");
    auto slice = dyn[1 .. $ - 1];
    slice[] = 0;
    dyn[] += 1;
    dyn.length = 10;
    dyn ~= [1, 2];
    auto c = dyn.dup, i = dyn.idup;
    auto r = dyn.reverse, srt = dyn.sort;
    assert(dyn.capacity >= dyn.length);
    auto lam = (int a, int b) => a + b;
    auto del = delegate(int a) { return a; };
    int function(int) fp = &inlined;
    int delegate(int) dg = (int a) => a;
    string s = "x" ~ "y";
    s ~= 'z';
    char ch = s[0];
    wchar wc = 'w';
    dchar dc = '\U0001F4E6';
    byte b = -128; ubyte ub = 255; short sh = -1; ushort ush = 1;
    int n = int.max; uint un = uint.max; long lg = long.min; ulong ul = ulong.max;
    float fl = float.nan; double d = double.infinity; real rl = real.epsilon;
    cent ce; ucent uce;
    void* vp = null;
    typeof(null) nul = null;
    bool bl = true;
    auto bits = 1 << 3 | 1 >> 1 & ~0 ^ 5;
    auto cond = n > 0 ? "pos" : n < 0 ? "neg" : "zero";
    auto tpl = tuple!("a", "b")(1, 2);
    auto cat = [1] ~ [2];
    auto power = 2 ^^ 10;
    auto shr = -8 >>> 1;
    auto neg = -n, pos = +n, notb = !bl, inc = n++, dec = --n;
    auto addr = &n;
    auto deref = *addr;
    goto L1;
L1: ;
    with (S()) { a = 1; }
    switch ("x") { case "x": break; default: break; }
    final switch (bl) { case true: break; case false: break; }
    synchronized (typeid(S)) {}
    version (all) { auto vv = 1; }
    scope(exit) {}
    asm { mov EAX, 1; }
    throw new Error("end");
}

template template_call() { enum template_call = 1; }
alias Seq(T...) = T;
alias Fun = void function() pure nothrow @nogc;
alias intAlias = int;
alias Fn2 = int delegate(int);
enum E : string { a = "x", b = "y" }
enum { anonymous1, anonymous2 }
enum immutable(char)[] constant = "constant";
immutable(char)* ip;
shared(int) shr;
const(int)[] ci;
inout int io;
extern(C++, "ns") void cpp_ns();
extern(C++, class) void cpp_class();
extern(Objective-C) void objc();
extern(Windows) void win();
extern(System) void sys();
export void exported() {}
deprecated("old") void dep() {}
deprecated void dep2() {}
nothrow:
void ntBelow() {}
