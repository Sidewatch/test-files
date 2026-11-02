// A tiny program that writes to the unified log through os.Logger, for run.sh to read back with
// `log stream` and `log show`.
//
//   logfixture [count]      (default 60 messages, about 70 ms apart)
//
// Subsystem com.example.logfixture, three categories, every level from debug to fault, and one multi-line
// message.

import Foundation
import os

let subsystem = "com.example.logfixture"
let network = Logger(subsystem: subsystem, category: "network")
let database = Logger(subsystem: subsystem, category: "database")
let ui = Logger(subsystem: subsystem, category: "ui")
let count = CommandLine.arguments.dropFirst().first.flatMap { Int($0) } ?? 60

for i in 0..<count {
    let user = "user-\(1000 + i * 7)"
    switch i % 10 {
    case 0: network.notice("connected to api.example.com:443 in \(12 + i) ms")
    case 1: database.info("opened store orders.sqlite, \(300 + i) rows")
    case 2: ui.debug("layout pass took \(i % 9) ms")
    case 3: network.error("request to /v1/orders failed with status 503")
    case 4: database.fault("store is corrupt: page \(i) checksum mismatch")
    case 5: network.log("signed in \(user, privacy: .public)")
    case 6: database.warning("slow fetch: \(800 + i) ms")
    case 7: ui.critical("window controller missing for document \(i)")
    case 8: network.info("token for \(user) refreshed")
    default: database.notice("migration summary:\n  applied: 3\n  skipped: 1")
    }
    usleep(UInt32(20_000 + (i * 7919) % 90_000))
}
