# Rego (OPA v1.x, v1 syntax) — syntax showcase
# ── Comments ──
# Rego (Open Policy Agent) showcase: warehouse access and stock policy.
# TODO: load roles from data.roles. FIXME: time zone handling.

# METADATA
# title: Warehouse authorization
# description: Decides who may change stock and cancel orders.
# authors:
# - Policy Team <policy@example.com>
# scope: package
# custom:
#   severity: high

package warehouse.authz

import rego.v1
import data.warehouse.roles
import data.warehouse.limits as limits
import input.user
import future.keywords.in
import future.keywords.every

# ── Defaults ──
default allow := false
default max_quantity := 100
default reasons := []

# ── Constants and literals ──
version := "1.4.0"
tax_rate := 0.075
big := 1e6
negative := -7
hex_like := 255
nothing := null
flag := true
off := false
raw_regex := `^AC-\d{4}$`
escapes := "tab\t newline\n quote\" backslash\\ unicode\u00e9 \u{1F4E6}"
numbers := [1, 2.5, -3, 1e3, 2E-2]
nested := {"sku": "AC-1001", "tags": ["new", "sale"], "dims": {"w": 1, "h": 2}}
a_set := {"admin", "manager", "picker"}
empty_set := set()
empty_obj := {}
empty_arr := []

# ── Rules: complete, partial set, partial object ──
allow if {
    "admin" in user.roles
}

allow if {
    input.action == "cancel"
    input.order.customer_id == user.id
    time.now_ns() - input.order.placed_at_ns < 60 * 60 * 1000000000
}

allow if {
    input.action == "cancel"
    "support" in user.roles
    not shipped
}

allow := true if {
    input.action == "read"
}

shipped if input.order.status == "shipped"

deny_reasons contains "order already shipped" if shipped
deny_reasons contains msg if {
    count(user.roles) == 0
    msg := sprintf("user %v lacks a role", [user.id])
}

deny contains {"reason": reason, "code": 403} if {
    some reason in deny_reasons
}

user_roles[name] := role if {
    some name, role in roles
}

stock_by_sku[sku] := qty if {
    some item in input.stock
    sku := item.sku
    qty := item.quantity
}

# Rule with else
access := "full" if {
    "admin" in user.roles
} else := "limited" if {
    "picker" in user.roles
} else := "none"

# Function rules
double(x) := y if {
    y := x * 2
}

is_low(qty) if qty < limits.reorder_point

tier(spend) := "gold" if spend >= 1000
tier(spend) := "silver" if {
    spend >= 100
    spend < 1000
}
tier(spend) := "bronze" if spend < 100

# ── Operators ──
arithmetic := 1 + 2 - 3 * 4 / 5
modulo := 17 % 5
comparison if {
    1 < 2
    2 > 1
    1 <= 2
    2 >= 1
    1 == 1
    1 != 2
}
assignment := x if {
    x := 5
    y = 5
    x == y
}
set_ops := a_set | {"extra"}
set_and := a_set & {"admin"}
set_minus := a_set - {"admin"}
negation if not input.disabled

# ── Comprehensions and iteration ──
low_stock := {sku | some sku, qty in stock_by_sku; is_low(qty)}
sku_list := [sku | some item in input.stock; sku := item.sku]
qty_by_sku := {sku: qty | some item in input.stock; sku := item.sku; qty := item.quantity}
first_item := input.stock[0]
all_valid if {
    every item in input.stock {
        item.quantity >= 0
        regex.match(`^AC-\d{4}$`, item.sku)
    }
}
any_out if {
    some i
    input.stock[i].quantity == 0
}
wildcard if {
    input.stock[_].sku == "AC-1001"
}
dotted := input.order.lines[0].product["sku"]
some_in if {
    some idx, item in input.stock
    idx > 0
    item.quantity > 0
}

# ── Built-in functions ──
builtins := {
    "count": count(input.stock),
    "sum": sum([1, 2, 3]),
    "max": max([1, 2, 3]),
    "concat": concat(", ", ["a", "b"]),
    "upper": upper("abc"),
    "split": split("a,b", ","),
    "sprintf": sprintf("%s has %d", ["AC-1001", 25]),
    "trim": trim_space("  x  "),
    "contains": contains("hello", "ell"),
    "startswith": startswith("AC-1001", "AC"),
    "regex": regex.match(`^\d+$`, "123"),
    "json": json.marshal({"a": 1}),
    "base64": base64.encode("x"),
    "time": time.format(time.now_ns()),
    "net": net.cidr_contains("192.0.2.0/24", "192.0.2.10"),
    "object": object.get(input, "missing", "default"),
    "is_string": is_string("x"),
    "type": type_name(1),
    "http": http.send({"method": "get", "url": "https://example.com/api"}),
    "units": units.parse_bytes("10MB"),
    "semver": semver.compare("1.0.0", "1.1.0"),
    "uuid": uuid.rfc4122("seed"),
    "glob": glob.match("*.log", [], "app.log"),
}

