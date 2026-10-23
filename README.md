# ai-infra

Central source of truth for my own AI tooling config (Claude Code).

- `skills/` own skills, symlinked into each tool's skills dir
- `agents/` own agents
- `bin/` scripts (`claude-as`, statusline)
- `manifest/` third-party skills and where they come from (not tracked here)
- `shell/` zsh helpers sourced from `.zshrc`

Secrets live outside this repo in `~/.config/ai/secrets.env`.
Installer-managed things (SuperClaude, plugins, `~/.agents` skills) are not tracked.
