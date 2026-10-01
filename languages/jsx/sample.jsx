#!/usr/bin/env node
// JSX (React 19 / ECMAScript 2025) — syntax showcase; JSX is checked against the TSX grammar, TypeScript-only constructs are omitted
// ── Imports ──
import React, { useState, useEffect, useMemo, useCallback, useReducer, createContext, useContext } from "react";
import PropTypes from "prop-types";
import { createRoot } from "react-dom/client";
import styles from "./Inventory.module.css";

/**
 * Doc comment: an inventory table with filters.
 * @param {{ items: Array, onSelect?: Function }} props
 */
// TODO: virtualise the list
/* FIXME: keyboard navigation */

// ── Constants ──
const LOW_STOCK = 10;
const PRICE_FORMAT = new Intl.NumberFormat("en-GB", { style: "currency", currency: "GBP" });
const hexMask = 0xFF, octal = 0o17, binary = 0b101, big = 1_000_000n, exp = 6.022e23;
const InventoryContext = createContext({ warehouse: "Main", locale: "en" });

// ── Reducer ──
function reducer(state, action) {
  switch (action.type) {
    case "received":
      return { ...state, [action.sku]: (state[action.sku] ?? 0) + action.count };
    case "shipped":
      return { ...state, [action.sku]: Math.max(0, (state[action.sku] || 0) - action.count) };
    default:
      throw new Error(`Unknown action: ${action.type}`);
  }
}

// ── Small function components ──
const Badge = ({ children, tone = "neutral", ...rest }) => (
  <span className={`badge badge--${tone}`} {...rest}>{children}</span>
);

function Row({ item, selected, onSelect }) {
  const low = item.quantity < LOW_STOCK;
  return (
    <tr
      className={[styles.row, selected && styles.selected, low ? "low" : null].filter(Boolean).join(" ")}
      data-sku={item.sku}
      aria-selected={selected}
      onClick={() => onSelect?.(item.sku)}
      style={{ color: low ? "#b00020" : "inherit", fontWeight: low ? 700 : 400 }}
    >
      <td>{item.sku}</td>
      <td>{item.quantity.toLocaleString()}</td>
      <td>{PRICE_FORMAT.format(item.unitPrice)}</td>
      <td>{low ? <Badge tone="warn">Low</Badge> : <Badge>OK</Badge>}</td>
    </tr>
  );
}

// ── Main component ──
export default function Inventory({ items = [], onSelect, title = "Stock" }) {
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState(null);
  const [counts, dispatch] = useReducer(reducer, {});
  const { warehouse } = useContext(InventoryContext);

  useEffect(() => {
    document.title = `${title} — ${warehouse}`;
    const timer = setInterval(() => dispatch({ type: "received", sku: "A-100", count: 1 }), 60_000);
    return () => clearInterval(timer);
  }, [title, warehouse]);

  const visible = useMemo(
    () => items.filter(({ sku }) => sku.toLowerCase().includes(query.toLowerCase())),
    [items, query],
  );

  const handleSelect = useCallback((sku) => {
    setSelected(sku);
    onSelect?.(sku);
  }, [onSelect]);

  if (items.length === 0) return <p className="empty">No items &mdash; nothing to show.</p>;

  return (
    <section id="inventory" className={styles.panel}>
      {/* JSX comment: the search box */}
      <header>
        <h1>{title}</h1>
        <input
          type="search"
          value={query}
          placeholder="Filter by SKU…"
          onChange={(e) => setQuery(e.target.value)}
          autoFocus
          disabled={false}
        />
      </header>

      <table>
        <thead>
          <tr><th>SKU</th><th>Qty</th><th>Price</th><th /></tr>
        </thead>
        <tbody>
          {visible.map((item, index) => (
            <Row key={item.sku} item={item} selected={item.sku === selected} onSelect={handleSelect} />
          ))}
        </tbody>
      </table>

      <>
        <p>
          Showing {visible.length} of {items.length} &middot; total{" "}
          <strong>{visible.reduce((sum, { quantity }) => sum + quantity, 0)}</strong>
          {selected && <em> (selected: {selected})</em>}
        </p>
        <p title='single "quoted" attr' data-escaped="a &amp; b">Unicode: Zürich → 東京 ✓ {"✓"}</p>
        <Badge tone="info" aria-label={`Counts: ${Object.keys(counts).length}`}>
          {Object.entries(counts).map(([sku, n]) => <span key={sku}>{sku}:{n} </span>)}
        </Badge>
        <InventoryContext.Provider value={{ warehouse: "Spare", locale: "en" }}>
          <Row item={{ sku: "X-1", quantity: 2, unitPrice: 1.5 }} />
        </InventoryContext.Provider>
        <svg:rect xlink:href="#a" width="10" height="10" />
        <label htmlFor="q">Query</label>
      </>
    </section>
  );
}

