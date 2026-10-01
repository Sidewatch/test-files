// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;
pragma experimental SMTChecker;

// ── Comments ──
// Line comment: warehouse inventory ledger on-chain.
/* Block comment
   spanning lines. */
/// @notice Single-line NatSpec comment.
/**
 * @title Warehouse inventory ledger
 * @author Acme Warehousing
 * @notice Tracks stock per SKU and per warehouse.
 * @dev TODO: add role-based access. FIXME: gas for the batch path.
 * @custom:security-contact security@example.com
 */

// ── Imports ──
import "./IERC20.sol";
import {Ownable, Pausable as Paused} from "./Ownable.sol";
import * as Math from "./Math.sol";
import "./Library.sol" as Lib;

// ── File-level definitions ──
uint256 constant MAX_SKUS = 10_000;
bytes32 constant ZERO_HASH = 0x0000000000000000000000000000000000000000000000000000000000000000;
type Quantity is uint128;
using {add as +, sub as -} for Quantity global;

function add(Quantity a, Quantity b) pure returns (Quantity) {
    return Quantity.wrap(Quantity.unwrap(a) + Quantity.unwrap(b));
}

function sub(Quantity a, Quantity b) pure returns (Quantity) {
    return Quantity.wrap(Quantity.unwrap(a) - Quantity.unwrap(b));
}

error Unauthorized(address caller);
error OutOfStock(bytes32 sku, uint256 requested, uint256 available);

enum Status { Pending, Active, Discontinued }

struct Item {
    bytes32 sku;
    uint128 quantity;
    uint64 updatedAt;
    Status status;
    string name;
}

// ── Interface ──
interface ILedger {
    event Restocked(bytes32 indexed sku, uint256 amount);
    function quantityOf(bytes32 sku) external view returns (uint256);
    function restock(bytes32 sku, uint256 amount) external;
}

// ── Library ──
library SafeAmount {
    function checked(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked {
            c = a + b;
        }
        require(c >= a, "overflow");
    }

    function clamp(uint256 x, uint256 hi) internal pure returns (uint256) {
        return x > hi ? hi : x;
    }
}

// ── Abstract contract ──
abstract contract Auditable {
    event Audited(address indexed by, uint256 at);
    function _audit() internal virtual;
    function audited() public view virtual returns (bool);
}

