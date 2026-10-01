<!--- CFML (Adobe ColdFusion 2025 / Lucee 6 / BoxLang-compatible) — syntax showcase --->
<!--- Warehouse order summary page: reads the cart, totals it, renders HTML. --->
<!---
    A multi-line CFML comment.
    <!--- Comments can nest in CFML --->
    TODO: move the query into a component.
--->
<cfsetting enablecfoutputonly="false" showdebugoutput="false">
<cfprocessingdirective pageencoding="utf-8">
<cfcontent type="text/html; charset=utf-8">
<cfheader name="X-Frame-Options" value="SAMEORIGIN">

<!--- ── Parameters and variables ───────────────────────────────────── --->
<cfparam name="url.orderId" type="numeric" default="0">
<cfparam name="form.note" type="string" default="">
<cfparam name="session.user" default="guest">

<cfset taxRate = 0.2>
<cfset greeting = "Hello, #session.user#!">
<cfset escapedHash = "Order ##12 costs ##5">
<cfset nothing = "">
<cfset items = []>
<cfset prices = {widget: 4.50, gadget: 1.25, "big thing": 99}>
<cfset flag = true>
<cfset n = 1 + 2 * 3 - 4 / 2 MOD 3>
<cfset total = 0>
<cfset var1 = "A" & "B">
<cfset isLow = (n LT 5) AND (n GTE 1) OR NOT flag>
<cfset arrayAppend(items, "A-100")>
<cfset structKeyExists(prices, "widget")>
<cfset message = 'single quoted with ''doubled'' quotes'>
<cfset url.debug = isDefined("url.debug") ? url.debug : false>

<cfparam name="request.timestamp" default="#now()#">

<!--- ── Queries ────────────────────────────────────────────────────── --->
<cfquery name="items" datasource="shop" cachedwithin="#createTimeSpan(0,0,5,0)#">
    SELECT sku, qty, price
    FROM order_items
    WHERE order_id = <cfqueryparam value="#url.orderId#" cfsqltype="cf_sql_integer">
      AND sku IN (<cfqueryparam value="A-100,B-200" list="true" cfsqltype="cf_sql_varchar">)
    ORDER BY sku
</cfquery>

<cfstoredproc procedure="usp_recalc" datasource="shop">
    <cfprocparam type="in" cfsqltype="cf_sql_integer" value="#url.orderId#">
    <cfprocresult name="recalc">
</cfstoredproc>

<!--- ── CFScript ───────────────────────────────────────────────────── --->
<cfscript>
    // line comment
    /* block comment */
    total = 0;
    for (row in items) {
        total += row.qty * row.price;
    }

    function money(required numeric n, string currency = "USD") {
        return numberFormat(n, "0.00") & " " & currency;
    }

    function classify(qty) {
        if (qty == 0) {
            return "empty";
        } else if (qty LT 25) {
            return "low";
        } else {
            return "ok";
        }
    }

    switch (classify(total)) {
        case "empty":
            writeOutput("nothing");
            break;
        case "low":
        case "ok":
            writeOutput("some");
            break;
        default:
            writeOutput("?");
    }

    i = 0;
    while (i < 3) { i++; }
    do { i--; } while (i > 0);
    for (j = 1; j <= 10; j += 2) {
        if (j == 5) continue;
        if (j > 8) break;
    }

    try {
        result = 10 / 0;
    } catch (any e) {
        writeLog(text = e.message, type = "error", file = "orders");
    } finally {
        cleanup = true;
    }

    obj = new components.Order(id = url.orderId);
    nums = [1, 2, 3, 4];
    doubled = nums.map(function(x) { return x * 2; });
    lambda = (a, b) => a + b;
    str = "interpolated #total# and #money(total)#";
    sql = "SELECT * FROM t WHERE x = :x";
    q = new Query(sql = sql);
    q.addParam(name = "x", value = 1, cfsqltype = "cf_sql_integer");
    ternary = total > 100 ? "big" : "small";
    elvis = url.missing ?: "default";
    safe = obj?.name;
    isNull = isNull(url.nothing);
    structured = {a: 1, b: [1, 2, {c: 3}]};
    throw(type = "InvalidInput", message = "Order not found");
</cfscript>

