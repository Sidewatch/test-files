// ActionScript 3.0 (Adobe AIR SDK 51 / ECMAScript 4 draft dialect) — syntax showcase
/**
 * Warehouse inventory model for a Flash-style stock viewer.
 *
 * @author Acme Logistics
 * @version 2.0
 * @see flash.display.Sprite
 */
// TODO: replace the polling timer with a socket push.
// FIXME: restock() does not clamp to capacity.
package com.example.warehouse {

    // ── Imports ──────────────────────────────────────────────────────
    import flash.display.Sprite;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.xml.*;
    import mx.collections.ArrayCollection;

    // ── Metadata ─────────────────────────────────────────────────────
    [Event(name="lowStock", type="flash.events.Event")]
    [Bindable]
    [Embed(source="assets/shelf.png")]

    /**
     * A shelf holding one SKU.
     * @param sku the stock keeping unit
     * @param qty starting quantity
     * @return nothing
     * @throws ArgumentError when qty is negative
     */
    public class Shelf extends EventDispatcher implements IStockHolder {

        // ── Constants and statics ────────────────────────────────────
        public static const LOW_STOCK:String = "lowStock";
        public static const CAPACITY:int = 500;
        public static const RATIO:Number = 1.5e-3;
        public static const MASK:uint = 0xFF00FF;
        public static const NAN_VALUE:Number = NaN;
        public static const BIG:Number = Infinity;
        private static var _instances:uint = 0;

        // ── Instance variables ───────────────────────────────────────
        private var _sku:String;
        private var _qty:int = 0;
        protected var timer:Timer;
        internal var tags:Array = ["fragile", 'heavy', "cold"];
        public var meta:Object = {label: "A-100", weight: 12.5, nested: {deep: true}};
        public var lookup:Dictionary = new Dictionary(true);
        public var bytes:Vector.<int> = new <int>[1, 2, 3];
        public var matrix:Vector.<Vector.<Number>>;
        public var pattern:RegExp = /^[A-Z]-\d{3}$/gi;
        public var feed:XML = <stock sku="A-100"><qty>12</qty><!-- inline --></stock>;
        public var rest:*;

        // ── Constructor ──────────────────────────────────────────────
        public function Shelf(sku:String, qty:int = 0, ... extras) {
            if (qty < 0) {
                throw new ArgumentError("qty must be >= 0, got " + qty);
            }
            _sku = sku;
            _qty = qty;
            _instances++;
            timer = new Timer(1000, 0);
            timer.addEventListener(TimerEvent.TIMER, onTick);
            timer.start();
        }

        // ── Getters and setters ──────────────────────────────────────
        public function get sku():String { return _sku; }
        public function get quantity():int { return _qty; }
        public function set quantity(value:int):void {
            _qty = value;
            if (_qty < 25) dispatchEvent(new Event(LOW_STOCK));
        }

        // ── Methods ──────────────────────────────────────────────────
        override public function toString():String {
            return "Shelf[" + _sku + "] qty=" + _qty + "\tcapacity=" + CAPACITY + "\n";
        }

        public final function restock(amount:int, now:Date = null):Boolean {
            var stamp:Date = now || new Date();
            var escapes:String = "tab\t newline\n quote\" apos\' unicodeé hex\x41 backslash\\";
            quantity = _qty + amount;
            return _qty <= CAPACITY;
        }

        private function onTick(e:TimerEvent):void {
            var elapsed:int = getTimer();
            var i:int, j:uint;
            for (i = 0; i < 10; i++) {
                if (i % 2 == 0) continue;
                if (i > 7) break;
            }
            for each (var tag:String in tags) {
                trace("tag:", tag);
            }
            for (var key:String in meta) {
                trace(key + " = " + meta[key]);
            }
            outer: while (true) {
                do { j++; } while (j < 3);
                break outer;
            }
        }

        // ── Control flow and operators ───────────────────────────────
        public function classify(n:Number):String {
            var label:String = n > 100 ? "high" : (n > 10 ? "mid" : "low");
            switch (label) {
                case "high":
                    return "H";
                case "mid":
                    return "M";
                default:
                    break;
            }
            var bits:int = (n << 2) | (n >> 1) & 0x0F ^ ~n;
            bits >>>= 1; bits <<= 1; bits &= 0xFF; bits |= 1; bits ^= 2;
            var q:Number = n; q += 1; q -= 1; q *= 2; q /= 2; q %= 7;
            var logic:Boolean = !(q > 1) && (q < 5) || q == 3 || q != 4 || q === 3 || q !== 4;
            return label;
        }

        // ── Type tests, casts, E4X, dynamic access ───────────────────
        public function inspect(thing:Object):void {
            if (thing is Shelf) {
                var s:Shelf = thing as Shelf;
                var t:Shelf = Shelf(thing);
                trace(typeof thing, s.sku, t.sku);
            }
            if ("sku" in thing) trace("has sku");
            delete meta.label;
            var xml:XML = <root><item id="1">one</item><item id="2">two</item></root>;
            var firstId:String = xml.item[0].@id;
            var all:XMLList = xml..item;
            var filtered:XMLList = xml.item.(@id == "2");
            var fn:Function = function(a:int, b:int):int { return a + b; };
            var result:* = fn.call(null, 1, 2);
            var inst:Object = new (getDefinitionByName("flash.display.Sprite") as Class)();
            var undef:* = undefined;
            var nothing:Object = null;
            var truth:Boolean = true, falsity:Boolean = false;
            this.dispatchEvent(new Event("inspected"));
            super.toString();
        }

        // ── Error handling ───────────────────────────────────────────
        public function safe(path:String):void {
            try {
                var loader:URLLoader = new URLLoader(new URLRequest(path));
                loader.load(new URLRequest(path));
            } catch (err:SecurityError) {
                trace("blocked", err.message);
            } catch (err:Error) {
                trace("failed", err.getStackTrace());
            } finally {
                trace("done");
            }
        }

        // ── Namespaces ───────────────────────────────────────────────
        public namespace warehouse_internal = "http://example.com/warehouse";
        warehouse_internal function secret():void {}
        use namespace warehouse_internal;
    }
}

