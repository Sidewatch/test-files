{* ── Comments ── *}
{* Smarty comment: not sent to the browser.
   The warehouse stock page; $items, $warehouse and $user come from the controller.
   TODO: paginate large warehouses
   FIXME: the low-stock cycle breaks on empty lists *}

{* ── Layout inheritance ── *}
{extends file="layout.tpl"}
{config_load file="site.conf" section="Warehouse"}
{assign var="lowCount" value=0}
{assign "threshold" 25}
{$total = 0}
{$names = ['alpha', 'beta', 'gamma']}
{$map = ['sku' => 'ABC-1', 'qty' => 12, 'nested' => ['a' => 1]]}

{block name="title"}Stock for {$warehouse.name|escape}{/block}

{block name="content"}
  <h1>{#pageTitle#} — {$warehouse.name|escape:'html'}</h1>
  <p>Hello, {$user->name|capitalize}! Today is {$smarty.now|date_format:"%A, %B %e, %Y"}.</p>

  {* ── Variables and modifiers ── *}
  <ul class="facts">
    <li>Region: {$warehouse.region|upper|default:'unknown'}</li>
    <li>Items: {$items|@count} / {$items|count}</li>
    <li>Total: {$total|number_format:2:".":","}</li>
    <li>Note: {$warehouse.note|truncate:40:"…":true|nl2br}</li>
    <li>Raw: {$warehouse.html nofilter}</li>
    <li>Static: {$smarty.const.APP_VERSION} {$smarty.server.REQUEST_URI} {$smarty.get.page}</li>
    <li>Cookie: {$smarty.cookies.theme|default:'light'} Session: {$smarty.session.user_id}</li>
    <li>Math: {$total * 2 + 1} {$threshold - 5} {$threshold / 5} {$threshold % 7}</li>
    <li>Array: {$map.nested.a} {$map['sku']} {$names[0]} {$names.1}</li>
    <li>Method: {$warehouse->address()} Property: {$warehouse->owner->name}</li>
    <li>Interpolated: {"Stock: $total units"} {"Item `$map.sku` ok"}</li>
    <li>Number literals: {1} {-2} {3.14} {0x1F}</li>
    <li>Strings: {'single quoted'} {"double \"quoted\""}</li>
  </ul>

  {* ── Conditionals ── *}
  {if $items|@count == 0}
    <p class="muted">No items yet.</p>
  {elseif $items|@count > 100 && !$user.isAdmin}
    <p class="muted">Too many items.</p>
  {else}
    <table class="items">
      <thead><tr><th>SKU</th><th>Name</th><th>Qty</th></tr></thead>
      <tbody>
      {* ── Loops ── *}
      {foreach from=$items item=item key=index name=stock}
        {if $item.qty lt $threshold}{$lowCount = $lowCount + 1}{/if}
        <tr class="{cycle values='odd,even'} {if $item.qty <= $threshold}low{/if}">
          <td>{$item.sku|escape}</td>
          <td>{$item.name|escape|truncate:30}</td>
          <td class="num">{$item.qty|string_format:"%05d"}</td>
          {if $smarty.foreach.stock.first}<td>first</td>{/if}
          {if $smarty.foreach.stock.last}<td>last of {$smarty.foreach.stock.total}</td>{/if}
          {if $item@iteration is even by 3}<td>every 3rd even</td>{/if}
          {if $item@index is odd}<td>odd</td>{/if}
        </tr>
      {foreachelse}
        <tr><td colspan="3">Nothing to show</td></tr>
      {/foreach}
      </tbody>
    </table>

    {foreach $names as $n}{$n@key}:{$n}{if !$n@last}, {/if}{/foreach}

    {for $i = 1 to 5 step 2}[{$i}]{/for}
    {for $i = 0; $i < 3; $i++}({$i}){/for}

    {section name=row loop=$items start=0 step=1 max=10}
      {$smarty.section.row.index}: {$items[row].sku}
    {sectionelse}
      <em>empty section</em>
    {/section}

    {while $total < 3}{$total++}{/while}
  {/if}

  {* ── Conditions with Smarty operators ── *}
  {if $a eq 1 and $b neq 2 or $c gt 3 && $d lte 4 || $e gte 5 and not $f}x{/if}
  {if $x is div by 3}div{/if}
  {if $x is not div by 3}not div{/if}
  {if isset($map.sku) && !empty($names) && is_array($map)}set{/if}
  {if $v === null || $v !== false || $v == 'str' || $v != "other"}strict{/if}
  {if $n mod 2 == 0}even{/if}
  {if ($a + $b) * $c > 10}grouped{/if}

  {* ── Built-in functions ── *}
  {include file="partials/pagination.tpl" page=$page total=$items|@count}
  {include file="partials/footer.tpl" inline}
  {insert name="getBanner" id=3}
  {assign var="greeting" value="Hello"}
  {assign var=list value=[1, 2, 3]}
  {counter start=1 skip=2 print=false assign=c}
  {counter}
  {cycle values="a,b,c" advance=false}
  {eval var="{$greeting} there"}
  {fetch file="/etc/hostname" assign=hostname}
  {html_options options=$map selected=$map.sku}
  {html_checkboxes name="tags" options=$names separator="<br>"}
  {html_select_date prefix="Start" time=$smarty.now start_year="-5"}
  {html_table loop=$items cols=3 table_attr='border="0"'}
  {mailto address="stock@example.com" encode="javascript"}
  {math equation="x * y / 100" x=$total y=15 format="%.2f" assign=pct}
  {textformat wrap=40 indent=2}A long text that wraps at forty characters.{/textformat}
  {popup_init src="/js/overlib.js"}
  {debug}

  {* ── Capture, literal, strip, nocache ── *}
  {capture name="summary" assign="summaryText"}
    {$items|@count} items in {$warehouse.name}
  {/capture}
  <p>{$smarty.capture.summary}</p>

  {literal}
    <script>
      // Braces here are not Smarty: function f() { return {a: 1}; }
      var stock = { sku: "ABC-1", qty: 12 };
    </script>
  {/literal}

  {strip}
    <ul>
      <li>whitespace</li>
      <li>stripped</li>
    </ul>
  {/strip}

  {nocache}{$smarty.now}{/nocache}
  {php}/* removed in Smarty 3 */{/php}

  {* ── Custom function, block function, modifier chain ── *}
  {my_function arg1="a" arg2=$total flag}
  {my_block param=$map}Content of the block{/my_block}
  {$total|my_modifier:1:'two'|escape:'javascript'}

  {* ── Escaping and delimiters ── *}
  {ldelim}not a tag{rdelim}
  {$smarty.ldelim}
  {$smarty.version} {$smarty.template} {$smarty.current_dir}

  {* ── Function-style calls and expressions ── *}
  {$names|implode:", "}
  {implode(", ", $names)}
  {count($items)}
  {str_repeat('-', 10)}
  {$map.qty|cat:" units"|upper}
  {'literal'|replace:'l':'L'}
  {$items|@array_slice:0:3|@json_encode}

  {$footerHtml nofilter}
  {$footerHtml|escape:"htmlall"}
{/block}

{block name="footer" append}
  <p>{$lowCount} of {$items|@count} need reordering — © Acme Warehousing ✓</p>
{/block}

{block name="head" prepend}
  <meta name="stock" content="{$lowCount}">
{/block}
