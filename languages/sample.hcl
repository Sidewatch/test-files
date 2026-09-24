# HCL (Nomad job): an API service with a health check and an update policy.
job "inventory-api" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel     = 1
    min_healthy_time = "30s"
    auto_revert      = true
  }

  group "api" {
    count = 3

    network {
      port "http" { to = 8080 }
    }

    service {
      name = "inventory-api"
      port = "http"
      check {
        type     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"
      config {
        image = "registry.example.com/inventory:1.4.0"
        ports = ["http"]
      }
      env {
        LOG_LEVEL = "info"
        DB_URL    = "${NOMAD_META_db_url}"
      }
      resources { cpu = 500, memory = 256 }
    }
  }
}