// ── Interface and helper types outside the package ───────────────────
internal interface IStockHolder {
    function get quantity():int;
    function restock(amount:int, now:Date = null):Boolean;
}

dynamic class Bag extends Object {
    public native function nativeCall():void;
}

// ── Further constructs: statements, operators, E4X, namespaces ───────
internal final class Extras {
    include "helpers.as";
    import flash.utils.*;
    import flash.net.registerClassAlias;

    public static const VERSION:String = "2.0.0";
    public static var counter:uint = 0;
    private const frozen:Array = [1, 2, 3];
    protected var untyped;
    mx_internal var flexLike:Object;

    [Inline]
    public static function fast(x:Number):Number { return x * x; }

    [Deprecated(replacement="fast")]
    public static function slow(x:Number):Number { return x * x; }

    public function operators():void {
        var s:String = "x";
        var n:Number = 10;
        var t:* = typeof n;
        var i:Boolean = s instanceof String;
        var d:* = void 0;
        n = n++ + ++n - n-- - --n;
        n = -n + +n;
        var bitnot:int = ~n;
        var neg:Boolean = !true;
        var big:Number = 1.7976931348623157e+308;
        var small:Number = 5e-324;
        var octal:int = 0777;
        var hex:uint = 0xDEADBEEF;
        var comma:int = (n = 1, n + 1);
        var arr:Array = new Array(3);
        var arr2:Array = Array(1, 2, 3);
        var obj:Object = {"quoted": 1, unquoted: 2, 3: "three", nested: {a: [1, {b: 2}]}};
        var fn:Function = function(...args):int { return args.length; };
        var vec:Vector.<String> = new Vector.<String>(2, true);
        var sorted:Array = arr.sort(Array.NUMERIC | Array.DESCENDING);
        var bytes:* = new <uint>[0x01, 0x02];
        n >>>= 1; n <<= 2; n >>= 1; n &= 7; n |= 1; n ^= 3; n %= 4;
        var andAssign:Boolean = true; andAssign &&= false; andAssign ||= true;
        label1: for (var a:int = 0; a < 3; a++) {
            label2: for (var b:int = 0; b < 3; b++) {
                if (b == 1) continue label1;
                if (a == 2) break label1;
            }
        }
        with (obj) {
            unquoted = 5;
        }
        do { n--; } while (n > 0);
        switch (typeof s) {
            case "string": break;
            case "number": break;
        }
        var ns:Namespace = new Namespace("ex", "http://example.com/ns");
        default xml namespace = ns;
        var qn:QName = new QName(ns, "local");
        var xml:XML = <stock xmlns:ex="http://example.com/ns"><ex:item id="1" qty="3"/><![CDATA[raw <text>]]></stock>;
        var attrs:XMLList = xml.@*;
        var desc:XMLList = xml..ex::item;
        var cond:XMLList = xml.ex::item.(@qty > 2);
        xml.ex::item[0].@qty = 4;
        xml.appendChild(<extra/>);
        delete xml.ex::item[0];
        var tmpl:XML = <a b={n} c="{s}">{s + "!"}</a>;
        var any:* = null;
        if (any == null && any === undefined) { trace("nothing"); }
        throw new Error("fatal", 42);
    }

