xquery version "3.1" encoding "UTF-8";

(: XQuery 3.1 (W3C Recommendation; XQuery 4.0 is still a draft) — syntax showcase
   ── Comments ───────────────────────────────────────────────
   XQuery 3.1: the warehouse stock report.
   (: comments nest in XQuery :)
   TODO: paginate. FIXME: locale-aware sort.
:)

(:~
 : Doc comment (XQDoc) for the module.
 : @author Acme Engineering
 : @version 1.0
 : @param $n the amount
 : @return a formatted string
 :)

(: ── Prolog: namespaces, options, imports ───────────────── :)
declare namespace ex = "https://example.com/orders";
declare namespace inv = "https://example.com/inventory";
declare default element namespace "http://www.w3.org/1999/xhtml";
declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare boundary-space strip;
declare default collation "http://www.w3.org/2005/xpath-functions/collation/codepoint";
declare base-uri "https://example.com/base/";
declare construction preserve;
declare ordering ordered;
declare default order empty least;
declare copy-namespaces preserve, no-inherit;
declare decimal-format ex:money decimal-separator = "." grouping-separator = "," digit = "#";
declare option output:method "html";
declare option output:indent "yes";
import schema namespace s = "https://example.com/schema" at "schema.xsd";
import module namespace util = "https://example.com/util" at "util.xqm", "util2.xqm";

(: ── More prolog declarations ───────────────────────────── :)
declare revalidation strict;
declare variable $ex:typed as map(xs:string, item()*) := map {};
declare variable $ex:fn as function(xs:integer) as xs:integer := function($i) { $i };
declare variable $ex:q := xs:QName("Q{https://example.com/orders}order");
declare variable $ex:seq as item()* := (1, "a");
declare function ex:typed-params($a as xs:string?, $b as xs:integer*, $c as element(ex:order)+, $d as attribute(status)?, $e as document-node(element(ex:orders))?, $f as schema-element(s:order)?, $g as schema-attribute(s:code)?, $h as text()?, $i as comment()?, $j as processing-instruction(php)?, $k as namespace-node()?, $l as node()*, $m as function(*)?, $n as map(*)?, $o as array(*)?, $p as item()+, $q as xs:anyAtomicType*, $r as empty-sequence()) as item()* {
  ()
};
declare %ex:inline function ex:inlined() as xs:boolean { true() };
declare %updating function ex:upd($n as node()) { delete node $n };
declare function ex:external($x as xs:integer) as xs:integer external;
declare option db:chop "false";

(: ── Variables and constants ────────────────────────────── :)
declare variable $ex:reorder-point as xs:integer := 25;
declare variable $ex:ratio := 0.75;
declare variable $ex:currency external := "GBP";
declare variable $ex:big := 1000000;
declare variable $ex:sci := 1.5e-3;
declare variable $ex:hex := xs:hexBinary("DEADBEEF");
declare variable $ex:date := xs:date("2026-03-01");
declare variable $ex:str := "double ""quoted"" with &amp; entity &#169; &#x263A;";
declare variable $ex:str2 := 'single ''quoted''';
declare context item as document-node() external;

(: ── Functions ──────────────────────────────────────────── :)
declare function ex:money($n as xs:decimal) as xs:string {
  format-number($n, "#,##0.00")
};

declare %public function ex:total($orders as element(ex:order)*) as xs:decimal {
  sum($orders/ex:total ! xs:decimal(.))
};

declare %private %updating function ex:cleanup($doc as node()) {
  delete node $doc//ex:draft
};

declare function ex:fact($n as xs:integer) as xs:integer {
  if ($n le 1) then 1 else $n * ex:fact($n - 1)
};

declare function ex:variadic($first as item(), $rest as item()*) as item()+ {
  ($first, $rest)
};

declare %an:annotation("value", 42) function ex:annotated() as empty-sequence() { () };

