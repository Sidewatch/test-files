// Java 25 — syntax showcase (no JDK installed here; written against JLS 25)
// ── Package and imports ──
package com.example.warehouse;

import java.io.IOException;
import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.*;
import module java.base;
import java.util.concurrent.CompletableFuture;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.stream.Collectors;
import static java.lang.Math.max;
import static java.util.Objects.requireNonNull;

/*
 * Block comment: a warehouse inventory model that touches every
 * lexical category of the language.
 */

/**
 * Doc comment for the whole unit.
 *
 * <p>Uses {@code HTML} tags and {@link Warehouse} references.
 *
 * @author Acme Tooling
 * @version 1.0
 * @since 17
 * @see <a href="https://example.com/docs">Docs</a>
 */
@SuppressWarnings({"unchecked", "rawtypes"})
public class Warehouse implements Serializable, Comparable<Warehouse> {

    // ── Constants and numbers ──
    private static final long serialVersionUID = 1L;
    public static final int MAX_BINS = 0x7FFF_FFFF;
    static final int OCTAL_MODE = 0755;
    static final int BINARY_FLAGS = 0b1010_0101;
    static final long BIG = 9_000_000_000L;
    static final float RATIO = 0.75f;
    static final double SCIENTIFIC = 1.6e-19;
    static final double HEX_FLOAT = 0x1.8p1;
    static final double INF = Double.POSITIVE_INFINITY;
    static final double NOT_NUMBER = Double.NaN;
    static final char LETTER = 'A';
    static final char TAB = '\t';
    static final char UNICODE = 'é';
    static final char OCT_CHAR = '\101';
    static final boolean ENABLED = true;
    static final Object NOTHING = null;

    // ── Strings ──
    static final String PLAIN = "Pallet \"A-100\"\tqty\\n";
    static final String UNICODE_STR = "Zürich → 東京 ✓ ☃";
    static final String TEXT_BLOCK = """
        Warehouse report
          indented line with "quotes" and \\ backslash
        trailing space escape\s
        joined \
        line
        """;

    // ── Fields and modifiers ──
    private final String name;
    private volatile int version;
    protected transient List<Item> items = new ArrayList<>();
    private static int counter;
    int[] bins = {1, 2, 3};
    int[][] grid = new int[3][4];

    static {
        counter = 0;
    }

    {
        version = 1;
    }

    // ── Annotations ──
    @Retention(java.lang.annotation.RetentionPolicy.RUNTIME)
    @Target({java.lang.annotation.ElementType.METHOD, java.lang.annotation.ElementType.TYPE})
    public @interface Audited {
        String value() default "none";
        int level() default 1;
    }

    // ── Enum with payload ──
    public enum Status {
        IN_STOCK("in", 1), LOW("low", 2), OUT("out", 3) {
            @Override
            public boolean alarming() { return true; }
        };

        private final String code;
        private final int rank;

        Status(String code, int rank) {
            this.code = code;
            this.rank = rank;
        }

        public boolean alarming() { return false; }
    }

    // ── Interface with default and static methods ──
    interface Priced {
        BigDecimal price();

        default BigDecimal withTax(BigDecimal rate) {
            return price().multiply(BigDecimal.ONE.add(rate));
        }

        static Priced free() { return () -> BigDecimal.ZERO; }
    }

    // ── Record, sealed hierarchy ──
    public record Item(String sku, int quantity, BigDecimal unitPrice) implements Priced {
        public Item {
            if (quantity < 0) throw new IllegalArgumentException("negative quantity");
        }

        @Override
        public BigDecimal price() { return unitPrice.multiply(BigDecimal.valueOf(quantity)); }
    }

    sealed interface Event permits Received, Shipped {}
    record Received(String sku, int count) implements Event {}
    record Shipped(String sku, int count, String carrier) implements Event {}

    // ── Generics with bounds ──
    static class Box<T extends Comparable<? super T>> {
        private T value;
        Box(T value) { this.value = value; }
        <R extends Number> R convert(Function<? super T, ? extends R> fn) { return fn.apply(value); }
        static <E> List<E> listOf(E... elements) { return List.of(elements); }
    }

    // ── Constructors ──
    public Warehouse(String name) {
        this.name = requireNonNull(name);
        counter++;
    }

    // ── Methods, control flow ──
    @Audited(value = "stock", level = 2)
    public int totalQuantity() {
        int sum = 0;
        for (Item item : items) {
            sum += item.quantity();
        }
        return sum;
    }

    public String describe(Event event) {
        return switch (event) {
            case Received r when r.count() > 100 -> "bulk receipt of " + r.sku();
            case Received r -> "receipt of " + r.sku();
            case Shipped(String sku, int count, String carrier) -> sku + " x" + count + " via " + carrier;
        };
    }

