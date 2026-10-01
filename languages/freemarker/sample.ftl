<#-- FreeMarker 2.3.34 — syntax showcase -->
<#ftl encoding="UTF-8" strip_whitespace=true strip_text=false output_format="HTML" auto_esc=true ns_prefixes={"d": "http://example.com/data"} attributes={"title": "Order email", "version": 2}>
<#-- ── Comments ── -->
<#-- FreeMarker: an order confirmation email for the warehouse system. -->
<#--
  Block comments can span several lines.
  TODO: split the shipment table into its own template.
  FIXME: tax rounding differs for exempt items.
-->

<#-- ── Directives: import, include, setting ── -->
<#import "macros.ftl" as m>
<#import "/lib/format.ftl" as fmt>
<#include "header.ftl" parse=true encoding="UTF-8">
<#setting number_format="0.00">
<#setting locale="en_GB">
<#setting time_zone="Europe/London">

<#-- ── Variables: assign, local, global ── -->
<#assign total = 0>
<#assign taxRate = 0.2, currency = "GBP">
<#assign tags = ["fragile", 'heavy', "cold-chain"]>
<#assign dims = {"w": 40, "h": 25.5, "d": 1e2, "weight": -3.5}>
<#assign banner>
  <strong>Order ${order.number}</strong>
</#assign>
<#global siteName = "Acme Warehouse">

<#-- ── Literals: strings, numbers, booleans, ranges, raw strings ── -->
<#assign plain = "double \"quoted\" with \\ backslash, \n newline, \t tab, \u00e9 unicode, \x41 hex">
<#assign single = 'it\'s single quoted'>
<#assign raw = r"C:\warehouse\bin\${notInterpolated}">
<#assign whole = 42>
<#assign negative = -17>
<#assign decimal = 3.14159>
<#assign exponent = 6.02e23>
<#assign flag = true>
<#assign off = false>
<#assign span = 1..10>
<#assign halfOpen = 0..<5>
<#assign openEnd = 3..>
<#assign lengthRange = 0..!5>
<#assign nested = {"items": [1, 2, {"k": "v"}], "empty": []}>

<h1>Thanks, ${customer.firstName?cap_first}!</h1>
<p>${banner}</p>
<p>Site: ${siteName} &mdash; ${.now?string("yyyy-MM-dd HH:mm")}</p>

<#-- ── Interpolation: expressions, formats, escapes ── -->
<p>Subtotal: ${order.subtotal?string.currency}</p>
<p>Count: ${order.items?size} items, ${(order.items?size / 2)?round} pairs</p>
<p>Tax: ${(order.subtotal * taxRate)?string("0.00")}</p>
<p>Raw markup: ${order.noteHtml?no_esc}</p>
<p>Number: #{total; m2M2}</p>
<p>Missing with default: ${customer.nickname!"friend"}</p>
<p>Missing chained: ${(customer.address.line2)!}</p>
<p>Exists? ${customer.phone???then("yes", "no")}</p>
<p>Escaped dollar: $\{literal} and #\{literal}</p>

<#-- ── Operators ── -->
<#assign sum = 1 + 2 - 3 * 4 / 5 % 2>
<#assign cmp = (a == b) || (a != b) && !(a < b) || a <= b || a > b || a >= b>
<#assign alt = (a lt b) && (a lte b) || (a gt b) && (a gte b) || (a gte b)>
<#assign inc = 5>
<#assign inc += 2>
<#assign inc -= 1>
<#assign inc *= 3>
<#assign inc /= 2>
<#assign inc %= 4>
<#assign inc++>
<#assign inc-->
<#assign pick = flag?then("on", "off")>
<#assign joined = "a" + "b" + 1>
<#assign slice = "warehouse"[0..3]>
<#assign last = tags[tags?size - 1]>
<#assign exists = (order.discount)??>
<#assign dflt = order.discount!0>
<#assign lambda = (x -> x * 2)>

<#-- ── Built-ins: strings, sequences, hashes, numbers, dates ── -->
<#assign s1 = customer.lastName?upper_case?trim?replace("-", " ")?html?xml?url>
<#assign s2 = "a,b,c"?split(",")?join(" | ")>
<#assign s3 = "text"?length + "text"?index_of("x") + "text"?starts_with("t")?then(1, 0)>
<#assign q1 = tags?first + tags?last + tags?seq_contains("heavy")?c>
<#assign q2 = tags?sort?reverse?chunk(2)?size>
<#assign q3 = order.items?map(i -> i.sku)?filter(s -> s?has_content)?join(", ")>
<#assign q4 = dims?keys?size + dims?values?size>
<#assign n1 = 1234.5678?string(",##0.00")?c>
<#assign n2 = 7?is_number?c + 7?floor + 7.5?ceiling + 7.5?round>
<#assign d1 = .now?date?string.short + .now?time?string.medium + .now?datetime?iso_utc>
<#assign t1 = order.status?switch("PAID", 1, "OPEN", 2, 0)>
<#assign tpl = "Hello ${customer.firstName}"?interpret>