(: ── Literals and constructors ──────────────────────────── :)
let $int := 42
let $dec := 3.14159
let $dbl := 1.5E10
let $str := "text with ""escaped"" quotes"
let $date := xs:date("2026-03-01")
let $dur := xs:dayTimeDuration("P1DT2H")
let $seq := (1, 2, 3, "four", 5.5)
let $range := 1 to 10
let $empty := ()
let $map := map { "sku": "WGT-100", "qty": 12, "tags": ["a", "b"], "nested": map { 1: "one" } }
let $arr := [1, 2, [3, 4], "five"]
let $arr2 := array { 1 to 5 }
let $fn := function($x as xs:integer) as xs:integer { $x * 2 }
let $inline := function($x) { $x + 1 }
let $named := ex:money#1
let $partial := fn:concat("a", ?)
let $lookup := $map?sku
let $lookup2 := $map?("qty")
let $lookup3 := $arr?1
let $wild := $map?*
let $unary := ?name
let $text := ``[Interpolated `{ $int }` and `{ $str }` in a template string]``

(: ── Operators ──────────────────────────────────────────── :)
let $arith := 1 + 2 - 3 * 4 div 5 idiv 6 mod 7
let $neg := -$int
let $cmp := $int = 1 or $int != 2 and $int < 3 or $int > 4 or $int <= 5 or $int >= 6
let $vcmp := $int eq 1 or $int ne 2 or $int lt 3 or $int gt 4 or $int le 5 or $int ge 6
let $node-cmp := $doc is $doc or $doc << $doc or $doc >> $doc
let $concat := "a" || "b" || "c"
let $simple-map := (1, 2, 3) ! (. * 2)
let $arrow := "text" => upper-case() => substring(1, 2)
let $set := ($seq union $seq) intersect ($seq except $empty)
let $type-ops := $int instance of xs:integer and $int castable as xs:string and ($int cast as xs:double) > 0
let $treat := $int treat as xs:integer
let $if := if ($int > 5) then "big" else "small"
let $switch :=
  switch ($int)
    case 1 case 2 return "low"
    case 3 return "mid"
    default return "other"
let $typeswitch :=
  typeswitch ($seq[1])
    case $i as xs:integer return $i + 1
    case xs:string | xs:decimal return "other"
    default $d return $d
let $quant := some $x in $seq satisfies $x > 3
let $quant2 := every $x in (1, 2), $y in (3, 4) satisfies $x < $y
let $try := try { 1 div 0 } catch err:FOAR0001 | err:FOAR0002 { "division error" } catch * { $err:description }
let $pred := $seq[. > 2][position() = 1 or position() = last()]

