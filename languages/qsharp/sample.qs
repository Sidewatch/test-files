// Q# (Microsoft QDK 1.x, Std library) — syntax showcase
// ── Comments ──
// Q# showcase: quantum routines for a warehouse slot-assignment search.
// TODO: add noise models. FIXME: the oracle ignores bin capacity.

/// # Summary
/// Doc comments use triple slashes with Markdown headings.
///
/// # Description
/// Prepares |Φ+⟩ on two qubits and measures both.
///
/// # Input
/// ## qubits
/// The register to act on.
///
/// # Output
/// A pair of measurement results.
///
/// # Remarks
/// See [Microsoft.Quantum.Canon](https://example.com/docs).
///
/// # Example
/// ```qsharp
/// let (a, b) = BellPair();
/// ```

namespace Warehouse.Quantum {
    // ── Imports ──
    open Std.Intrinsic;
    open Std.Canon;
    open Std.Measurement;
    open Std.Math;
    open Std.Arrays as Arrays;
    open Std.Convert as Conv;
    open Std.Diagnostics;
    import Std.Random.*;
    import Std.Arrays.Mapped, Std.Arrays.Fold;
    import Std.Convert.IntAsDouble as ToDouble;

    // ── Types ──
    struct Slot { Aisle : Int, Shelf : Int }
    struct Named { Label : String, Position : Slot }
    struct Stock { Sku : String, Qty : Int, Weight : Double }
    newtype Legacy = (Id : Int, Name : String); // deprecated: use struct

    // ── Literals ──
    function Literals() : Unit {
        let integer = 42;
        let negative = -7;
        let hex = 0xFF;
        let octal = 0o755;
        let binary = 0b1010;
        let big = 123456789012345678901234567890L;
        let bigHex = 0xDEADBEEFL;
        let float = 3.14;
        let exponent = 1.5e-3;
        let exp2 = 6.022E23;
        let flag = true;
        let no = false;
        let unit = ();
        let text = "plain string with \"escapes\" \\ and \n newline \t tab";
        let interpolated = $"agree {integer} times {1 + 2} at {float}";
        let nested = $"outer {Message("inner")} and {{braces}}";
        let zero = Zero;
        let one = One;
        let paulis = [PauliI, PauliX, PauliY, PauliZ];
        let range = 0 .. 2 .. 10;
        let reverse = 10 .. -1 .. 0;
        let open = 1 ...;
        let rangeOnly = ... 5;
        let empty = [];
        let tuple = (1, "two", 3.0, (true, ()));
        let array = [1, 2, 3, 4];
        let sized = [0, size = 5];
        let slice = array[1 .. 2];
        let lastItem = array[Length(array) - 1];
        let sliceRest = array[2 ...];
        let sliceRev = array[...-1...];
    }

    // ── Operators ──
    function Operators(a : Int, b : Int, x : Double, p : Bool, q : Bool) : Unit {
        let arithmetic = a + b - a * b / a % b;
        let power = a ^ 2;
        let powerD = x ^ 2.0;
        let bitwise = (a &&& b) ||| (a ^^^ b) <<< 2 >>> 1;
        let bitNot = ~~~a;
        let comparison = a < b and a <= b or a > b and a >= b;
        let equality = a == b and a != b;
        let logical = not p or (p and q);
        let ternary = p ? a | b;
        let nested = p ? (q ? 1 | 2) | 3;
        let update = [1, 2, 3] w/ 1 <- 20;
        let multiUpdate = [1, 2, 3] w/ 0 <- 10 w/ 2 <- 30;
        mutable counter = 0;
        set counter += 1;
        set counter -= 1;
        set counter *= 2;
        set counter /= 2;
        set counter %= 3;
        set counter ^= 2;
        set counter &&&= 1;
        set counter |||= 2;
        set counter ^^^= 3;
        set counter <<<= 1;
        set counter >>>= 1;
        mutable flag = true;
        set flag and= false;
        set flag or= true;
        mutable list = [1];
        set list += [2];
        mutable text = "a";
        set text += "b";
        let slot = new Slot { Aisle = 1, Shelf = 2 };
        let copied = new Slot { ...slot, Aisle = 5 };
        let item = new Named { Label = "x", Position = slot }.Position.Aisle;
    }

    // ── Functions ──
    function Factorial(n : Int) : Int {
        mutable result = 1;
        for i in 2 .. n {
            set result *= i;
        }
        return result;
    }

    function Agreement(samples : (Result, Result)[]) : Double {
        mutable agree = 0;
        for (x, y) in samples {
            if x == y { set agree += 1; }
        }
        return IntAsDouble(agree) / IntAsDouble(Length(samples));
    }

