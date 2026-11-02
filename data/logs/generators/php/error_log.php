<?php
// PHP's own error_log: trigger.php run once per case, each run appending one entry, with the answers taken
// from the run.
//
//   php error_log.php <out>      writes <out>/error_log.log and error_log.expected.json
//
// The clock is real. Each run starts early in a second and its second is read before and after; if they
// differ the script stops, so every answer's time is the second the line shows. The line count of an entry is
// what that run appended (stack traces add lines).

[, $out] = $argv;
$log = "$out/error_log.log";
@unlink($log);
touch($log);

// [case, answer level]. Deprecated answers notice, as Monolog's ErrorHandler maps E_DEPRECATED; every fatal
// kind (uncaught exception, Error, TypeError, memory exhausted) answers fatal.
$cases = [
    ['warning', 'warning'], ['notice', 'notice'], ['deprecated', 'notice'], ['warning2', 'warning'],
    ['uwarning', 'warning'], ['fatal', 'fatal'], ['deprecated2', 'notice'], ['warning3', 'warning'],
    ['typeerror', 'fatal'], ['notice', 'notice'], ['fatal2', 'fatal'], ['warning', 'warning'],
    ['memory', 'fatal'], ['uwarning', 'warning'], ['deprecated', 'notice'],
];
$trigger = __DIR__ . '/trigger.php';
$entries = [];
$line = 1;
$offset = 0;

for ($round = 0; $round < 3; $round++) {
    foreach ($cases as [$case, $level]) {
        // Start between 50 ms and 600 ms into a second, so a run cannot cross into the next one.
        while (true) {
            $us = (int)(microtime(true) * 1e6) % 1000000;
            if ($us > 50000 && $us < 600000) break;
            usleep(20000);
        }
        $before = time();
        shell_exec(sprintf(
            '%s -n -d log_errors=1 -d display_errors=0 -d error_reporting=-1 -d html_errors=0 -d date.timezone=UTC '
                . '-d error_log=%s %s %s 2>&1',
            escapeshellarg(PHP_BINARY), escapeshellarg($log), escapeshellarg($trigger), escapeshellarg($case)));
        if (time() !== $before) {
            fwrite(STDERR, "a run crossed a second; run again\n");
            exit(2);
        }
        clearstatcache();
        $appended = substr(file_get_contents($log), $offset);
        $lines = substr_count($appended, "\n");
        $entries[] = ['line' => $line, 'lines' => $lines, 'level' => $level,
                      'time' => gmdate('Y-m-d\TH:i:s', $before) . '.000Z', 'zoned' => true, 'component' => null];
        $line += $lines;
        $offset += strlen($appended);
        usleep(150000);
    }
}

file_put_contents("$out/error_log.expected.json", json_encode([
    'source' => 'PHP ' . PHP_VERSION . ' CLI error_log (php -n -d log_errors=1 -d error_log=FILE -d date.timezone=UTC), '
        . 'one run of trigger.php per entry; script error_log.php',
    'referenceDate' => '2026-10-01',
    'entries' => $entries,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");
