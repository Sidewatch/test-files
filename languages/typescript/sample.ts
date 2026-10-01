#!/usr/bin/env -S deno run
// ── Comments ───────────────────────────────────────────────
// Line comment. TODO: batch the stock updates. FIXME: rounding.
/* Block comment
   spanning lines */
/**
 * Doc comment for the warehouse module.
 * @param sku - the stock keeping unit
 * @returns the item, if any
 * @example
 * findItem("WGT-100");
 * @deprecated use {@link lookup} instead
 */
/// <reference lib="es2022" />
// @ts-check
// @ts-expect-error: intentionally wrong below
// eslint-disable-next-line no-console

// ── Imports and exports ────────────────────────────────────
import { readFileSync, type PathLike } from "node:fs";
import * as path from "node:path";
import defaultExport, { join as joinPath, type Stats as FsStats } from "node:path";
import type { EventEmitter } from "node:events";
import json from "./data.json" with { type: "json" };
export { joinPath as join };
export * from "./types.js";
export * as helpers from "./helpers.js";
export type { Item as ExportedItem };
import fs = require("node:fs");
export = Warehouse;

// ── Numbers ────────────────────────────────────────────────
const decimal = 42;
const separated = 1_000_000;
const float = 3.14159;
const exponent = 1.5e-3;
const hex = 0xff_ff;
const octal = 0o755;
const binary = 0b1010_1010;
const big = 9_007_199_254_740_993n;
const nan = NaN;
const inf = -Infinity;

// ── Strings ────────────────────────────────────────────────
const single = 'it\'s a single-quoted string';
const double = "double with \"quotes\", \t tab, \n newline, \u00e9, \u{1F4E6}, \x41, \0";
const name = "WGT-100";
const tpl = `item ${name} has ${decimal * 2} units, ${`nested ${float.toFixed(1)}`}`;
const multi = `line one
line two with \` backtick and \${escaped}`;
const raw = String.raw`C:\inventory\${name}`;
function tag(strings: TemplateStringsArray, ...values: unknown[]): string {
  return strings.raw.join("|") + values.join(",");
}
const tagged = tag`sku=${name} qty=${decimal}`;

// ── Regular expressions ────────────────────────────────────
const skuPattern = /^[A-Z]{3}-\d{3,}$/giu;
const lookbehind = /(?<=\$)\d+(\.\d+)?|(?<year>\d{4})-(?<month>\d{2})/dgy;
const division = decimal / 2 / 3;

// ── Constants and primitives ───────────────────────────────
const truthy: boolean = true;
const falsy: boolean = false;
const empty: null = null;
let missing: undefined = undefined;
let anything: any = {};
let unknownValue: unknown = 1;
let sym: symbol = Symbol("sku");
let nothing: void;
let never: never;
let obj: object = {};

// ── Types, interfaces, enums ───────────────────────────────
type Sku = `${Uppercase<string>}-${number}`;
type Id = string | number;
type Pair<A, B = A> = readonly [first: A, second: B, ...rest: unknown[]];
type Optional<T> = { [K in keyof T]?: T[K] };
type Mutable<T> = { -readonly [K in keyof T]-?: T[K] };
type Renamed<T> = { [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K] };
type Unwrap<T> = T extends Promise<infer U> ? U : T extends Array<infer V> ? V : never;
type ElementOf<T> = T extends readonly (infer E)[] ? E : never;
type Fn = (this: void, a: number, b?: string, ...rest: boolean[]) => void;
type Ctor<T> = new (...args: any[]) => T;
type Abstract = abstract new () => object;
type Lookup = Item["sku"] | Item[keyof Item];
type Keys = keyof typeof defaults;
declare const brand: unique symbol;
type Branded<T> = T & { readonly [brand]: true };

interface Item {
  readonly sku: Sku | string;
  name: string;
  qty: number;
  price?: number;
  tags: string[];
  [extra: string]: unknown;
  (call: number): string;
  new (init: string): Item;
  method<T extends object = {}>(arg: T): void;
  get value(): number;
  set value(v: number);
}
interface Perishable extends Item, Partial<Pick<Item, "name">> {
  expires: Date;
}

enum Status { Pending, Paid = 10, Cancelled }
const enum Direction { Up = "UP", Down = "DOWN" }
declare enum Ambient { A = 1 }

// ── Namespaces, modules, ambient declarations ──────────────
namespace Warehouse {
  export const capacity = 500;
  export namespace Inner { export type Id = number; }
}
declare module "legacy-lib" {
  export function legacy(x: number): string;
}
declare global {
  interface Window { inventory: Item[]; }
}
declare function ambient(x: number): void;
declare let ambientVar: string;

// ── Decorators and classes ─────────────────────────────────
function logged(target: Function, ctx: ClassDecoratorContext): void {
  ctx.addInitializer(() => console.log(`registered ${target.name}`));
}
function bound(_t: Function, ctx: ClassMethodDecoratorContext<any>): void {
  ctx.addInitializer(function (this: any) { this[ctx.name] = this[ctx.name].bind(this); });
}

