// Kotlin 2.2 — syntax showcase (kotlinc is not installed here; written against the 2.2 language reference)
@file:JvmName("WarehouseKt")
@file:Suppress("unused", "UNUSED_PARAMETER")

// ── Comments ──
// Line comment
/* Block comment /* nested block comment */ still inside */
/**
 * KDoc for the package.
 *
 * Uses [Warehouse] links and `code`.
 * @param sku the stock keeping unit
 * @property quantity units on hand
 * @return the total
 * @throws IllegalStateException when empty
 * @see Item
 * @sample com.example.warehouse.sample
 */
// TODO: support multiple sites
// FIXME: negative stock is clamped silently

// ── Package and imports ──
package com.example.warehouse

import kotlin.math.max
import kotlin.math.abs as absolute
import kotlin.collections.List as Sequence
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import java.util.concurrent.atomic.AtomicInteger

// ── Constants and numbers ──
const val MAX_BINS = 1_000
const val HEX = 0xFF_EC
const val BINARY = 0b1010_0101
const val LONG = 9_000_000_000L
const val UNSIGNED = 42u
const val ULONG = 42uL
const val FLOAT = 3.14f
const val DOUBLE = 3.14159
const val EXPONENT = 6.022e23
const val SMALL = 1E-9
const val NOT_NUMBER = Double.NaN
const val INFINITE = Double.POSITIVE_INFINITY
val CHAR = 'A'
val ESC_CHAR = '\n'
val UNI_CHAR = 'é'
val TAB_CHAR = '\t'
val BOOLS = listOf(true, false)
val NOTHING: String? = null

// ── Strings ──
val name = "Widget"
val qty = 3
val plain = "Pallet \"A-100\"\ttab \\ backslash \$dollar é"
val simple = "Item $name x$qty"
val expr = "Total ${qty * 2} ${name.uppercase()} ${if (qty > 2) "bulk" else "single"}"
val rawString = """
    Raw "string" with $name and ${qty + 1}
      keeps \n escapes literal
    """.trimIndent()
val margin = """
    |Report for $name
    |  quantity: $qty
    """.trimMargin()
val unicode = "Zürich → 東京 ✓ 📦"
val dollar = "price: ${'$'}5"

// ── Annotations ──
@Target(AnnotationTarget.CLASS, AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.RUNTIME)
@MustBeDocumented
annotation class Audited(val level: Int = 1, val tags: Array<String> = [])

// ── Enum, sealed, data, value classes ──
enum class Status(val code: String) {
    IN_STOCK("in"), LOW("low") {
        override fun alarming() = true
    },
    OUT("out");

    open fun alarming(): Boolean = false
}

sealed class Event {
    data class Received(val sku: String, val count: Int) : Event()
    data class Shipped(val sku: String, val count: Int, val carrier: String? = null) : Event()
    object Reset : Event()
}

sealed interface Result<out T> {
    data class Ok<T>(val value: T) : Result<T>
    data class Err(val message: String) : Result<Nothing>
}

@JvmInline
value class Sku(val value: String)

data class Item(val sku: Sku, var quantity: Int = 0, val price: Double = 0.0)

// ── Interfaces, abstract and open classes ──
interface Priced {
    val price: Double
    fun withTax(rate: Double = 0.2): Double = price * (1 + rate)
}

abstract class Shape {
    abstract fun area(): Double
    open val sides: Int get() = 0
}

open class Container<T : Comparable<T>>(protected val items: MutableList<T> = mutableListOf()) {
    operator fun plusAssign(item: T) { items += item }
    operator fun get(index: Int): T = items[index]
    operator fun contains(item: T): Boolean = item in items
    operator fun invoke(): Int = items.size
    operator fun iterator(): Iterator<T> = items.iterator()
    infix fun has(item: T): Boolean = item in this
}

