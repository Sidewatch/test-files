#!/usr/bin/env dotnet
// C# 14 (.NET 10) — syntax showcase
// ── Comments ──
// Line comment. TODO: partition by warehouse. FIXME: rounding.
/* Block comment
   across lines */
/// <summary>
/// XML doc comment for <see cref="Product"/> with <c>code</c>.
/// </summary>
/// <param name="name">Product name.</param>
/// <typeparam name="T">Element type.</typeparam>
/// <returns>A value.</returns>
/// <remarks>Remarks go <paramref name="name"/> here.</remarks>

// ── Preprocessor ──
#define WAREHOUSE_DEBUG
#undef LEGACY
#nullable enable annotations
#nullable enable
#pragma warning disable CS0168
#pragma warning restore CS0168
#region Directives
#if WAREHOUSE_DEBUG && !LEGACY
#warning Debug build
#elif RELEASE
#else
#error Unsupported configuration
#endif
#endregion
#line 200 "inventory.cs"
#line hidden
#line default

// ── Usings ──
extern alias Legacy;
global using System.IO;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static System.Math;
using Json = System.Text.Json.JsonSerializer;
using Point3 = (int X, int Y, int Z);

[assembly: System.Reflection.AssemblyVersion("1.0.0.0")]
[module: System.Runtime.CompilerServices.SkipLocalsInit]
#if WAREHOUSE_DEBUG
[Obsolete("debug only")]
#endif
[Serializable]
public class Conditional { [param: NonSerialized] public void M([param: Optional] int x) { } [property: NonSerialized] public int P { get; set; } [typevar: Foo] public void G<T>() { } }

namespace Acme.Warehouse;

// ── Delegates, events ──
public delegate void StockChanged(object sender, int delta);
public delegate TResult Transformer<in TIn, out TResult>(TIn input);

// ── Enums ──
[Flags]
public enum Category : byte
{
    None = 0,
    Tools = 1,
    Fasteners = 1 << 1,
    Safety = 0b0100,
    All = Tools | Fasteners | Safety,
}

// ── Interfaces ──
public interface IAuditable
{
    void Audit();
    string Id { get; }
    int Compare(IAuditable other) => 0;
    static abstract IAuditable Create();
}

// ── Records and structs ──
public record Product(string Name, decimal Price, Category Kind);
public record struct Point(int X, int Y);
public readonly record struct Weight(double Kilograms);
public record Perishable(string Name, decimal Price) : Product(Name, Price, Category.None)
{
    public DateTime Expires { get; init; }
}

public readonly struct Dimensions
{
    public int Width { get; }
    public int Height { get; }
    public Dimensions(int w, int h) => (Width, Height) = (w, h);
    public void Deconstruct(out int w, out int h) { w = Width; h = Height; }
}

public ref struct Span2 { public Span<int> Items; }

// ── Attributes and generics ──
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false)]
public sealed class AuditAttribute : Attribute
{
    public string Level { get; init; } = "info";
}

[Serializable]
[Audit(Level = "high")]
public abstract class Repository<TKey, TValue> : IAuditable
    where TKey : notnull, IComparable<TKey>
    where TValue : class, new()
{
    private readonly Dictionary<TKey, TValue> _items = new();
    protected internal static readonly int MaxItems = 1_000;
    private volatile bool _dirty;
    public event StockChanged? Changed;
    public string Id => $"repo-{typeof(TValue).Name}";

    public TValue this[TKey key]
    {
        get => _items[key];
        set { _items[key] = value; _dirty = true; Changed?.Invoke(this, 1); }
    }

    public abstract void Audit();
    public virtual IEnumerable<TValue> All() => _items.Values;
    public static IAuditable Create() => throw new NotImplementedException();
    ~Repository() { }

    public static Repository<TKey, TValue> operator +(Repository<TKey, TValue> a, TValue b) => a;
    public static implicit operator int(Repository<TKey, TValue> r) => r._items.Count;
    public static explicit operator string(Repository<TKey, TValue> r) => r.Id;
}

public partial class Bin : Repository<int, Product>
{
    private int _count;
    public int Count { get => _count; private set => _count = value; }
    public required string Label { get; init; }
    public override void Audit() => Console.WriteLine($"Bin {Label}");
    public Bin() : base() { }
    static Bin() { }
    public unsafe void Raw(int* p) { *p = 1; }
}

