xquery version "3.1";
(: XQuery: paid orders as HTML rows, with a function and a FLWOR expression. :)
declare namespace ex = "https://example.com/orders";
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function ex:money($n as xs:decimal) as xs:string {
  format-number($n, "#,##0.00")
};

let $orders := doc("orders.xml")/ex:orders/ex:order
let $paid := $orders[@status = "paid"]
return
  <table class="orders">
    <caption>{ count($paid) } of { count($orders) } paid</caption>
    {
      for $o in $paid
      let $total := xs:decimal($o/ex:total)
      where $total > 10
      order by $o/@number descending
      return
        <tr>
          <td>#{ data($o/@number) }</td>
          <td>{ ex:money($total) }</td>
          <td>{ if ($total > 100) then "large" else "small" }</td>
        </tr>
    }
  </table>
