<!-- ── Comments ─────────────────────────────────────────────
     Vue 3 single-file component: the warehouse stock table.
     TODO: virtualise the list. FIXME: keyboard focus after delete. -->

<script lang="ts">
// Normal <script>: runs once per module, not per instance.
export const COMPONENT_NAME = "StockTable";
export default { name: COMPONENT_NAME, inheritAttrs: false };
</script>

<script setup lang="ts">
/**
 * Script setup: everything below runs per instance.
 * @see https://vuejs.org
 */
import { computed, ref, reactive, watch, watchEffect, onMounted, onBeforeUnmount, provide, inject, nextTick } from "vue";
import type { PropType, Ref } from "vue";
import StatusBadge from "./StatusBadge.vue";
import { useStockStore } from "@/stores/stock";

type Order = { id: string; number: number; total: number; status: "paid" | "pending" | "cancelled" };
interface Item { sku: string; qty: number; price?: number; tags: string[] }

// ── Macros: props, emits, expose, slots, model, options ────
const props = withDefaults(
  defineProps<{ orders: Order[]; items?: Item[]; reorderPoint?: number; title: string }>(),
  { items: () => [], reorderPoint: 25 },
);
const emit = defineEmits<{
  (e: "select", id: string): void;
  (e: "restock", sku: string, amount: number): void;
  change: [value: string];
}>();
const model = defineModel<string>({ default: "" });
const [count, countModifiers] = defineModel<number>("count", { required: true });
defineSlots<{ default(props: { item: Item }): unknown; footer(): unknown }>();
defineExpose({ focus: () => input.value?.focus() });
defineOptions({ inheritAttrs: false });

// ── State ──────────────────────────────────────────────────
const query = ref("");
const input = ref<HTMLInputElement | null>(null);
const state = reactive({ loading: false, error: null as string | null, selected: new Set<string>() });
const sortKey = ref<keyof Item>("sku");
const accent = ref("#2a7");
const store = useStockStore();
const theme = inject<string>("theme", "light");
provide("stock", { reorderPoint: props.reorderPoint });

const visible = computed(() =>
  props.orders.filter((o) => String(o.number).includes(query.value) && o.status !== "cancelled"),
);
const lowCount = computed<number>({
  get: () => props.items.filter((i) => i.qty <= props.reorderPoint).length,
  set: (v) => { console.log(`low count forced to ${v}`); },
});

const money = (n: number): string =>
  new Intl.NumberFormat("en-GB", { style: "currency", currency: "GBP" }).format(n);

watch(query, async (next, prev) => {
  state.loading = true;
  await nextTick();
  emit("change", next ?? prev ?? "");
  state.loading = false;
}, { immediate: true, deep: false });
watchEffect(() => { document.title = `${props.title} (${visible.value.length})`; });

function onSelect(id: string, ev?: MouseEvent) {
  if (ev?.shiftKey) state.selected.add(id); else state.selected = new Set([id]);
  emit("select", id);
}

onMounted(() => input.value?.focus());
onBeforeUnmount(() => state.selected.clear());
</script>

