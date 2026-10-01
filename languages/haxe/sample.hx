// ── Comments ──
// Haxe: generic containers, abstracts, macros and conditional compilation.
/* Block comment. TODO: split into modules. FIXME: expiry drift. */
/**
 * Documentation comment.
 * @param key The cache key.
 * @return The cached value.
 */
package sample;

// ── Imports ──
import haxe.Timer;
import haxe.ds.StringMap;
import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File in FileIO;
import haxe.io.Bytes as Buffer;
import haxe.Json.*;
using StringTools;
using Lambda;

// ── Conditional compilation ──
#if js
import js.Browser;
#elseif (cpp || hl)
import sys.FileSystem;
#elseif !neko
// nothing
#else
#error "Unsupported target"
#end

#if debug
private final DEBUG = true;
#else
private final DEBUG = false;
#end

// ── Typedefs ──
typedef Entry<T> = { value:T, expires:Float };
typedef Point = { x:Float, y:Float, ?label:String };
typedef Callback = (value:Int, name:String) -> Bool;
typedef Extended = Point & { z:Float };
typedef Fn = Int->String->Void;

// ── Enums ──
enum Status {
    Pending;
    Paid(on:Date);
    Shipped(carrier:String, tracking:String);
    Cancelled(reason:String);
}

enum abstract Level(Int) from Int to Int {
    var Low = 1;
    var High = 10;
    inline function isHigh() return this >= 10;
}

// ── Abstract types ──
abstract Meters(Float) from Float to Float {
    public inline function new(v:Float) this = v;
    @:op(A + B) static function add(a:Meters, b:Meters):Meters;
    @:op(A * B) public inline static function mul(a:Meters, b:Float):Meters return new Meters(a.toFloat() * b);
    @:op(-A) function neg():Meters return new Meters(-this);
    @:op(a.b) function field(name:String):Dynamic return null;
    @:to inline function toString():String return this + "m";
    @:from static function fromInt(i:Int):Meters return new Meters(i);
    public inline function toFloat():Float return this;
    @:arrayAccess function get(i:Int):Float return this + i;
}

// ── Interfaces ──
interface Shape {
    var name(get, never):String;
    function area():Float;
}

// ── Classes ──
@:keep
@:generic
class Cache<K, V:{}> {
    final ttlMs:Float;
    final store = new Map<K, Entry<V>>();
    public var hits(default, null):Int = 0;
    public var misses(get, set):Int;
    public static inline var VERSION = "1.0";
    static var instance:Cache<String, Int>;
    var _misses:Int = 0;

    public function new(ttlMs:Float = 5000) this.ttlMs = ttlMs;

    function get_misses() return _misses;
    function set_misses(v:Int) return _misses = v;

    public function get(key:K, compute:() -> V):V {
        final now = Timer.stamp() * 1000;
        switch store.get(key) {
            case e if (e != null && e.expires > now):
                hits++;
                return e.value;
            case _:
                final value = compute();
                store.set(key, { value: value, expires: now + ttlMs });
                return value;
        }
    }

    @:isVar public var size(get, null):Int;
    function get_size() return Lambda.count(store);

    public inline function clear():Void store.clear();
    overload public function put(key:K, value:V) {}
    macro public function debugLog(self:Expr, message:Expr):Expr {
        return macro trace($message);
    }
}

class Circle implements Shape {
    public var name(get, never):String;
    var radius:Float;
    public function new(r) radius = r;
    function get_name() return "circle";
    public function area() return Math.PI * radius * radius;
    public dynamic function hook() {}
    @:deprecated("use area()")
    public function size() return area();
    extern inline public static function twice(x:Int) return x * 2;
}

class Child extends Circle {
    override public function area():Float return super.area() * 2;
    private function hidden():Void {}
}

// ── Macros ──
class Macros {
    public static macro function assert(cond:Expr):Expr {
        return macro if (!$cond) throw "assertion failed: " + $v{haxe.macro.ExprTools.toString(cond)};
    }

    public static macro function timestamp():Expr {
        return macro $v{Date.now().toString()};
    }

    #if macro
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();
        return fields;
    }
    #end
}

// ── Literals ──
class Literals {
    static function main() {
        var int = 42;
        var neg = -17;
        var hex = 0xFF;
        var float = 3.14;
        var exp = 6.02e23;
        var leading = .5;
        var sci = 1e-3;
        var nan = Math.NaN;
        var inf = Math.POSITIVE_INFINITY;
        var bool = true;
        var other = false;
        var nothing = null;
        var double = "double \"quoted\" \\ \n \t é \x41 \u{1F600} $int ${int + 1}";
        var single = 'single \'quoted\' with $int and ${int * 2} and $$ dollar';
        var regex = ~/^[A-Z]{3}-\d{4}$/i;
        var arr = [1, 2, 3];
        var map = ["a" => 1, "b" => 2];
        var objMap = [for (i in 0...3) i => i * i];
        var anon = { name: "widget", qty: 3, nested: { deep: true } };
        var comprehension = [for (i in 0...10) if (i % 2 == 0) i * i];
        var whileComp = [while (int < 45) int++];
        var range = 0...10;
        var fn = (a:Int, b:Int) -> a + b;
        var fnBlock = function(x:Int):Int { return x * 2; };
        var typed:Array<Int> = [];
        var cast1 = cast(int, Float);
        var cast2:Float = cast int;
        var checkType = (int : Float);
        var untyped_ = untyped int;
        trace(arr, map, objMap, anon, comprehension, whileComp, range, fn, fnBlock, typed, cast1, cast2, checkType, untyped_);
    }
}

