#!/usr/bin/env raku
# Raku 6.d (Rakudo 2025.x) — syntax showcase
use v6.d;
# ── Comments ──
# Raku showcase: warehouse inventory with grammars, roles and junctions.
# TODO: persist the stock. FIXME: grammar rejects negative quantities.

#`( An embedded comment using bracketing delimiters )
#`[ Another bracketed comment
    spanning lines ]
#`{{ double-bracketed comment }}

=begin pod
=head1 Inventory

POD documentation: B<bold>, I<italic>, C<code>, L<a link|https://example.com>.

=item First item
=item2 Nested item

=begin code
say "code in pod";
=end code
=end pod

=for comment
A comment paragraph in POD.

#| Declarator doc comment for the next declaration
sub documented() { }
#= Trailing declarator comment

# ── Use statements ──
use Test;
use JSON::Fast;
use lib 'lib';
need Cro::HTTP::Client;
use experimental :macros;
no precompilation;

# ── Variables and sigils ──
my $scalar = 42;
my @array = 1, 2, 3;
my %hash = a => 1, b => 2;
my &code = { $^a + $^b };
our $package-var = 'global';
state $counter = 0;
my ($x, $y) = 10, 20;
my Int $typed = 5;
my Str @names = <alpha beta gamma>;
my $twigil-self = $*PID;
my $dynamic = $*CWD;
my $env = %*ENV<HOME>;
my $args = @*ARGS;
my $compile-time = $?FILE;
my $dollar-underscore = $_;
my $match-var = $/;
my $named-capture = $<name>;
my $positional-capture = $0;

# ── Numbers ──
my $int = 42;
my $neg = -7;
my $underscore = 1_000_000;
my $hex = 0xFF;
my $oct = 0o755;
my $bin = 0b1010;
my $dec = :10<42>;
my $radix = :16<DEADBEEF>;
my $rat = 3/4;
my $rat-lit = <3/4>;
my $float = 3.14;
my $exp = 1.5e-3;
my $big-exp = 6.022E23;
my $complex = 3 + 4i;
my $inf = Inf;
my $nan = NaN;
my $pi = π;
my $tau = τ;
my $e = 𝑒;

# ── Strings ──
my $single = 'single quoted, no $interpolation';
my $double = "double quoted with $scalar and @array[0] and %hash<a> and {1 + 2} and &code(1, 2)";
my $escapes = "tab\t newline\n quote\" backslash\\ hex\x[41] unicode\c[LATIN SMALL LETTER E WITH ACUTE] \e[0m bell\a";
my $q-form = q[no interpolation $here];
my $qq-form = qq{interpolated $scalar {$scalar * 2}};
my $qqw = qqww<"two words" third>;
my $words = <alpha beta gamma>;
my $words-interp = «alpha $scalar "multi word"»;
my $heredoc = q:to/END/;
    Indented heredoc, $not interpolated.
      Keeps relative indentation.
    END
my $qq-heredoc = qq:to/EOT/;
    Name: $scalar
    Sum: {1 + 1}
    EOT
my $adverb = Q:c'closure {1+1} only';
my $format = sprintf("%-10s|%5.2f|%05d|%x", "sku", 3.14159, 42, 255);
my $chars = "caf\c[LATIN SMALL LETTER E WITH ACUTE] 📦";
my $joined = "a" ~ "b" ~ "c";
my $repeat = "ab" x 3;
my $list-repeat = <a b> xx 3;

# ── Regexes ──
my $m = "AC-1001" ~~ / (<[A..Z]>+) '-' (\d+) /;
my $named = "AC-1001" ~~ / $<prefix>=[<alpha>+] '-' $<num>=[\d+] /;
my $subst = "a-b-c";
$subst ~~ s/'-'/_/;
$subst ~~ s:g/'_'/ /;
my $trans = "hello".trans('a'..'z' => 'A'..'Z');
my $tr = "hello" ~~ tr/a..y/b..z/;
my $rx = rx/ ^ \d+ [ '.' \d+ ]? $ /;
my $rx2 = rx:i/ hello \s+ world /;
my $match-all = "a1b2c3".match(/ \d /, :g);
if "x=10" ~~ / (\w) '=' (\d+) / { say "$0 => $1" }
my regex digits { \d+ }
my token word { \w+ }
my rule sentence { <word>+ % \s+ }

