<?hh // strict
// ── Comments ──
// Hack: a typed repository with async loading, shapes, generics and attributes.
# Hash-style comment. TODO: split into files. FIXME: rounding.
/* Block comment */
/**
 * Doc comment.
 * @param string $sku The stock keeping unit.
 * @return int The quantity.
 */

// ── Namespaces and use ──
namespace App\Inventory;

use namespace HH\Lib\{C, Dict, Str, Vec};
use type Facebook\HackTest\HackTest;
use function HH\Lib\Math\max;
use const App\Config\DEFAULT_LIMIT;

// ── Type aliases, shapes, tuples ──
type StockRow = shape('sku' => string, 'qty' => int, 'price' => float);
type Partial = shape(?'name' => string, ...);
newtype Opaque = int;
newtype Hidden as arraykey = string;
type Callback = (function(int, string): bool);
type Pair<Ta, Tb> = (Ta, Tb);
type Nullable = ?string;
type Mixed = mixed;
type Json = dict<string, vec<int>>;
type Tagged = (int, string, ?float);
type Lazy = (function(): Awaitable<int>);

// ── Enums and enum classes ──
enum Status: string as string {
  PENDING = 'pending';
  PAID = 'paid';
  SHIPPED = 'shipped';
}

enum Level: int {
  LOW = 1;
  HIGH = 10;
}

enum class Colors: mixed {
  string RED = 'red';
  int CODE = 7;
}

// ── Constants ──
const int MAX_ITEMS = 128;
const string GREETING = "hello";

// ── Attributes ──
<<__EntryPoint>>
function main(): void {
  echo "start\n";
}

<<__Memoize, __Deprecated('use total()')>>
function legacy(int $x): int {
  return $x;
}

// ── Interfaces, traits, abstract and final classes ──
interface Shape {
  const type TUnit = int;
  public function area(): float;
}

trait Loggable {
  require extends Base;
  require implements Shape;
  protected vec<string> $log = vec[];
  public function log(string $message): void {
    $this->log[] = $message;
  }
}

abstract class Base implements Shape {
  abstract const type T;
  public function __construct(protected string $name = 'base') {}
  abstract protected function describe(): string;
  public static function create(): this {
    return new static();
  }
}

final class Repository extends Base {
  use Loggable;

  const int REORDER_POINT = 25;
  const string TABLE = 'stock';
  public static int $instances = 0;
  private ?AsyncMysqlConnection $conn = null;
  private dict<string, int> $cache = dict[];
  public readonly int $id;

  public function __construct(private AsyncMysqlConnection $connection, public int $limit = 10, protected readonly string $label = "repo") {
    parent::__construct($label);
    $this->id = self::$instances++;
  }

  <<__Override>>
  protected function describe(): string {
    return Str\format('Repository(%s)', $this->label);
  }

  public function area(): float { return 0.0; }

  public async function lowStock(): Awaitable<vec<StockRow>> {
    $result = await $this->connection->queryf(
      'SELECT sku, qty, price FROM stock WHERE qty < %d',
      self::REORDER_POINT,
    );
    $rows = vec[];
    foreach ($result->mapRows() as $row) {
      $rows[] = shape('sku' => $row['sku'], 'qty' => (int)$row['qty'], 'price' => (float)$row['price']);
    }
    return $rows;
  }

  public static function totalValue(vec<StockRow> $rows): float {
    return \HH\Lib\C\reduce($rows, ($acc, $r) ==> $acc + $r['qty'] * $r['price'], 0.0);
  }

  public async function loadAll(vec<string> $skus): Awaitable<dict<string, int>> {
    $awaitables = Dict\from_keys($skus, async ($sku) ==> await $this->quantity($sku));
    return await Dict\from_async($awaitables);
  }

  private async function quantity(string $sku): Awaitable<int> {
    await \HH\Asio\usleep(1000);
    return 1;
  }

  public function __toString(): string { return $this->describe(); }
}

// ── Generics with constraints and variance ──
class Box<+T> {
  public function __construct(private T $value) {}
  public function get(): T { return $this->value; }
}

function first<T as arraykey, Tv>(KeyedContainer<T, Tv> $c): ?Tv where T = int {
  foreach ($c as $v) { return $v; }
  return null;
}

function reified<reify T>(mixed $x): bool {
  return $x is T;
}