// ── Contract ──
contract Ledger is ILedger, Auditable, Ownable {
    using SafeAmount for uint256;
    using Math for uint256;

    // State variables of every kind
    address public immutable deployer;
    uint256 public constant REORDER_POINT = 25;
    uint256 public totalItems;
    bool private paused = false;
    int256 internal delta = -1;
    bytes4 public selector = bytes4(keccak256("restock(bytes32,uint256)"));
    string public name = "Acme Ledger";
    bytes public blob = hex"deadbeef";
    address payable public treasury;
    mapping(bytes32 => Item) public items;
    mapping(address => mapping(bytes32 => uint256)) private reservations;
    mapping(bytes32 sku => uint256 count) public counts;
    bytes32[] private skus;
    uint256[3] public fixedSlots;
    Status public defaultStatus = Status.Pending;

    // Events and errors
    event Restocked(bytes32 indexed sku, uint256 amount);
    event Shipped(address indexed to, bytes32 indexed sku, uint256 amount, string note);
    event Anonymous(uint256 value) anonymous;

    // Modifiers
    modifier onlyDeployer() {
        if (msg.sender != deployer) revert Unauthorized(msg.sender);
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    modifier validSku(bytes32 sku) {
        require(items[sku].updatedAt != 0, "unknown sku");
        _;
    }

    // Constructor, receive, fallback
    constructor(address payable _treasury) payable Ownable(msg.sender) {
        deployer = msg.sender;
        treasury = _treasury;
    }

    receive() external payable {}

    fallback(bytes calldata data) external payable returns (bytes memory) {
        return data;
    }

    // ── Functions ──
    function restock(bytes32 sku, uint256 amount)
        external
        override
        whenNotPaused
        onlyDeployer
    {
        Item storage item = items[sku];
        if (item.updatedAt == 0) {
            skus.push(sku);
            item.sku = sku;
            item.status = Status.Active;
        }
        item.quantity += uint128(amount);
        item.updatedAt = uint64(block.timestamp);
        totalItems += amount;
        emit Restocked(sku, amount);
    }

    function quantityOf(bytes32 sku) external view override returns (uint256) {
        return items[sku].quantity;
    }

    function ship(address to, bytes32 sku, uint256 amount, string calldata note)
        external
        whenNotPaused
        validSku(sku)
        returns (bool ok, uint256 remaining)
    {
        Item storage item = items[sku];
        if (amount > item.quantity) {
            revert OutOfStock(sku, amount, item.quantity);
        }
        item.quantity -= uint128(amount);
        totalItems -= amount;
        emit Shipped(to, sku, amount, note);
        return (true, item.quantity);
    }

    function lowStock() external view returns (bytes32[] memory low) {
        uint256 n;
        for (uint256 i = 0; i < skus.length; ++i) {
            if (items[skus[i]].quantity <= REORDER_POINT) n++;
        }
        low = new bytes32[](n);
        uint256 j;
        for (uint256 i; i < skus.length; i++) {
            if (items[skus[i]].quantity <= REORDER_POINT) {
                low[j++] = skus[i];
            }
        }
    }

    function _audit() internal override {
        emit Audited(msg.sender, block.timestamp);
    }

    function audited() public view override returns (bool) {
        return totalItems > 0;
    }

    function pause() external onlyOwner { paused = true; }
    function unpause() external onlyOwner { paused = false; }

    // ── Literals ──
    function literals() external pure returns (uint256) {
        uint256 dec = 1_000_000;
        uint256 hexNum = 0xDEAD_BEEF;
        uint256 sci = 2e18;
        uint256 mix = 1.5e3;
        uint8 small = 255;
        int8 negative = -128;
        bool flag = true && !false || (1 < 2);
        address zero = address(0);
        address checksummed = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        bytes1 b = 0xff;
        bytes memory raw = hex"00ff_10";
        string memory plain = "plain string";
        string memory single = 'single "quoted"';
        string memory escapes = "tab\t newline\n quote\" backslash\\ hex\x41 unicodeé";
        string memory uni = unicode"Hello — ✓ 🏭";
        uint256 time = 1 days + 2 hours + 30 minutes + 45 seconds + 1 weeks;
        uint256 money = 1 ether + 5 gwei + 100 wei;
        return dec + hexNum + sci + mix + small + time + money + uint256(uint8(b));
    }

    // ── Expressions and operators ──
    function operators(uint256 a, uint256 b) external pure returns (uint256 r) {
        r = a + b - a * b / (b + 1) % 7;
        r += 1; r -= 1; r *= 2; r /= 2; r %= 100;
        r |= 0x0f; r &= 0xff; r ^= 0x01; r <<= 2; r >>= 1;
        r = (a & b) | (a ^ b) | ~a;
        r = a << 3 >> 1;
        r = a ** 2;
        r = a > b ? a : b;
        bool cmp = a == b || a != b && a <= b || a >= b;
        delete cmp;
        r = (r++) + (++r) + (r--) + (--r);
    }

    // ── Control flow ──
    function control(uint256 n) external pure returns (uint256 total) {
        if (n == 0) {
            return 0;
        } else if (n < 10) {
            total = 1;
        } else {
            total = 2;
        }

        for (uint256 i = 0; i < n; i++) {
            if (i == 3) continue;
            if (i > 8) break;
            total += i;
        }

        uint256 k = n;
        while (k > 0) {
            k /= 2;
            total++;
        }

        do {
            total--;
        } while (total > 100);

        unchecked { total += 1; }
    }

    // ── Error handling ──
    function handling(address target) external returns (uint256) {
        try ILedger(target).quantityOf(ZERO_HASH) returns (uint256 q) {
            return q;
        } catch Error(string memory reason) {
            emit Audited(msg.sender, bytes(reason).length);
        } catch Panic(uint256 code) {
            emit Audited(msg.sender, code);
        } catch (bytes memory) {
            revert("low-level failure");
        }
        require(target != address(0), "zero target");
        assert(totalItems >= 0);
        return 0;
    }

    // ── Low level and assembly ──
    function lowLevel(address payable to, uint256 amount) external onlyDeployer {
        (bool ok, bytes memory data) = to.call{value: amount, gas: 30000}("");
        require(ok, string(data));
        to.transfer(0);
        bool sent = to.send(0);
        (bool ok2, ) = address(this).staticcall(abi.encodeWithSignature("audited()"));
        (bool ok3, ) = address(this).delegatecall(abi.encodeCall(this.pause, ()));
        bytes32 h = keccak256(abi.encodePacked(to, amount, block.number));
        bytes memory packed = abi.encode(h, sent, ok2, ok3);
        (bytes32 decoded, , , ) = abi.decode(packed, (bytes32, bool, bool, bool));
        decoded;
    }

    function assembly_() external view returns (uint256 size) {
        address self = address(this);
        assembly ("memory-safe") {
            size := extcodesize(self)
            let ptr := mload(0x40)
            mstore(ptr, 0x20)
            for { let i := 0 } lt(i, 4) { i := add(i, 1) } {
                mstore8(add(ptr, i), i)
            }
            switch size
            case 0 { size := 1 }
            default { size := add(size, 1) }
            if iszero(size) { revert(0, 0) }
        }
    }

    // ── Globals ──
    function globals() external payable returns (address, uint256, bytes32) {
        return (msg.sender, msg.value + block.chainid + tx.gasprice + gasleft(), blockhash(block.number - 1));
    }

    function creation() external returns (address) {
        Ledger child = new Ledger{salt: bytes32(uint256(1)), value: 0}(treasury);
        return address(child);
    }

    function cleanup() external onlyOwner {
        selfdestruct(treasury);
    }
}

// ── Inheritance, generics-ish and free usage ──
contract Warehouse is Ledger(payable(address(0))) {
    uint256 public constant CAPACITY = 5_000;

    function capacityLeft() public view returns (uint256) {
        return CAPACITY - totalItems;
    }
}

// ── Additional constructs ──
contract Extras {
    uint256 transient lock;
    uint256 public immutable createdAt = block.timestamp;
    bytes32 public constant ROLE = keccak256("ROLE");
    uint256 public maxValue = type(uint256).max;
    uint8 public minValue = type(uint8).min;
    bytes4 public iface = type(ILedger).interfaceId;
    string public label = string.concat("a", "b");
    bytes public joined = bytes.concat(hex"01", hex"02");
    function(uint256) external view returns (uint256) public callback;
    uint256[] public dynamicArray;
    uint256[2][3] public matrix;

    modifier nonReentrant() {
        require(lock == 0, "reentrant");
        lock = 1;
        _;
        lock = 0;
    }

    function virtualFn() public virtual returns (uint256) { return 1; }

    function pureCalc(uint256 x) public pure returns (uint256) {
        return mulmod(addmod(x, 1, 10), 2, 10) + uint256(keccak256(abi.encodePacked(x))) % 7;
    }

    function arrays() public {
        dynamicArray.push(1);
        dynamicArray.push();
        dynamicArray.pop();
        uint256[] memory mem = new uint256[](3);
        mem[0] = 1;
        (uint256 a, uint256 b) = (1, 2);
        (a, b) = (b, a);
        string memory s = "x";
        bytes memory bs = bytes(s);
        bytes1 first = bs[0];
        ecrecover(bytes32(0), 27, bytes32(0), bytes32(0));
        sha256(bs); ripemd160(bs);
        require(gasleft() > 0, "no gas");
        assert(first == 0x78);
    }

    function receive_() external payable nonReentrant {
        emit Transfer(msg.sender, address(this), msg.value);
        payable(msg.sender).transfer(0);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}