    function Compose<'A, 'B, 'C>(f : ('B -> 'C), g : ('A -> 'B)) : ('A -> 'C) {
        return x -> f(g(x));
    }

    function Twice<'T>(op : ('T -> 'T), x : 'T) : 'T {
        return op(op(x));
    }

    function WithLambdas() : Int {
        let add = (a, b) -> a + b;
        let inc = x -> x + 1;
        let partial = add(1, _);
        let mapped = Arrays.Mapped(x -> x * 2, [1, 2, 3]);
        return Twice(inc, partial(2));
    }

    // ── Operations ──
    operation BellPair() : (Result, Result) {
        use (a, b) = (Qubit(), Qubit());
        H(a);
        CNOT(a, b);
        let results = (M(a), M(b));
        ResetAll([a, b]);
        return results;
    }

    operation AllocationForms() : Unit {
        use q = Qubit();
        use qs = Qubit[5];
        use (x, y) = (Qubit(), Qubit[2]);
        use anc = Qubit() {
            X(anc);
            Reset(anc);
        }
        borrow helper = Qubit();
        borrow helpers = Qubit[2] {
            X(helpers[0]);
        }
        Reset(q);
        ResetAll(qs);
    }

    operation Controlled_Ops(control : Qubit, target : Qubit) : Unit is Adj + Ctl {
        within {
            H(control);
        } apply {
            CNOT(control, target);
        }
    }

    operation BodySpecs(q : Qubit) : Unit is Adj + Ctl {
        body (...) {
            Rz(PI() / 4.0, q);
        }
        adjoint (...) {
            Rz(-PI() / 4.0, q);
        }
        controlled (cs, ...) {
            Controlled Rz(cs, (PI() / 4.0, q));
        }
        controlled adjoint (cs, ...) {
            Controlled Adjoint Rz(cs, (PI() / 4.0, q));
        }
    }

    operation AutoSpecs(q : Qubit) : Unit is Adj {
        body ... { S(q); }
        adjoint auto;
    }

    operation Variants(q : Qubit) : Unit {
        Adjoint X(q);
        Controlled X([q], q);
        Controlled Adjoint X([q], q);
        Adjoint Controlled X([q], q);
        let op = Adjoint H;
        op(q);
    }

    // ── Control flow ──
    operation Search(n : Int) : Int {
        mutable found = -1;
        mutable i = 0;
        while i < n {
            if i == 3 {
                set found = i;
            } elif i > 100 {
                set found = 100;
            } else {
                set i += 1;
            }
        }
        repeat {
            set i -= 1;
        } until i <= 0 fixup {
            set found = 0;
        }
        repeat {
            set i += 1;
        } until i >= 2;
        for item in [1, 2, 3] {
            if item == 2 { return item; }
        }
        for idx in IndexRange([5, 6]) {
            Message($"index {idx}");
        }
        return found;
    }

    operation Failures(n : Int) : Unit {
        if n < 0 {
            fail "negative input";
        }
        Fact(n >= 0, "n must be non-negative");
        EqualityFactI(n, n, "n equals itself");
        let _ = n;
    }

    // ── Further forms ──
    function MoreForms() : Unit {
        // array updates by copy-and-update assignment
        mutable arr = [1, 2, 3];
        set arr w/= 0 <- 10;
        set arr w/= 1..2 <- [20, 30];
        // tuple reassignment and discard
        mutable (a, b) = (1, 2);
        set (a, b) = (b, a);
        let (_, second) = (1, 2);
        // nested lambdas and operation lambdas
        let adder = x -> y -> x + y;
        let applyH = q => H(q);
        let adj = (q => S(q), q => Adjoint S(q));
        // ranges: all forms
        let r1 = 0..5;
        let r2 = 0..2..10;
        let r3 = 5..-1..0;
        let r4 = ...3;
        let r5 = 2...;
        let r6 = ...;
        let r7 = 0..2...;
        let r8 = ...2..10;
        // numeric forms
        let big = 1000000000000L;
        let sci = 1e3;
        let tiny = 1.0E-10;
        let c = Complex(1.0, 2.0);
        let paulis = (PauliI, PauliX, PauliY, PauliZ);
        let results = (Zero, One);
        // types spelled out
        let t1 : Int = 1;
        let t2 : BigInt = 1L;
        let t3 : Double = 1.0;
        let t4 : Bool = true;
        let t5 : String = "s";
        let t6 : Result = Zero;
        let t7 : Pauli = PauliX;
        let t8 : Range = 1..2;
        let t9 : Int[] = [1];
        let t10 : (Int, Bool) = (1, true);
        let t11 : Int[][] = [[1], [2]];
        let t12 : (Int -> Int) = x -> x;
        let t13 : (Qubit => Unit is Adj + Ctl) = q => X(q);
        let t14 : Unit = ();
        let t15 : Complex = Complex(0.0, 1.0);
    }

    function Generic<'T, 'U>(x : 'T, f : 'T -> 'U) : 'U { f(x) }

    operation Intrinsics(q : Qubit) : Unit is Adj + Ctl {
        body intrinsic;
    }

    operation Simulatable(q : Qubit) : Unit is Adj {
        body ... { X(q); }
        adjoint self;
    }

    operation Teleport(msg : Qubit, target : Qubit) : Unit {
        use here = Qubit();
        H(here);
        CNOT(here, target);
        CNOT(msg, here);
        H(msg);
        if M(msg) == One { Z(target); }
        if MResetZ(here) == One { X(target); }
    }

    operation RotationsAndMeasure() : Result[] {
        use qs = Qubit[3];
        Rx(PI() / 2.0, qs[0]);
        Ry(PI() / 4.0, qs[1]);
        Rz(2.0 * PI(), qs[2]);
        ApplyToEach(H, qs);
        ApplyToEachA(T, qs);
        Controlled X([qs[0], qs[1]], qs[2]);
        let r = MeasureEachZ(qs);
        let p = Measure([PauliX, PauliZ], qs[0..1]);
        ResetAll(qs);
        return r + [p];
    }

    // ── Entry point and attributes ──
    @Config(Base)
    internal function Hidden() : Unit {}

    @Test("QuantumSimulator")
    operation TestBell() : Unit {
        let (a, b) = BellPair();
        Fact(a == b, "Bell pair must agree");
    }

    @Unimplemented("Hadamard")
    operation NotYet(q : Qubit) : Unit {}

    @EntryPoint()
    operation Main() : Double {
        let sample = new Stock { Sku = "AC-1001", Qty = 25, Weight = 1.5 };
        Message($"{sample.Sku} x {sample.Qty}");
        mutable samples = [];
        for _ in 1 .. 100 {
            set samples += [BellPair()];
        }
        Message($"agreement: {Agreement(samples)}");
        DumpMachine();
        return Agreement(samples);
    }
    export Main, BellPair, Factorial;
}
