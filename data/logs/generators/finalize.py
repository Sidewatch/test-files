"""Scrubs, checks and copies the generated fixtures into the corpus.

    python3 finalize.py <scratch-folder> <destination>

The generators ran from copies inside the scratch folder, so tracebacks and stack traces name paths there.
Each `<scratch>/<toolchain>/` becomes `/srv/app/`, which keeps every line count the same. Answer files are
rewritten in one style (two-space JSON, trailing newline) whatever language wrote them. Then every answer
is checked against its log, and nothing is copied unless every check passes.
"""

import datetime as dt
import getpass
import json
import os
import re
import socket
import sys
from zoneinfo import ZoneInfo

WORK, DEST = sys.argv[1], sys.argv[2]
OUT = os.path.join(WORK, "out")

LEVELS = {"trace", "debug", "info", "notice", "warning", "error", "fatal", None}
TIME = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$")
ENTRY_KEYS = {"line", "lines", "level", "time", "zoned", "component"}
# Logs whose every line is one JSON object.
JSON_LINES = {"node/pino.log", "node/bunyan.log", "node/winston.log", "python/structlog.log",
              "docker/json-file.log", "go/slog-json.log"}
# What must never reach a public corpus: the scratch folder, any home folder, this machine's name, the user.
FORBIDDEN = [WORK, os.path.expanduser("~"), "/Users/", "/private/var/", "/private/tmp/", "/var/folders/",
             socket.gethostname().split(".")[0], getpass.getuser()]


def machine_zone():
    """This machine's own time zone, as its name and UTC offsets, unless it is UTC. Read from /etc/localtime,
    since the generators run with TZ=UTC."""
    name = os.path.realpath("/etc/localtime").partition("/zoneinfo/")[2]
    if not name:
        return []
    offset = dt.datetime.now(ZoneInfo(name)).strftime("%z")
    if offset == "+0000":
        return []
    return [name.split("/")[-1].replace("_", " "), offset, offset[:3] + ":" + offset[3:]]


FORBIDDEN += machine_zone()
# Every IPv4 address must be a documentation one (RFC 5737), or 0.0.0.0 as a listen address; every IPv6 one
# 2001:db8:: (RFC 3849) or [::] as a listen address.
IPV4 = re.compile(r"(?<![\d.])(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?![\d.])")
DOC_V4 = ("192.0.2.", "198.51.100.", "203.0.113.")
LOCAL_V6 = re.compile(r"(?i)\b(fe80|fd[0-9a-f]{2}|fc[0-9a-f]{2}):[0-9a-f:]*|(?<![\w:])::1(?![\w:])")


def scrub(rel, text):
    text = re.sub(re.escape(WORK) + r"/[a-z]+/", "/srv/app/", text)
    for bad in FORBIDDEN:
        if bad and bad.lower() in text.lower():
            raise SystemExit("%s: %r is in the output" % (rel, bad))
    for match in IPV4.finditer(text):
        address = match.group(0)
        if address != "0.0.0.0" and not address.startswith(DOC_V4):
            raise SystemExit("%s: address %s is not a documentation address" % (rel, address))
    match = LOCAL_V6.search(text)
    if match:
        raise SystemExit("%s: address %s is not a documentation address" % (rel, match.group(0)))
    return text


def check(rel, log, answers):
    assert set(answers) == {"source", "referenceDate", "entries"}, rel
    line_count = log.count("\n") + (0 if log.endswith("\n") else 1)
    previous_end = 0
    for entry in answers["entries"]:
        assert set(entry) == ENTRY_KEYS, (rel, entry)
        assert entry["line"] > previous_end and entry["lines"] >= 1, (rel, entry)
        previous_end = entry["line"] + entry["lines"] - 1
        assert previous_end <= line_count, (rel, entry, line_count)
        assert entry["level"] in LEVELS, (rel, entry)
        assert entry["time"] is None or TIME.match(entry["time"]), (rel, entry)
        assert isinstance(entry["zoned"], bool), (rel, entry)
        assert entry["component"] is None or isinstance(entry["component"], str), (rel, entry)
    if rel in JSON_LINES:
        for row in log.splitlines():
            json.loads(row)
    return line_count


results = {}
for fmt in sorted(os.listdir(OUT)):
    for name in sorted(os.listdir(os.path.join(OUT, fmt))):
        with open(os.path.join(OUT, fmt, name), encoding="utf-8", newline="") as f:
            results[fmt + "/" + name] = scrub(fmt + "/" + name, f.read())

for rel in sorted(results):
    if not rel.endswith(".expected.json"):
        continue
    log_rel = rel.replace(".expected.json", ".log")
    assert log_rel in results, "no log for " + rel
    answers = json.loads(results[rel])
    results[rel] = json.dumps(answers, indent=2, ensure_ascii=False) + "\n"
    lines = check(log_rel, results[log_rel], answers)
    print("%-34s %4d entries  %4d lines" % (log_rel, len(answers["entries"]), lines))

logs = [rel for rel in results if rel.endswith(".log")]
assert all(rel.replace(".log", ".expected.json") in results for rel in logs), "a log has no answers"

for rel, text in results.items():
    path = os.path.join(DEST, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text)
print("%d fixtures written to %s" % (len(logs), DEST))
