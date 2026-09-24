// Q#: a Bell pair and a measurement loop.
namespace Sample {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Measurement;

    /// # Summary
    /// Prepares |Φ+⟩ on two qubits and measures both.
    operation BellPair() : (Result, Result) {
        use (a, b) = (Qubit(), Qubit());
        H(a);
        CNOT(a, b);
        let results = (M(a), M(b));
        ResetAll([a, b]);
        return results;
    }

    function Agreement(samples : (Result, Result)[]) : Double {
        mutable agree = 0;
        for (x, y) in samples {
            if x == y { set agree += 1; }
        }
        return IntAsDouble(agree) / IntAsDouble(Length(samples));
    }

    @EntryPoint()
    operation Main() : Double {
        mutable samples = [];
        for _ in 1 .. 100 {
            set samples += [BellPair()];
        }
        Message($"agreement: {Agreement(samples)}");
        return Agreement(samples);
    }
}
