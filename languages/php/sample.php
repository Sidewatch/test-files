#!/usr/bin/env php
<?php
// PHP 8.5 — syntax showcase
declare(encoding='UTF-8');
declare(strict_types=1);

/**
 * File-level docblock for the inventory showcase.
 *
 * @package AcmeVault
 * @author  Warehouse team
 * @param   string $name  The item name
 * @return  void
 * @throws  \InvalidArgumentException when the quantity is negative
 * @see     https://example.com/docs
 * @deprecated use render_pipeline() instead
 */

// A line comment
# A hash comment mentioning #123 and #facade — neither is a color
/* A block comment
   over several lines */
// TODO: stream large reports
// FIXME: rounding differs between currencies

namespace AcmeVault;

use AcmeVault\Crypto\Signer as CryptoSigner;
use function AcmeVault\Util\clamp;
use const AcmeVault\Limits\MAX_BODY;
use AcmeVault\Crypto\{Cipher, Digest as CryptoDigest};
use function AcmeVault\Util\{normalize, truncate};
use const AcmeVault\Limits\{MAX_BODY as BODY_LIMIT, soft_cap};
use Psr\Log\LoggerInterface;

// ── Constants ──
const MAX_RETRIES = 3;
const GREETING = "hello";
define('LEGACY_FLAG', true);

// ── Literals ──
$int_dec = 1_000_000;
$int_hex = 0xFF_EC;
$int_oct = 0755;
$int_oct2 = 0o755;
$int_bin = 0b1010_1010;
$float = 3.14;
$float_exp = 1.5e-3;
$float_us = 1_000.5;
$inf = INF;
$nan = NAN;
$max = PHP_INT_MAX;
$yes = true;
$no = FALSE;
$nothing = null;
$single = 'single \'quoted\' with $no interpolation and \n literal';
$double = "double \"quoted\" tab:\t newline:\n hex:\x41 oct:\101 unicode:\u{1F4E6} dollar:\$ brace:\{";
$name = 'widget';
$list = ['a' => 1, 'b' => [2, 3], 'obj' => (object)['k' => 'v']];
$obj = new \stdClass();
$obj->prop = 'value';
$interp = "simple $name, array $list[a], index {$list['b'][0]}, prop $obj->prop, expr {$obj->prop}s, call {${'name'}}";
$interp_dollar = "dollar-brace ${name}";
$heredoc = <<<EOT
Heredoc with $name and {$list['a']} and \$escaped
  Indented line, method {$obj->prop}
EOT;
$heredoc_quoted = <<<"EOT"
Quoted heredoc interpolates $name
EOT;
$nowdoc = <<<'EOT'
Nowdoc keeps $name and {$braces} and \n literal
EOT;
$flex = <<<SQL
    SELECT * FROM stock WHERE sku = '$name'
      AND qty > 0
    SQL;
$backtick = `echo shell`;
$printf = sprintf('%05.1f|%-8s|%+d|%x|%b|%e|%%|%2$s', 3.14159, 'ab', 7);

// ── Arrays and destructuring ──
$short = [1, 2, 3, 'four' => 4, ...[5, 6]];
$long = array(1, 2, array('nested' => true));
[$a, $b, [$c, $d]] = [1, 2, [3, 4]];
['x' => $x, 'y' => $y] = ['x' => 1, 'y' => 2];
list($p, , $q) = [1, 2, 3];
[$a, $b] = [$b, $a];
foreach ([[1, 2], [3, 4]] as [$m, $n]) { echo $m + $n; }
$merged = [...$short, ...$long];
$named = [...['a' => 1], ...['b' => 2]];

// ── Enums, interfaces, traits ──
enum Status: string implements HasLabel
{
    case Pending = 'pending';
    case Paid = 'paid';
    case Cancelled = 'cancelled';

