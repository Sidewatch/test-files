// A Starknet contract that keeps a per-user counter.
use starknet::ContractAddress;

#[starknet::interface]
trait ICounter<TContractState> {
    fn increment(ref self: TContractState, by: u64);
    fn get(self: @TContractState, user: ContractAddress) -> u64;
}

#[starknet::contract]
mod Counter {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        counts: Map<ContractAddress, u64>,
    }

    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        fn increment(ref self: ContractState, by: u64) {
            assert(by > 0, 'increment must be positive');
            let who = get_caller_address();
            let current = self.counts.entry(who).read();
            self.counts.entry(who).write(current + by);
        }

        fn get(self: @ContractState, user: ContractAddress) -> u64 {
            self.counts.entry(user).read()
        }
    }
}