<template>
  <!-- Template: directives, bindings, slots, events -->
  <section :class="['stock', { empty: orders.length === 0 }, theme]" :style="{ '--accent': accent }" v-bind="$attrs">
    <h1 class="title">{{ title }} <small>({{ visible.length }} of {{ orders.length }})</small></h1>

    <input ref="input" v-model.trim.lazy="query" v-model:count="count" placeholder="Filter…" @keyup.enter="onSelect('')" />
    <input v-model.number="count" type="number" min="0" :max="999" :disabled="state.loading" />
    <select v-model="model"><option v-for="n in 3" :key="n" :value="n">{{ n }}</option></select>

    <p v-if="orders.length === 0" class="muted">No orders yet.</p>
    <p v-else-if="state.error" role="alert" v-text="state.error"></p>
    <p v-else v-once>Showing {{ visible.length }} orders</p>

    <table v-show="!state.loading">
      <caption>Orders &amp; stock &lt;{{ lowCount }} low&gt; &copy; 2026</caption>
      <tr
        v-for="(order, index) in visible"
        :key="order.id"
        :class="{ paid: order.status === 'paid', odd: index % 2 }"
        @click.stop.prevent="onSelect(order.id, $event)"
        @keydown.ctrl.enter="emit('restock', order.id, 1)"
        v-memo="[order.status, state.selected.has(order.id)]"
      >
        <td>#{{ order.number }}</td>
        <td>{{ money(order.total) }}</td>
        <td><StatusBadge :status="order.status" v-slot="{ label }">{{ label.toUpperCase() }}</StatusBadge></td>
        <td v-html="'<b>' + order.id + '</b>'"></td>
        <td>{{ order.number > 100 ? "large" : "small" }} {{ order?.total ?? 0 }}</td>
      </tr>
    </table>

    <ul>
      <li v-for="(value, key, i) in { sku: 'WGT-100', qty: 12 }" :key="key">{{ i }}. {{ key }}: {{ value }}</li>
      <li v-for="item of items" :key="item.sku" :title="`SKU ${item.sku}`">
        <slot :item="item" name="default">{{ item.sku }}</slot>
      </li>
    </ul>

    <component :is="state.loading ? 'span' : 'div'" v-bind:id="`c-${count}`" #default>dynamic</component>
    <Teleport to="body"><div class="modal" v-if="state.selected.size">Selected</div></Teleport>
    <Transition name="fade" mode="out-in"><div :key="query">{{ query }}</div></Transition>
    <KeepAlive><StatusBadge :status="'paid'" /></KeepAlive>
    <Suspense><template #default><AsyncPanel /></template><template #fallback>Loading…</template></Suspense>

    <MyList v-slot:header="{ total }">Header {{ total }}</MyList>
    <MyList #footer>Footer</MyList>
    <MyList v-bind="{ id: 'x', class: 'y' }" v-on="{ click: onSelect }" @custom-event="(a: string) => emit('select', a)" />
    <div v-pre>{{ untouched }} <span v-if="x"></span></div>
    <div v-cloak :[dynamicAttr]="value" @[dynamicEvent]="handler">dynamic arguments</div>
    <button type="button" :disabled="!count" @click="count++; emit('restock', 'WGT-100', count)">Restock</button>
    <slot name="footer" />
    <img src="/logo.png" alt="" /><br />

    <!-- Event and key modifiers, bind modifiers, legacy and special attributes -->
    <button @click.once="onSelect('a')" @click.capture="onSelect('b')" @scroll.passive="onSelect('c')" @click.self="onSelect('d')" @click.exact="onSelect('e')" @click.left="onSelect('f')" @contextmenu.right.prevent="onSelect('g')" @mouseup.middle="onSelect('h')">Modifiers</button>
    <input @keyup.esc="query = ''" @keydown.tab.shift="onSelect('t')" @keyup.page-down="onSelect('p')" @keydown.alt.enter.exact="onSelect('x')" @input.native="onSelect('n')" />
    <MyInput v-model.trim.number.lazy="query" v-model:title.trim="query" :foo.camel="query" :bar.prop="query" :baz.attr="query" :aria-label.sync="query" />
    <div :class="[state.loading ? 'busy' : '', { active: count > 0, 'is-low': lowCount > 0 }]" :style="[{ color: accent }, { fontSize: '12px' }]" :data-count.number="count"></div>
    <p>{{ $t("stock.title") }} {{ $slots.default ? "slot" : "no slot" }} {{ $refs.input?.value }} {{ $props.title }} {{ $attrs.id }} {{ $emit }} {{ $el }} {{ $parent }} {{ $root }}</p>
    <p>{{ count | 0 }} {{ query || "empty" }} {{ items?.[0]?.sku ?? "none" }} {{ [1, 2, 3].map((n) => n * 2).join(", ") }} {{ `template ${count}` }} {{ !state.loading && count >= 1 }} {{ count ** 2 }} {{ typeof count }}</p>
    <p>{{ { a: 1 }.a }} {{ new Date().getFullYear() }} {{ Math.max(1, 2) }} {{ JSON.stringify({ a: 1 }) }} {{ String(count).padStart(3, "0") }} {{ parseInt("42", 10) }}</p>
    <textarea v-model="query"></textarea>
    <input type="checkbox" v-model="state.loading" true-value="yes" false-value="no" />
    <input type="radio" v-model="model" value="a" /><input type="radio" v-model="model" value="b" />
    <slot name="header" :total="count" :items="visible">Fallback content {{ count }}</slot>
    <template v-if="count > 5"><span>many</span></template>
    <template v-else-if="count > 0"><span>few</span></template>
    <template v-else><span>none</span></template>
    <template v-for="n in 3" :key="n"><i>{{ n }}</i></template>
    <component :is="StatusBadge" status="paid" @select="onSelect" />
    <router-link :to="{ name: 'item', params: { id: 1 } }" custom v-slot="{ href, navigate }"><a :href="href" @click="navigate">Link</a></router-link>
    <svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><circle cx="5" cy="5" r="4" :fill="accent" /></svg>
    <MyComp v-slot:[dynamicSlot]="{ item: { sku, qty } }">{{ sku }} {{ qty }}</MyComp>
    <MyComp #item="{ item }" #[dynamicSlot]>dynamic slot</MyComp>
    <input v-focus v-custom:arg.mod1.mod2="{ a: 1 }" v-bind:[dynamicKey].sync="value" />
  </section>
</template>

<style scoped>
/* Scoped CSS */
.stock { --gap: 8px; display: grid; gap: var(--gap); color: v-bind(accent); }
.muted { color: #888; font-style: italic; }
tr.paid td { color: #2a7; background: rgb(34 170 119 / 0.1); }
tr:hover > td:first-child::before { content: "▶ "; }
:deep(.badge) { border-radius: 4px; }
:slotted(span) { font-weight: 600; }
:global(body) { margin: 0; }
@media (max-width: 600px) { .stock { grid-template-columns: 1fr; } }
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>

<style lang="scss" module="classes">
$accent: #2a7;
.card {
  &:hover { color: darken($accent, 10%); }
  .inner { margin: { top: 1px; bottom: 2px; } }
}
</style>

<style lang="less">
@accent: #2a7;
.panel { color: @accent; .inner { &:hover { color: darken(@accent, 10%); } } }
</style>

<style lang="stylus">
accent = #2a7
.panel
  color accent
</style>

<style lang="postcss" src="./stock.css"></style>

<style scoped lang="scss">
@use "sass:math";
$gap: 8px;
@mixin pad($n: 1) { padding: math.div($gap, 2) * $n; }
.card { @include pad(2); &__title { font-weight: bold; } @extend %placeholder; }
%placeholder { margin: 0; }
@each $name, $color in (ok: #2a7, low: #c33) { .badge-#{$name} { color: $color; } }
</style>

<custom lang="yaml">
meta:
  reviewed: true
</custom>

<i18n lang="json">
{ "en": { "title": "Stock", "empty": "No orders yet." }, "de": { "title": "Bestand" } }
</i18n>

<docs>
## StockTable
Custom blocks are passed to tooling.
</docs>
