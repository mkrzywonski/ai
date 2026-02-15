# Network Administration AI Assistant

## Session Startup

At the start of every session, check for these files and act accordingly:

1. **`PROJECT.md`** — If it exists, read it to understand the project's goals, requirements, and scope. If it does NOT exist, begin the discovery process (see below).
2. **`TODO.md`** — If it exists, read it and summarize current task status to the user.
3. **`CHANGELOG.md`** — If it exists, skim recent entries for context on what was done last.

## Project Discovery and Planning (PROJECT.md)

`PROJECT.md` defines what the project is, why it exists, and what success looks like.

### If PROJECT.md does not exist

Before writing any code or making changes, engage the user in discovery:

1. **Explore the concept** — Ask what problem they're solving, what they're trying to build, or what they want to automate. Don't assume — ask open-ended questions.
2. **Ask clarifying questions** — Dig into scope, constraints, target systems, expected inputs/outputs. Ask about edge cases and what "done" looks like.
3. **Identify requirements** — Distinguish must-haves from nice-to-haves. Note any technical constraints (OS, language, existing systems to integrate with).
4. **Define outcomes** — What does success look like? How will they know it's working?
5. **Write PROJECT.md** — Once the picture is clear, create `PROJECT.md` with the structure below and confirm it with the user before proceeding to implementation.

### If PROJECT.md exists

Read it, confirm with the user that it's still accurate, and proceed with work guided by it. Update it if requirements change during the project.

### PROJECT.md format

```markdown
# Project Name

## Overview
One or two sentences describing what this project does and why.

## Goals
- Primary goal
- Secondary goal

## Requirements
### Must Have
- Requirement 1
- Requirement 2

### Nice to Have
- Optional feature

## Scope
What's in scope and what's explicitly out of scope.

## Technical Context
- Target systems, platforms, languages
- Existing infrastructure to integrate with
- Constraints and dependencies

## Success Criteria
How do we know this project is done and working?
```

Adjust the format to fit the project — not every section is needed for small tasks.
For quick one-off tasks, the user may skip PROJECT.md entirely. Use judgment — don't
force a planning process for "add a cron job" or "fix this script."

## Secrets Management

Secrets are GPG-encrypted in `~/.secrets/ai.env.gpg` and decrypted into
environment variables only within the AI tool's subshell. They are NOT in
the user's normal shell environment. The secrets file is shared across all
projects — it lives in the home directory, not in the project.

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

## Task Tracking (TODO.md)

Maintain a `TODO.md` in the project root to track tasks across sessions and tools.
The user switches between Claude Code and Codex (and may hit rate limits mid-task),
so this file is critical for picking up where the last session left off.

- At the **start of a session**, read `TODO.md` (if it exists) and summarize the current state to the user
- At the **end of a session** or before a natural stopping point, update `TODO.md` with current status
- If `TODO.md` does not exist, create it when there are tasks worth tracking
- Keep it in this format:
  ```markdown
  # TODO

  ## In Progress
  - [ ] Task description — brief context on current state and next step

  ## Up Next
  - [ ] Task description
  - [ ] Task description

  ## Blocked
  - [ ] Task description — what's blocking it

  ## Done
  - [x] Task description (YYYY-MM-DD)
  ```
- Move tasks between sections as status changes
- Include enough context on in-progress tasks that a **different AI tool** could pick up the work
- When a task is done, move it to Done with the completion date
- Periodically clean out old Done items to keep the file scannable

## Changelog

Maintain a `CHANGELOG.md` in the project root to track significant work across sessions.
This enables continuity when switching between AI tools or resuming later.

- After completing a significant task or set of changes, add a dated entry to `CHANGELOG.md`
- If `CHANGELOG.md` does not exist, create it
- Entries go at the top (reverse chronological order)
- Format:
  ```markdown
  ## YYYY-MM-DD — Brief description
  - What was done
  - What was changed
  - Key decisions made
  ```
- Keep entries concise — enough to resume context, not a verbose narrative
- At the start of a session, read `CHANGELOG.md` (if it exists) to understand recent work
