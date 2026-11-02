// pino, bunyan and winston writing their default JSON lines, with the answers taken from each call.
//
//   node json_loggers.js <out>      writes <out>/pino.log, bunyan.log, winston.log and their .expected.json
//
// Date is replaced before the libraries load, so every call sees a seeded clock and the output is the same on
// every run (apart from the process ID pino and bunyan write). After each call the new bytes in the file are
// counted, which is how a multi-line value would be counted; each library writes one line per call.

const fs = require('fs');
const path = require('path');

const OUT = process.argv[2];

// The seeded clock: from 2026-10-01T00:00:00Z, 1 ms to 2.4 s per call.
const RealDate = Date;
let clock = RealDate.UTC(2026, 9, 1, 0, 0, 0, 0);
let seed = 11;
const random = (n) => { seed = (seed * 1103515245 + 12345) % 2147483648; return seed % n; };
const tick = () => { clock += 1 + random(2400); };
global.Date = class extends RealDate {
  constructor(...args) { if (args.length) super(...args); else super(clock); }
  static now() { return clock; }
};
const iso = (ms) => new RealDate(ms).toISOString();

const pino = require('pino');
const bunyan = require('bunyan');
const winston = require('winston');
const { Writable } = require('stream');

/** Answers for one file: `note` counts the lines written since the last call. */
function answers(file) {
  fs.writeFileSync(file, '');
  let offset = 0;
  let line = 1;
  const entries = [];
  return {
    entries,
    note(level, component) {
      const written = fs.readFileSync(file).subarray(offset);
      const lines = written.toString().split('\n').length - 1;
      entries.push({ line, lines, level, time: iso(clock), zoned: true, component });
      line += lines;
      offset += written.length;
    },
  };
}

function save(name, source, result) {
  fs.writeFileSync(path.join(OUT, name + '.expected.json'),
    JSON.stringify({ source, referenceDate: '2026-10-01', entries: result.entries }, null, 2) + '\n');
}

const version = (pkg) => require(pkg + '/package.json').version;
const LEVELS = { trace: 'trace', debug: 'debug', info: 'info', warn: 'warning', error: 'error', fatal: 'fatal' };
// [level, message, fields]; null fields means "log an Error instead".
const SCRIPT = [
  ['info', 'server listening', { port: 3000 }],
  ['debug', 'loaded routes', { count: 42 }],
  ['trace', 'tick', { queue: 0 }],
  ['info', 'request completed', { method: 'GET', url: '/api/orders/1042', statusCode: 200, responseTime: 14 }],
  ['warn', 'slow query', { ms: 812, sql: 'SELECT * FROM orders WHERE user_id = $1' }],
  ['error', 'upstream failed', { host: 'api.example.com', status: 502 }],
  ['info', 'user signed in', { user: 'user-1042', ip: '203.0.113.17' }],
  ['fatal', 'database unreachable', { host: '198.51.100.20', port: 5432 }],
  ['error', 'ERR', null],
  ['info', 'cache warmed', { keys: 1200 }],
];
function notFound() {
  const error = new Error('order 7731 not found');
  error.code = 'E_NOT_FOUND';
  return error;
}

// pino: numeric levels and epoch-millisecond times. `base` is set only so the machine's hostname is not
// written; `name` comes before `component` in the reader's lookup, so the db child still answers "api".
{
  const file = path.join(OUT, 'pino.log');
  const result = answers(file);
  const destination = pino.destination({ dest: file, sync: true });
  const api = pino({ name: 'api', level: 'trace', base: { pid: process.pid, hostname: 'web-01' } }, destination);
  const db = api.child({ component: 'db' });
  const worker = pino({ level: 'trace', base: { pid: process.pid, hostname: 'web-01', module: 'worker' } }, destination);
  for (let i = 0; i < 90; i++) {
    tick();
    const [level, message, fields] = SCRIPT[i % SCRIPT.length];
    const logger = i % 5 === 3 ? worker : i % 3 === 1 ? db : api;
    if (fields === null) logger.error(notFound(), 'request failed'); else logger[level](fields, message);
    result.note(LEVELS[level], logger === worker ? 'worker' : 'api');
  }
  save('pino', `pino ${version('pino')} on Node ${process.version}, default JSON; base set to {pid, hostname: "web-01"} ` +
    '(and module: "worker" for the second logger) so the real hostname is not written; script json_loggers.js', result);
}

// bunyan: its default JSON, hostname given as an option for the same reason.
{
  const file = path.join(OUT, 'bunyan.log');
  const result = answers(file);
  const stream = { write(text) { fs.appendFileSync(file, text); } };
  const billing = bunyan.createLogger({ name: 'billing', hostname: 'web-01', level: 'trace', stream });
  const invoice = billing.child({ component: 'invoice' });
  for (let i = 0; i < 70; i++) {
    tick();
    const [level, message, fields] = SCRIPT[(i * 3) % SCRIPT.length];
    const logger = i % 4 === 2 ? invoice : billing;
    if (fields === null) logger.error({ err: notFound() }, 'invoice run failed'); else logger[level](fields, message);
    result.note(LEVELS[level], 'billing');
  }
  save('bunyan', `bunyan ${version('bunyan')} on Node ${process.version}, default JSON, hostname option set to "web-01"; ` +
    'script json_loggers.js', result);
}

// winston as its README sets it up: timestamp() + errors({stack: true}) + json(), a defaultMeta service.
// winston's own levels http, verbose and silly answer info, trace and trace.
{
  const file = path.join(OUT, 'winston.log');
  const result = answers(file);
  const sink = new Writable({ write(chunk, encoding, done) { fs.appendFileSync(file, chunk); done(); } });
  const logger = winston.createLogger({
    level: 'silly',
    format: winston.format.combine(winston.format.timestamp(), winston.format.errors({ stack: true }), winston.format.json()),
    defaultMeta: { service: 'user-service' },
    transports: [new winston.transports.Stream({ stream: sink })],
  });
  const WINSTON_LEVELS = { error: 'error', warn: 'warning', info: 'info', http: 'info', verbose: 'trace', debug: 'debug', silly: 'trace' };
  const levels = ['info', 'http', 'debug', 'warn', 'error', 'verbose', 'info', 'silly', 'error', 'info'];
  for (let i = 0; i < 80; i++) {
    tick();
    const level = levels[i % levels.length];
    const [, message, fields] = SCRIPT[i % SCRIPT.length];
    const service = i % 6 === 5 ? 'mailer' : 'user-service';
    if (fields === null) logger.error(notFound());
    else if (service === 'mailer') logger.log(level, message, { ...fields, service });
    else logger.log(level, message, fields);
    result.note(WINSTON_LEVELS[level], service);
  }
  save('winston', `winston ${version('winston')} on Node ${process.version}, format combine(timestamp(), ` +
    'errors({stack: true}), json()), defaultMeta {service: "user-service"}; levels http -> info, verbose and silly -> trace; ' +
    'script json_loggers.js', result);
}
