<?xml version="1.0" encoding="UTF-8"?>
<!-- ── Comments ───────────────────────────────────────────────
     XSLT 3.0 (with the whole 1.0 core): warehouse orders XML to an HTML report, paid first.
     TODO: group by warehouse. FIXME: locale-aware numbers. -->
<!DOCTYPE xsl:stylesheet [
  <!ENTITY nbsp "&#160;">
  <!ENTITY copy "&#169;">
]>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ex="https://example.com/orders"
                xmlns:str="http://exslt.org/strings"
                xmlns:exsl="http://exslt.org/common"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:array="http://www.w3.org/2005/xpath-functions/array"
                xmlns:err="http://www.w3.org/2005/xqt-errors"
                expand-text="no"
                extension-element-prefixes="exsl"
                exclude-result-prefixes="ex str">

  <!-- ── Imports (must come first) ───────────────────────── -->
  <xsl:import href="base.xsl"/>
  <xsl:include href="helpers.xsl"/>

  <!-- ── Output, whitespace, keys, formats ───────────────── -->
  <xsl:output method="html" version="4.0" encoding="UTF-8" indent="yes" doctype-public="-//W3C//DTD HTML 4.01//EN" doctype-system="http://www.w3.org/TR/html4/strict.dtd"/>
  <xsl:output method="xml" indent="yes" cdata-section-elements="script"/>
  <xsl:strip-space elements="order items *"/>
  <xsl:preserve-space elements="pre code"/>
  <xsl:key name="order-by-status" match="order" use="@status"/>
  <xsl:key name="item-by-sku" match="item" use="concat(@warehouse, ':', @sku)"/>
  <xsl:decimal-format name="uk" decimal-separator="." grouping-separator="," infinity="∞" NaN="n/a"/>
  <xsl:namespace-alias stylesheet-prefix="ex" result-prefix="xsl"/>

  <!-- ── Parameters, variables, attribute sets ───────────── -->
  <xsl:param name="currency" select="'GBP'"/>
  <xsl:param name="reorder-point" select="25"/>
  <xsl:param name="title">Warehouse &copy; Orders</xsl:param>
  <xsl:variable name="ratio" select="0.75"/>
  <xsl:variable name="big" select="1.5e3"/>
  <xsl:variable name="quote" select="concat('double ', '&quot;', 'quoted', '&quot;')"/>
  <xsl:variable name="paid" select="/orders/order[@status = 'paid']"/>
  <xsl:variable name="fragment">
    <total><xsl:value-of select="sum($paid/total)"/></total>
  </xsl:variable>
  <xsl:attribute-set name="cell">
    <xsl:attribute name="class">cell</xsl:attribute>
    <xsl:attribute name="style">padding: 2px</xsl:attribute>
  </xsl:attribute-set>

  <!-- ── Root template ───────────────────────────────────── -->
  <xsl:template match="/orders" priority="2">
    <html>
      <head>
        <title><xsl:value-of select="$title"/></title>
        <style type="text/css">
          .paid { color: #2a7; }
          .cell { padding: 2px; }
        </style>
        <script type="text/javascript"><![CDATA[
          if (1 < 2 && 3 > 2) { console.log("CDATA keeps < and & literal"); }
        ]]></script>
      </head>
      <body>
        <h1>Orders (<xsl:value-of select="count(order)"/>)</h1>
        <xsl:comment> Generated report </xsl:comment>
        <xsl:processing-instruction name="report">format="html"</xsl:processing-instruction>
        <table border="1">
          <xsl:apply-templates select="order">
            <xsl:sort select="@status = 'paid'" order="descending"/>
            <xsl:sort select="@number" data-type="number" order="ascending"/>
            <xsl:sort select="customer" data-type="text" case-order="upper-first" lang="en"/>
            <xsl:with-param name="highlight" select="true()"/>
          </xsl:apply-templates>
        </table>
        <xsl:call-template name="summary">
          <xsl:with-param name="orders" select="order"/>
          <xsl:with-param name="label">Totals</xsl:with-param>
        </xsl:call-template>
        <xsl:copy-of select="$fragment"/>
        <p>&nbsp;&copy; 2026</p>
      </body>
    </html>
  </xsl:template>

  <!-- ── Matching templates, modes, conditionals ─────────── -->
  <xsl:template match="order" mode="#default">
    <xsl:param name="highlight" select="false()"/>
    <xsl:variable name="total" select="number(total)"/>
    <xsl:variable name="position-label" select="concat('#', position(), ' of ', last())"/>
    <tr>
      <xsl:attribute name="class">
        <xsl:value-of select="@status"/>
        <xsl:if test="$highlight and position() = 1"> first</xsl:if>
      </xsl:attribute>
      <xsl:attribute name="id">order-<xsl:value-of select="@number"/></xsl:attribute>
      <xsl:attribute name="data-total" namespace="">{$total}</xsl:attribute>
      <td xsl:use-attribute-sets="cell">#<xsl:value-of select="@number"/></td>
      <td title="{$position-label}">
        <xsl:value-of select="format-number($total, '#,##0.00', 'uk')"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$currency"/>
      </td>
      <td>
        <xsl:choose>
          <xsl:when test="$total &gt; 100">large</xsl:when>
          <xsl:when test="$total &lt;= 10 and $total != 0">tiny</xsl:when>
          <xsl:when test="not(total)">missing</xsl:when>
          <xsl:otherwise>normal</xsl:otherwise>
        </xsl:choose>
      </td>
      <xsl:if test="@status = 'paid'"><td>&#10003;</td></xsl:if>
      <td>
        <xsl:for-each select="items/item">
          <xsl:sort select="@sku"/>
          <xsl:value-of select="@sku"/>
          <xsl:if test="position() != last()">, </xsl:if>
        </xsl:for-each>
      </td>
      <td><xsl:value-of select="key('order-by-status', @status)[1]/@number"/></td>
      <td><xsl:number value="position()" format="01. "/></td>
      <td><xsl:number level="multiple" count="order|items" format="1.1"/></td>
    </tr>
  </xsl:template>

  <xsl:template match="order[@status = 'cancelled']" priority="3"/>
  <xsl:template match="order[not(total)] | order[total = 0]" mode="empty">
    <em>empty</em>
  </xsl:template>

  <!-- ── Named templates, recursion ──────────────────────── -->
  <xsl:template name="summary">
    <xsl:param name="orders" select="/.."/>
    <xsl:param name="label"/>
    <xsl:param name="n" select="1"/>
    <section>
      <h2><xsl:value-of select="$label"/></h2>
      <p>Revenue: <xsl:value-of select="format-number(sum($orders[@status='paid']/total), '#,##0.00')"/></p>
      <p>Average: <xsl:value-of select="sum($orders/total) div count($orders)"/></p>
      <p>Remainder: <xsl:value-of select="count($orders) mod 3"/></p>
      <p>Range: <xsl:value-of select="floor(2.7) + ceiling(2.1) + round(2.5)"/></p>
      <p>Strings: <xsl:value-of select="concat(substring('abcdef', 2, 3), '|', substring-before('a-b', '-'), '|', substring-after('a-b', '-'), '|', translate('abc', 'abc', 'ABC'), '|', normalize-space('  a  b  '), '|', string-length('abc'))"/></p>
      <p>Tests: <xsl:value-of select="starts-with('abc', 'a') and contains('abc', 'b') and boolean(1) and not(false()) and lang('en')"/></p>
      <p>Context: <xsl:value-of select="concat(name(.), local-name(.), namespace-uri(.))"/></p>
      <p>Generate: <xsl:value-of select="generate-id(.)"/> <xsl:value-of select="system-property('xsl:version')"/> <xsl:value-of select="current()/@x"/> <xsl:value-of select="document('other.xml')/root"/></p>
      <p>Functions: <xsl:value-of select="function-available('str:tokenize')"/> <xsl:value-of select="element-available('xsl:message')"/> <xsl:value-of select="unparsed-entity-uri('logo')"/></p>
      <xsl:if test="$n &lt; 3">
        <xsl:call-template name="summary">
          <xsl:with-param name="orders" select="$orders"/>
          <xsl:with-param name="label" select="concat($label, '+')"/>
          <xsl:with-param name="n" select="$n + 1"/>
        </xsl:call-template>
      </xsl:if>
    </section>
  </xsl:template>

  <!-- ── Axes and node tests in select expressions ───────── -->
  <xsl:template match="item" mode="axes">
    <xsl:value-of select="ancestor::order/@number | ancestor-or-self::*[1]/@id | child::name | descendant::tag | descendant-or-self::node() | following::item[1] | following-sibling::item | parent::items | preceding::item[last()] | preceding-sibling::item[1] | self::item | @sku | attribute::qty"/>
    <xsl:value-of select="text() | comment() | processing-instruction() | processing-instruction('x') | node() | *"/>
    <xsl:value-of select="//item[@qty &lt; $reorder-point][position() &lt; 4]/name"/>
    <xsl:value-of select="(item | other)[last()]/../@*"/>
    <xsl:value-of select="$paid[1]/total"/>
    <xsl:value-of select="ex:custom/@ex:flag"/>
  </xsl:template>

  <!-- ── Copy, identity, messages, fallback ──────────────── -->
  <xsl:template match="@*|node()" mode="identity">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="identity"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="notes">
    <xsl:message terminate="no">Skipping notes</xsl:message>
    <xsl:message terminate="yes">Fatal: unexpected notes element</xsl:message>
    <xsl:fallback>
      <xsl:text disable-output-escaping="yes">&lt;!-- fallback --&gt;</xsl:text>
    </xsl:fallback>
    <xsl:element name="note" namespace="https://example.com/orders">
      <xsl:attribute name="n">{position()}</xsl:attribute>
      <xsl:apply-templates select="." mode="axes"/>
    </xsl:element>
    <xsl:apply-imports/>
  </xsl:template>

  <xsl:template match="text()"><xsl:value-of select="normalize-space(.)"/></xsl:template>
  <!-- ══ XSLT 2.0 / 3.0 additions ══════════════════════════ -->
  <xsl:use-package name="https://example.com/packages/util" package-version="1.0">
    <xsl:accept component="function" names="ex:*" visibility="public"/>
    <xsl:override><xsl:function name="ex:hook" as="xs:string"><xsl:sequence select="'overridden'"/></xsl:function></xsl:override>
  </xsl:use-package>
  <xsl:mode name="summary" streamable="no" on-no-match="shallow-copy" on-multiple-match="use-last" warning-on-no-match="false" visibility="public"/>
  <xsl:mode on-no-match="text-only-copy"/>
  <xsl:import-schema namespace="https://example.com/orders" schema-location="orders.xsd"/>
  <xsl:character-map name="symbols">
    <xsl:output-character character="&#169;" string="(c)"/>
  </xsl:character-map>
  <xsl:output name="json-out" method="json" indent="yes" use-character-maps="symbols"/>
  <xsl:global-context-item as="document-node(element(orders))" use="required"/>
  <xsl:accumulator name="running-total" as="xs:decimal" initial-value="0">
    <xsl:accumulator-rule match="order" select="$value + xs:decimal(total)" phase="end"/>
  </xsl:accumulator>
  <xsl:param name="threshold" as="xs:decimal" select="100.00" static="yes" required="no"/>
  <xsl:variable name="seq" as="xs:integer*" select="(1, 2, 3)"/>
  <xsl:variable name="m" as="map(xs:string, item()*)" select="map { 'sku': 'WGT-100', 'tags': ['a', 'b'] }"/>
  <xsl:variable name="inline" select="function($x) { $x * 2 }"/>
  <xsl:variable name="u" select="let $a := 1, $b := 2 return $a + $b"/>
  <xsl:variable name="concat" select="'a' || 'b'"/>
  <xsl:variable name="arrow" select="'text' =&gt; upper-case() =&gt; substring(1, 2)"/>
  <xsl:variable name="simple-map" select="(1, 2, 3) ! (. * 2)"/>
  <xsl:variable name="tmpl" select="`Total: {sum($seq)}`"/>
  <xsl:variable name="range" select="1 to 10"/>
  <xsl:variable name="cond" select="if ($threshold gt 50) then 'high' else 'low'"/>
  <xsl:variable name="quant" select="every $s in $seq satisfies $s gt 0"/>
  <xsl:variable name="for-expr" select="for $s in $seq return $s * $s"/>
  <xsl:variable name="cast" select="xs:integer('42') castable as xs:integer"/>
  <xsl:variable name="str" select="string-join(for $i in 1 to 3 return string($i), ',')"/>
  <xsl:variable name="regex" select="replace('abc', '(b)', '[$1]')"/>
  <xsl:variable name="tokens" select="tokenize('a,b,c', ',')"/>
  <xsl:variable name="avg" select="avg($seq) + max($seq) + min($seq) + sum($seq)"/>
  <xsl:variable name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
  <xsl:variable name="doc" select="doc('other.xml')//order[1]"/>
  <xsl:variable name="json" select="parse-json('{&quot;a&quot;: [1, 2]}')"/>
  <xsl:variable name="xp" select="parse-xml('&lt;a/&gt;')/a"/>
  <xsl:variable name="ser" select="serialize($doc, map { 'method': 'xml' })"/>

  <xsl:function name="ex:money" as="xs:string" visibility="public" override-extension-function="no">
    <xsl:param name="n" as="xs:decimal"/>
    <xsl:param name="cur" as="xs:string"/>
    <xsl:sequence select="concat(format-number($n, '#,##0.00'), ' ', $cur)"/>
  </xsl:function>

  <xsl:function name="ex:fact" as="xs:integer" cache="yes">
    <xsl:param name="n" as="xs:integer"/>
    <xsl:sequence select="if ($n le 1) then 1 else $n * ex:fact($n - 1)"/>
  </xsl:function>

  <xsl:template match="/" mode="summary" name="main" as="item()*" expand-text="yes" use-when="system-property('xsl:version') ge '3.0'">
    <xsl:context-item as="document-node()" use="required"/>
    <xsl:param name="verbose" as="xs:boolean" select="false()" tunnel="yes" required="no"/>
    <xsl:variable name="all" as="element(order)*" select="//order"/>

    <!-- grouping -->
    <xsl:for-each-group select="$all" group-by="@status">
      <xsl:sort select="current-grouping-key()"/>
      <group status="{current-grouping-key()}" count="{count(current-group())}">
        <xsl:for-each select="current-group()"><xsl:value-of select="@number"/><xsl:if test="position() ne last()">, </xsl:if></xsl:for-each>
      </group>
    </xsl:for-each-group>
    <xsl:for-each-group select="$all" group-adjacent="@status"><xsl:sequence select="current-group()"/></xsl:for-each-group>
    <xsl:for-each-group select="$all" group-starting-with="order[@status = 'paid']"><xsl:sequence select="current-group()"/></xsl:for-each-group>
    <xsl:for-each-group select="$all" group-ending-with="order[@status = 'open']" composite="yes" collation="http://www.w3.org/2005/xpath-functions/collation/codepoint"><xsl:sequence select="current-group()"/></xsl:for-each-group>

    <!-- regular expressions -->
    <xsl:analyze-string select="'WGT-100 GDG-200'" regex="([A-Z]{{3}})-(\d+)" flags="i">
      <xsl:matching-substring><sku code="{regex-group(1)}" num="{regex-group(2)}"/></xsl:matching-substring>
      <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
    </xsl:analyze-string>

    <!-- error handling -->
    <xsl:try rollback-output="yes">
      <xsl:sequence select="1 div 0"/>
      <xsl:catch errors="err:FOAR0001 err:FOAR0002"><xsl:message select="$err:description"/></xsl:catch>
      <xsl:catch><xsl:value-of select="$err:code, $err:module, $err:line-number, $err:column-number"/></xsl:catch>
      <xsl:finally><done/></xsl:finally>
    </xsl:try>
    <xsl:assert test="count($all) ge 0" error-code="ex:ASSERT">Count must not be negative</xsl:assert>

    <!-- iteration, merging, forking -->
    <xsl:iterate select="$all">
      <xsl:param name="running" as="xs:decimal" select="0"/>
      <xsl:on-completion><total><xsl:value-of select="$running"/></total></xsl:on-completion>
      <xsl:variable name="next" select="$running + xs:decimal(total)"/>
      <xsl:if test="$next gt 1000"><xsl:break><stopped/></xsl:break></xsl:if>
      <xsl:next-iteration><xsl:with-param name="running" select="$next"/></xsl:next-iteration>
    </xsl:iterate>
    <xsl:merge>
      <xsl:merge-source select="doc('a.xml')//order" for-each-source="'a.xml'" streamable="no">
        <xsl:merge-key select="@number" order="ascending" data-type="number"/>
      </xsl:merge-source>
      <xsl:merge-source select="doc('b.xml')//order"><xsl:merge-key select="@number"/></xsl:merge-source>
      <xsl:merge-action><merged><xsl:copy-of select="current-merge-group()"/></merged></xsl:merge-action>
    </xsl:merge>
    <xsl:fork>
      <xsl:sequence><xsl:value-of select="count($all)"/></xsl:sequence>
      <xsl:sequence><xsl:value-of select="sum($all/total)"/></xsl:sequence>
    </xsl:fork>

    <!-- streaming and sources -->
    <xsl:source-document href="big.xml" streamable="yes" use-accumulators="running-total">
      <xsl:value-of select="count(*/order)"/>
    </xsl:source-document>

    <!-- maps and arrays -->
    <xsl:map>
      <xsl:map-entry key="'sku'" select="'WGT-100'"/>
      <xsl:map-entry key="'qty'"><xsl:value-of select="12"/></xsl:map-entry>
    </xsl:map>
    <xsl:variable name="arr" select="array { 1, 2, 3 }"/>
    <xsl:value-of select="$arr?1, $m?sku, $m?*, array:size($arr), map:size($m), map:keys($m)"/>

    <!-- populate-conditional content -->
    <xsl:where-populated><section><xsl:apply-templates select="$all[@status = 'paid']"/></section></xsl:where-populated>
    <xsl:on-empty><p>No paid orders</p></xsl:on-empty>
    <xsl:on-non-empty><p>Has orders</p></xsl:on-non-empty>

    <!-- sorting, namespaces, output, evaluate -->
    <xsl:perform-sort select="$all"><xsl:sort select="xs:decimal(total)" order="descending"/></xsl:perform-sort>
    <xsl:namespace name="h" select="'http://www.w3.org/1999/xhtml'"/>
    <xsl:result-document href="report.html" format="html5" method="html" indent="yes" validation="strict" type="ex:report" item-separator="&#10;">
      <html><body><xsl:value-of select="$tmpl"/></body></html>
    </xsl:result-document>
    <xsl:result-document href="out.json" format="json-out"><xsl:sequence select="serialize($m, map { 'method': 'json' })"/></xsl:result-document>
    <xsl:evaluate xpath="'1 + 2'" context-item="." namespace-context="." with-params="map { QName('', 'x'): 1 }" base-uri="." schema-aware="no"/>
    <xsl:next-match><xsl:with-param name="verbose" select="true()" tunnel="yes"/></xsl:next-match>
    <xsl:apply-templates select="$all" mode="summary"><xsl:with-param name="verbose" select="true()" tunnel="yes"/></xsl:apply-templates>
    <xsl:copy copy-namespaces="no" inherit-namespaces="yes" use-attribute-sets="cell" type="xs:untyped" validation="preserve">
      <xsl:copy-of select="@*" copy-accumulators="yes" validation="strip"/>
    </xsl:copy>
    <xsl:document validation="lax"><x/></xsl:document>
    <xsl:attribute name="id" select="generate-id()" separator=" " type="xs:ID"/>
    <xsl:value-of select="$all/@number" separator=", "/>
    <xsl:sequence select="$all/total ! xs:decimal(.)"/>
    <xsl:text expand-text="no">{literal braces}</xsl:text>
    <p title="{ex:money(12.5, 'GBP')} {{literal}} {$threshold}">Total { sum($all/total) } and {{escaped}}</p>
    <xsl:stream href="legacy.xml"><xsl:copy-of select="."/></xsl:stream>
    <xsl:number select="$all[1]" level="any" count="order" from="orders" format="A" lang="en" letter-value="alphabetic" ordinal="yes" grouping-separator="," grouping-size="3"/>
    <xsl:message select="'3.0 template done'" error-code="ex:MSG" terminate="no"/>
    <xsl:fallback><xsl:message terminate="yes">Processor does not support XSLT 3.0</xsl:message></xsl:fallback>
  </xsl:template>

  <xsl:template match="order[@status = 'paid']" mode="summary" priority="5">
    <xsl:param name="verbose" as="xs:boolean" tunnel="yes"/>
    <xsl:variable name="rt" select="accumulator-after('running-total')"/>
    <xsl:variable name="before" select="accumulator-before('running-total')"/>
    <paid n="{@number}" before="{$before}" after="{$rt}" verbose="{$verbose}"/>
  </xsl:template>

  <xsl:template name="initial" visibility="final"><xsl:param name="x" as="item()*" select="()"/></xsl:template>
  <xsl:expose component="template" names="initial" visibility="public"/>
  <xsl:key name="by-sku" match="item" use="@sku" composite="yes" collation="http://www.w3.org/2005/xpath-functions/collation/codepoint"/>
  <xsl:strip-space elements="*"/>
</xsl:stylesheet>