    public function get computed():Number { return fast(counter); }
    public function set computed(v:Number):void { counter = uint(v); }
    AS3 function legacy():void {}
    prototype.oldStyle = function():void {};
}

internal interface IExtras extends IStockHolder {
    function get computed():Number;
    function set computed(v:Number):void;
}

internal function topLevel(a:int, b:int = 2, ...rest):void {
    trace(arguments.length, arguments.callee);
}

// ── Unnamed package, conditional compilation, SWF metadata ───────────
package {
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.*;
    import flash.utils.Proxy;
    import flash.utils.flash_proxy;
    import flash.utils.describeType;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;

    use namespace flash_proxy;

    [SWF(width="800", height="600", frameRate="60", backgroundColor="#102030")]
    [Frame(factoryClass="Preloader")]
    [ExcludeClass]
    [DefaultProperty("children")]
    [ArrayElementType("String")]
    [RemoteClass(alias="com.example.Stock")]
    [Style(name="gap", type="Number", inherit="no")]
    [Event(name="ready", type="flash.events.Event")]
    [Bindable("changed")]
    [Transient]
    [Inject]
    public final class Showcase extends Sprite {

        // Conditional compilation constants and blocks
        CONFIG::debug {
            private var debugLog:Array = [];
        }
        CONFIG::release {
            private var releaseFlag:Boolean = true;
        }
        CONFIG::debug const verbose:Boolean = true;

        // Modifier orderings and visibility
        public static const ONE:int = 1, TWO:int = 2;
        static public var shared:Object = {};
        static private var hidden:int;
        final public function sealedMethod():void {}
        public final override function toString():String { return "Showcase"; }
        override protected function dispatchEvent_(e:Event):Boolean { return false; }
        internal static function helper():void {}

        // Rest, default values, typed and untyped params
        public function many(first:*, second:int = 2, third:String = "x", ... rest:Array):void {
            var count:int = rest.length;
            var args:Array = [first, second, third].concat(rest);
        }

        // Nested functions, closures and function expressions
        public function closures():Function {
            var counter:int = 0;
            function inner(step:int = 1):int { return counter += step; }
            var anon:Function = function(x:int):int { return x * 2; };
            var bound:Function = inner;
            return function():int { return inner() + anon(2); };
        }

        // Types: Vector, Dictionary, generics-like syntax, wildcard
        public function types():void {
            var v1:Vector.<int> = new Vector.<int>();
            var v2:Vector.<*> = new <*>[1, "two", 3.0];
            var v3:Vector.<Vector.<String>> = new Vector.<Vector.<String>>(2, true);
            var d:Dictionary = new Dictionary(false);
            var u:uint = 0xFFFFFFFF;
            var i:int = -2147483648;
            var n:Number = 1.5E+10 + .5 + 5. + 0x1F;
            var s1:String = 'single "quoted"';
            var s2:String = "double 'quoted' é \x41 \101";
            var multi:String = "line one\
line two";
            var re:RegExp = /(?P<year>\d{4})-(?P<month>\d\d)/gimsx;
            var re2:RegExp = new RegExp("a+b", "g");
            var cls:Class = getDefinitionByName("flash.display.Sprite") as Class;
            var qn:QName = new QName("urn:x", "name");
            var date:Date = new Date(2024, 0, 1, 12, 30, 0, 0);
            var err:Error = new RangeError("bad range", 1);
            var xmlList:XMLList = new XMLList("<a/><b/>");
        }

        // Operators: is, as, in, instanceof, typeof, delete, void, comma
        public function operators(o:Object):void {
            var a:Boolean = o is String;
            var b:Object = o as Sprite;
            var c:Boolean = "k" in o;
            var d:Boolean = o instanceof Object;
            var e:String = typeof o;
            var f:Boolean = delete o.key;
            var g:* = void 0;
            var h:int = (1, 2);
            var cast1:Sprite = Sprite(o);
            var cast2:int = int("12");
            var cast3:Number = Number("1.5");
            var cast4:Boolean = Boolean(o);
            var cast5:String = String(o);
            var cast6:Array = Array(o);
            var cast7:XML = XML("<x/>");
            var t:Boolean = a ? b != null : !c;
            var shift:uint = 1 << 31 >>> 28 >> 1;
        }

        // Statements: for, for each, for in, while, do, labels, with, switch
        public function statements(list:Array, dict:Object):void {
            for (var i:int = 0, j:int = 10; i < j; i++, j--) {}
            for (;;) { break; }
            for each (var item:* in list) { if (item == null) continue; }
            for each (var val:String in dict) { trace(val); }
            for (var key:* in dict) { trace(key, dict[key]); }
            var k:int = 0;
            while (k < 3) k++;
            do k--; while (k > 0);
            top: for (var x:int = 0; x < 2; x++) { for (var y:int = 0; y < 2; y++) { if (y) continue top; } }
            with (dict) { trace(length); }
            switch (k) {
                case 0: case 1: trace("low"); break;
                case 2: { trace("two"); break; }
                default: trace("other");
            }
            if (k) trace("a"); else if (!k) trace("b"); else trace("c");
            try { throw "string error"; } catch (e:*) { trace(e); } finally { trace("end"); }
            try { null.x; } catch (e:TypeError) { trace(e.errorID); }
            return;
        }

        // E4X: descendants, filters, namespaces, mutation, literals
        public function e4x():void {
            default xml namespace = new Namespace("http://example.com/ns");
            var xml:XML = <catalog xmlns:p="http://example.com/p">
                <p:item id="1" price="9.5"><name>Alpha</name></p:item>
                <p:item id="2" price="3"><name>Beta</name></p:item>
                <!-- comment node -->
                <?pi processing instruction?>
            </catalog>;
            var p:Namespace = xml.namespace("p");
            var names:XMLList = xml.p::item.name;
            var cheap:XMLList = xml.p::item.(@price < 5);
            var first:XML = xml.p::item[0];
            var allAttrs:XMLList = xml.p::item.@*;
            var deep:XMLList = xml..name;
            var text:String = xml.p::item.name.text();
            var kids:XMLList = xml.*;
            var count:int = xml.p::item.length();
            xml.p::item[0].@price = 10;
            xml.p::item[1].name = "Gamma";
            xml.appendChild(<p:item id="3"/>);
            xml.p::item += <p:item id="4"/>;
            delete xml.p::item[0];
            var dyn:XML = <row id={count} label={"n" + count}>{names}</row>;
            XML.ignoreWhitespace = true;
            XML.prettyPrinting = false;
            var attrName:String = "id";
            var viaExpr:String = first.@[attrName];
            var viaQName:String = first.@p::id;
        }

        // Proxy overrides (flash_proxy namespace)
        flash_proxy override function getProperty(name:*):* { return null; }
        flash_proxy override function callProperty(name:*, ... rest):* { return null; }
        flash_proxy override function hasProperty(name:*):Boolean { return false; }
        flash_proxy override function nextNameIndex(index:int):int { return 0; }
    }
}

// ── Several types in one file: interface inheritance, dynamic, native ─
internal interface IReadable extends IEventDispatcher, IStockHolder {
    function read(count:uint = 1):Array;
    function get length():uint;
}

internal dynamic class Registry extends Proxy implements IReadable {
    private var _items:Array = [];
    public function read(count:uint = 1):Array { return _items.slice(0, count); }
    public function get length():uint { return _items.length; }
}

internal class StaticInit {
    public static var table:Object;
    // static initialiser block
    {
        table = {a: 1, b: 2};
        trace("class initialised");
    }
}

// Deprecated-but-valid: octal literals, with, prototype-based classes
function LegacyClass():void { this.value = 0; }
LegacyClass.prototype.getValue = function():int { return this.value; };
var legacyInstance:Object = new LegacyClass();
