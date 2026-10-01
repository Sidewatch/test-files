#!/usr/bin/env raku
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