# ── With keyword and test rules ──
test_admin_allowed if {
    allow with input as {"user": {"id": "u1", "roles": ["admin"]}}
}

test_picker_denied if {
    not allow with input as {"user": {"id": "u2", "roles": ["picker"]}, "action": "cancel"}
        with data.warehouse.limits as {"reorder_point": 10}
}

test_double if double(2) == 4

todo_test_pending if {
    false
}

# ── Entrypoint ──
decision := {
    "allow": allow,
    "reasons": deny_reasons,
    "access": access,
}

# ── Package paths, imports and ref heads ──
# (a file has one `package`; this section shows the other spellings as comments)
#   package warehouse.authz.v2
#   package warehouse["quoted-segment"].v2
#   import data.warehouse.roles as r
#   import input as inp
#   import rego.v1
#   import future.keywords.contains
#   import future.keywords.if
#   import future.keywords.in
#   import future.keywords.every

# Ref heads: dotted and bracketed rule names (v1)
config.limits.max := 100
config.limits.min := 1
config.names[name] := upper(name) if some name in {"a", "b"}
"literal-key".nested := true
pkg.items contains item if some item in [1, 2, 3]

# ── Rules: every head form ──
single_value := 1
single_bool if true
partial_set contains 1
partial_set contains 2 if input.extra
partial_object[key] := value if { some key, value in {"k": "v"} }
object_with_ref.deep[key] := 1 if some key in ["x"]
default constant_false := false
default fn_default(_) := 0
fn_default(x) := x * 2 if x > 0
const_str := "string"
const_obj := {"a": {"b": [1, {"c": null}]}}
multi_line_obj := {
    "first": 1,
    "second": [
        1,
        2,
    ],
}

# Bodies with newline or semicolon separators and unification
semi if { x := 1; y := 2; x < y }
unify if { [a, b] = [1, 2]; a + b == 3 }
unify_object if { {"k": v} = {"k": 1}; v == 1 }
destructure if { [first, second] := [1, 2]; first < second }
shadow if { x := 1; x == 1 }

# else chains with values and bodies
level := "high" if { input.score > 90 } else := "mid" if { input.score > 50 } else := "low"
level_fn(x) := "big" if { x > 10 } else := "small"
bool_else if { input.a } else := false

# Negation, comparison, arithmetic, set operators
negated if not input.flag
neg_compare if not 1 > 2
precedence := (1 + 2) * 3 - 4 / 2 % 3
unary := -(1 + 2)
set_union := {1, 2} | {3}
set_intersect := {1, 2} & {2, 3}
set_diff := {1, 2} - {2}
abs_val := abs(-5)

# ── Iteration forms ──
iter_some if { some i; input.xs[i] == 1 }
iter_some2 if { some i, j; input.grid[i][j] == 1 }
iter_in if { some x in input.xs; x > 1 }
iter_in_idx if { some i, x in input.xs; i > 0; x > 1 }
iter_in_obj if { some k, v in input.obj; k != v }
iter_wild if { input.xs[_] == 1 }
iter_ref if { input.obj[k] == 1; k != "x" }
iter_every if { every x in input.xs { x > 0 } }
iter_every_kv if { every k, v in input.obj { v != k } }
iter_nested if { some x in input.xs; some y in input.ys; x == y }
iter_walk if { walk(input, [path, value]); value == "needle"; path[0] == "a" }
iter_dyn if { name := "xs"; input[name][0] == 1 }
iter_deep if { input.a.b["c-d"][0].e == 1 }

# ── Comprehensions and rule-valued refs ──
arr_comp := [x * 2 | some x in input.xs; x > 0]
set_comp := {x | some x in input.xs; x != 0}
obj_comp := {k: v | some k, v in input.obj; v != null}
nested_comp := [[x, y] | some x in [1, 2]; some y in [3, 4]]
comp_in_call := count([x | some x in input.xs; x > 1])
comp_with_vars := {k | k := sprintf("%d", [x]); some x in [1, 2]}

# ── The with keyword, in every position ──
with_input if { allow with input as {"user": {"roles": ["admin"]}} }
with_data if { allow with data.warehouse.roles as {"admin": ["write"]} }
with_chain if { allow with input.user as {"id": 1} with input.action as "read" with data.limits as {} }
with_func if { fn_default(1) with fn_default as 5 }
with_builtin if { time.now_ns() > 0 with time.now_ns as 1 }