// ── Operators ──
class Operators {
    static function run(a:Int, b:Int) {
        var r = a + b - a * b / a % b;
        r += 1; r -= 1; r *= 2; r /= 2; r %= 3;
        var bits = (a & b) | (a ^ b) | ~a | (a << 2) | (a >> 1) | (a >>> 1);
        bits &= 1; bits |= 2; bits ^= 3; bits <<= 1; bits >>= 1; bits >>>= 1;
        var logic = (a > b && b < a) || !(a == b) || (a != b) || (a <= b) || (a >= b);
        var tern = a > b ? "big" : "small";
        var coalesce = null ?? "default";
        var nullAssign:Null<String> = null;
        nullAssign ??= "set";
        var safe = nullAssign?.length;
        var inc = a++ + ++b - a-- - --b;
        var isCheck = Std.isOfType(a, Int);
        var rangeLoop = [for (i in 0...3) i];
        var keyValue = [for (k => v in ["a" => 1]) k + v];
    }
}

// ── Control flow ──
class Flow {
    static function run(x:Dynamic) {
        if (x == null) {
            return "null";
        } else if (Std.isOfType(x, Int)) {
            return "int";
        } else {
            trace("other");
        }

        for (i in 0...10) {
            if (i == 2) continue;
            if (i == 5) break;
        }
        for (item in [1, 2, 3]) trace(item);
        for (key => value in ["a" => 1]) trace(key, value);

        var n = 0;
        while (n < 3) n++;
        do { n--; } while (n > 0);

        switch (x) {
            case 1, 2, 3: trace("small");
            case "a" | "b": trace("letter");
            case Paid(date) if (date != null): trace(date);
            case Shipped(c, _): trace(c);
            case [a, b]: trace(a + b);
            case { name: "widget", qty: q }: trace(q);
            case _.length => 3: trace("length 3");
            case null: trace("null");
            default: trace("default");
        }

        var label = switch (n) { case 0: "zero"; case _: "other"; };

        try {
            throw "boom";
        } catch (e:String) {
            trace(e);
        } catch (e:haxe.Exception) {
            trace(e.message);
        } catch (e) {
            trace(e);
        }

        return label;
    }
}

// ── Main ──
class Main {
    static function main() {
        final cache = new Cache<String, Int>(1000);
        for (i in 0...3) trace('answer: ${cache.get("answer", () -> 42)}');
        trace('hits: ${cache.hits}');   // 2
        var m:Meters = 5;
        trace(m + m);
        Macros.assert(cache.hits == 2);
    }
}

// ── More conditional compilation ──
#if (haxe_ver >= 4.2) && !macro
// new compiler features
#elseif (haxe >= "4.0.0")
// older
#end
#if (js && !nodejs) || (cpp && !cppia)
// browser or cpp
#end
#if !debug
// release only
#end

// ── Metadata of every kind ──
@:structInit
class Config {
    public var name:String;
    @:optional public var retries:Int = 3;
    @:isVar public var level(get, set):Int = 0;
    function get_level() return level;
    function set_level(v) return level = v;
}

@:forward(push, pop, length)
abstract Stack(Array<Int>) from Array<Int> {
    @:from public static function fromInt(i:Int):Stack return [i];
    @:commutative @:op(A + B) static function addInt(a:Stack, b:Int):Stack return a;
    @:resolve function resolve(name:String):Dynamic return null;
}

@:enum abstract Flag(Int) {
    var A = 1;
    var B = 2;
    @:op(A | B) static function or(a:Flag, b:Flag):Flag;
}

@:native("NativeName")
@:require(js)
@:noCompletion
@:pure
@:final
@:nullSafety(Strict)
@:publicFields
@:keepSub
@:expose("Exposed")
@:allow(sample.Main)
@:access(sample.Cache)
@:generic
@:analyzer(no_optimize)
@:coreType
@:runtimeValue
@:fakeEnum(Int)
@:deprecated
@:overload(function(a:Int):Void {})
@:jsRequire("module")
@:build(sample.Macros.build())
@:autoBuild(sample.Macros.build())
@:genericBuild(sample.Macros.build())
@:rtti
@:meta(custom, arg1, "arg2")
class Annotated {
    @:meta public var x:Int;
    @:keep @:isVar var y(get, never):Int;
    @:noDebug @:noUsing @:extern inline function f() {}
    function get_y() return 0;
    @:deprecated("Use something else") static function old() {}
}