    const DEFAULT = self::Pending;

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'Waiting',
            self::Paid => 'Paid',
            self::Cancelled => 'Cancelled',
        };
    }

    public static function fromLabel(string $l): self { return self::from(strtolower($l)); }
}

enum Suit { case Hearts; case Spades; }

interface HasLabel
{
    const VERSION = '1.0';
    public function label(): string;
}

interface Auditable extends HasLabel, \Countable, \JsonSerializable {}

trait Timestamps
{
    protected ?\DateTimeImmutable $createdAt = null;
    public static int $instances = 0;
    abstract public function id(): int;
    public function touch(): static { $this->createdAt = new \DateTimeImmutable('now'); return $this; }
}

trait Loggable
{
    private function log(string $msg): void { error_log($msg); }
    public function hello(): string { return 'loggable'; }
}

// ── Attributes ──
#[\Attribute(\Attribute::TARGET_CLASS | \Attribute::TARGET_METHOD)]
final class Route
{
    public function __construct(public string $path, public array $methods = ['GET']) {}
}

#[Route('/orders', methods: ['GET', 'POST'])]
#[\AllowDynamicProperties]
abstract class BaseRunner
{
    abstract protected function run(): void;
}

// ── Classes ──
function render_pipeline(string $name, int $count = 0): void
{
    $total = $count + MAX_RETRIES;
    $dir = __DIR__;
    audit_log($name, $total);
    echo "hello $name";
}

final class Money implements \Stringable
{
    public function __construct(
        public readonly int $amount,
        public readonly string $currency = 'GBP',
    ) {}

    public function __toString(): string { return sprintf('%d %s', $this->amount, $this->currency); }
    public function with(int $amount): static { return new static($amount, $this->currency); }
}

class Signer
{
    public string $key;
    public function sign(array $data): string
    {
        return hash_hmac('sha256', $this->key, 'salt');
    }
}

class Pipeline extends BaseRunner implements Auditable
{
    use Timestamps, Loggable { Loggable::hello as protected traitHello; }

    public const MAX = 10;
    protected const PROTECTED_CONST = 'p';
    private const PRIVATE_CONST = 'x';
    final public const FINAL_CONST = 1;

    private CryptoSigner $signer;
    private LoggerInterface $logger;
    public static ?self $current = null;
    public int|string $mixed = 0;
    protected iterable $items = [];
    private readonly array $frozen;

    public function __construct(private int $id = 0, protected ?string $label = null)
    {
        $this->frozen = [1, 2, 3];
        static::$instances++;
        self::$current = $this;
    }

    public function __destruct() {}
    public function __get(string $n): mixed { return $this->$n ?? null; }
    public function __set(string $n, mixed $v): void { $this->$n = $v; }
    public function __call(string $n, array $a): mixed { return null; }
    public static function __callStatic(string $n, array $a): mixed { return null; }
    public function __invoke(int $x): int { return $x * 2; }
    public function id(): int { return $this->id; }
    public function label(): string { return $this->label ?? 'none'; }
    public function count(): int { return count($this->items); }
    public function jsonSerialize(): mixed { return ['id' => $this->id]; }

    # a hash comment mentioning #123 and #facade — neither is a color
    public function run(): void
    {
        $out = new \AcmeVault\Crypto\Signer();
        $sig = $out->sign(['k' => 'v']);
        $max = \AcmeVault\Core\Limits::MAX_BATCH;
        $this->logger->info($sig);
        clamp(Config\Defaults::TIMEOUT, 0, 60);
        $anon = new class(5) extends \ArrayObject implements \Countable { public function __construct(public int $n) {} };
    }

    public function chain(?array $opts = null): static
    {
        $len = $opts?->length ?? $this?->label?->name ?? 0;
        return $this->touch()->touch();
    }
}

