"""structlog writing JSON lines, with the answers taken from each event dict on its way to the renderer.

    python -I structlog_json.py <out>      writes <out>/structlog.log and structlog.expected.json

The chain is add_log_level, an ISO UTC TimeStamper, format_exc_info and JSONRenderer. The clock is real, so
the times change on every run; a processor placed just before the renderer reads the timestamp the line gets.
"""

import json
import sys
import time

import structlog

OUT = sys.argv[1]
LEVELS = {"debug": "debug", "info": "info", "warning": "warning", "error": "error", "critical": "fatal",
          "exception": "error"}
entries = []


def record_answer(logger, method, event):
    """A processor: notes the answer for this event and passes it on unchanged. One event is one line."""
    timestamp = event["timestamp"]  # 2026-11-02T08:50:00.123456Z, cut to milliseconds below
    entries.append({"line": len(entries) + 1, "lines": 1, "level": LEVELS[event["level"]],
                    "time": timestamp[:23] + "Z", "zoned": True, "component": event.get("logger")})
    return event


log_file = open(OUT + "/structlog.log", "w")
structlog.configure(
    processors=[structlog.contextvars.merge_contextvars, structlog.processors.add_log_level,
                structlog.processors.StackInfoRenderer(), structlog.dev.set_exc_info,
                structlog.processors.TimeStamper(fmt="iso", utc=True), structlog.processors.format_exc_info,
                record_answer, structlog.processors.JSONRenderer()],
    wrapper_class=structlog.make_filtering_bound_logger(0),
    logger_factory=structlog.WriteLoggerFactory(file=log_file),
    cache_logger_on_first_use=False)

LOGGER_NAMES = ["billing", "auth", "search", None]  # None: an event with no logger key
for i in range(60):
    name = LOGGER_NAMES[i % 4]
    log = structlog.get_logger().bind(**({"logger": name} if name else {}), request_id="req-%04d" % (3000 + i))
    kind = i % 8
    if kind == 0:
        log.info("order.created", order_id=7700 + i, total_cents=1999 + i)
    elif kind == 1:
        log.debug("cache.lookup", key="user:%d" % (1000 + i), hit=bool(i % 3))
    elif kind == 2:
        log.warning("rate.limited", user="user-%d" % (1000 + i), retry_after=30)
    elif kind == 3:
        log.error("upstream.failed", host="api.example.com", status=502)
    elif kind == 4:
        log.critical("db.unreachable", host="198.51.100.20", port=5432)
    elif kind == 5:
        try:
            1 / 0
        except ZeroDivisionError:
            log.exception("report.failed", report="monthly")
    elif kind == 6:
        log.info("user.login", user="user-%d" % (1000 + i), ip="203.0.113.%d" % (i + 1))
    else:
        log.info("job.done", job="digest", duration_ms=120 + i)
    log_file.flush()
    time.sleep(0.013)
log_file.close()

with open(OUT + "/structlog.expected.json", "w") as f:
    json.dump({"source": "structlog %s on Python %d.%d.%d, processors add_log_level, TimeStamper(fmt='iso', utc=True), "
                         "format_exc_info, JSONRenderer; WriteLoggerFactory; script structlog_json.py"
                         % ((structlog.__version__,) + sys.version_info[:3]),
               "referenceDate": "2026-10-01", "entries": entries}, f, indent=2)
