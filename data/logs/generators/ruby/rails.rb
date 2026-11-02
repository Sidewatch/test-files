# A Rails production.log, written by Ruby's Logger, with the answers taken from each call.
#
#   ruby rails.rb <out>      writes <out>/production.log and production.expected.json
#
# Rails itself is not installed here. The log is built from what Rails is made of: Logger with Logger::Formatter
# (what config/environments/production.rb sets), a request-id tag in front of every line as
# ActiveSupport::TaggedLogging writes it, and request lines as the Rails guides show them:
#   https://guides.rubyonrails.org/debugging_rails_applications.html
#   https://guides.rubyonrails.org/action_controller_overview.html
# Time.now is a seeded clock from 2026-10-01T00:00:00Z, so the output is the same on every run apart from the
# process ID each line carries.
require 'logger'
require 'json'

OUT = ARGV[0]

$clock = Time.utc(2026, 10, 1, 0, 0, 0).to_r
$seed = 17
# Moves the clock on lo to hi microseconds.
def tick(lo, hi)
  $seed = ($seed * 1103515245 + 12345) % 2147483648
  $clock += Rational(lo + $seed % (hi - lo), 1_000_000)
end

class << Time
  def now
    Time.at($clock).utc
  end
end

LEVELS = { Logger::DEBUG => 'debug', Logger::INFO => 'info', Logger::WARN => 'warning', Logger::ERROR => 'error',
           Logger::FATAL => 'fatal' }.freeze

file = File.join(OUT, 'production.log')
io = File.open(file, 'w')
io.sync = true
log = Logger.new(io)
log.formatter = Logger::Formatter.new
entries = []
line = 1
offset = 0

# Logs `message` with every one of its lines tagged, as TaggedLogging does, and notes the answer. The tag is
# not a component, so the answer has none.
emit = lambda do |severity, tag, message|
  log.add(severity, message.split("\n", -1).map { |text| "[#{tag}] #{text}" }.join("\n"))
  written = File.binread(file)[offset..]
  lines = written.count("\n")
  entries << { line: line, lines: lines, level: LEVELS[severity], time: Time.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
               zoned: false, component: nil }
  line += lines
  offset += written.bytesize
end

# [outcome, verb, path, controller action, format, parameters]
REQUESTS = [
  [:ok, 'GET', '/articles', 'ArticlesController#index', 'HTML', nil],
  [:ok, 'GET', '/articles/42', 'ArticlesController#show', 'HTML', '{"id"=>"42"}'],
  [:redirect, 'POST', '/articles', 'ArticlesController#create', 'HTML',
   '{"authenticity_token"=>"[FILTERED]", "article"=>{"title"=>"Hello", "body"=>"First post"}, "commit"=>"Create Article"}'],
  [:not_found, 'GET', '/wp-login.php', nil, nil, nil],
  [:error, 'GET', '/reports/monthly', 'ReportsController#show', 'HTML', '{"id"=>"monthly"}'],
  [:unprocessable, 'PATCH', '/articles/42', 'ArticlesController#update', 'TURBO_STREAM',
   '{"authenticity_token"=>"[FILTERED]", "article"=>{"title"=>""}, "id"=>"42"}'],
  [:ok, 'GET', '/api/orders/1042', 'Api::OrdersController#show', 'JSON', '{"id"=>"1042"}'],
].freeze
CLIENTS = %w[203.0.113.17 198.51.100.23 192.0.2.44 2001:db8::1f].freeze
ROUTING_TRACE = [
  "actionpack (7.2.1) lib/action_dispatch/middleware/debug_exceptions.rb:33:in `call'",
  "actionpack (7.2.1) lib/action_dispatch/middleware/show_exceptions.rb:31:in `call'",
  "railties (7.2.1) lib/rails/rack/logger.rb:41:in `call_app'",
].freeze

20.times do |i|
  outcome, verb, path, action, response_format, params = REQUESTS[i % REQUESTS.size]
  tag = format('%08x-%04x-4%03x-8%03x-%012x', 0x1f3a5c00 + i * 977, i * 31, i, i * 7, 0xabc000 + i)
  tick(200_000, 9_000_000)
  emit.(Logger::INFO, tag, "Started #{verb} \"#{path}\" for #{CLIENTS[i % 4]} at #{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}")

  if outcome == :not_found
    tick(300, 2000)
    emit.(Logger::FATAL, tag, "  \nActionController::RoutingError (No route matches [GET] \"#{path}\"):\n  \n" +
                              ROUTING_TRACE.join("\n"))
    next
  end

  tick(300, 2000)
  emit.(Logger::INFO, tag, "Processing by #{action} as #{response_format}")
  if params
    tick(100, 900)
    emit.(Logger::INFO, tag, "  Parameters: #{params}")
  end
  if i % 5 == 1
    tick(100, 900)
    emit.(Logger::DEBUG, tag, '  Article Load (0.4ms)  SELECT "articles".* FROM "articles" WHERE "articles"."id" = $1 ' \
                              'LIMIT $2  [["id", 42], ["LIMIT", 1]]')
  end

  case outcome
  when :ok
    tick(1000, 20_000) # the view time passes for JSON too; only HTML logs the render
    unless response_format == 'JSON'
      emit.(Logger::INFO, tag, "  Rendered #{path.split('/')[1]}/index.html.erb within layouts/application " \
                               '(Duration: 4.2ms | GC: 0.0ms)')
    end
    tick(1000, 9000)
    emit.(Logger::INFO, tag, 'Completed 200 OK in 14ms (Views: 6.1ms | ActiveRecord: 1.9ms (2 queries, 0 cached) | GC: 0.3ms)')
  when :redirect
    tick(1000, 9000)
    emit.(Logger::INFO, tag, 'Redirected to https://www.example.com/articles/43')
    tick(1000, 9000)
    emit.(Logger::INFO, tag, 'Completed 302 Found in 21ms (ActiveRecord: 4.0ms (3 queries, 0 cached) | GC: 0.0ms)')
  when :unprocessable
    tick(1000, 9000)
    emit.(Logger::WARN, tag, "Can't verify CSRF token authenticity.")
    tick(1000, 9000)
    emit.(Logger::INFO, tag, 'Completed 422 Unprocessable Content in 3ms (ActiveRecord: 0.0ms | GC: 0.0ms)')
  when :error
    tick(1000, 9000)
    emit.(Logger::ERROR, tag, 'Report generation failed: upstream api.example.com returned 502')
    tick(1000, 9000)
    emit.(Logger::INFO, tag, 'Completed 500 Internal Server Error in 33ms (ActiveRecord: 2.2ms (1 query, 0 cached) | GC: 0.0ms)')
    tick(300, 900)
    emit.(Logger::FATAL, tag, "  \nReportsController::UpstreamError (upstream api.example.com returned 502):\n  \n" \
                              "app/services/report_builder.rb:27:in `fetch'\napp/controllers/reports_controller.rb:9:in `show'")
  end
end
io.close

File.write(File.join(OUT, 'production.expected.json'), JSON.pretty_generate(
  source: "Ruby #{RUBY_VERSION} stdlib Logger with Logger::Formatter (as Rails' production.rb configures), request-id " \
          'tags prefixed to every line the way ActiveSupport::TaggedLogging does, request lines from ' \
          'https://guides.rubyonrails.org/debugging_rails_applications.html and ' \
          'https://guides.rubyonrails.org/action_controller_overview.html ; simulated clock, TZ=UTC; script rails.rb ' \
          '(Rails itself is not installed)',
  referenceDate: '2026-10-01', entries: entries
) + "\n")