// ── Functions, closures, generators ──
function add(int $a, int $b = 10, int ...$rest): int { return $a + $b + array_sum($rest); }
function &ref_return(array &$arr): int { return $arr[0]; }
function nullable(?int $x, int|float|null $y = null, mixed $z = null): ?string { return null; }
function never_returns(): never { throw new \RuntimeException('never'); }
function gen(): \Generator { $x = yield 1; yield 'k' => 2; yield from [3, 4]; return 5; }
function named_args(int $width, int $height = 1): int { return $width * $height; }

$result = named_args(height: 3, width: 2);
$fn = fn(int $x): int => $x * 2;
$closure = function (int $x) use ($name, &$result): int { return $x + $result; };
$static_fn = static fn() => 42;
$first_class = strlen(...);
$method_ref = $obj->prop(...);
$static_ref = Pipeline::fromLabel(...);
$invoked = (new Pipeline())(21);
$spread_call = add(...[1, 2, 3, 4]);

// ── Operators ──
$arith = (1 + 2 - 3) * 4 / 2 % 3 ** 2;
$inc = $a++ + ++$a - $a-- - --$a;
$cmp = 1 < 2 && 2 <= 2 || 3 > 4 and 4 >= 5 xor !true;
$eq = 1 == 1 && 2 != 3 && 1 === 1 && 2 !== 3 && 1 <> 2;
$spaceship = 1 <=> 2;
$bits = (0xF0 & 0x3C) | (1 << 4) ^ (256 >> 2) | ~0;
$concat = 'a' . 'b' . 1;
$tern = $a > 5 ? 'big' : 'small';
$elvis = $a ?: 'fallback';
$coalesce = $undefined ?? 'default';
$a += 1; $a -= 1; $a *= 2; $a /= 2; $a %= 7; $a **= 2;
$name .= 'x'; $a <<= 1; $a >>= 1; $a &= 7; $a |= 8; $a ^= 1; $maybe ??= 'set';
$is = $obj instanceof \stdClass;
$cast = (int)'12' + (float)'1.5' + (bool)1 + (string)5 + (array)'a' + (object)[];
$silenced = @file_get_contents('/nonexistent');
$new_in_init = new Money(5);
$clone = clone $new_in_init;
$print = print 'printed';
$ref = &$a;
$nullsafe = $obj?->prop?->deep;
$static_prop = Pipeline::$current;
$const_expr = Pipeline::MAX;
$class_const = Pipeline::class;
$dynamic = $obj->{'prop'};
$var_var = ${'name'};
$var_class = new $class_const();
$var_method = $obj->$name();
$var_static = $class_const::MAX;

// ── Control flow ──
if ($a > 5) {
    echo 'big';
} elseif ($a > 2) {
    echo 'medium';
} else if ($a > 0) {
    echo 'small';
} else {
    echo 'zero';
}

if ($a): echo 'alt'; elseif ($b): echo 'alt2'; else: echo 'alt3'; endif;
for ($i = 0, $j = 10; $i < $j; $i++, $j--) { if ($i === 2) continue; if ($i === 4) break; }
for ($i = 0; $i < 3; $i++): echo $i; endfor;
foreach ($list as $key => $value) { echo "$key=$value"; }
foreach ($list as &$by_ref) { $by_ref = 1; } unset($by_ref);
foreach ($list as $k => $v): echo $k; endforeach;
while ($a-- > 0) { if ($a === 3) continue 1; }
while ($a > 0): $a--; endwhile;
do { $a++; } while ($a < 5);
switch ($a) {
    case 1:
    case 2: echo 'low'; break;
    case 3: echo 'three'; // fallthrough
    default: echo 'other';
}
switch ($a): case 1: break; endswitch;
$m = match (true) {
    $a < 0 => 'negative',
    $a === 0, $a === 1 => 'tiny',
    default => 'large',
};
outer: foreach ([1, 2] as $o) { foreach ([1, 2] as $i) { continue 2; } }
goto outer;

try {
    throw new \InvalidArgumentException('bad', 400);
} catch (\InvalidArgumentException | \RuntimeException $e) {
    echo $e->getMessage();
} catch (\Throwable) {
    echo 'anything';
} finally {
    echo 'cleanup';
}

