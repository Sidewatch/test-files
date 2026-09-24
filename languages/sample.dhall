-- Dhall: a typed configuration with defaults and a list built by a function.
let Environment = < Dev | Staging | Prod >

let Service =
      { Type = { name : Text, replicas : Natural, env : Environment, ports : List Natural }
      , default = { replicas = 2, env = Environment.Dev, ports = [ 8080 ] }
      }

let mkService =
      \(name : Text) -> \(env : Environment) ->
        Service::{ name, env, replicas = merge { Dev = 1, Staging = 2, Prod = 6 } env }

let services =
      [ mkService "api" Environment.Prod
      , mkService "worker" Environment.Staging // { ports = [] : List Natural }
      ]

in  { services, region = "eu-west-1", debug = False }
