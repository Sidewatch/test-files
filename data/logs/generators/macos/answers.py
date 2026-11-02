"""Turns run.sh's captures into the three macOS fixtures and their answers.

    python3 -I answers.py <run-folder> <out>      writes <out>/show-syslog.log, show-default.log, stream-default.log
                                                  and their .expected.json

Each text capture's answers come from the ndjson capture of the same messages by the same tool: one entry per
message, in order, as many lines as the message has, after the capture's header lines (which belong to no
entry). The component is the process name. The syslog style prints no level, so its answers have none.
"""

import json
import os
import sys

RUN, OUT = sys.argv[1], sys.argv[2]
LEVELS = {"Default": "info", "Info": "info", "Debug": "debug", "Error": "error", "Fault": "fatal"}
PREDICATE = "--predicate 'subsystem == \"com.example.logfixture\" AND processID == <pid>'"


def build(capture, ndjson, name, source, with_levels=True):
    with open(os.path.join(RUN, capture)) as f:
        text = f.read()
    with open(os.path.join(RUN, ndjson)) as f:
        messages = [row for row in (json.loads(line) for line in f if line.startswith("{")) if "messageType" in row]
    lines = text.split("\n")
    if lines[-1] == "":
        lines.pop()
    first = messages[0]["timestamp"][:19]  # "2026-11-02 08:56:47", how both the capture and ndjson start a line
    line = next(i for i, text_line in enumerate(lines) if text_line.startswith(first)) + 1
    entries = []
    for message in messages:
        count = message["eventMessage"].count("\n") + 1
        timestamp = message["timestamp"]  # 2026-11-02 08:56:47.340674+0000
        assert timestamp.endswith("+0000"), "run with TZ=UTC: " + timestamp
        entries.append({"line": line, "lines": count,
                        "level": LEVELS[message["messageType"]] if with_levels else None,
                        "time": timestamp[:10] + "T" + timestamp[11:23] + "Z", "zoned": True,
                        "component": os.path.basename(message["processImagePath"])})
        line += count
    assert line - 1 == len(lines), "%s: the messages do not cover the capture (%d of %d lines)" % (name, line - 1, len(lines))
    with open(os.path.join(OUT, name + ".log"), "w") as f:
        f.write(text)
    with open(os.path.join(OUT, name + ".expected.json"), "w") as f:
        json.dump({"source": source, "referenceDate": "2026-10-01", "entries": entries}, f, indent=2)
    print("macos/%s.log: %d entries" % (name, len(entries)))


VERSION = os.popen("sw_vers -productVersion").read().strip()
build("show-syslog.txt", "show.ndjson", "show-syslog",
      "macOS " + VERSION + " /usr/bin/log show --timezone UTC --info --debug " + PREDICATE + " --style syslog, messages "
      "written by a tiny os.Logger program (subsystem com.example.logfixture); expected from log show --style ndjson of "
      "the same query, except the level: the syslog style prints none. Debug messages are not persisted, so log show "
      "has none", with_levels=False)
build("show-default.txt", "show.ndjson", "show-default",
      "macOS " + VERSION + " /usr/bin/log show --timezone UTC --info --debug " + PREDICATE + " (default style), same "
      "messages; expected from log show --style ndjson of the same query")
build("stream-default.txt", "stream.ndjson", "stream-default",
      "macOS " + VERSION + " TZ=UTC /usr/bin/log stream --level debug --predicate 'subsystem == \"com.example.logfixture\"' "
      "(default style), captured live during the same run, so Debug messages are present; expected from a parallel log "
      "stream --style ndjson")