// ── Language constructs ──
echo 'a', 'b';
print('p');
isset($a, $b) && !empty($a) && is_null($a);
unset($a);
exit(0);
die('stop');
require 'vendor/autoload.php';
require_once __DIR__ . '/bootstrap.php';
include 'optional.php';
include_once 'optional2.php';
assert($a > 0, 'positive');
eval('return 1;');
echo __FILE__, __LINE__, __FUNCTION__, __CLASS__, __METHOD__, __NAMESPACE__, __TRAIT__, __DIR__;
$callable = [new Pipeline(), 'run'];
$static_call = 'AcmeVault\Pipeline::fromLabel';
static $counter = 0;
global $config;
function scoped() { global $config; static $calls = 0; $calls++; }
register_shutdown_function(fn() => print "bye\n");
$status = Status::tryFrom('paid')?->label();
$cases = Status::cases();
$hint = new readonly class { public function __construct(public int $x = 1) {} };
?>
<!DOCTYPE html>
<html>
<head><title><?= htmlspecialchars($name) ?> inventory</title></head>
<body>
<?php if ($yes): ?>
  <p>Inline HTML with <?= $name ?> and <?php echo strtoupper($name); ?>.</p>
<?php else: ?>
  <p>Hidden.</p>
<?php endif; ?>
<?php foreach ($list as $k => $v): ?>
  <li><?= $k ?></li>
<?php endforeach ?>
<script>var x = <?= json_encode($list) ?>;</script>
</body>
</html>
<?php
// ── More PHP: types, traits, enums and rarely used constructs ──
declare(ticks=1);

namespace AcmeVault\Extra;

use Countable, IteratorAggregate, ArrayAccess, Traversable, ArrayIterator;

interface HasName { public function name(): string; }
interface HasId { public function id(): int; }

trait A { public function hello(): string { return 'A'; } public static function make(): static { return new static(); } }
trait B { public function hello(): string { return 'B'; } abstract public function required(): void; private int $secret = 0; }

final class Both implements HasName, HasId, Countable, IteratorAggregate, ArrayAccess
{
    use A, B {
        A::hello insteadof B;
        B::hello as protected helloB;
        hello as public aliasHello;
    }
    public function required(): void {}
    public function name(): string { return 'both'; }
    public function id(): int { return 1; }
    public function count(): int { return 0; }
    public function getIterator(): Traversable { return new ArrayIterator([]); }
    public function offsetExists(mixed $o): bool { return false; }
    public function offsetGet(mixed $o): mixed { return null; }
    public function offsetSet(mixed $o, mixed $v): void {}
    public function offsetUnset(mixed $o): void {}
    public function inter(HasName&HasId $x): (HasName&HasId)|null { return $x; }
    public function dnf((HasName&HasId)|null|int $x = null): static|false { return $this; }
    public function __serialize(): array { return []; }
    public function __unserialize(array $d): void {}
    public function __clone() {}
    public function __isset(string $n): bool { return false; }
    public function __unset(string $n): void {}
    public function __debugInfo(): array { return []; }
    public function __sleep(): array { return []; }
    public function __wakeup(): void {}
    public static function __set_state(array $a): object { return new self(); }
}

abstract class Shape
{
    abstract public function area(): float;
    public static function create(string $kind): static { return new $kind(); }
    final protected function sealed(): void {}
}

enum Level: int
{
    case Low = 1;
    case High = 10;
    public static function default(): self { return self::Low; }
    public function double(): int { return $this->value * 2; }
    const Max = self::High;
}

function typed(
    int|string $a,
    ?float $b = null,
    callable|Closure $c = null,
    iterable $d = [],
    object $e = new \stdClass(),
    int|null $f = null,
    string|false $g = false,
    mixed $h = null,
    array &...$rest,
): int|null {}