@logged
abstract class Base<T extends object = {}> implements Iterable<T> {
  static #instances = 0;
  static readonly VERSION = "1.0";
  static { Base.#instances = 0; }
  #secret = "hidden";
  protected abstract readonly kind: string;
  public declare phantom: number;
  private _qty = 0;
  override toString(): string { return `${this.kind}`; }
  constructor(public readonly sku: string, protected qty = 0, private tags: string[] = []) {
    Base.#instances++;
  }
  get quantity(): number { return this._qty; }
  set quantity(v: number) { this._qty = v; }
  accessor auto = 1;
  @bound
  describe(this: Base<T>, prefix?: string): string { return `${prefix ?? ""}${this.sku}`; }
  abstract compute(): number;
  *[Symbol.iterator](): Iterator<T> { yield* []; }
  async *stream(): AsyncGenerator<number, void, unknown> { yield 1; }
  static create<U extends object>(this: new () => Base<U>): Base<U> { return new this(); }
  #privateMethod(): boolean { return #secret in this; }
}

class Product extends Base<Item> implements Perishable {
  protected kind = "product";
  expires = new Date(0);
  readonly sku!: string;
  constructor() { super("WGT-100"); }
  compute(): number { return super.quantity * 2; }
}

// ── Functions ──────────────────────────────────────────────
function overloaded(x: string): string;
function overloaded(x: number): number;
function overloaded(x: any): any { return x; }

function isItem(x: unknown): x is Item { return typeof x === "object" && x !== null && "sku" in x; }
function assertItem(x: unknown): asserts x is Item { if (!isItem(x)) throw new TypeError("not an item"); }
function assertDefined<T>(x: T): asserts x is NonNullable<T> {}

const arrow = async <T,>(x: T, ...rest: T[]): Promise<T[]> => [x, ...rest];
const iife = (() => 42)();
function* counter(limit = 3): Generator<number, string, boolean> {
  for (let i = 0; i < limit; i++) { const stop = yield i; if (stop) return "stopped"; }
  return "done";
}
function defaults({ a = 1, b: { c = 2 } = {} }: { a?: number; b?: { c?: number } } = {}, [d, , e = 5] = [1, 2]) {
  return a + c + d + e;
}

// ── Expressions and operators ──────────────────────────────
let n = 10;
n += 1; n -= 1; n *= 2; n /= 2; n %= 7; n **= 2; n <<= 1; n >>= 1; n >>>= 1; n &= 0xf; n |= 1; n ^= 2;
let maybe: number | undefined;
maybe ??= 5; maybe ||= 6; maybe &&= 7;
const arith = (1 + 2) * 3 - 4 / 5 % 6 ** 2;
const bits = ~1 & 2 | 3 ^ 4 << 1 >> 1 >>> 1;
const logic = !truthy && falsy || truthy;
const compare = n < 1 || n > 2 || n <= 3 || n >= 4 || n == 5 || n != 6 || n === 7 || n !== 8;
const ternary = n > 5 ? "big" : n > 2 ? "medium" : "small";
const chain = alice?.profile?.["email"]?.toUpperCase?.() ?? "none";
const nonNull = alice!.name!;
const cast = <unknown>n as number;
const satisfied = { a: 1 } satisfies Record<string, number>;
const typeofExpr = typeof n === "number" && n instanceof Object && "x" in {};
const spreadArr = [...[1, 2], ...new Set([3])];
const spreadObj = { ...{ a: 1 }, b: 2, ["computed" + 1]: 3, get g() { return 1; }, async *gen() {}, method() {} };
const [first, , third = 3, ...others] = [1, 2, undefined, 4, 5];
const { a, b: renamed, ...restObj } = { a: 1, b: 2, c: 3 };
const del = delete (restObj as any).c;
const v = void 0;
const comma = (1, 2);
const nested = new Map<string, Array<Record<string, number | undefined>>>();
const optionalCall = nested.get?.("x")?.[0]?.y;
const newTarget = function () { return new.target; };
const imported = await import("./lazy.js");
const meta = import.meta.url;

// ── Control flow ───────────────────────────────────────────
declare const alice: { name: string; profile?: { email?: string } };

outer: for (let i = 0; i < 3; i++) {
  for (const j of [1, 2, 3]) {
    if (j === 2) continue outer;
    if (i === 2) break outer;
  }
}
for (const key in { a: 1 }) { console.log(key); }
for await (const chunk of (async function* () { yield 1; })()) { console.log(chunk); }
while (n > 0) { n--; }
do { n++; } while (n < 3);
switch (n) {
  case 1:
  case 2: console.log("low"); break;
  default: console.log("other");
}
label: { break label; }
if (n) { } else if (!n) { } else { }
with_try: try {
  throw new Error("failure", { cause: "reason" });
} catch (err: unknown) {
  if (err instanceof Error) console.error(err.message);
} finally {
  console.log("done");
}
try { } catch { }
debugger;

// ── Async ──────────────────────────────────────────────────
async function load(file: PathLike): Promise<number> {
  const raw = await Promise.all([readFileSync(file, "utf-8")]);
  return raw.length * 2;
}
using resource = { [Symbol.dispose]() {} };
await using handle = { async [Symbol.asyncDispose]() {} };

// ── Generics with constraints ──────────────────────────────
function pick<T extends object, K extends keyof T>(o: T, ...keys: K[]): Pick<T, K> {
  return Object.fromEntries(keys.map((k) => [k, o[k]])) as Pick<T, K>;
}
class Box<in out T = unknown, const U extends readonly unknown[] = []> {}

export default class Inventory {}
export abstract class Shape {}
export declare const done: boolean;

// ── More type-level syntax ─────────────────────────────────
import InnerId = Warehouse.Inner;
import type Legacy = require("legacy-lib");
declare module "*.css" { const styles: Record<string, string>; export default styles; }
declare namespace NodeJS { interface ProcessEnv { WAREHOUSE_HOME?: string } }
type ReadonlyList = readonly string[];
type ReadonlyTuple = readonly [x: number, y?: number];
type Imported = typeof import("node:fs");
type ImportedType = import("node:fs").Stats;
type First<T extends readonly unknown[]> = T extends readonly [infer H extends string, ...infer _Rest] ? H : never;
type Getters<T> = { [K in keyof T & string as `get${Capitalize<K>}`]: () => T[K] };
type Conditional<T> = T extends string ? "s" : T extends number ? "n" : T extends (...args: any[]) => infer R ? R : never;
type Distribute<T> = T extends unknown ? T[] : never;
type Union = "a" | "b" | 1 | 2n | true | null | undefined | symbol | bigint | object | never | unknown | any | void;
type Intersect = { a: 1 } & { b: 2 } & Record<string, unknown>;
type FnWithThis = (this: Window, ev: Event) => any;
type ThisTyped = ThisType<{ x: number }>;
type Lower = Lowercase<"ABC"> | Uppercase<"abc"> | Capitalize<"abc"> | Uncapitalize<"ABC">;
type Utility = Partial<Item> | Required<Item> | Readonly<Item> | Pick<Item, "sku"> | Omit<Item, "sku"> | Exclude<1 | 2, 1> | Extract<1 | 2, 1> | NonNullable<string | null> | ReturnType<typeof isItem> | Parameters<typeof tag> | InstanceType<typeof Product> | Awaited<Promise<string>> | NoInfer<string>;
type Recursive = { next?: Recursive } | Recursive[];
type Accessors = { get x(): number; set x(v: number) };
type Optionality = { a?: number; readonly b: string };
type Stripped = { -readonly [K in "c"]-?: boolean };
type Added = { +readonly [K in "c"]+?: boolean };
type ArrayOf<T> = T[] | Array<T> | ReadonlyArray<T> | [T, ...T[]];
type Predicate<T> = (value: T) => value is T & { checked: true };
type Asserts = (value: unknown) => asserts value;
type Ctor2 = abstract new (...args: any) => object;
type Accessor<T> = { readonly [index: number]: T; [key: string]: T | number };

// ── More statements and expressions ────────────────────────
class Fluent {
  value = 0;
  add(n: number): this { this.value += n; return this; }
  isZero(): this is Fluent & { value: 0 } { return this.value === 0; }
  static override readonly [Symbol.hasInstance] = (x: unknown) => true;
  declare static readonly brand: unique symbol;
  constructor(private readonly a: number, protected b?: string, public c = 1, readonly d: boolean = false) {}
}
const chained = new Fluent(1).add(1).add(2);
const generic = new Map<string, Set<Array<readonly [number, string]>>>();
const call = identity<string>("x");
function identity<const T>(x: T): T { return x; }
const objWithMethods = {
  async *agen() { yield 1; },
  *gen() { yield 2; },
  async method() {},
  get prop() { return 1; },
  set prop(v) {},
  [`computed${1}`]: 1,
  "quoted-key": 2,
  123: 3,
  shorthand: 4,
  arrow: (x: number) => x,
};
const inOp = "x" in objWithMethods;
const voidOp = void 0;
const typeofOp = typeof objWithMethods;
const exponent2 = 2 ** 3 ** 2;
const comma2 = (1, 2, 3);
const optionalElement = [1, , 3];
const tplNested = `a${`b${`c${1}`}`}`;
const regexFlags = /[\p{L}&&[^a-z]]/vs;
const hashbangLike = "#!/not/a/shebang";
const nulEscape = "\0";
const lineContinuation = "line \
continues";
const unicodeIdentifier = { café: 1, π: 3.14, $dollar: 2, _under: 3, ünï: 4 };
label2: while (true) { break label2; }
if (maybe) maybe++; else maybe--;
for (;;) { break; }
for (var legacy = 0, other = 1; legacy < 1; legacy++) {}
var hoisted = 1;
let [swapA, swapB] = [1, 2];
[swapA, swapB] = [swapB, swapA];
({ a: swapA } = { a: 3 });
throw new RangeError("done");
