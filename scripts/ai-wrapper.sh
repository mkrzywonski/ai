#!/usr/bin/env bash
# AI Tool Wrapper Functions
#
# Source this file from ~/.bashrc:
#   source ~/ai/scripts/ai-wrapper.sh
#
# These wrappers decrypt secrets.env.gpg into a subshell before launching
# the AI tool. When the tool exits, the subshell exits and secrets are gone.
# Your main shell never has secrets in its environment.

# Secrets file selection (in priority order):
# 1) Explicit AI_SECRETS_FILE env override
# 2) Project-local secrets file for this repo
# 3) Shared per-user secrets file in ~/.secrets
if [ -z "${AI_SECRETS_FILE:-}" ]; then
    if [ -f "./secrets.env.gpg" ]; then
        AI_SECRETS_FILE="./secrets.env.gpg"
    else
        AI_SECRETS_FILE="$HOME/.secrets/secrets.env.gpg"
    fi
fi

_ai_load_secrets() {
    if [ ! -f "$AI_SECRETS_FILE" ]; then
        echo "WARNING: Secrets file not found: $AI_SECRETS_FILE" >&2
        echo "Run 'ai-secrets-edit' to create it, or set AI_SECRETS_FILE." >&2
        return 1
    fi
    set -a
    eval "$(gpg -d -q "$AI_SECRETS_FILE" 2>/dev/null)"
    set +a
}

claude() {
    (
        _ai_load_secrets || return 1
        command claude "$@"
    )
}

codex() {
    (
        _ai_load_secrets || return 1
        _ai_sync_codex_mcp
        command codex "$@"
    )
}

# Ensure Codex has MCP servers from local .mcp.json.
# This keeps per-project MCP config in one file while Codex stores servers globally.
_ai_sync_codex_mcp() {
    local mcp_file=".mcp.json"
    local entry name transport server_cmd url bearer_env
    local env_key env_val
    local -a server_args
    local -a add_env_opts

    [ -f "$mcp_file" ] || return 0

    if ! command -v jq >/dev/null 2>&1; then
        echo "WARNING: jq not found; skipping Codex MCP sync from $mcp_file" >&2
        return 0
    fi

    while IFS= read -r entry; do
        name=$(printf '%s' "$entry" | base64 -d | jq -r '.key')
        transport=$(printf '%s' "$entry" | base64 -d | jq -r '
            if (.value.command // "") != "" then "stdio"
            elif (.value.url // "") != "" then "http"
            else "unknown"
            end
        ')

        if command codex mcp get "$name" >/dev/null 2>&1; then
            continue
        fi

        if [ "$transport" = "stdio" ]; then
            server_cmd=$(printf '%s' "$entry" | base64 -d | jq -r '.value.command // empty')
            if [ -z "$server_cmd" ]; then
                echo "WARNING: Skipping MCP server '$name' (missing command)" >&2
                continue
            fi

            mapfile -t server_args < <(printf '%s' "$entry" | base64 -d | jq -r '.value.args[]?')
            add_env_opts=()
            while IFS=$'\t' read -r env_key env_val; do
                [ -n "$env_key" ] || continue
                # Claude-style placeholders (e.g. ${NETBOX_URL}) should be inherited from
                # the current shell, not stored literally in Codex global MCP config.
                if [[ "$env_val" =~ ^\$\{[A-Za-z_][A-Za-z0-9_]*\}$ ]]; then
                    continue
                fi
                add_env_opts+=(--env "${env_key}=${env_val}")
            done < <(printf '%s' "$entry" | base64 -d | jq -r '.value.env // {} | to_entries[] | [.key, .value] | @tsv')

            if [ "${#server_args[@]}" -gt 0 ]; then
                command codex mcp add "$name" "${add_env_opts[@]}" -- "$server_cmd" "${server_args[@]}" >/dev/null 2>&1 \
                    || echo "WARNING: Failed to add Codex MCP server '$name'" >&2
            else
                command codex mcp add "$name" "${add_env_opts[@]}" -- "$server_cmd" >/dev/null 2>&1 \
                    || echo "WARNING: Failed to add Codex MCP server '$name'" >&2
            fi
            continue
        fi

        if [ "$transport" = "http" ]; then
            url=$(printf '%s' "$entry" | base64 -d | jq -r '.value.url // empty')
            bearer_env=$(printf '%s' "$entry" | base64 -d | jq -r '.value.bearerTokenEnvVar // empty')
            if [ -z "$url" ]; then
                echo "WARNING: Skipping MCP server '$name' (missing url)" >&2
                continue
            fi

            if [ -n "$bearer_env" ]; then
                command codex mcp add "$name" --url "$url" --bearer-token-env-var "$bearer_env" >/dev/null 2>&1 \
                    || echo "WARNING: Failed to add Codex MCP server '$name'" >&2
            else
                command codex mcp add "$name" --url "$url" >/dev/null 2>&1 \
                    || echo "WARNING: Failed to add Codex MCP server '$name'" >&2
            fi
            continue
        fi

        echo "WARNING: Skipping MCP server '$name' (unsupported .mcp.json entry)" >&2
    done < <(jq -r '.mcpServers // {} | to_entries[] | @base64' "$mcp_file")
}

# Decrypt, open in editor, re-encrypt
ai-secrets-edit() {
    local gpg_file="$AI_SECRETS_FILE"
    local gpg_recipient="ai-secrets@localhost"
    local tmp_file
    tmp_file=$(mktemp /dev/shm/secrets.XXXXXX.env)
    trap 'shred -u "$tmp_file" 2>/dev/null' EXIT

    if [ -f "$gpg_file" ]; then
        gpg -d -q "$gpg_file" > "$tmp_file" 2>/dev/null
    else
        # Start from template if one exists in current directory
        if [ -f "env.example" ]; then
            cp "env.example" "$tmp_file"
        else
            echo "# AI Tool Secrets — fill in values and save" > "$tmp_file"
        fi
        mkdir -p "$(dirname "$gpg_file")"
    fi

    "${EDITOR:-vi}" "$tmp_file"

    if [ -s "$tmp_file" ]; then
        gpg -e -r "$gpg_recipient" --yes -o "$gpg_file" "$tmp_file"
        echo "Secrets encrypted to $gpg_file"
    else
        echo "Empty file — secrets not updated."
    fi
}

# Check which secrets are set (without showing values)
ai-secrets-check() {
    (
        _ai_load_secrets || return 1
        echo "=== Secret Status ==="
        while IFS='=' read -r key _; do
            # Skip comments and blank lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            key=$(echo "$key" | xargs)  # trim whitespace
            val="${!key}"
            if [ -n "$val" ]; then
                echo "  [SET]     $key (${#val} chars)"
            else
                echo "  [MISSING] $key"
            fi
        done < <(gpg -d -q "$AI_SECRETS_FILE" 2>/dev/null)
    )
}
