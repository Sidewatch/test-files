// ── Comments ───────────────────────────────────────────────
// Line comment. TODO: persist the stock. FIXME: rounding.
/* Block comment
   spanning lines */
/**
 * Doc comment for the warehouse namespace.
 *
 * @param sku the stock keeping unit
 * @return the matching item, or null
 * @see Warehouse.Item
 * @since 1.0
 */

// ── Preprocessor ───────────────────────────────────────────
#if DEBUG
const bool verbose = true;
#elif TRACE
const bool verbose = true;
#else
const bool verbose = false;
#endif

using GLib;
using Gee;

// ── Namespace, constants, enums ────────────────────────────
namespace Warehouse {

    public const int REORDER_POINT = 25;
    public const double RATIO = 0.75;
    public const string APP_NAME = "Warehouse";

    [Flags]
    public enum Perm {
        READ,
        WRITE,
        EXEC;

        public string label () {
            return this.to_string ();
        }
    }

    public enum Status {
        PENDING = 0,
        PAID = 1,
        CANCELLED
    }

    public errordomain StockError {
        EMPTY,
        NEGATIVE,
        PARSE
    }

    public delegate int Reducer (int acc, int value);

    // ── Interfaces and structs ─────────────────────────────
    public interface Describable : Object {
        public abstract string describe ();
        public virtual string tag () {
            return "item";
        }
    }

    public struct Point {
        public int x;
        public int y;

        public Point (int x, int y) {
            this.x = x;
            this.y = y;
        }
    }

    // ── Class with properties, signals, constructors ───────
    [CCode (cname = "warehouse_item_new")]
    public class Item : Object, Describable {
        private static int instances = 0;
        private int _qty;
        protected string internal_name;
        internal bool dirty = false;

        public string sku { get; construct; }
        public int qty {
            get { return _qty; }
            set { _qty = value < 0 ? 0 : value; }
        }
        public double price { get; set; default = 1.0; }
        public bool active { get; private set; default = true; }
        public string[] tags { get; set; }
        public Status status { get; set; default = Status.PENDING; }

        public signal void restocked (int amount);

        [Signal (action = true)]
        public virtual signal void low_stock (int remaining);

        static construct {
            instances = 0;
        }

        construct {
            instances++;
        }

        public Item (string sku, int qty = 0) {
            Object (sku: sku, qty: qty);
        }

        public Item.with_price (string sku, double price) {
            this (sku);
            this.price = price;
        }

        ~Item () {
            instances--;
        }

        public override string describe () {
            return "%s: %d left".printf (sku, qty);
        }

        public void restock (int amount) requires (amount > 0) ensures (qty >= amount) {
            qty += amount;
            restocked (amount);
        }

        public static Item parse (string line) throws StockError {
            string[] parts = line.split (",");
            if (parts.length != 3) {
                throw new StockError.PARSE ("expected 3 fields, got %d", parts.length);
            }
            var item = new Item (parts[0], int.parse (parts[1]));
            item.price = double.parse (parts[2]);
            return item;
        }

        public Item? find_better (Item[] others) {
            foreach (unowned Item o in others) {
                if (o.price < price) return o;
            }
            return null;
        }
    }

    public abstract class Shape : Object {
        public abstract double area ();
        public virtual void draw () {}
    }

    public class Square : Shape {
        public override double area () { return 4.0; }
        public new void draw () {}
    }

    public class Box<T> : Object {
        public T content;
        public Box (T content) { this.content = content; }
        public T get_content<V> (V extra) where V : Object { return content; }
    }
}

// ── Strings and literals ───────────────────────────────────
void literals () {
    string plain = "double \"quoted\" with \t tab, \n newline, \x41, é, \101";
    string verbatim = """Verbatim string
    with "quotes" and \n kept literally.""";
    string tpl = @"item $(plain.length) and ${1 + 2} and $plain";
    char c = 'x';
    char nl = '\n';
    unichar u = '☃';
    int dec = 42;
    int hex = 0xFF;
    int oct = 0755;
    long l = 123L;
    uint ui = 7U;
    uint64 big = 0xFFFFFFFFFFFFUL;
    float f = 1.5f;
    double d = 1.5e-3;
    double d2 = .5;
    bool t = true;
    bool fl = false;
    string? nothing = null;
    var re = /^[A-Z]{3}-\d+$/i;
    print ("%s %c %d\n", plain, c, dec);
}

