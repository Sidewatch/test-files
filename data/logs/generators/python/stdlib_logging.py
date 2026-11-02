"""Python's own logging module writing four fixtures, with the answers taken from the records it emitted.

    python -I stdlib_logging.py <out>

    <out>/python/basicconfig.log   logging.BASIC_FORMAT, no time
    <out>/python/asctime.log       "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    <out>/plain/plain.log          ISO UTC time, padded level, [component], a request id
    <out>/plain/mixed.log          text lines and JSON lines from different loggers in one file

A record factory moves a seeded clock on for every record, so the times are the same on every run. A second
handler after the file handler counts the lines each record added, which is how continuation lines
(tracebacks, multi-line messages) are counted without parsing anything.
"""

import json
import logging
import os
import random
import sys
import time

OUT = sys.argv[1]
LEVELS = {logging.DEBUG: "debug", logging.INFO: "info", logging.WARNING: "warning",
          logging.ERROR: "error", logging.CRITICAL: "fatal"}
START_MS = 1790812800000  # 2026-10-01T00:00:00Z

rng = random.Random(7)
clock_ms = START_MS
make_record = logging.getLogRecordFactory()


def simulated_record(*args, **kwargs):
    """Every record is stamped 1 ms to 2.5 s after the one before."""
    global clock_ms
    record = make_record(*args, **kwargs)
    clock_ms += rng.randint(1, 2500)
    record.created = clock_ms / 1000
    record.msecs = clock_ms % 1000
    record.clock_ms = clock_ms
    return record


logging.setLogRecordFactory(simulated_record)


def iso(ms):
    return time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(ms // 1000)) + ".%03dZ" % (ms % 1000)


class AnswerRecorder(logging.Handler):
    """Runs after the file handler and turns each record into an answer, counting the lines it added.

    `timed` is None (the format has no time), "local" (a time with no zone) or "zoned".
    """

    def __init__(self, path, timed):
        super().__init__(logging.DEBUG)
        self.path, self.timed = path, timed
        self.offset, self.line, self.entries = 0, 1, []

    def emit(self, record):
        with open(self.path, "rb") as f:
            f.seek(self.offset)
            written = f.read()
        lines = written.count(b"\n")
        self.entries.append({"line": self.line, "lines": lines, "level": LEVELS[record.levelno],
                             "time": iso(record.clock_ms) if self.timed else None,
                             "zoned": self.timed == "zoned", "component": record.name})
        self.line += lines
        self.offset += len(written)


def start(folder, name, formatter, timed):
    """Points the root logger at a fresh <folder>/<name>.log with `formatter`, and an AnswerRecorder after it."""
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, name + ".log")
    open(path, "w").close()
    root = logging.getLogger()
    for handler in list(root.handlers):
        root.removeHandler(handler)
    root.setLevel(logging.DEBUG)
    file_handler = logging.FileHandler(path)
    file_handler.setFormatter(formatter)
    root.addHandler(file_handler)
    recorder = AnswerRecorder(path, timed)
    root.addHandler(recorder)
    return file_handler, recorder


def finish(folder, name, source, file_handler, recorder):
    file_handler.close()
    with open(os.path.join(folder, name + ".expected.json"), "w") as f:
        json.dump({"source": source, "referenceDate": "2026-10-01", "entries": recorder.entries}, f, indent=2)
        f.write("\n")


def utc_formatter(fmt, datefmt):
    formatter = logging.Formatter(fmt, datefmt)
    formatter.converter = time.gmtime
    return formatter


MESSAGES = [
    (logging.INFO, "service started on port %d", (8080,)),
    (logging.DEBUG, "loaded %d settings from %s", (31, "config/app.ini")),
    (logging.INFO, "GET /api/orders/%d 200 %dms", (1042, 18)),
    (logging.WARNING, "slow query (%dms): %s", (912, "SELECT * FROM orders WHERE status = 'open'")),
    (logging.ERROR, "payment provider returned %d for order %d", (502, 7731)),
    (logging.INFO, "user-%d signed in from %s", (1042, "203.0.113.17")),
    (logging.DEBUG, "cache hit ratio %.2f", (0.87,)),
    (logging.CRITICAL, "disk almost full: %d%% used on /var/lib/app", (97,)),
    (logging.WARNING, "retrying job %d (attempt %d of %d)", (5521, 2, 5)),
    (logging.INFO, "multi-line note:\n  first detail\n  second detail", ()),
]
LOGGER_NAMES = ["app", "app.db", "app.http", "billing.worker", "root"]