// ── Class with everything ──
@Audited(level = 2, tags = ["stock", "core"])
class Warehouse private constructor(
    val name: String,
    private val bins: MutableMap<String, Int> = mutableMapOf(),
) : Priced, Comparable<Warehouse> {

    companion object Factory {
        const val DEFAULT = "Main"
        @JvmStatic fun create(name: String = DEFAULT) = Warehouse(name)
    }

    init {
        require(name.isNotBlank()) { "name must not be blank" }
    }

    constructor() : this(DEFAULT)

    override val price: Double by lazy { bins.values.sum() * 2.5 }
    var capacity: Int = 100
        get() = field
        set(value) { field = max(0, value) }
    lateinit var owner: String
    val total: Int get() = bins.values.sum()
    private val counter = AtomicInteger(0)

    inner class Bin(val code: String) {
        fun parent() = this@Warehouse
    }

    override fun compareTo(other: Warehouse): Int = name.compareTo(other.name)
    override fun toString(): String = "Warehouse($name, $total)"

    // ── Extension and generic functions ──
    fun <T> List<T>.second(): T? = if (size > 1) this[1] else null
}

fun String.shout(): String = uppercase() + "!"
val Int.squared: Int get() = this * this
inline fun <reified T> typeName(): String = T::class.simpleName ?: "unknown"
fun <T, R : Comparable<R>> Iterable<T>.maxOfBy(selector: (T) -> R): T? = maxByOrNull(selector)
infix fun Int.times(f: () -> Unit) { repeat(this) { f() } }
tailrec fun gcd(a: Int, b: Int): Int = if (b == 0) a else gcd(b, a % b)
fun varargs(vararg names: String, separator: String = ", ") = names.joinToString(separator)
fun <T : Any> require_(value: T?, lazyMessage: () -> String): T = value ?: throw IllegalStateException(lazyMessage())

// ── Control flow and expressions ──
fun describe(event: Event): String = when (event) {
    is Event.Received -> if (event.count > 100) "bulk receipt" else "receipt of ${event.sku}"
    is Event.Shipped -> "shipped ${event.count} via ${event.carrier ?: "unknown"}"
    Event.Reset -> "reset"
}

fun classify(x: Any?): String = when {
    x == null -> "null"
    x is Int && x > 10 -> "big int"
    x is String, x is Char -> "text"
    x in 1..5 -> "small"
    x !in listOf(1, 2) -> "other"
    else -> "unknown"
}

fun operators(a: Int, b: Int?): Int {
    var c = a + 1 - 2 * 3 / 4 % 5
    c += 1; c -= 1; c *= 2; c /= 2; c %= 3
    val bits = (a shl 2) or (a shr 1) and 0xFF xor 0x0F
    val ushifted = a ushr 1
    val inverted = a.inv()
    val safe = b?.let { it + 1 } ?: 0
    val forced = b!!
    val elvis = b ?: return -1
    val range = 1..10 step 2
    val down = 10 downTo 1
    val until = 0 until 10
    val cast = a as Number
    val safeCast = a as? String
    val check = a is Int && a !is String
    val ref = ::gcd
    val boundRef = "x"::length
    val compare = a == 1 || a != 2 && a < 3 || a <= 4 && a > 5 || a >= 6
    val identity = a === 1 || a !== 2
    val negated = !(a > 1)
    val pair = a to b
    val (first, second) = pair
    val spread = varargs(*arrayOf("a", "b"))
    val inc = c++ + ++c - c-- - --c
    return safe + (if (compare) 1 else 0) + first
}

fun loops() {
    outer@ for (i in 1..3) {
        for (j in 1..3) {
            if (j == 2) continue@outer
            if (i == 3) break@outer
        }
    }
    var n = 0
    while (n < 3) n++
    do { n-- } while (n > 0)
    for ((index, value) in listOf("a", "b").withIndex()) println("$index=$value")
    listOf(1, 2, 3).forEach { println(it) }
    listOf(1, 2, 3).map { x -> x * 2 }.filter { it > 2 }.fold(0) { acc, v -> acc + v }
    val lambda: (Int, Int) -> Int = { a, b -> a + b }
    val noParam: () -> Unit = { }
    val receiver: String.() -> Int = { length }
    val anon = fun(x: Int): Int = x * 2
    repeat(3) { println(it) }
}

