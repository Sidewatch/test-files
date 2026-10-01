// ── Comments ──
// Scala 3 showcase: a warehouse inventory library.
// TODO: persist the stock. FIXME: partial match in `describe`.
/* A block comment
   /* with a nested block comment */
   spanning lines. */

/** Scaladoc comment for the package object.
  *
  * @param name the name
  * @tparam T the type parameter
  * @return something
  * @throws IllegalArgumentException if invalid
  * @see [[com.example.inventory.Item]]
  * @example {{{ val item = Item("widget", 9.99) }}}
  * @note Uses `inline code` and <b>html</b>.
  * @since 1.4
  * @deprecated use something else
  * @author nobody
  */

// ── Package, imports ──
package com.example.inventory

import scala.collection.mutable
import scala.collection.mutable.{ArrayBuffer, ListBuffer as LB}
import scala.util.{Try, Success, Failure, Using}
import scala.concurrent.{Future, ExecutionContext, Await}
import scala.concurrent.duration.*
import scala.language.implicitConversions
import java.time.{Instant, LocalDate}
import java.util.{List as JList, *}
import scala.annotation.{tailrec, targetName, unused}
import scala.compiletime.{constValue, erasedValue, summonInline}
import scala.quoted.*
import scala.deriving.Mirror

export mutable.Map as MutMap

// ── Literals ──
object Literals:
  val integer = 42
  val negative = -7
  val long = 42L
  val hex = 0xFF
  val hexLong = 0xFFL
  val binary = 0b1010
  val underscored = 1_000_000
  val float = 3.14f
  val double = 3.14
  val doubleSuffix = 3.14d
  val exponent = 1.5e-3
  val exponent2 = 6.022E23
  val noLeadingDigit = .5
  val boolTrue = true
  val boolFalse = false
  val nothing = null
  val unit = ()
  val char = 'x'
  val escapedChar = '\n'
  val unicodeChar = 'A'
  val octalChar = '\101'
  val quoteChar = '\''
  val string = "A string with \"quotes\", a \\ backslash, \t tab, é unicode."
  val multiline = """Triple-quoted
    |string with "quotes" and \n unescaped
    |  margin stripped.""".stripMargin
  val symbolLike = Symbol("sku")
  val interpolated = s"item $integer and ${integer + 1} and ${string.length}"
  val formatted = f"$double%.2f and ${integer}%05d and $hex%x and %%"
  val raw = raw"no \n escapes: $integer"
  val multilineS = s"""first $integer
    second ${long}"""
  val nestedInterp = s"outer ${s"inner ${integer}"}"
  val dollar = s"cost: $$5"
  val tuple = (1, "two", 3.0)
  val tupleAccess = tuple._1 + tuple(0)
  val list = List(1, 2, 3)
  val range = 1 to 10
  val rangeUntil = 1 until 10
  val rangeBy = (1 to 10 by 2).reverse

// ── Types: classes, traits, objects ──
/** An item held in stock. */
case class Item(name: String, price: Double, quantity: Int = 1)

sealed trait StockEvent
case class Added(item: Item) extends StockEvent
case class Removed(name: String) extends StockEvent
case object Cleared extends StockEvent

enum Status:
  case Pending, Paid, Cancelled

enum Level(val weight: Int):
  case Low extends Level(1)
  case High extends Level(10)
  def heavy: Boolean = weight > 5

enum Tree[+T]:
  case Leaf
  case Node(left: Tree[T], value: T, right: Tree[T])

enum Color derives CanEqual:
  case Red, Green, Blue

abstract class Shape(val name: String):
  def area: Double
  override def toString: String = s"$name($area)"

final class Circle(radius: Double) extends Shape("circle"):
  def area: Double = math.Pi * radius * radius

open class Base private (val id: Int) extends Serializable:
  def this() = this(0)
  protected def hook(): Unit = ()
  private[inventory] val internal = 1
  private[this] var counter = 0
  protected[inventory] def scoped(): Unit = ()

class Derived extends Base with Ordered[Derived]:
  override protected def hook(): Unit = super.hook()
  def compare(that: Derived): Int = 0
  lazy val expensive: Int = { Thread.sleep(1); 42 }
  @volatile var flag = false
  @transient val skipped = 1

trait Describable:
  self: Product =>
  def describe: String
  def shout: String = describe.toUpperCase

trait Logging { self =>
  def log(msg: String): Unit = println(s"[${getClass.getSimpleName}] $msg")
}

