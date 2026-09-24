{* Smarty: the orders page; $orders and $user come from the controller. *}
{extends file="layout.tpl"}
{assign var="paidCount" value=0}

{block name="content"}
  <h1>Orders for {$user.name|escape}</h1>

  {if $orders|@count == 0}
    <p class="muted">No orders yet.</p>
  {else}
    <table class="orders">
      {foreach $orders as $order}
        {if $order.paid}{assign var="paidCount" value=$paidCount+1}{/if}
        <tr class="{if $order.paid}paid{else}open{/if} {cycle values='odd,even'}">
          <td>#{$order.number}</td>
          <td>{$order.total|number_format:2}</td>
          <td>{$order.placedAt|date_format:"%Y-%m-%d"}</td>
          {if $order@first}<td><span class="badge">latest</span></td>{/if}
        </tr>
      {/foreach}
    </table>
    <p>{$paidCount} of {$orders|@count} paid</p>
  {/if}

  {include file="partials/pagination.tpl" page=$page}
  {$footerHtml nofilter}
{/block}
