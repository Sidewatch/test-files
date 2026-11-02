<?php
// A Laravel log: Monolog with the formatter Laravel's LogManager builds, with the answers taken from each record.
//
//   php laravel.php <out>      writes <out>/laravel.log and laravel.expected.json
//
// The formatter is LineFormatter(null, 'Y-m-d H:i:s', allowInlineLineBreaks: true, ignoreEmptyContextAndExtra:
// true) with includeStacktraces(), so exceptions carry "[stacktrace]" and "#0 ..." lines. Each record is given
// its time from a seeded clock (Monolog's own datetime argument), so the output is the same on every run.

require __DIR__ . '/vendor/autoload.php';

use Composer\InstalledVersions;
use Monolog\Formatter\LineFormatter;
use Monolog\Handler\StreamHandler;
use Monolog\JsonSerializableDateTimeImmutable;
use Monolog\Level;
use Monolog\Logger;

[, $out] = $argv;
$file = "$out/laravel.log";
@unlink($file);

$formatter = new LineFormatter(null, 'Y-m-d H:i:s', true, true);
$formatter->includeStacktraces();
$handler = new StreamHandler($file, Level::Debug);
$handler->setFormatter($formatter);
$channels = ['production' => new Logger('production', [$handler]), 'payments' => new Logger('payments', [$handler])];

const LEVELS = ['DEBUG' => 'debug', 'INFO' => 'info', 'NOTICE' => 'notice', 'WARNING' => 'warning', 'ERROR' => 'error',
                'CRITICAL' => 'fatal', 'ALERT' => 'fatal', 'EMERGENCY' => 'fatal'];

// Two frames deep, so the stack trace has something in it.
class OrderRepository { function find($id) { throw new RuntimeException("No query results for model [App\\Models\\Order] $id"); } }
class OrderController { function show($id) { return (new OrderRepository)->find($id); } }

// [level, message, context]; 'EXCEPTION' logs a caught exception instead.
$script = [
    [Level::Info, 'User signed in', ['user_id' => 1042, 'ip' => '203.0.113.17']],
    [Level::Debug, 'Cache hit', ['key' => 'settings:site']],
    [Level::Warning, 'Slow request', ['path' => '/api/orders', 'ms' => 2310]],
    [Level::Error, 'EXCEPTION', []],
    [Level::Notice, 'Password reset requested', ['user_id' => 1077]],
    [Level::Info, 'Queued job dispatched', ['job' => 'App\\Jobs\\SendInvoice', 'queue' => 'default']],
    [Level::Critical, 'Database connection lost', ['host' => '198.51.100.20']],
    [Level::Alert, 'Disk usage at 97%', []],
    [Level::Emergency, 'Application down', []],
    [Level::Info, "Webhook payload:\n{\"id\":\"evt_1\",\"type\":\"invoice.paid\"}", []],
];

$time = new DateTimeImmutable('2026-10-01 00:00:00', new DateTimeZone('UTC'));
$seed = 3;
$entries = [];
$line = 1;
$offset = 0;
for ($i = 0; $i < 70; $i++) {
    $seed = ($seed * 1103515245 + 12345) % 2147483648;
    $time = $time->modify('+' . (1 + $seed % 4000) . ' seconds');
    [$level, $message, $context] = $script[$i % count($script)];
    $channel = ($i % 7 === 5) ? 'payments' : 'production';
    if ($message === 'EXCEPTION') {
        try {
            (new OrderController)->show(7700 + $i);
        } catch (Throwable $e) {
            $message = $e->getMessage();
            $context = ['exception' => $e];
        }
    }
    $stamp = (new JsonSerializableDateTimeImmutable(true, new DateTimeZone('UTC')))->setTimestamp($time->getTimestamp());
    $channels[$channel]->addRecord($level, $message, $context, $stamp);

    clearstatcache();
    $appended = substr(file_get_contents($file), $offset);
    $lines = substr_count($appended, "\n");
    $entries[] = ['line' => $line, 'lines' => $lines, 'level' => LEVELS[$level->getName()],
                  'time' => $time->format('Y-m-d\TH:i:s') . '.000Z', 'zoned' => false, 'component' => $channel];
    $line += $lines;
    $offset += strlen($appended);
}

$monolog = InstalledVersions::getPrettyVersion('monolog/monolog');
file_put_contents("$out/laravel.expected.json", json_encode([
    'source' => "monolog/monolog $monolog on PHP " . PHP_VERSION . ", StreamHandler + LineFormatter(null, 'Y-m-d H:i:s', "
        . "allowInlineLineBreaks: true, ignoreEmptyContextAndExtra: true) with includeStacktraces(), the formatter "
        . "Laravel's LogManager builds; channels 'production' and 'payments'; script laravel.php",
    'referenceDate' => '2026-10-01',
    'entries' => $entries,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");