object Inventory extends Logging:
  val MaxItems: Int = 100
  private val items = mutable.Map.empty[String, Item]
  var version = "1.4.0"
  type Price = Double
  type Pair[A, B] = (A, B)
  opaque type Sku = String
  object Sku:
    def apply(s: String): Sku = s
    extension (s: Sku) def value: String = s

  def add(item: Item): Either[String, Item] =
    if items.size >= MaxItems then Left(s"inventory full (${items.size})")
    else
      items(item.name) = item
      Right(item)

  def total: Double = items.values.map(i => i.price * i.quantity).sum

  def describe(event: StockEvent): String = event match
    case Added(Item(name, price, qty)) => f"added $name%s x$qty ($$${price}%.2f)"
    case Removed(name)                 => s"removed $name"
    case Cleared                       => "cleared"

// ── Methods ──
def square(x: Int): Int = x * x
def defaults(a: Int, b: Int = 2, c: String = "x"): String = s"$a$b$c"
def varargs(xs: Int*): Int = xs.sum
def curried(a: Int)(b: Int)(using ctx: Ordering[Int]): Int = ctx.max(a, b)
def byName(x: => Int): Int = x + x
def polymorphic[A, B >: A <: AnyRef](a: A)(using Ordering[A]): List[A] = List(a)
def contextBound[T: Ordering](a: T, b: T): T = if summon[Ordering[T]].lt(a, b) then b else a
def viewBound[A](a: A)(implicit ev: A <:< AnyRef): A = a
def multiline(
    first: Int,
    second: String
): String =
  first.toString + second

inline def inlineFn(inline x: Int): Int = x + 1
transparent inline def trans(x: Int): Any = x
@tailrec def factorial(n: Int, acc: BigInt = 1): BigInt =
  if n <= 1 then acc else factorial(n - 1, acc * n)

@main def run(): Unit =
  for n <- 1 to 3 do Inventory.add(Item(s"widget-$n", n * 9.99, n))
  println(s"total = ${Inventory.total}")   // string interpolation + method call

// ── Operators and expressions ──
object Operators:
  val arithmetic = 1 + 2 - 3 * 4 / 5 % 6
  val bitwise = (5 & 3) | (5 ^ 3) << 1 >> 1 >>> 1
  val unary = -1 + +2 + ~3 + (!true).hashCode
  val comparison = 1 < 2 && 2 > 1 || 1 <= 2 && 2 >= 1
  val equality = 1 == 1 && 1 != 2 && ("a" eq "a") && ("a" ne "b")
  val concatenation = "a" + "b" ++ "c" :: Nil
  val cons = 1 :: 2 :: Nil
  val prepend = 0 +: List(1) :+ 2
  val appendAll = List(1) ::: List(2)
  val infix = List(1, 2) zip List(3, 4)
  val customOp = 1 min 2 max 3
  val ifExpr = if 1 > 0 then "pos" else "neg"
  val oldIf = if (1 > 0) "pos" else "neg"
  val typeTest = "x".isInstanceOf[String]
  val typeCast = ("x": Any).asInstanceOf[String]
  val ascription: Any = ("x": String)
  val postfix = List(1).toString
  val assignOps =
    var x = 1
    x += 1; x -= 1; x *= 2; x /= 2; x %= 3; x <<= 1; x >>= 1; x &= 1; x |= 2; x ^= 1
    x
  val updated = Array(1, 2, 3).updated(0, 9)
  val update =
    val arr = Array(1, 2, 3)
    arr(0) = 5
    arr
  val lambda = (x: Int, y: Int) => x + y
  val placeholder = List(1, 2).map(_ + 1)
  val placeholder2 = List(1, 2).foldLeft(0)(_ + _)
  val partial: PartialFunction[Int, String] = { case 1 => "one"; case _ => "other" }
  val contextFn: Int ?=> Int = summon[Int]
  val polyFn = [T] => (x: T) => x
  val tupled = (1, 2) match { case (a, b) => a + b }
  val symbolOps = List(1, 2, 3) map (_ * 2) filter (_ > 2)
  val infixSpread = List(1, 2, 3).sum
  val strMult = "ab" * 3

// ── Pattern matching ──
object Patterns:
  def describe(x: Any): String = x match
    case 0                       => "zero"
    case 1 | 2 | 3               => "small"
    case i: Int if i > 100       => "big"
    case i: Int                  => s"int $i"
    case s: String               => s"string $s"
    case "literal"               => "literal"
    case 'c'                     => "char"
    case 3.14                    => "pi"
    case true                    => "true"
    case null                    => "null"
    case Nil                     => "nil"
    case List(a, b)              => s"two: $a $b"
    case List(a, rest*)          => s"head $a"
    case a :: b :: _             => "cons"
    case (a, b)                  => s"tuple $a $b"
    case Item(n, p, _)           => s"item $n"
    case i @ Item(_, _, q) if q > 1 => s"multi $i"
    case Some(Item(name, _, _))  => name
    case xs: Array[Int]          => "array"
    case _: Boolean              => "bool"
    case `MaxItems`              => "stable identifier"
    case Status.Paid             => "paid"
    case _                       => "other"

  val MaxItems = 100

  def forComprehension =
    for
      a <- List(1, 2, 3)
      b <- List("x", "y")
      if a > 1
      c = a * 2
    yield (a, b, c)

  def oldFor = for { x <- 1 to 3; y <- 1 to 3 if x != y } yield x * y

  val Some(extracted) = Some(5)
  val (left, right) = (1, 2)
  val List(first, _*) = List(1, 2, 3)