public static class Extensions
{
    public static string Shout(this string s) => s.ToUpperInvariant() + "!";
    public static T? FirstOr<T>(this IEnumerable<T> src, T? fallback = default) => src.FirstOrDefault() ?? fallback;
}

// ── Main program ──
public static class Program
{
    private const double Pi = 3.14159;

    // ── Literals ──
    static void Literals()
    {
        int dec = 1_000_000;
        int hex = 0xFF_EC;
        int bin = 0b1010_1010;
        uint u = 42u;
        long l = 42L;
        ulong ul = 42UL;
        float f = 2.5f;
        double d = 6.02e23;
        double d2 = 1.5E-10;
        double d3 = .5;
        decimal m = 19.99m;
        double nan = double.NaN, inf = double.PositiveInfinity;
        char c = 'a', nl = '\n', uni = '\u00e9', hx = '\x41';
        bool yes = true, no = false;
        object? none = null;

        string plain = "Warehouse \"north\"\ttab\n";
        string verbatim = @"C:\stock\bins ""quoted""
second line";
        string interp = $"Total: {dec,10:N0} items at {d:F2} {{literal braces}}";
        string interpVerbatim = $@"path\{dec}";
        string interpAt = @$"path\{dec}";
        string raw = """
            Raw "string" literal with "quotes" and \n kept
            """;
        string rawInterp = $$"""{ "sku": "{{plain}}" }""";
        string utf8 = "bytes"u8.Length.ToString();
        string esc = "bell\a nul\0 bs\b ff\f cr\r vt\v \U0001F4E6";
    }

    // ── Control flow and expressions ──
    static async Task<int> Main(string[] args)
    {
        var items = new List<Product> { new("Hammer", 12.5m, Category.Tools), new("Bolt", 0.1m, Category.Fasteners) };
        int[] arr = [1, 2, 3, ..4];
        var range = arr[1..^1];
        var last = arr[^1];
        var anon = new { Sku = "A-1", Qty = 5 };
        (int a, int b) tuple = (1, 2);
        var (x, y) = tuple;

        int n = args.Length;
        n += 1; n -= 1; n *= 2; n /= 2; n %= 5; n <<= 1; n >>= 1; n &= 7; n |= 1; n ^= 3;
        n ??= 0;
        string? s = null;
        s ??= "default";
        int len = s?.Length ?? 0;
        int? maybe = null;
        int val = maybe!.Value;
        bool cmp = n < 3 && n >= 1 || n != 2 && !(n == 0);
        int tern = cmp ? 1 : 0;
        bool isStr = s is string;
        var asObj = s as object;
        int bits = ~n ^ (n & 1) | (n << 2);

        if (n > 3) { Console.WriteLine("big"); }
        else if (n > 1) { Console.WriteLine("mid"); }
        else { Console.WriteLine("small"); }

        var label = n switch
        {
            0 => "zero",
            1 or 2 => "few",
            > 2 and < 10 => "some",
            int k when k > 100 => "lots",
            _ => "many",
        };

        object obj = items;
        if (obj is List<Product> { Count: > 1 } list && list is not null) { }
        if (obj is not null and IEnumerable<Product>) { }

        switch (obj)
        {
            case int i when i > 0: break;
            case string str: break;
            case null: break;
            default: break;
        }

        for (int i = 0; i < 3; i++) { if (i == 1) continue; }
        foreach (var item in items) { Console.WriteLine(item.Name); }
        while (n-- > 0) { if (n == 2) break; }
        do { n++; } while (n < 3);
        goto done;
    done:

        lock (items) { }
        using var reader = new StringReader("x");
        using (var w = new StringWriter()) { }
        checked { n++; }
        unchecked { n++; }

        try
        {
            throw new InvalidOperationException("bad bin");
        }
        catch (InvalidOperationException ex) when (ex.Message.Length > 0)
        {
            Console.Error.WriteLine(ex.Message);
        }
        catch (Exception)
        {
            throw;
        }
        finally
        {
            Console.WriteLine("cleanup");
        }

        // ── LINQ ──
        var query = from p in items
                    where p.Price > 1m
                    orderby p.Name descending
                    group p by p.Kind into g
                    let total = g.Sum(p => p.Price)
                    join c in items on g.Key equals c.Kind
                    select new { g.Key, total };
        var fluent = items.Where(p => p.Price > 1m).Select(p => p.Name).ToList();

        // ── Lambdas, local functions, async ──
        Func<int, int> square = v => v * v;
        Action<string> print = static str => Console.WriteLine(str);
        Transformer<int, string> t = delegate (int v) { return v.ToString(); };
        int Local(int v) => v + 1;
        await Task.Delay(10).ConfigureAwait(false);
        await foreach (var v in Stream()) { }
        var tcs = new TaskCompletionSource<int>();
        var typeName = nameof(Program);
        var size = sizeof(int);
        var typ = typeof(List<>);
        var def = default(int);
        dynamic dyn = 5;
        var cast = (int)3.7;
        return 0;
    }