<#-- ── Special variables ── -->
<p>${.version} ${.locale} ${.lang} ${.output_encoding!"none"} ${.template_name} ${.main_template_name}</p>
<p>${.data_model.order.number!"n/a"} ${.globals.siteName} ${.vars["customer"].firstName} ${.error!""}</p>
<p>${.current_template_name}</p>

<#-- ── Conditionals ── -->
<#if order.items?size == 0>
  <p>Your order is empty.</p>
<#elseif order.items?size gt 100>
  <p>That is a very large order.</p>
<#else>
  <table>
    <#-- ── Loops: list, items, sep, break, continue ── -->
    <#list order.items as item>
      <#if item.qty <= 0><#continue></#if>
      <#assign total += item.qty * item.price>
      <tr class="${item?is_odd_item?then('odd', 'even')}">
        <td>${item?counter}. ${item.sku}<#sep>,</#sep></td>
        <td>${item.qty} × ${item.price}</td>
        <td><@m.money amount=item.qty * item.price currency=currency /></td>
        <td><#if item?has_next>more<#else>last</#if> ${item?index}</td>
      </tr>
      <#if item?counter gte 50><#break></#if>
    <#else>
      <tr><td colspan="4">No lines.</td></tr>
    </#list>
  </table>
  <p>Total: <b><@m.money amount=total /></b></p>
</#if>

<#list dims as key, value>
  <span>${key}=${value}</span><#sep>, </#sep>
</#list>

<#list order.items?chunk(3) as row>
  <#items as cell>${cell.sku}</#items>
</#list>

<#list 1..3 as n>${n}</#list>
<#list tags as tag>
  ${tag}
  <#items as t>${t}</#items>
</#list>

<#-- ── Switch ── -->
<#switch order.status>
  <#case "PAID">
    <p>Paid in full.</p>
    <#break>
  <#case "OPEN">
  <#case "PENDING">
    <p>Awaiting payment.</p>
    <#break>
  <#default>
    <p>Unknown status.</p>
</#switch>

<#-- ── Macros, functions, calls, nested, caller ── -->
<#macro footer year=.now?string("yyyy") company="Example Ltd" extras...>
  <footer>&copy; ${year} ${company}<#if extras?has_content> (${extras?keys?join(", ")})</#if></footer>
  <#nested year, company>
</#macro>

<#macro box title style="plain">
  <div class="box ${style}"><h2>${title}</h2><#nested></div>
</#macro>

<#function discount price pct=10>
  <#local result = price * (100 - pct) / 100>
  <#return result>
</#function>

<@footer />
<@footer year="2030" company="Acme Co" region="EU"; y, c>${y} ${c}</@footer>
<@box title="Notes" style="warn">Handle with care.</@box>
<@m.money amount=discount(19.99, 25) />
<@fmt.pad value="x" width=5 />
<@"dynamic"?interpret />

<#-- ── Scoping, attempt/recover, flush, compress, escape, noescape, lt/rt/nt ── -->
<#attempt>
  <p>${risky.value}</p>
<#recover>
  <p>Something went wrong: ${.error}</p>
</#attempt>

<#compress>
  <p>   squeezed     whitespace   </p>
</#compress>

<#escape x as x?html>
  <p>${customer.bio}</p>
  <#noescape>${customer.trustedHtml}</#noescape>
</#escape>

<#noautoesc><b>${order.rawNote}</b></#noautoesc>
<#autoesc><i>${order.note}</i></#autoesc>

<#t>trim both sides
<#lt>trim left
<#rt>trim right
<#nt>no trim
<#flush>

<#-- ── Legacy and misc directives ── -->
<#visit doc using handlers>
<#recurse node>
<#fallback>
<#stop "Aborted: no customer on the order.">

<#-- ── Mixed user directives and plain text ── -->
<@m.layout title="Order ${order.number}">
  <@m.section name="body">
    Dear ${customer.firstName}, your order ships on ${order.shipDate?date}.
    Questions? Write to support@example.com or visit https://example.com/help?id=${order.number?c}.
  </@m.section>
</@m.layout>

