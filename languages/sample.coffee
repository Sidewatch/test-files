# A tiny event emitter and a class that uses it.
class Emitter
  constructor: -> @handlers = {}

  on: (event, fn) ->
    (@handlers[event] ?= []).push fn
    this

  emit: (event, args...) ->
    fn args... for fn in @handlers[event] ? []
    return

class Counter extends Emitter
  constructor: (@limit = 3) ->
    super()
    @count = 0

  tick: =>
    @count += 1
    @emit 'tick', @count
    @emit 'done' if @count >= @limit

counter = new Counter 2
counter
  .on 'tick', (n) -> console.log "tick #{n}"
  .on 'done', -> console.log 'finished'

counter.tick() for [1..2]
squares = (x * x for x in [1..5] when x % 2 is 1)
