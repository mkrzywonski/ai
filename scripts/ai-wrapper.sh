#!/usr/bin/env bash
# AI Tool Wrapper Functions
#
# Source this file from ~/.bashrc:
#   source ~/ai/scripts/ai-wrapper.sh
#
# These wrappers decrypt secrets.env.gpg into a subshell before launching
# the AI tool. When the tool exits, the subshell exits and secrets are gone.
# Your main shell never has secrets in its environment.

AI_SECRETS_FILE="${AI_SECRETS_FILE:-$HOME/ai/secrets.env.gpg}"

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
        command codex "$@"
    )
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
        # Start from template if it exists
        local template_dir
        template_dir="$(dirname "$gpg_file")"
        if [ -f "$template_dir/env.example" ]; then
            cp "$template_dir/env.example" "$tmp_file"
        else
            echo "# AI Tool Secrets — fill in values and save" > "$tmp_file"
        fi
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
