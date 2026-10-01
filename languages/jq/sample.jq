#!/usr/bin/env jq -nf
# ── Comments ──
# Line comment; jq has no block comments.
# TODO: stream large inputs with --stream
# FIXME: s are treated as UTC

# ── Directives ──
module {name: "warehouse", version: "1.0"};
import "lib/helpers" as helpers;
include "lib/constants";
import "data/defaults" as $defaults;

# ── Function definitions ──
def money: (. * 100 | round) / 100;
def addvalue(f): f as $x | map(. + $x);
def inc(n; by): n + by;
def fac: if . <= 1 then 1 else . * (. - 1 | fac) end;
def zip_with($a; $b; f): [range(0; [$a, $b | length] | min)] | map(f($a[.]; $b[.]));
def revenue_by_status:
  group_by(.status)
  | map({ key: .[0].status, value: (map(.total) | add | money) })
  | from_entries;

# ── Literals and numbers ──
def literals: {
  integer: 42,
  negative: -17,
  float: 3.14159,
  exponent: 6.022e23,
  small: 1E-9,
  nothing: null,
  yes: true,
  no: false,
  not_a_number: nan,
  infinite: infinite,
  neg_infinite: -infinite,
  list: [1, 2, 3, "four", null],
  empty_list: [],
  empty_obj: {}
};

# ── Strings ──
def strings: [
  "plain",
  "escapes: \" \\ \/ \b \f \n \r \t é",
  "interpolation: \(1 + 2) and \("nested \("deep")")",
  "unicode Zürich → 東京 ✓",
  @base64 "encoded \(.name)",
  @uri "https://example.com/?q=\(.q)",
  @csv "\([1, "two", 3.5])",
  @tsv "\(["a", "b"])",
  @html "<b>\(.html)</b>",
  @sh "echo \(.cmd)",
  @json "value: \(.)",
  @text "text \(.)",
  ("dGVzdA==" | @base64d)
];

# ── Object construction and paths ──
def shape: {
  sku,
  "quoted key": .qty,
  (.dynamic | tostring): 1,
  $__loc__,
  total: (.qty * .price),
  "interp \(.sku)": true,
  @base64 "k": 1,
  nested: { a: { b: [1, 2, 3] } }
};

def access:
  .sku, .["sku"], ."sku", .a.b.c, .a?.b?, .[0], .[-1], .[2:5], .[:3], .[-2:],
  .[], .[]?, ..,  .. | numbers,
  .items[] | .sku,
  .["a","b"],
  getpath(["a","b"]),
  paths, path(.a[0].b),
  to_entries, with_entries(.value += 1), del(.a), delpaths([["a"]]),
  setpath(["a"]; 1), has("a"), (keys | length), keys_unsorted;

