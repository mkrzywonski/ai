# Grafana MCP Server

Provides access to Grafana dashboards, datasources, alerts, Prometheus/Loki
queries, and more via the [mcp-grafana](https://github.com/grafana/mcp-grafana)
Go binary.

## Prerequisites

- A Grafana instance with an API key (Service Account token)

## Secrets

Add these to your encrypted secrets file (`ai-secrets-edit`):

```
GRAFANA_URL=https://grafana.example.com
GRAFANA_API_KEY=<your-service-account-token>
```

## Installation

Download the prebuilt binary from GitHub releases:

```bash
sudo mkdir -p /opt/mcp-grafana
sudo chown $USER: /opt/mcp-grafana

# Check https://github.com/grafana/mcp-grafana/releases for latest version
VERSION=v0.10.0
curl -L "https://github.com/grafana/mcp-grafana/releases/download/${VERSION}/mcp-grafana_linux_amd64.tar.gz" \
  | tar xz -C /opt/mcp-grafana
chmod +x /opt/mcp-grafana/mcp-grafana
```

Verify:

```bash
/opt/mcp-grafana/mcp-grafana --version
```

## Claude Code Configuration (`.mcp.json`)

```json
{
  "grafana": {
    "command": "/opt/mcp-grafana/mcp-grafana",
    "env": {
      "GRAFANA_URL": "${GRAFANA_URL}",
      "GRAFANA_API_KEY": "${GRAFANA_API_KEY}"
    }
  }
}
```

## Verify

Start Claude from the `~/ai` directory and ask:

```
> Can you see any dashboards?
```

## Capabilities

- Search and browse dashboards and folders
- Read dashboard panels, queries, and variables
- Query Prometheus and Loki datasources directly
- List and inspect alert rules and contact points
- Render dashboard panels as PNG images (requires Image Renderer plugin)
- Create and manage incidents (if Grafana Incident is enabled)

## Notes

- The binary is a single static Go executable — no runtime dependencies.
- Env vars are passed via `${VAR}` expansion in `.mcp.json`, which Claude
  Code resolves from the subshell environment at startup.
