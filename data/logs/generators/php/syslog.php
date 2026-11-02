<?php
// Syslog lines built by Monolog's SyslogUdpHandler, in its RFC 5424 and RFC 3164 modes, with the answers taken
// from each record.
//
//   php syslog.php <out>      writes <out>/rfc5424.log, rfc3164-pri.log and their .expected.json
//
// The handler's UDP socket is swapped for one that appends each datagram to the file as a line, so the
// lines are exactly what a syslog server would receive. Monolog writes gethostname() into each line; the
// socket writes web-01 in its place so the machine's name stays out of the corpus. A seeded clock from
// 2026-10-01T00:00:00Z, so the output is the same on every run.

require __DIR__ . '/vendor/autoload.php';

use Composer\InstalledVersions;
use Monolog\Handler\SyslogUdp\UdpSocket;
use Monolog\Handler\SyslogUdpHandler;
use Monolog\JsonSerializableDateTimeImmutable;
use Monolog\Level;
use Monolog\Logger;

[, $out] = $argv;

class FileSocket extends UdpSocket
{
    public static string $file;

    public function __construct() { parent::__construct('127.0.0.1', 514); }

    protected function send(string $chunk): void
    {
        $chunk = str_replace(' ' . gethostname() . ' ', ' web-01 ', $chunk);
        file_put_contents(self::$file, $chunk . "\n", FILE_APPEND);
    }

    public function close(): void {}
}

const LEVELS = ['DEBUG' => 'debug', 'INFO' => 'info', 'NOTICE' => 'notice', 'WARNING' => 'warning', 'ERROR' => 'error',
                'CRITICAL' => 'fatal', 'ALERT' => 'fatal', 'EMERGENCY' => 'fatal'];
$idents = [['sshd', LOG_AUTH], ['billing', LOG_LOCAL4], ['cron', LOG_CRON], ['mailer', LOG_MAIL], ['api', LOG_LOCAL0]];
$script = [
    [Level::Info, 'Accepted publickey for user-1042 from 203.0.113.17 port 52144'],
    [Level::Warning, 'Failed password for invalid user admin from 198.51.100.23'],
    [Level::Error, 'payment provider returned 502 for order 7731'],
    [Level::Notice, 'configuration reloaded'],
    [Level::Debug, 'pool stats idle=4 busy=1'],
    [Level::Critical, 'database volume read-only'],
    [Level::Alert, 'ledger out of balance by 12.50'],
    [Level::Emergency, 'disk failure on /dev/sda'],
    [Level::Info, "batch summary:\nimported 120\nskipped 3"],  // the default formatter flattens the newlines
    [Level::Info, 'GET /health 200'],
];
$monolog = InstalledVersions::getPrettyVersion('monolog/monolog');

foreach ([SyslogUdpHandler::RFC5424e => 'rfc5424', SyslogUdpHandler::RFC3164 => 'rfc3164-pri'] as $rfc => $name) {
    $rfc3164 = $rfc === SyslogUdpHandler::RFC3164;
    $file = "$out/$name.log";
    @unlink($file);
    FileSocket::$file = $file;
    $loggers = [];
    foreach ($idents as [$ident, $facility]) {
        $handler = new SyslogUdpHandler('127.0.0.1', 514, $facility, Level::Debug, true, $ident, $rfc);
        $handler->setSocket(new FileSocket());
        $loggers[] = [$ident, new Logger('app', [$handler])];
    }

    $time = (new JsonSerializableDateTimeImmutable(true, new DateTimeZone('UTC')))->setTimestamp(1790812800);
    $seed = 9;
    $entries = [];
    $line = 1;
    for ($i = 0; $i < 75; $i++) {
        $seed = ($seed * 1103515245 + 12345) % 2147483648;
        $time = $time->modify('+' . (1 + $seed % 9000) . ' milliseconds');
        [$ident, $logger] = $loggers[$i % count($loggers)];
        [$level, $message] = $script[($i * 3) % count($script)];
        $logger->addRecord($level, $message, [], $time);

        // RFC 3164 has whole seconds and no zone (Monolog writes UTC); RFC 5424 has milliseconds and a zone.
        clearstatcache();
        $new = substr_count(file_get_contents($file), "\n") - ($line - 1);
        for ($k = 0; $k < $new; $k++) {
            $entries[] = ['line' => $line++, 'lines' => 1, 'level' => LEVELS[$level->getName()],
                          'time' => $rfc3164 ? $time->format('Y-m-d\TH:i:s') . '.000Z' : $time->format('Y-m-d\TH:i:s.v') . 'Z',
                          'zoned' => !$rfc3164, 'component' => $ident];
        }
    }

    $source = "monolog/monolog $monolog on PHP " . PHP_VERSION . ', SyslogUdpHandler(' . ($rfc3164 ? 'RFC3164' : 'RFC5424e')
        . ') with idents sshd/billing/cron/mailer/api, datagrams appended to a file one per line; the machine hostname '
        . 'gethostname() wrote is replaced with web-01; script syslog.php'
        . ($rfc3164 ? '; Monolog writes the day zero-padded (Oct 01) and in UTC' : '')
        . '; the default formatter flattens newlines, so every record is one line';
    file_put_contents("$out/$name.expected.json", json_encode(
        ['source' => $source, 'referenceDate' => '2026-10-01', 'entries' => $entries],
        JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");
}
