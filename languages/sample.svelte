<script lang="ts">
  // Svelte 5: an orders table with a filter, runes and a derived value.
  import { money } from "./money";
  import StatusBadge from "./StatusBadge.svelte";

  type Order = { id: string; number: number; total: number; status: string };
  let { orders = [] }: { orders?: Order[] } = $props();
  let query = $state("");
  let visible = $derived(orders.filter((o) => String(o.number).includes(query)));
</script>

<h1>Orders</h1>
<input bind:value={query} placeholder="Filter…" />

{#if orders.length === 0}
  <p class="muted">No orders yet.</p>
{:else}
  <table>
    {#each visible as order (order.id)}
      <tr class:paid={order.status === "paid"}>
        <td>#{order.number}</td>
        <td>{money(order.total)}</td>
        <td><StatusBadge status={order.status} /></td>
      </tr>
    {/each}
  </table>
  <p>{visible.length} of {orders.length}</p>
{/if}

<style>
  .muted { color: #888; }
  tr.paid td { color: #2a7; }
</style>
