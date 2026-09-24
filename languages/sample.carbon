// Carbon: a generic pair and a function that swaps it.
package Sample api;

import Core library "io";

class Pair(T:! type) {
  var first: T;
  var second: T;

  fn Make(a: T, b: T) -> Pair(T) {
    return {.first = a, .second = b};
  }

  fn Swapped[self: Self]() -> Pair(T) {
    return {.first = self.second, .second = self.first};
  }
}

fn Sum(n: i32) -> i32 {
  var total: i32 = 0;
  var i: i32 = 1;
  while (i <= n) {
    total += i;
    ++i;
  }
  return total;
}

fn Run() -> i32 {
  let p: Pair(i32) = Pair(i32).Make(3, 4);
  let q: Pair(i32) = p.Swapped();
  Core.Print(q.first + Sum(10));   // 4 + 55
  return 0;
}
