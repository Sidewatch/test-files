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
