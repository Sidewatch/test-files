// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title A per-user counter with an owner-only reset.
contract Counter {
    address public immutable owner;
    uint256 public constant MAX = 1_000_000;
    mapping(address => uint256) private counts;

    event Bumped(address indexed who, uint256 by, uint256 total);
    error TooHigh(uint256 requested);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() { owner = msg.sender; }

    function bump(uint256 by) external {
        uint256 next = counts[msg.sender] + by;
        if (next > MAX) revert TooHigh(next);
        counts[msg.sender] = next;
        emit Bumped(msg.sender, by, next);
    }

    function get(address who) external view returns (uint256) { return counts[who]; }

    function reset(address who) external onlyOwner { delete counts[who]; }
}
