# @version ^0.4.0
# Vyper: a per-user counter with an owner-only reset.

owner: public(immutable(address))
MAX: constant(uint256) = 1_000_000
counts: HashMap[address, uint256]

event Bumped:
    who: indexed(address)
    by: uint256
    total: uint256

@deploy
def __init__():
    owner = msg.sender

@external
def bump(by: uint256):
    next: uint256 = self.counts[msg.sender] + by
    assert next <= MAX, "too high"
    self.counts[msg.sender] = next
    log Bumped(who=msg.sender, by=by, total=next)

@external
@view
def get(who: address) -> uint256:
    return self.counts[who]

@external
def reset(who: address):
    assert msg.sender == owner, "not owner"
    self.counts[who] = 0
