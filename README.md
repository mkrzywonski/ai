# AI Network Administration Workflow

Configuration repo for AI-assisted network administration. Secrets are
GPG-encrypted and only decrypted into memory when an AI tool is running.

## Setup on a New System

### 1. Clone this repo

```bash
git clone <your-repo-url> ~/ai
```

### 2. Add wrapper functions to your shell

Add this line to `~/.bashrc`:

```bash
source ~/ai/scripts/ai-wrapper.sh
```

Then reload:

```bash
source ~/.bashrc
```

This gives you:

| Command | What it does |
|---------|-------------|
| `claude` | Decrypts secrets into a subshell, runs Claude Code |
| `codex` | Decrypts secrets into a subshell, runs Codex CLI |
| `ai-secrets-edit` | Decrypt, edit, and re-encrypt secrets |
| `ai-secrets-check` | Show which secrets are set (without showing values) |
| `ai-init` | Set up current directory with AI config symlinks |

### 3. Generate a GPG keypair

If this is a new machine that doesn't have the project GPG key yet:

**Option A — Generate a new keypair (first-time setup):**

```bash
gpg --batch --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: AI Secrets
Name-Email: ai-secrets@localhost
Expire-Date: 0
%commit
EOF
```

**Option B — Import an existing keypair from another machine:**

On the old machine, export:

```bash
gpg --export-secret-keys "ai-secrets@localhost" > /tmp/ai-secrets.key
# Transfer ai-secrets.key to the new machine securely (scp, USB, etc.)
```

On the new machine, import:

```bash
gpg --import /tmp/ai-secrets.key
shred -u /tmp/ai-secrets.key
```

Verify the key is available:

```bash
gpg --list-keys "ai-secrets@localhost"
```

### 4. Create or update the encrypted secrets file

```bash
ai-secrets-edit
```

This opens your editor with the current secrets (or the `env.example` template
if no secrets file exists yet). Fill in your values, save, and close. The file
is encrypted to `~/.secrets/secrets.env.gpg` automatically.

Run `ai-secrets-edit` from the project directory so it picks up `env.example`
as a starting template.

The plaintext is written to `/dev/shm/` (RAM-backed tmpfs) during editing and
shredded when done. No plaintext touches disk.

### 5. Verify

```bash
# Check which secrets are configured
ai-secrets-check

# Test Claude (secrets are only in this subshell)
claude
```

## How It Works

```
~/.bashrc
  └── source ~/ai/scripts/ai-wrapper.sh
        └── claude()  ← wrapper function
              └── ( subshell )
                    ├── gpg -d ~/.secrets/secrets.env.gpg → eval (secrets in memory)
                    ├── claude runs (MCP servers inherit env vars)
                    └── subshell exits → secrets gone
```

- Secrets live in `~/.secrets/secrets.env.gpg` — shared across all projects
- Secrets are decrypted **only** into the AI tool's subshell process
- Your main shell **never** has secrets in its environment
- Only the GPG private key needs to be transferred between machines

## Editing Secrets

```bash
# Edit secrets (decrypts, opens editor, re-encrypts)
ai-secrets-edit

# Check what's set
ai-secrets-check
```

After editing, restart the AI tool for changes to take effect.

## Moving to a New Machine

1. Clone this repo
2. Add `source ~/ai/scripts/ai-wrapper.sh` to `~/.bashrc`
3. Import your GPG key (`gpg --import`)
4. Run `ai-secrets-check` to verify
5. Done — `claude` and `codex` commands will decrypt secrets on the fly

## Starting a New Project

From any directory:

```bash
mkdir ~/projects/new-thing && cd ~/projects/new-thing
git init
ai-init
```

This creates symlinks to the shared AI config in `~/ai` and seeds a `.gitignore`.
Start `claude` or `codex` and the AI will walk you through creating a `PROJECT.md`.

The symlinked files (AGENTS.md, CLAUDE.md, .mcp.json) are gitignored in the new
project so they don't get committed — they always point back to `~/ai`.

## MCP Servers

MCP (Model Context Protocol) servers give AI tools direct API access to your
infrastructure. They are configured in `.mcp.json` for Claude Code and synced
to Codex automatically by the wrapper script.

### Installed

| Server | Source | Install Location | Setup Guide |
|--------|--------|-----------------|-------------|
| NetBox | [netboxlabs/netbox-mcp-server](https://github.com/netboxlabs/netbox-mcp-server) | `~/ai/mcp/netbox/` (Python venv) | [docs/mcp-netbox.md](docs/mcp-netbox.md) |
| Grafana | [grafana/mcp-grafana](https://github.com/grafana/mcp-grafana) | `~/ai/mcp/grafana/` (Go binary) | [docs/mcp-grafana.md](docs/mcp-grafana.md) |

### Planned / Not Yet Installed

| Server | Notes |
|--------|-------|
| InfluxDB v1 | [GreenScreen410/influxdb-v1-mcp](https://github.com/GreenScreen410/influxdb-v1-mcp) — Python, needs local clone |
| Juniper | [Juniper/junos-mcp-server](https://github.com/Juniper/junos-mcp-server) — Python, needs `devices.json` config |
| GitHub | [@github/mcp-server](https://github.com/github/github-mcp-server) — via npx |

### No MCP Server Available

These are queried via `curl` or SSH, documented in `AGENTS.md`:

- **SolarWinds Orion** — REST API with SWQL queries
- **Ruckus SmartZone** — REST API
- **Cisco** — SSH

### Adding a New MCP Server

1. Install the server binary/package (see individual setup guides)
2. Add an entry to `.mcp.json` with `${VAR}` references for secrets
3. Add the required env vars to `env.example` (names only, no values)
4. Run `ai-secrets-edit` to add the actual secret values
5. Restart the AI tool
6. Create a setup guide in `docs/mcp-<name>.md`

## File Reference

| File | Committed | Purpose |
|------|-----------|---------|
| `~/.secrets/secrets.env.gpg` | No (in home dir) | GPG-encrypted secrets, shared across projects |
| `env.example` | Yes | Plaintext template showing expected variables |
| `scripts/ai-wrapper.sh` | Yes | Shell wrapper functions |
| `AGENTS.md` | Yes | Shared AI instructions (secrets rules, conventions) |
| `CLAUDE.md` | Yes | Claude-specific config (imports AGENTS.md) |
| `.mcp.json` | Yes | MCP server definitions for Claude Code |
| `docs/mcp-*.md` | Yes | Per-server installation and setup guides |
