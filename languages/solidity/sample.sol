// Solidity 0.8.30 — syntax showcase (EVM version prague by default)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
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
        selfdestruct(treasury); // deprecated since 0.8.18 (EIP-6780) but still valid
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

// ── Custom errors in require (0.8.26+), and revert forms ──
error Insufficient(uint256 needed, uint256 have);
contract Reverts {
    function checks(uint256 have) external pure {
        require(have > 0, Insufficient(1, have));
        require(have > 1, "plain reason string");
        require(have > 2);
        if (have > 100) revert Insufficient({needed: 1, have: have});
        if (have > 200) revert("reason");
        if (have > 300) revert();
        assert(have != 400);
    }
}

// ── Storage layout specifier (0.8.29+) ──
contract Positioned layout at 0x1000 {
    uint256 public first;
    mapping(address => uint256) public balances;
}

// ── User-defined value types and operators on them ──
type Price is uint128;
using {addPrice as +, subPrice as -, mulPrice as *, divPrice as /, modPrice as %, negPrice as -, notPrice as ~, andPrice as &, orPrice as |, xorPrice as ^, eqPrice as ==, nePrice as !=, ltPrice as <, lePrice as <=, gtPrice as >, gePrice as >=} for Price global;

function addPrice(Price a, Price b) pure returns (Price) { return Price.wrap(Price.unwrap(a) + Price.unwrap(b)); }
function subPrice(Price a, Price b) pure returns (Price) { return Price.wrap(Price.unwrap(a) - Price.unwrap(b)); }
function mulPrice(Price a, Price b) pure returns (Price) { return Price.wrap(Price.unwrap(a) * Price.unwrap(b)); }
function divPrice(Price a, Price b) pure returns (Price) { return Price.wrap(Price.unwrap(a) / Price.unwrap(b)); }
function modPrice(Price a, Price b) pure returns (Price) { return Price.wrap(Price.unwrap(a) % Price.unwrap(b)); }
function negPrice(Price a) pure returns (Price) { return Price.wrap(0 - Price.unwrap(a)); }
function notPrice(Price a) pure returns (Price) { return Price.wrap(~Price.unwrap(a)); }
function andPrice(Price a, Price b) pure returns (Price) { return Price.wrap(Price.unwrap(a) & Price.unwrap(b)); }
function orPrice(Price a, Price b) pure returns (Price) { return Price.wrap(Price.unwrap(a) | Price.unwrap(b)); }
function xorPrice(Price a, Price b) pure returns (Price) { return Price.wrap(Price.unwrap(a) ^ Price.unwrap(b)); }
function eqPrice(Price a, Price b) pure returns (bool) { return Price.unwrap(a) == Price.unwrap(b); }
function nePrice(Price a, Price b) pure returns (bool) { return Price.unwrap(a) != Price.unwrap(b); }
function ltPrice(Price a, Price b) pure returns (bool) { return Price.unwrap(a) < Price.unwrap(b); }
function lePrice(Price a, Price b) pure returns (bool) { return Price.unwrap(a) <= Price.unwrap(b); }
function gtPrice(Price a, Price b) pure returns (bool) { return Price.unwrap(a) > Price.unwrap(b); }
function gePrice(Price a, Price b) pure returns (bool) { return Price.unwrap(a) >= Price.unwrap(b); }

// ── Libraries attached to types, and using ... for * ──
library Bits {
    function isSet(uint256 self, uint8 index) internal pure returns (bool) {
        return (self >> index) & 1 == 1;
    }
    function sum(uint256[] storage values) internal view returns (uint256 total) {
        for (uint256 i = 0; i < values.length; i++) total += values[i];
    }
}

// ── Inheritance: multiple bases, overrides, constructors, super ──
contract BaseA {
    uint256 public a;
    constructor(uint256 _a) { a = _a; }
    function who() public pure virtual returns (string memory) { return "A"; }
    modifier guarded() virtual { _; }
}
contract BaseB {
    function who() public pure virtual returns (string memory) { return "B"; }
}
contract Derived is BaseA, BaseB {
    using Bits for uint256;
    using Bits for *;
    uint256[] private values;

    constructor(uint256 x) BaseA(x) {}

    function who() public pure override(BaseA, BaseB) returns (string memory) {
        return string.concat("D:", super.who());
    }
    modifier guarded() override { require(a > 0); _; }
    function total() external view guarded returns (uint256) { return Bits.sum(values); }
    function bit(uint256 v) external pure returns (bool) { return v.isSet(3); }
}