// ── Control flow and operators ─────────────────────────────
int main (string[] args) {
    var items = new Gee.ArrayList<Warehouse.Item> ();
    items.add (new Warehouse.Item ("WGT-100", 12));
    items.add (new Warehouse.Item.with_price ("GDG-200", 3.5));
    items[0].restocked.connect ((amount) => stdout.printf ("restocked %d\n", amount));
    items[0].low_stock.connect (() => { print ("low\n"); });

    int n = 10;
    n += 1; n -= 1; n *= 2; n /= 2; n %= 7; n <<= 1; n >>= 1; n &= 0xf; n |= 1; n ^= 2;
    n++; n--;
    bool ok = !(n > 1 && n < 5) || n == 3 || n != 4 || n >= 1 || n <= 9;
    int bits = ~n & 2 | 3 ^ 4 << 1 >> 1;
    string label = ok ? "yes" : "no";
    string maybe = null ?? "default";
    bool is_item = items[0] is Warehouse.Item;
    Warehouse.Item? same = items[0] as Warehouse.Item;
    var sz = sizeof (int);
    var tn = typeof (Warehouse.Item);
    var casted = (double) n;
    int[] arr = { 1, 2, 3, 4, 5 };
    int[,] grid = new int[3, 3];
    var slice = arr[1:3];
    var inl = "a" in new string[] { "a", "b" };

    for (int i = 0; i < 3; i++) {
        if (i == 1) continue;
        else if (i == 2) break;
    }
    foreach (var o in items) {
        stdout.printf ("%s\n", o.describe ());
    }
    while (n > 0) { n--; }
    do { n++; } while (n < 3);
    switch (n) {
        case 1:
        case 2:
            print ("low\n");
            break;
        default:
            print ("other\n");
            break;
    }

    try {
        var parsed = Warehouse.Item.parse ("bad");
        print ("%s\n", parsed.sku);
    } catch (Warehouse.StockError e) {
        stderr.printf ("error: %s\n", e.message);
    } finally {
        print ("done\n");
    }

    lock (items) {
        print ("locked\n");
    }

    var loop = new MainLoop ();
    Timeout.add (100, () => { loop.quit (); return false; });
    async_demo.begin ((obj, res) => { async_demo.end (res); });
    var out_val = 0;
    helper (out out_val, ref n);
    delete same;
    assert (n >= 0);
    return 0;
}

async void async_demo () {
    yield;
    Idle.add (async_demo.callback);
    yield;
}

void helper (out int result, ref int counter) {
    result = counter * 2;
    counter++;
}

unowned string get_name (owned string s) {
    return s;
}

[DBus (name = "com.example.Warehouse")]
interface WarehouseBus : Object {
    public abstract int count () throws GLib.Error;
}

// ── Types, modifiers and attributes ────────────────────────
[Compact]
[CCode (cname = "WarehouseHandle", free_function = "warehouse_handle_free", has_type_id = false)]
public class Handle {
    public int fd;
}

[SimpleType]
[CCode (cname = "int", has_type_id = false)]
public struct Id : int {}

[GIR (name = "Warehouse")]
[Version (since = "1.0", deprecated = true, deprecated_since = "2.0", replacement = "Stock")]
[Deprecated]
[Immutable]
[Experimental]
public sealed class Sealed : Object {
    public const int MAX = 100;
    public static int shared_count;
    public weak Object? parent;
    public dynamic Object? dyn;
    public inline int quick () { return 1; }
    public extern int native ();
    public int sum (params int[] values) {
        int total = 0;
        foreach (int v in values) total += v;
        return total;
    }
    public Sealed () {
        base ();
    }
    public override void dispose () {
        base.dispose ();
    }
}

