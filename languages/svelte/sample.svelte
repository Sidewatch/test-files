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
  import { onMount, onDestroy, tick, createEventDispatcher, getContext, setContext } from "svelte";
  import { fade, fly, slide, scale } from "svelte/transition";
  import { flip } from "svelte/animate";
  import { writable, derived, get } from "svelte/store";
  import { page } from "$app/stores";
  import StatusBadge from "./StatusBadge.svelte";
  import type { Snippet } from "svelte";

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
  let {
    items = [],
    title = "Stock",
    onselect,
    children,
    header,
    ...rest
  }: {
    items?: Item[];
    title?: string;
    onselect?: (item: Item) => void;
    children?: Snippet;
    header?: Snippet<[string]>;
  } = $props();

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

  $effect(() => {
    document.title = `${title} (${visible.length})`;
    return () => (document.title = "");
  });

  $effect.pre(() => {
    counter = visible.length;
  });

  const unsubscribe = $effect.root(() => {
    $effect(() => console.log($inspect(query)));
  });

  /* ── Stores and legacy reactive statements ── */
  const store = writable<number>(0);
  $: doubled = $store * 2;
  $: if (doubled > 10) console.warn("large");
  $: ({ length } = items);

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

  const dispatch = createEventDispatcher<{ pick: Item }>();
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

<!-- ── Markup ── -->
<svelte:head>
  <title>{title}</title>
  <meta name="description" content="Warehouse stock for {items.length} items" />
</svelte:head>

<svelte:window onkeydown={(e) => e.key === "Escape" && (selected = null)} bind:innerWidth={counter} />
<svelte:document onvisibilitychange={reload} />
<svelte:body class:busy={counter > 100} />

<section class="stock" {...rest}>
  {#if header}
    {@render header(title)}
  {:else}
    <h1>{title}</h1>
  {/if}

  <input bind:value={query} placeholder="Filter…" aria-label="Filter items" />
  <select bind:value={sortKey}>
    {#each ["sku", "name", "quantity"] as key}
      <option value={key}>{key}</option>
    {/each}
  </select>
  <label>
    <input type="checkbox" bind:checked={descending} /> Descending
  </label>
  <button type="button" onclick={reload} disabled={counter === 0}>Reload</button>
  <button on:click|preventDefault|once={() => counter++}>Legacy event modifiers</button>

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

  <StatusBadge status="ok" {...{ size: "small" }} bind:this={counter} />
  <svelte:component this={StatusBadge} status="low" />
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

  @keyframes pulse {
    from { opacity: 1; }
    50% { opacity: 0.5; }
    to { opacity: 1; }
  }

  @media (max-width: 600px) {
    table { font-size: 0.875rem; }
  }
</style>
