#!/usr/bin/env node
// @ts-check
"use strict";

// ── Comments ──
// Line comment
/* Block comment */
/**
 * JSDoc comment for the module.
 * @param {string} sku - Stock keeping unit.
 * @returns {Promise<number>} Quantity on hand.
 * @typedef {{ sku: string, qty: number }} StockLine
 */
// TODO: paginate the results
// FIXME: handle sparse arrays

// ── Imports and exports ──
import { readFile, writeFile as write } from "node:fs/promises";
import * as path from "node:path";
import defaultLogger, { level } from "./logger.js";
export { level };
export * from "./constants.js";
export * as helpers from "./helpers.js";

// ── Numbers ──
const integer = 42;
const negative = -17;
const float = 3.14159;
const leadingDot = .5;
const trailingDot = 5.;
const exponent = 6.022e23;
const negExp = 1E-9;
const hex = 0xFF_EC;
const octal = 0o755;
const binary = 0b1010_1010;
const big = 9_007_199_254_740_993n;
const hexBig = 0xFFn;
const specials = [NaN, Infinity, -Infinity, undefined, null];

// ── Strings ──
const single = 'It\'s a "pallet"';
const double = "Line one\nLine two\ttabbed \\ backslash";
const escapes = "\x41 \u0042 \u{1F4E6} \0 \v \f \b \r";
const continued = "joined \
across lines";
const unicode = "Zürich → 東京 ✓";
const name = "Widget";
const qty = 3;
const template = `Item ${name} x${qty} costs ${(qty * 2.5).toFixed(2)} — ${qty > 2 ? `bulk ${name}` : "single"}`;
const multiline = `first
second ${name}
third \${not interpolated} \` backtick`;
const tag = (strings, ...values) => strings.raw.join("|") + values.join(",");
const tagged = tag`sku=${name} count=${qty}\n`;
const raw = String.raw`C:\warehouse\bin\${name}`;

// ── Regular expressions ──
const skuPattern = /^[A-Z]{1,3}-\d{3,}(?:-(?<variant>[a-z]+))?$/giu;
const lookaround = /(?<=\$)\d+(\.\d+)?(?!\d)/;
const escapedSlash = /<\/?div[^>]*>/gm;
const sticky = /\bpallet\b/y;
const dotAll = /a.b/s;
const unicodeProps = /\p{Letter}+/u;

// ── Constants and keywords ──
const flags = { yes: true, no: false, nothing: null, unknown: undefined };
var declared = "var";
let mutable = 0;
const symbolKey = Symbol("internal");
const wellKnown = Symbol.iterator;

// ── Functions ──
function classic(a, b = 2, ...rest) {
  if (!new.target) console.log("called without new");
  return a + b + rest.length + arguments.length;
}

const arrow = (x) => x * 2;
const arrowBlock = async (x, { y = 1, z } = {}, [first, , third] = []) => {
  return x + y + (z ?? 0) + first + third;
};

function* idGenerator(start = 1) {
  let id = start;
  while (true) {
    const reset = yield id++;
    if (reset) id = start;
  }
}

async function* streamLines(handle) {
  for await (const chunk of handle) {
    yield* String(chunk).split("\n");
  }
}

const iife = (function () { return this; })();
const asyncIife = (async () => { await null; })();

// ── Classes ──
class Item {
  static #registry = new Map();
  static count = 0;
  #secret = "hidden";
  sku;
  quantity = 0;

  static {
    Item.count = 0;
  }

  constructor(sku, quantity) {
    this.sku = sku;
    this.quantity = quantity;
    Item.count++;
    Item.#registry.set(sku, this);
  }

  get label() { return `${this.sku} (${this.quantity})`; }
  set label(value) { [this.sku] = value.split(" "); }