// ── Exceptions and scope functions ──
fun risky(path: String): String =
    try {
        check(path.isNotEmpty()) { "empty" }
        error("boom")
    } catch (e: IllegalStateException) {
        e.message ?: "none"
    } catch (e: Exception) {
        throw RuntimeException("wrapped", e)
    } finally {
        println("done")
    }

fun scopes(): Warehouse = Warehouse.create().apply { capacity = 5 }.also { println(it) }.let { it }.run { this }

// ── Delegation and destructuring ──
class Delegated(base: Priced) : Priced by base
val lazyValue: String by lazy { "computed" }
var observed: Int by kotlin.properties.Delegates.observable(0) { _, old, new -> println("$old -> $new") }

// ── Coroutines ──
suspend fun fetchStock(sku: String): Int {
    delay(100)
    return withContext(Dispatchers.IO) { sku.length }
}

fun stream(): Flow<Int> = flow {
    for (i in 1..3) { emit(i); delay(10) }
}

fun main() = runBlocking {
    val deferred = async { fetchStock("A-100") }
    launch { println("launched") }
    println(deferred.await())
    stream().collect { println(it) }
    val w = Warehouse.create("North")
    println(w.toString().shout() + describe(Event.Received("A-1", 5)) + typeName<String>())
    5 times { print(".") }
    // typealias and objects
    println(Registry.names)
}

typealias StockMap = Map<String, List<Pair<String, Int>>>

object Registry {
    val names = mutableListOf<String>()
    const val VERSION = "1.0"
}

// ── Rare constructs ──


expect class PlatformStock { fun count(): Int }
actual class PlatformStockImpl { actual fun count(): Int = 0 }
expect fun platformName(): String
expect val platformId: String

fun interface Visitor<in T> { fun visit(item: T): Unit }
data object Singleton
data class Pair3<out A, out B, out C>(val a: A, val b: B, val c: C)
enum class Level {
    LOW, MID, HIGH;

    companion object {
        val default = MID
    }
}
enum class Op(val symbol: String) : java.util.function.IntBinaryOperator {
    PLUS("+") { override fun applyAsInt(a: Int, b: Int) = a + b },
    TIMES("*") { override fun applyAsInt(a: Int, b: Int) = a * b };
}
sealed class Tree<out T> { object Leaf : Tree<Nothing>(); data class Node<T>(val l: Tree<T>, val v: T, val r: Tree<T>) : Tree<T>() }
abstract class Base<T> where T : Comparable<T>, T : java.io.Serializable { abstract fun f(): T }
open class Outer {
    inner class In {
        fun o() = this@Outer
    }

    class Nested
    protected open val p = 1
    internal fun i() {}
    final override fun toString() = "O"
}
class Ctors(val a: Int) {
    var b = 0
    constructor(a: Int, b: Int) : this(a) { this.b = b }
    constructor() : this(0, 0)
    init { b = a }
    private constructor(s: String) : this(s.length)
}
class Props {
    @get:JvmName("fetch") @set:JvmName("store") var x = 0
    @field:Transient val y = 1
    @delegate:Transient val z by lazy { 2 }
    @property:Deprecated("no") val w = 3
    lateinit var late: String
    val computed: Int get() = 5
    var guarded: Int = 0
        private set
        get() = field + 1
    protected var prot = 0
    internal val int = 0
    public val pub = 0
    private val priv = 0
    companion object {
        @JvmField val F = 1
        @JvmStatic fun s() {}
        const val C = 2
    }
}
object Obj : Runnable, Comparable<Obj> { override fun run() {}; override fun compareTo(other: Obj) = 0 }

