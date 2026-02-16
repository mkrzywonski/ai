#!/usr/bin/env bash
set -euo pipefail

# Load secrets directly for the MCP child process because Codex may launch
# stdio MCP servers with a restricted environment.
secrets_file="${AI_SECRETS_FILE:-}"
if [ -z "$secrets_file" ]; then
    if [ -f "/home/netops/ai/secrets.env.gpg" ]; then
        secrets_file="/home/netops/ai/secrets.env.gpg"
    else
        secrets_file="$HOME/.secrets/ai.env.gpg"
    fi
fi

if [ ! -f "$secrets_file" ]; then
    echo "NetBox MCP launcher error: secrets file not found: $secrets_file" >&2
    exit 1
fi

set -a
eval "$(gpg -d -q "$secrets_file" 2>/dev/null)"
set +a

exec /opt/netbox-mcp-server/bin/netbox-mcp-server "$@"