function generator_demo(): iterable
{
    $received = yield;
    $key = yield 'key' => 'value';
    yield from generator_demo();
    return $received ?? $key;
}

function static_vars(): int { static $n = 0, $m = 1; return ++$n + $m; }

$closure_bind = \Closure::bind(function () { return $this->secret; }, new Both(), Both::class);
$callable_str = 'strlen';
$result = $callable_str('abc');
$array_fn = [new Both(), 'name'];
$result2 = $array_fn();
$first_class_static = Both::make(...);

$heredoc_complex = <<<HTML
    <div class="{$callable_str}">
      {$array_fn[0]->name()} ${callable_str} $result[0] \x41 \u{1F4E6} \\ \$
    </div>
    HTML;

$list_keyed = ['a' => 1, 'b' => ['c' => 2]];
['a' => $ka, 'b' => ['c' => $kc]] = $list_keyed;
[, $second, , $fourth] = [1, 2, 3, 4];
foreach ($list_keyed as ['x' => $lx]) {}

if ($ka > 0): ?>
  <p>Template mode with <?= $ka ?></p>
<?php elseif ($kc): ?>
  <p>elseif</p>
<?php else: ?>
  <p>else</p>
<?php endif;

switch ($ka):
    case 1: echo 'one'; break;
    default: echo 'other';
endswitch;

$match_no_arg = match(true) { $ka > 5 => 'big', default => 'small' };
$nullsafe_chain = $obj?->a?->b() ?? 'none';
$spaceship_sort = usort($list, fn($a, $b) => $a <=> $b);
$int_ops = intdiv(7, 2) + 7 % 2 + 2 ** 3 ** 2 + (-7 % 3) + (7 <=> 3);
$str_ops = 'a' . 'b' . "c{$ka}" . 'd' . PHP_EOL;
$bool_ops = true && false || !true and false or true xor false;
// non-canonical casts below are deprecated in 8.5
$cast_ops = (int)'1' + (integer)'2' + (float)'3' + (double)'4';
$cast_ops2 = (bool)'a' . (boolean)'b' . (string)1 . (binary)'c' . (array)1 . (object)[];
$assign_ops = $ka .= 'x';
$ref_assign = &$list_keyed['a'];
$global_var = $GLOBALS['ka'] ?? $_SERVER['argv'] ?? $_GET['x'] ?? $_POST['y'] ?? $_COOKIE['z'] ?? $_FILES ?? $_ENV ?? $_REQUEST ?? $_SESSION ?? null;
$magic = __LINE__ . __FILE__ . __DIR__ . __FUNCTION__ . __CLASS__ . __TRAIT__ . __METHOD__ . __NAMESPACE__ . PHP_VERSION . PHP_OS . PHP_INT_SIZE . M_PI . E_ALL . E_STRICT . DIRECTORY_SEPARATOR . PHP_FLOAT_EPSILON;
$constants = [true, false, null, TRUE, FALSE, NULL, True, \PHP_INT_MAX, \E_USER_ERROR, SORT_STRING, JSON_PRETTY_PRINT, LC_ALL, LOCK_EX];
$inc_dec = [$ka++, ++$ka, $ka--, --$ka];
$exception_chain = new \RuntimeException('outer', 1, new \LogicException('inner'));
$instance_of = $exception_chain instanceof \Throwable && !($exception_chain instanceof \Countable);
$anonymous = new class extends Shape implements HasName {
    public function area(): float { return 0.0; }
    public function name(): string { return 'anon'; }
};
$readonly_anon = new readonly class(5) { public function __construct(public int $n) {} };
$enum_const = Level::Max->double();
$enum_cases = Level::cases();
$enum_from = Level::from(1);
$enum_try = Level::tryFrom(99);
$enum_name = Level::High->name . Level::High->value;
$new_in_expr = (new Both())->name();
$clone_with = clone $new_in_expr;
$static_closure = static fn(int ...$n): int => array_sum($n);
$arrow_nested = fn($x) => fn($y) => $x + $y;
$by_ref_closure = function () use (&$ka) { $ka++; };
echo <<<'NOW'
Nowdoc inside echo with $no_interp and {$braces}
NOW;
print <<<"DOC"
Heredoc inside print with $ka
DOC . "\n";
// ── PHP 8.4 / 8.5: property hooks, asymmetric visibility, pipe, #[\NoDiscard] ──
namespace AcmeVault\Modern;