# ── Grammars ──
grammar OrderLine {
    token TOP    { <number> ',' <total> ',' <status> }
    token number { \d+ }
    token total  { \d+ [ '.' \d+ ]? }
    token status { 'paid' | 'pending' | 'cancelled' }
    rule  heading { ^^ '#' \s+ <text=.line> $$ }
    regex line   { \N* }
    proto token op {*}
    token op:sym<+> { <sym> }
    token op:sym<-> { <sym> }
}

grammar Config is OrderLine {
    token TOP { <pair>+ % \n }
    token pair { <key=.ident> \s* '=' \s* <value=.word> }
    token ident { <.alpha> \w* }
    token word { <-[\n]>+ }
    token ws { \h* }
}

class OrderActions {
    method TOP($/) { make Order.new(number => +$<number>, total => $<total>.Rat, status => ~$<status>) }
}

# ── Roles and classes ──
role Describable {
    method describe(--> Str) { ... }
    method shout() { self.describe.uc }
}

role Priced[::T] {
    has T $.price is required;
}

class Order does Describable {
    has Int    $.number is required;
    has Rat    $.total  = 0;
    has Str    $.status = 'pending';
    has @.tags is rw;
    has %!private;
    has $.lazy is built(False) is default(5);

    submethod BUILD(:$!number, :$!total = 0, :$!status = 'pending') { }
    method describe(--> Str) { "#{ $!number } { $!status } { $!total.fmt('%.2f') }" }
    method !secret() { %!private }
    method total-with-tax(Numeric :$rate = 0.075 --> Numeric) { $!total * (1 + $rate) }
    multi method add(Int $n) { $!total += $n }
    multi method add(Str $s) { $!total += +$s }
    method Str { self.describe }
    method gist { "Order({$!number})" }
    method FALLBACK($name, |c) { "no method $name" }
}

class Perishable is Order {
    has Date $.expires;
    method describe(--> Str) { callsame() ~ " (perishable)" }
}

enum Status <Pending Paid Cancelled>;
enum Level (Low => 1, High => 10);
subset PositiveInt of Int where * > 0;
subset Sku of Str where /^ <[A..Z]> ** 2 '-' \d ** 4 $/;
constant LIMIT = 100;
constant @PRIMES = 2, 3, 5, 7;

