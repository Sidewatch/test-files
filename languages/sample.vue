<script setup lang="ts">
// Vue 3: an orders table with a filter and a computed list.
import { computed, ref } from "vue";
import StatusBadge from "./StatusBadge.vue";

type Order = { id: string; number: number; total: number; status: string };
const props = defineProps<{ orders: Order[] }>();
const query = ref("");
const visible = computed(() => props.orders.filter((o) => String(o.number).includes(query.value)));
const money = (n: number) => new Intl.NumberFormat("en-GB", { style: "currency", currency: "GBP" }).format(n);
</script>

<template>
  <h1>Orders</h1>
  <input v-model="query" placeholder="Filter…" />
  <p v-if="orders.length === 0" class="muted">No orders yet.</p>
  <table v-else>
    <tr v-for="order in visible" :key="order.id" :class="{ paid: order.status === 'paid' }">
      <td>#{{ order.number }}</td>
      <td>{{ money(order.total) }}</td>
      <td><StatusBadge :status="order.status" /></td>
    </tr>
  </table>
  <p>{{ visible.length }} of {{ orders.length }}</p>
</template>

<style scoped>
.muted { color: #888; }
tr.paid td { color: #2a7; }
</style>
