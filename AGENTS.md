# Network Administration AI Assistant

## Secrets Management

Secrets are GPG-encrypted in `secrets.env.gpg` and decrypted into environment
variables only within the AI tool's subshell. They are NOT in the user's
normal shell environment.

### Rules — READ THESE CAREFULLY

- **NEVER** echo, print, cat, or display environment variable values containing secrets
- **NEVER** run `env`, `printenv`, `set`, or `export -p` to dump all environment variables
- **NEVER** pass secret values as command-line arguments (visible in process lists)
- **NEVER** write secrets to files, logs, or command output
- **NEVER** include secrets in code, configs, or commit messages
- When debugging API auth failures, check HTTP status codes and error messages — not token values
- To verify a secret is set without exposing it:
  ```bash
  [ -n "$VAR_NAME" ] && echo "VAR_NAME is set (${#VAR_NAME} chars)" || echo "VAR_NAME is NOT set"
  ```

### Adding New Secrets

If a task requires a new secret (API key, token, password, etc.):

1. **Do NOT handle it ad-hoc** (don't ask the user to paste it, don't put it in a file, don't set it with `export`)
2. **Ask the user to add it to the encrypted secrets file** by running:
   ```
   ai-secrets-edit
   ```
3. Tell the user what variable name to use (e.g., `NEW_SERVICE_TOKEN=`)
4. After they save, they must restart the AI tool for the new variable to be available
5. Update `env.example` in the repo to include the new variable name (no value) as a template for future setups

### Available Secrets

See `env.example` for the list of expected environment variables and their purposes.
Run `ai-secrets-check` to see which secrets are currently set.