def parse_quantity():
    return int("forty-two")


def load_order():
    try:
        {}["missing"]
    except KeyError as error:
        raise RuntimeError("could not load order 7731") from error


def log_messages(count, names=LOGGER_NAMES):
    """Logs `count` records across `names`; some are logger.exception calls with a plain or chained traceback."""
    for i in range(count):
        level, message, args = MESSAGES[i % len(MESSAGES)]
        name = names[(i * 3) % len(names)]
        logger = logging.getLogger() if name == "root" else logging.getLogger(name)
        if i % 17 == 11:
            try:
                parse_quantity()
            except ValueError:
                logger.exception("could not parse quantity for line item %d", i)
        elif i % 23 == 19:
            try:
                load_order()
            except RuntimeError:
                logger.exception("job failed")
        else:
            logger.log(level, message, *args)


PYTHON = "Python %d.%d.%d logging" % sys.version_info[:3]
SCRIPT = "; script stdlib_logging.py"
python_dir = os.path.join(OUT, "python")
plain_dir = os.path.join(OUT, "plain")

# basicConfig's default format, %(levelname)s:%(name)s:%(message)s: no time at all.
handler, recorder = start(python_dir, "basicconfig", logging.Formatter(logging.BASIC_FORMAT), None)
log_messages(70)
finish(python_dir, "basicconfig", PYTHON + ", logging.BASIC_FORMAT ('%(levelname)s:%(name)s:%(message)s', the "
       "basicConfig default)" + SCRIPT, handler, recorder)

# The format from the logging HOWTO, default datefmt: local time (TZ=UTC here) with no zone written.
handler, recorder = start(python_dir, "asctime",
                          logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s"), "local")
log_messages(90)
finish(python_dir, "asctime", PYTHON + ", format '%(asctime)s - %(name)s - %(levelname)s - %(message)s', default "
       "datefmt, TZ=UTC" + SCRIPT, handler, recorder)

# plain.log: the shape many hand-rolled formats share. WARN and FATAL are the names it prints.
logging.addLevelName(logging.WARNING, "WARN")
logging.addLevelName(logging.CRITICAL, "FATAL")


class RequestIds(logging.Filter):
    """Gives every record a made-up request id: r00fa7, r00fae and on."""
    next_id = 4000

    def filter(self, record):
        RequestIds.next_id += 7
        record.req = "r%05x" % RequestIds.next_id
        return True


handler, recorder = start(plain_dir, "plain", utc_formatter(
    "%(asctime)s.%(msecs)03dZ %(levelname)-5s [%(name)s] req=%(req)s %(message)s", "%Y-%m-%dT%H:%M:%S"), "zoned")
handler.addFilter(RequestIds())
log_messages(80, ["auth", "db", "http", "billing", "scheduler"])
finish(plain_dir, "plain", PYTHON + ", format '%(asctime)s.%(msecs)03dZ %(levelname)-5s [%(name)s] req=%(req)s "
       "%(message)s', gmtime converter, WARNING renamed WARN and CRITICAL renamed FATAL with addLevelName" + SCRIPT,
       handler, recorder)


# mixed.log: the gateway and search loggers write JSON lines, the rest text lines, into one file.
class JsonLines(logging.Formatter):
    def format(self, record):
        level = {"WARN": "warn", "FATAL": "fatal"}.get(record.levelname, record.levelname.lower())
        fields = {"ts": iso(record.clock_ms), "level": level, "service": record.name, "msg": record.getMessage()}
        if record.exc_info:
            fields["err"] = self.formatException(record.exc_info)
        return json.dumps(fields)


class ByLogger(logging.Formatter):
    json_lines = JsonLines()
    text = utc_formatter("%(asctime)s.%(msecs)03dZ %(levelname)-5s [%(name)s] %(message)s", "%Y-%m-%dT%H:%M:%S")

    def format(self, record):
        return (self.json_lines if record.name in ("gateway", "search") else self.text).format(record)


handler, recorder = start(plain_dir, "mixed", ByLogger(), "zoned")
log_messages(90, ["auth", "gateway", "db", "search", "http"])
finish(plain_dir, "mixed", PYTHON + "; text lines use '%(asctime)s.%(msecs)03dZ %(levelname)-5s [%(name)s] "
       "%(message)s', the gateway and search loggers use a JSON formatter ({ts, level, service, msg, err})" + SCRIPT,
       handler, recorder)
