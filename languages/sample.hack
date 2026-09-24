<?hh // strict
// Hack: a typed repository with async loading and a shape.

namespace App\Inventory;

type StockRow = shape('sku' => string, 'qty' => int, 'price' => float);

final class Repository {
  const int REORDER_POINT = 25;

  public function __construct(private AsyncMysqlConnection $conn) {}

  public async function lowStock(): Awaitable<vec<StockRow>> {
    $result = await $this->conn->queryf(
      'SELECT sku, qty, price FROM stock WHERE qty < %d',
      self::REORDER_POINT,
    );
    $rows = vec[];
    foreach ($result->mapRows() as $row) {
      $rows[] = shape('sku' => $row['sku'], 'qty' => (int)$row['qty'], 'price' => (float)$row['price']);
    }
    return $rows;
  }

  public static function totalValue(vec<StockRow> $rows): float {
    return \HH\Lib\C\reduce($rows, ($acc, $r) ==> $acc + $r['qty'] * $r['price'], 0.0);
  }
}
