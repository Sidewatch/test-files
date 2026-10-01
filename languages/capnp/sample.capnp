# Cap'n Proto 1.2 schema language — syntax showcase
# Cap'n Proto schema for the warehouse message bus.
# Comments start with a hash. TODO: version the envelope.
@0xd4a7c1b2e3f40518;

# ── Annotations on the file ──────────────────────────────────────────
using Cxx = import "/capnp/c++.capnp";
$Cxx.namespace("warehouse::bus");

using Java = import "/capnp/java.capnp";
$Java.package("com.example.bus");
$Java.outerClassname("BusProto");

using Common = import "common.capnp";
using import "types.capnp".Timestamp;

# ── Constants ────────────────────────────────────────────────────────
const maxItems :UInt32 = 1_000;
const defaultTopic :Text = "stock.updates";
const pi :Float64 = 3.14159;
const smallFloat :Float32 = 1.5e-3;
const hexValue :UInt64 = 0xdeadbeef;
const negative :Int32 = -42;
const flag :Bool = true;
const defaultSku :Data = 0x"a1 b2 c3";
const sampleList :List(Int32) = [1, 2, 3];
const samplePoint :Point = (x = 1.0, y = 2.0);
const bigInf :Float64 = inf;
const notANumber :Float32 = nan;

# ── Enums ────────────────────────────────────────────────────────────
enum Priority {
  low @0;
  normal @1;
  high @2;
  urgent @3;
}

enum Category $Cxx.name("ItemCategory") {
  tools @0;
  parts @1;
  fasteners @2;
}

# ── Structs ──────────────────────────────────────────────────────────
struct Point {
  x @0 :Float64;
  y @1 :Float64;
}

struct Envelope {
  id @0 :UInt64;
  topic @1 :Text = "default";
  priority @2 :Priority = normal;
  sentAt @3 :Int64;
  payload :union {
    text @4 :Text;
    bytes @5 :Data;
    none @6 :Void;
    item @7 :Item;
  }
  headers @8 :List(Header);
  tags @9 :List(Text) = ["a", "b"];
  matrix @10 :List(List(Float32));
  signature @11 :Data = 0x"deadbeef";
  position @12 :Point = (x = 0.0, y = 0.0);
  anyPointer @13 :AnyPointer;
  anyStruct @14 :AnyStruct;
  anyList @15 :AnyList;
  capability @16 :Capability;

  struct Header {
    key @0 :Text;
    value @1 :Text;
  }

  enum Kind {
    request @0;
    response @1;
  }

  const defaultKind :Kind = request;
}

struct Item {
  sku @0 :Text;
  quantity @1 :UInt32;
  price @2 :Float64;
  category @3 :Category;
  dimensions :group {
    width @4 :Float32;
    height @5 :Float32;
    depth @6 :Float32;
  }
  flags @7 :List(Bool);
  union {
    perishable @8 :Bool;
    shelfLifeDays @9 :UInt16;
  }
}

struct Wrapper(T, U) {
  first @0 :T;
  second @1 :U;
}

struct Pair {
  value @0 :Wrapper(Text, Int32);
}

# ── Interfaces ───────────────────────────────────────────────────────
interface Bus {
  publish @0 (envelope :Envelope) -> (accepted :Bool);
  subscribe @1 (topic :Text, priority :Priority = normal) -> (stream :Subscription);
  stats @2 () -> (published :UInt64, dropped :UInt64);
  ping @3 () -> ();
  lookup @4 (sku :Text) -> import "inventory.capnp".Item;
  batch @5 (envelopes :List(Envelope)) -> stream;
}

interface Subscription {
  next @0 () -> (envelope :Envelope);
  cancel @1 ();
}

interface Admin extends(Bus) {
  purge @0 (topic :Text) -> (count :UInt32);
}

interface Generic(T) {
  get @0 () -> (value :T);
  set @1 (value :T) -> ();
}

# ── Annotations ──────────────────────────────────────────────────────
annotation doc(*) :Text;
annotation unit(field) :Text;
annotation version(file, struct) :UInt16;
annotation deprecated(enumerant, method) :Void;

struct Measured {
  weight @0 :Float64 $unit("kg");
  length @1 :Float64 $unit("m") $doc("Overall length");
}