    static async IAsyncEnumerable<int> Stream()
    {
        yield return 1;
        await Task.Yield();
        yield break;
    }

    static IEnumerable<int> Counter(int max)
    {
        for (var i = 0; i < max; i++) yield return i;
    }

    static ref int RefReturn(ref int x, in int y, out int z) { z = y; return ref x; }
    static void Params(params int[] values) { }
    static void Named(int a, int b = 2, string c = "c") { }
}

// ── Further constructs ──
// A block-scoped namespace cannot coexist with the file-scoped one above (CS8955); kept for completeness.
namespace Acme.Warehouse.Extras
{
    using Alias = System.Collections.Generic.List<(int Id, string Name)>;

    file class FileLocal { }

    public interface IShape
    {
        static abstract double Area(double r);
        static virtual string Name => "shape";
        abstract void Draw();
    }

    public interface IAdd<TSelf> where TSelf : IAdd<TSelf>
    {
        static abstract TSelf operator +(TSelf a, TSelf b);
        static abstract bool operator ==(TSelf a, TSelf b);
        static abstract bool operator !=(TSelf a, TSelf b);
    }

    public struct Money : IAdd<Money>, IEquatable<Money>, IComparable<Money>
    {
        public decimal Amount { get; init; }
        public static Money operator +(Money a, Money b) => new() { Amount = a.Amount + b.Amount };
        public static Money operator checked +(Money a, Money b) => new() { Amount = checked(a.Amount + b.Amount) };
        public static Money operator -(Money a) => new() { Amount = -a.Amount };
        public static Money operator ++(Money a) => new() { Amount = a.Amount + 1 };
        public static bool operator ==(Money a, Money b) => a.Amount == b.Amount;
        public static bool operator !=(Money a, Money b) => !(a == b);
        public static bool operator true(Money a) => a.Amount != 0;
        public static bool operator false(Money a) => a.Amount == 0;
        public static Money operator >>>(Money a, int n) => a;
        public bool Equals(Money other) => this == other;
        public int CompareTo(Money other) => Amount.CompareTo(other.Amount);
        public override bool Equals(object? obj) => obj is Money m && Equals(m);
        public override int GetHashCode() => Amount.GetHashCode();
    }

    public class Events
    {
        private EventHandler? _handler;
        public event EventHandler Custom
        {
            add { _handler += value; }
            remove { _handler -= value; }
        }
        public event Action<int>? Auto;
        public void Raise() => Auto?.Invoke(1);
    }

    public unsafe class Native
    {
        [System.Runtime.InteropServices.DllImport("libc", EntryPoint = "getpid")]
        private static extern int GetPid();

        public static void Pointers()
        {
            int value = 5;
            int* p = &value;
            *p += 1;
            int[] arr = { 1, 2, 3 };
            fixed (int* q = arr) { q[0] = q[1] + *q; }
            Span<int> span = stackalloc int[4];
            var size = sizeof(Money);
            void* raw = (void*)p;
            nint native = (nint)raw;
            nuint unsignedNative = 0;
        }
    }

    public static class Patterns
    {
        public static string Match(object o) => o switch
        {
            null => "null",
            int and > 0 and < 10 => "small",
            int or long => "integral",
            string { Length: 0 } => "empty",
            string s when s.StartsWith("A-") => "sku",
            [1, 2, ..] => "starts with 1 2",
            [var first, .., var last] => $"{first}..{last}",
            (int x, int y) => $"point {x},{y}",
            Money { Amount: > 100m } => "rich",
            not null => "other",
        };

