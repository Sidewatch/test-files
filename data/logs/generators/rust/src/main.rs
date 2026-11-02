//! env_logger and tracing-subscriber writing their default formats, with the answers taken from each call.
//!
//!   logfixture env <log> <count>       > env_logger.expected.json
//!   logfixture tracing <log> <count>   > tracing.expected.json
//!
//! The clock is real. env_logger prints whole seconds and tracing microseconds, so each call waits until it is
//! well inside a second (or millisecond) and the program stops if the call crosses into the next one; the
//! answer is then exactly the time the line shows, cut to milliseconds. After each call the new lines in the
//! file are counted, which is how multi-line messages get their line counts. Versions are pinned by Cargo.lock.

use std::fs::{File, OpenOptions};
use std::io::{Read, Seek, SeekFrom};
use std::sync::Mutex;
use std::thread::sleep;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const ENV_LOGGER: &str = "env_logger 0.11.11 (log 0.4.35)";
const TRACING: &str = "tracing-subscriber 0.3.23 (tracing 0.1.44)";

/// The answers for one log file, built as it is written.
struct Answers {
    path: String,
    offset: u64,
    line: usize,
    entries: Vec<String>,
    /// The precision the format prints its times to, in milliseconds: 1000 for env_logger, 1 for tracing.
    precision_ms: u128,
}

fn now_us() -> u128 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_micros()
}

impl Answers {
    /// Waits until the clock is between 10% and 70% of the way through a time bucket, and returns it.
    fn settle(&self) -> u128 {
        let bucket = self.precision_ms * 1000;
        loop {
            let us = now_us();
            let position = us % bucket;
            if position > bucket / 10 && position < bucket * 7 / 10 {
                return us;
            }
            sleep(Duration::from_micros(30));
        }
    }

    /// Notes the entry the last call wrote: the lines it added, and the bucket it started in.
    fn record(&mut self, started_us: u128, level: &str, component: &str) {
        let bucket = self.precision_ms * 1000;
        if started_us / bucket != now_us() / bucket {
            eprintln!("a call crossed into the next time bucket; run again");
            std::process::exit(2);
        }
        let mut file = File::open(&self.path).unwrap();
        file.seek(SeekFrom::Start(self.offset)).unwrap();
        let mut written = String::new();
        file.read_to_string(&mut written).unwrap();
        let lines = written.matches('\n').count();
        let ms = (started_us / bucket) * self.precision_ms;
        let (y, mo, d, h, mi, s) = civil((ms / 1000) as i64);
        let time = format!("{y:04}-{mo:02}-{d:02}T{h:02}:{mi:02}:{s:02}.{:03}Z", ms % 1000);
        self.entries.push(format!(
            "    {{\"line\": {}, \"lines\": {lines}, \"level\": \"{level}\", \"time\": \"{time}\", \"zoned\": true, \
             \"component\": \"{component}\"}}",
            self.line
        ));
        self.line += lines;
        self.offset += written.len() as u64;
    }
}

/// Seconds since 1970 as a UTC (year, month, day, hour, minute, second), by the usual days-to-civil arithmetic.
fn civil(secs: i64) -> (i64, u32, u32, u32, u32, u32) {
    let days = secs.div_euclid(86400);
    let rem = secs.rem_euclid(86400);
    let z = days + 719468;
    let era = z.div_euclid(146097);
    let doe = z - era * 146097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = (doy - (153 * mp + 2) / 5 + 1) as u32;
    let month = if mp < 10 { mp + 3 } else { mp - 9 } as u32;
    let year = yoe + era * 400 + if month <= 2 { 1 } else { 0 };
    (year, month, day, (rem / 3600) as u32, ((rem % 3600) / 60) as u32, (rem % 60) as u32)
}

/// The answer level for a level name in MESSAGES.
fn answer_level(name: &str) -> &'static str {
    match name {
        "trace" => "trace",
        "debug" => "debug",
        "info" => "info",
        "warn" => "warning",
        _ => "error",
    }
}

// Modules, so env_logger shows real module-path targets (logfixture::db, logfixture::http::server, ...).
mod db {
    pub const TARGET: &str = module_path!();
}
mod http {
    pub mod server {
        pub const TARGET: &str = module_path!();
    }
}
mod cache {
    pub const TARGET: &str = module_path!();
}