    public String classify(Object o) {
        if (o instanceof String s && !s.isEmpty()) {
            return "string:" + s;
        } else if (o instanceof Integer i) {
            return "int:" + i;
        } else {
            return "other";
        }
    }

    public int legacySwitch(Status status) {
        int result;
        switch (status) {
            case IN_STOCK:
                result = 1;
                break;
            case LOW:
            case OUT:
                result = 2;
                break;
            default:
                result = 0;
        }
        return result;
    }

    @SafeVarargs
    public final void loops(int... numbers) throws IOException {
        outer:
        for (int i = 0, j = 10; i < j; i++, j--) {
            for (int n : numbers) {
                if (n == i) continue outer;
                if (n < 0) break outer;
            }
        }
        int k = 0;
        while (k < 3) { k++; }
        do { k--; } while (k > 0);
        var map = new HashMap<String, List<Integer>>();
        map.computeIfAbsent("a", key -> new ArrayList<>()).add(1);
    }

    // ── Expressions and operators ──
    int operators(int a, int b) {
        int c = a + b - a * b / (b == 0 ? 1 : b) % 7;
        c += 1; c -= 1; c *= 2; c /= 2; c %= 5;
        c <<= 2; c >>= 1; c >>>= 1; c &= 0xFF; c |= 0x10; c ^= 0x01;
        boolean flag = (a < b) && (b <= 10) || !(a != b) ^ (a >= b) | (a > b) & true;
        int bits = ~a & (b << 2) | (a >> 1) ^ (b >>> 1);
        c = flag ? c++ : --c;
        long casted = (long) a * (int) 3.9;
        Function<Integer, Integer> doubler = x -> x * 2;
        BiFunction<Integer, Integer, Integer> adder = (x, y) -> x + y;
        Runnable r = () -> System.out.println("run");
        Function<String, Warehouse> factory = Warehouse::new;
        r.run();
        return doubler.apply(adder.apply(bits, (int) casted));
    }

    // ── Exceptions and resources ──
    String readAll(java.io.Reader reader) throws IOException {
        try (var in = new java.io.BufferedReader(reader)) {
            return in.readLine();
        } catch (IOException | RuntimeException e) {
            throw new IOException("failed", e);
        } finally {
            System.out.println("closed");
        }
    }

    synchronized void sync() {
        synchronized (this) {
            assert version > 0 : "version must be positive";
        }
    }

    // ── Streams and async ──
    Map<String, Integer> totals() {
        return items.stream()
            .filter(i -> i.quantity() > 0)
            .collect(Collectors.groupingBy(Item::sku, Collectors.summingInt(Item::quantity)));
    }

    CompletableFuture<Optional<Item>> fetchAsync(String sku) {
        return CompletableFuture.supplyAsync(() ->
            items.stream().filter(i -> i.sku().equals(sku)).findFirst());
    }

    // ── Inner and anonymous classes ──
    abstract static class Shape {
        abstract double area();
    }

    Shape square(double side) {
        return new Shape() {
            @Override
            double area() { return side * side; }
        };
    }

    @Override
    public int compareTo(Warehouse other) { return name.compareTo(other.name); }

    @Override
    public boolean equals(Object obj) { return obj instanceof Warehouse w && w.name.equals(name); }

    @Override
    public int hashCode() { return name.hashCode(); }

    @Deprecated(since = "2.0", forRemoval = true)
    native void nativeCall();

    // TODO: support multiple sites
    // FIXME: negative stock is silently clamped


    // ── Rare constructs ──
    @FunctionalInterface
    interface Visitor<R> {
        R visit(Item item) throws Exception;
        private static void helper() {}
    }

    sealed static abstract class Base permits Leaf, Mid {}
    non-sealed static class Mid extends Base {}
    static final class Leaf extends Base {}
    strictfp static double precise(double x) { return x * 2; }

    <T extends Number & Comparable<T>> T biggest(T a, T b) { return a.compareTo(b) > 0 ? a : b; }

    int yielding(Status s) {
        return switch (s) {
            case IN_STOCK, LOW -> {
                int base = 1;
                yield base + 1;
            }
            case OUT -> 0;
        };
    }

    void misc(Object o, int[] arr) {
        if (!(o instanceof final String str)) return;
        if (o instanceof Item(String sku, var qty, BigDecimal price)) System.out.println(sku + qty + price);
        Class<?> c1 = int.class, c2 = String[].class, c3 = void.class;
        int[][] jagged = new int[][] {{1}, {2, 3}};
        char ch = '\\', q = '\'', u = '\u0041';
        long mask = 0xFFFF_FFFFL | 1L << 40;
        float f = 1e3f, g = .5F, h = 0x1p-2f;
        double dd = 1d, de = 2D, df = 1_0.0_1;
        int x = 0, y = 1;
        x = y = 5;
        x = (x > 0) ? (y > 0 ? 1 : 2) : 3;
        boolean b = o instanceof Integer i2 ? false : true;
        Function<String, Integer> parse = Integer::parseInt;
        java.util.function.Supplier<int[]> mk = int[]::new;
        java.util.function.BiFunction<Integer, Integer, Integer> bf = (var a, var b2) -> a + b2;
        label: { if (x > 0) break label; }
        for (;;) { break; }
        for (var e : arr) { System.out.println(e); }
        this.version = super.hashCode();
        Object lock = new Object();
        var anon = new Object() { int field = 1; };
        assert x > 0;
        try { throw new Exception("x"); } catch (final Exception | Error err) { } 
        System.exit(0);
    }