(: ── Paths and axes ─────────────────────────────────────── :)
let $orders := doc("orders.xml")/ex:orders/ex:order
let $paid := $orders[@status = "paid"]
let $axes := $orders/child::ex:total | $orders/descendant-or-self::node() | $orders/parent::* | $orders/ancestor::* | $orders/following-sibling::* | $orders/preceding-sibling::* | $orders/attribute::status | $orders/self::ex:order
let $abbr := $orders//ex:total/../@number
let $kind-tests := $orders/(text() | comment() | processing-instruction("x") | element(ex:total) | attribute(status) | document-node() | node())
let $wildcards := $orders/*:total | $orders/ex:* | $orders/@*
let $ns-attr := $orders/@xml:lang

(: ── FLWOR ──────────────────────────────────────────────── :)
let $flwor :=
  for $o at $pos in $paid
  let $total := xs:decimal($o/ex:total)
  where $total > 10
  group by $status := $o/@status
  order by $total descending empty greatest, $o/@number ascending collation "http://www.w3.org/2005/xpath-functions/collation/codepoint"
  count $c
  return <row n="{ $c }">{ $total }</row>
let $window :=
  for tumbling window $w in (1 to 10)
    start $s at $sp when $s mod 3 = 1
    end $e at $ep when $ep - $sp = 2
  return <w>{ $w }</w>
let $sliding := for sliding window $w in $seq start when true() only end when fn:true() return $w
let $allowing := for $x allowing empty in () return $x

(: ── Direct constructors and computed constructors ──────── :)
return
  <table class="orders" xmlns:h="http://www.w3.org/1999/xhtml">
    <!-- XML comment inside a direct constructor -->
    <caption>{ count($paid) } of { count($orders) } paid &amp; &lt;done&gt; {{ literal braces }}</caption>
    {
      for $o in $paid
      let $total := xs:decimal($o/ex:total)
      where $total > 10
      order by $o/@number descending
      return
        <tr id="r-{ data($o/@number) }" class='{ if ($total > 100) then "large" else "small" }'>
          <td>#{ data($o/@number) }</td>
          <td>{ ex:money($total) }</td>
          <td>{ if ($total > 100) then "large" else "small" }</td>
          <td><![CDATA[Raw <text> & CDATA]]></td>
          <?target processing instruction?>
        </tr>
    }
    { element footer { attribute class { "ft" }, text { "computed" }, comment { "computed comment" }, processing-instruction pi { "data" } } }
    { document { <root/> } }
    { namespace ex { "https://example.com/orders" } }
    { validate strict { <ex:order/> } }
    { ordered { $seq } }
    { unordered { $seq } }
    { <p>nested { <b>{ "deeply" }</b> }</p> }
    { util:render(`{ $int }`) }
    { $orders/(. | ..)/string()
      (: comment inside an enclosed expression :) }
  </table>

(: ── XQuery Update Facility and scripting ───────────────── :)
,
(
  insert node <ex:order number="9"/> into doc("orders.xml")/ex:orders,
  insert node <a/> as first into $orders[1],
  insert node <b/> as last into $orders[1],
  insert node <c/> before $orders[1],
  insert node <d/> after $orders[1],
  delete nodes $orders[@status = "cancelled"],
  replace node $orders[1]/ex:total with <ex:total>0</ex:total>,
  replace value of node $orders[1]/@status with "paid",
  rename node $orders[1] as "ex:purchase",
  copy $c := $orders[1] modify (delete node $c/@status) return $c,
  transform copy $c := $orders[1] modify replace value of node $c/@number with 0 return $c
)
,
(: ── Remaining expression forms ──────────────────────────── :)
(
  (# ex:pragma some content #) { 1 + 1 },
  (# db:hint #) (# ex:second #) { $orders },
  $orders/Q{https://example.com/orders}order,
  $orders/Q{}local-name-in-no-namespace,
  fn:true() and fn:false(),
  math:pi() * math:sqrt(2),
  map:get($map, "sku"), map:keys($map), map:put($map, "k", 1), map:merge(($map, $map)), map:for-each($map, function($k, $v) { $k }),
  array:size($arr), array:get($arr, 1), array:append($arr, 1), array:flatten($arr), array:join(($arr, $arr)),
  for $m in [1, 2, 3]?* return $m,
  for $k at $i in map:keys($map) return $i,
  let $x as xs:integer := 5, $y as xs:string := "s" return concat($x, $y),
  $arr?*, $arr?(1 to 2), $map?("a", "b"),
  "text" contains text "word" using stemming using language "en" using wildcards ftand "other" ftor "third" ftnot "fourth",
  $orders[. contains text { "paid", "open" } any word],
  (1, 2, 3) => count(),
  string-join(("a", "b"), ", "),
  "a" ! upper-case(.),
  xs:untypedAtomic("1") + 1,
  xs:QName("ex:name"), xs:anyURI("https://example.com/"), xs:base64Binary("AA=="), xs:boolean("true"),
  xs:dateTime("2026-03-01T09:30:00Z"), xs:time("09:30:00"), xs:duration("P1Y2M"), xs:yearMonthDuration("P1Y"),
  xs:gYear("2026"), xs:gMonthDay("--03-01"), xs:float("1.5"), xs:double("INF"), xs:double("NaN"), xs:double("-0"),
  xs:byte(127), xs:short(1), xs:long(1), xs:unsignedInt(1), xs:positiveInteger(1), xs:token("t"), xs:NCName("n"), xs:language("en"),
  1 idiv 2, 7 mod 3, -1, +1, 1e0, .5, 5., 0.5e-3,
  "&lt;&gt;&amp;&quot;&apos;&#65;&#x41;", 'it''s', "say ""hi""",
  ()
)

(: Not shown: `module namespace` library declarations (a file is either a main module, like this
   one, or a library module) and XQuery 4.0 draft syntax (`for member`, `otherwise`, `fn(...)`,
   choice item types, numeric literal underscores, `declare context value`). :)
