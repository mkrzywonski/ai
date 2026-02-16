# NetBox MCP Server

Provides read-only access to NetBox (DCIM, IPAM, tenancy, etc.) via the
[netbox-mcp-server](https://github.com/netboxlabs/netbox-mcp-server) Python package.

## Prerequisites

- Python 3.11+ (`dnf install python3.11`)
- A NetBox instance with an API token

## Secrets

Add these to your encrypted secrets file (`ai-secrets-edit`):

```
NETBOX_URL=https://netbox.example.com
NETBOX_TOKEN=<your-api-token>
```

## Installation

Create a venv and install from GitHub:

```bash
mkdir -p ~/ai/mcp/netbox

python3.11 -m venv ~/ai/mcp/netbox
~/ai/mcp/netbox/bin/pip install git+https://github.com/netboxlabs/netbox-mcp-server.git
```

Verify the binary is in place:

```bash
~/ai/mcp/netbox/bin/netbox-mcp-server --help
```

## Launch Script

NetBox MCP needs `NETBOX_URL` and `NETBOX_TOKEN` in its environment. When
launched by Codex (which may not inherit all env vars), a wrapper script
handles decrypting secrets before exec'ing the server.

The launch script lives at `scripts/netbox-mcp-launch.sh` and is referenced
in `.mcp.json`.

## MCP Server Configuration (`mcp-servers.json`)

```json
{
  "netbox": {
    "command": "${HOME}/ai/scripts/netbox-mcp-launch.sh"
  }
}
```

The `claude` and `codex` wrappers expand `${HOME}` and generate `.mcp.json`
automatically at launch.

## Verify

Start Claude from the `~/ai` directory and ask it to query NetBox:

```
> List all prefixes with the tag "dhcp-migration-pending"
```

## Notes

- The MCP server is **read-only**. For write operations (creating/updating
  objects), use `curl` against the NetBox REST API.
- The package is not on PyPI — it must be installed from the GitHub repo.
