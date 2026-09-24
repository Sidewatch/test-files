#!/usr/bin/env raku
# Raku: grammars, a class with a typed attribute, and a hyper-operator.

grammar OrderLine {
    token TOP    { <number> ',' <total> ',' <status> }
    token number { \d+ }
    token total  { \d+ [ '.' \d+ ]? }
    token status { 'paid' | 'pending' | 'cancelled' }
}

class Order {
    has Int    $.number is required;
    has Rat    $.total  = 0;
    has Str    $.status = 'pending';

    method describe(--> Str) { "#{ $!number } { $!status } { $!total.fmt('%.2f') }" }
}

my @orders = gather for "1,120.50,paid", "2,42,pending", "3,0,cancelled" -> $line {
    with OrderLine.parse($line) -> $m {
        take Order.new(number => +$m<number>, total => $m<total>.Rat, status => ~$m<status>);
    }
}

.describe.say for @orders;
my $revenue = [+] @orders.grep(*.status eq 'paid').map(*.total);
say "revenue: $revenue";
say (1..5) »**» 2;   # (1 4 9 16 25)
