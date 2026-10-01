#!/usr/bin/env node
// TypeScript 5.9 + React 19 JSX — TSX syntax showcase
// ── Comments ──
// Line comment: warehouse inventory UI in TSX.
/* Block comment
   spanning lines. */
/**
 * JSDoc block comment.
 * @param {string} sku - the stock keeping unit
 * @returns {JSX.Element} the badge
 * @deprecated use <StockBadge /> instead
 * @see https://example.com/docs
 */
// TODO: virtualise the table
// FIXME: focus ring disappears on the clear button
// @ts-expect-error intentionally untyped
// eslint-disable-next-line no-console

"use client";

// ── Imports and exports ──
import React, {
  useState,
  useEffect,
  useCallback,
  useMemo,
  useRef,
  useReducer,
  useContext,
  createContext,
  forwardRef,
  Fragment,
  type ReactNode,
  type ComponentPropsWithoutRef,
} from "react";
import type { FC, PropsWithChildren } from "react";
import * as Utils from "./utils";
import Default, { named as alias } from "./module";
import json from "./data.json" with { type: "json" };
import "./styles.css";

export { Utils };
export type { Item as StockItem };
export * from "./types";
export * as Types from "./types";

// ── Types, interfaces, enums ──
type Variant = "primary" | "ghost" | `custom-${string}`;
type Status = "ok" | "low" | "out";
type Maybe<T> = T | null | undefined;
type Callback<A extends unknown[] = [], R = void> = (...args: A) => R;
type Mutable<T> = { -readonly [K in keyof T]-?: T[K] };
type Getters<T> = { [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K] };
type Unwrap<T> = T extends Promise<infer U> ? U : T extends Array<infer V> ? V : never;
type Tuple = [sku: string, qty?: number, ...rest: boolean[]];
type Fn = new (sku: string) => Item;

interface Item {
  readonly id: string;
  sku: string;
  name: string;
  quantity: number;
  price?: number;
  tags: Array<string>;
  [extra: string]: unknown;
}

interface BadgeProps extends ComponentPropsWithoutRef<"span"> {
  label: string;
  count?: number;
  variant?: Variant;
  onSelect?: (id: string) => void;
}

enum Level {
  Low = 1,
  Medium,
  High = "HIGH".length,
}

const enum Flags {
  None = 0,
  Fragile = 1 << 0,
  Heavy = 1 << 1,
}

declare const __VERSION__: string;
declare global {
  interface Window {
    inventory: { version: string };
  }
}
declare module "*.svg" {
  const src: string;
  export default src;
}

namespace Warehouse {
  export const REORDER_POINT = 25;
  export function isLow(item: Item): boolean {
    return item.quantity <= REORDER_POINT;
  }
}

abstract class Repository<T extends { id: string }> {
  protected items = new Map<string, T>();
  abstract load(): Promise<T[]>;
  get size(): number { return this.items.size; }
  set size(_: number) { throw new Error("read-only"); }
}

