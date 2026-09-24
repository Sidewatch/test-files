// D: ranges, templates and a struct with a contract.
import std.stdio;
import std.algorithm : filter, map, sum;
import std.range : iota;

struct Account {
    string owner;
    double balance = 0;

    invariant { assert(balance >= 0, "balance never negative"); }

    void deposit(double amount)
    in (amount > 0)
    do { balance += amount; }
}

T clamp(T)(T value, T lo, T hi) pure nothrow @safe {
    return value < lo ? lo : value > hi ? hi : value;
}

void main() {
    auto acct = Account("Ada");
    acct.deposit(120.5);
    immutable evens = iota(1, 20).filter!(n => n % 2 == 0).map!(n => n * n).sum;
    writefln("%s has %.2f; even squares sum to %d", acct.owner, acct.balance, evens);
    writeln(clamp(42, 0, 10));   // 10
}