# ── Operators ──
def operators:
  (1 + 2 - 3 * 4 / 5 % 6),
  (.a // "default"),
  (.a == 1 and .b != 2 or (.c < 3 and .d >= 4 | not)),
  (.a |= . + 1), (.a += 1), (.a -= 1), (.a *= 2), (.a /= 2), (.a %= 3), (.a //= 0),
  ([1, 2] + [3]), ({"a": 1} * {"b": 2}), ("abc" * 2), ("a,b" / ","),
  (.a, .b),
  (.a | .b | .c),
  (. as [$first, $second] | $first),
  (. as {sku: $s, qty: $q} | $s),
  (. as {$sku, qty: [$one]} | $sku),
  (. as [$a] ?// $a | $a),
  .a = 1,
  .a?,
  -.a,
  (try error("x") catch .),
  (.a | tostring | ascii_downcase | ltrimstr("x") | rtrimstr("y") | test("^a.*z$"; "ix"));

# ── Control flow ──
def control:
  if . > 100 then "big"
  elif . > 10 then "medium"
  else "small"
  end,
  (if . then 1 end),
  (try error({code: 1}) catch .code),
  (.[] | select(.qty > 0)),
  (reduce .[] as $item (0; . + $item.qty)),
  (foreach .[] as $item (0; . + $item.qty; {running: .})),
  (foreach range(5) as $i (0; . + $i)),
  (label $out | foreach .[] as $x (0; . + $x; if . > 10 then ., break $out else . end)),
  (limit(3; .[])), first(.[]), until(. > 100; . * 2), while(. < 100; . * 2),
  (recurse(.children[]?)), (recurse(.[]?; . != null)),
  [range(10)], [range(0; 10; 2)], [range(10; 0; -3)],
  (.[] as $x | $x * 2),
  ([.[] | select(.status == "paid" and .total > 100) | .number]),
  (try (1 / 0) catch "division"),
  (.a? // empty),
  error, error("custom"), halt, halt_error, halt_error(1);

# ── Builtins ──
def builtins:
  length, utf8bytelength, not, keys, values, map(.+1), map_values(.+1), add, any, all,
  any(. > 1), all(. > 1), flatten, flatten(1), floor, sqrt, pow(.; 2), log, exp10,
  tostring, tonumber, type, sort, sort_by(.a), group_by(.a), min, max, min_by(.a), max_by(.a),
  unique, unique_by(.a), reverse, contains("x"), inside("xyz"), startswith("a"), endswith("z"),
  split(", "), join("-"), ascii_upcase, explode, implode, ltrimstr("a"), trim, ltrim, rtrim,
  indices(1), index("a"), rindex("a"), combinations, combinations(2), walk(.),
  transpose, first, last, nth(2), input, inputs, debug, debug("msg"), stderr, input_line_number,
  tojson, fromjson, todate, fromdate, now, strftime("%Y-%m-%dT%H:%M:%SZ"),
  strptime("%Y-%m-%d"), mktime, gmtime, localtime, strflocaltime("%H"), 
  test("a"), match("a"; "g"), capture("(?<n>\\d+)"), scan("\\d+"), splits(", "), sub("a"; "b"), gsub("a"; "b"; "x"),
  env, $ENV.HOME, env.PATH, input_filename,
  tostream, fromstream(tostream), 
  isempty(empty), significand, drem(5; 3), ldexp(1; 2), scalb(1; 2), nearbyint, trunc,
  @base32 "x", abs, have_literal_numbers, have_decnum,
  pick(.a), $__loc__.line, getpath(["y"]), splits("x"; "g"),
  INDEX(.id), IN(1, 2), limit(2; repeat(1));

# ── Rare constructs ──
def nested_defs: def inner($x; f): f + $x; inner(1; 2);
def closure_params(f; g): [f, g];
def keywords_as_keys: {if: 1, then: 2, else: 3, end: 4, and: 5, or: 6, def: 7, reduce: 8, foreach: 9, try: 10, catch: 11, label: 12, import: 13, include: 14, __loc__: 15}
  | .if, .then, .and, .reduce;
def object_forms($x): {$x, "lit", "a b", (1 | tostring): 2, @base64 "k": 3, "\(1+1)": 4, $__loc__, a: 1, b: (2, 3)};
def optional_forms: .a?, .a.b?, .["a"]?, .[0]?, ..?, (.[]? | .x?), (try .a), (try error("x")), .a.[0], .a."b", .a.["c"];
def alt_destructure: . as [$a] ?// {a: $a} ?// $a | $a;
def destructure_deep: . as {a: [$x, {b: $y, $c}], "d": $z, ("e", "f"): $w} | [$x, $y, $c, $z];
def reduce_forms: reduce range(5) as $i (0; . + $i), reduce .[] as [$a, $b] (0; . + $a * $b), foreach .[] as {a: $v} (0; . + $v), foreach range(3) as $i ([]; . + [$i]; length);
def limits: limit(0; 1), first(range(10)), last(range(10)), nth(5; range(10)), until(. > 3; . + 1), skip(1; .[]), tojson, @json, ltrimstr("a");
def paths_family: paths(type == "number"), path(..), pick(.a.b), getpath(["a"]) as $v | del(.a, .b), to_entries, from_entries, with_entries(select(.value > 1)), delpaths([["a"]]), tostream, input_line_number;
def numbers_forms: 1, 1.5, .5, 1e3, 1E-3, 1.5e+3, 100000000000000000000, -1, - 1, 1 - 1, 0.1 + 0.2, infinite, -infinite, nan, (nan | isnan), (1 | isinfinite), (1 | isnormal), 3 % -2, 5 / 2, 5 // 2;
def string_forms: "tab\tnewline\n\"quote\" backslash\\ slash\/ \u00e9 \ud83d\udce6", "\(1)\(2)", @text "x", @json "x\(.)", @html "<\(.)>", @uri "\(.)", @csv "\(.)", @tsv "\(.)", @sh "\(.)", @base64 "\(.)", @base64d "\(.)", @base32 "\(.)", @base32d "\(.)";
def string_funcs: ascii_downcase, ascii_upcase, ltrimstr("a"), rtrimstr("b"), trimstr("c"), startswith("a"), endswith("b"), test("a"), splits("a"), sub("(?<x>a)"; "\(.x)"), @sh, tojson, fromjson, tostring, tonumber, utf8bytelength, explode, implode, split("a"; "g"), ltrimstr("x"), getpath([]), splits("b"; null);
def sql_style: INDEX(.[]; .id), IN(.[]; 1, 2), INDEX({id: 1}; .id);
def misc_builtins: env, $ENV, input_filename, now, "2026-01-31T00:00:00Z" | fromdateiso8601, todateiso8601, getpath(["a"]), halt_error(5)?, builtins, input_line_number, splits("x"), ltrimstr("y"), significand, gamma, lgamma, tgamma, lgamma_r, frexp, modf, trunc, round, ceil, floor, fabs, sqrt, pow(2; 3), log2, exp2, getpath(["z"]), error(null)?, tojson, limit(1; empty), combinations, walk(if type == "number" then . + 1 else . end), env.HOME, splits("a"), ltrimstr("b"), @uri, getpath(["x"]), debug("m"), debug(.), scan("a"; "g"), have_decnum, $__loc__, getpath(["y"]), group_by(.a), unique_by(length), min_by(.a), max_by(.a), flatten(2), add(.[]), any(.[]; . > 1), all(.[]; . > 1), tojson, ltrimstr("c"), @sh;
def comments_cont: 1 # comment with trailing backslash continues in jq 1.7.1+ \
  still a comment
  ;
def pipes_and_alts: (1, 2) as $x | ($x // 3) | . as $y | [$y, ($y | -.), (. as [$q] | $q)?] | (., .) | select(. != null) | try error catch . // empty;
def label_break: label $done | (1, 2, break $done, 3);
def operators_assign: .a |= empty, (.[] += 1), (.a //= 2), (.a |= (. // 3)), (.. |= .), (.a, .b) = 9, (.a = (1, 2)), (.[1:3] = ["x"]), (.[2:4] |= map(. + 1)), del(.[1:3]), (to_entries | map(select(.key != "a")) | from_entries);
def slices: .[1:], .[:-1], .[1:-1], .[-2:], .["a":"c"]?, .[1.5:3.5], (.[1:][1:]);
def formats_inline: @base64 "dGVzdA==\(.)", ("dGVzdA==" | @base64d), ([1, "a"] | @csv, @tsv, @sh), ("é" | @uri), ({"a": "<&>"} | @html "\(.a)");

# ── Main program ──
{
  count: length,
  revenue: revenue_by_status,
  top: ([ .[] | .items[] ] | group_by(.sku) | map({ sku: .[0].sku, qty: (map(.quantity) | add) }) | sort_by(-.qty) | .[:3]),
  paid: [ .[] | select(.status == "paid" and .total > 100) | .number ]
}
| ., ( .paid[] | "\(.)" )
