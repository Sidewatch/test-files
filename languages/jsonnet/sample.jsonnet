// Jsonnet 0.21 — syntax showcase (no jsonnet binary installed here; checked against the language reference)
# Hash comment form
/* Block comment
   across lines */
/** Doc-style block comment */

// ── Imports ──
local base = import 'base.libsonnet';
local raw_text = importstr 'banner.txt';
local binary = importbin 'logo.bin';
local lib = import "lib/helpers.libsonnet";
local std2 = std;

// ── Locals, numbers, literals ──
local integer = 42;
local negative = -17;
local float = 3.14159;
local exponent = 6.022e23;
local small = 1E-9;
local flags = [true, false, null];
local self_ref = { a: 1, b: self.a + 1, c: $.top };

// ── Strings ──
local strings = {
  single: 'It\'s "quoted"',
  double: "Tab\t newline\n quote \" backslash \\ unicode \u00e9",
  verbatimSingle: @'C:\warehouse\bin ''with'' doubled quote',
  verbatimDouble: @"C:\warehouse\bin ""with"" doubled quote",
  block: |||
    Multi-line text block
      keeps relative indentation
    and "quotes" and \backslashes\ and %(placeholder)s
  |||,
  stripped: |||-
    no trailing newline
  |||,
  unicode: 'Zürich → 東京 ✓',
};

// ── Functions ──
local service(name, replicas=1, env='staging', labels={}) = {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: { name: name, labels: { app: name, env: env } + labels },
  spec: {
    replicas: replicas,
    template: {
      spec: {
        containers: [{
          name: name,
          image: 'registry.example.com/%s:%s' % [name, base.version],
          args: ['--port=%(port)d' % { port: 8080 }, '--env=' + env],
          env: [{ name: k, value: std.toString(base.env[env][k]) } for k in std.objectFields(base.env[env])],
          resources: if env == 'prod' then { limits: { memory: '1Gi', cpu: '500m' } } else {},
        }],
      },
    },
  },
};

local fib(n) = if n <= 1 then n else fib(n - 1) + fib(n - 2);
local apply(f, x) = f(x);
local anon = function(x, y=2) x * y;
local mixed(a, b, c=3, d=4) = a + b + c + d;

// ── Operators ──
local ops = {
  arithmetic: 1 + 2 - 3 * 4 / 5 % 6,
  bitwise: (1 << 3) | (255 & 15) ^ 7 >> 1,
  complement: ~5,
  comparison: 1 < 2 && 2 <= 3 || 3 > 4 && 4 >= 5,
  equality: 1 == 1 && 1 != 2,
  negation: !true,
  unary: -(+1),
  membership: 'a' in { a: 1 },
  stringIndex: 'hello'[1],
  slice: [1, 2, 3, 4, 5][1:4:2],
  concat: [1] + [2] + 'x'[0:1],
  objectMerge: { a: 1 } + { b: 2 } + { a:: 3 },
  ternary: if self.arithmetic > 0 then 'positive' else 'negative',
  noElse: if false then 1,
  superRef: { a: 1 } + { b: super.a },
  error_unless: if std.length(flags) > 0 then 'ok' else error 'empty',
  assertion: assert 1 < 2 : 'math works'; 'asserted',
};

// ── Comprehensions ──
local comprehensions = {
  list: [x * x for x in std.range(1, 5) if x % 2 == 1],
  nested: [[x, y] for x in [1, 2] for y in ['a', 'b']],
  object: { ['key_' + k]: k for k in ['a', 'b'] },
  objectIf: { [k]: base.env[k] for k in std.objectFields(base.env) if k != 'dev' },
};

// ── Objects: visibility, fields, asserts ──
local object = {
  visible: 1,
  hidden:: 2,
  forced::: 3,
  inherited: self.hidden + self.forced,
  'quoted-field': 4,
  ['computed_' + 'name']: 5,
  nested+: { added: true },
  method(x): x + self.visible,
  assert self.visible > 0 : 'visible must be positive',
  local private = 99,
  usesPrivate: private,
  withLocal: local t = 1; t + 1,
  outer: $.visible,
  [if true then 'conditional']: 'present',
  field_plus:: { a: 1 },
  override+:: { b: 2 },
};