// variance, projections, constraints
interface Source<out T> { fun next(): T }
interface Sink<in T> { fun put(t: T) }
fun copy(from: Array<out Any>, to: Array<in Any>) {}
fun star(x: List<*>, y: Map<String, *>) {}
fun <T> T.constrained(): Int where T : CharSequence, T : Comparable<T> = length
inline fun <reified T : Any> kotlin.reflect.KClass<T>.simple() = simpleName
inline fun withLambdas(noinline a: () -> Unit, crossinline b: () -> Unit, c: () -> Unit) { c() }
fun higher(f: (Int, String) -> Boolean, g: Int.(String) -> Unit, h: suspend () -> Unit, i: (() -> Unit)?, j: Pair<Int, (Int) -> Int>) {}
context(String, Int) fun contextual() {}
suspend fun suspending() {}
external fun nativeFn(): Int
operator fun Int.unaryMinus2() = -this
operator fun Point2.plus(o: Point2) = this
operator fun Point2.unaryMinus() = this
operator fun Point2.inc() = this
operator fun Point2.not() = this
operator fun Point2.rangeTo(o: Point2) = this..o
operator fun Point2.rangeUntil(o: Point2) = this
operator fun Point2.compareTo(o: Point2) = 0
operator fun Point2.component1() = 0
operator fun Point2.get(i: Int, j: Int) = 0
operator fun Point2.set(i: Int, j: Int, v: Int) {}
operator fun Point2.timesAssign(o: Int) {}
operator fun Point2.invoke(): Int = 0
operator fun Point2.contains(o: Int) = true
operator fun Point2.getValue(t: Any?, p: kotlin.reflect.KProperty<*>) = 0
operator fun Point2.setValue(t: Any?, p: kotlin.reflect.KProperty<*>, v: Int) {}
operator fun Point2.provideDelegate(t: Any?, p: kotlin.reflect.KProperty<*>) = this
class Point2

// backtick identifiers
fun `my test with spaces`() {}
val `class` = 1
@Suppress("ObjectPropertyName") val `in` = 2

// annotations
@Target(AnnotationTarget.PROPERTY, AnnotationTarget.VALUE_PARAMETER) @Repeatable annotation class Tag(val v: String)
@Tag("a") @Tag("b") class Tagged
@JvmOverloads fun overloads(a: Int = 1, b: String = "") {}
@Deprecated("Use new", ReplaceWith("newFn()"), DeprecationLevel.WARNING) fun oldFn() {}
@OptIn(ExperimentalStdlibApi::class) fun opt() {}
@receiver:Tag("r") fun String.recv() {}
fun annotated(@Tag("p") p: Int, @param:Tag("q") q: Int) {}

