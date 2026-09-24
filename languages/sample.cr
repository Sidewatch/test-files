# Crystal: a typed HTTP-ish request log summariser.
require "json"

struct Hit
  include JSON::Serializable
  getter path : String
  getter status : Int32
  getter ms : Float64
end

class Summary
  @by_status = Hash(Int32, Int32).new(0)
  @slow = [] of Hit

  def add(hit : Hit) : Nil
    @by_status[hit.status] += 1
    @slow << hit if hit.ms > 500.0
  end

  def to_s(io : IO) : Nil
    @by_status.each { |code, n| io << code << ": " << n << '\n' }
    io << "slow: " << @slow.map(&.path).join(", ") unless @slow.empty?
  end
end

hits = Array(Hit).from_json(%([{"path":"/","status":200,"ms":12.5},{"path":"/api","status":500,"ms":812.0}]))
summary = Summary.new
hits.each { |h| summary.add(h) }
puts summary