// ── Standard library calls ──
local stdlib = {
  length: std.length([1, 2, 3]),
  map: std.map(function(x) x * 2, [1, 2, 3]),
  filter: std.filter(function(x) x > 1, [1, 2, 3]),
  foldl: std.foldl(function(acc, x) acc + x, [1, 2, 3], 0),
  join: std.join(', ', ['a', 'b']),
  format: std.format('%05.1f|%-5s|%x|%e|%%', [3.14159, 'ab', 255, 1000]),
  manifest: std.manifestYamlDoc({ a: [1, 2] }),
  json: std.manifestJsonEx({ a: 1 }, '  '),
  thisFile: std.thisFile,
  ext: std.extVar('environment'),
  tla: std.native('hash')('x'),
  trace: std.trace('debug', 1),
  type: std.type(null),
  isString: std.isString('x'),
  codepoint: std.codepoint('a'),
  md5: std.md5('abc'),
  base64: std.base64('abc'),
  parse: std.parseJson('{"a": 1}'),
  sets: std.setUnion([1, 2], [2, 3]),
  sort: std.sort([3, 1, 2]),
  pow: std.pow(2, 10),
  infinity: 1e308 * 10,
};

// ── Rare constructs ──
local multi_a = 1, multi_b(x) = x + multi_a, multi_c = multi_b(2);
local composed = { a: 1 } { b: 2 } { c: super.a };
local field_forms = {
  plain: 1,
  plus+: { more: true },
  hidden_plus+:: 2,
  forced_plus+::: 3,
  'single-quoted': 4,
  "double-quoted": 5,
  |||
    block key
  |||: 6,
  @'verbatim key': 7,
  method(a, b=2): a + b,
  'quoted method'(x): x,
  [self.plain]: 'computed from self',
  [if self.plain > 0 then 'cond']: 8,
  ['a' + 'b']:: 9,
  local helper = 10,
  uses_helper: helper,
  assert self.plain == 1,
  assert self.plain >= 0 : 'message',
  nested: { inner: $.plain + self.plain, outer_super: super },
};
local access_forms = {
  a: field_forms.plain,
  b: field_forms['single-quoted'],
  c: field_forms.method(1, b=3),
  d: field_forms.method(a=1),
  e: [1, 2, 3][1],
  f: 'abc'[1:],
  g: [1, 2, 3, 4][::2],
  h: [1, 2, 3, 4][1:3],
  i: [1, 2, 3, 4][:-1],
  j: 'x' in field_forms,
  k: 'plain' in field_forms && !('missing' in field_forms),
  l: field_forms { plain: 99 }.plain,
  m: (function(x) x)(1),
  n: (function(x=1, y) x + y)(y=2),
};
local tailstrict_demo(n, acc=0) = if n == 0 then acc else tailstrict_demo(n - 1, acc + n) tailstrict;
local more_numbers = [0, 1.5, 1e2, 1E2, 1e+2, 1e-2, 0.0, 100, 1000000];
local more_strings = [
  'single \' \" \\ \/ \b \f \n \r \t \u0041 \u00e9',
  "double \' \" \\ \/ \b \f \n \r \t \u0041",
  @'verbatim \n stays; '' is a quote',
  @"verbatim \n stays; "" is a quote",
  |||
      indented block
        keeps nesting
    |||,
  |||-
    chomped block
  |||,
  |||
	tab-indented block
  |||,
  'a' + 'b' + "c",
  'fmt %s %d %5.2f %x %% %(name)s' % ['a', 1, 2.5, 255] ,
  '%(a)s-%(b)s' % { a: 1, b: 2 },
  'x' * 3,
];
local more_ops = {
  and_or: true && false || true,
  not_: !false,
  bit: (5 & 3) | (5 ^ 3),
  bitnot: ~5,
  shifts: (1 << 4) >> 2,
  cmp: [1 < 2, 1 <= 2, 2 > 1, 2 >= 1, 1 == 1, 1 != 2],
  arithmetic: 7 + 3 - 2 * 4 / 5 % 3,
  string_cmp: 'a' < 'b',
  array_cmp: [1, 2] < [1, 3],
  unary: [-1, +1, -(-1)],
  precedence: 1 + 2 * 3 - (4 + 5) / 3,
  obj_eq: { a: 1 } == { a: 1 },
  in_super: 'x' in super,
  coalesce: if std.objectHas({}, 'a') then 1 else 2,
};
local imports_demo = [import 'a.libsonnet', importstr 'b.txt', importbin 'c.bin', import "d.json"];
local errors_demo = if false then error 'unreachable' else null;
local anonymous_fn = function(x, y=x * 2) x + y;
local std_more = {
  a: std.makeArray(3, function(i) i * i),
  b: std.slice([1, 2, 3], 1, 3, 1),
  c: std.mapWithIndex(function(i, x) [i, x], ['a']),
  d: std.objectFieldsAll({ a:: 1 }),
  e: std.mergePatch({ a: 1 }, { a: null }),
  f: std.lines(['a', 'b']),
  g: std.toString(1),
  h: std.assertEqual(1, 1),
  i: std.manifestIni({ sections: { s: { k: 'v' } } }),
  j: std.escapeStringJson('a"b'),
  k: std.get({ a: 1 }, 'b', default=0),
};

