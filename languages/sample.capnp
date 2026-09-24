# Cap'n Proto schema for a small message bus.
@0xd4a7c1b2e3f40518;

using Java = import "/capnp/java.capnp";
$Java.package("com.example.bus");

enum Priority {
  low @0;
  normal @1;
  high @2;
}

struct Envelope {
  id @0 :UInt64;
  topic @1 :Text;
  priority @2 :Priority = normal;
  payload :union {
    text @3 :Text;
    bytes @4 :Data;
    none @5 :Void;
  }
  headers @6 :List(Header);

  struct Header {
    key @0 :Text;
    value @1 :Text;
  }
}

interface Bus {
  publish @0 (envelope :Envelope) -> (accepted :Bool);
  subscribe @1 (topic :Text) -> (stream :Subscription);
}

interface Subscription {
  next @0 () -> (envelope :Envelope);
}
