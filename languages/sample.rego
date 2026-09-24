# Rego (Open Policy Agent): who may cancel an order.
package orders.authz

import rego.v1

default allow := false

# Admins may do anything.
allow if {
    "admin" in input.user.roles
}

# A customer may cancel their own order within an hour of placing it.
allow if {
    input.action == "cancel"
    input.order.customer_id == input.user.id
    time.now_ns() - input.order.placed_at_ns < 60 * 60 * 1000000000
}

# Support may cancel any order that is not yet shipped.
allow if {
    input.action == "cancel"
    "support" in input.user.roles
    not shipped
}

shipped if input.order.status == "shipped"

deny_reasons contains "order already shipped" if shipped
deny_reasons contains sprintf("user %v lacks a role", [input.user.id]) if count(input.user.roles) == 0
