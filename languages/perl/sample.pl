#!/usr/bin/env perl
# Perl showcase: parse an orders CSV, total the paid ones, print a report.
# TODO: read the path from @ARGV
# FIXME: split on commas ignores quoted fields
use strict;
use warnings;
use utf8;
use v5.34;
use feature qw(say state signatures postderef fc isa);
no warnings qw(experimental::signatures experimental::isa experimental::try);
use List::Util qw(sum0 max min first reduce);
use Scalar::Util qw(blessed looks_like_number reftype);
use POSIX qw(floor ceil strftime);
use Data::Dumper;
use constant { PI => 3.14159, REORDER_POINT => 25 };
use constant DEBUG => 0;
use parent -norequire, 'Exporter';
require File::Basename;
our $VERSION = '1.04';
our @EXPORT_OK = qw(describe);

=pod

=head1 NAME

sample - POD documentation block

=head2 SYNOPSIS

    perl sample.pl orders.csv

=over 4

=item B<-v>

Verbose, with I<italic>, C<code> and L<perlpod/links>.

=back

=cut

# ── Variables and sigils ──
my $scalar = 42;
my @array = (1, 2, 3, 'four', [5, 6], { seven => 7 });
my %hash = (name => 'widget', qty => 12, 'quoted key' => 1, -bare => 2);
my ($first, $second, @rest) = @array;
my $aref = \@array;
my $href = \%hash;
my $cref = sub { return $_[0] * 2 };
my $sref = \$scalar;
my $rref = \\$scalar;
our $global = 'visible';
local $_ = 'topic';
local $, = '-';
state $counter = 0;
my $last_idx = $#array;
my $last_idx2 = $#{$aref};
my $count = @array;
my $elem = $array[0] + $$aref[1] + ${$aref}[2] + $aref->[3];
my $val = $hash{name} . $$href{qty} . ${$href}{name} . $href->{name};
my @slice = @array[0, 1];
my @hslice = @hash{qw(name qty)};
my %kv = %hash{'name', 'qty'};
my @postfix = $aref->@*;
my %postfix_h = $href->%*;
my $postfix_last = $aref->$#*;

# ── Numbers ──
my $dec = 1_000_000;
my $hex = 0xFF_EC;
my $oct = 0755;
my $oct2 = 0o755;
my $bin = 0b1010_1010;
my $flt = 3.14;
my $exp = 1.5e-3;
my $hexf = 0x1.8p3;
my $ver = v1.22.333;
my $inf = 9**9**9;
my $nan = -sin(9**9**9);

# ── Strings and quoting ──
my $single = 'single \'quoted\' no $interp\n';
my $double = "double \"quoted\" tab:\t newline:\n hex:\x41 wide:\x{263A} oct:\101 ctrl:\cA name:\N{U+00E9} \$escaped \@escaped";
my $interp = "scalar $scalar, elem $array[0], hash $hash{name}, aref $aref->[0], method @{[ scalar @array ]}, expr ${\ ($scalar + 1)}";
my $q = q(single quoted (nested parens) with 'quotes');
my $qq = qq{double quoted {nested} with $scalar and "quotes"};
my $qw = [qw(alpha beta gamma)];
my $backtick = `echo hello`;
my $qx = qx(echo hello);
my $heredoc = <<"END";
Interpolating heredoc: $scalar and @{[ $scalar * 2 ]}
Second line\twith escape
END
my $heredoc_raw = <<'END';
Raw heredoc: $scalar stays literal \n
END
my $heredoc_indent = <<~EOT;
    Indented heredoc strips common leading space
      keeps relative indent
    EOT
my $bare_heredoc = <<END;
Bare heredoc interpolates $scalar
END
my $concat = 'a' . 'b' x 3 . "c";
my @repeat = (0) x 5;
my $chr = chr(65) . ord('A') . sprintf('%05.1f|%-5s|%+d|%x|%o|%e|%b|%%|%3$s', 3.14159, 'ab', 7);
my $unicode = "caf\x{e9} \x{1F4E6}";