        public static void Misc(int[] list, string? text, ref int counter)
        {
            var copy = list is [_, _, ..] ? list[..2] : list;
            var recordCopy = new Perishable("Milk", 1m) { Expires = DateTime.Today } with { Expires = DateTime.MaxValue };
            if (text is { Length: > 3 } t && t is not "stop") { counter++; }
            var type = text?.GetType() ?? typeof(void);
            var def = default(Money);
            Money other = default;
            var tuple = (Name: "a", Count: 1);
            var (name, _) = tuple;
            scoped Span<int> s = stackalloc int[2];
            ref readonly var r = ref list[0];
            ref int rr = ref counter;
            ref var refLocal = ref rr;
            object boxed = 5;
            if (boxed is int unboxed) counter += unboxed;
            dynamic d = new System.Dynamic.ExpandoObject();
            d.Name = "dynamic";
            var anon = new { A = 1, B = "b", C = new[] { 1, 2 } };
            var lambda = (int a, int b = 2) => a + b;
            var staticLambda = static (int a) => a;
            var asyncLambda = async () => await Task.Yield();
            Func<int> method = Program.GetNumber;
            var tc = (Action)(() => { });
            Action? maybe = null;
            maybe?.Invoke();
            int? nullable = null;
            nullable ??= 1;
            var coalesce = nullable ?? throw new ArgumentNullException(nameof(nullable));
            object o = new();
            Span<char> chars = ['a', 'b'];
            ReadOnlySpan<byte> utf8 = "data"u8;
            var @event = 1;
            var global_ = global::System.Math.PI;
            char c1 = '\'', c2 = '\\', c3 = '\0', c4 = 'A', c5 = '\x41', c6 = '\U0001F4E6'.ToString()[0];
            var longEsc = "tab\t quote\" backslash\\ é \x41 \U0001F4E6 \e";
            var csv = $"{counter,5}|{counter,-5}|{counter:D3}|{(counter > 0 ? "pos" : "neg")}";
            var ranges = new[] { ^1, 0 };
            Index idx = ^2;
            Range rg = 1..^1;
        }

        private static int GetNumber() => 7;
        public static int Local => 1;
        public int this[Index i] => 0;
        public int this[Range r] => 0;
        public static implicit operator int(Patterns p) => 0;
        public ref struct RS { }
        public static async ValueTask<int> Value() => await new ValueTask<int>(1);
        public static void Goto(int n)
        {
            switch (n)
            {
                case 1:
                    goto case 2;
                case 2:
                    goto default;
                default:
                    break;
            }
            __arglist();
        }
    }

    [System.Diagnostics.CodeAnalysis.SuppressMessage("Style", "IDE0001")]
    [return: System.Diagnostics.CodeAnalysis.NotNull]
    public delegate T Factory<out T>() where T : class;

    public class Generic<T, U> where T : struct where U : class?, new()
    {
        [field: NonSerialized]
        public int Field { get; set; }
        public T? Value { get; init; }
        public static T Create<TNew>() where TNew : T, new() => default;
        public interface INested { }
        protected private int hidden;
        public sealed override string ToString2() => "";
        public const string Constant = "c";
        public static readonly int ReadOnly = 1;
        public event EventHandler<EventArgs>? Changed;
        public int Prop { get; } = 5;
        public int Computed => Prop * 2;
        public Generic() { }
        ~Generic() { }
    }

    // ── C# 14 / 13 / 12 additions ──
    public static class Ext14
    {
        extension(string source)
        {
            public bool IsBlank => string.IsNullOrWhiteSpace(source);
            public string Twice() => source + source;
            public static string operator *(string text, int times) => string.Concat(Enumerable.Repeat(text, times));
        }

        extension<T>(IEnumerable<T> source) where T : notnull
        {
            public bool AnyItems => source.Any();
            public IEnumerable<T> Doubled() => source.Concat(source);
        }
    }

    public partial class Partials
    {
        public partial Partials(int n);
        public partial int Size { get; set; }
        public partial event EventHandler Moved;
    }

