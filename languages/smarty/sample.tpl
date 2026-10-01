{* Smarty 5 — syntax showcase *}
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
  {* {php} blocks and {insert} are not part of Smarty 5 and are left out *}

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

  {* ── More variable forms and assignments ── *}
  {$count = 1}
  {$count++}
  {$count--}
  {$map['extra'] = $names[1]}
  {$key = 'sku'}
  {$map.$key} {$map[$key]}
  {$warehouse->owner->address()->city|upper}
  {$ternary = $count > 1 ? 'many' : 'one'}
  {$flag = !$user.isAdmin && ($count == 1 || $count != 2)}
  {$quoted = "Total: $total, first: $names[0], sku: $map.sku, method: {$warehouse->address()}"}
  {$backtick = "Key `$map.sku` and `$names.0` and `$smarty.now`"}
  {$list = [1, 2, 3]}
  {$assoc = ['a' => ['b' => ['c' => 1]], 'd' => [1, 2]]}
  {$number = 1.5} {$neg = -$count} {$bool = true} {$none = null} {$off = false}
  {$prop = $item@iteration} {$idx = $item@index} {$total_rows = $item@total}
  {* ── Config variables ── *}
  {#pageTitle#} {#bgColor#} {$smarty.config.pageTitle|default:'none'}
  {* ── Special variables ── *}
  {$smarty.get.page} {$smarty.post.name} {$smarty.request.id} {$smarty.session.user_id}
  {$smarty.cookies.theme} {$smarty.server.HTTP_HOST} {$smarty.env.PATH}
  {$smarty.now} {$smarty.const.PHP_VERSION} {$smarty.template} {$smarty.current_dir}
  {$smarty.version} {$smarty.ldelim} {$smarty.rdelim}
  {$smarty.capture.default} {$smarty.capture.summary}
  {$smarty.block.parent} {$smarty.block.child}
  {$smarty.foreach.stock.iteration} {$smarty.section.row.rownum}
  {* ── Whitespace after the delimiter makes it plain text ── *}
  { $not_a_tag } { if $nothing } function() { return 1; }

  {* ── Foreach: every form, with break/continue and properties ── *}
  {foreach $items as $row}{$row.sku}{foreachelse}none{/foreach}
  {foreach $items as $k => $row}{$k}={$row.sku}{/foreach}
  {foreach from=$items item=row key=k name=loop1}
    {if $row@first}first{/if}{if $row@last}last{/if}
    {$row@index} {$row@iteration} {$row@total} {$row@key} {$row@show}
    {if $row.skip}{continue}{/if}
    {if $row.stop}{break}{/if}
    {$smarty.foreach.loop1.index} {$smarty.foreach.loop1.show}
  {/foreach}
  {foreach from=$items item=row}{$row.sku}{/foreach}
  {foreach key=k item=row from=$map}{$k}{/foreach}
  {foreach $map as $mapKey => $mapValue}{$mapKey}: {$mapValue|escape}{/foreach}
  {foreach $nested as $outer}
    {foreach $outer as $inner}{$inner@key}{/foreach}
  {/foreach}

  {* ── For, while and section variants ── *}
  {for $i = 0 to 10}{$i}{/for}
  {for $i = 10 to 0 step -2}{$i}{forelse}nothing{/for}
  {for $x = 0, $y = count($items); $x < $y; $x++}{$x}{/for}
  {while $count < 5}{$count++}{/while}
  {section name=s loop=$items show=true}
    {$smarty.section.s.index} {$smarty.section.s.iteration} {$smarty.section.s.first} {$smarty.section.s.last}
    {$smarty.section.s.total} {$smarty.section.s.index_prev} {$smarty.section.s.index_next} {$smarty.section.s.rownum}
    {$items[s].sku}
  {/section}
  {section name=t start=-1 loop=$items step=-1}{$items[t].sku}{/section}
  {section loop=5 name=u max=3}{$smarty.section.u.index}{/section}

  {* ── Conditionals: every comparison and alias ── *}
  {if $a == $b}eq{/if}{if $a eq $b}eq{/if}{if $a != $b}ne{/if}{if $a ne $b}ne{/if}{if $a neq $b}neq{/if}
  {if $a > $b}gt{/if}{if $a gt $b}gt{/if}{if $a < $b}lt{/if}{if $a lt $b}lt{/if}
  {if $a >= $b}ge{/if}{if $a ge $b}ge{/if}{if $a gte $b}gte{/if}{if $a <= $b}le{/if}{if $a le $b}le{/if}{if $a lte $b}lte{/if}
  {if $a && $b}and{/if}{if $a and $b}and{/if}{if $a || $b}or{/if}{if $a or $b}or{/if}
  {if !$a}not{/if}{if not $a}not{/if}{if $a % 2}mod{/if}{if $a mod 2}mod{/if}
  {if $a is even}even{/if}{if $a is not even}odd{/if}{if $a is odd}odd{/if}{if $a is not odd}even{/if}
  {if $a is even by 2}even by{/if}{if $a is odd by 3}odd by{/if}{if $a is div by 4}div by{/if}
  {if $a === 0 && $b !== ''}identical{/if}
  {if is_array($a) && count($a) > 0 && in_array($b, $a)}php functions{/if}
  {if $a|count > 1 && $b|strlen < 4}modifiers in conditions{/if}
  {if $obj->isReady() && $obj->count > 0}objects{/if}
  {if ($a || $b) && !($c && $d)}grouped{/if}
  {if empty($a)}empty{elseif isset($b)}isset{else if $c}else if{else}other{/if}
  {if $a}{if $b}nested{/if}{/if}

  {* ── Modifiers: the complete built-in set ── *}
  {$text|capitalize}{$text|capitalize:true}{$text|cat:'!'}{$text|count_characters}{$text|count_characters:true}
  {$text|count_paragraphs}{$text|count_sentences}{$text|count_words}
  {$now|date_format}{$now|date_format:'%Y-%m-%d'}{$now|date_format:'%H:%M:%S':$fallback}
  {$text|default:''}{$text|escape}{$text|escape:'html'}{$text|escape:'htmlall'}{$text|escape:'url'}
  {$text|escape:'urlpathinfo'}{$text|escape:'quotes'}{$text|escape:'hex'}{$text|escape:'hexentity'}
  {$text|escape:'decentity'}{$text|escape:'javascript'}{$text|escape:'mail'}{$text|escape:'nonstd'}
  {$text|from_charset:'ISO-8859-1'}{$text|to_charset:'UTF-8'}
  {$text|indent}{$text|indent:4}{$text|indent:2:"\t"}
  {$text|lower}{$text|upper}{$text|nl2br}{$text|regex_replace:'/\s+/':' '}
  {$text|replace:'a':'b'}{$text|spacify}{$text|spacify:'-'}{$text|string_format:'%d'}
  {$text|strip}{$text|strip:'&nbsp;'}{$text|strip_tags}{$text|strip_tags:false}
  {$text|truncate}{$text|truncate:30}{$text|truncate:30:'...'}{$text|truncate:30:'...':true}{$text|truncate:30:'':false:true}
  {$text|unescape:'html'}{$text|wordwrap}{$text|wordwrap:40}{$text|wordwrap:40:"<br>\n"}{$text|wordwrap:40:"\n":true}
  {$array|@count}{$array|@implode:','}{$array|@reverse}{$array|@sort}
  {$text|trim|ucfirst|nl2br}
  {$items|@array_map:'strtoupper'|@implode:'-'}
  {$a|default:$b|default:'x'}
  {'literal'|upper}{"double $quoted"|lower}{1234.5|number_format:2}

  {* ── Function calls with every attribute style ── *}
  {include file="a.tpl"}
  {include file='b.tpl' title="Hello" count=$count items=[1, 2] flag=true}
  {include file="c.tpl" assign="rendered"}
  {include file="d.tpl" scope="parent" nocache caching=false cache_lifetime=60}
  {include file="string:Hello {$user->name}"}
  {include file="file:/var/www/templates/e.tpl"}
  {include file="$tplName.tpl"}
  {include file="$dir/f.tpl"}
  {include file=$dynamic}
  {assign var="x" value=1 scope="global"}
  {assign var="y" value=$x+1 nocache}
  {assign "z" "text"}
  {append var="list" value="new" index="key"}

  {* ── User functions: function / call ── *}
  {function name=menu level=0}
    <ul class="level{$level}">
    {foreach $data as $entry}
      <li>{$entry.name}
      {if $entry.children}{call name=menu data=$entry.children level=$level+1}{/if}
      </li>
    {/foreach}
    </ul>
  {/function}
  {call name=menu data=$tree}
  {call name=$dynamicName data=$tree}

  {* ── Filters, setfilter, strip, capture variants ── *}
  {setfilter escape:'html'}{$userInput}{/setfilter}
  {setfilter default|escape:'html'}{$maybe}{/setfilter}
  {capture}{$summaryText}{/capture}
  {capture name="a"}A{/capture}{capture assign="b" append="c"}B{/capture}
  {$smarty.capture.a}
  {strip}{foreach $names as $n}<i>{$n}</i> {/foreach}{/strip}

  {* ── Remaining built-in plugins ── *}
  {html_image file="logo.png" alt="Logo" width=64 height=32 href="/"}
  {html_options values=$ids output=$labels selected=$selectedId name="choice"}
  {html_options options=$map selected=$map.sku class="wide"}
  {html_radios name="size" options=$sizes selected="m" separator="<br>"}
  {html_radios name="size" values=$ids output=$labels labels=false}
  {html_checkboxes name="tags" values=$ids output=$labels selected=$checked labels=true}
  {html_select_date prefix="Due" time=$smarty.now start_year="+0" end_year="+5" display_days=false}
  {html_select_time use_24_hours=true minute_interval=15 display_seconds=false}
  {html_table loop=$list cols=4 tr_attr=['class="a"', 'class="b"'] td_attr='align="center"'}
  {html_table loop=$list cols="a,b,c" hdir="right" vdir="down" inner="cols"}
  {mailto address="stock@example.com" text="Write to us" subject="Stock" cc="cc@example.com" extra='class="mail"'}
  {math equation="(x + y) * z" x=1 y=2 z=3 assign="result"}
  {math equation="floor(a / b)" a=$total b=7 format="%d"}
  {textformat wrap=30 indent=4 indent_first=2 wrap_cut=true style="email"}Long text {$user->name}.{/textformat}
  {cycle values=["odd", "even"] name="rows" print=true advance=true reset=false}
  {counter name="n" start=10 skip=-1 direction="down" print=true assign="current"}
  {fetch file="http://example.com/status" assign="status"}
  {eval var="Dynamic {$user->name}" assign="evaluated"}
  {debug output="html"}
  {ldelim}$escaped{rdelim}

  {* ── Custom block functions and plugin-style calls ── *}
  {my_block id="b1" class="x"}Inner {$total}{/my_block}
  {my_function a=1 b="two" c=$three d=[1, 2] e=['k' => 'v'] f=true g=null}
  {$value|my_modifier:$arg1:"arg2":3}

  {$footerHtml nofilter}
  {$footerHtml|escape:"htmlall"}
{/block}

{block name="footer" append}
  <p>{$lowCount} of {$items|@count} need reordering — © Acme Warehousing ✓</p>
{/block}

{block name="sidebar" hide}
  <aside>Only rendered when a child template defines it.</aside>
{/block}

{block name="inherit" nocache}
  {$smarty.block.parent}
  <p>Child text before {$smarty.block.child} after.</p>
{/block}

{block name="head" prepend}
  <meta name="stock" content="{$lowCount}">
{/block}
