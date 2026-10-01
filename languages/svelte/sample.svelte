<!-- Svelte 5.x (runes mode) — syntax showcase -->
<!-- ── Comments ── -->
<!-- Svelte 5 component: warehouse stock table with runes, snippets and transitions.
     TODO: virtualise long lists.
     FIXME: the sort icon flickers on first render. -->

<script module lang="ts">
  // Module script: runs once per module, not per instance.
  export const REORDER_POINT = 25;
  export const prerender = true;

  export function money(value: number, currency = "GBP"): string {
    return new Intl.NumberFormat("en-GB", { style: "currency", currency }).format(value);
  }
</script>

<script lang="ts">
  /* ── Imports ── */
  import { onMount, onDestroy, tick, untrack, getContext, setContext, mount, unmount, hydrate, createRawSnippet } from "svelte";
  import { fade, fly, slide, scale, blur, draw, crossfade } from "svelte/transition";
  import { flip } from "svelte/animate";
  import { cubicOut } from "svelte/easing";
  import { writable, derived, get, readable } from "svelte/store";
  import { SvelteMap, SvelteSet, SvelteURL, SvelteDate } from "svelte/reactivity";
  import { createSubscriber } from "svelte/reactivity";
  import { Spring, Tween, prefersReducedMotion } from "svelte/motion";
  import { page } from "$app/state";
  import { createAttachmentKey, fromAction } from "svelte/attachments";
  import Wrapper from "./Wrapper.svelte";
  import StatusBadge, { type Props as BadgeProps } from "./StatusBadge.svelte";
  import * as Icons from "./icons";
  import type { Snippet, Component } from "svelte";
  import type { Attachment } from "svelte/attachments";
  import type { Action } from "svelte/action";

  /* ── Types ── */
  type Status = "ok" | "low" | "out";
  interface Item {
    id: string;
    sku: string;
    name: string;
    quantity: number;
    price?: number;
  }

  /* ── Props (runes) ── */
  // $props.id() gives a unique, SSR-stable id; $bindable marks a prop two-way bindable.
  let {
    items = [],
    title = "Stock",
    onselect,
    children,
    header,
    value = $bindable(""),
    ...rest
  }: {
    items?: Item[];
    title?: string;
    onselect?: (item: Item) => void;
    children?: Snippet;
    header?: Snippet<[string]>;
    value?: string;
  } = $props();
  const uid = $props.id();
  const onclick = () => counter++;

  /* ── State, derived and effects (runes) ── */
  let query = $state("");
  let sortKey = $state<keyof Item>("sku");
  let descending = $state(false);
  let selected = $state.raw<Item | null>(null);
  let counter = $state(0);

  let visible = $derived(
    items
      .filter((item) => item.name.toLowerCase().includes(query.toLowerCase()))
      .sort((a, b) => (a[sortKey]! > b[sortKey]! ? 1 : -1) * (descending ? -1 : 1))
  );
  let lowCount = $derived.by(() => visible.filter((i) => i.quantity <= REORDER_POINT).length);
  const snapshot = $state.snapshot(items);
  let element = $state<HTMLElement>();
  let badgeRef = $state<StatusBadge>();
  let fileList = $state<FileList>();
  let rect = $state<DOMRectReadOnly>();
  let form = $state({ name: "", tags: ["a"], nested: { on: true } });
  const cache = new SvelteMap<string, Item>();
  const seen = new SvelteSet<string>();
  const spring = new Spring(0, { stiffness: 0.2, damping: 0.8 });
  const tween = new Tween(0, { duration: 400, easing: cubicOut });

  // Reactive class fields: $state / $derived in a class body.
  class Cart {
    lines = $state<Item[]>([]);
    count = $derived(this.lines.length);
    #secret = $state(0);
    static from(items: Item[]) {
      const c = new Cart();
      c.lines = items;
      return c;
    }
    add(item: Item) {
      this.lines.push(item);
    }
  }
  const cart = new Cart();

  // $inspect logs when its arguments change (dev only).
  $inspect(query, counter).with((type, ...values) => console.log(type, values));
  $inspect(query).with(console.trace);

  $effect(() => {
    document.title = `${title} (${visible.length})`;
    return () => (document.title = "");
  });

  $effect.pre(() => {
    counter = visible.length;
  });

  $effect(() => {
    // untrack reads state without subscribing to it
    const first = untrack(() => items[0]);
    console.log(first, $effect.tracking());
  });

  const unsubscribe = $effect.root(() => {
    $effect(() => {
      console.log(query);
    });
    return () => {};
  });

  /* ── Stores (auto-subscribed with $ prefix; still valid in runes mode) ── */
  const store = writable<number>(0);
  const double = derived(store, ($s) => $s * 2);
  const clock = readable(new Date(), (set) => {
    const id = setInterval(() => set(new Date()), 1000);
    return () => clearInterval(id);
  });
  const storeTotal = $derived($store + $double);

  /* ── Attachments and actions ── */
  const focusOnMount: Attachment<HTMLInputElement> = (node) => {
    node.focus();
    return () => node.blur();
  };
  const tooltip: Action<HTMLElement, { text: string }> = (node, params) => {
    node.title = params.text;
    return { update: (p) => (node.title = p.text), destroy() {} };
  };
  const subscribe = createSubscriber((update) => {
    window.addEventListener("resize", update);
    return () => window.removeEventListener("resize", update);
  });
  const rawBadge = createRawSnippet((label: () => string) => ({
    render: () => `<b>${label()}</b>`,
  }));

  /* ── Functions, events, lifecycle ── */
  function pick(item: Item) {
    selected = item;
    onselect?.(item);
  }

  function status(item: Item): Status {
    return item.quantity <= 0 ? "out" : item.quantity <= REORDER_POINT ? "low" : "ok";
  }

  async function reload() {
    try {
      const res = await fetch("/api/items");
      items = (await res.json()) as Item[];
    } catch (err) {
      console.error(err);
    } finally {
      await tick();
    }
  }

  onMount(() => {
    reload();
    return () => unsubscribe();
  });

  function imperative(target: HTMLElement) {
    const app = mount(StatusBadge, { target, props: { status: "ok" } });
    unmount(app);
  }

  function swap(a: string, b: string) {
    [a, b] = [b, a];
  }