class ItemRepository extends Repository<Item> implements Iterable<Item> {
  static #instances = 0;
  #secret = "private field";
  private readonly cache: Item[] = [];
  declare public label: string;
  static readonly VERSION = "1.4.0";
  static { ItemRepository.#instances++; }

  constructor(public readonly name: string, private limit: number = 100) {
    super();
  }

  override async load(): Promise<Item[]> {
    const res = await fetch(`/api/items?limit=${this.limit}`);
    return (await res.json()) as Item[];
  }

  *[Symbol.iterator](): Iterator<Item> {
    yield* this.items.values();
  }

  async *stream(): AsyncGenerator<Item, void, unknown> {
    for await (const chunk of this.chunks()) yield* chunk;
  }

  private async *chunks(): AsyncIterable<Item[]> { yield []; }
}

// ── Literals ──
const nothing = null, undef = undefined, yes = true, no = false;
const decimal = 1_000_000, hex = 0xff_ec, octal = 0o755, binary = 0b1010, big = 12345678901234567890n;
const float = 3.14, exp = 1.5e-3, notANumber = NaN, infinite = -Infinity;
const strings = ['single', "double", `template ${decimal + 1} ${`nested ${yes}`}`];
const escapes = "tab\t newline\n quote\" backslash\\ hex\x41 unicode\u00e9 code\u{1F3ED} octal\0";
const regex = /^(?<prefix>[A-Z]{3})-(?<num>\d+)$/giu;
const regexLookbehind = /(?<=\$)\d+(?!\d)/dgimsuy;
const tagged = String.raw`C:\path\${decimal}`;
const html = ((s: TemplateStringsArray, ...v: unknown[]) => s.raw.join(""))`<p>${decimal}</p>`;
const array = [1, , 3, ...[4, 5]];
const object = { a: 1, "b-c": 2, [`d${decimal}`]: 3, get e() { return 1; }, set e(_v) {}, async f() {}, *g() {}, h, ...{ i: 1 } };
const h = 1;

// ── Generics, overloads, decorators ──
function identity<T>(value: T): T { return value; }
function overloaded(a: string): string;
function overloaded(a: number): number;
function overloaded(a: unknown): unknown { return a; }
const arrow = <T extends object = {}>(value: T): T => value;
const generic = <T,>(x: T) => x;

function assertIsString(val: unknown): asserts val is string {
  if (typeof val !== "string") throw new TypeError("not a string");
}
function isItem(val: unknown): val is Item {
  return typeof val === "object" && val !== null && "sku" in val;
}

function logged(target: unknown, context: ClassMethodDecoratorContext) {
  return function (this: unknown, ...args: unknown[]) { return (target as Function).apply(this, args); };
}

@sealed
class Decorated {
  @logged method() {}
  @observable accessor count = 0;
  constructor(@inject("token") private readonly dep: string) {}
}
function sealed(constructor: Function) { Object.seal(constructor); }
function observable(_t: unknown, _c: unknown) {}
function inject(_token: string) { return (_t: object, _k: string | symbol | undefined, _i: number) => {}; }

// ── Expressions and operators ──
function operators(a: number, b: number, c?: { d?: { e?: number } }): number {
  let x = a + b - a * b / (b + 1) % 7 ** 2;
  x += 1; x -= 1; x *= 2; x /= 2; x %= 100; x **= 2;
  x &= 0xff; x |= 0x0f; x ^= 1; x <<= 2; x >>= 1; x >>>= 1;
  let y: number | undefined;
  y ??= 5; y ||= 6; y &&= 7;
  const bits = (a & b) | (a ^ b) | ~a;
  const shifted = a << 3 >> 1 >>> 2;
  const logic = a > b && b >= 0 || !(a === b) && a !== b && a == b && a != b;
  const ternary = a > b ? a : b;
  const coalesced = c?.d?.e ?? 0;
  const chained = c?.["d"]?.e!;
  const nonNull = c!.d!.e!;
  const cast = a as unknown as string;
  const satisfied = { a } satisfies Record<string, number>;
  const kind = typeof a, isIn = "d" in (c ?? {}), isInst = c instanceof Object;
  const voided = void 0, deleted = delete (c as any)?.d;
  const comma = (a++, b--, ++a, --b);
  const spread = Math.max(...[a, b], 0);
  const { d: { e = 5 } = {}, ...restProps } = c ?? {};
  const [first, , third = 3, ...others] = [1, 2, undefined, 4, 5];
  return x + (bits | shifted) + (logic ? 1 : 0) + ternary + coalesced + (chained ?? 0) + nonNull +
    Number(cast) + (satisfied.a) + kind.length + Number(isIn) + Number(isInst) + (voided ?? 0) +
    Number(deleted) + comma + spread + e + Object.keys(restProps).length + first + third + others.length;
}

// ── Control flow ──
async function control(items: Item[]): Promise<void> {
  outer: for (let i = 0; i < items.length; i++) {
    for (const item of items) {
      if (item.quantity === 0) continue outer;
      else if (item.quantity > 1000) break outer;
    }
  }
  for (const key in items[0]) console.log(key);
  for await (const chunk of new ItemRepository("x").stream()) console.log(chunk);
  let n = 0;
  while (n < 3) n++;
  do { n--; } while (n > 0);
  switch (items.length) {
    case 0: console.log("empty"); break;
    case 1:
    case 2: { console.log("few"); break; }
    default: console.log("many");
  }
  try {
    await Promise.all(items.map(async (item) => item.quantity));
    throw new RangeError("out of range");
  } catch (error: unknown) {
    if (error instanceof RangeError) console.error(error.message);
  } finally {
    console.debug("done");
  }
  debugger;
  label: { break label; }
  with_(items);
}
function with_(_: unknown) {}

// ── Context, reducer, hooks ──
const ThemeContext = createContext<{ dark: boolean; toggle(): void }>({ dark: false, toggle() {} });

type Action = { type: "add"; item: Item } | { type: "remove"; id: string } | { type: "clear" };
function reducer(state: Item[], action: Action): Item[] {
  switch (action.type) {
    case "add": return [...state, action.item];
    case "remove": return state.filter((i) => i.id !== action.id);
    case "clear": return [];
    default: { const _exhaustive: never = action; return state; }
  }
}

function useDebounced<T>(value: T, delay = 250): T {
  const [debounced, setDebounced] = useState<T>(value);
  useEffect(() => {
    const handle = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(handle);
  }, [value, delay]);
  return debounced;
}

// ── Components ──
function Badge({ label, count = 0, variant = "primary", onSelect, ...rest }: BadgeProps) {
  return (
    <span
      className={`badge badge--${variant}`}
      data-count={count}
      aria-label={label}
      role="status"
      style={{ fontWeight: 600, "--accent": "#336699" } as React.CSSProperties}
      onClick={() => onSelect?.(label)}
      {...rest}
    >
      {label}
      {count > 0 && <sup>{count}</sup>}
    </span>
  );
}

const Panel = forwardRef<HTMLDivElement, PropsWithChildren<{ title: string }>>(
  function Panel({ title, children }, ref) {
    return (
      <div ref={ref} className="panel">
        <h2>{title}</h2>
        {children}
      </div>
    );
  }
);

const List = <T extends { id: string }>({ items, render }: { items: T[]; render: (item: T) => ReactNode }) => (
  <ul>{items.map((item) => <li key={item.id}>{render(item)}</li>)}</ul>
);

export default function Toolbar<T extends { id: string }>({ items }: { items: T[] }) {
  const [active, setActive] = useState<string | null>(null);
  const [state, dispatch] = useReducer(reducer, [] as Item[]);
  const inputRef = useRef<HTMLInputElement>(null);
  const theme = useContext(ThemeContext);
  const query = useDebounced(active ?? "");
  const pick = useCallback((id: string) => setActive(id), []);
  const total = useMemo(() => state.reduce((sum, i) => sum + i.quantity, 0), [state]);

  useEffect(() => {
    inputRef.current?.focus();
    const onKey = (event: KeyboardEvent) => event.key === "Escape" && setActive(null);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  return (
    <>
      {/* JSX comment: toolbar with badges */}
      <nav className="toolbar" aria-label="Main" data-theme={theme.dark ? "dark" : "light"}>
        {items.map((item) => (
          <Badge key={item.id} label={item.id} count={items.length} onSelect={pick} />
        ))}
        <input ref={inputRef} type="search" defaultValue={query} placeholder="Filter…" disabled={false} />
        <button
          type="button"
          disabled={active === null}
          onClick={() => { setActive(null); dispatch({ type: "clear" }); }}
        >
          Clear
        </button>
        <label htmlFor="qty">Qty &amp; price &nbsp;&copy; 2026</label>
        <select id="qty" value={String(total)} onChange={(e) => console.log(e.target.value)}>
          <option value="0">None</option>
          <option value="1">One</option>
        </select>
        <svg viewBox="0 0 24 24" width={24} height={24} xmlns="http://www.w3.org/2000/svg">
          <path d="M12 2l3 7h7l-5.5 4.5L18 21l-6-4-6 4 1.5-7.5L2 9h7z" fill="currentColor" />
        </svg>
        <Panel title="Details">
          <List items={state} render={(item) => <strong>{item.name}</strong>} />
        </Panel>
        <Fragment key="frag">
          <React.Fragment>{null}{undefined}{false}{0}</React.Fragment>
        </Fragment>
        <ThemeContext.Provider value={{ dark: true, toggle() {} }}>
          <ThemeContext.Consumer>{(ctx) => <i>{String(ctx.dark)}</i>}</ThemeContext.Consumer>
        </ThemeContext.Provider>
        <Utils.Icon name="warehouse" {...{ size: 16 }} />
        <p dangerouslySetInnerHTML={{ __html: "<em>raw</em>" }} />
      </nav>
      {active ? <p className="hint">Selected: {active}</p> : <p className="hint">Nothing selected</p>}
      {active && (
        <p>
          {active.length > 3 ? `Long: ${active}` : "Short"} — total {total.toLocaleString("en-GB")}
        </p>
      )}
    </>
  );
}

export const config = { runtime: "edge", version: typeof __VERSION__ === "string" ? __VERSION__ : "dev" } as const;
export { Badge as StockBadge, Warehouse, Level, Flags };

// ── Type-system forms ──
import fs = require("node:fs");
import Path = Warehouse.REORDER_POINT;
import type Mod = require("./module");
export import Alias = Warehouse;
// CommonJS-only form: cannot coexist with the ES exports above in a real build.
export = Warehouse;
declare const uniqueTag: unique symbol;
type Probe = typeof uniqueTag;
type Opt = [string?, number?];
type Rest = [first: string, ...rest: number[]];
type Ro = readonly string[];
type RoTuple = readonly [x: number, y: number];
type Paren = (string | number)[];
type Self = { chain(): this };
type Callable = { (sku: string): Item; new (sku: string): Item; readonly [key: string]: unknown };
type Instance = InstanceType<typeof ItemRepository>;
type Nested = Types.Deep.Name;
type Keys = keyof typeof Warehouse;
type Cond<T> = T extends readonly (infer U)[] ? U : never;
type NarrowInfer<T> = T extends [infer H extends string, ...infer R] ? [H, R] : never;
type Abstract = abstract new (...args: any[]) => object;
declare function assertNever(x: never): never;
declare class Ambient { method(): void; static create(): Ambient }
declare namespace Types.Deep { type Name = string }

// ── Instantiation expressions and meta properties ──
const makeBox = <T,>(value: T) => ({ value });
const stringBox = makeBox<string>;
const metaUrl = import.meta.url;
function Ctor(this: { made?: boolean }) {
  if (!new.target) return;
  this.made = true;
}

// ── Older declaration forms ──
var legacy = 1;
var a1 = 1, b1 = 2;
let assigned: number;
assigned = 5;
assigned += 1;
;
const GenExpr = function* () { yield 1; };
function* genDecl(): Generator<number> { yield 1; yield* [2, 3]; }
const ClassExpr = class Named { static x = 1; };
const json2 = await import("./data.json", { with: { type: "json" } });
// deprecated import-assertion spelling (replaced by `with`):
import legacyJson from "./data.json" assert { type: "json" };

// ── Explicit resource management ──
async function useResources() {
  using handle = { [Symbol.dispose]() { console.log("closed"); } };
  await using conn = { async [Symbol.asyncDispose]() { console.log("closed async"); } };
  for (using h of [handle]) void h;
  for (await using c of [conn]) void c;
}

// ── JSX forms ──
const NS = <svg:rect xlink:href="#a" width="10" />;
const Member = <Utils.Icon name="x" />;
const Generic = <List<Item> items={[]} render={(i) => <b>{i.name}</b>} />;
const Spread = <Badge {...{ label: "x" }} label="y" />;
const Entities = <p>&lt;&amp;&gt; &#169; &#x1F3ED;</p>;
const Attr = <a href='single' title="double" data-x={`tpl ${1}`} hidden>text</a>;
