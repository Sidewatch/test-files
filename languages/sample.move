/// Move (Aptos/Sui style): a simple counter resource.
module sample::counter {
    use std::signer;

    const E_NOT_INITIALIZED: u64 = 1;
    const MAX: u64 = 1_000_000;

    struct Counter has key {
        value: u64,
        bumps: u64,
    }

    public entry fun init(account: &signer) {
        move_to(account, Counter { value: 0, bumps: 0 });
    }

    public entry fun bump(account: &signer, by: u64) acquires Counter {
        let addr = signer::address_of(account);
        assert!(exists<Counter>(addr), E_NOT_INITIALIZED);
        let c = borrow_global_mut<Counter>(addr);
        c.value = if (c.value + by > MAX) { MAX } else { c.value + by };
        c.bumps = c.bumps + 1;
    }

    #[view]
    public fun value(addr: address): u64 acquires Counter {
        borrow_global<Counter>(addr).value
    }

    #[test(account = @0x1)]
    fun bump_twice(account: &signer) acquires Counter {
        init(account);
        bump(account, 2); bump(account, 3);
        assert!(value(signer::address_of(account)) == 5, 0);
    }
}