use InvalidArgumentException;

interface HasFullName { public string $fullName { get; } }

class Person implements HasFullName
{
    // virtual property: get hook only, short (arrow) form
    public string $fullName { get => $this->first . ' ' . $this->last; }

    // set hook, long form with body, then get hook
    public string $first {
        set(string $value) {
            if ($value === '') { throw new InvalidArgumentException('empty'); }
            $this->first = ucfirst($value);
        }
        get => $this->first;
    }

    // set hook with arrow form and implicit parameter
    public string $last { set => strtolower($value); }

    // hooks with attributes, final and by-reference get
    public array $tags = [] {
        #[\Deprecated] final get => $this->tags;
    }
    public array $refs = [] { &get { return $this->refs; } }

    // promoted property with hooks
    public function __construct(public int $age { set => max(0, $value); }, string $first = 'Ada', string $last = 'Lovelace')
    {
        $this->first = $first;
        $this->last = $last;
    }

    // asymmetric visibility
    public private(set) string $id = 'p-1';
    protected(set) int $visits = 0;
    public protected(set) readonly string $slug;
    final public string $locked = 'x';
    var $legacy_var = 1;
    public function __clone() {}
}

abstract class HookedBase
{
    abstract public string $label { get; set; }
}

// pipe operator (8.5)
$piped = 'Hello World' |> strtolower(...) |> ucwords(...) |> (fn(string $s): string => trim($s));
$piped2 = [1, 2, 3] |> array_reverse(...) |> array_sum(...);

// #[\NoDiscard] and #[\Deprecated] attributes
#[\NoDiscard('use the result')]
function compute(): int { return 1; }
#[\Deprecated(message: 'use compute()', since: '8.5')]
function old_compute(): int { return 1; }
(void) compute();

// clone with updated properties (8.5), new without wrapping parentheses (8.4)
$p1 = new Person(30);
$p2 = clone($p1, ['first' => 'Grace']);
$chained = new Person(31)->fullName;
$const_closure = static fn(int $x): int => $x + 1;
const ADDER = static function (int $x): int { return $x + 2; };
class Pt { public function __construct(final public int $x = 0) {} }

// array_first / array_last (8.5), mb_trim, bcmath, json_validate (8.3), typed class constants (8.3)
$first = array_first([1, 2, 3]);
$last = array_last([1, 2, 3]);
$valid = json_validate('{"a":1}');
interface TypedConst { const string NAME = 'typed'; }
class TypedConstImpl implements TypedConst { final public const int LIMIT = 5; }
$dyn_const = TypedConstImpl::{'LIMIT'};
$lazy = (new \ReflectionClass(Person::class))->newLazyGhost(function (Person $o): void {});
class OverrideDemo extends HookedBase { #[\Override] public string $label { get => 'x'; set { } } }
$octal_explicit = 0o17;

// ── Rarely used constructs ──
namespace\helper();
$rel = new namespace\Thing();
$rel_const = namespace\SOME_CONST;
class ParentUse extends Pt
{
    public function __construct() { parent::__construct(1); }
    public function who(): string { return parent::class . self::class . static::class; }
}
declare(ticks=1): echo 'ticked'; enddeclare;
declare(ticks=1) { echo 'block'; }
;
if ($yes) { ; }
for (;;) { break; }
while (false);
$empty_block = function (): void {};

goto end_label;
end_label:
__halt_compiler();
This text after __halt_compiler is not parsed as PHP.