[Flags]
public enum Mask {
    A = 1 << 0,
    B = 1 << 1,
    C = A | B;

    public bool has (Mask m) { return (this & m) == m; }
}

public class Numbers : Object {
    public int8 i8 = 1;
    public uint8 u8 = 2;
    public int16 i16 = 3;
    public uint16 u16 = 4;
    public int32 i32 = 5;
    public uint32 u32 = 6;
    public int64 i64 = 7;
    public short sh = 8;
    public ushort ush = 9;
    public long lg = 10;
    public ulong ulg = 11;
    public size_t sz = 12;
    public ssize_t ssz = 13;
    public time_t tm = 14;
    public float fl = 1.5f;
    public double db = 2.5;
    public bool bl = true;
    public unichar uc = 'x';
    public void* ptr = null;
    public string s = "str";
    public uint8[] bytes = { 0x01, 0x02 };
    public int[,] grid2 = new int[2, 2];
    public string? opt = null;
    public Object? obj;
    public unowned string un = "x";
    public owned string ow = "y";
}

// ── Generics, delegates, closures, iterators ───────────────
public delegate bool Predicate<T> (T item);

public class Collection<T> : Object {
    private Gee.ArrayList<T> list = new Gee.ArrayList<T> ();

    public void add (owned T item) { list.add ((owned) item); }

    public Collection<T> where (Predicate<T> p) {
        var result = new Collection<T> ();
        foreach (var item in list) if (p (item)) result.add (item);
        return result;
    }

    public Gee.Iterator<T> iterator () { return list.iterator (); }

    public Gee.Iterator<T> generate () {
        return list.iterator ();
    }
}

public interface Container<G> : Object {
    public abstract G get_item (int index);
    public abstract int size { get; }
    public abstract void each (Func<G> f);
}

void closures () {
    int captured = 10;
    Func<int> f = (x) => { print ("%d\n", x + captured); };
    f (1);
    var strs = new string[] { "a", "b" };
    strs.length;
    SourceFunc cb = () => { return Source.REMOVE; };
    var m = new HashTable<string, int> (str_hash, str_equal);
    m["k"] = 1;
    m.foreach ((k, v) => { print ("%s=%d\n", k, v); });
    var list = new List<string> ();
    list.append ("x");
    list.foreach ((s) => { print ("%s\n", s); });
}

// ── More statements ────────────────────────────────────────
void statements (int argc) {
    switch (argc) {
        case 0: print ("zero\n"); break;
        case 1: goto done;
        default: break;
    }
    string text = "x";
    switch (text) {
        case "x":
        case "y":
            print ("xy\n");
            break;
    }
    int i = 0;
    for (;;) { if (++i > 2) break; }
    var sb = new StringBuilder ();
    sb.append ("a").append_c ('b').append_unichar ('☃');
    unowned string u = sb.str;
    print ("%s %s\n", u, (string) null ?? "nil");
    if (typeof (Object) == typeof (Object) && sizeof (int) == 4) print ("types\n");
    var arr = new int[3];
    arr.resize (6);
    stdout.printf ("%d\n", arr.length);
    var tuple_like = (1, "a");
    with (sb) { append ("z"); }
    done:
    print ("done\n");
}

int yield_demo () {
    yield return 1;
    return 0;
}

extern void external_function (int x);
static int module_static = 0;
public const string[] NAMES = { "a", "b" };
public errordomain AppError { FAILED, TIMEOUT }

[DBus (name = "com.example.Stock")]
public interface StockService : Object {
    public abstract int count () throws DBusError, IOError;
    public signal void changed (string sku);
    [DBus (name = "SKU")] public abstract string sku { owned get; }
}

[GtkTemplate (ui = "/com/example/warehouse/window.ui")]
public class Window : Gtk.ApplicationWindow {
    [GtkChild] private unowned Gtk.Button button;
    [GtkCallback] private void on_click (Gtk.Button b) {}
}
