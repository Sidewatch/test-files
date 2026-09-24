<#-- FreeMarker: an order confirmation email. -->
<#import "macros.ftl" as m>
<#assign total = 0>
<#setting number_format="0.00">

<h1>Thanks, ${customer.firstName?cap_first}!</h1>

<#if order.items?size == 0>
  <p>Your order is empty.</p>
<#else>
  <table>
    <#list order.items as item>
      <#assign total += item.qty * item.price>
      <tr class="${item?is_odd_item?then('odd', 'even')}">
        <td>${item.sku}</td>
        <td>${item.qty} × ${item.price}</td>
        <td><@m.money amount=item.qty * item.price /></td>
      </tr>
    </#list>
  </table>
  <p>Total: <b><@m.money amount=total /></b></p>
</#if>

<#macro footer year=.now?string("yyyy")>
  <footer>&copy; ${year} Example Ltd</footer>
</#macro>
<@footer />