</script>

<!-- ── Snippets ── -->
{#snippet row(item: Item, index: number)}
  <tr class:low={status(item) === "low"} class:out={status(item) === "out"} onclick={() => pick(item)}>
    <td>{index + 1}</td>
    <td>{item.sku}</td>
    <td>{item.name}</td>
    <td class="num">{item.quantity.toLocaleString("en-GB")}</td>
    <td>{money(item.price ?? 0)}</td>
    <td><StatusBadge status={status(item)} /></td>
  </tr>
{/snippet}

{#snippet badge(label: string)}
  <span class="badge">{label}</span>
{/snippet}

{#snippet nothing()}{/snippet}

<!-- ── Markup ── -->
<svelte:options namespace="html" css="injected" />

<svelte:head>
  <title>{title}</title>
  <meta name="description" content="Warehouse stock for {items.length} items" />
</svelte:head>

<svelte:window onkeydown={(e) => e.key === "Escape" && (selected = null)} bind:innerWidth={counter} bind:scrollY={counter} />
<svelte:document onvisibilitychange={reload} bind:activeElement={element} />
<svelte:body class:busy={counter > 100} onmouseenter={() => counter++} />

<section class="stock" {...rest} id={uid} bind:this={element}>
  {#if header}
    {@render header(title)}
  {:else}
    <h1>{title}</h1>
  {/if}

  <input bind:value={query} placeholder="Filter…" aria-label="Filter items" {@attach focusOnMount} />
  <input bind:value={() => query, (v) => (query = v.trim())} />
  <input bind:value={form.name} bind:this={element} use:tooltip={{ text: "name" }} />
  <input type="radio" bind:group={sortKey} value="sku" />
  <input type="range" min="0" max="10" bind:value={spring.target} />
  <input type="file" bind:files={fileList} />
  <textarea bind:value={form.name}></textarea>
  <details bind:open={descending}><summary>More</summary></details>
  <video bind:currentTime={counter} bind:paused={descending} bind:duration={tween.target}></video>
  <div bind:clientWidth={counter} bind:offsetHeight={counter} bind:contentRect={rect}></div>
  <select bind:value={sortKey}>
    {#each ["sku", "name", "quantity"] as key}
      <option value={key}>{key}</option>
    {/each}
  </select>
  <label>
    <input type="checkbox" bind:checked={descending} /> Descending
  </label>
  <button type="button" onclick={reload} disabled={counter === 0}>Reload</button>
  <button onclick={(e) => { e.preventDefault(); counter++; }} onclickcapture={() => {}}>Event handlers are plain attributes</button>
  <button class={["btn", { active: descending, big: counter > 5 }, query && "has-query"]} style:color="red" style:--gap="1rem" style:font-size|important="1rem">
    Class arrays and objects
  </button>
  <button class="a b" class:active={descending} class:big={counter > 5} class:low={lowCount > 0}>Directives</button>
  <button {onclick} {...{ disabled: false }} aria-pressed={descending ? "true" : "false"} data-count={counter}>Shorthand</button>
  <Wrapper {@attach focusOnMount} --accent="tomato" --gap={`${counter}px`}>With CSS custom props</Wrapper>
  <p>{@render badge("inline")} {@render rawBadge(() => "raw")} {#if cart.count > 0}{cart.count}{/if}</p>

  {#if items.length === 0}
    <p class="muted" transition:fade={{ duration: 150 }}>No items yet.</p>
  {:else if visible.length === 0}
    <p class="muted">Nothing matches “{query}”.</p>
  {:else}
    <table in:fly={{ y: 20 }} out:slide>
      <thead>
        <tr>
          <th>#</th><th>SKU</th><th>Name</th><th>Qty</th><th>Price</th><th>Status</th>
        </tr>
      </thead>
      <tbody>
        {#each visible as item, index (item.id)}
          <tr animate:flip={{ duration: 200 }}>
            {@render row(item, index)}
          </tr>
        {:else}
          <tr><td colspan="6">Empty</td></tr>
        {/each}
      </tbody>
    </table>
    <p>{visible.length} of {items.length} shown, {lowCount} low.</p>
  {/if}

  {#await reload()}
    <p>Loading…</p>
  {:then}
    <p>Loaded.</p>
  {:catch error}
    <p class="error">{error.message}</p>
  {/await}

  {#key counter}
    <span class="pulse">{counter}</span>
  {/key}

  {#if selected}
    {@const label = `${selected.sku} — ${selected.name}`}
    <aside use:tooltip={{ text: label }} transition:scale>
      <h2>{label}</h2>
      {@html `<em>${selected.quantity}</em> in stock`}
      {@debug selected}
    </aside>
  {/if}

  <StatusBadge status="ok" {...{ size: "small" }} bind:this={badgeRef} />
  <svelte:component this={StatusBadge} status="low" /> <!-- deprecated in runes mode: use a component variable -->
  {#if selected}
    {@const Dynamic = StatusBadge}
    <Dynamic status="out" />
  {/if}
  <Icons.Warning size={16} />
  <svelte:boundary onerror={(e, reset) => console.error(e)}>
    <StatusBadge status="ok" />
    {#snippet pending()}<p>Loading…</p>{/snippet}
    {#snippet failed(error, reset)}
      <button onclick={reset}>Retry after {error}</button>
    {/snippet}
  </svelte:boundary>
  <!-- Component with snippet props, children and a bindable prop -->
  <Wrapper bind:value {header}>
    {#snippet footer(total)}
      <small>{total} rows</small>
    {/snippet}
    Default children content
  </Wrapper>
  <!-- Legacy (Svelte 4) forms, labelled: each is deprecated in runes mode and cannot be mixed with runes
       in one component, so they are shown as comments:
       <slot name="x" />, <svelte:fragment slot="x">, let:item, on:click|once|preventDefault, $: doubled = a * 2,
       export let prop, createEventDispatcher, <svelte:self />, <svelte:component this={C} />, $$props, $$restProps -->
  <svelte:element this={"div"} class="dynamic-tag">Dynamic element</svelte:element>

  {@render children?.()}
</section>

<!-- ── Styles ── -->
<style lang="scss">
  $accent: #336699;

  /* Block comment in CSS */
  .stock {
    font: 400 1rem/1.5 system-ui, sans-serif;
    --gap: 0.75rem;
  }

  .muted { color: #888; }
  .num { text-align: right; font-variant-numeric: tabular-nums; }

  tr.low td { color: darkorange; }
  tr.out td { color: crimson; text-decoration: line-through; }

  :global(body) { margin: 0; }
  :global(.stock) > h1 { color: $accent; }

  .pulse { animation: pulse 1s infinite; }

  /* Scoped modern CSS: nesting, :has(), @layer, @container, custom properties */
  .stock {
    container-type: inline-size;
    &:has(.low) { outline: 1px solid color-mix(in oklch, orange 40%, transparent); }
    & .badge { padding-inline: 0.5ch; background: var(--accent, oklch(60% 0.15 250)); }
  }
  @layer base, components;
  @layer components {
    .btn.active { font-weight: 600; }
  }
  @container (min-width: 40rem) {
    table { font-size: 1rem; }
  }
  :global {
    /* everything inside this block is unscoped */
    .third-party { margin: 0; }
  }
  .a:global(.b) { color: inherit; }
  @keyframes -global-spin { to { transform: rotate(360deg); } }

  @keyframes pulse {
    from { opacity: 1; }
    50% { opacity: 0.5; }
    to { opacity: 1; }
  }

  @media (max-width: 600px) {
    table { font-size: 0.875rem; }
  }
</style>
