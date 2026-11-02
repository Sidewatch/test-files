# Ruby's standard Logger with its default Formatter, with the answers taken from each call.
#
#   ruby logger.rb <out>      writes <out>/logger.log, logger-progname.log and their .expected.json
#
# Time.now is replaced by a seeded clock from 2026-10-01T00:00:00Z, so the output is the same on every run
# apart from the process ID each line carries. After each call the new lines in the file are counted, which is
# how logged exceptions (message, class, backtrace) get their line counts.
require 'logger'
require 'json'

OUT = ARGV[0]

$clock = Time.utc(2026, 10, 1, 0, 0, 0).to_r
$seed = 5
# Moves the clock on 1 us to 2.5 s.
def tick
  $seed = ($seed * 1103515245 + 12345) % 2147483648
  $clock += Rational(1 + $seed % 2_500_000, 1_000_000)
end

class << Time
  def now
    Time.at($clock).utc
  end
end

def stamp
  Time.at($clock).utc.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
end

# Logger::UNKNOWN ("A, ... ANY") answers fatal.
LEVELS = { Logger::DEBUG => 'debug', Logger::INFO => 'info', Logger::WARN => 'warning', Logger::ERROR => 'error',
           Logger::FATAL => 'fatal', Logger::UNKNOWN => 'fatal' }.freeze

# Writes <name>.log through a Logger and <name>.expected.json from the calls. With `header`, the Logger opens the
# path itself and writes its "# Logfile created on" line first, which belongs to no entry.
def fixture(name, source, header)
  file = File.join(OUT, name + '.log')
  File.delete(file) if File.exist?(file)
  logger = header ? Logger.new(file) : Logger.new(File.open(file, 'w').tap { |f| f.sync = true })
  logger.level = Logger::DEBUG
  offset = File.size(file)
  line = 1 + File.read(file).count("\n")
  entries = []
  note = lambda do |severity, component|
    written = File.binread(file)[offset..]
    lines = written.count("\n")
    entries << { line: line, lines: lines, level: LEVELS[severity], time: stamp, zoned: false, component: component }
    line += lines
    offset += written.bytesize
  end
  yield logger, note
  logger.close
  File.write(File.join(OUT, name + '.expected.json'),
             JSON.pretty_generate(source: source, referenceDate: '2026-10-01', entries: entries) + "\n")
end

MESSAGES = [
  [Logger::INFO, 'Booting worker pool size=5'], [Logger::DEBUG, 'loaded 31 settings from config/app.yml'],
  [Logger::INFO, 'processed job 5521 in 182ms'], [Logger::WARN, 'queue latency 4.2s above threshold 2s'],
  [Logger::ERROR, 'SMTP 451 from mail.example.com, will retry'], [Logger::INFO, 'user-1042 exported 12 reports'],
  [Logger::FATAL, 'cannot open /var/lib/app/state.db: Permission denied'], [Logger::UNKNOWN, 'shutdown requested by signal TERM'],
  [Logger::DEBUG, "payload:\n  {\"id\": 7731,\n   \"items\": 3}"], [Logger::INFO, 'heartbeat ok'],
].freeze

def parse_quantity
  Integer('forty-two')
end

source = "Ruby #{RUBY_VERSION} stdlib Logger (logger.rb #{Logger::VERSION}) default Formatter, simulated clock, TZ=UTC; " \
         'script logger.rb'

fixture('logger', source + '; Logger.new(path), so the first line is the "# Logfile created on" header (not an entry); ' \
                  'no progname', true) do |logger, note|
  80.times do |i|
    tick
    if i % 13 == 7
      begin
        parse_quantity
      rescue ArgumentError => e
        logger.error(e)
      end
      note.(Logger::ERROR, nil)
    else
      severity, message = MESSAGES[i % MESSAGES.size]
      logger.add(severity, message)
      note.(severity, nil)
    end
  end
end

fixture('logger-progname', source + '; Logger.new(io, progname: "mailer"), some calls pass their own progname', false) do |logger, note|
  logger.progname = 'mailer'
  70.times do |i|
    tick
    severity, message = MESSAGES[(i * 3) % MESSAGES.size]
    if i % 11 == 4
      begin
        parse_quantity
      rescue ArgumentError => e
        logger.add(Logger::ERROR, e, 'importer')
      end
      note.(Logger::ERROR, 'importer')
    elsif i % 4 == 1
      logger.add(severity, message, 'scheduler')
      note.(severity, 'scheduler')
    else
      logger.add(severity, message)
      note.(severity, 'mailer')
    end
  end
end
