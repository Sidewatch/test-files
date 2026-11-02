"""Log fixtures for the formats whose tools are not installed here, written to each format's documentation.

    python3 -I documented.py <out>      writes <out>/<format>/<name>.log and <name>.expected.json

Every fixture cites the page it follows in its answer file's `source`. A line and its answer are built from
the same values (the time, level and component picked for it), so the answers never come from parsing the
line. Each fixture has its own seeded clock, so the output is the same on every run.
"""

import datetime as dt
import json
import os
import random
import re
import sys

OUT = sys.argv[1]
UTC = dt.timezone.utc
REFERENCE_DATE = "2026-10-01"  # the date (and year) a reader assumes for formats that leave it out


class Fixture:
    """One log file and its answers, built line by line."""

    def __init__(self, fmt, name, source):
        self.fmt, self.name, self.source = fmt, name, source
        self.lines, self.entries = [], []

    def raw(self, text):
        """Lines in the file that belong to no entry: dividers, banners, blank separators."""
        self.lines.extend(text.split("\n"))

    def add(self, text, level, t, zoned, component):
        """One entry; `text` may hold continuation lines after the first."""
        parts = text.split("\n")
        self.entries.append({"line": len(self.lines) + 1, "lines": len(parts), "level": level,
                             "time": stamp(t), "zoned": zoned, "component": component})
        self.lines.extend(parts)

    def save(self):
        folder = os.path.join(OUT, self.fmt)
        os.makedirs(folder, exist_ok=True)
        with open(os.path.join(folder, self.name + ".log"), "w", newline="") as f:
            f.write("\n".join(self.lines) + "\n")
        with open(os.path.join(folder, self.name + ".expected.json"), "w") as f:
            json.dump({"source": self.source, "referenceDate": REFERENCE_DATE, "entries": self.entries}, f, indent=2)
            f.write("\n")
        print("%s/%s.log: %d entries" % (self.fmt, self.name, len(self.entries)))