    Warehouse() { this("default"); }
    @Override protected void finalize() throws Throwable { super.finalize(); }

    // ── Java 25 additions ──
    // Not shown (cannot coexist in this file): compact source files with an instance `void main()`
    // (JEP 512) replace the whole class; string templates were removed in 23; primitive patterns are preview.

    // ── Sized integer types and array access ──
    byte byteValue = 0x7F;
    short shortValue = (short) 300;
    int firstBin() { return bins[0] + grid[1][2]; }

    // ── Type-use annotations ──
    @java.lang.annotation.Target(java.lang.annotation.ElementType.TYPE_USE)
    @interface Nullable {}

    @Nullable String maybe;
    List<@Nullable String> labels = new ArrayList<>();
    String @Nullable [] nullableArray;

    // ── Interface constants and extending interfaces ──
    interface Limits {
        int LIMIT = 10;
        String UNIT = "kg";
    }
    interface Special extends Priced, Serializable, Limits {}

    // ── Receiver parameter ──
    void withReceiver(Warehouse this, int x) { }

    // ── Unnamed variables and patterns (final in 22) ──
    int unnamed(Event event, int[] arr, Object o) {
        int count = 0;
        for (var _ : arr) count++;
        try { Integer.parseInt("x"); } catch (NumberFormatException _) { count--; }
        java.util.function.BiFunction<Integer, Integer, Integer> first = (a, _) -> a;
        if (o instanceof Item(_, var qty, _)) count += qty;
        return switch (event) {
            case Received(_, int n) -> count + n;
            case Shipped(var _, _, _) -> count;
        };
    }

    // ── Pattern switch: null, guards, nested record patterns ──
    record Pair<A, B>(A first, B second) {}

    String patterns(Object o) {
        return switch (o) {
            case null -> "null";
            case Integer i when i > 5 -> "big " + i;
            case Integer i -> "int " + i;
            case String s -> s;
            case Pair(Pair(var a, var b), String c) -> a + "" + b + c;
            case Pair<?, ?>(var a, var b) -> a + "/" + b;
            case Status st when st == Status.OUT -> "out";
            case int[] ia -> "ints " + ia.length;
            default -> "other";
        };
    }

    String nullDefault(String s) {
        switch (s) {
            case null, default -> { return "none"; }
            case "a" -> { return "A"; }
        }
    }

    // ── Local declarations ──
    void locals() {
        record Point(int x, int y) {}
        enum Mode { ON, OFF }
        interface Greeter { String greet(); }
        class Local { int n; }
        var p = new Point(1, 2);
        var g = (Greeter) () -> "hi" + p + Mode.ON;
        Object[] objs = new Object[] { new Local(), g };
        System.out.println(objs.length);
    }

    // ── Inner class creation and qualified this ──
    class Inner {
        Warehouse outer() { return Warehouse.this; }
        <U> U pick(U u) { return u; }
    }

    void innerUse() {
        Warehouse.Inner in = this.new Inner();
        String s = in.<String>pick("x");
        Object o = Collections.<String>emptyList();
    }

    // ── Flexible constructor bodies (final in 25) ──
    Warehouse(String name, int version) {
        if (version < 0) throw new IllegalArgumentException("version");
        var normalised = name.strip();
        this(normalised);
        this.version = version;
    }

    public static void main(String[] args) throws Exception {
        Warehouse w = new Warehouse("Main");
        w.items.add(new Item("A-100", 5, new BigDecimal("2.50")));
        System.out.printf("%s holds %d units on %s%n", w.name, w.totalQuantity(), LocalDate.of(2026, 1, 31));
        System.out.println(TEXT_BLOCK + max(1, 2) + w.legacySwitch(Status.LOW));
    }
}

// ── Module declaration (module-info.java form; lives in its own file in real projects) ──
@Deprecated
open module com.example.warehouse {
    requires transitive java.logging;
    requires static java.sql;
    requires java.base;
    exports com.example.warehouse;
    exports com.example.warehouse.api to java.sql, java.logging;
    opens com.example.warehouse.model;
    opens com.example.warehouse.internal to java.base;
    uses java.sql.Driver;
    provides java.sql.Driver with com.example.warehouse.DriverImpl;
}