  #privateMethod() { return this.#secret; }
  static create(sku) { return new this(sku, 0); }
  static isItem(o) { return #secret in o; }
  [Symbol.toPrimitive](hint) { return hint === "number" ? this.quantity : this.label; }
  toString() { return this.#privateMethod(); }
}

class Perishable extends Item {
  constructor(sku, quantity, expires) {
    super(sku, quantity);
    this.expires = expires;
  }
  get label() { return super.label + ` expires ${this.expires}`; }
}

// ── Objects, arrays, destructuring ──
const key = "dynamic";
const stock = {
  sku: "A-100",
  [key]: true,
  "quoted-key": 1,
  42: "numeric key",
  method() { return this.sku; },
  async load() {},
  *gen() {},
  get size() { return 1; },
  set size(v) {},
  ...{ spread: 1 },
};
const { sku, quantity: q = 0, ...others } = stock;
const [head, , third = 3, ...tail] = [1, 2, undefined, 4, 5];
const merged = [...tail, ...[6, 7]];
const nested = stock?.method?.() ?? stock?.["quoted-key"] ?? "none";

// ── Operators ──
let n = 10;
n += 1; n -= 1; n *= 2; n /= 2; n %= 7; n **= 2;
n <<= 1; n >>= 1; n >>>= 1; n &= 0xF; n |= 0x1; n ^= 0x3;
let logical = null;
logical ||= "default"; logical &&= logical + "!"; logical ??= "never";
const bits = ~n & 3 | 4 ^ 5;
const cmp = n === 1 || n !== 2 && !(n <= 3) || n >= 4 || n == "5" || n != 6;
const power = 2 ** 10;
const comma = (1, 2, 3);
const kind = typeof n, inst = stock instanceof Object, has = "sku" in stock;
delete stock.spread;
void 0;
const incr = n++ + ++n - n-- - --n;

// ── Control flow ──
outer: for (let i = 0; i < 3; i++) {
  for (const ch of "abc") {
    if (ch === "b") continue outer;
    if (i === 2) break outer;
  }
}
for (const k in stock) { if (Object.hasOwn(stock, k)) console.log(k); }
let w = 0;
while (w < 3) w++;
do { w--; } while (w > 0);

switch (kind) {
  case "number":
  case "bigint":
    console.log("numeric");
    break;
  default:
    console.log("other");
}

if (n > 5) {
  console.log("big");
} else if (n > 2) {
  console.log("medium");
} else {
  console.log("small");
}

// ── Errors and async ──
class StockError extends Error {
  constructor(message, options) {
    super(message, options);
    this.name = "StockError";
  }
}

async function load(file) {
  try {
    const text = await readFile(path.resolve(file), { encoding: "utf8" });
    return JSON.parse(text);
  } catch (err) {
    if (err instanceof SyntaxError) throw new StockError("bad json", { cause: err });
    throw err;
  } finally {
    console.log("done");
  }
}

try { null.x; } catch { /* optional catch binding */ }

new Promise((resolve, reject) => setTimeout(resolve, 10, "ok"))
  .then((v) => v.toUpperCase())
  .catch(console.error)
  .finally(() => console.log("settled"));

const results = await Promise.allSettled([load("a.json"), load("b.json")]);
const dyn = await import("./lazy.js");

// ── Collections and misc ──
const map = new Map([["a", 1]]);
const set = new Set([1, 2, 2, 3]);
const weak = new WeakMap();
const proxy = new Proxy({}, { get: (t, p) => Reflect.get(t, p) });
const sorted = [3, 1, 2].toSorted((a, b) => a - b).map((x) => x ** 2).filter(Boolean);
const date = new Date("2026-01-31T12:00:00Z");
debugger;
label: { break label; }

console.log(import.meta.url, globalThis, process.argv.length);
export default function main() { return [single, double, escapes, continued, template, tagged, raw]; }
// ── Rare constructs ──
import json from "./data.json" with { type: "json" };
export class Registry extends Map { static async *[Symbol.asyncIterator]() {} }
export { Item as ItemClass, Perishable as default2 };
const rareNumbers = [0B11, 0O17, 0XaB, 1_0.5e1_0, .1e-1, 0n, 0b1n, 1e3];
const rareStrings = ['\'', "\"", `\``, '\u{0}', "\x7f", '\
'];
const rareRegex = [/[/]/, /a|b/dgimsy, /[\p{L}--[a-z]]/v, /(?<year>\d{4})-\k<year>/, /\//, /(?:x)*?/];
async function* agen() { yield await 1; yield* [2, 3]; }
const o2 = { async *g() {}, async am() {}, get [key]() { return 1; }, set [key](v) {}, __proto__: null, "a b": 1 };
const fnExpr = function named() { return named; };
const asyncArrow = async x => await x;
const classExpr = class Named extends (class {}) {};
const optionalCall = stock.method?.(1)?.[0]?.prop;
const nullish = null ?? undefined ?? 0;
const comma2 = (a, b) => (a, b);
const exp2 = 2 ** (-1) ** 1 === undefined;

let [aa = 1, [bb] = [2], ...cc] = [], { dd = 3, ee: { ff } = { ff: 4 }, ...gg } = {};
for (const [k, v] of Object.entries({ a: 1 })) { }
for (var vv in { a: 1 }) { }
for await (const x of agen()) { break; }
if (typeof globalThis !== "undefined" && void 0 === undefined) { }
switch (1) { default: break; case 1: }
throw_label: try { throw 1; } catch ({ message }) { } finally { }
new (class {})();
new Foo;
(() => {})?.();
a: b: c: for (;;) break a;
export const VERSION = "1.0.0";
