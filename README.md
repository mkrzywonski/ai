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
is encrypted to `secrets.env.gpg` automatically.

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
                    ├── gpg -d secrets.env.gpg → eval (secrets in memory)
                    ├── claude runs (MCP servers inherit env vars)
                    └── subshell exits → secrets gone
```

- Secrets live **only** in the AI tool's subshell process
- Your main shell **never** has secrets in its environment
- `secrets.env.gpg` is committed to git (encrypted, safe to share)
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

## File Reference

| File | Committed | Purpose |
|------|-----------|---------|
| `secrets.env.gpg` | Yes (encrypted) | GPG-encrypted secrets |
| `env.example` | Yes | Plaintext template showing expected variables |
| `scripts/ai-wrapper.sh` | Yes | Shell wrapper functions |
| `AGENTS.md` | Yes | Shared AI instructions (secrets rules, conventions) |
| `CLAUDE.md` | Yes | Claude-specific config (imports AGENTS.md) |
