// Apache Thrift 0.22 IDL — syntax showcase
// ── Comments ──
// Apache Thrift IDL: the warehouse inventory service.
# Shell-style comments are accepted as well.
/* Block comment
   spanning lines. */
/**
 * Doc comment (Doxygen style).
 * @param sku the stock keeping unit
 * TODO: version the wire format
 * FIXME: Status needs an UNKNOWN member
 */

// ── Includes and namespaces ──
include "shared.thrift"
include "types/common.thrift"
cpp_include "<unordered_map>"

namespace java com.example.inventory
namespace py example.inventory
namespace cpp example.inventory
namespace go example.inventory
namespace js example.inventory
namespace rb Example.Inventory
namespace php Example.Inventory
namespace perl Example::Inventory
namespace swift ExampleInventory
namespace netstd Example.Inventory
namespace * example.inventory
// deprecated forms, still accepted by the compiler:
cpp_namespace example.legacy
php_namespace Example\Legacy

// ── Constants ──
const i32 REORDER_POINT = 25
const i64 MAX_SKUS = 0x10000
const i16 SMALL = -7
const byte FLAG = 0x7F
const double SCALE = 1.5e-3
const double PI = 3.14159
const double BIG = 1E+10
const bool ENABLED = true
const bool DISABLED = false
const string NAME = "inventory"
const string ESCAPED = "tab\t newline\n quote\" backslash\\ unicodeé"
const string SINGLE = 'single "quoted"'
const binary BLOB = "raw"
const list<i32> PORTS = [8080, 8443, 9090]
const set<string> REGIONS = ["eu-west", "us-east", "eu-west"]
const map<string, i32> LIMITS = { "small": 10, "medium": 100, "large": 1000 }
const list<map<string, list<i32>>> NESTED = [{ "a": [1, 2], "b": [] }]
const Status DEFAULT_STATUS = Status.PENDING
const shared.Priority DEFAULT_PRIORITY = shared.Priority.NORMAL

// ── Typedefs ──
typedef string OrderId
typedef i64 Timestamp
typedef map<string, string> Tags
typedef list<LineItem> LineItems
typedef shared.Money Money

// ── Enums ──
enum Status {
  PENDING = 1,
  PAID = 2,
  SHIPPED,
  CANCELLED = 0x10,
}

enum Level {
  LOW,
  MEDIUM,
  HIGH
}

// ── Structs ──
struct LineItem {
  1: required string sku,
  2: i32 quantity = 1,
  3: double unitPrice,
  4: optional string note = "none",
  5: optional list<string> tags,
}

struct Order {
  1: required OrderId id,
  2: i64 number,
  3: Status status = Status.PENDING,
  4: LineItems items,
  5: optional string note,
  6: Tags tags,
  7: set<i32> flags = [],
  8: map<string, list<i32>> history,
  9: optional binary signature,
  10: Timestamp placedAt,
  11: bool gift = false,
  12: i16 priority = 5,
  13: byte checksum,
  14: double total = 0.0,
  15: optional Money amount,
  16: shared.SharedStruct meta,
  17: list<list<string>> grid,
}

struct Empty {}

struct WithAnnotations {
  1: string name (cpp.type = "std::string", python.immutable = "true"),
  2: i32 count = 0 (go.tag = "json:\"count\""),
} (cpp.noncopyable, java.final = "")

// ── Unions ──
union Payload {
  1: string text,
  2: i64 number,
  3: LineItem item,
  4: binary raw,
}

// ── Exceptions ──
exception NotFound {
  1: OrderId id,
  2: string message,
}

exception OutOfStock {
  1: required string sku,
  2: i32 requested,
  3: i32 available,
}

exception InvalidRequest {
  1: string reason (message = "true"),
}

// ── Services ──
service Orders {
  /** Fetch one order. */
  Order getOrder(1: OrderId id) throws (1: NotFound nf),

  list<Order> listOrders(1: Status status, 2: i32 limit = 50, 3: i32 offset = 0),

  OrderId placeOrder(1: Order order) throws (1: OutOfStock oos, 2: InvalidRequest bad),

  void ping(),

  oneway void cancel(1: OrderId id),

  map<string, i32> counts(1: list<Status> statuses),

  set<string> skus(1: Level level = Level.MEDIUM),

  Payload convert(1: Payload input) throws (1: InvalidRequest bad) (priority = "high"),

  binary export(1: OrderId id; 2: string format),

  Money total(1: list<LineItem> items) throws (1: NotFound nf; 2: InvalidRequest bad);
}

service AdminOrders extends Orders {
  void purge(1: Timestamp before),
  bool reindex() throws (1: InvalidRequest bad)
}

service Streaming extends shared.SharedService {
  list<Order> watch(1: Status status),
}

service Interactions {
  void begin(),
  i32 next() throws (1: NotFound nf),
}

// ── Container annotations, deprecated keywords ──
typedef map<string, i32> (cpp.template = "std::unordered_map") CountMap
typedef list<i32> (cpp.template = "std::list") IntList
typedef i32 (cpp.type = "uint32_t") Counter

const LineItem DEFAULT_ITEM = { "sku": "A-1", "quantity": 2, "unitPrice": 9.99 }

senum Color { "red", "green" } // deprecated
typedef slist LegacyList // deprecated

service Legacy {
  async void notify(1: OrderId id), // deprecated alias of oneway
  void a(), void b(); // comma and semicolon separators mix
}

struct XsdLegacy {
  1: optional string name xsd_optional,
  2: optional string nick xsd_nillable,
} // xsd_* are deprecated

// ── Reserved-looking identifiers and types in one place ──
struct AllTypes {
  1: bool b,
  2: byte by,
  3: i8 i8field,
  4: i16 i16field,
  5: i32 i32field,
  6: i64 i64field,
  7: double d,
  8: string s,
  9: binary bin,
  10: uuid id,
  11: list<i32> l,
  12: set<i32> st,
  13: map<i32, string> m,
}
