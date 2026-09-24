;; Fennel: a small state machine for a traffic light, compiled to Lua.
(local states {:green :yellow :yellow :red :red :green})
(local durations {:green 30 :yellow 5 :red 20})

(fn next-state [current]
  "The state after `current`."
  (or (. states current) :red))

(fn make-light [initial]
  (var state (or initial :red))
  (var elapsed 0)
  {:tick (fn [seconds]
           (set elapsed (+ elapsed seconds))
           (when (>= elapsed (. durations state))
             (set state (next-state state))
             (set elapsed 0))
           state)
   :state (fn [] state)})

(let [light (make-light :green)]
  (for [i 1 40]
    (let [s (light.tick 1)]
      (when (= i 31) (print (.. "after 31s: " (tostring s))))))
  (print (string.format "final: %s" (light.state))))