    public partial class Partials
    {
        public partial Partials(int n) { }
        public partial int Size { get => field; set => field = value < 0 ? 0 : value; }
        public partial event EventHandler Moved { add { } remove { } }

        public string Title { get; set => field = value.Trim(); } = "";
        public static void NullConditionalAssign(Partials? p, int[]? a)
        {
            p?.Size = 5;
            p?.Size += 1;
            a?[0] = 1;
        }
    }

    public delegate bool TryParser(string text, out int result);

    public class Modern(string name, int slots) : IDisposable
    {
        private readonly System.Threading.Lock _gate = new();
        public string Name => name;
        public void Dispose() { lock (_gate) { } }
        public static void Params(params ReadOnlySpan<int> values) { }
        public static void Params2(params IEnumerable<string> values) { }
        public static void Allows<T>(T value) where T : allows ref struct { } // allows ref struct: C# 13
        [System.Runtime.CompilerServices.OverloadResolutionPriority(1)]
        public static void Prefer(int[] a) { }
        public static void Lambdas()
        {
            TryParser parse = (text, out result) => int.TryParse(text, out result);
            var defaults = (int a = 1, params int[] rest) => a;
            Func<ref int, int> byRef = (ref int x) => x;
            var tuple3 = new Point3(1, 2, 3);
            var nameOfOpen = nameof(List<>);
            var esc = "\e[0m";
        }
    }

    [System.Runtime.CompilerServices.InlineArray(4)]
    public struct Buffer4 { private int _element0; }

    // ── Compiler-era corners ──
    public unsafe class Corners
    {
        public static void Run(TypedReference tr, string[] names)
        {
            ;
            int local = 3;
            _ = int.TryParse("7", out var parsed);
            _ = int.TryParse("8", out int typed);
            var made = __makeref(local);
            Type t = __reftype(made);
            int back = __refvalue(made, int);
            unsafe { int* p = &local; (*p)++; var sx = new Point3(); }
            fixed (char* c = "abc") { }
            int[] sized = new int[3];
            int[] filled = new int[] { 1, 2, 3 };
            int[,] grid = new int[2, 2];
            int[][] jagged = new int[2][];
            var implicitStack = stackalloc[] { 1, 2, 3 };
            var legacy = new Legacy::Old.Thing();
            var root = global::System.Math.PI;
            object o = 5;
            if (o is var anything) { }
            if (o is (int or long) and not 0) { }
            if (o is (string)) { }
            var (a, (b, c2)) = (1, (2, 3));
            var (x, _) = (1, 2);
            var nested = (a: 1, b: (c: 2, d: 3));
            var pq = new Point3 { X = 1 };
            Point3* ptr = null;
            ptr->X = 1;
            int rem = a % 2;
            double half = a / 2.0;
            bool le = a <= b;
            int shr = a >> 1;
            uint ushr = 8u; ushr >>>= 1;
            var q = from n in names
                    orderby n ascending, n.Length descending
                    join m in names on n equals m into grouped
                    select grouped;
            delegate*<int, int> managedPtr = null;
            delegate* managed<int, int> managedPtr2 = null;
            delegate* unmanaged<int, int> unmanagedPtr = null;
            delegate* unmanaged[Cdecl]<int, int> cdecl = null;
            delegate* unmanaged[Stdcall]<int, int> stdcall = null;
            delegate* unmanaged[Fastcall]<int, int> fastcall = null;
            delegate* unmanaged[Thiscall]<int, int> thiscall = null;
            delegate* unmanaged[Cdecl, SuppressGCTransition]<int, void> multi = null;
        }
        public static void Scoped(scoped ref int x, scoped Span<int> span, scoped in int y) { }
        public static ref int Ref(scoped ref int a) => ref a;
    }

    public class ExplicitImpl : IAuditable
    {
        string IAuditable.Id => "explicit";
        void IAuditable.Audit() { }
        static IAuditable IAuditable.Create() => new ExplicitImpl();
    }

    public enum Bits : long { A = 1L << 0, B = 1L << 40, Mask = ~0L }
    public class Ns { public override string ToString() => nameof(Ns); }
}

#pragma checksum "file.cs" "{406EA660-64CF-4C82-B6F0-42D48172A799}" "ab007f1d23d9"
#nullable restore
#nullable disable warnings
