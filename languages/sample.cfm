<!--- Order summary page: reads the cart and totals it. --->
<cfparam name="url.orderId" type="numeric" default="0">

<cfset taxRate = 0.2>
<cfquery name="items" datasource="shop">
    SELECT sku, qty, price FROM order_items
    WHERE order_id = <cfqueryparam value="#url.orderId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfscript>
    total = 0;
    for (row in items) {
        total += row.qty * row.price;
    }
    function money(required numeric n) {
        return numberFormat(n, "0.00");
    }
</cfscript>

<cfoutput>
    <h1>Order ##url.orderId#</h1>
    <cfif items.recordCount EQ 0>
        <p>No items.</p>
    <cfelse>
        <p>Subtotal: #money(total)# &middot; Tax: #money(total * taxRate)#</p>
    </cfif>
</cfoutput>