// expressions
fun expressions(x: Any?, n: Int, s: String?, list: List<Int>) {
    val a = when (val y = n * 2) { 0 -> "zero"; in 1..9 -> "small"; !in 10..99 -> "big"; else -> "mid" }
    val b = when (x) { is String -> x.length; is Int, is Long -> 1; null -> 0; else -> -1 }
    val c = if (n > 0) "pos" else if (n < 0) "neg" else "zero"
    val d = try { n / 0 } catch (e: ArithmeticException) { 0 } finally { }
    val e = s?.length ?: 0
    val f = s!!.length
    val g = (x as? String)?.length
    val h = x is String && x.isNotEmpty() || x !is Int
    val i = 1..10; val j = 1 until 10; val k = 1..<10; val l = 10 downTo 1 step 2
    val m = list.map { it * 2 }.filter { it > 2 }.sumOf { it }
    val o = list.fold(0) { acc, v -> acc + v }
    val p = list.sortedWith(compareBy<Int> { it }.thenByDescending { it })
    val (q, _, r) = Triple(1, 2, 3)
    val (key, value) = mapOf(1 to 2).entries.first()
    val lambda = { a: Int, _: Int -> a }
    val ext: Int.(Int) -> Int = { this + it }
    val callable = ::expressions
    val klass = String::class; val jclass = String::class.java; val bound = s::length
    val obj = object : Runnable { override fun run() {} }
    val anon = object { val field = 1 }
    val arr = arrayOf(1, 2); val intArr = intArrayOf(1, 2); val nested = Array(3) { IntArray(3) }
    arr[0] = 5; nested[1][2] += 1
    val ch = 'a' + 1; val code = 'a'.code
    val bits = 0xFF and 0x0F or 0x10 xor 0x01 shl 2 shr 1 ushr 1
    var counter = 0; counter++; ++counter; counter--; --counter; counter += 1; counter -= 1; counter *= 2; counter /= 2; counter %= 3
    val big = 1L shl 40; val unsignedBig = 0xFFFFFFFFu; val ulong = 18446744073709551615UL
    val binary = 0b1010_1010; val hexLong = 0xFFL; val sci = 1e10; val sciF = 1.5e-3f; val dot = 1.0F
    val str = """tricky "quotes" ${"nested ${n}"} $n"""
    val dollars = "\$ literal \${not} A \n \t \r \b \\ \' \""
    val multiDollar = $$"""costs $$n and $${n + 1} but $n is literal"""
    val label = run outer@{ list.forEach { if (it > 1) return@outer }; 1 }
    loop@ for (idx in 1..3) { for (jdx in 1..3) { if (jdx == 2) continue@loop; if (idx == 3) break@loop } }
    val sup = object : Base<String>() { override fun f() = super<Base>.toString() }
    val nullable: String? = null; val nn: String = nullable ?: "default"
    val dyn: Any = 1; val nothing: Nothing? = null; val unit: Unit = Unit
    val safeIdx = list.getOrNull(5)
    throw IllegalStateException("never")
}
tailrec fun tail(n: Int, acc: Int = 0): Int = if (n == 0) acc else tail(n - 1, acc + n)
fun Int.isEven() = this % 2 == 0
val Int.isOdd get() = this % 2 != 0
infix fun Int.shiftBy(n: Int) = this shl n
typealias Handler<T> = (T) -> Unit
typealias Matrix = Array<DoubleArray>
var topLevelDelegate by kotlin.properties.Delegates.notNull<Int>()
const val CONST_EXPR = 1 + 2 * 3

// ── Kotlin 2.x additions ──
// when with guard conditions (stable in 2.2)
fun guarded(event: Event, limit: Int): String = when (event) {
    is Event.Received if event.count > limit -> "bulk"
    is Event.Received -> "receipt"
    is Event.Shipped if event.carrier != null && event.count > 0 -> "shipped via ${event.carrier}"
    else -> "other"
}

// definitely non-nullable types
fun <T> nonNull(value: T & Any): T & Any = value
fun <T> orFail(value: T?): T & Any = value ?: error("null")
val parenthesised: (String)? = null
val parenthesisedFunction: ((Int) -> Int)? = null

// unlabelled break and continue, destructuring in lambdas and loops
fun controlJumps(pairs: List<Pair<Int, String>>) {
    for (i in 1..10) {
        if (i % 2 == 0) continue
        if (i > 7) break
    }
    while (true) {
        break
    }
    pairs.forEach { (number, text) -> println("$number $text") }
    for ((number, text) in pairs) println("$number $text")
    val (head, tail) = pairs.first() to pairs.drop(1)
    println(head.first + tail.size)
}

// annotation use-site targets and super with labels
@Target(AnnotationTarget.VALUE_PARAMETER, AnnotationTarget.PROPERTY_SETTER)
annotation class Marker

class UseSites(@setparam:Marker var setting: Int = 0)

open class Parent {
    open fun hello() = "parent"
}

class Child : Parent() {
    inner class Helper {
        fun hello() = super@Child.hello() + this@Child.hello()
    }
    override fun hello() = "child"
}

// unicode escapes in characters and strings
val escapedUnicode = "\u00e9 \u4E2D"
val escapedChar = '\u0041'

// Kotlin/JS only: the dynamic type
// val untyped: dynamic = js("{}")

// multi-dollar string interpolation (stable in 2.2)
val templated = $$"""{"price": "$", "name": "$$name", "total": $${qty * 2}}"""