// ── Literals ──
function literals(): void {
  $int = 42;
  $neg = -17;
  $hex = 0xFF;
  $bin = 0b1010;
  $oct = 0755;
  $sep = 1_000_000;
  $float = 3.14;
  $exp = 6.02e23;
  $bool = true;
  $other = FALSE;
  $nil = null;
  $single = 'single \'quoted\' no $interp \n';
  $double = "double \"quoted\" $int {$int} ${int} \n \t \\ \x41 \u{1F600} \101 $int[0] $obj->prop";
  $heredoc = <<<EOT
  Heredoc with $int and {$double}
    indented text
  EOT;
  $nowdoc = <<<'EOT'
  Nowdoc keeps $int literal
  EOT;
  $vec = vec[1, 2, 3];
  $dict = dict['a' => 1, 'b' => 2];
  $keyset = keyset['x', 'y'];
  $tuple = tuple(1, 'two', 3.0);
  $shape = shape('sku' => 'A-1', 'qty' => 2, 'price' => 9.5);
  $legacy = array(1, 2, 3);
  $short = vec[];
  $xhp = <div class="box">{$double}</div>;
  $lambda = $x ==> $x + 1;
  $lambda2 = (int $x): int ==> { return $x * 2; };
  $anon = function(int $x) use ($int): int { return $x + $int; };
  $coroutine = async () ==> await gen();
}

async function gen(): Awaitable<int> { return 1; }

// ── Operators ──
function operators(int $a, int $b, ?string $s): void {
  $r = $a + $b - $a * $b / $a % $b ** 2;
  $r += 1; $r -= 1; $r *= 2; $r /= 2; $r %= 3; $r **= 2;
  $r .= 'x';
  $r ??= 'default';
  $bits = ($a & $b) | ($a ^ $b) | ~$a | ($a << 2) | ($a >> 1);
  $bits &= 1; $bits |= 2; $bits ^= 3; $bits <<= 1; $bits >>= 1;
  $logic = ($a > $b && $b < $a) || !($a === $b) || ($a !== $b and $a <= $b) or ($a >= $b xor true);
  $cmp = $a <=> $b;
  $loose = $a == $b || $a != $b || $a <> $b;
  $tern = $a > $b ? 'big' : 'small';
  $short = $a ?: 'zero';
  $coalesce = $s ?? 'none';
  $safe = $s?->length();
  $pipe = vec[1, 2, 3] |> Vec\map($$, $x ==> $x * 2) |> C\count($$);
  $concat = 'a' . 'b' . "c";
  $inc = $a++ + ++$b - $a-- - --$b;
  $is = $s is string;
  $not = $s is nonnull;
  $as = $s as string;
  $nullas = $s ?as string;
  $inst = $s instanceof Stringish;
  $silent = @file_get_contents('x');
  $new = new Repository(new AsyncMysqlConnection());
  $static = Repository::REORDER_POINT;
  $classname = Repository::class;
  $nameof = nameof Repository;
  $cast = (string)$a . (int)'5' . (float)'1.5' . (bool)1 . (array)$a;
}

// ── Control flow ──
function control(mixed $x): string {
  if ($x is int && $x > 0) {
    return 'positive';
  } else if ($x is string) {
    return $x;
  } elseif ($x === null) {
    return 'null';
  } else {
    // fallthrough
  }

  switch ($x) {
    case 1:
    case 2:
      return 'small';
    case 'a':
      break;
    default:
      return 'other';
  }

  for ($i = 0; $i < 3; $i++) {
    if ($i === 1) { continue; }
    if ($i === 2) { break; }
  }
  foreach (vec[1, 2] as $k => $v) {}
  foreach (dict['a' => 1] as $key => $value) {}
  $n = 0;
  while ($n < 3) { $n++; }
  do { $n--; } while ($n > 0);
  concurrent {
    $a = await gen();
    $b = await gen();
  }

  try {
    throw new \Exception('boom', 42);
  } catch (\InvalidArgumentException $e) {
    return $e->getMessage();
  } catch (\Exception $e) {
    return 'generic';
  } finally {
    echo "cleanup";
  }

  using ($handle = new Handle()) {}
  using $other = new Handle();
  return 'end';
}

function gen_values(): Generator<int, string, void> {
  yield 1 => 'a';
  yield 2 => 'b';
  $got = yield;
}

class Handle implements IDisposable { public function __dispose(): void {} }