$version(2);

# ── Further constructs ──────────────────────────────────────────────
using import "/capnp/persistent.capnp".Persistent;
using Rpc = import "/capnp/rpc.capnp";
using Schema = import "/capnp/schema.capnp";
using Nested = Envelope.Header;
using Alias = Priority;

$Cxx.allowCancellation;

# Every primitive type, with defaults
struct Primitives {
  void @0 :Void;
  boolean @1 :Bool = true;
  int8 @2 :Int8 = -128;
  int16 @3 :Int16 = -32768;
  int32 @4 :Int32 = -2147483648;
  int64 @5 :Int64 = -9223372036854775808;
  uint8 @6 :UInt8 = 255;
  uint16 @7 :UInt16 = 0xffff;
  uint32 @8 :UInt32 = 0o777;
  uint64 @9 :UInt64 = 0b1010;
  float32 @10 :Float32 = 1.5e-3;
  float64 @11 :Float64 = -2.5E+10;
  text @12 :Text = "escapes: \n \t \" \\ \x41 \u00e9 \101 \'";
  data @13 :Data = 0x"01 02 ff";
  textList @14 :List(Text) = ["a", "b", "c"];
  nestedList @15 :List(List(Int32)) = [[1, 2], [3]];
  structList @16 :List(Point) = [(x = 1.0, y = 2.0), (x = 3.0, y = 4.0)];
  enumList @17 :List(Priority) = [low, high];
  inlineStruct @18 :Point = (x = 1.5, y = -2.5);
  nestedInline @19 :Wrapper(Text, Int32) = (first = "a", second = 2);
  anyPtr @20 :AnyPointer;
}

# Unnamed unions and groups with ordinals
struct Shape {
  area @0 :Float64;
  union {
    circle :group {
      radius @1 :Float64;
    }
    rectangle :group {
      width @2 :Float64;
      height @3 :Float64;
    }
    point @4 :Void;
  }
  union {
    filled @5 :Bool;
    outline @6 :Text;
  }
}

struct Node {
  value @0 :Int64;
  children @1 :List(Node);
  parent @2 :Node;
}

# Generics with bound parameters and brand-aware use
struct Map(Key, Value) {
  entries @0 :List(Entry);
  struct Entry {
    key @0 :Key;
    value @1 :Value;
  }
}

struct TextToInt {
  map @0 :Map(Text, Int32);
}

interface Container(T) {
  put @0 (item :T) -> ();
  get @1 (index :UInt32) -> (item :T);
  size @2 () -> (count :UInt32);
}

interface Repository {
  open @0 (name :Text) -> (container :Container(Item));
  stream @1 (callback :Callback) -> (done :Bool);
  struct Callback {
    notify @0 (item :Item) -> stream;
  }
  const defaultName :Text = "main";
  enum Mode { read @0; write @1; }
  mode @2 () -> (mode :Mode);
}

interface Extended extends(Repository, Admin) {
  reset @0 () -> ();
  fork @1 [T] (seed :T) -> (copy :Container(T));
}

# Annotations with targets
annotation allTargets(*) :Text;
annotation fileOnly(file) :Void;
annotation constAnn(const) :Text;
annotation enumAnn(enum) :Text;
annotation enumerantAnn(enumerant) :Text;
annotation structAnn(struct) :Text;
annotation fieldAnn(field) :Text;
annotation unionAnn(union) :Text;
annotation groupAnn(group) :Text;
annotation interfaceAnn(interface) :Text;
annotation methodAnn(method) :Text;
annotation paramAnn(param) :Text;
annotation annotationAnn(annotation) :Text;

struct Annotated $structAnn("outer") {
  first @0 :Text $fieldAnn("first");
  grouped :group $groupAnn("g") {
    inner @1 :Int32 $fieldAnn("inner");
  }
}
enum Marked $enumAnn("e") {
  one @0 $enumerantAnn("1");
  two @1 $enumerantAnn("2");
}
interface Documented $interfaceAnn("i") {
  call @0 (arg :Text $paramAnn("arg")) -> (ret :Text) $methodAnn("call");
}
const marked :Text = "value" $constAnn("const");