<#-- ── More directives: noparse, outputformat, capture assigns, namespaces ── -->
<#noparse>${not} <#evaluated> <@here /> #{either}</#noparse>
<#outputformat "XML">${"<&>"}</#outputformat>
<#outputformat "plainText">${"<&>"}</#outputformat>
<#assign counter = 0 in m>
<#assign captured in m>captured into the namespace</#assign>
<#assign tmp>captured text ${total}</#assign>
<#global shared>global capture</#global>
<#global answer = 42, other = "x">
<#macro early>
  <#local x>local capture</#local>
  <#local y = 1, z = 2>
  <#if x?length gt 3><#return></#if>
  after the return
</#macro>
<#macro oneArg value><#nested value></#macro>
<#function fact n>
  <#if n <= 1><#return 1></#if>
  <#return n * fact(n - 1)>
</#function>
<#function lazyJoin items sep=", ">
  <#local out = "">
  <#list items as i><#local out += (i?is_first?then("", sep)) + i></#list>
  <#return out>
</#function>
<@early />
<@oneArg value=3 ; v>${v}</@oneArg>
<@oneArg 3 ; v>${v}</@oneArg>
<@.namespace.early />
<@m.layout "positional" />
<@(some.expression) arg=1 />

<#-- ── Operators: word forms, backslash forms, precedence ── -->
<#if (a > b) && (c >= d) || (e < f) && !(g <= h)>symbolic</#if>
<#if a gt b and c gte d>word forms</#if>
<#if a \gt b || c \gte d || e \lt f || g \lte h>backslash forms</#if>
<#if a?? && b??>exists</#if>
<#if (a.b)?? && (c.d)!"" == "x">nested exists</#if>
<#if x == "text" && y != 'other' && z = 3>
  <#-- single = is also comparison in FTL expressions -->
</#if>
<#assign precedence = 1 + 2 * 3 - 4 / 2 % 2>
<#assign unary = -a + +b>
<#assign negated = !flag>
<#assign sliceFrom = "abcdef"[2..]>
<#assign sliceLen = "abcdef"[1..*3]>
<#assign sliceRev = "abcdef"[3..*-2]>
<#assign hashKey = dims["w"]>
<#assign hashDot = dims.w>
<#assign dynamicKey = dims[key]>
<#assign methodCall = "text"?upper_case?substring(1, 3)>
<#assign lambdaMap = tags?map((t) -> t?upper_case)>
<#assign hashLiteral = {"a": 1, "b": [1, 2], "c": {"d": 'e'}, f: 1}>

<#-- ── Special variables ── -->
${.auto_esc?c} ${.output_format} ${.url_escaping_charset!"none"} ${.locale_object} ${.time_zone} ${.incompatible_improvements}
${.namespace.counter!0} ${.main.answer!0} ${.locals.x!""} ${.current_template_name} ${.get_optional_template("x.ftl").exists?c}
${.now?iso_local} ${.template_name} ${.custom_attribute_name!""}

<#-- ── Built-ins by family ── -->
<#assign b1 = "Text"?lower_case + "t"?capitalize + "Text"?uncap_first + "a"?left_pad(5) + "a"?right_pad(5, "-")>
<#assign b2 = "text"?contains("e")?c + "text"?ends_with("t")?c + "text"?remove_beginning("t") + "text"?remove_ending("t") + "x"?ensure_starts_with("/") + "x"?ensure_ends_with("/")>
<#assign b3 = "a1b2"?matches("[a-z]\\d")?c + "a1b2"?replace("\\d", "#", "r") + "  a  b "?squeeze_spaces + "a b c"?word_list?size + "x\ny"?chop_linebreak>
<#assign b4 = "<b>"?html + "<b>"?xhtml + "<b>"?xml + "a b"?url + "a/b"?url_path + "it's"?js_string + "it's"?json_string + "x"?cn>
<#assign b5 = "text"?substring(1) + "text"?left_pad(6) + "text"?last_index_of("t") + "text"?string + "text"?truncate(2) + "text"?truncate_c(2) + "text"?truncate_w(2)>
<#assign b6 = "5"?number + "true"?boolean?c + "2026-01-01"?date("yyyy-MM-dd") + "10:00"?time("HH:mm") + "2026-01-01 10:00"?datetime("yyyy-MM-dd HH:mm")>
<#assign t1 = x?is_string?c + x?is_sequence?c + x?is_hash?c + x?is_hash_ex?c + x?is_boolean?c + x?is_date?c + x?is_date_like?c + x?is_directive?c + x?is_macro?c + x?is_method?c + x?is_node?c + x?is_enumerable?c + x?is_indexable?c + x?is_collection?c + x?is_collection_ex?c + x?is_transform?c>
<#assign t2 = x?is_first?c + x?is_last?c + x?item_parity + x?item_parity_cap + x?item_cycle("a", "b") + x?counter + x?index + x?has_next?c + x?has_content?c>
<#assign s1 = seq?size + seq?first + seq?last + seq?seq_index_of(1) + seq?seq_last_index_of(1) + seq?sort_by("name")?size + seq?min + seq?max + seq?sum + seq?reverse?size + seq?take_while(i -> i < 3)?size + seq?drop_while(i -> i < 3)?size + seq?join(",") + seq?chunk(2)?size + seq?seq_contains(1)?c + seq?sort?size>
<#assign s2 = seq?filter(i -> i > 1)?size + seq?map(i -> i * 2)?size + seq?sequence?size + seq?then(1, 2)>
<#assign h1 = dims?keys?size + dims?values?size + dims?api.size() + dims?size + dims?has_content?c + dims?is_hash?c>
<#assign n3 = 7?abs + 7?c + 7?string + 7?string.number + 7?string.percent + 7?string["0.0"] + 7?int + 7?long + 7?double + 7?float + 7?floor + 7?round + 7?ceiling + 7?number_to_date?string + 7.5?is_infinite?c + 7.5?is_nan?c>
<#assign d2 = .now?date_if_unknown + .now?time_if_unknown + .now?datetime_if_unknown + .now?unix_time + .now?iso("UTC") + .now?iso_utc_ms + .now?iso_nz + .now?string.iso>
<#assign e1 = "1+1"?eval + '{"a":1}'?eval_json + "freemarker.template.utility.ObjectConstructor"?new()>
<#assign e2 = x?markup_string + x?esc + x?no_esc + x?trim + x?upper_case + x?node_name!"" + x?children!"" + x?root!"" + x?parent!"">
<#assign e3 = bean?api.getName() + bean?api.class.name>