// ── Unit tests and top level ──
function using_asserts(): void {
  invariant($GLOBALS !== null, 'globals must exist');
  invariant_violation('unreachable');
  exit(0);
}

// ── XHP ──
xhp class warehouse:item extends x\element {
  attribute
    string sku @required,
    int qty = 0,
    enum {'new', 'used'} condition = 'new',
    ?string label;
  children (:li | :span | pcdata)*;
  category %flow;

  protected async function renderAsync(): Awaitable<x\node> {
    return <li class="item">{$this->:sku}: {$this->:qty}</li>;
  }
}

function render_list(vec<string> $skus): XHPChild {
  return <ul id="list" data-count={C\count($skus)}>
    <li>First &amp; <b>bold</b></li>
    {Vec\map($skus, $s ==> <warehouse:item sku={$s} />)}
    <!-- an XHP comment -->
    <x:frag>fragment</x:frag>
  </ul>;
}

// ── Attributes with arguments, sealed classes, contexts and capabilities ──
<<__Sealed(Child1::class, Child2::class)>>
abstract class Parent1 {}
final class Child1 extends Parent1 {}
final class Child2 extends Parent1 {}

<<__ConsistentConstruct, __Support_Dynamic_Type>>
class Constructible {
  public function __construct() {}
}

function with_contexts(
  (function(): void) $f,
)[defaults, write_props]: void {
  $f();
}

function pure_function(int $x)[]: int { return $x + 1; }
function reads_globals()[globals]: int { return 1; }
function rx_function()[zoned_with, leak_safe]: void {}

class ReadonlyExample {
  public function __construct(public readonly vec<int> $items) {}
  public function get(): readonly vec<int> { return readonly $this->items; }
}

function inout_example(inout int $x, inout vec<int> $xs): void {
  $x += 1;
  $xs[] = $x;
}

function variadics(int ...$nums): int { return C\count(vec($nums)); }
function splat(mixed ...$args): void {}

// ── Modules ──
new module foo {}
module foo;
internal class InModule {}
public function exported(): void {}
internal function not_exported(): void {}

// ── Class method and callable helpers ──
function callables(): void {
  $f = fun('App\Inventory\pure_function');
  $m = class_meth(Repository::class, 'totalValue');
  $i = inst_meth(new Handle(), '__dispose');
  $c = meth_caller(Repository::class, 'area');
  $g = pure_function<>;
  $s = Repository::totalValue<>;
  $r = (new Repository(new AsyncMysqlConnection()))->area<>;
  $lam = (int $x): int ==> $x * 2;
  $stat = static function(int $x): int { return $x; };
}

// ── Remaining PHP-style statements and magic constants ──
function legacy_statements(): void {
  echo __FILE__, __LINE__, __DIR__, __FUNCTION__, __CLASS__, __METHOD__, __NAMESPACE__, __TRAIT__, \PHP_EOL;
  print "print statement\n";
  $a = isset($x) && !empty($y);
  unset($z);
  list($p, $q) = tuple(1, 2);
  list(, $second) = tuple(1, 2);
  [$d, $e] = tuple(3, 4);
  $str = <<<"QUOTED"
  Heredoc with double-quoted tag $a
  QUOTED;
  $nested = "Nested: {$a->b['c']->d()} and $a[0] and $a->prop and {$a}";
  $arr = array('a' => 1, 'b' => array(2, 3));
  $v = vec[1, 2, 3]
  |> Vec\map($$, $x ==> $x * 2)
  |> Vec\filter($$, $x ==> $x > 2);
  declare(ticks=1);
  require_once 'file.php';
  include 'other.php';
  exit;
}

function generators(): Generator<int, int, void> {
  yield 1;
  yield from other_gen();
}
function other_gen(): Generator<int, int, void> { yield 2; }

async function async_gen(): AsyncGenerator<int, string, void> {
  yield 1;
  await \HH\Asio\usleep(1);
  yield 2 => 'two';
}

async function consume(): Awaitable<void> {
  foreach (async_gen() await as $k => $v) {}
  using ($h = new Handle()) {}
  await using ($h2 = new Handle()) {}
  concurrent {
    await gen();
    await gen();
  }
  $r = await gen() ?? 0;
  $x = \HH\Asio\join(gen());
}

/* HH_FIXME[4110] suppressed type error */
/* HH_IGNORE_ERROR[4110] legacy suppression */
function suppressed(): int { return 'string'; }
