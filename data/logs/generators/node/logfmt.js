// logfmt lines written by Heroku's logfmt package, with the answers taken from the object each line was made of.
//
//   node logfmt.js <out>      writes <out>/logfmt.log and logfmt.expected.json
//
// Keys time, level, msg and component, plus request fields on some lines. A seeded clock from
// 2026-10-01T00:00:00Z, so the output is the same on every run. Some lines leave out component, so their
// answer has none.

const fs = require('fs');
const path = require('path');
const logfmt = require('logfmt');

const OUT = process.argv[2];

let seed = 21;
const random = (n) => { seed = (seed * 1103515245 + 12345) % 2147483648; return seed % n; };
let clock = Date.UTC(2026, 9, 1, 0, 0, 0, 0);
const iso = (ms) => new Date(ms).toISOString();

const LEVELS = { trace: 'trace', debug: 'debug', info: 'info', warn: 'warning', error: 'error', fatal: 'fatal' };
const COMPONENTS = ['api', 'worker', 'scheduler', 'db'];
const LEVEL_CYCLE = ['info', 'debug', 'info', 'warn', 'error', 'info', 'trace', 'fatal', 'info', 'debug'];
const MESSAGES = ['request handled', 'cache miss', 'job enqueued', 'slow query', 'upstream unavailable',
  'user signed in', 'tick', 'config invalid', 'shutdown complete', 'retrying'];

const lines = [];
const entries = [];
for (let i = 0; i < 90; i++) {
  clock += 1 + random(3000);
  const level = LEVEL_CYCLE[i % LEVEL_CYCLE.length];
  const fields = { time: iso(clock), level, msg: MESSAGES[i % MESSAGES.length] };
  const component = i % 9 === 4 ? null : COMPONENTS[i % COMPONENTS.length];
  if (component) fields.component = component;
  if (i % 3 === 0) {
    Object.assign(fields, { method: 'GET', path: '/api/orders/' + (1000 + i), status: level === 'error' ? 502 : 200,
      duration: (i * 7 % 900) + 'ms' });
  }
  if (i % 4 === 1) fields.user = 'user-' + (1000 + i);
  if (i % 5 === 2) fields.err = 'dial tcp 198.51.100.20:5432: connect: connection refused';
  if (i % 7 === 3) fields.query = 'SELECT id, total FROM orders WHERE status = \'open\'';
  lines.push(logfmt.stringify(fields));
  entries.push({ line: i + 1, lines: 1, level: LEVELS[level], time: iso(clock), zoned: true, component });
}

fs.writeFileSync(path.join(OUT, 'logfmt.log'), lines.join('\n') + '\n');
fs.writeFileSync(path.join(OUT, 'logfmt.expected.json'), JSON.stringify({
  source: `logfmt ${require('logfmt/package.json').version} (Heroku's npm package) logfmt.stringify() on Node ` +
    `${process.version}; keys time, level, msg, component; script logfmt.js`,
  referenceDate: '2026-10-01',
  entries,
}, null, 2) + '\n');