# ── Subroutines ──
sub revenue(@orders --> Numeric) { [+] @orders.grep(*.status eq 'paid').map(*.total) }
sub greet(Str $name, Int :$times = 1, *@rest, *%named) { "Hello, $name!" x $times }
sub with-slurpy(|c) { c.perl }
sub optional(Int $a, Int $b?, Int $c = 5) { $a + ($b // 0) + $c }
sub typed-return(Int $n --> Int:D) { $n * 2 }
sub lambda-user { my &add = -> $a, $b = 2 { $a + $b }; add(1) }
sub pointy-block { for 1..3 -> $i, $j? { say $i } }
multi sub area(Int $r) { π * $r ** 2 }
multi sub area(Int $w, Int $h) { $w * $h }
multi sub area(Str $s where *.chars > 0) { $s.chars }
sub MAIN(Str :$name = 'world', Bool :$verbose) { say "Hello, $name" }
proto sub dispatch(|) {*}
multi sub dispatch(Int $x) { 'int' }
my $anon = sub ($x) { $x * 2 };
my $whatever = * + 1;
my $whatever2 = *.uc;
my $block = { $_ * 2 };
my $placeholder = { $^a <=> $^b };
my $named-placeholder = { $:flag ?? 1 !! 0 };

# ── Operators ──
my @ops = (
    1 + 2, 3 - 1, 2 * 3, 7 / 2, 7 div 2, 7 % 3, 7 mod 3, 2 ** 8, -5, +"5",
    1 == 1, 1 != 2, 1 < 2, 2 > 1, 1 <= 2, 2 >= 1, 1 <=> 2, 'a' cmp 'b', 'a' leg 'b',
    'a' eq 'a', 'a' ne 'b', 'a' lt 'b', 'b' gt 'a', 'a' le 'a', 'b' ge 'a',
    1 === 1, $scalar =:= $scalar, 1 eqv 1, 1 ~~ Int, 1 !~~ Str,
    True && False, True || False, True ^^ False, !True, not True, so True,
    $x // 0, $x andthen 1, $x orelse 2, $x notandthen 3,
    1 ?? 2 !! 3, 1 min 2, 1 max 2, 1 gcd 2, 1 lcm 2,
    1 <=> 2, 5 % 3, 10 %% 5, 3 xx 2, 'a' x 2, 'a' ~ 'b',
    1..5, 1^..5, 1..^5, 1^..^5, 1...10, 1,3...11, ^5, 1..*, 
    +^5, ?^5, 5 +& 3, 5 +| 3, 5 +^ 3, 5 +< 2, 5 +> 1,
    (1, 2) Z (3, 4), (1, 2) X (3, 4), (1, 2) Z+ (3, 4),
    [+] 1..5, [*] 1..5, [~] <a b c>, [max] 1, 5, 3, [<] 1, 2, 3,
    (1, 2, 3) »+» 1, (1, 2) »*« (3, 4), (1..5) »**» 2, -« (1, 2),
    (1, 2, 3).map(* * 2), @array>>.say,
    $scalar++, ++$scalar, $scalar--, --$scalar,
    (1 | 2 | 3), (1 & 2), (1 ^ 2),
    set(1, 2) ∪ set(2, 3), set(1, 2) ∩ set(2, 3), 1 ∈ set(1), 1 ∉ set(2), set(1) ⊆ set(1, 2),
);
$scalar += 1; $scalar -= 1; $scalar *= 2; $scalar /= 2; $scalar **= 2; $scalar ~= "x";
$scalar //= 5; $scalar ||= 6; $scalar &&= 7; $scalar min= 3; $scalar max= 9;
@array.push(4); @array[0]; @array[*-1]; @array[1..2]; @array[0, 2]; @array[^2];
%hash<a>; %hash{'b'}; %hash<a b>; %hash<c>:exists; %hash<a>:delete;
@array.=sort;
@array .= reverse;
my @sliced = @array[*-2..*];
my $chained = (1..10).grep(* %% 2).map(* ** 2).sum;
say (1..5) »**» 2;   # (1 4 9 16 25)

# ── Control flow ──
if $scalar > 10 { say "big" } elsif $scalar > 5 { say "mid" } else { say "small" }
unless $scalar { say "falsy" }
say "postfix if" if $scalar;
say "postfix unless" unless !$scalar;
for @array -> $item { say $item }
for @array.kv -> $i, $v { say "$i: $v" }
for 1..3 { say $_ }
say $_ for <a b c>;
for @array Z @names -> ($n, $name) { say "$n $name" }
loop (my $i = 0; $i < 3; $i++) { next if $i == 1; last if $i == 2; redo if False }
loop { last }
while $counter < 3 { $counter++ }
until $counter <= 0 { $counter-- }
repeat { $counter++ } while $counter < 3;
repeat { $counter-- } until $counter <= 0;
given $scalar {
    when 1       { say "one" }
    when 2..5    { say "few" }
    when Int     { say "int" }
    when /^ a /  { say "starts with a" }
    default      { say "other" }
    proceed;
    succeed;
}
LINE: for 1..3 -> $row {
    for 1..3 -> $col { next LINE if $col == 2 }
}
my $result = do { 1 + 1 };
my @gathered = gather for 1..3 { take $_ * 2 };
my @lazy = lazy gather { take 1; take 2 };
my $sequence = 1, 2, 4 ... 100;
my $fib = 0, 1, * + * ... *;

# ── Exceptions and phasers ──
try {
    die "boom";
    CATCH {
        when X::AdHoc { say "caught: {.message}" }
        default { .rethrow }
    }
    CONTROL { when CX::Warn { .resume } }
}

class X::OutOfStock is Exception {
    has $.sku;
    method message() { "Out of stock: $!sku" }
}
sub check(Int $qty) { X::OutOfStock.new(sku => 'AC-1001').throw if $qty == 0; fail "negative" if $qty < 0 }
my $outcome = try { check(0) } // 'recovered';
warn "careful";

BEGIN { say "compile time" }
CHECK { }
INIT { }
START { say "first time through" }
FIRST { }
NEXT { }
LAST { }
ENTER { }
LEAVE { }
END { say "program end" }
{ my $x = 1; $x = 2; KEEP { say 'ok' } UNDO { say 'failed' } }

# ── Concurrency ──
my $promise = start { sleep 0.1; 42 };
say await $promise;
my $channel = Channel.new;
$channel.send(1);
$channel.close;
my $supply = Supply.from-list(1..3);
react { whenever $supply -> $v { say $v } }
my @workers = (1..3).map: -> $n { start { $n * 2 } };
await @workers;
my $lock = Lock.new;
$lock.protect: { $counter++ };
my atomicint $atomic = 0;
$atomic ⚛= 5;

# ── Main body ──
my @orders = gather for "1,120.50,paid", "2,42,pending", "3,0,cancelled" -> $line {
    with OrderLine.parse($line) -> $m {
        take Order.new(number => +$m<number>, total => $m<total>.Rat, status => ~$m<status>);
    }
}

.describe.say for @orders;
my $revenue = [+] @orders.grep(*.status eq 'paid').map(*.total);
say "revenue: $revenue";
say @orders.map(*.describe).join("\n");
say @orders.sort(*.total).reverse».number;
say "done" if @orders ~~ Positional;
say Order.^methods.map(*.name).sort;
say $revenue.WHAT, $revenue.^name, $revenue.?foo, $revenue.Str;

# ── Custom operators, term and circumfix declarations ──
sub infix:<⊕>($a, $b) is tighter(&infix:<+>) { $a + $b }
sub infix:<**!>(Int $a, Int $b) is assoc<right> { $a ** $b }
sub prefix:<√>($x) is equiv(&prefix:<->) { sqrt $x }
sub postfix:<!>(Int $n) is looser(&postfix:<++>) { [*] 1..$n }
sub circumfix:<⟦ ⟧>(*@items) { @items.join(",") }
sub postcircumfix:<⟨ ⟩>(%h, $key) { %h{$key} }
sub term:<ø> { Nil }
sub trait_mod:<is>(Routine $r, :$logged!) { $r.wrap: -> |c { say "calling"; callsame } }
multi sub infix:<~~~>(Str $a, Str $b) { $a.lc eq $b.lc }
say 1 ⊕ 2, √16, 5!, ⟦1, 2⟧, ø;
sub documented-fn is logged { 42 }

# ── Capture, Pair, Slip, and adverb syntax ──
my $capture = \(1, 2, :named<v>);
sub takes-capture(|c) { c }
takes-capture(|$capture);
my $pair1 = :key<value>;
my $pair2 = :key(42);
my $pair3 = :!flag;
my $pair4 = :flag;
my $pair5 = :5limit;
my $pair6 = :$scalar;
my $pair7 = :@array;
my $pair8 = :%hash;
my $pair9 = :&code;
my %built = :a(1), :b<two>, c => 3, 'd' => 4, "e" => 5, f => <x y>;
my @slipped = 1, |(2, 3), slip(4, 5);
my %merged = |%hash, extra => 1;
my $anon-hash = %( a => 1 );
my $anon-array = @(1, 2, 3);
my $item = $(1, 2);
my $interp-hash = "%hash<a>";
my $interp-call = "@array[0]" ~ "&code(1, 2)" ~ "{ $scalar }" ~ "$scalar.abs()" ~ "@array.sum()" ~ "$scalar[0]";

# ── Whatever, HyperWhatever, ranges and sequences ──
my @w = (1, 2, 3).map(* + 1);
my @w2 = (1, 2, 3).map(*.Str);
my @w3 = (1, 2, 3).grep(* > 1);
my $hw = **;
my @hw = (1, 2, 3)[**];
my @multi-dim = [[1, 2], [3, 4]];
say @multi-dim[1;0];
say @multi-dim[*;1];
my @seq1 = 1, 2, 4 ... 64;
my @seq2 = 1, 3 ... *;
my @seq3 = 10, 8 ... 0;
my @seq4 = 'a' ... 'e';
my @seq5 = 1 ...^ 5;
my @seq6 = 1, 1, * + * ... *;
my @seq7 = 1, 2, 3 … 10;
my @ranges = 1..5, 1..^5, 1^..5, 1^..^5, ^5, 'a'..'e', 1..*, *..5;
my @rev = (1..5).reverse;
my @lazy-infinite = (1..Inf).lazy.map(* * 2);

# ── Meta-operators ──
my @meta = (
    [+] 1..5, [\+] 1..5, [[+]] [1, 2], [**] 1..3, [~] 'a'..'c', [,] 1..3, [Z] (1, 2), (3, 4),
    (1, 2) Z (3, 4), (1, 2) Z+ (3, 4), (1, 2) Z=> (3, 4), (1, 2) X (3, 4), (1, 2) X* (3, 4), (1, 2) Xcmp (3, 4),
    1 R- 2, 1 R/ 2, 'a' R~ 'b', (1, 2) RZ (3, 4),
    (1, 2) »+« (3, 4), (1, 2) «+» (3, 4), (1, 2) »+» 1, 1 «+« (2, 3), -« (1, 2), (1, 2)».succ, (1, 2)>>.succ,
    @array».Str, @array>>.Str, @array.map(*.Str), (1, 2) <<+>> (3, 4),
    !(1 == 2), 1 !== 2, 1 !eq 2, 1 !after 2, 1 ![==] 1,
    $scalar [+]= 1, $scalar [max]= 5,
    1 xx 3, 'a' x 3, ('a', 'b') xx 2,
    1 <=> 2, 1 before 2, 1 after 2, 'a' coll 'b',
    2 ** 3, 2 ⚛+= 1,
);

# ── Regex features ──
my regex tokens {
    :ratchet
    :sigspace
    [ <alpha> | <digit> | <[_ -]> | <:Lu> | <:L + :N> | <+alpha + [_]> | <-[\s]> | <?[a..f]> ]+
    <?before \s> <!before x> <?after \d> <!after y> <|w> <.ws> <.alpha> <ident> <sym> <wb>
    $<capture>=(\d+) $<named>=<alpha> <name=.ident> @<list>=[\d+] %<hash>=[\w+]
    [ 'literal' | "other" | \x[41] | \c[BULLET] | \t | \n | \h | \v | \s | \S | \w | \W | \d | \D | \N | \H | \V ]
    ** 2..5 ** 3 ** {2} ** 1..* \d+ % ',' \d+ %% ',' \d ** 3 % '-'
    [ a || b ] [ a | b ] [ a && b ] [ a & b ]
    { say "inline code" } <{ $scalar }> <?{ $scalar > 1 }> <!{ $scalar < 0 }> <$scalar> <@array> <&regex-sub>
    ^ ^^ $ $$ << >> « »
    :my $x = 5; { $x++ }
    <~~> <$<capture>> $0 $1 $<capture> \1
    :i :m :s :g :x :ov :ex :c :p :nth(2) :1st :2nd :3rd :4th :rw
}
my $adverbed = "AbC" ~~ m:i/abc/;
my $multi-m = "a b" ~~ ms/a b/;
my $mm = "a b" ~~ mm/a b/;
my $ss = "a-b" ~~ s:g/'-'/_/;
my $sss = "a-b".subst(/'-'/, '_', :g);
my $S = S:g/'-'/_/ given "a-b";
my $sub-block = "abc".subst(/(.)/, { $0.uc }, :g);
my $transliteration = "abc".trans("a" => "x", "b" => "y");
my $tr-op = ("abc" ~~ tr/a..c/A..C/);
my @all = "a1b2".comb(/\d/);
my @parts = "a,b".split(',');
my $first-match = "foo bar" ~~ /<alpha>+/;
say $first-match<alpha>;
say $/.from, $/.to, $/.orig, $/.prematch, $/.postmatch;
say "abc" ~~ /^ <[a..c]> ** 3 $/;
say "x" ~~ /<|w>/;

# ── Classes: traits, attributes, MOP, and more ──
class Point is repr('CStruct') is export {
    has num64 $.x is rw;
    has num64 $.y is rw;
}

class Counter {
    has Int $.count is rw = 0;
    has Int $!hidden;
    has $.lazy-attr is built(:bind) is lazy;
    has Str $.name is required("must be given");
    has @.items handles <push pop elems>;
    has %.map handles <AT-KEY EXISTS-KEY>;
    has $.proxy is rw handles 'print';
    my $.shared = 0;
    my Int $private-class-var = 0;
    our $.pkg = 1;

    method new(|) { callsame }
    submethod TWEAK { $!hidden = 1 }
    submethod DESTROY { }
    method increment(--> Counter:D) { $!count++; self }
    method CALL-ME(|c) { self.increment }
    method !private-method { 1 }
    method call-private { self!private-method }
    method with-dot { $.count + $!count + self.count }
    method ::?CLASS.static-like { ::?CLASS.new }
    method Bool { $!count > 0 }
    method Numeric { $!count }
    method Int { $!count }
    method list { [$!count] }
    method iterator { (1, 2).iterator }
    method sink { }
    method ACCEPTS($other) { True }
    method postcircumfix:<[ ]>($i) { $i }
    method AT-POS($i) { $i }
    method ASSIGN-POS($i, $v) { }
    trusts Other;
    also is Cool;
    also does Positional;
}

augment class Int { method double { self * 2 } }
class Other { }
my $anon-class = class { method hi { "hi" } };
my $anon-role = role { method hello { "hello" } };
my $mixed = 5 but Counter;
my $does = "str" does Describable;
say Counter.^name, Counter.^attributes, Counter.^methods(:local), Counter.^mro, Counter.^roles, Counter.^parents;
say Counter.HOW.WHAT;
Counter.^add_method("dyn", my method dyn { 1 });
Counter.^compose;
my $meta = Metamodel::ClassHOW.new_type(:name<Dyn>);

# ── Native, NativeCall, and low-level types ──
use NativeCall;
sub getpid() returns int32 is native { * }
sub strlen(Str --> size_t) is native(Str) { * }
sub with-lib(int32 $a, CArray[uint8] $buf --> int32) is native('c') is symbol('strlen') { * }
my int $native-int = 5;
my num $native-num = 1e0;
my str $native-str = "s";
my uint8 $byte = 255;
my int64 $big = 1;
my CArray[int32] $carray .= new(1, 2, 3);
my Pointer $ptr;
my @native-array is Array[int32] = 1, 2;
my buf8 $buf = buf8.new(1, 2, 3);
my blob8 $blob = Blob.new(4, 5);
use nqp;
nqp::say("nqp op");

# ── Typed, constrained, and coercion parameters ──
sub typed(Int:D $a, Str:U $b, Int:_ $c, Numeric() $d, Int(Str) $e, Array[Int] $f, Positional[Int] $g, Callable:D $h, ::T $t, T $u) { }
sub where-clause(Int $n where * > 0, Str $s where { .chars < 5 }, $x where /abc/) { }
sub destructure(@(Int $a, $b), %(:$c, :$d), [$e, *@rest], (:$f, :$g)) { }
sub named-and-positional($a, $b = $a * 2, :$c = $b + 1, :d($dd) = 3, :$e!, *@rest, :f(:$ff), *%other --> Int) { 1 }
sub return-types(--> Nil) { }
sub more(Int $a --> Bool:D) { True }
sub rw-param($a is rw, $b is copy, $c is raw, :$d is required) { }
sub anon-params($, $, *@, *%) { }
sub sig-literal(Int $ where * > 3, 'literal') { }
my &curried = &named-and-positional.assuming(1, :e(5));
my $sig = :(Int $a, Str $b --> Bool);
say $sig.params;
say &typed.signature;

# ── Supplies, promises, and threads ──
my $supply = supply {
    emit 1;
    whenever Supply.interval(1) { emit $_; done if $_ > 3 }
    LAST { say "done" }
    CLOSE { }
};
react {
    whenever $supply -> $v { say $v }
    whenever signal(SIGINT) { done }
    whenever Promise.in(5) { done }
}
my $p = Promise.new;
$p.keep(42);
$p.break("reason");
my $v = Promise.start({ 42 }).then({ .result });
await Promise.allof(start { 1 }, start { 2 });
my $vow = $p.vow;
my $s = Supplier.new;
$s.emit(1);
$s.done;
my @threads = (^4).map: -> $n { Thread.start({ say $n }) };
.finish for @threads;
my $semaphore = Semaphore.new(2);
$semaphore.acquire; $semaphore.release;
hyper for 1..100 { .say }
race for 1..100 { .say }
my @r = (1..10).hyper(:degree(4), :batch(2)).map(* * 2);
my @r2 = (1..10).race.map(* * 2);

# ── Unit-scoped declarations, modules, and exports ──
unit module Warehouse::Inventory;
our sub exported-fn is export { 1 }
sub tagged is export(:DEFAULT, :extras) { 2 }
sub only-extras is export(:extras) { 3 }
our constant $VERSION = v1.2.3;
module Inner { our sub nested { 4 } }
package Pkg { our $var = 5 }
my $version = Version.new("1.2.3");
say v6.d.PREVIEW;
say $?DISTRO.name, $*VM.name, $*PERL.version, $*KERNEL, $*DISTRO, $*TZ, $*HOME, $*TMPDIR, $*USER, $*EXECUTABLE;
say $?PACKAGE, $?CLASS, $?ROLE, $?MODULE, $?LINE, $?FILE, $?NL;
say &?ROUTINE, &?BLOCK, $?TABSTOP, $=pod, $=finish, $*IN, $*OUT, $*ERR, $*ARGFILES, $*PROGRAM-NAME, $*PROGRAM, @*INC, %*ENV;
say Nil, Any, Mu, Failure, Empty, Whatever, WhateverCode, HyperWhatever, Cool, Junction, Order::More;

# ── Heredocs, formats, and quoting variations ──
my $q1 = q:to/EOF/;
    heredoc
    EOF
my $q2 = qq:to/EOF/;
    interpolated {$scalar}
    EOF
my $q3 = qq:to [END];
    bracketed terminator
    END
my $q4 = q:w<a b c>;
my $q5 = qw<a b c>;
my $q6 = qqw/a $scalar c/;
my $q7 = Q:q[nested [brackets] work];
my $q8 = q:b'with \t escape';
my $q9 = qq:!c"no closures {1+1}";
my $q10 = q:s[scalar $scalar only];
my $q11 = q:a[array @array only];
my $q12 = q:h[hash %hash only];
my $q13 = q:f[function &code() only];
my $q14 = ｢fullwidth corner quotes｣;
my $q15 = “curly double quotes”;
my $q16 = ‘curly single quotes’;
my $q17 = „low double quote“;
my $q18 = <<"double angle with $scalar">>;
my $q19 = << 'plain' words >>;
my $q20 = «guillemets with $scalar and {1 + 1}»;
my $fmt = 'Total: %.2f'.sprintf(3.14159);
say sprintf('%s has %d items costing %.2f', 'x', 3, 9.99), 5.fmt('%03d'), 255.base(16), :16<FF>, "ff".parse-base(16);
say Q:to/END/;
    Q heredoc: no interpolation, no escapes \n at all
    END

# ── Pod and declarator blocks ──
=begin pod :kind<example>
=TITLE Warehouse
=SUBTITLE Inventory
=head2 Syntax
=para A paragraph with B<bold>, I<italic>, U<underline>, C<code>, V<verbatim>, E<gt> and L<link|https://example.com>,
X<index entry>, Z<comment>, N<note>, P<placement>, D<definition>, K<keyboard>, T<terminal>, R<replaceable>.
=begin table
 Sku  | Qty
 =====+====
 AC-1 | 25
=end table
=begin item
Item content
=end item
=defn Term
Definition text.
=for code :lang<raku>
say "pod code";
=begin nested
=para Nested block
=end nested
=config head1 :like<head2>
=END
Anything after =END is documentation only.
