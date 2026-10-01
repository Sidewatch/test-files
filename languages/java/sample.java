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

    public static void main(String[] args) throws Exception {
        Warehouse w = new Warehouse("Main");
        w.items.add(new Item("A-100", 5, new BigDecimal("2.50")));
        System.out.printf("%s holds %d units on %s%n", w.name, w.totalQuantity(), LocalDate.of(2026, 1, 31));
        System.out.println(TEXT_BLOCK + max(1, 2) + w.legacySwitch(Status.LOW));
    }
}
