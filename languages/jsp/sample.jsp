<%-- Jakarta Server Pages 4.0 (Jakarta EE 11), Expression Language 6.0 — syntax showcase; page, tag-file and XML-syntax forms are shown together and cannot all be valid in one real file --%>
<%-- ── JSP comments ── --%>
<%-- Hidden JSP comment: never sent to the browser. TODO: paginate --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
    import="java.util.*, java.text.SimpleDateFormat, com.example.warehouse.model.*"
    session="true" buffer="16kb" autoFlush="true" isThreadSafe="true"
    errorPage="/WEB-INF/views/error.jsp" isErrorPage="false" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="sql" uri="jakarta.tags.sql" %>
<%@ taglib prefix="x" uri="jakarta.tags.xml" %>
<%@ taglib prefix="wh" tagdir="/WEB-INF/tags/warehouse" %>
<%@ include file="/WEB-INF/fragments/header.jspf" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title><c:out value="${warehouse.name}" default="Warehouse" escapeXml="true" /> — Stock</title>
  <style>
    .low { color: #b00020; font-weight: bold; }
    .ok  { color: #2e7d32; }
  </style>
  <script>
    const warehouseId = ${warehouse.id};
    const label = "<c:out value='${warehouse.name}' />";
    function confirmShip(sku) { return confirm("Ship " + sku + "?"); }
  </script>
</head>
<body>

<%-- ── Declarations ── --%>
<%!
  private static final int LOW_STOCK = 10;
  private int hits = 0;

  /** Formats a quantity with its unit. */
  private String format(int quantity, String unit) {
    return quantity + " " + unit + (quantity == 1 ? "" : "s");
  }

  public void jspInit() { hits = 0; }
%>

<%-- ── Scriptlets ── --%>
<%
  // Java line comment inside a scriptlet
  /* block comment */
  int year = java.time.Year.now().getValue();
  String greeting = "Hello, \"" + request.getParameter("user") + "\"\n";
  List<Item> items = (List<Item>) request.getAttribute("items");
  if (items == null) {
    items = new ArrayList<>();
  }
  hits++;
  for (Item item : items) {
    if (item.getQuantity() < LOW_STOCK) {
      out.println("<!-- low: " + item.getSku() + " -->");
    }
  }
  try {
    Integer.parseInt("12x");
  } catch (NumberFormatException e) {
    application.log("bad number", e);
  }
%>

<%-- ── Expressions ── --%>
<p>Year: <%= year %>, hits: <%= hits %>, <%= format(3, "pallet") %>, <%= new Date() %></p>
<p>Session: <%= session.getId() %> via <%= request.getMethod() %> on <%= pageContext.getServletContext().getServerInfo() %></p>

<%-- ── Expression language ── --%>
<h1>Stock for ${fn:toUpperCase(warehouse.name)}</h1>
<p>${warehouse.bins.size()} bins, ${not empty items ? 'non-empty' : 'empty'},
   total ${1 + 2 * 3 - 4 / 2 mod 3}, ${param.q eq 'x' and requestScope.flag or false},
   ${sessionScope.user.name ne null}, ${items[0].sku}, ${header['User-Agent']},
   ${cookie.theme.value}, ${initParam.version}, ${pageScope.answer lt 42}, #{deferred.expression}</p>
<p>Escaped \${literal} and a string ${"quoted \"text\""} and ${'single'} and ${true} ${null} ${3.14} ${0x1F}.</p>

<%-- ── JSTL core ── --%>
<c:set var="total" value="0" scope="page" />
<c:set var="greeting">Welcome, ${user.name}</c:set>
<c:if test="${empty items}">
  <p class="muted">No stock.</p>
</c:if>
<c:choose>
  <c:when test="${items.size() > 100}"><p>Large</p></c:when>
  <c:when test="${items.size() > 10}"><p>Medium</p></c:when>
  <c:otherwise><p>Small</p></c:otherwise>
</c:choose>
<table>
  <thead><tr><th>#</th><th>SKU</th><th>Qty</th><th>Price</th><th>Updated</th></tr></thead>
  <tbody>
  <c:forEach var="item" items="${items}" varStatus="row" begin="0" end="99" step="1">
    <tr class="${item.quantity < 10 ? 'low' : 'ok'}${row.last ? ' last' : ''}">
      <td>${row.count}</td>
      <td><c:out value="${item.sku}" /></td>
      <td><fmt:formatNumber value="${item.quantity}" type="number" groupingUsed="true" /></td>
      <td><fmt:formatNumber value="${item.unitPrice}" type="currency" currencySymbol="£" /></td>
      <td><fmt:formatDate value="${item.updatedAt}" pattern="yyyy-MM-dd HH:mm" timeZone="UTC" /></td>
      <td><a href="<c:url value='/items/edit'><c:param name='sku' value='${item.sku}' /></c:url>"
             onclick="return confirmShip('${item.sku}')">Edit</a></td>
    </tr>
    <c:set var="total" value="${total + item.quantity}" />
  </c:forEach>
  </tbody>
</table>
<c:forTokens items="north,south,east" delims="," var="zone"><span>${zone}</span></c:forTokens>
<c:catch var="failure"><c:import url="/WEB-INF/optional.jsp" /></c:catch>
<c:if test="${failure != null}"><c:remove var="failure" /></c:if>
<c:redirect url="/done" context="/warehouse" />

<%-- ── Standard actions ── --%>
<jsp:useBean id="cart" class="com.example.warehouse.Cart" scope="session" />
<jsp:setProperty name="cart" property="owner" value="${user.name}" />
<jsp:getProperty name="cart" property="size" />
<jsp:include page="/WEB-INF/fragments/footer.jsp" flush="true">
  <jsp:param name="year" value="<%= year %>" />
</jsp:include>
<jsp:forward page="/next.jsp" />
<jsp:element name="div"><jsp:attribute name="class">dyn</jsp:attribute><jsp:body>Body</jsp:body></jsp:element>
<jsp:text>Literal text</jsp:text>
<jsp:plugin type="applet" code="Chart.class" codebase="/applets"><jsp:params><jsp:param name="k" value="v" /></jsp:params></jsp:plugin>

<%-- ── Custom tags ── --%>
<wh:bin code="A-01" capacity="${500}" highlight="true">
  <jsp:attribute name="title">Primary bin</jsp:attribute>
  <jsp:body>Contents: <%= items.size() %></jsp:body>
</wh:bin>

<%-- ── CDATA, entities, inline XML-style ── --%>
<![CDATA[ raw <text> & more ]]>
&copy; <%= year %> Example Ltd &mdash; &lt;ops@example.com&gt;
<footer data-ip="192.0.2.10" data-token="example-not-a-real-key">Contact ${fn:escapeXml(contact)}</footer>

<%-- ── Rare constructs: remaining directives ── --%>
<%@ page extends="com.example.warehouse.BasePage" language="java" isELIgnored="false" deferredSyntaxAllowedAsLiteral="false" trimDirectiveWhitespaces="false" defaultContentType="text/html" responseEncoding="UTF-8" scriptingEnabled="true" info="Stock page" %>
<%@ tag display-name="bin" body-content="scriptless" dynamic-attributes="attrs" small-icon="icon.png" description="A bin" example="&lt;wh:bin/&gt;" language="java" import="java.util.*" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ attribute name="code" required="true" rtexprvalue="true" type="java.lang.String" fragment="false" description="Bin code" %>
<%@ variable name-given="count" variable-class="java.lang.Integer" scope="NESTED" declare="true" %>
<%@ variable name-from-attribute="alias" alias="aliasVar" %>
<%@ taglib uri="http://example.com/tags" prefix="ex" %>

<%-- XML-syntax equivalents --%>
<jsp:root xmlns:jsp="http://java.sun.com/JSP/Page" xmlns:c="jakarta.tags.core" version="3.1">
  <jsp:directive.page contentType="text/html;charset=UTF-8" />
  <jsp:directive.include file="/WEB-INF/fragments/header.jspf" />
  <jsp:declaration>int xmlCounter = 0;</jsp:declaration>
  <jsp:scriptlet>xmlCounter++;</jsp:scriptlet>
  <jsp:expression>xmlCounter</jsp:expression>
  <jsp:output omit-xml-declaration="false" doctype-root-element="html" doctype-public="-//W3C//DTD XHTML 1.0//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" />
  <jsp:plugin type="bean" code="Chart" codebase="/applets" name="chart" archive="a.jar" align="top" height="10" width="10" hspace="1" vspace="1" jreversion="1.8" nspluginurl="x" iepluginurl="y" mayscript="true">
    <jsp:params><jsp:param name="color" value="red" /></jsp:params>
    <jsp:fallback>Plugin not supported</jsp:fallback>
  </jsp:plugin>
  <jsp:invoke fragment="body" var="result" varReader="reader" scope="page" />
  <jsp:doBody var="inner" varReader="innerReader" scope="request" />
  <jsp:setProperty name="cart" property="*" />
  <jsp:setProperty name="cart" param="qty" property="quantity" />
  <jsp:useBean id="b2" type="java.util.List" beanName="com.example.Bean" class="java.util.ArrayList"><jsp:setProperty name="b2" property="x" value="1" /></jsp:useBean>
</jsp:root>

<%-- ── Rare constructs: EL in full ── --%>
${1 + 2 - 3 * 4 div 5 mod 6} ${7 / 2} ${7 % 3} ${-x} ${!flag} ${not flag}
${a == b} ${a eq b} ${a != b} ${a ne b} ${a < b} ${a lt b} ${a > b} ${a gt b} ${a <= b} ${a le b} ${a >= b} ${a ge b}
${a && b} ${a and b} ${a || b} ${a or b} ${empty list} ${not empty list} ${a ? b : c} ${a ? (b ? 1 : 2) : 3}
${x instanceof String} ${a += b} ${a = 5} ${a; b} ${1 + 2; 3 + 4}
${"string" += 'concat'} ${'single \'escaped\''} ${"double \"escaped\""} ${"backslash \\"} ${'${'}
${true} ${false} ${null} ${42} ${-42} ${3.14} ${1e3} ${1.5E-3} ${0x1F}
${list[0]} ${map['key']} ${map.key} ${bean.property.nested} ${array[1][2]} ${list.size()} ${bean.method(1, 'two')}
${(x, y) -> x + y} ${((x, y) -> x + y)(1, 2)} ${list.stream().map(i -> i * 2).toList()} ${[1, 2, 3]} ${{'a': 1, 'b': 2}} ${{1, 2, 3}}
${pageScope.a} ${requestScope.b} ${sessionScope.c} ${applicationScope.d} ${param.e} ${paramValues.f[0]}
${header.g} ${headerValues.h} ${cookie.i.value} ${initParam.j} ${pageContext.request.contextPath}
${fn:contains(s, 't')} ${fn:containsIgnoreCase(s, 'T')} ${fn:endsWith(s, 'x')} ${fn:escapeXml(s)} ${fn:indexOf(s, 'x')}
${fn:join(arr, ',')} ${fn:length(s)} ${fn:replace(s, 'a', 'b')} ${fn:split(s, ',')} ${fn:startsWith(s, 'x')}
${fn:substring(s, 1, 3)} ${fn:substringAfter(s, 'x')} ${fn:substringBefore(s, 'x')} ${fn:toLowerCase(s)} ${fn:toUpperCase(s)} ${fn:trim(s)}
#{bean.value} #{bean.method()} #{not empty x} #{a ? 'b' : 'c'}
\${escaped} \#{escaped} $\{not-el} ${'$'}{literal}

<%-- ── Rare constructs: remaining JSTL ── --%>
<fmt:setLocale value="en_GB" variant="x" scope="session" />
<fmt:setBundle basename="messages" var="bundle" scope="page" />
<fmt:bundle basename="messages" prefix="stock."><fmt:message key="title" var="t" scope="request" /></fmt:bundle>
<fmt:message key="welcome" bundle="${bundle}"><fmt:param value="${user.name}" /><fmt:param>second</fmt:param></fmt:message>
<fmt:parseNumber value="1,234.5" type="number" pattern="#,##0.0" parseLocale="en_GB" integerOnly="false" var="num" scope="page" />
<fmt:parseDate value="2026-01-31" pattern="yyyy-MM-dd" timeZone="UTC" parseLocale="en" dateStyle="short" timeStyle="short" type="both" var="d" />
<fmt:formatNumber value="0.75" type="percent" minFractionDigits="1" maxFractionDigits="2" minIntegerDigits="1" maxIntegerDigits="5" currencyCode="GBP" var="pct" />
<fmt:formatDate value="${d}" type="both" dateStyle="medium" timeStyle="short" timeZone="Europe/London" var="fd" scope="page" />
<fmt:timeZone value="UTC"><fmt:formatDate value="${d}" /></fmt:timeZone>
<fmt:setTimeZone value="Europe/London" var="tz" scope="session" />
<fmt:requestEncoding value="UTF-8" />
<sql:setDataSource dataSource="jdbc/stock" var="ds" scope="application" driver="org.example.Driver" url="jdbc:example://192.0.2.10/stock" user="reader" password="example-not-a-real-key" />
<sql:query dataSource="${ds}" var="rows" startRow="0" maxRows="10" scope="page">SELECT sku, qty FROM stock WHERE qty &lt; ? <sql:param value="${10}" /></sql:query>
<sql:transaction dataSource="${ds}" isolation="read_committed"><sql:update var="n" sql="UPDATE stock SET qty = ? WHERE sku = ?"><sql:param value="5" /><sql:param value="A-100" /><sql:dateParam value="${d}" type="date" /></sql:update></sql:transaction>
<x:parse doc="${xml}" var="doc" scope="page" systemId="id" filter="${f}" varDom="dom" scopeDom="request" />
<x:out select="$doc/stock/item[1]/@sku" escapeXml="true" />
<x:set select="$doc//item" var="items" scope="page" />
<x:if select="$doc/stock/@ok = 'true'">ok</x:if>
<x:choose><x:when select="$doc/a">A</x:when><x:otherwise>B</x:otherwise></x:choose>
<x:forEach select="$doc//item" var="i" varStatus="st"><x:out select="$i/@sku" /></x:forEach>
<x:transform doc="${xml}" xslt="${xsl}" result="${res}" var="out" scope="page"><x:param name="p" value="v" /></x:transform>
<c:import url="/x.jsp" var="imp" scope="page" varReader="rdr" context="/ctx" charEncoding="UTF-8"><c:param name="k" value="v" /></c:import>
<c:url value="/items" var="u" scope="page" context="/ctx"><c:param name="a" value="1" /></c:url>
<c:out value="${x}" default="none" escapeXml="false" />
<c:remove var="tmp" scope="session" />
<c:set target="${bean}" property="name" value="x" />
<c:forEach items="${rows.rows}" var="r" varStatus="s" begin="1" end="5" step="2"><c:out value="${r.sku}" /></c:forEach>
<c:forEach var="i" begin="1" end="3">${i}</c:forEach>
<c:forTokens items="a;b" delims=";" var="t" varStatus="s" begin="0" end="1" step="1">${t}</c:forTokens>

<%-- ── Rare constructs: scriptlet corners ── --%>
<% for (int i = 0; i < 3; i++) { %><li><%= i %></li><% } %>
<% if (hits > 0) { %>positive<% } else { %>zero<% } %>
<% out.print("\u00e9 \"quoted\" %\> not closed"); %>
<%= "string with %\> inside" %>
<% String s = """
    text block in a scriptlet
    """; %>
<% response.setHeader("X-Stock", "1"); request.setAttribute("k", "v"); session.invalidate(); %>
<% pageContext.setAttribute("a", 1, PageContext.REQUEST_SCOPE); config.getServletName(); page.hashCode(); exception.getMessage(); %>
<%!  static { System.out.println("class init"); }  public void jspDestroy() {}  %>
<% try { %>try<% } catch (Exception ex) { %>catch<% } finally { %>finally<% } %>
</body>
</html>
