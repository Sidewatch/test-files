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
