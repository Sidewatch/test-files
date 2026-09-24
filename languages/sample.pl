#!/usr/bin/env perl
# Perl: parse an orders CSV, total the paid ones, print a report.
use strict;
use warnings;
use List::Util qw(sum0 max);

my $REORDER_POINT = 25;
my %by_status;
my @orders;

while (my $line = <DATA>) {
    chomp $line;
    next if $line =~ /^\s*(#|$)/;
    my ($number, $total, $status) = split /,/, $line;
    push @orders, { number => $number, total => $total, status => $status };
    $by_status{$status}++;
}

my $revenue = sum0 map { $_->{total} } grep { $_->{status} eq 'paid' } @orders;
printf "%d orders, revenue %.2f, largest #%d\n", scalar @orders, $revenue,
    (sort { $b->{total} <=> $a->{total} } @orders)[0]{number};

for my $status (sort keys %by_status) {
    print "  $status: $by_status{$status}\n";
}

sub describe { my ($o) = @_; return "#$o->{number} ($o->{status})" }

__DATA__
# number,total,status
1,120.50,paid
2,42,pending
3,0,cancelled
