#!/usr/bin/env swift
// swift-tools-version: 6.0
// swiftlint:disable file_length

// ── Comments ──
// Line comment: warehouse inventory model in Swift.
/* Block comment
   /* nested block comments are legal in Swift */
   still inside the outer comment. */
/// Documentation comment for a declaration.
/// - Parameter sku: the stock keeping unit.
/// - Returns: a label.
/// - Throws: ``InventoryError`` when the sku is unknown.
/** Block documentation comment.
    - Note: Markdown works in doc comments. */
// MARK: - Section marker
// TODO: persist the ledger
// FIXME: rounding in the average
// !NOTE: pragma-style marker

// ── Imports ──
import Foundation
import Dispatch
import struct Foundation.URL
import class Foundation.JSONDecoder
@preconcurrency import os
@_exported import Darwin

// ── Compiler directives ──
#if os(macOS) && !targetEnvironment(macCatalyst)
let platform = "macOS"
#elseif os(Linux) || os(Windows)
let platform = "other desktop"
#else
let platform = "unknown"
#endif

#if swift(>=5.9) && canImport(Foundation)
let modern = true
#endif

#if DEBUG
let isDebug = true
#else
let isDebug = false
#endif

#warning("Showcase file: not production code")

// ── Literals ──
let decimal = 1_000_000
let hex = 0xFF_EC
let octal = 0o755
let binary = 0b1010_1010
let float = 3.14159
let exponent = 1.5e-3
let hexFloat = 0x1.8p3
let boolTrue = true, boolFalse = false
let nothing: Int? = nil
let character: Character = "é"
let emoji = "🏭"
let simple = "plain string"
let escapes = "tab\t newline\n quote\" backslash\\ null\0 unicode\u{1F3ED} \u{e9}"
let interpolated = "total \(decimal + 1) of \(simple.uppercased()) and \(String(format: "%.2f", float))"
let rawString = #"raw "quotes" and \n kept, interpolation \#(decimal)"#
let rawMulti = ##"""
    double-hash raw multi-line: \##(decimal) and "#" fine
    """##
let multiline = """
    Warehouse report
      indented line
    Escaped quote: \"
    Interpolation: \(decimal)
    Line continuation \
    joined.
    """
let regex = /(?<sku>[A-Z]{3})-(?<num>\d+)/
let extendedRegex = #/
    (?<prefix> [A-Z]+ )  # letters
    -
    (?<digits> \d+ )     # digits
    /#
let array = [1, 2, 3]
let dictionary = ["a": 1, "b": 2]
let tuple = (sku: "ABC-1", quantity: 12, 3.5)
let range = 1...10, halfOpen = 0..<5, oneSided = ...5
let keyPath = \Item.name
let selector = #selector(NSObject.description)
let fileInfo = (#file, #line, #function, #column, #fileID, #filePath)

// ── Type aliases ──
typealias SKU = String
typealias Handler<T> = @Sendable (T) -> Void
typealias Pair<A, B> = (first: A, second: B)

// ── Protocols ──
protocol Describable {
    associatedtype ID: Hashable
    var id: ID { get }
    var summary: String { get set }
    static var kind: String { get }
    func describe() -> String
    mutating func rename(to name: String)
    init(id: ID)
}

protocol Stockable: AnyObject, Sendable where Self: Describable {
    func restock(by amount: Int) async throws
}

extension Describable {
    func describe() -> String { "\(Self.kind) \(id)" }
}

// ── Enums ──
enum Status: String, CaseIterable, Codable, Sendable {
    case pending, active
    case discontinued = "gone"

    var isLive: Bool {
        switch self {
        case .pending, .active: return true
        case .discontinued: return false
        }
    }
}

enum InventoryError: Error, LocalizedError {
    case unknownSKU(String)
    case outOfStock(sku: String, requested: Int, available: Int)
    case invalidQuantity
    indirect case wrapped(InventoryError)

    var errorDescription: String? {
        switch self {
        case .unknownSKU(let sku): return "Unknown SKU \(sku)"
        case let .outOfStock(sku, requested, available):
            return "\(sku): requested \(requested), only \(available)"
        case .invalidQuantity: return "Invalid quantity"
        case .wrapped(let inner): return inner.errorDescription
        }
    }
}

enum Level: Int, Comparable {
    case low = 1, medium, high
    static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }
}

// ── Structs, property wrappers, result builders ──
@propertyWrapper
struct Clamped<Value: Comparable> {
    private var value: Value
    let range: ClosedRange<Value>

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }

    var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }

    var projectedValue: ClosedRange<Value> { range }
}

@resultBuilder
enum LabelBuilder {
    static func buildBlock(_ parts: String...) -> String { parts.joined(separator: " · ") }
    static func buildOptional(_ part: String?) -> String { part ?? "" }
    static func buildEither(first: String) -> String { first }
    static func buildEither(second: String) -> String { second }
}

struct Item: Describable, Hashable, Codable, Identifiable {
    typealias ID = SKU

    let id: SKU
    var name: String
    @Clamped(0...10_000) var quantity: Int = 0
    var price: Decimal?
    var status: Status = .pending
    private(set) var history: [Int] = []
    fileprivate static let reorderPoint = 25
    static var kind: String { "item" }
    var summary: String { get { "\(name) ×\(quantity)" } set { name = newValue } }

    lazy var label: String = "\(id)-\(name)"

    var isLow: Bool { quantity <= Self.reorderPoint }

    var total: Decimal {
        guard let price else { return 0 }
        return price * Decimal(quantity)
    }

    var observed: Int = 0 {
        willSet { print("will set to \(newValue)") }
        didSet { history.append(oldValue) }
    }

    init(id: SKU) { self.id = id; self.name = id }
    init(id: SKU, name: String, quantity: Int = 0, price: Decimal? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
    }

    mutating func rename(to name: String) { self.name = name }

    mutating func remove(_ amount: Int) throws {
        guard amount > 0 else { throw InventoryError.invalidQuantity }
        guard amount <= quantity else {
            throw InventoryError.outOfStock(sku: id, requested: amount, available: quantity)
        }
        quantity -= amount
    }

    @LabelBuilder func banner(verbose: Bool) -> String {
        name
        "(\(id))"
        if verbose { "qty \(quantity)" }
    }

    subscript(index: Int) -> Int { history[index] }
    subscript(safe index: Int) -> Int? { history.indices.contains(index) ? history[index] : nil }

    static func + (lhs: Item, rhs: Item) -> Item {
        Item(id: lhs.id, name: lhs.name, quantity: lhs.quantity + rhs.quantity)
    }
}

// ── Operators ──
infix operator ~~: ComparisonPrecedence
prefix operator +++
postfix operator ---
precedencegroup StockPrecedence {
    associativity: left
    higherThan: AdditionPrecedence
    lowerThan: MultiplicationPrecedence
}
infix operator <+>: StockPrecedence

func ~~ (lhs: Double, rhs: Double) -> Bool { abs(lhs - rhs) < 0.001 }
prefix func +++ (value: inout Int) -> Int { value += 2; return value }
postfix func --- (value: inout Int) -> Int { defer { value -= 3 }; return value }
func <+> (lhs: Int, rhs: Int) -> Int { lhs + rhs }

// ── Classes ──
class Warehouse: Describable, @unchecked Sendable {
    typealias ID = Int
    let id: Int
    var summary: String = ""
    static var kind: String { "warehouse" }
    private var items: [SKU: Item] = [:]
    weak var delegate: AnyObject?
    unowned let owner: Warehouse?
    final var capacity = 5_000
    class var defaultCapacity: Int { 1_000 }

    required init(id: Int) { self.id = id; self.owner = nil }
    convenience init() { self.init(id: 0) }
    deinit { print("closing warehouse \(id)") }

    func describe() -> String { "warehouse #\(id)" }
    func rename(to name: String) { summary = name }

    @discardableResult
    func add(_ item: Item) -> Bool {
        items.updateValue(item, forKey: item.id) == nil
    }

    func low() -> [Item] { items.values.filter(\.isLow).sorted { $0.quantity < $1.quantity } }
}

final class FrozenWarehouse: Warehouse {
    override func describe() -> String { "frozen " + super.describe() }
    override class var defaultCapacity: Int { 100 }
}

// ── Generics ──
func largest<T: Comparable>(_ values: [T]) -> T? { values.max() }

func merge<K, V, S: Sequence>(_ pairs: S, combine: (V, V) -> V) -> [K: V]
    where S.Element == (K, V), K: Hashable {
    Dictionary(pairs, uniquingKeysWith: combine)
}

struct Stack<Element> {
    private var storage: [Element] = []
    mutating func push(_ element: Element) { storage.append(element) }
    mutating func pop() -> Element? { storage.popLast() }
}

extension Stack: Sequence where Element: Hashable {
    func makeIterator() -> IndexingIterator<[Element]> { storage.makeIterator() }
}

func first<each T>(_ values: repeat each T) -> (repeat each T) { (repeat each values) }
func opaque() -> some Collection { [1, 2, 3] }
func boxed() -> any Describable { Item(id: "ABC-1") }

// ── Extensions ──
extension Item: CustomStringConvertible {
    var description: String { "\(id): \(name) (\(quantity))" }
}

extension Array where Element == Item {
    var totalUnits: Int { reduce(0) { $0 + $1.quantity } }
}

extension String {
    var isSKU: Bool { wholeMatch(of: /[A-Z]{3}-\d+/) != nil }
}

// ── Actors, concurrency ──
actor Ledger {
    private var balances: [SKU: Int] = [:]

    func record(_ sku: SKU, delta: Int) -> Int {
        balances[sku, default: 0] += delta
        return balances[sku] ?? 0
    }

    nonisolated func name() -> String { "ledger" }
}

@MainActor
final class ViewModel {
    var items: [Item] = []
    func refresh() async { items = await fetchItems() }
}

func fetchItems() async -> [Item] {
    try? await Task.sleep(nanoseconds: 1_000_000)
    return [Item(id: "ABC-1", name: "Hammer", quantity: 12)]
}

func load() async throws -> Int {
    async let one = fetchItems()
    async let two = fetchItems()
    let (a, b) = await (one, two)
    return try await withThrowingTaskGroup(of: Int.self) { group in
        group.addTask { a.count }
        group.addTask { b.count }
        return try await group.reduce(0, +)
    }
}

func stream() -> AsyncStream<Int> {
    AsyncStream { continuation in
        for i in 0..<3 { continuation.yield(i) }
        continuation.finish()
    }
}

// ── Closures ──
let double = { (x: Int) -> Int in x * 2 }
let sorted = [3, 1, 2].sorted { $0 < $1 }
let mapped = [1, 2, 3].map { n in n * n }
let shorthand = [1, 2, 3].filter { $0.isMultiple(of: 2) }
let capturing = { [weak delegateObject = Optional<AnyObject>.none, count = 1] in count }
let escaping: @Sendable @escaping () -> Void = {}
func perform(_ work: @autoclosure () -> Int, then done: (Int) -> Void) { done(work()) }

// ── Control flow ──
func control(_ values: [Int?]) throws {
    for case let value? in values where value > 0 {
        print(value)
    }

    outer: for i in 1...3 {
        for j in 1...3 {
            if i * j == 4 { continue outer }
            if i * j > 6 { break outer }
        }
    }

    var n = 0
    while n < 3 { n += 1 }
    repeat { n -= 1 } while n > 0

    switch values.first ?? nil {
    case .none: print("empty")
    case 0?: print("zero")
    case let x? where x < 0: print("negative")
    case 1...9?: print("small")
    case .some(let x) where x.isMultiple(of: 2): fallthrough
    default: print("other")
    }

    if let first = values.first, let value = first, value > 0 { print(value) }
    else if case .some(nil) = values.first { print("nil element") }
    else { print("none") }

    guard !values.isEmpty else { return }
    defer { print("done") }

    let result = if n > 0 { "positive" } else { "zero" }
    let kind = switch n { case 0: "zero"; default: "other" }
    _ = (result, kind)
}

// ── Error handling ──
func handleErrors() {
    do {
        var item = Item(id: "ABC-1", name: "Hammer", quantity: 3)
        try item.remove(5)
    } catch InventoryError.outOfStock(let sku, _, let available) where available < 5 {
        print("low on \(sku)")
    } catch let error as InventoryError {
        print(error.localizedDescription)
    } catch {
        print("unexpected: \(error)")
    }

    let value = try? Int("12")
    let forced = try! Int("34") ?? 0
    let optional: Int? = nil
    _ = (value, forced, optional ?? 0)
}

// ── Operators and expressions ──
func expressions(a: Int, b: Int, c: Int?) {
    var x = a + b - a * b / (b + 1) % 7
    x += 1; x -= 1; x *= 2; x /= 2; x %= 100
    x &= 0xFF; x |= 0x0F; x ^= 0x01; x <<= 2; x >>= 1
    let bits = (a & b) | (a ^ b) | ~a
    let shifted = a << 3 >> 1 &<< 2 &>> 1
    let wrapping = a &+ b &- a &* b
    let logic = a > b && b >= 0 || !(a == b) && a != b
    let ternary = a > b ? a : b
    let coalesced = c ?? 0
    let chained = c?.description.count
    let forcedValue = c!
    let cast = a as Double? as Any
    let conditional = cast as? Int
    let forcedCast = cast as! Optional<Int>
    let isInt = cast is Int
    let identical = (Item.self === Item.self)
    let inRange = (1...10).contains(a) ~= true
    let pattern = ~=("a", "a")
    let keyPathValue = Item(id: "X")[keyPath: \.name]
    let pointer = withUnsafePointer(to: x) { $0.pointee }
    _ = (bits, shifted, wrapping, logic, ternary, coalesced, chained, forcedValue,
         conditional, forcedCast, isInt, identical, inRange, pattern, keyPathValue, pointer)
}

// ── Attributes ──
@available(macOS 14, iOS 17, *)
@available(*, deprecated, message: "Use load() instead")
@inlinable @inline(__always)
public func legacy() -> Int { 1 }

@frozen public struct Point { public var x = 0.0, y = 0.0 }
@objc(WarehouseObject) @objcMembers final class Bridge: NSObject {
    @objc dynamic var count = 0
    @IBOutlet weak var label: AnyObject?
    @IBAction func tap(_ sender: Any) {}
    @NSManaged var managed: String
}

@usableFromInline internal let cached = 1
@_silgen_name("c_function") func cFunction() -> Int32
@discardableResult @Sendable func sendable() -> Int { 1 }
enum Context { @TaskLocal static var requestID = 0 }

// ── Access control and modifiers ──
open class Base {}
public final class Facade { public init() {} }
internal struct Hidden {}
package func packageScoped() {}
private enum Secret { case a }
fileprivate func helper() {}
public private(set) var counter = 0
nonisolated(unsafe) var unsafeGlobal = 0

// ── Macros ──
@attached(member) macro Observable() = #externalMacro(module: "Macros", type: "ObservableMacro")
@freestanding(expression) macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "Macros", type: "StringifyMacro")
let (value, code) = #stringify(1 + 2)

// ── Main ──
@main
struct App {
    static func main() async throws {
        var item = Item(id: "ABC-1", name: "Hammer", quantity: 12, price: 12.5)
        item.observed = 3
        print(item, platform, modern, isDebug, item.banner(verbose: true))
        for await value in stream() { print(value) }
        _ = try await load()
    }
}

// ── More declarations ──
struct FileHandleBox: ~Copyable {
    var descriptor: Int32
    consuming func close() { _ = consume self }
    borrowing func peek() -> Int32 { descriptor }
    deinit { print("closing \(descriptor)") }
}

@dynamicMemberLookup
struct Bag {
    var storage: [String: Int] = [:]
    subscript(dynamicMember key: String) -> Int? { storage[key] }
    func callAsFunction(_ key: String) -> Int { storage[key, default: 0] }
}

@dynamicCallable
struct Caller {
    func dynamicallyCall(withArguments args: [Int]) -> Int { args.reduce(0, +) }
}

protocol Shape { func area() -> Double }
struct Square: Shape { var side: Double; func area() -> Double { side * side } }
func makeShape() -> some Shape { Square(side: 2) }
func total(_ shapes: [any Shape]) -> Double { shapes.map { $0.area() }.reduce(0, +) }
func transform(_ value: inout Int, by f: (Int) throws -> Int) rethrows { value = try f(value) }
func isolatedWork(on actor: isolated Ledger) async { _ = await actor.name() }
func sendIt(_ work: sending Item) {}
func borrow(_ value: borrowing Item, take other: consuming Item) {}

extension Item: ExpressibleByStringLiteral {
    init(stringLiteral value: String) { self.init(id: value) }
}

extension Collection where Element: Numeric {
    func sum() -> Element { reduce(0, +) }
}

class Node<T> {
    var value: T
    var next: Node<T>?
    weak var previous: Node<T>?
    init(_ value: T) { self.value = value }
    deinit {}
}

enum Result2<Success, Failure: Error> {
    case success(Success), failure(Failure)
}

enum Planet: Int, CaseIterable {
    case mercury = 1, venus, earth
    static let home = Planet.earth
    mutating func advance() { self = .venus }
}

// ── Availability and misc statements ──
func availability() {
    if #available(macOS 14, iOS 17, *) { print("modern") }
    if #unavailable(watchOS 10) { print("old watch") }
    precondition(true, "never fails")
    assert(1 + 1 == 2)
    assertionFailure("unreachable")
    fatalError("stop")
}

func inoutDemo() {
    var counter = 0
    func bump(_ n: inout Int) { n += 1 }
    bump(&counter)
    let tupleSwap = { (a: inout Int, b: inout Int) in (a, b) = (b, a) }
    var x = 1, y = 2
    tupleSwap(&x, &y)
    let optionalChain: [Int]? = [1, 2, 3]
    print(optionalChain?.first ?? 0, optionalChain?.map { $0 * 2 } ?? [])
    let closureWithCapture = { [counter] in counter + 1 }
    let unsafe = unsafe_ptr()
    _ = (closureWithCapture(), unsafe)
}
func unsafe_ptr() -> UnsafeMutablePointer<Int> { .allocate(capacity: 1) }

#Preview { Text("Preview macro") }
@Observable final class Model { var count = 0 }
@Test func addition() { #expect(1 + 1 == 2) }
@Suite struct Tests { @Test(arguments: [1, 2]) func param(_ n: Int) { #require(n > 0) } }
typealias Callback2 = @convention(c) (Int32) -> Void
let existential: any Equatable.Type = Int.self
let metatype = type(of: existential)
let dynamicSelf = Int.self
let initializer = Item.init(id:)
let methodRef = Item.rename(to:)
let unwrapped = { (value: Int?) -> Int in guard let value else { return 0 }; return value }
let stringIndex = "hello".firstIndex(of: "l")
let sliced = "hello"[..<"hello".index(after: "hello".startIndex)]
let multiLineChain = [1, 2, 3]
    .map { $0 + 1 }
    .filter { $0 > 2 }
    .reduce(into: [Int]()) { $0.append($1) }