const MESSAGES: &[(&str, &str)] = &[
    ("info", "server listening on 0.0.0.0:8080"),
    ("debug", "loaded 42 routes from config/routes.toml"),
    ("trace", "poll tick queue_depth=0"),
    ("info", "GET /api/orders/1042 200 12ms"),
    ("warn", "slow query took 812ms: SELECT * FROM orders WHERE user_id = $1"),
    ("error", "connection to 198.51.100.20:5432 refused"),
    ("info", "cache warm: 1200 keys"),
    ("debug", "pool stats idle=4 busy=1"),
    ("error", "request failed: upstream timeout\ncaused by: deadline has elapsed\ncaused by: operation timed out"),
    ("warn", "retrying job 7731 (attempt 2 of 5)"),
    ("info", "user-1042 signed in from 203.0.113.17"),
    ("trace", "entered handler orders::show"),
];

/// env_logger's default format, styles off: "[time LEVEL target] message", continuation lines indented.
fn write_env_logger(path: &str, count: usize, answers: &mut Answers) {
    let file = OpenOptions::new().append(true).open(path).unwrap();
    env_logger::Builder::new()
        .filter_level(log::LevelFilter::Trace)
        .write_style(env_logger::WriteStyle::Never)
        .target(env_logger::Target::Pipe(Box::new(file)))
        .init();
    let targets = [db::TARGET, http::server::TARGET, cache::TARGET, "audit", "logfixture"];
    for i in 0..count {
        let (name, message) = MESSAGES[i % MESSAGES.len()];
        let target = targets[(i * 7 + 3) % targets.len()];
        let level: log::Level = name.parse().unwrap();
        let started = answers.settle();
        log::log!(target: target, level, "{message}");
        log::logger().flush();
        answers.record(started, answer_level(name), target);
        if i % 9 == 0 {
            sleep(Duration::from_millis(1100)); // spread the entries over more than one second
        }
    }
}

/// tracing-subscriber's default fmt layer, ANSI off: "time  LEVEL span{fields}: target: message fields".
fn write_tracing(path: &str, count: usize, answers: &mut Answers) {
    let file = OpenOptions::new().append(true).open(path).unwrap();
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::TRACE)
        .with_ansi(false)
        .with_writer(Mutex::new(file))
        .init();
    // A tracing target must be a constant, so each target is its own call site.
    macro_rules! event {
        ($target:expr, $level:expr, $attempt:expr, $message:expr) => {
            match $level {
                "trace" => tracing::trace!(target: $target, attempt = $attempt, "{}", $message),
                "debug" => tracing::debug!(target: $target, attempt = $attempt, "{}", $message),
                "info" => tracing::info!(target: $target, attempt = $attempt, "{}", $message),
                "warn" => tracing::warn!(target: $target, attempt = $attempt, "{}", $message),
                _ => tracing::error!(target: $target, attempt = $attempt, "{}", $message),
            }
        };
    }
    for i in 0..count {
        let (name, message) = MESSAGES[i % MESSAGES.len()];
        let user = 1000 + (i * 37) % 900;
        let started = answers.settle();
        // Every fourth event happens inside a request span, which the line shows before the target.
        let span = (i % 4 == 0)
            .then(|| tracing::info_span!("request", method = "GET", path = "/api/orders", user_id = user).entered());
        let target = match (i * 7 + 3) % 3 {
            0 => {
                event!("logfixture::db", name, i, message);
                "logfixture::db"
            }
            1 => {
                event!("logfixture::http::server", name, i, message);
                "logfixture::http::server"
            }
            _ => {
                event!("logfixture::cache", name, i, message);
                "logfixture::cache"
            }
        };
        drop(span);
        answers.record(started, answer_level(name), target);
        sleep(Duration::from_millis(3 + (i as u64 * 13) % 40));
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let (which, path, count) = (args[1].as_str(), args[2].as_str(), args[3].parse::<usize>().unwrap());
    File::create(path).unwrap();
    let precision_ms = if which == "env" { 1000 } else { 1 };
    let mut answers = Answers { path: path.to_string(), offset: 0, line: 1, entries: vec![], precision_ms };
    let version = if which == "env" {
        write_env_logger(path, count, &mut answers);
        ENV_LOGGER
    } else {
        write_tracing(path, count, &mut answers);
        TRACING
    };
    println!(
        "{{\n  \"source\": \"{version} default format, written by a cargo program (logfixture {which})\",\n  \
         \"referenceDate\": \"2026-10-01\",\n  \"entries\": [\n{}\n  ]\n}}",
        answers.entries.join(",\n")
    );
}