Inventory.propTypes = {
  items: PropTypes.arrayOf(PropTypes.shape({
    sku: PropTypes.string.isRequired,
    quantity: PropTypes.number,
    unitPrice: PropTypes.number,
  })),
  onSelect: PropTypes.func,
  title: PropTypes.string,
};

// ── Class component ──
class ErrorBoundary extends React.Component {
  state = { error: null };
  static getDerivedStateFromError(error) { return { error }; }
  render() {
    const { error } = this.state;
    return error ? <pre role="alert">{String(error)}</pre> : this.props.children;
  }
}

// ── Rare JSX constructs ──
const ui = { Panel: { Header: (p) => <h2 {...p} />, Body: ({ children }) => <div>{children}</div> } };
const tagName = "section";
const Dynamic = tagName;

function RareConstructs({ component: Component = "div", children, ...props }) {
  const items = [1, 2, 3];
  return (
    <>
      <ui.Panel.Header className="member-expression-tag" />
      <ui.Panel.Body>{children}</ui.Panel.Body>
      <Component {...props} {...{ id: "spread-object" }} data-x="y" />
      <Dynamic>capitalised-variable tag</Dynamic>
      <this.props.component />
      <xlink:use xlink:href="#icon" xml:lang="en" />
      <svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><path d="M0 0L10 10" strokeWidth={2} /></svg>
      {/* block comment as child */}
      {
        // line comment as child
      }
      {}
      {/* empty expression above */}
      {children}
      {...items}
      {items.map((n) => <React.Fragment key={n}><b>{n}</b>,</React.Fragment>)}
      {items.length > 0 && <ul>{items.map((n) => <li key={n}>{n}</li>)}</ul>}
      {items.length === 0 ? <p>none</p> : items.length === 1 ? <p>one</p> : <p>many</p>}
      {null}{undefined}{false}{true}{0}{""}{NaN}
      {`template ${items.length} literal child`}
      {"string literal child"}
      {'single quoted child'}
      <input value="a &amp; b &lt; c &gt; d &quot;e&quot; &apos;f&apos; &nbsp; &#169; &#x1F4E6; &copy; &hearts;" />
      <p title="multi
line attribute" data-json={'{"a": 1}'} data-neg={-1} data-expr={1 + 2} data-fn={() => {}} data-arr={[1, 2]} data-obj={{ a: 1 }} />
      <p aria-hidden aria-label='single "quoted" attr' aria-describedby="a b" data-empty="" data-unicode="Zürich → 東京" />
      <button onClick={async (e) => { e.preventDefault(); await Promise.resolve(); }} disabled={!items.length}>
        Text with {"{"}braces{"}"}, "quotes", 'apostrophes' and a trailing space{" "}
      </button>
      <label>
        Line one
        Line two collapses
        <em>inline</em>, punctuation.
      </label>
      <style jsx>{`
        .scoped { color: red; }
      `}</style>
      <Trans i18nKey="x" values={{ n: 1 }} components={{ bold: <b /> }} />
      <Suspense fallback={<Spinner size="large" />}><Lazy /></Suspense>
      <Context.Consumer>{(value) => <span>{value}</span>}</Context.Consumer>
      <Render prop={<div />} children={<span />} render={() => <i />} />
      <A b={<C d={<E />} />} />
      <input type="text" value={value} onChange={(e) => setValue(e.target.value)} {...(cond ? { a: 1 } : {})} />
    </>
  );
}

const arrowReturningJsx = () => <div className="immediate" />;
const withTernaryAttr = <div className={cond ? "a" : "b"} style={{ ...base, color: cond ? "red" : undefined }} />;
const inObject = { element: <hr />, list: [<br key="1" />, <br key="2" />] };
const shortCircuit = cond && <span />;
const asArg = render(<App />, document.getElementById("root"));
const comparison = a < b && c > d; // not JSX
const generic = items.map((x) => x < 3 ? <i /> : <b />);
class WithJsxField extends React.Component { static defaultElement = <div />; element = <p>field</p>; render() { return this.element; } }
export { RareConstructs, arrowReturningJsx };

// ── Lazy, async and bootstrap ──
const Settings = React.lazy(() => import("./Settings.jsx"));

