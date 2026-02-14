// Grafana Alloy Configuration for CloudLab Swarm
// This configuration collects Docker container logs and metrics
//
// This is a template file. Placeholders are replaced with actual values
// at container startup via sed substitution in docker-compose.yml.
// See alloy/.env.example for the required environment variables.

logging {
  level  = "info"
  format = "logfmt"
}

// Collect system metrics
prometheus.exporter.unix "system" {
  enable_collectors = [
    "cpu",
    "diskstats",
    "filesystem",
    "loadavg",
    "meminfo",
    "netdev",
    "stat",
    "time",
  ]
}

// Scrape system metrics
prometheus.scrape "system" {
  targets = prometheus.exporter.unix.system.targets
  forward_to = [prometheus.relabel.system.receiver]
}

// Add labels to system metrics
prometheus.relabel "system" {
  forward_to = [prometheus.remote_write.default.receiver]
  
  rule {
    source_labels = ["__name__"]
    target_label  = "job"
    replacement   = "system"
  }
}

// Discover Docker containers
discovery.docker "containers" {
  host = "unix:///var/run/docker.sock"
}

// Collect Docker container logs
loki.source.docker "containers" {
  host       = "unix:///var/run/docker.sock"
  targets    = discovery.docker.containers.targets
  forward_to = [loki.process.containers.receiver]
}

// Process and add labels to logs
loki.process "containers" {
  forward_to = [loki.write.default.receiver]

  // Extract JSON logs if present
  stage.json {
    expressions = {
      level = "level",
      msg   = "msg",
    }
  }

  // Add container labels
  stage.labels {
    values = {
      level = "",
    }
  }
}

// Configure Grafana Cloud Loki endpoint for logs
// Credentials are injected from environment variables at container startup
loki.write "default" {
  endpoint {
    url = "GRAFANA_CLOUD_LOGS_URL_PLACEHOLDER"

    basic_auth {
      username = "GRAFANA_CLOUD_LOGS_ID_PLACEHOLDER"
      password = "GRAFANA_CLOUD_API_KEY_PLACEHOLDER"
    }
  }
}

// Configure Grafana Cloud Prometheus endpoint for metrics
prometheus.remote_write "default" {
  endpoint {
    url = "GRAFANA_CLOUD_METRICS_URL_PLACEHOLDER"

    basic_auth {
      username = "GRAFANA_CLOUD_METRICS_ID_PLACEHOLDER"
      password = "GRAFANA_CLOUD_API_KEY_PLACEHOLDER"
    }
  }
}

// Alternative: For local testing without Grafana Cloud, use these configurations:
// 
// loki.write "local" {
//   endpoint {
//     url = "http://localhost:3100/loki/api/v1/push"
//   }
// }
//
// prometheus.remote_write "local" {
//   endpoint {
//     url = "http://localhost:9090/api/v1/write"
//   }
// }
