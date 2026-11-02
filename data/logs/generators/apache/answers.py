"""Turns run.sh's httpd logs into the two Apache fixtures and their answers.

    python3 -I answers.py <run-folder> <out>      writes <out>/access.log, error.log and their .expected.json

access.log's answers come from the second CustomLog httpd wrote for the same requests ("%{msec}t %>s"):
the time to the millisecond and the status, so they never depend on reading the combined line. The level
follows the status: 5xx error, 4xx warning, else info.

httpd writes only one error log, so error.log's answers come from a strict regex of the documented default
ErrorLogFormat (https://httpd.apache.org/docs/2.4/mod/core.html#errorlogformat). Every line must match it, so
it is the one answer file here that depends on parsing, and the regex is as narrow as the format.

Both files are scrubbed first: the run folder's paths become /srv/www, /srv/cgi-bin, /etc/httpd and /run/httpd,
and the loopback clients become documentation addresses (203.0.113.7, 2001:db8::7).
"""

import datetime as dt
import json
import re
import subprocess
import sys

RUN, OUT = sys.argv[1], sys.argv[2]
UTC = dt.timezone.utc
HTTPD = re.search(r"Apache/([\d.]+)", subprocess.run(["/usr/sbin/httpd", "-v"], capture_output=True,
                                                         text=True).stdout).group(1)


def scrub(text):
    for path, public in (("/www", "/srv/www"), ("/cgi-bin", "/srv/cgi-bin"), ("/httpd.conf", "/etc/httpd/httpd.conf"),
                         ("/logs/httpd.pid", "/run/httpd/httpd.pid")):
        text = text.replace(RUN + path, public)
    text = text.replace("http://127.0.0.1:18080/", "http://web-01.example.com:18080/")
    text = text.replace("127.0.0.1", "203.0.113.7").replace("[::1]", "[2001:db8::7]")
    text = re.sub(r"^::1 ", "2001:db8::7 ", text, flags=re.M)
    text = text.replace("client ::1:", "client 2001:db8::7:")
    if RUN in text or "/Users/" in text:
        raise SystemExit("a path from the run is left in an Apache log")
    return text


def read(name):
    with open(RUN + "/logs/" + name) as f:
        return f.read()


def save(name, text, source, entries):
    with open(OUT + "/" + name + ".log", "w") as f:
        f.write(text)
    with open(OUT + "/" + name + ".expected.json", "w") as f:
        json.dump({"source": source, "referenceDate": "2026-10-01", "entries": entries}, f, indent=2)


# access.log
access = scrub(read("access_log"))
entries = []
for i, row in enumerate(read("answers").splitlines()):
    msec, status = row.split()
    when = dt.datetime.fromtimestamp(int(msec) // 1000, UTC)  # %t in the combined line has whole seconds
    status = int(status)
    entries.append({"line": i + 1, "lines": 1, "level": "error" if status >= 500 else "warning" if status >= 400 else "info",
                    "time": when.strftime("%Y-%m-%dT%H:%M:%S.000Z"), "zoned": True, "component": None})
assert len(entries) == len(access.splitlines()), "the two access logs disagree"
save("access", access, "Apache httpd " + HTTPD + " (macOS /usr/sbin/httpd, prefork, own config on the loopback interface, port 18080) "
     "CustomLog combined, requests sent with curl; the expected file comes from a second CustomLog \"%{msec}t %>s\" that "
     "httpd wrote for the same requests", entries)

# error.log: "[Www Mmm dd hh:mm:ss.uuuuuu yyyy] [module:level] ...", local time (UTC here) with no zone.
ERROR_LEVELS = {"emerg": "fatal", "alert": "fatal", "crit": "fatal", "error": "error", "warn": "warning",
                "notice": "notice", "info": "info", "debug": "debug"}  # trace1..trace8 answer trace
HEADER = re.compile(r"^\[\w{3} (\w{3}) (\d{2}) (\d{2}:\d{2}:\d{2})\.(\d{6}) (\d{4})\] \[([a-z_0-9]+):([a-z0-9]+)\] ")
errors = scrub(read("error_log"))
entries = []
for i, line in enumerate(errors.splitlines()):
    match = HEADER.match(line)
    assert match, "an error log line does not match the documented format: " + line
    month, day, clock, micros, year, module, level = match.groups()
    when = dt.datetime.strptime("%s %s %s %s" % (year, month, day, clock), "%Y %b %d %H:%M:%S")
    entries.append({"line": i + 1, "lines": 1, "level": "trace" if level.startswith("trace") else ERROR_LEVELS[level],
                    "time": when.strftime("%Y-%m-%dT%H:%M:%S.") + micros[:3] + "Z", "zoned": False, "component": module})
save("error", errors, "Apache httpd " + HTTPD + " ErrorLog in the built-in default format, same run as access.log (LogLevel info, "
     "authz_core:debug inside /private/); httpd cannot write a second error log, so this expected file was made by a strict "
     "regex of that documented format (https://httpd.apache.org/docs/2.4/mod/core.html#errorlogformat) that every line had "
     "to match", entries)
print("apache: %d access, %d error entries" % (len(access.splitlines()), len(entries)))