<!--- ── Output ─────────────────────────────────────────────────────── --->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Order <cfoutput>#url.orderId#</cfoutput></title>
    <style>
        .low { color: #c00; }
        table { border-collapse: collapse; }
    </style>
    <script>
        const orderId = <cfoutput>#url.orderId#</cfoutput>;
        console.log("order", orderId);
    </script>
</head>
<body>
<cfoutput>
    <h1>Order ##url.orderId#</h1>
    <p>#greeting# &middot; Rendered at #timeFormat(now(), "HH:mm:ss")#</p>

    <cfif items.recordCount EQ 0>
        <p>No items.</p>
    <cfelseif items.recordCount LT 3>
        <p>A few items.</p>
    <cfelse>
        <p>Subtotal: #money(total)# &middot; Tax: #money(total * taxRate)#</p>
    </cfif>

    <table>
        <cfloop query="items">
            <tr class="#iif(qty LT 25, de('low'), de(''))#">
                <td>#htmlEditFormat(sku)#</td>
                <td>#qty#</td>
                <td>#numberFormat(price, "0.00")#</td>
            </tr>
        </cfloop>
    </table>

    <cfloop from="1" to="3" index="k">#k# </cfloop>
    <cfloop list="a,b,c" index="letter" delimiters=",">#letter#</cfloop>
    <cfloop array="#nums#" item="num">#num#</cfloop>
    <cfloop collection="#prices#" item="key">#key#=#prices[key]# </cfloop>
    <cfloop condition="i LT 3"><cfset i++></cfloop>

    <cfswitch expression="#classify(total)#">
        <cfcase value="empty">Empty</cfcase>
        <cfcase value="low,ok" delimiters=",">Some</cfcase>
        <cfdefaultcase>Unknown</cfdefaultcase>
    </cfswitch>

    <cfoutput query="items" group="sku">
        #sku#<br>
    </cfoutput>
</cfoutput>

<!--- ── Includes, modules, components ─────────────────────────────── --->
<cfinclude template="footer.cfm">
<cfmodule template="tags/banner.cfm" title="Orders">
<cf_banner title="Custom tag">
<cfimport taglib="/tags" prefix="ui">
<ui:button label="Save" />
<cfinvoke component="services.Orders" method="load" returnvariable="order">
    <cfinvokeargument name="id" value="#url.orderId#">
</cfinvoke>
<cfobject type="java" class="java.util.ArrayList" name="list">
<cflocation url="/orders?id=#url.orderId#" addtoken="false">

<!--- ── Forms, errors, misc tags ──────────────────────────────────── --->
<cfform name="noteForm" method="post" action="save.cfm">
    <cfinput type="text" name="note" value="#form.note#" required="true">
    <cfinput type="submit" name="save" value="Save">
</cfform>

<cftry>
    <cfthrow type="Custom" message="Boom" detail="Details here">
    <cfcatch type="Custom">
        <cfoutput>Caught: #cfcatch.message#</cfoutput>
    </cfcatch>
    <cfcatch type="any">
        <cfrethrow>
    </cfcatch>
    <cffinally>
        <cflog text="done" file="orders">
    </cffinally>
</cftry>

<cflock scope="session" type="exclusive" timeout="5">
    <cfset session.last = now()>
</cflock>
<cfthread name="bg" action="run">
    <cfset thread.done = true>
</cfthread>
<cfmail to="buyer@example.com" from="ops@example.com" subject="Order #url.orderId#" type="html">
    Your order shipped.
</cfmail>
<cfdump var="#items#" label="items">
<cfabort>
<cfexit method="exitTag">
</body>
</html>

<!--- ── Further constructs ──────────────────────────────────────── --->
<cfcomponent displayname="Orders" output="false" accessors="true" extends="BaseService" implements="IOrders" persistent="true" table="orders">
    <cfproperty name="id" type="numeric" fieldtype="id" generator="native" ormtype="int" />
    <cfproperty name="items" type="array" fieldtype="one-to-many" cfc="OrderItem" fkcolumn="order_id" cascade="all" />

    <cffunction name="init" access="public" returntype="Orders" output="false" hint="Constructor">
        <cfargument name="dsn" type="string" required="true" default="shop">
        <cfset variables.dsn = arguments.dsn>
        <cfreturn this>
    </cffunction>

    <cffunction name="total" access="remote" returntype="numeric" returnformat="json" roles="admin,buyer" secureJSON="true">
        <cfargument name="orderId" type="numeric" required="yes">
        <cfset var local = {}>
        <cfset local.sum = 0>
        <cfloop array="#variables.items#" index="local.item">
            <cfset local.sum += local.item.getQty() * local.item.getPrice()>
        </cfloop>
        <cfreturn local.sum>
    </cffunction>
</cfcomponent>

<cfscript>
component displayname="Inventory" extends="Base" accessors=true singleton {
    property name="stock" type="struct" default="#{}#";
    property string sku;

    public Inventory function init(required string dsn = "shop", numeric limit = 25) {
        variables.dsn = arguments.dsn;
        return this;
    }

    private void function log(required string msg) {
        writeLog(text = msg, type = "information");
    }

    remote any function find(required numeric id) returnformat="json" {
        var q = queryExecute(
            "SELECT * FROM stock WHERE id = :id",
            { id: { value: id, cfsqltype: "cf_sql_integer" } },
            { datasource: variables.dsn }
        );
        return q;
    }

    function onMissingMethod(missingMethodName, missingMethodArguments) {
        return missingMethodName;
    }

    static function create() { return new Inventory(); }
    final function locked() {}
    abstract function todo();
}

interface {
    function total(required numeric id);
}

// Operators, every spelling
a = 1 + 2 - 3 * 4 / 5 % 6 ^ 2;
b = 7 \ 2;            // integer division
c = "a" & "b";        // concatenation
d = 1 eq 1 and 2 neq 3 or 4 gt 3 and 5 lt 6 and 6 gte 6 and 7 lte 7 xor true eqv true imp false;
e = !true && (false || true);
f = "abc" contains "b" and "abc" does not contain "z";
g = 5 mod 3;
h = a == b ? "same" : "different";
i = url.x ?: "elvis";
j = a++ + ++a - a-- - --a;
a += 1; a -= 1; a *= 2; a /= 2; a %= 3; c &= "!";
k = not true;
l = (1 is 1) and (1 is not 2) and ("a" is "A");
m = 1 greater than 0;
n = 1 less than or equal to 1;
o = 1 greater than or equal to 1;
p = 1 not equal 2;

// Literals
nums = [1, 2.5, -3, 1e3, 0x1F];
str1 = "double ""escaped"" and ##hash##";
str2 = 'single ''escaped''';
str3 = "interp #a# and #b + 1#";
arr = [1, [2, 3], {x: 1}];
st1 = {a: 1, "b": 2, 'c': 3};
st2 = {a = 1, b = 2};
st3 = [a: 1, b: 2];
ordered = [ "x": 1, "y": 2 ];
nada = javacast("null", "");
dt = createDate(2024, 1, 2);
ts = {ts '2024-01-02 03:04:05'};
dd = {d '2024-01-02'};
tt = {t '03:04:05'};
guid = createUUID();
re = reFindNoCase("^[a-z]+$", "abc");
lam = (x) => x * 2;
fnexp = function(x) { return x; };
call = lam(3);

// Control flow
if (a > 1) { b = 2; } else if (a < 0) { b = 3; } else { b = 4; }
switch (a) { case 1: b = 1; break; case 2: case 3: b = 2; break; default: b = 0; }
for (i = 1; i <= 3; i++) { writeOutput(i); }
for (key in st1) { writeOutput(key); }
for (item in arr) { writeOutput(item); }
while (a < 5) { a++; }
do { a--; } while (a > 0);
try { x = 1 / 0; } catch (any e) { rethrow; } finally { y = 1; }
try { throw(message = "boom", type = "App"); } catch ("App" e) {}
param name="url.id" type="numeric" default=0;
include "footer.cfm";
location(url = "/home", addtoken = false);
abort;
exit;
return;
thread name="t1" action="run" { thread.result = 1; }
lock name="l1" type="exclusive" timeout=5 { x = 1; }
transaction { queryExecute("UPDATE t SET x = 1"); transaction action="commit"; }
savecontent variable="out" { writeOutput("captured"); }
cfhttp(url = "https://example.com", method = "GET", result = "resp");
writeDump(var = resp, label = "response");
</cfscript>

<cfsilent>
    <cfset quiet = true>
</cfsilent>
<cfsavecontent variable="snippet"><b>captured</b></cfsavecontent>
<cfhttp url="https://example.com/api" method="post" result="resp" timeout="10">
    <cfhttpparam type="header" name="Content-Type" value="application/json">
    <cfhttpparam type="body" value="#serializeJSON({sku: 'A-100'})#">
</cfhttp>
<cffile action="read" file="#expandPath('./data.txt')#" variable="content">
<cfdirectory action="list" directory="#expandPath('./')#" name="files" filter="*.cfm">
<cfzip action="zip" source="#expandPath('./')#" file="#expandPath('./a.zip')#">
<cfschedule action="update" task="nightly" url="https://example.com/job" interval="daily" startdate="2024-01-01" starttime="02:00">
<cfcache action="flush">
<cfflush interval="256">
<cfapplication name="warehouse" sessionmanagement="yes" sessiontimeout="#createTimeSpan(0,0,30,0)#">
<cfcookie name="seen" value="1" expires="30" httponly="true" secure="true">
<cfset session.cart = []>
<cfset application.startedAt = now()>
<cfset arrayAppend(session.cart, {sku: "A-100"})>
<cfset x = structNew()>
<cfset x["key with space"] = 1>
<cfset x.dynamic[1].deep = true>
<cfset y = "#x.key#" & "#chr(10)#">
<cfif isDefined("x.key") AND NOT structIsEmpty(x) OR len(trim(y)) GT 0>yes<cfelse>no</cfif>
<cfoutput>#x["key with space"]# #uCase(y)# #dateFormat(now(), "yyyy-mm-dd")# ##literal##</cfoutput>
<cfmodule name="CustomTags.Foo" attr="1">
<cf_myTag a="1" b="#x.key#">Body</cf_myTag>
<cfbreak><cfcontinue>
<cfreturn x>
<!--- TODO: replace cfhttp with a shared HTTP client component. --->

<!--- ── Modern CFML: script components, closures, member functions ── --->
<cfscript>
import models.Order;
import com.example.*;

/**
 * Javadoc-style component documentation.
 * @hint Handles stock queries
 * @author Acme Logistics
 */
component accessors="true" output="false" extends="models.Base" implements="IStock,IAudit" {

    property name="dsn" type="string" default="shop";
    property name="cache" type="struct" setter="false";
    property string sku default="A-100";
    property numeric qty default=0 getter=true setter=true;

    static {
        static.instances = 0;
    }

    final string function name() { return "stock"; }

    /** @hint Looks up one SKU */
    public struct function find(required string sku, numeric qty = 0, boolean strict = false) hint="Find a SKU" returnformat="json" {
        var result = {};
        local.query = queryExecute(
            "SELECT * FROM stock WHERE sku = :sku",
            { sku: { value: arguments.sku, cfsqltype: "cf_sql_varchar" } },
            { datasource: variables.dsn, returntype: "array" }
        );
        return local.query.len() ? local.query[1] : result;
    }

    public function map(required array items, required function callback) {
        return items.map(callback);
    }

    private any function secret() { return super.secret(); }
    package function pkg() {}
    remote string function api() returnformat="plain" { return "ok"; }
}

// Arrow functions, closures, and member functions on every type
square = (n) => n * n;
adder = (a, b) => { return a + b; };
compose = (f, g) => (x) => f(g(x));
counter = function() { var c = 0; return function() { return ++c; }; }();
items = [3, 1, 2];
sorted = items.sort("numeric", "asc");
evens = items.filter((n) => n % 2 == 0);
total = items.reduce((acc, n) => acc + n, 0);
items.each((n, i) => writeOutput("#i#:#n# "));
names = "alpha,beta,gamma".listToArray();
joined = names.toList("|");
upper = "text".ucase().trim().left(2);
size = {a: 1, b: 2}.count();
keys = {a: 1}.keyArray();
exists = {a: 1}.keyExists("a");
rows = queryNew("id,name", "integer,varchar", [[1, "a"], [2, "b"]]);
rows.each((row) => writeOutput(row.name));
mapped = rows.map((row) => row.id * 2);
found = items.find((n) => n > 1);
every = items.every((n) => n > 0);
some = items.some((n) => n > 2);
flat = [[1, 2], [3]].flatten ?: "n/a";
first = items.first();
last = items.last();
sliced = items.slice(1, 2);
reversed = items.reverse();
sumValue = items.sum();
avgValue = items.avg();
maxValue = items.max();
parsed = deserializeJSON('{"a":[1,2,3]}');
printed = serializeJSON(parsed, "struct");
d = now().dateFormat("yyyy-mm-dd");
chain = "  Mixed Case  ".trim().lcase().replace("mixed", "MIXED");

// Named, positional and spread-like argument styles
r1 = numberFormat(value = 1234.5, mask = "9,999.00");
r2 = numberFormat(1234.5, "9,999.00");
r3 = structNew("ordered");
r4 = new models.Order(id = 1, sku = "A-100");
r5 = createObject("component", "models.Order").init(1);
r6 = createObject("java", "java.util.HashMap").init();
r7 = invoke(r4, "total", { currency: "USD" });
r8 = evaluate("1 + 2");
args = { id = 1, sku = "A-100" };
r9 = new models.Order(argumentCollection = args);

// Tag-in-script syntax
cfhttp(url = "https://example.com/api", method = "POST", result = "apiResponse", timeout = 10) {
    cfhttpparam(type = "header", name = "Accept", value = "application/json");
    cfhttpparam(type = "body", value = serializeJSON({ sku: "A-100" }));
}
cfquery(name = "q", datasource = "shop") {
    writeOutput("SELECT 1 AS one");
}
cfmail(to = "buyer@example.com", from = "ops@example.com", subject = "Shipped", type = "html") {
    writeOutput("<p>Shipped</p>");
}
cflog(text = "tag-in-script", type = "information", file = "orders");
cfparam(name = "url.page", default = 1);
cfsetting(requesttimeout = 60, showdebugoutput = false);
cfheader(name = "X-Powered-By", value = "CFML");
cfcontent(type = "application/json", reset = true);
cfcookie(name = "seen", value = "1", expires = "never");
cfflush();
cfdump(var = r4, expand = false);
cftimer(label = "timed block", type = "debug") {
    sleep(10);
}

// Error handling forms
try {
    throw(type = "Custom.Error", message = "Failed", detail = "More detail", errorCode = "E100");
} catch (Custom.Error e) {
    writeOutput("custom: #e.message#");
} catch (database e) {
    writeOutput("db: #e.sqlState#");
} catch (any e) {
    rethrow;
} finally {
    writeOutput("always");
}

// Scopes and null handling
scopes = [url, form, cgi, cookie, session, application, request, server, variables, arguments, local, this, client];
value = url.missing ?: "default";
safe = r4?.customer?.name ?: "anonymous";
isNullValue = isNull(r4.unknown);
nullable = javaCast("null", 0);
exists2 = isDefined("url.x") && structKeyExists(form, "y");

// Literals: numbers, strings, dates, structs, arrays, queries
hex = 0x1F; sci = 6.02e23; neg = -42; dec = .5;
dq = "He said ""hi"" and ##hash## and #value#";
sq = 'It''s fine';
multi = "line one
line two";
struct1 = { "quoted key": 1, plain: 2, 'single': 3, nested: { deep: [1, { x: 2 }] } };
struct2 = [ a: 1, b: 2 ];
arr1 = [ 1, 2, 3, [ 4, 5 ], { k: "v" } ];
date1 = createDateTime(2025, 6, 15, 12, 0, 0);
ts1 = { ts '2025-06-15 12:00:00' };
</cfscript>

<!--- ── Additional tags ───────────────────────────────────────────── --->
<cftimer label="template" type="inline"><cfoutput>#now()#</cfoutput></cftimer>
<cfimage action="resize" source="#expandPath('./in.png')#" destination="#expandPath('./out.png')#" width="200" height="200" overwrite="true">
<cfspreadsheet action="read" src="#expandPath('./data.xlsx')#" query="sheet" headerrow="1">
<cfpdf action="merge" source="a.pdf,b.pdf" destination="merged.pdf" overwrite="true">
<cfdocument format="pdf" filename="report.pdf" overwrite="true"><cfoutput>Report</cfoutput></cfdocument>
<cfchart format="png" chartwidth="400" chartheight="300"><cfchartseries type="bar"><cfchartdata item="A" value="1"></cfchartseries></cfchart>
<cfexecute name="/bin/echo" arguments="hello" variable="out" timeout="5" />
<cfwebsocket name="ws" onmessage="handle" />
<cfloop file="#expandPath('./big.txt')#" index="line" characters="1024" />
<cfloop from="10" to="1" step="-3" index="down"><cfoutput>#down# </cfoutput></cfloop>
<cftransaction action="begin" isolation="serializable"><cftransaction action="commit" /></cftransaction>
<cfset result = queryExecute("SELECT 1")>
<cfset local.items = []>
<cfset "dynamic#1#" = "dynamic variable name">
<cfset this.name = "app">
<cfset this.sessionManagement = true>
<cfset this.mappings["/lib"] = expandPath("./lib")>
<cfset this.datasource = "shop">
<cfset this.javaSettings = { loadPaths: ["./jars"], reloadOnChange: true }>
<cfset this.restSettings = { cfclocation: "./api", skipCFCWithError: true }>
<cfif NOT isNull(result) AND result.recordCount GT 0>found<cfelseif false>never<cfelse>none</cfif>