# Field numbers out of order and unions reserving gaps
struct Sparse {
  late @5 :Text;
  early @1 :Text;
  middle @3 :Text;
}
# TODO: add a Cxx.name annotation for every reserved word.

# ── Cap'n Proto 1.x additions ────────────────────────────────────────
using Json = import "/capnp/compat/json.capnp";
using Go = import "/go.capnp";
$Go.package("bus");
$Go.import("example.com/warehouse/bus");

# Embedded file contents (embed reads a file at compile time)
const embeddedText :Text = embed "banner.txt";
const embeddedData :Data = embed "logo.bin";
const embeddedStruct :Item = embed "default-item.bin";

# JSON annotations on fields, structs and enumerants
struct JsonEnvelope {
  id @0 :UInt64 $Json.name("identifier");
  secret @1 :Text $Json.name("shh");
  blob @2 :Data $Json.base64;
  checksum @3 :Data $Json.hex;
  inner @4 :Inner $Json.flatten();
  kind :union $Json.flatten($prefix = "kind_") {
    text @5 :Text;
    count @6 :UInt32 $Json.name("n");
  }
  variant :union $Json.discriminator(name = "type") {
    alpha @7 :Text $Json.name("A");
    beta @8 :Void $Json.name("B");
  }
  struct Inner {
    left @0 :Int32;
    right @1 :Int32;
  }
}

enum Colour {
  red @0 $Json.name("RED");
  green @1 $Json.name("GREEN");
  blue @2;
}

interface Notifier {
  fire @0 (event :Text) -> () $Json.notification;
}

# Methods: streaming, generic methods, named results, imported results
interface Uploader {
  begin @0 (name :Text) -> (sink :Sink);
  interface Sink {
    write @0 (chunk :Data) -> stream;
    done @1 () -> (size :UInt64);
  }
  checksum @1 [Algorithm] (data :Data) -> (digest :Algorithm);
  fetch @2 (path :Text) -> (content :Data, mime :Text);
  noResults @3 (flag :Bool = false);
}

# Struct and interface generics, bound parameters, AnyPointer generics
struct Cache(Key, Value) {
  entries @0 :List(Entry);
  struct Entry {
    key @0 :Key;
    value @1 :Value;
    meta @2 :AnyPointer;
  }
}

interface Store(Key, Value) {
  get @0 (key :Key) -> (value :Value);
  put @1 (key :Key, value :Value) -> ();
  cache @2 () -> (cache :Cache(Key, Value));
}

struct TextStore {
  inner @0 :Store(Text, Data);
  nested @1 :Cache(Text, Cache(UInt32, List(Text)));
}

# Lists of every kind and defaults using each literal form
struct Defaults {
  bools @0 :List(Bool) = [true, false, true];
  floats @1 :List(Float64) = [1.0, -2.5, 3e10, inf, -inf, nan];
  texts @2 :List(Text) = ["one", "two"];
  datas @3 :List(Data) = [0x"01", 0x"02 03"];
  points @4 :List(Point) = [(x = 1.0), (y = 2.0), ()];
  lists @5 :List(List(Text)) = [["a"], [], ["b", "c"]];
  enums @6 :List(Colour) = [red, blue];
  point @7 :Point = (x = 1.0, y = 2.0);
  nestedStruct @8 :Wrapper(Text, Point) = (first = "x", second = (x = 0.0, y = 0.0));
  unionStruct @9 :Shape = (area = 1.0, circle = (radius = 0.5), filled = true);
  emptyStruct @10 :Point = ();
  version @11 :UInt16 = 0x0102;
  mask @12 :UInt32 = 0xFFFF_FFFF;
  big @13 :UInt64 = 18_446_744_073_709_551_615;
  octal @14 :UInt8 = 0o17;
  binary @15 :UInt8 = 0b1111_0000;
}

# Annotation scopes combined, and annotations on annotations
annotation tagged(struct, field, enum, enumerant) :Text;
annotation experimental(*) :Void;
annotation meta(annotation) :Text;
annotation owner(file) :Text $meta("file-level");

$owner("platform team");

struct Combined $tagged("s") $experimental {
  one @0 :Text $tagged("f") $experimental;
  two :group $tagged("g") {
    inner @1 :Text;
  }
}