def stamp(t):
    """An answer's time: UTC, milliseconds, truncated."""
    if t is None:
        return None
    t = t.astimezone(UTC)
    return t.strftime("%Y-%m-%dT%H:%M:%S.") + "%03dZ" % (t.microsecond // 1000)


def millis(t):
    """`.mmm`: the milliseconds most formats print."""
    return "%03d" % (t.microsecond // 1000)


class Clock:
    """A seeded clock from 2026-10-01T00:00:00Z that moves forward a random step per entry."""

    def __init__(self, seed, start=dt.datetime(2026, 10, 1, 0, 0, 0, tzinfo=UTC)):
        self.t, self.rng = start, random.Random(seed)

    def step(self, lo=1, hi=4000, us=False):
        """Moves lo to hi milliseconds on, plus up to 999 microseconds when `us` is set."""
        self.t += dt.timedelta(milliseconds=self.rng.randint(lo, hi))
        if us:
            self.t += dt.timedelta(microseconds=self.rng.randint(0, 999))
        return self.t


def wall(t, off_hours=0):
    """The time as a clock in a zone off_hours from UTC shows it."""
    return t.astimezone(dt.timezone(dt.timedelta(hours=off_hours)))


# ---------------------------------------------------------------- java
def java():
    # java.util.logging.SimpleFormatter's default format,
    # "%1$tb %1$td, %1$tY %1$tl:%1$tM:%1$tS %1$Tp %2$s%n%4$s: %5$s%6$s%n": a header line (time, source class
    # and method), then "LEVEL: message", then the throwable if there is one. A throwable ends with its own
    # line break, so the record is followed by an empty line, which belongs to no entry.
    fx = Fixture("java", "jul-simpleformatter",
            "Documentation-derived: java.util.logging.SimpleFormatter default format "
            "https://docs.oracle.com/en/java/javase/21/docs/api/java.logging/java/util/logging/SimpleFormatter.html "
            "and the throwable layout of Throwable.printStackTrace (a record with a throwable is followed by an empty line, "
            "which belongs to no entry; the line shows whole seconds, the answers keep milliseconds) "
            "https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Throwable.html#printStackTrace()")
    c = Clock(101)
    LV = {"SEVERE": "error", "WARNING": "warning", "INFO": "info", "CONFIG": "info", "FINE": "debug",
          "FINER": "debug", "FINEST": "trace"}
    rows = [
        ("com.example.orders.OrderService", "placeOrder", "INFO", "Order 7731 placed for user-1042"),
        ("com.example.orders.OrderService", "loadConfig", "CONFIG", "orders.maxItems=50"),
        ("com.example.db.ConnectionPool", "borrow", "FINE", "borrowed connection 3 of 10"),
        ("com.example.db.ConnectionPool", "evict", "FINER", "evicting idle connection 7"),
        ("com.example.http.Server", "start", "INFO", "Listening on port 8080"),
        ("com.example.http.Server", "handle", "WARNING", "Slow request GET /api/orders took 2310 ms"),
        ("com.example.cache.CacheLoader", "refresh", "FINEST", "refresh tick"),
        ("com.example.orders.OrderService", "charge", "SEVERE", "Payment failed for order 7731"),
    ]
    for i in range(48):
        cls, meth, lv, msg = rows[i % len(rows)]
        t = c.step(200, 90000)
        h = t.hour % 12 or 12
        head = "%s %02d, %d %d:%02d:%02d %s %s %s" % (t.strftime("%b"), t.day, t.year, h, t.minute, t.second,
                                                    "AM" if t.hour < 12 else "PM", cls, meth)
        body = "%s: %s" % (lv, msg)
        throwable = lv == "SEVERE" and i % 16 == 7
        if throwable:
            body += ("\njava.lang.IllegalStateException: gateway returned 502\n"
                     "\tat com.example.payments.GatewayClient.charge(GatewayClient.java:88)\n"
                     "\tat com.example.orders.OrderService.charge(OrderService.java:142)\n"
                     "\tat com.example.orders.OrderService.placeOrder(OrderService.java:61)\n"
                     "\tat java.base/java.lang.Thread.run(Thread.java:1583)\n"
                     "Caused by: java.net.SocketTimeoutException: Read timed out\n"
                     "\tat java.base/sun.nio.ch.NioSocketImpl.timedRead(NioSocketImpl.java:278)\n"
                     "\t... 4 more")
        # The answer keeps the milliseconds; the line shows whole seconds, and the reader's test allows for that.
        fx.add(head + "\n" + body, LV[lv], t, False, cls)
        if throwable:
            fx.raw("")
    fx.save()

    # logback's default configuration (BasicConfigurator), pattern
    # "%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n". Time only: the date is REFERENCE_DATE.
    fx = Fixture("java", "logback",
            "Documentation-derived: logback's default configuration (BasicConfigurator) pattern "
            "\"%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n\" "
            "https://logback.qos.ch/manual/configuration.html#automaticConf and stack trace layout "
            "https://logback.qos.ch/manual/layouts.html#ex ; time only, so the date is referenceDate")
    c = Clock(102)
    LV = {"TRACE": "trace", "DEBUG": "debug", "INFO": "info", "WARN": "warning", "ERROR": "error"}
    rows = [
        ("main", "INFO", "com.example.Application", "Starting Application v1.4.2"),
        ("main", "DEBUG", "com.example.config.AppConfig", "Loaded 31 properties from application.yml"),
        ("http-nio-8080-exec-1", "INFO", "com.example.web.OrderController", "GET /api/orders/1042 -> 200 (14 ms)"),
        ("http-nio-8080-exec-2", "WARN", "com.example.web.RateLimiter", "user-1042 exceeded 100 req/min"),
        ("scheduling-1", "TRACE", "com.example.jobs.DigestJob", "tick"),
        ("http-nio-8080-exec-3", "ERROR", "com.example.web.OrderController", "Request failed"),
        ("pool-2-thread-1", "INFO", "com.example.mail.Mailer", "Sent invoice 2026-1042 to billing@example.com"),
        ("pool-2-thread-1", "DEBUG", "com.example.db.OrderRepository", "SELECT id, total FROM orders WHERE id = ?"),
    ]
    for i in range(70):
        th, lv, lg, msg = rows[i % len(rows)]
        t = c.step(5, 3000)
        line = "%s [%s] %-5s %s - %s" % (t.strftime("%H:%M:%S.") + millis(t), th, lv, lg, msg)
        if lv == "ERROR":
            line += ("\norg.springframework.dao.DataAccessResourceFailureException: Unable to acquire JDBC Connection\n"
                     "\tat com.example.db.OrderRepository.findById(OrderRepository.java:57)\n"
                     "\tat com.example.web.OrderController.show(OrderController.java:33)\n"
                     "Caused by: java.sql.SQLTransientConnectionException: HikariPool-1 - Connection is not available, request timed out after 30000ms.\n"
                     "\tat com.zaxxer.hikari.pool.HikariPool.createTimeoutException(HikariPool.java:696)\n"
                     "\t... 12 common frames omitted")
        if i % 23 == 9:
            line += "\n  continued detail on a second line"
        fx.add(line, LV[lv], t.replace(tzinfo=UTC), False, lg)
    fx.save()

    # Spring Boot's default console format: ISO time with zone, a 5-wide level, PID, "---", the
    # application name, the thread (15 wide, cut from the left), the logger (40 wide) and ": message". An
    # exception follows an empty line, which is part of the entry because more of the entry follows it.
    fx = Fixture("java", "spring-boot",
            "Documentation-derived: Spring Boot default log format (ISO-8601 time, %5p level, PID, '---', "
            "[application name], [thread], logger, ':' message) "
            "https://docs.spring.io/spring-boot/reference/features/logging.html#features.logging.log-format")
    c = Clock(103)
    LV = {"TRACE": "trace", "DEBUG": "debug", "INFO": "info", "WARN": "warning", "ERROR": "error"}
    rows = [
        ("main", "INFO", "c.e.shop.ShopApplication", "Starting ShopApplication using Java 21.0.5 with PID 4127 (/srv/app/shop.jar started by app in /srv/app)"),
        ("main", "INFO", "o.s.b.w.embedded.tomcat.TomcatWebServer", "Tomcat initialized with port 8080 (http)"),
        ("main", "DEBUG", "c.e.shop.config.SecurityConfig", "Configured 4 security filters"),
        ("main", "WARN", "o.h.engine.jdbc.spi.SqlExceptionHelper", "SQL Warning Code: 0, SQLState: 00000"),
        ("http-nio-8080-exec-1", "INFO", "c.e.shop.web.CartController", "Cart 551 updated by user-1042"),
        ("http-nio-8080-exec-4", "ERROR", "o.a.c.c.C.[.[.[/].[dispatcherServlet]", "Servlet.service() for servlet [dispatcherServlet] threw exception"),
        ("scheduling-1", "TRACE", "c.e.shop.jobs.StockSync", "polling supplier feed"),
    ]
    for i in range(60):
        th, lv, lg, msg = rows[i % len(rows)]
        t = c.step(3, 5000)
        line = "%s %5s 4127 --- [shop] [%15s] %-40s : %s" % (stamp(t), lv, th[-15:], lg, msg)
        if lv == "ERROR":
            line += ("\n\njava.lang.NullPointerException: Cannot invoke \"com.example.shop.Cart.items()\" because \"cart\" is null\n"
                     "\tat com.example.shop.web.CartController.checkout(CartController.java:71) ~[classes/:na]\n"
                     "\tat java.base/java.lang.reflect.Method.invoke(Method.java:580) ~[na:na]")
        fx.add(line, LV[lv], t, True, lg)
    fx.save()


# ---------------------------------------------------------------- nginx
def nginx():
    # The predefined "combined" access format, $time_local in a +0200 zone; the level answers follow the status
    # (5xx error, 4xx warning, else info). Then the error log, local time with no zone.
    fx = Fixture("nginx", "access",
            "Documentation-derived: nginx predefined 'combined' log_format "
            "https://nginx.org/en/docs/http/ngx_http_log_module.html#log_format ; $time_local written in a +0200 zone")
    c = Clock(201)
    ips = ["203.0.113.7", "198.51.100.23", "192.0.2.44", "2001:db8::1f", "203.0.113.150"]
    uas = ["Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15",
           "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0", "curl/8.7.1", "-",
           "Googlebot/2.1 (+http://www.google.com/bot.html)"]
    reqs = [("GET / HTTP/1.1", 200, 612), ("GET /static/app.css HTTP/2.0", 200, 10240), ("GET /favicon.ico HTTP/1.1", 404, 153),
            ("POST /api/login HTTP/1.1", 302, 0), ("GET /api/orders/1042 HTTP/1.1", 200, 932), ("GET /admin HTTP/1.1", 403, 153),
            ("GET /api/report HTTP/1.1", 504, 167), ("GET /index.html HTTP/1.1", 304, 0), ("GET /api/orders HTTP/1.1", 500, 177),
            ("HEAD /health HTTP/1.1", 200, 0), ("GET /wp-login.php HTTP/1.1", 404, 153), ("-", 400, 0),
            ("GET /search?q=log%20parser HTTP/1.1", 200, 4410), ("PUT /api/cart/551 HTTP/1.1", 201, 88)]
    for i in range(120):
        t = c.step(10, 6000)
        r, s, b = reqs[i % len(reqs)]
        user = "user-1042" if i % 11 == 4 else "-"
        ref = "https://www.example.com/" if i % 3 == 0 else "-"
        w = wall(t, 2)
        line = '%s - %s [%s] "%s" %d %d "%s" "%s"' % (ips[i % len(ips)], user, w.strftime("%d/%b/%Y:%H:%M:%S %z"), r, s, b, ref, uas[i % len(uas)])
        fx.add(line, "error" if s >= 500 else "warning" if s >= 400 else "info", t.replace(microsecond=0), True, None)
    fx.save()

    fx = Fixture("nginx", "error",
            "Documentation-derived: nginx error log lines 'YYYY/MM/DD HH:MM:SS [level] pid#tid: *connection message' "
            "with levels from https://nginx.org/en/docs/ngx_core_module.html#error_log and line shapes from "
            "https://nginx.org/en/docs/debugging_log.html ; local time, no zone")
    c = Clock(202)
    LV = {"debug": "debug", "info": "info", "notice": "notice", "warn": "warning", "error": "error", "crit": "fatal",
          "alert": "fatal", "emerg": "fatal"}
    rows = [
        ("notice", 1, None, 'using the "epoll" event method'),
        ("notice", 1, None, "nginx/1.27.2"),
        ("notice", 1, None, "start worker processes"),
        ("warn", 1, None, 'conflicting server name "example.com" on 0.0.0.0:80, ignored'),
        ("error", 29, 3, 'open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 203.0.113.7, server: example.com, request: "GET /favicon.ico HTTP/1.1", host: "example.com"'),
        ("error", 29, 7, 'upstream timed out (110: Connection timed out) while reading response header from upstream, client: 198.51.100.23, server: example.com, request: "GET /api/report HTTP/1.1", upstream: "http://192.0.2.10:8080/api/report", host: "example.com"'),
        ("info", 30, 9, "client 203.0.113.150 closed keepalive connection"),
        ("debug", 30, 9, "http keepalive handler"),
        ("crit", 30, 12, "SSL_do_handshake() failed (SSL: error:0A00006C:SSL routines::bad key share) while SSL handshaking, client: 192.0.2.44, server: 0.0.0.0:443"),
        ("error", 29, 14, 'connect() failed (111: Connection refused) while connecting to upstream, client: 203.0.113.7, server: example.com, request: "GET /api/orders HTTP/1.1", upstream: "http://192.0.2.10:8080/api/orders", host: "example.com"'),
        ("alert", 1, None, "worker process 30 exited on signal 9"),
        ("emerg", 1, None, 'bind() to 0.0.0.0:80 failed (98: Address already in use)'),
        ("warn", 29, 20, "an upstream response is buffered to a temporary file /var/cache/nginx/proxy_temp/1/00/0000000001 while reading upstream"),
    ]
    for i in range(65):
        lv, pid, conn, msg = rows[i % len(rows)]
        t = c.step(50, 20000)
        line = "%s [%s] %d#%d: %s%s" % (t.strftime("%Y/%m/%d %H:%M:%S"), lv, pid, pid, "*%d " % (conn + i) if conn else "", msg)
        fx.add(line, LV[lv], t.replace(microsecond=0), False, None)
    fx.save()


# ---------------------------------------------------------------- syslog
def syslog():
    # RFC 3164 lines as a syslog daemon stores them (no <PRI>, so no level), then RFC 5424: its own four
    # examples verbatim, then lines built to its ABNF. The level is the severity in PRI (PRI % 8).
    fx = Fixture("syslog", "rfc3164",
            "Documentation-derived: RFC 3164 HEADER (TIMESTAMP 'Mmm dd hh:mm:ss' with a space-padded day, HOSTNAME) and "
            "TAG[pid]: CONTENT https://www.rfc-editor.org/rfc/rfc3164#section-4.1.2 , as syslog daemons write files "
            "(the <PRI> part is not stored, so lines carry no level); no year, so referenceDate's year")
    c = Clock(301)
    rows = [("web-01", "sshd", 812, "Accepted publickey for user-1042 from 203.0.113.17 port 52144 ssh2: ED25519 SHA256:Zq1kN0xAbCdEf"),
            ("web-01", "sshd", 815, "Failed password for invalid user admin from 198.51.100.23 port 40122 ssh2"),
            ("web-01", "CRON", 1201, "(root) CMD (/usr/local/bin/backup --quiet)"),
            ("web-01", "kernel", None, "[ 8123.456789] TCP: request_sock_TCP: Possible SYN flooding on port 443. Sending cookies."),
            ("db-02", "postfix/smtpd", 2210, "connect from mail.example.com[192.0.2.25]"),
            ("db-02", "systemd", 1, "Started Daily apt download activities."),
            ("web-01", "sudo", None, "  user-1042 : TTY=pts/0 ; PWD=/home/user-1042 ; USER=root ; COMMAND=/usr/bin/systemctl restart nginx"),
            ("web-01", "nginx", 29, "2026/10/01 00:00:00 [error] 29#29: *3 open() failed"),
            ("db-02", "dhclient", 640, "DHCPACK of 192.0.2.30 from 192.0.2.1"),
            ("web-01", "su", None, "'su root' failed for lonvick on /dev/pts/8")]
    for i in range(80):
        host, prog, pid, msg = rows[i % len(rows)]
        t = c.step(100, 40000)
        ts = "%s %2d %s" % (t.strftime("%b"), t.day, t.strftime("%H:%M:%S"))
        line = "%s %s %s%s: %s" % (ts, host, prog, "[%d]" % pid if pid is not None else "", msg)
        fx.add(line, None, t.replace(microsecond=0), False, prog)
    fx.save()

    fx = Fixture("syslog", "rfc5424-examples",
            "Documentation-derived: the four examples of RFC 5424 section 6.5 verbatim (BOM written as the real U+FEFF bytes) "
            "https://www.rfc-editor.org/rfc/rfc5424#section-6.5 , then lines built to the ABNF of section 6 including NILVALUE "
            "timestamps and app names, numeric offsets and structured data")
    BOM = "﻿"
    def sev(pri):
        s = pri % 8
        return "fatal" if s <= 2 else ["error", "warning", "notice", "info", "debug"][s - 3]
    ex = [
        (34, "<34>1 2003-10-11T22:14:15.003Z mymachine.example.com su - ID47 - " + BOM + "'su root' failed for lonvick on /dev/pts/8",
         dt.datetime(2003, 10, 11, 22, 14, 15, 3000, tzinfo=UTC), "su"),
        (165, "<165>1 2003-08-24T05:14:15.000003-07:00 192.0.2.1 myproc 8710 - - %% It's time to make the do-nuts.",
         dt.datetime(2003, 8, 24, 5, 14, 15, 3, tzinfo=dt.timezone(dt.timedelta(hours=-7))), "myproc"),
        (165, '<165>1 2003-10-11T22:14:15.003Z mymachine.example.com evntslog - ID47 [exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"] ' + BOM + "An application event log entry...",
         dt.datetime(2003, 10, 11, 22, 14, 15, 3000, tzinfo=UTC), "evntslog"),
        (165, '<165>1 2003-10-11T22:14:15.003Z mymachine.example.com evntslog - ID47 [exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"][examplePriority@32473 class="high"]',
         dt.datetime(2003, 10, 11, 22, 14, 15, 3000, tzinfo=UTC), "evntslog"),
    ]
    for pri, line, t, app in ex:
        fx.add(line, sev(pri), t, True, app)
    c = Clock(302)
    apps = [("web-01.example.com", "nginx", "29", "-"), ("db-02.example.com", "postgres", "4123", "CHECKPOINT"),
            ("web-01.example.com", "-", "-", "-"), ("203.0.113.9", "billing", "77", "PAY01"), ("-", "kernel", "-", "-")]
    msgs = ["upstream timed out", "checkpoint complete: wrote 12 buffers", "no app name on this one",
            "payment provider returned 502", "Out of memory: Killed process 4312"]
    for i in range(36):
        host, app, pid, mid = apps[i % len(apps)]
        fac = [16, 3, 1, 20, 0][i % 5]
        s = [6, 4, 3, 5, 2, 7, 1, 0][i % 8]
        pri = fac * 8 + s
        t = c.step(100, 20000, us=True)
        if i % 9 == 4:
            ts, tt = "-", None
        elif i % 4 == 1:
            w = wall(t, 2)
            ts, tt = w.strftime("%Y-%m-%dT%H:%M:%S.") + "%06d+02:00" % w.microsecond, t
        else:
            ts, tt = t.strftime("%Y-%m-%dT%H:%M:%S.") + "%03dZ" % (t.microsecond // 1000), t.replace(microsecond=t.microsecond // 1000 * 1000)
        sd = '[origin ip="192.0.2.15" software="shop" swVersion="1.4.2"]' if i % 3 == 0 else "-"
        fx.add("<%d>1 %s %s %s %s %s %s %s" % (pri, ts, host, app, pid, mid, sd, msgs[i % len(msgs)]), sev(pri), tt, tt is not None,
               None if app == "-" else app)
    fx.save()


# ---------------------------------------------------------------- journald
LOGFMT_LEVELS = {"debug": "debug", "info": "info", "warning": "warning", "error": "error", "fatal": "fatal"}


def logfmt_level(message):
    """The level= of a message that is itself logfmt, else None."""
    match = re.search(r"\blevel=(\w+)", message)
    return LOGFMT_LEVELS.get(match.group(1)) if match else None


def journald():
    # journalctl -o short and -o short-iso. Continuation lines are indented to the message column, and the
    # "-- Boot ... --" separators belong to no entry. journald stores no level in these outputs, but a
    # message that is itself logfmt with a level= (dockerd's) answers that level, as people filter for it.
    src = ("Documentation-derived: journalctl --output=%s as described in journalctl(1) "
           "https://www.freedesktop.org/software/systemd/man/latest/journalctl.html#-o ; continuation lines of "
           "multi-line messages are indented to the message column, '-- Boot … --' separators are not entries")
    rows = [("sshd", 812, "Accepted publickey for user-1042 from 203.0.113.17 port 52144 ssh2"),
            ("systemd", 1, "Started nginx.service - A high performance web server and a reverse proxy server."),
            ("nginx", 2290, "2026/10/01 00:00:01 [notice] 2290#2290: using the \"epoll\" event method"),
            ("kernel", None, "EXT4-fs (sda1): mounted filesystem with ordered data mode. Quota mode: none."),
            ("app", 4123, "Traceback (most recent call last):\n  File \"/srv/app/worker.py\", line 12, in <module>\nValueError: bad input"),
            ("CRON", 1201, "pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)"),
            ("systemd-logind", 600, "New session 14 of user user-1042."),
            ("dockerd", 950, "time=\"2026-10-01T00:00:00.000000000Z\" level=info msg=\"Loading containers: done.\""),
            ("sudo", 3011, "user-1042 : TTY=pts/0 ; PWD=/home/user-1042 ; USER=root ; COMMAND=/usr/bin/apt update")]
    for name, off in (("short", 0), ("short-iso", 2)):
        fx = Fixture("journald", name, src % name + ("; times in a +02:00 zone" if off else "; local time, no zone, no year"))
        c = Clock(401 + off)
        fx.raw("-- Boot 3f1c2a9e8d7b4c5a9e1f2d3c4b5a6978 --")
        for i in range(70):
            prog, pid, msg = rows[i % len(rows)]
            t = c.step(200, 30000, us=True).replace(microsecond=0)
            w = wall(t, off)
            ts = w.strftime("%b %d %H:%M:%S") if name == "short" else w.strftime("%Y-%m-%dT%H:%M:%S") + "+%02d:00" % off
            head = "%s web-01 %s%s: " % (ts, prog, "[%d]" % pid if pid else "")
            parts = msg.split("\n")
            text = head + parts[0] + "".join("\n" + " " * len(head) + p for p in parts[1:])
            fx.add(text, logfmt_level(msg), t, name != "short", prog)
            if i == 44:
                fx.raw("-- Boot 7a6b5c4d3e2f10293847566574839201 --")
        fx.save()


# ---------------------------------------------------------------- heroku
def heroku():
    # Heroku's "timestamp source[dyno]: message". Router lines take their level from at=; app and dyno lines
    # carry none. The component is the source without the dyno.
    fx = Fixture("logfmt", "heroku-router",
            "Documentation-derived: Heroku log format 'timestamp source[dyno]: message' "
            "https://devcenter.heroku.com/articles/logging#log-format and router fields "
            "https://devcenter.heroku.com/articles/http-routing#heroku-router-log-format , error codes "
            "https://devcenter.heroku.com/articles/error-codes")
    c = Clock(501)
    paths = ["/", "/api/orders", "/assets/app.js", "/login", "/api/report", "/health"]
    for i in range(80):
        t = c.step(20, 4000, us=True)
        ts = t.strftime("%Y-%m-%dT%H:%M:%S.") + "%06d+00:00" % t.microsecond
        k = i % 10
        rid = "%08x-%04x-4%03x-a%03x-%012x" % (0x5f3a0000 + i, i, i, i, 0xb00c00000000 + i)
        if k in (0, 1, 2, 4, 6):
            st = [200, 200, 304, 404, 200][k % 5]
            line = ('%s heroku[router]: at=info method=GET path="%s" host=example-app.herokuapp.com request_id=%s fwd="203.0.113.%d" '
                    'dyno=web.%d connect=%dms service=%dms status=%d bytes=%d protocol=https') % (
                ts, paths[i % len(paths)], rid, 10 + i % 50, 1 + i % 2, i % 3, 5 + i * 7 % 300, st, 120 + i * 31 % 9000)
            fx.add(line, "info", t, True, "heroku")
        elif k == 3:
            line = ('%s heroku[router]: at=error code=H12 desc="Request timeout" method=GET path="/api/report" host=example-app.herokuapp.com '
                    'request_id=%s fwd="198.51.100.%d" dyno=web.1 connect=0ms service=30000ms status=503 bytes=0 protocol=https') % (ts, rid, 1 + i % 200)
            fx.add(line, "error", t, True, "heroku")
        elif k == 5:
            fx.add("%s app[web.%d]: Started GET \"/api/orders\" for 203.0.113.%d at 2026-10-01 00:00:00 +0000" % (ts, 1 + i % 2, 10 + i % 50), None, t, True, "app")
        elif k == 7:
            fx.add("%s heroku[web.1]: State changed from starting to up" % ts, None, t, True, "heroku")
        elif k == 8:
            fx.add("%s app[worker.1]: Processed job 77%02d in 182ms" % (ts, i), None, t, True, "app")
        else:
            fx.add('%s heroku[router]: at=error code=H10 desc="App crashed" method=GET path="/" host=example-app.herokuapp.com request_id=%s fwd="192.0.2.%d" dyno= connect= service= status=503 bytes= protocol=https' % (ts, rid, 1 + i % 200), "error", t, True, "heroku")
    fx.save()


# ---------------------------------------------------------------- docker
def docker():
    # The json-file driver: one {"log", "stream", "time"} object per line, nanosecond times. The text inside
    # carries no level, so the level is null and the component is the stream.
    fx = Fixture("docker", "json-file",
            "Documentation-derived: Docker json-file logging driver lines {\"log\", \"stream\", \"time\"} "
            "https://docs.docker.com/engine/logging/drivers/json-file/ ; time in RFC 3339 with nanoseconds; "
            "the inner text carries no level, so level is null; component is the stream")
    c = Clock(601)
    msgs = [("stdout", "Listening on http://0.0.0.0:3000\n"), ("stdout", "GET /api/orders/1042 200 14ms\n"),
            ("stderr", "Error: connect ECONNREFUSED 198.51.100.20:5432\n"),
            ("stderr", "    at TCPConnectWrap.afterConnect [as oncomplete] (node:net:1607:16)\n"),
            ("stdout", "worker 3 ready\n"), ("stdout", "progress: 40%"), ("stdout", "\r\n"),
            ("stderr", "warning: \"quoted\" value and a tab\tin it\n"), ("stdout", "{\"inner\":\"json text stays a string\"}\n")]
    for i in range(60):
        stream, log = msgs[i % len(msgs)]
        t = c.step(1, 2500, us=True)
        ns = t.microsecond * 1000 + (i * 37) % 1000
        ts = t.strftime("%Y-%m-%dT%H:%M:%S.") + "%09dZ" % ns
        fx.add(json.dumps({"log": log, "stream": stream, "time": ts}, separators=(",", ":")), None, t, True, stream)
    fx.save()


# ---------------------------------------------------------------- klog
def klog():
    # klog's "Lmmdd hh:mm:ss.uuuuuu threadid file:line] msg", with structured values and a multi-line
    # "key=<" block; ends with a fatal entry carrying its goroutine dump. No year and no zone.
    fx = Fixture("kubernetes", "klog",
            "Documentation-derived: klog header 'Lmmdd hh:mm:ss.uuuuuu threadid file:line] msg' "
            "https://github.com/kubernetes/klog/blob/main/klog.go (header comment) and structured values incl. "
            "multi-line 'key=<' blocks https://github.com/kubernetes/community/blob/master/contributors/devel/sig-instrumentation/migration-to-structured-logging.md ; "
            "no year (referenceDate) and no zone")
    c = Clock(701)
    rows = [("I", "controller.go", 123, '"Reconciling" deployment="default/web"'),
            ("I", "reflector.go", 359, 'Listing and watching *v1.Pod from k8s.io/client-go/informers/factory.go:160'),
            ("W", "reflector.go", 547, 'k8s.io/client-go/informers/factory.go:160: watch of *v1.Pod ended with: an error on the server ("unable to decode an event from the watch stream") has prevented the request from succeeding'),
            ("E", "controller.go", 211, '"Reconciler error" err="Operation cannot be fulfilled on deployments.apps \\"web\\": the object has been modified" controller="deployment" namespace="default" name="web"'),
            ("I", "leaderelection.go", 250, 'attempting to acquire leader lease kube-system/kube-controller-manager...'),
            ("I", "server.go", 88, '"Serving" address="[::]:10257"'),
            ("I", "pod_workers.go", 965, '"Pod spec changed" pod="default/web-0" diff=<\n\t-  image: example/web:1.4.1\n\t+  image: example/web:1.4.2\n >'),
            ("W", "warnings.go", 70, "metadata.finalizers: \"example.com/cleanup\": prefer a domain-qualified finalizer name"),
            ("E", "kubelet.go", 2412, '"Error syncing pod, skipping" err="failed to \\"StartContainer\\" for \\"web\\" with CrashLoopBackOff" pod="default/web-0"')]
    LV = {"I": "info", "W": "warning", "E": "error", "F": "fatal"}
    for i in range(72):
        L, f, ln, msg = rows[i % len(rows)]
        t = c.step(1, 9000, us=True)
        fx.add("%s%s %s %7d %s:%d] %s" % (L, t.strftime("%m%d"), t.strftime("%H:%M:%S.") + "%06d" % t.microsecond, 1 + (i % 3) * 17,
                                          f, ln, msg), LV[L], t, False, f)
    t = c.step()
    fx.add("F%s %s %7d %s:%d] %s" % (t.strftime("%m%d"), t.strftime("%H:%M:%S.") + "%06d" % t.microsecond, 1, "server.go", 301,
                                     "failed to load kubeconfig: open /etc/kubernetes/admin.conf: no such file or directory\n"
                                     "goroutine 1 [running]:\n"
                                     "k8s.io/klog/v2.stacks(0x1)\n"
                                     "\tk8s.io/klog/v2@v2.130.1/klog.go:1029 +0x8a\n"
                                     "main.main()\n"
                                     "\texample.com/operator/cmd/main.go:42 +0x1f4"), "fatal", t, False, "server.go")
    fx.save()


# ---------------------------------------------------------------- logcat
def logcat():
    # logcat -v threadtime. The "--------- beginning of" dividers belong to no entry. logcat writes each line
    # of a multi-line message (the AndroidRuntime crash) as its own entry, so each is one here too.
    fx = Fixture("android", "logcat-threadtime",
            "Documentation-derived: logcat -v threadtime 'date time PID TID priority tag: message' "
            "https://developer.android.com/tools/logcat#outputFormat (tag left-aligned in 8 columns as logcat prints it); "
            "'--------- beginning of' dividers are not entries; no year (referenceDate)")
    c = Clock(801)
    LV = {"V": "trace", "D": "debug", "I": "info", "W": "warning", "E": "error", "F": "fatal", "A": "fatal"}
    rows = [(1203, 1230, "I", "ActivityManager", "Start proc 4120:com.example.shop/u0a201 for top-activity {com.example.shop/com.example.shop.MainActivity}"),
            (4120, 4120, "D", "OpenGLRenderer", "Setting vsync rate to 60"),
            (4120, 4120, "V", "ShopViewModel", "loadCart user=user-1042"),
            (4120, 4161, "W", "OkHttp", "A connection to https://api.example.com/ was leaked. Did you forget to close a response body?"),
            (4120, 4161, "E", "ShopRepository", "fetch failed: java.net.UnknownHostException: Unable to resolve host \"api.example.com\""),
            (612, 612, "I", "chatty", "uid=1000(system) Binder:612_3 identical 4 lines"),
            (4120, 4120, "I", "Choreographer", "Skipped 31 frames!  The application may be doing too much work on its main thread."),
            (1203, 1255, "W", "ActivityTaskManager", "Activity top resumed state loss timeout for ActivityRecord{8f2a1c u0 com.example.shop/.MainActivity t42}"),
            (980, 1001, "D", "WifiStateMachine", "connected to SSID \"ExampleNet\" rssi=-58")]
    fx.raw("--------- beginning of main")
    for i in range(80):
        pid, tid, L, tag, msg = rows[i % len(rows)]
        t = c.step(1, 3000)
        fx.add("%s %5d %5d %s %-8s: %s" % (t.strftime("%m-%d %H:%M:%S.") + millis(t), pid, tid, L, tag, msg),
               LV[L], t, False, tag)
        if i == 50:
            fx.raw("--------- beginning of crash")
            t = c.step(1, 10)
            for line in ["FATAL EXCEPTION: main", "Process: com.example.shop, PID: 4120",
                         "java.lang.IllegalStateException: Cart must not be empty",
                         "\tat com.example.shop.CartFragment.onCheckout(CartFragment.kt:88)",
                         "\tat android.view.View.performClick(View.java:7659)"]:
                fx.add("%s %5d %5d E %-8s: %s" % (t.strftime("%m-%d %H:%M:%S.") + millis(t), 4120, 4120, "AndroidRuntime", line),
                       "error", t, False, "AndroidRuntime")
            t = c.step(1, 20)
            fx.add("%s %5d %5d F %-8s: %s" % (t.strftime("%m-%d %H:%M:%S.") + millis(t), 4120, 4199, "libc",
                                               "Fatal signal 6 (SIGABRT), code -1 (SI_QUEUE) in tid 4199 (RenderThread), pid 4120 (example.shop)"),
                   "fatal", t, False, "libc")
            fx.add("%s %5d %5d A %-8s: %s" % (t.strftime("%m-%d %H:%M:%S.") + millis(t), 4230, 4230, "DEBUG",
                                               "Abort message: 'Check failed: renderer != nullptr'"), "fatal", t, False, "DEBUG")
            fx.raw("--------- beginning of main")
    fx.save()


# ---------------------------------------------------------------- postgres
def postgres():
    # The default log_line_prefix '%m [%p] '. DETAIL, HINT, CONTEXT and STATEMENT lines repeat the prefix but
    # continue the entry above them, as do tab-indented lines.
    fx = Fixture("postgres", "postgresql",
            "Documentation-derived: PostgreSQL stderr log with the default log_line_prefix '%m [%p] ' "
            "https://www.postgresql.org/docs/current/runtime-config-logging.html#GUC-LOG-LINE-PREFIX and severity levels "
            "https://www.postgresql.org/docs/current/runtime-config-logging.html#RUNTIME-CONFIG-SEVERITY-LEVELS ; DETAIL/HINT/"
            "CONTEXT/STATEMENT lines (which repeat the prefix) and tab-indented lines continue the entry above")
    c = Clock(901)
    LV = {"DEBUG1": "debug", "DEBUG2": "debug", "LOG": "info", "INFO": "info", "NOTICE": "notice", "WARNING": "warning",
          "ERROR": "error", "FATAL": "fatal", "PANIC": "fatal"}
    def pfx(t, pid):
        return "%s UTC [%d] " % (t.strftime("%Y-%m-%d %H:%M:%S.") + millis(t), pid)
    rows = [
        (1, "LOG", "starting PostgreSQL 17.2 on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 13.2.0, 64-bit", []),
        (1, "LOG", "listening on IPv4 address \"0.0.0.0\", port 5432", []),
        (27, "LOG", "database system was shut down at 2026-09-30 23:58:01 UTC", []),
        (1, "LOG", "database system is ready to accept connections", []),
        (412, "ERROR", "duplicate key value violates unique constraint \"users_email_key\"",
         [("DETAIL", "Key (email)=(user-1042@example.com) already exists."),
          ("STATEMENT", "INSERT INTO users (email, name) VALUES ('user-1042@example.com', 'User 1042');")]),
        (413, "ERROR", "relation \"order_items\" does not exist at character 15",
         [("STATEMENT", "SELECT *\n\t  FROM order_items\n\t WHERE order_id = 7731;")]),
        (25, "LOG", "checkpoint starting: time", []),
        (25, "LOG", "checkpoint complete: wrote 44 buffers (0.3%); 0 WAL file(s) added, 0 removed, 0 recycled; write=4.312 s, sync=0.004 s, total=4.330 s; sync files=12, longest=0.002 s, average=0.001 s; distance=301 kB, estimate=301 kB; lsn=0/1A3C2B8, redo lsn=0/1A3C280", []),
        (420, "FATAL", "password authentication failed for user \"app\"",
         [("DETAIL", "Connection matched file \"/var/lib/postgresql/data/pg_hba.conf\" line 99: \"host all all all scram-sha-256\"")]),
        (431, "WARNING", "there is no transaction in progress", []),
        (440, "ERROR", "canceling statement due to statement timeout",
         [("CONTEXT", "while scanning block 1200 of relation \"public.events\""), ("STATEMENT", "SELECT count(*) FROM events;")]),
        (52, "LOG", "automatic vacuum of table \"shop.public.orders\": index scans: 1\n\tpages: 0 removed, 312 remain, 312 scanned (100.00% of total)\n\ttuples: 120 removed, 9800 remain, 0 are dead but not yet removable", []),
        (460, "NOTICE", "table \"tmp_import\" does not exist, skipping", []),
        (470, "ERROR", "deadlock detected",
         [("DETAIL", "Process 470 waits for ShareLock on transaction 5521; blocked by process 471.\n\tProcess 471 waits for ShareLock on transaction 5520; blocked by process 470.\n\tProcess 470: UPDATE accounts SET balance = balance - 10 WHERE id = 1;\n\tProcess 471: UPDATE accounts SET balance = balance + 10 WHERE id = 2;"),
          ("HINT", "See server log for query details."), ("CONTEXT", "while updating tuple (0,12) in relation \"accounts\""),
          ("STATEMENT", "UPDATE accounts SET balance = balance - 10 WHERE id = 1;")]),
        (480, "LOG", "duration: 2310.442 ms  statement: SELECT * FROM orders WHERE status = 'open' ORDER BY created_at DESC;", []),
        (481, "DEBUG1", "autovacuum: processing database \"shop\"", []),
        (490, "LOG", "connection received: host=203.0.113.17 port=52144", []),
        (490, "LOG", "connection authorized: user=app database=shop application_name=psql", []),
        (1, "PANIC", "could not write to file \"pg_wal/xlogtemp.31\": No space left on device", []),
    ]
    for i in range(95):
        pid, lv, msg, extra = rows[i % len(rows)]
        pid = pid if pid < 100 else pid + (i // len(rows)) * 100
        t = c.step(5, 20000)
        text = pfx(t, pid) + "%s:  %s" % (lv, msg)
        for k, v in extra:
            text += "\n" + pfx(t, pid) + "%s:  %s" % (k, v)
        fx.add(text, LV[lv], t, True, None)
    fx.save()


# ---------------------------------------------------------------- mysql
def mysql():
    # MySQL 8.4's error log: "time thread [label] [err_code] [subsystem] message", UTC (log_timestamps'
    # default). System and Note both answer info.
    fx = Fixture("mysql", "error",
            "Documentation-derived: MySQL 8 error log, traditional format 'time thread [label] [err_code] [subsystem] message' "
            "https://dev.mysql.com/doc/refman/8.4/en/error-log-format.html ; log_timestamps=UTC (the default)")
    c = Clock(1001)
    LV = {"System": "info", "Note": "info", "Warning": "warning", "Error": "error"}
    rows = [(0, "System", "MY-010116", "Server", "/usr/sbin/mysqld (mysqld 8.4.3) starting as process 1"),
            (1, "System", "MY-013576", "InnoDB", "InnoDB initialization has started."),
            (1, "System", "MY-013577", "InnoDB", "InnoDB initialization has ended."),
            (0, "Warning", "MY-010068", "Server", "CA certificate ca.pem is self signed."),
            (0, "System", "MY-013602", "Server", "Channel mysql_main configured to support TLS. Encrypted connections are now supported for this channel."),
            (0, "Warning", "MY-011810", "Server", "Insecure configuration for --pid-file: Location '/var/run/mysqld' in the path is accessible to all OS users. Consider choosing a different directory."),
            (0, "System", "MY-010931", "Server", "/usr/sbin/mysqld: ready for connections. Version: '8.4.3'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL."),
            (8, "Warning", "MY-013360", "Server", "Plugin mysql_native_password reported: ''mysql_native_password' is deprecated and will be removed in a future release. Please use caching_sha2_password instead'"),
            (12, "Note", "MY-010914", "Server", "Aborted connection 12 to db: 'shop' user: 'app' host: '203.0.113.17' (Got an error reading communication packets)."),
            (0, "Error", "MY-012574", "InnoDB", "Unable to lock ./ibdata1 error: 11"),
            (14, "Error", "MY-010584", "Repl", "Replica SQL for channel '': Worker 1 failed executing transaction 'ANONYMOUS' at source log binlog.000042, end_log_pos 1337; Error 'Duplicate entry '7731' for key 'orders.PRIMARY'' on query. Default database: 'shop'. Query: 'INSERT INTO orders VALUES (7731)', Error_code: MY-001062"),
            (0, "Note", "MY-011953", "InnoDB", "Page cleaner took 4321ms to flush 210 and evict 0 pages")]
    for i in range(64):
        th, lab, code, sub, msg = rows[i % len(rows)]
        t = c.step(1, 30000, us=True)
        fx.add("%s %d [%s] [%s] [%s] %s" % (t.strftime("%Y-%m-%dT%H:%M:%S.") + "%06dZ" % t.microsecond, th, lab, code, sub, msg),
               LV[lab], t, True, sub)
    fx.save()


# ---------------------------------------------------------------- redis
def redis():
    # serverLogRaw's "pid:role dd Mon yyyy hh:mm:ss.mmm level message", with a stock 7.4 server's start-up
    # messages. Levels: . debug, - verbose (debug), * notice, # warning.
    fx = Fixture("redis", "redis",
            "Documentation-derived: Redis log line 'pid:role dd Mon yyyy hh:mm:ss.mmm level message' as serverLogRaw writes it "
            "https://github.com/redis/redis/blob/7.4/src/server.c (roles X sentinel, C child, S replica, M primary; levels "
            ". debug, - verbose, * notice, # warning); messages from a stock Redis 7.4 start-up; local time, no zone")
    c = Clock(1101)
    LV = {".": "debug", "-": "debug", "*": "notice", "#": "warning"}
    rows = [(1, "C", "*", "oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo"),
            (1, "C", "*", "Redis version=7.4.1, bits=64, commit=00000000, modified=0, pid=1, just started"),
            (1, "C", "#", "Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf"),
            (1, "M", "*", "monotonic clock: POSIX clock_gettime"),
            (1, "M", "*", "Running mode=standalone, port=6379."),
            (1, "M", "#", "WARNING Memory overcommit must be enabled! Without it, a background save or replication may fail under low memory condition."),
            (1, "M", "*", "Server initialized"),
            (1, "M", "*", "Ready to accept connections tcp"),
            (1, "M", "-", "Accepted 203.0.113.17:52144"),
            (1, "M", ".", "Client closed connection id=12 addr=203.0.113.17:52144"),
            (1, "M", "*", "1 changes in 3600 seconds. Saving..."),
            (1, "M", "*", "Background saving started by pid 42"),
            (42, "C", "*", "DB saved on disk"),
            (42, "C", "*", "Fork CoW for RDB: current 0 MB, peak 0 MB, average 0 MB"),
            (1, "M", "*", "Background saving terminated with success"),
            (7, "S", "*", "Connecting to MASTER 192.0.2.10:6379"),
            (7, "S", "#", "Error condition on socket for SYNC: Connection refused"),
            (9, "X", "#", "+sdown master mymaster 192.0.2.10 6379")]
    for i in range(72):
        pid, role, L, msg = rows[i % len(rows)]
        t = c.step(1, 8000)
        fx.add("%d:%s %s %s %s" % (pid, role, t.strftime("%d %b %Y %H:%M:%S.") + millis(t), L, msg),
               LV[L], t, False, None)
    fx.save()


# ---------------------------------------------------------------- elixir
def elixir():
    LV = {"debug": "debug", "info": "info", "notice": "notice", "warning": "warning", "error": "error",
          "critical": "fatal", "alert": "fatal", "emergency": "fatal"}
    rows = [("info", "Running ShopWeb.Endpoint with Bandit 1.5.7 at 0.0.0.0:4000 (http)"),
            ("info", "Access ShopWeb.Endpoint at http://localhost:4000"),
            ("debug", "QUERY OK source=\"orders\" db=1.2ms idle=812.3ms\nSELECT o0.\"id\", o0.\"total\" FROM \"orders\" AS o0 WHERE (o0.\"user_id\" = $1) [1042]"),
            ("info", "GET /api/orders"),
            ("info", "Sent 200 in 14ms"),
            ("warning", "Rate limit hit for user-1042"),
            ("error", "GenServer Shop.Cart terminating\n** (RuntimeError) cart 551 is locked\n    (shop 0.1.0) lib/shop/cart.ex:42: Shop.Cart.handle_call/3\n    (stdlib 6.1) gen_server.erl:2381: :gen_server.try_handle_call/4\nLast message: {:checkout, 551}"),
            ("notice", "Application shop started at :nonode@nohost"),
            ("critical", "Database pool exhausted"),
            ("alert", "Disk usage at 97%"),
            ("emergency", "Node is going down")]
    # Logger's default formatter: "\n$time $metadata[$level] $message\n"
    fx = Fixture("elixir", "logger-default",
            "Documentation-derived: Elixir Logger default formatter format \"\\n$time $metadata[$level] $message\\n\" with no metadata "
            "https://hexdocs.pm/logger/Logger.Formatter.html ; every entry is preceded by an empty line (not part of any entry); "
            "time only, so the date is referenceDate")
    c = Clock(1201)
    for i in range(56):
        lv, msg = rows[i % len(rows)]
        t = c.step(1, 4000)
        fx.raw("")
        fx.add("%s [%s] %s" % (t.strftime("%H:%M:%S.") + millis(t), lv, msg), LV[lv], t, False, None)
    fx.save()
    # Phoenix generator's console config: format "$time $metadata[$level] $message\n", metadata: [:request_id]
    fx = Fixture("elixir", "phoenix",
            "Documentation-derived: the Phoenix generator's logger config format \"$time $metadata[$level] $message\\n\" with "
            "metadata: [:request_id] https://hexdocs.pm/phoenix/up_and_running.html (config/config.exs of mix phx.new) and "
            "https://hexdocs.pm/logger/Logger.Formatter.html ; time only")
    c = Clock(1202)
    for i in range(60):
        lv, msg = rows[(i * 5) % len(rows)]
        t = c.step(1, 4000)
        md = "request_id=F%013x " % (0x18A2B3C4D5E6F + i * 977) if i % 3 != 0 else ""
        fx.add("%s %s[%s] %s" % (t.strftime("%H:%M:%S.") + millis(t), md, lv, msg), LV[lv], t, False, None)
    fx.save()


# ---------------------------------------------------------------- go
def go():
    # The log package with LstdFlags (no level), then log/slog's TextHandler and JSONHandler. Levels between
    # the named ones (ERROR+4, DEBUG-4) answer their named base level.
    fx = Fixture("go", "log",
            "Documentation-derived: Go standard log package default flags LstdFlags ('2009/01/23 01:23:23 message') "
            "https://pkg.go.dev/log#pkg-constants ; no level, local time, no zone")
    c = Clock(1301)
    msgs = ["listening on :8080", "GET /api/orders/1042 200 14.2ms", "dial tcp 198.51.100.20:5432: connect: connection refused",
            "config: using defaults for 3 keys", "multi-line value:\nfirst continuation\nsecond continuation",
            "worker 3 finished job 5521", "http: TLS handshake error from 203.0.113.17:52144: EOF",
            "panic recovered: runtime error: index out of range [5] with length 3"]
    for i in range(64):
        t = c.step(1, 5000)
        fx.add("%s %s" % (t.strftime("%Y/%m/%d %H:%M:%S"), msgs[i % len(msgs)]), None, t.replace(microsecond=0), False, None)
    fx.save()

    SL = {"DEBUG": "debug", "INFO": "info", "WARN": "warning", "ERROR": "error", "DEBUG-4": "debug", "INFO+2": "info",
          "WARN+2": "warning", "ERROR+4": "error"}
    rows = [("INFO", "server started", [("addr", ":8080"), ("component", "api")]),
            ("DEBUG", "cache lookup", [("key", "user:1042"), ("hit", True)]),
            ("WARN", "slow request", [("method", "GET"), ("path", "/api/report"), ("duration", "2.31s"), ("component", "api")]),
            ("ERROR", "query failed", [("err", "pq: relation \"order_items\" does not exist"), ("component", "db")]),
            ("INFO", "user signed in", [("user", "user-1042"), ("ip", "203.0.113.17")]),
            ("INFO", "message with spaces and \"quotes\"", [("note", "a=b c")]),
            ("ERROR+4", "data loss detected", [("table", "orders"), ("component", "db")]),
            ("DEBUG-4", "very verbose detail", [("n", 7)]),
            ("WARN+2", "disk nearly full", [("used", "97%"), ("component", "storage")])]
    def textval(v):
        if v is True:
            return "true"
        s = str(v)
        return '"%s"' % s.replace('"', '\\"') if (any(ch in s for ch in ' ="') or s == "") else s
    fx = Fixture("go", "slog-text",
            "Documentation-derived: log/slog TextHandler 'time=… level=… msg=… key=value' "
            "https://pkg.go.dev/log/slog#TextHandler (time as RFC 3339 with milliseconds; levels between the named ones "
            "are written as e.g. ERROR+4) ; UTC")
    c = Clock(1302)
    for i in range(70):
        lv, msg, attrs = rows[i % len(rows)]
        t = c.step(1, 3000)
        ts = t.strftime("%Y-%m-%dT%H:%M:%S.") + "%03dZ" % (t.microsecond // 1000)
        line = "time=%s level=%s msg=%s" % (ts, lv, textval(msg)) + "".join(" %s=%s" % (k, textval(v)) for k, v in attrs)
        comp = dict(attrs).get("component")
        fx.add(line, SL[lv], t.replace(microsecond=t.microsecond // 1000 * 1000), True, comp)
    fx.save()

    fx = Fixture("go", "slog-json",
            "Documentation-derived: log/slog JSONHandler https://pkg.go.dev/log/slog#JSONHandler ; time written as "
            "time.RFC3339Nano, which drops trailing zeros (handler.go appendJSONTime), in a -05:00 zone")
    c = Clock(1303)
    for i in range(70):
        lv, msg, attrs = rows[(i * 2) % len(rows)]
        t = c.step(1, 3000, us=True)
        w = wall(t, -5)
        frac = ("%06d" % w.microsecond).rstrip("0")
        ts = w.strftime("%Y-%m-%dT%H:%M:%S") + ("." + frac if frac else "") + "-05:00"
        d = {"time": ts, "level": lv, "msg": msg}
        d.update(attrs)
        comp = dict(attrs).get("component")
        if i % 7 == 3:
            d["service"] = "checkout"
            comp = "checkout"   # service comes before component in the lookup order
        fx.add(json.dumps(d, separators=(",", ":")), SL[lv], t, True, comp)
    fx.save()


if __name__ == "__main__":
    for write in (java, nginx, syslog, journald, heroku, docker, klog, logcat, postgres, mysql, redis, elixir, go):
        write()