// ── Given, using, extension, type classes ──
trait Show[A]:
  def show(a: A): String

given Show[Int] with
  def show(a: Int): String = a.toString

given Show[String] = (s: String) => s"'$s'"

given intOrdering: Ordering[Item] = Ordering.by(_.price)

given [A](using s: Show[A]): Show[List[A]] with
  def show(as: List[A]): String = as.map(s.show).mkString("[", ", ", "]")

extension (s: String)
  def shout: String = s.toUpperCase + "!"
  infix def ++?(other: String): String = s + other

extension [T](xs: List[T])
  def second: Option[T] = xs.drop(1).headOption

extension (i: Item) {
  def total: Double = i.price * i.quantity
}

implicit class RichInt(val n: Int) extends AnyVal:
  def double: Int = n * 2

implicit val ordering: Ordering[Int] = Ordering.Int
implicit def intToString(i: Int): String = i.toString
implicit object Default

given Conversion[Int, String] = _.toString

// ── Generics and variance ──
trait Container[+A]:
  def get: A
trait Sink[-A]:
  def put(a: A): Unit
class Box[T <: Comparable[T]](val value: T)
class Wrapper[F[_], A](fa: F[A])
type Lambda = [X] =>> Either[String, X]
type Union = Int | String
type Intersection = Serializable & Comparable[?]
type Match[X] = X match
  case String => Int
  case Int => String
type Tup = (Int, String)
type Fun = (Int, String) => Boolean
type CtxFun = Int ?=> String
type Existential = List[?]
type Refined = { def name: String }
type Nothingness = Nothing
type Anything = Any
val ev = summon[Int =:= Int]

// ── Exceptions, Option, Try, Future ──
object Effects:
  def risky(n: Int): Int =
    if n < 0 then throw new IllegalArgumentException("negative")
    n

  def handle(n: Int): Int =
    try risky(n)
    catch
      case e: IllegalArgumentException => -1
      case _: Exception => -2
    finally println("done")

  def oldTry = try { 1 } catch { case e: Exception => 2 } finally { println("x") }

  val attempt = Try(risky(1)) match
    case Success(v) => v
    case Failure(e) => 0

  val opt: Option[Int] = Some(1)
  val chained = opt.map(_ + 1).flatMap(x => Some(x)).getOrElse(0)
  val either: Either[String, Int] = Right(1)
  def future(using ExecutionContext) = Future { 42 }.map(_ + 1)
  val awaited = Await.result(Future.successful(1), 1.second)

  def using =
    Using(new java.io.StringReader("x")) { r => r.read() }

  def jumps =
    import scala.util.control.Breaks.*
    breakable { for i <- 1 to 5 do if i == 3 then break() }

  def whileLoops =
    var i = 0
    while i < 3 do i += 1
    while (i > 0) { i -= 1 }
    do { i += 1 } while (i < 3)
    return_(i)

  def return_(i: Int): Int = return i

// ── Annotations and modifiers ──
@deprecated("use something else", "1.4")
@SerialVersionUID(1L)
final case class Legacy(@transient id: Int)

@unused private val hidden = 1
@targetName("plusPlus") def ++(a: Int): Int = a
@inline final def fast = 1
@throws[Exception] def mayThrow(): Unit = ()
@main def entry(args: String*): Unit = ()
private object Secret
final val Const = 1
lazy val lz = 2
sealed abstract class Abs
infix class Pair2[A, B]

// ── Macros and metaprogramming ──
inline def debug(inline x: Any): Unit = ${ debugImpl('x) }
def debugImpl(x: Expr[Any])(using Quotes): Expr[Unit] =
  import quotes.reflect.*
  '{ println(${ Expr(x.show) }) }

object Derives:
  case class Point(x: Int, y: Int) derives CanEqual
  trait Eq[T] derives CanEqual
  inline def size[T]: Int = ${ sizeImpl[T] }
  def sizeImpl[T: Type](using Quotes): Expr[Int] = Expr(1)

// ── Scala 2 compatible forms still accepted by Scala 3 ──
object Scala2:
  val wildcard = List(1).map { case x => x }
  import scala.collection.mutable.{Map => MMap, _}
  val withUnderscoreImport = MMap.empty[String, Int]
  def wildcardType(xs: List[_]) = xs.size
  val eta = square _
  trait Marker extends scala.annotation.StaticAnnotation
  class Outer { class Inner; def m(i: this.Inner) = i }
  val hash = 1.##