# ── Built-ins: strings, regex, encoding, time, net, crypto, collections ──
more_builtins := {
    "sprintf": sprintf("%s=%d %v %q %5.2f %t", ["a", 1, [1], "q", 2.5, true]),
    "format_int": format_int(255, 16),
    "replace": replace("a-b", "-", "_"),
    "substring": substring("hello", 1, 3),
    "indexof": indexof("hello", "l"),
    "trim": trim("xxhixx", "x"),
    "trim_prefix": trim_prefix("AC-1", "AC-"),
    "lower": lower("ABC"),
    "strings_reverse": strings.reverse("abc"),
    "any_prefix": strings.any_prefix_match("abc", ["a"]),
    "render": strings.render_template("hi {{.n}}", {"n": "x"}),
    "regex_find": regex.find_n(`\d+`, "a1b22", -1),
    "regex_split": regex.split(`,\s*`, "a, b"),
    "regex_replace": regex.replace("a1", `\d`, "#"),
    "regex_subs": regex.find_all_string_submatch_n(`(\w)(\d)`, "a1b2", -1),
    "json_unmarshal": json.unmarshal("{\"a\": 1}"),
    "json_filter": json.filter({"a": 1, "b": 2}, ["a"]),
    "json_patch": json.patch({"a": 1}, [{"op": "add", "path": "/b", "value": 2}]),
    "yaml": yaml.marshal({"a": [1, 2]}),
    "base64url": base64url.encode("x"),
    "hex": hex.encode("x"),
    "urlquery": urlquery.encode_object({"a": "b c"}),
    "sha": crypto.sha256("x"),
    "hmac": crypto.hmac.sha256("msg", "key"),
    "jwt": io.jwt.decode_verify("a.b.c", {"secret": "example-not-a-real-key"}),
    "time_parse": time.parse_rfc3339_ns("2026-01-01T00:00:00Z"),
    "time_add": time.add_date(time.now_ns(), 0, 0, 1),
    "time_clock": time.clock(time.now_ns()),
    "time_weekday": time.weekday(time.now_ns()),
    "duration": time.parse_duration_ns("1h30m"),
    "cidr": net.cidr_contains_matches("192.0.2.0/24", ["192.0.2.1"]),
    "cidr_expand": net.cidr_expand("192.0.2.0/30"),
    "cidr_merge": net.cidr_merge(["192.0.2.0/25", "192.0.2.128/25"]),
    "ip": net.lookup_ip_addr("example.com"),
    "array_concat": array.concat([1], [2]),
    "array_slice": array.slice([1, 2, 3], 0, 2),
    "array_reverse": array.reverse([1, 2]),
    "object_union": object.union({"a": 1}, {"b": 2}),
    "object_remove": object.remove({"a": 1, "b": 2}, ["a"]),
    "object_filter": object.filter({"a": 1, "b": 2}, {"a"}),
    "object_keys": object.keys({"a": 1}),
    "object_subset": object.subset({"a": 1, "b": 2}, {"a": 1}),
    "sort": sort([3, 1, 2]),
    "sets": intersection({{1, 2}, {2, 3}}),
    "union": union({{1}, {2}}),
    "to_number": to_number("42"),
    "numbers": numbers.range(1, 5),
    "round": round(1.5),
    "ceil": ceil(1.2),
    "floor": floor(1.8),
    "product": product([2, 3]),
    "min": min([3, 1]),
    "bits": bits.or(1, 2),
    "types": [is_number(1), is_boolean(true), is_array([]), is_set(set()), is_object({}), is_null(null)],
    "cast": [cast_array([1]), cast_set({1}), cast_string("s"), cast_boolean(true), cast_null(null), cast_object({})],
    "graph": graph.reachable({"a": ["b"], "b": []}, {"a"}),
    "uuid": uuid.parse("6ba7b810-9dad-11d1-80b4-00c04fd430c8"),
    "semver_valid": semver.is_valid("1.0.0"),
    "opa": opa.runtime(),
    "metadata": rego.metadata.rule(),
    "chain": rego.metadata.chain(),
    "parse": rego.parse_module("x.rego", "package x"),
    "env": opa.runtime().env,
    "glob_quote": glob.quote_meta("a*b"),
    "units": units.parse("10Ki"),
    "trace": trace("debugging"),
    "print": print("printed", input),
    "rand": rand.intn("seed", 10),
    "yaml_unmarshal": yaml.unmarshal("a: 1"),
    "is_valid": json.is_valid("{}"),
    "verify": json.verify_schema({"type": "string"}),
    "match_schema": json.match_schema("x", {"type": "string"}),
    "sprintf_vals": sprintf("%v", [input]),
    "internal": internal.print([1]),
}

# ── Test rules: names, with-mocks, and todo ──
test_level_high if level == "high" with input as {"score": 99}
test_level_low if { level == "low" with input as {"score": 1} }
test_not_allowed if not allow with input as {"user": {"roles": []}}
test_set_contains if { partial_set == {1} with input as {"extra": false} }
test_with_mock_time if { time.now_ns() == 1 with time.now_ns as 1 }
test_fn if { fn_default(2) == 4 }
todo_test_later if { false }
test_trace if { trace("tracing"); true }