<#-- ── Interpolation forms ── -->
${"string with ${nested} interpolation"}
${'single ${nested}'}
${r"raw ${not}"}
${true?c} ${1.5?c} ${date?string("yyyy")} ${date?string.long} ${date?string.xs}
${x!} ${x!"d"} ${x!(1 + 2)} ${(x.y.z)!} ${x???c}
#{3.14159; M2m1} #{x; m0M3}
${"Unicode: \u00e9 \x41"}
${"Dollar: $\{x}"}

<#-- ── Comments in tags and attributes ── -->
<#assign withComment = 1> <#-- trailing comment -->
<#if true<#-- inline comment in tag -->>yes</#if>
<#---
  Triple-dash comment form (legacy-looking but valid as a comment).
-->

<#-- Non-ASCII: ¡Gracias! 谢谢 ありがとう Спасибо -->

<#-- ── 2.3.3x additions: includes, with_args, markup output, more built-ins ── -->
<#include "optional.ftl" ignore_missing=true>
<#include "dynamic/" + order.type + ".ftl">
<#assign wa1 = m.money?with_args({"currency": "EUR"})>
<#assign wa2 = m.money?with_args_last([100, "GBP"])>
<@wa1 amount=5 />
<#assign abc1 = 1?lower_abc + 28?upper_abc>
<#assign ks = "a/b/c"?keep_before("/") + "a/b/c"?keep_after("/") + "a/b/c"?keep_before_last("/") + "a/b/c"?keep_after_last("/")>
<#assign cases = "abc"?c_lower_case + "abc"?c_upper_case>
<#assign tpath = "x.ftl"?absolute_template_name + .template_name?absolute_template_name("../y.ftl")>
<#assign markup = "<b>x</b>"?no_esc?is_markup_output?c + x?is_unknown_date_like?c + 100?number_to_time?string + 100?number_to_datetime?string>
<#assign opt = .get_optional_template("maybe.ftl")>
<#if opt.exists><@opt.include /></#if>
<#assign lazy = (items?filter(i -> i.active)?map(i -> i.name))![]>
<#assign nullSafe = (a.b.c)!"x" + (a.b.c)?has_content?c + a.b.c???c>
<#assign methodRef = tags?join>

<#-- ── Deprecated constructs still accepted (labelled deprecated) ── -->
<#-- deprecated: <#foreach>, <#call>, <#comment>, the "= " comparison, <#transform>, ?exists/?if_exists -->
<#foreach item in tags>${item}</#foreach>
<#call early>
<#comment>This block is dropped from the output; deprecated in favour of ordinary comments.</#comment>
<#assign legacyExists = customer.nick?exists?c + customer.nick?if_exists + customer.nick?default("n/a")>
<#transform html_escape>deprecated transform</#transform>

<#-- ── Square-bracket syntax (alternative to angle brackets; a template uses one or the other) ── -->
<#-- The line below is a standalone template fragment written with [ ] tags; shown as plain text here:
[#ftl]
[#assign x = 1]
[#if x == 1]one[#else]other[/#if]
[#list items as item]${item}[#sep], [/#sep][/#list]
[@m.money amount=3 /]
[=x]   [=x?string("0.0")]
-->