@:structInit
@:using(StringTools)
@:forwardStatics
extern class ExternExample {
    static var instance:ExternExample;
    var field:Int;
    function new(a:Int, ?b:String);
    function method(a:Int, ?b:String, c:Bool = false, ...rest:Int):Void;
    static function create():ExternExample;
    @:overload(function(s:String):Void {})
    function call(i:Int):Void;
    @:native("jsName") function renamed():Void;
}

// ── Structures, interfaces, extends and implements ──
typedef Base = { id:Int };
typedef Derived = { > Base, name:String };
typedef Readonly = { final id:Int; final name:String };
typedef WithMethods = { function run():Void; var value(default, null):Int; };
typedef Generic<T:{ id:Int }> = { item:T };
typedef FunctionAlias<T> = (T, T) -> Bool;
typedef Optional = { ?a:Int, ?b:String };

interface Readable extends Closeable {
    function read():Int;
}
interface Closeable { function close():Void; }

class Resource implements Readable implements Closeable {
    public function new() {}
    public function read():Int return 0;
    public function close():Void {}
}

final class Sealed {
    public function new() {}
}

private class Hidden {}
private typedef HiddenT = Int;
private enum HiddenE { A; B; }

// ── Reification macros ──
class MacroForms {
    static macro function reify(e:Expr):Expr {
        var name = "x";
        var items = [macro 1, macro 2];
        return macro {
            var $name = $e;
            var arr = [$a{items}];
            var path = $p{["haxe", "Json"]};
            var ident = $i{name};
            var block = { $b{items} };
            var value = $v{42};
            var inner = ${e};
            trace($name, arr, path, ident, block, value, inner);
            @:pos(e.pos) $e;
        };
    }

    static macro function typed():Expr {
        var t = Context.typeof(macro 1);
        var ct = macro : Int;
        var td = macro class Gen { public var x:Int; };
        return macro null;
    }

    #if macro
    static function helper():Void {
        Context.error("message", Context.currentPos());
        Context.warning("warn", Context.currentPos());
        Context.info("info", Context.currentPos());
        Context.fatalError("fatal", Context.currentPos());
    }
    #end
}

// ── Functions: optional, default, rest, generic, inline, dynamic ──
class FunctionForms {
    static inline var CONST = 42;
    static final LIST = [1, 2, 3];
    public static function optional(a:Int, ?b:String, c:Float = 1.5, d:Array<Int> = null):Void {}
    public static function rest(...args:Int):Int return args.length;
    public static function spread():Int return rest(...[1, 2, 3]);
    public static function generic<T:(Float, Int)>(x:T):T return x;
    public static inline function inlined(x:Int) return x * 2;
    public static dynamic function overridable() {}
    public static function arrow() {
        var f = (x:Int) -> x + 1;
        var g = x -> x * 2;
        var h = () -> {};
        var i = (a, b) -> a + b;
        var j = function(x) return x;
        var k:Int->Int->Int = function(a, b) return a + b;
        var l:(Int, Int) -> Int = (a, b) -> a + b;
        return [f, g, h, i, j, k, l];
    }
    public static function untypedBlock() {
        untyped {
            var x = 1;
            __js__("console.log(x)");
        }
        return untyped __cpp__("1");
    }
    public static function throws() {
        throw "string";
        throw new haxe.Exception("typed");
    }
}

// ── Remaining literal forms ──
class MoreLiterals {
    static function run() {
        var i64:haxe.Int64 = haxe.Int64.make(1, 2);
        var big = 0xFFFFFFFF;
        var sci = 1e10;
        var sciNeg = 1E-10;
        var plain = 1.0;
        var ints = [0, 1, -1, 2147483647];
        var octalLike = 0777;
        var str1 = "tab\t newline\n cr\r quote\" backslash\\ nul\0 hex\x41 uni\u0041 braces\u{1F600} octal\101";
        var str2 = 'interp $ints ${ints.length} $$dollar \' quote';
        var str3 = 'nested ${'inner ${1 + 2}'}';
        var re1 = ~/abc/;
        var re2 = ~/a\/b[c-d]+\d*/gimsu;
        var key = "k";
        var map2 = [key => 1, "b" => 2];
        var intMap = [1 => "a", 2 => "b"];
        var objMap:Map<{}, Int> = new Map();
        var anon = { "quoted-key": 1, unquoted: 2, nested: { deep: [] } };
        var emptyArr:Array<Int> = [];
        var emptyAnon = {};
        var nullable:Null<Int> = null;
        var dyn:Dynamic = 1;
        var any:Any = "x";
        var unit:Void = null;
        var tuple = { a: 1, b: 2 };
        var fnType:Void->Void = null;
        var enumVal = Status.Paid(Date.now());
        var enumNoArgs = Status.Pending;
        var path = haxe.io.Path.join(["a", "b"]);
        var cls = Std.string(Literals);
        var typeNames = [Int, Float, String, Bool, Array, Map];
        var fieldAccess = anon.nested.deep.length;
        var arrayAccess = emptyArr[0];
        var instance = new Cache<String, Int>();
        var cast1 = cast(dyn, Int);
        var cast2:Int = cast dyn;
        var isCheck = Std.isOfType(dyn, Int);
        var typecheck = (dyn : Int);
    }
}