async function boot() {
  const response = await fetch("/api/items?limit=50", { headers: { Authorization: "Bearer example-not-a-real-key" } });
  const items = await response.json();
  createRoot(document.getElementById("root")).render(
    <ErrorBoundary>
      <React.Suspense fallback={<p>Loading…</p>}>
        <Inventory items={items} title="Warehouse" />
        <Settings />
      </React.Suspense>
    </ErrorBoundary>,
  );
}

boot().catch(console.error);

// ── React 19 additions ──
function Greeting({ ref, name }) {
  // ref is a plain prop in React 19; no forwardRef needed
  return <h1 ref={ref}>Hello, {name}</h1>;
}

function AddItemForm({ addItem }) {
  const [message, submitAction, isPending] = React.useActionState(async (previous, formData) => {
    await addItem(formData.get("sku"));
    return "added";
  }, null);
  const [optimistic, addOptimistic] = React.useOptimistic([], (state, next) => [...state, next]);
  return (
    <form action={submitAction}>
      <title>Add item</title>
      <meta name="description" content="Add a stock item" />
      <link rel="stylesheet" href="/form.css" precedence="default" />
      <input name="sku" required />
      <button type="submit" disabled={isPending} formAction={submitAction}>Add</button>
      <output>{message}{optimistic.length}</output>
    </form>
  );
}

const ThemeContext = React.createContext("light");
const themed = <ThemeContext value="dark"><Greeting name="Acme" /></ThemeContext>;
function Reader({ promise }) { const data = React.use(promise); return <pre>{data}</pre>; }

// ── Plain JavaScript statements and expressions ──
let counter = 0;
counter++; ++counter; counter--; --counter;
counter += 1; counter -= 1; counter *= 2; counter /= 2; counter %= 5; counter **= 2;
counter <<= 1; counter >>= 1; counter >>>= 1; counter &= 7; counter |= 8; counter ^= 3;
let flagA = null; flagA ||= 1; flagA &&= 2; flagA ??= 3;
const arithmetic = (7 % 3) + (2 ** 3) - (6 / 2) * 4;
const bitwise = (5 & 3) | (5 ^ 3) | (1 << 2) | (16 >> 1) | (16 >>> 1) | ~5;
const comparisons = [1 == 1, 1 != 2, 1 === 1, 1 !== 2, 1 <= 2, 2 >= 1];
const sequence = (counter++, counter--, counter);
const kinds = [typeof counter, void 0, delete inObject.element, "x" in inObject, inObject instanceof Object];

function* numbers() { yield 1; yield* [2, 3]; }
const genFn = function* () { yield 0; };
const namedFn = function named(a, b = 1, ...rest) { return [a, b, rest, new.target, arguments.length]; };
const pattern = /ab+c/giu.test("abbc");
const html = "<!-- not an HTML comment in a string -->";

label: for (let i = 0; i < 3; i++) {
  for (var j = 0; j < 3; j++) {
    if (j === 1) continue label;
    if (i === 2) break label;
  }
}
for (const key in inObject) { if (key) continue; }
for (const value of [1, 2]) { if (value) break; }
let loops = 0;
while (loops < 2) loops++;
do { loops--; } while (loops > 0);
;
if (loops) { } else if (!loops) { } else { }
try {
  throw new Error("boom", { cause: "demo" });
} catch (error) {
  console.error(error?.cause, error?.["message"], error?.toString?.());
} finally {
  debugger;
}
try { JSON.parse("{"); } catch { /* optional catch binding */ }

class Base { constructor() { this.id = 1; } greet() { return "base"; } }
class Derived extends Base {
  static #count = 0;
  #secret = 1;
  static { Derived.#count = 1; }
  constructor() { super(); this.#secret++; }
  greet() { return super.greet() + (#secret in this ? "!" : "?"); }
  get secret() { return this.#secret; }
  set secret(value) { this.#secret = value; }
}
const ClassExpression = class extends Base {};
const dynamicImport = () => import("./Settings.jsx");
const metaUrl = import.meta.url;

// ── Module forms and escapes ──
import * as everything from "./Settings.jsx";
import config from "./config.json" with { type: "json" };
export * as settingsNamespace from "./Settings.jsx";
export * from "./Settings.jsx";
export { everything as allSettings, config };
const escaped = "tab\t newline\n quote\" backslash\\ hex\x41 unicodeB braces\u{1F4E6} nul\0 vtab\v bell-ish\b ff\f cr\r";
const escapedSingle = 'it\'s é';
{
  using resource = { [Symbol.dispose]() {} }; // explicit resource management (ES2026)
}
