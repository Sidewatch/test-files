// Apache Thrift: the orders service.
namespace java com.example.orders
namespace py example.orders

const i32 REORDER_POINT = 25
typedef string OrderId

enum Status { PENDING = 1, PAID = 2, SHIPPED = 3, CANCELLED = 4 }

struct LineItem {
  1: required string sku,
  2: i32 quantity = 1,
  3: double unitPrice,
}

struct Order {
  1: required OrderId id,
  2: i64 number,
  3: Status status = Status.PENDING,
  4: list<LineItem> items,
  5: optional string note,
  6: map<string, string> tags,
}

exception NotFound { 1: OrderId id, 2: string message }

service Orders {
  Order getOrder(1: OrderId id) throws (1: NotFound nf),
  list<Order> listOrders(1: Status status, 2: i32 limit = 50),
  oneway void cancel(1: OrderId id),
}