// ── Calls: named arguments, value/gas options, interface selectors, try new ──
contract Calls {
    event Done(uint256 id);
    function target(uint256 id, address who, bool flag) public payable returns (uint256) {
        emit Done(id);
        return flag && who != address(0) ? id : 0;
    }
    function named() external payable returns (uint256) {
        uint256 r = this.target{value: msg.value}({flag: true, id: 7, who: msg.sender});
        r += target(1, address(this), false);
        bytes4 sel = this.target.selector;
        bytes4 isel = ILedger.restock.selector;
        bytes32 topic = Done.selector;
        bytes4 err = Insufficient.selector;
        bytes memory c = abi.encodeWithSelector(sel, 1, address(0), true);
        bytes memory d = abi.encodeWithSignature("target(uint256,address,bool)", 1, address(0), true);
        bytes memory e = abi.encodeCall(this.target, (1, address(0), true));
        (uint256 id, address who) = abi.decode(c, (uint256, address));
        isel; topic; err; d; e; id; who;
        return r;
    }
    function creator() external returns (address) {
        try new Ledger(payable(msg.sender)) returns (Ledger created) {
            return address(created);
        } catch {
            return address(0);
        }
    }
    function create2Addr() external view returns (address) {
        bytes memory code = type(Ledger).creationCode;
        bytes memory runtime = type(Derived).runtimeCode;
        string memory nm = type(Ledger).name;
        nm; runtime;
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), bytes32(0), keccak256(code))))));
    }
}

// ── Data locations, slices, members, globals ──
contract Data {
    struct Point { int128 x; int128 y; }
    enum Level { Low, Mid, High }
    Level public constant DEFAULT_LEVEL = Level.Mid;
    Point[] public points;
    mapping(address user => mapping(uint256 id => Point)) public byUser;
    bytes32 constant SALT = keccak256(abi.encodePacked("salt"));

    function slice(bytes calldata payload) external pure returns (bytes memory head, bytes4 sig) {
        head = payload[0:4];
        sig = bytes4(payload[:4]);
        bytes calldata tail = payload[4:];
        tail;
    }
    function members() external view returns (uint256) {
        uint256 b = address(this).balance + address(this).code.length;
        bytes32 h = address(this).codehash;
        uint256 lo = uint256(type(Level).min) + uint256(type(Level).max);
        int256 mn = type(int128).min;
        h; mn;
        return b + lo + block.number + block.timestamp + block.gaslimit + block.basefee + block.blobbasefee + block.prevrandao + uint256(uint160(block.coinbase)) + block.chainid;
    }
    function transaction() external payable returns (address, address, uint256, bytes4, bytes memory, uint256, bytes32) {
        return (msg.sender, tx.origin, msg.value, msg.sig, msg.data, gasleft(), blobhash(0));
    }
    function copyAround(Point memory p) internal returns (Point storage s) {
        points.push(p);
        s = points[points.length - 1];
        Point memory m = Point({x: 1, y: 2});
        Point memory n = Point(3, 4);
        s.x = m.x + n.y;
        delete points[0];
        points.pop();
    }
    function bitwise(uint8 a) external pure returns (uint8) {
        return ~a ^ (a << 1) | (a >> 1) & 0x0f;
    }
    function shifts(int256 a) external pure returns (int256) {
        return (a >> 2) << 1;
    }
    function literals() external pure returns (uint256 r, bytes memory b, string memory s) {
        r = 0xff_ff == 0 ? 1e3 : 2 ** 8;
        r += 1 gwei + 2 ether + 3 wei + 4 seconds + 5 minutes + 6 hours + 7 days + 8 weeks;
        b = hex"cafe_babe";
        s = "multiple "
            "adjacent "
            "strings";
        s = unicode"emoji 🎉";
    }
}

// ── Inline assembly (Yul): functions, loops, switch, memory and transient ops ──
contract Yul {
    /// @solidity memory-safe-assembly
    function ops(uint256 x) external returns (uint256 r) {
        assembly {
            function double(v) -> w { w := mul(v, 2) }
            function pair(v) -> lo, hi { lo := and(v, 0xff) hi := shr(8, v) }
            let a, b := pair(x)
            let c := 0
            for { let i := 0 } lt(i, 3) { i := add(i, 1) } {
                if eq(i, 1) { continue }
                if gt(i, 2) { break }
                c := add(c, double(i))
            }
            switch c
            case 0 { r := a }
            case 1 { r := b }
            default { r := add(a, b) }
            tstore(0, r)
            let t := tload(0)
            let p := mload(0x40)
            mcopy(p, add(p, 0x20), 0x20)
            mstore(p, true)
            r := add(r, t)
            r := add(r, sload(0))
            sstore(1, false)
            {
                let scoped := 1
                r := add(r, scoped)
            }
        }
    }
    function slots() external view returns (uint256 slot, uint256 offset) {
        assembly {
            slot := _data.slot
            offset := _data.offset
        }
    }
    bytes32 private _data;
}

// ── Receive, fallback and payable variants ──
contract Wallet {
    event Received(address from, uint256 amount);
    receive() external payable { emit Received(msg.sender, msg.value); }
    fallback() external payable {}
    function withdraw(address payable to, uint256 amount) external {
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "send failed");
    }
    function pay(address payable to) external payable {
        to.transfer(msg.value);
        require(to.send(0), "send");
    }
}

// ── Interface inheritance with nested types, errors and events ──
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface ISupplier is IERC165 {
    enum Rating { Poor, Fair, Good }
    struct Quote { uint256 price; Rating rating; }
    error NoQuote(bytes32 sku);
    event Quoted(bytes32 indexed sku, Quote quote);
    function quote(bytes32 sku) external view returns (Quote memory);
}