// ── Jsonnet 0.20 / 0.21 additions ──
local newer_std = {
  a: std.xor(true, false),
  b: std.xnor(true, false),
  c: std.trim('  padded  '),
  d: std.objectRemoveKey({ a: 1, b: 2 }, 'a'),
  e: std.sum([1, 2, 3]) + std.avg([1, 2, 3]),
  f: std.minArray([3, 1, 2]) + std.maxArray([3, 1, 2]),
  g: std.all([true, true]) && std.any([false, true]),
  h: std.contains([1, 2], 2),
  i: std.isEmpty(''),
  j: std.equalsIgnoreCase('A', 'a'),
  k: std.splitLimitR('a,b,c', ',', 1),
  l: std.stripChars('xxhixx', 'x'),
  m: std.sha256('abc') + std.sha1('abc') + std.sha512('abc'),
  n: std.decodeUTF8([104, 105]),
  o: std.manifestTomlEx({ a: 1 }, '  '),
  p: std.parseYaml('a: 1'),
  q: std.xmlEscape('<a>'),
  r: std.reverse([1, 2, 3]),
  s: std.member('abc', 'b'),
  t: std.clamp(15, 0, 10),
  u: std.deepJoin(['a', ['b']]),
  v: std.manifestPython({ a: [1, true, null] }),
  w: std.mod(7, 3),
  x: std.round(2.5) + std.floor(2.5) + std.ceil(2.5),
  y: std.exponent(8) + std.mantissa(8),
};
local more_comprehensions = {
  withLocal: { local y = x * 2, ['k' + y]: y for x in [1, 2, 3] },
  filtered: { [k]: 1 for k in ['a', 'b', 'c'] if k != 'b' },
  doubleLoop: [[x, y] for x in [1, 2, 3] if x > 1 for y in [x, x + 1] if y != 3],
  empty: [x for x in []],
};
local super_forms = { a: 1, b: 2 } + { c: super.a, d: super['b'], e: 'a' in super };
local self_forms = { a: 1, b: self.a, c: self['a'], d: $.a };
local trailing_commas = [1, 2, 3,];
local trailing_obj = { a: 1, b: 2, };
local trailing_params(a, b,) = a + b;
local comment_forms = [
  1, # hash comment after a value
  2, // line comment after a value
  3, /* block comment */ 4,
];

// ── Top-level arguments and the output ──
function(environment='staging', region='eu-west-1')
{
  ['%s-%s' % [name, env]]: service(name, if env == 'prod' then 4 else 1, env)
  for name in ['api', 'worker']
  for env in ['staging', 'prod']
} + {
  metadata:: { region: region },
  summary: {
    fib10: fib(10),
    applied: apply(anon, 3),
    mixed: mixed(1, 2, d=10),
    ops: ops,
    strings: strings,
    comprehensions: comprehensions,
    object: object,
    selfRef: self_ref,
    stdlib: stdlib,
    banner: raw_text,
    password: 'example-not-a-real-key',
  },
}