# ── Regular expressions ──
my $line = 'order 123, total 45.67, status paid';
if ($line =~ /^order\s+(\d+),\s*total\s+([\d.]+)/i) { say "n=$1 total=$2"; }
if ($line =~ m{status\s+(?<state>\w+)}x) { say $+{state}; }
$line =~ s/paid/PAID/g;
$line =~ s{(\d+)}{<$1>}ge;
$line =~ s/(\w+)/\u$1/;
(my $copy = $line) =~ tr/a-z/A-Z/;
my $count_a = ($line =~ tr/a//);
$line =~ y/0-9/#/;
my @words = split /\s+/, $line;
my @fields = split(/,/, 'a,b,c', 2);
my @matches = $line =~ /(\d+)/g;
my $re = qr/^(?:foo|bar)\b[[:alpha:]]+$/ix;
my $named = qr/(?<year>\d{4})-(?<mon>\d\d)/;
if ('2025-01' =~ $named) { say "$+{year}/$+{mon}"; }
my $neg = 'abc' !~ /z/;
while ($line =~ /(\w)/g) { last if pos($line) > 3; }
my $tr_ret = ($line =~ tr/a-z//cdr);
$line =~ s/^\s+|\s+$//g;
my $look = 'foobar' =~ /foo(?=bar)(?!baz)(?<=o)(?<!x)/;
my $unicode_class = 'é' =~ /\p{L}\X\R\h\v\K/;

# ── Operators ──
my $arith = (1 + 2 - 3) * 4 / 2 % 3 ** 2;
my $inc = $scalar++ + ++$scalar - $scalar-- - --$scalar;
my $cmp = (1 < 2) && (2 <= 2) || (3 > 4) and not (4 >= 5);
my $eq = (1 == 1) && (2 != 3);
my $spaceship = 1 <=> 2;
my $strcmp = 'a' cmp 'b';
my $streq = ('a' eq 'a') && ('a' ne 'b') && ('a' lt 'b') && ('b' gt 'a') && ('a' le 'a') && ('b' ge 'b');
my $bits = (0xF0 & 0x3C) | (1 << 4) ^ (256 >> 2) | ~0;
my $strbits = "ab" |. "cd";
my $logic = $scalar || 'default';
my $dor = $hash{missing} // 'undef';
my $tern = $scalar > 5 ? 'big' : 'small';
$scalar += 1; $scalar -= 1; $scalar *= 2; $scalar /= 2; $scalar %= 7; $scalar **= 2;
$scalar .= 'x'; $scalar x= 2; $scalar ||= 1; $scalar &&= 2; $scalar //= 3;
$scalar <<= 1; $scalar >>= 1; $scalar &= 7; $scalar |= 8; $scalar ^= 1;
my @range = (1 .. 5, 'a' .. 'e');
my ($min, $max) = (min(@range), max(1 .. 5));
my $chained = 1 < 2 < 3;
my $isa = $aref isa 'ARRAY';
my $wantarray = wantarray ? 'list' : 'scalar';
my $filetest = -e '/etc/hosts' && -d '/tmp' && -f $0 && -r $0 && -s $0;

# ── Control flow ──
my %by_status;
my @orders;

while (my $line = <DATA>) {
    chomp $line;
    next if $line =~ /^\s*(#|$)/;
    my ($number, $total, $status) = split /,/, $line;
    push @orders, { number => $number, total => $total, status => $status };
    $by_status{$status}++;
}

unless ($scalar) { say 'false' } elsif ($count) { say 'elsif' } else { say 'true' }
if ($scalar) { say 'if' } elsif ($count) { say 'elsif' } else { say 'else' }
for my $i (1 .. 3) { next if $i == 2; last if $i == 3; redo if 0; }
for (my $i = 0; $i < 3; $i++) { say $i }
foreach my $item (@array) { say ref $item }
until ($scalar > 100) { $scalar *= 2 }
do { $scalar-- } while ($scalar > 50);
do { $scalar++ } until ($scalar > 60);
OUTER: for my $x (1 .. 3) { for my $y (1 .. 3) { next OUTER if $y == 2; last OUTER if $x == 3; } }
say 'postfix if' if $scalar;
say 'postfix unless' unless !$scalar;
say $_ for 1 .. 3;
say 'postfix while' while $scalar-- > 58;
{ local $@; eval { die "boom\n" }; say "caught: $@" if $@; }
eval { die { code => 500, message => 'object' } };
my $ok = eval { risky(); 1 } or do { warn "failed: $@"; 0 };
use feature 'try';
no warnings 'experimental::try';
try { die "oops" } catch ($e) { warn $e } finally { say 'cleanup' }
given_when() if 0;
goto END_LABEL if 0;
END_LABEL: say 'label';
warn "a warning\n";
die "fatal\n" if 0;
exit 0 if 0;

# ── Subroutines ──
sub describe { my ($o) = @_; return "#$o->{number} ($o->{status})" }
sub with_sig($x, $y = 10, @rest) { return $x + $y + @rest }
sub named_args(%opts) { return join ',', map { "$_=$opts{$_}" } sort keys %opts }
sub with_proto :prototype($$;$) { return $_[0] }
sub list_ctx { return wantarray ? (1, 2, 3) : 3 }
sub recurse { my $n = shift; return $n <= 1 ? 1 : $n * recurse($n - 1) }
sub AUTOLOAD { our $AUTOLOAD; return if $AUTOLOAD =~ /DESTROY/; return "auto($AUTOLOAD)" }
sub DESTROY {}
my $anon = sub ($n) { $n + 1 };
my $closure = do { my $c = 0; sub { return ++$c } };
&$anon(1); &{$anon}(1); $anon->(1); &describe({ number => 1, status => 'x' });
BEGIN { $| = 1 }
END { say 'bye' }
INIT { }
CHECK { }
UNITCHECK { }

# ── Packages, OO, tie ──
package Order {
    use parent -norequire, 'Base';
    our @ISA = ('Base');
    use overload '""' => \&to_string, '==' => sub { $_[0]->{number} == $_[1]->{number} }, '+' => sub { $_[0] }, 'bool' => sub { 1 };
    sub new { my ($class, %args) = @_; my $self = bless { %args }, $class; return $self }
    sub number { $_[0]->{number} }
    sub to_string { my $self = shift; return "Order #" . $self->number }
    sub SUPER_demo { my $self = shift; return $self->SUPER::new() }
    sub can_demo { return Order->can('new') && Order->isa('Base') && UNIVERSAL::isa([], 'ARRAY') }
}
package main;
my $order = Order->new(number => 7);
my $class = 'Order';
my $dyn = $class->new(number => 8);
my $meth = 'number';
my $val2 = $order->$meth();
my $cr = $order->can('number');
say $order->$cr;
say Order::->new->number;
say ref($order), ' ', blessed($order), ' ', reftype($order);
tie my %tied, 'Tie::StdHash';

# ── I/O, formats, special variables ──
open(my $fh, '<', $0) or die "Cannot open: $!";
open(FH, '>', '/dev/null') || die;
binmode(STDOUT, ':encoding(UTF-8)');
my @lines = <$fh>;
close($fh);
print STDERR "to stderr\n";
print {*STDOUT} "glob print\n";
printf STDOUT "%s\n", $0;
say for @ARGV;
say "$0 $$ $@ $! $/ $\\ $; $& $` $' $+ @ARGV %ENV $ENV{HOME} $^O $^W $1";
my @sorted = sort { $a <=> $b } (3, 1, 2);
my @mapped = map { $_ * 2 } grep { $_ % 2 } 1 .. 10;
my @mapped2 = map +( $_ => 1 ), qw(a b);
my %seen; my @uniq = grep { !$seen{$_}++ } qw(a b a);
my ($r) = reverse 1 .. 3;
my $joined = join ', ', map { sprintf '%02d', $_ } sort { $b <=> $a } keys %hash;
my @spliced = splice(@array, 1, 2, 'x', 'y');
my $exists = exists $hash{name} && defined $hash{name} && delete $hash{name};
my ($d1, $d2) = (each %hash);
local $SIG{__WARN__} = sub { print "warn: @_" };
local $SIG{ALRM} = 'IGNORE';
local $ENV{PATH} = '/usr/bin';
my $lc = lc('ABC') . uc('abc') . lcfirst('ABC') . ucfirst('abc') . fc('ABC') . length('abc') . substr('abcdef', 1, 3) . index('abc', 'b') . rindex('abcb', 'b');
my $time = strftime('%Y-%m-%d', localtime(0));
my $dumper = Dumper(\%hash);

format STDOUT_TOP =
Number  Total   Status
------  ------  ------
.
format STDOUT =
@<<<<<  @##.##  @>>>>>
$scalar, $scalar, $scalar
.

# ── More Perl: globs, pack, lvalues, special blocks and rarely used forms ──
our (@ISA2, %SEEN, $LOCAL_VAR);
*alias = \&describe;
*PI_ALIAS = \3.14159;
local *STDOUT_COPY;
my $glob_ref = \*STDOUT;
my $stdin_line = <STDIN>;
my @glob_files = <*.pl>;
my @glob_files2 = glob('*.{pl,pm}');
my $diamond = <<>>;
my $pack = pack('A3 n C*', 'abc', 258, 1, 2, 3);
my @unpacked = unpack('A3 n C*', $pack);
my $vec = vec(my $bits_v = '', 3, 1);
my $sprintf_v = sprintf('%vd', '1.22.333');
my $lc_sort = join ',', sort { lc($a) cmp lc($b) or $a cmp $b } qw(b A a B);
my $sort_sub = sub { $a <=> $b };
my @sorted_by = sort $sort_sub 3, 1, 2;
my @rev_sorted = reverse sort { $a <=> $b } 1 .. 5;
my $str_repeat = '-' x 20;
my @list_repeat = (1, 2) x 3;
my ($x, $y) = (10, 20);
($x, $y) = ($y, $x);
my $chop = 'abc'; chop $chop; chomp(my $chomped = "line\n");
my $lcx = lc $chop . uc $chop;
my $ternary_chain = $x < 5 ? 'low' : $x < 15 ? 'mid' : 'high';
my $unless_else = do { unless ($x) { 'zero' } else { 'nonzero' } };
my $complex_slice = { map { $_ => 1 } qw(a b) }->{a};
my ($aa, $bb) = @{[ 1, 2 ]};
my %inverse = reverse %hash;
my @pairs = %hash{qw(name)};
my %idx = %array[0, 1];
my $exists_arr = exists $array[0];
delete local $hash{temp};
my $sprintf_pos = sprintf('%2$s %1$s', 'world', 'hello');
my $tr_range = ($x =~ tr/0-9//);
my $nested_data = { list => [1, 2, { deep => [3, 4] }], code => sub { 42 } };
my $deep = $nested_data->{list}[2]{deep}[-1];
my $code_call = $nested_data->{code}->();
my $chain = $nested_data->{list}->[0] + $$nested_data{list}[1];
my @copy = @{ $nested_data->{list} }[0, 1];
my ($first_key) = sort keys %{ $nested_data };
print "ref types: ", join(',', map { ref } (\1, [], {}, sub {}, \\1, qr/x/, \*STDOUT)), "\n";
print "chained: ", (1 < 2) ? "yes" : "no", "\n";
printf("%s has %d chars\n", $_, length) for qw(apple pear);
print "sum: ${\ sum0(1 .. 4)}\n";
print "time: @{[ scalar localtime(0) ]}\n";
my $lvalue_substr = 'hello world'; substr($lvalue_substr, 0, 5) = 'HELLO';
my $four_arg = 'hello'; substr($four_arg, 0, 1, 'J');
my $local_time = join '-', (localtime)[5, 4, 3];
my $sprintf_list = sprintf '%s-%s', split /,/, 'a,b';
my $wantarray_ctx = sub { wantarray }->();
my $str_inc = 'aa9'; $str_inc++;
my ($min2) = sort { $a <=> $b } 3, 1, 2;
my $quotelike = join '|', q/slash/, q#hash#, q!bang!, qq|pipe|, qw<angle>, q[square];
my $m_delims = ('abc' =~ m!b!) . ('abc' =~ m#b#) . ('abc' =~ m,b,) . ('abc' =~ m'b') . ('abc' =~ m[b]);
(my $s_delims = 'abc') =~ s!b!B! ; $s_delims =~ s#B#b#; $s_delims =~ s{b}[B]; $s_delims =~ s(B)<b>;
my $tr_ret_r = ($s_delims =~ tr/a-c/A-C/r);
my $subst_expr = 'a1b2' =~ s/(\d)/$1*2/ger;
my $named_cap = 'k=v' =~ /(?<key>\w)=(?<val>\w)/ ? "$+{key}:$+{val}" : '';
my $branch_reset = 'ab' =~ /(?|(a)|(b))/;
my $recursion = '((()))' =~ /^(\((?1)*\))$/;
my $cond_re = 'ab' =~ /^(a)?(?(1)b|c)$/;
my $possessive = 'aaa' =~ /a++a/;
my $atomic = 'aaab' =~ /(?>a+)b/;
my $inline_mod = 'ABC' =~ /(?i)abc/;
my $comment_re = 'abc' =~ /a(?#comment)b/;
my $verbs = 'abc' =~ /a(*SKIP)(*FAIL)|b/;
my $unicode_prop = "\x{263A}" =~ /\p{So}|\p{IsAlpha}|\P{L}|\X/;
my $anchors = 'abc' =~ /\Aabc\z|\Aabc\Z|^abc$|\Gabc|\babc\B/;
my $mods = 'a b' =~ /a b/xx && 'a' =~ /A/i && "a\nb" =~ /a.b/s && "a\nb" =~ /^b/m && 'a' =~ /a/o && 'a' =~ /a/a && 'a' =~ /a/u && 'a' =~ /a/l && 'a' =~ /a/n && 'a' =~ /a/p;
# ── Special blocks, pragmas and misc ──
use integer; no integer;
use bigint; no bigint;
use lib '/opt/lib';
use vars qw($legacy_var);
use if $] > 5.010, 'feature', 'say';
use overload; no overload;
use fields qw(a b);
use sort 'stable';
use locale; no locale;
use open qw(:std :utf8);
use autodie;
use Carp qw(croak carp confess);
use Time::HiRes qw(time sleep);
use Getopt::Long;
use File::Spec::Functions qw(catfile);
use Storable qw(dclone);
use Encode qw(encode decode);
use JSON::PP;
BEGIN { unshift @INC, '.' }
sub with_attr :lvalue { $lvalue_substr }
sub with_attrs :method :prototype($) { $_[0] }
my sub lexical_sub ($v) { $v * 2 }
sub context_demo { return unless defined wantarray; return wantarray ? 'list' : 'scalar' }
sub recursion_demo { my $n = shift; return __SUB__->($n - 1) if $n > 0; return 0 }
say __PACKAGE__, ' ', __FILE__, ' ', __LINE__, ' ', __SUB__ // 'nosub';
tie my @tied_arr, 'Tie::StdArray';
untie @tied_arr;
dbmopen(my %dbm, '/tmp/db', 0644);
local $SIG{INT} = \&handler;
sub handler { die "interrupted\n" }
srand(42); my $rnd = int(rand(10));
sleep 0;
select(STDERR); $| = 1; select(STDOUT);
my $sprintf_big = sprintf('%.15g', 1/3);
lock($counter);
require 5.006;
use 5.010_001;
no strict 'refs';
*{"main::dyn_$_"} = sub { $_ } for qw(a b);
use strict 'refs';
format_demo() if 0;
sub format_demo { write }
__PACKAGE__->can('describe');

my $revenue = sum0 map { $_->{total} } grep { $_->{status} eq 'paid' } @orders;
printf "%d orders, revenue %.2f, largest #%d\n", scalar @orders, $revenue,
    (sort { $b->{total} <=> $a->{total} } @orders)[0]{number};

for my $status (sort keys %by_status) {
    print "  $status: $by_status{$status}\n";
}

1;

__DATA__
# number,total,status
1,120.50,paid
2,42,pending
3,0,cancelled
