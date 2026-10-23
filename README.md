# ai-infra

Central source of truth for my own AI tooling config (Claude Code).

- `skills/` own skills, symlinked into `~/.claude/skills`
- `agents/` own agents, symlinked into `~/.claude/agents`
- `bin/` scripts (statusline)
- `manifest/` third-party skills and where they come from (not tracked here)
- `shell/` zsh helpers (`claude-as`, `sbx-as`) sourced from `.zshrc`
- `CLAUDE.md` global instructions, symlinked to `~/.claude/CLAUDE.md`
- `settings.example.json` key-free copy of `~/.claude/settings.json`

## Config and secrets (both gitignored)

- `config.env` base URL and model names. Names listed in `secrets.env.example`.
- `secrets/secrets.env` tokens only (`chmod 600`). Names listed in `secrets.env.example`.

Edit them by hand. Changes apply in a new terminal or after `source ~/.zshrc`.
Installer-managed things (SuperClaude, plugins, `~/.agents` skills) are not tracked.

## New laptop setup

1. Install Claude Code, `git`, `gh` (log in as HIRWA13) and `zsh`.
2. Clone: `git clone https://github.com/HIRWA13/ai-infra.git ~/ai`
3. Create the config files from the example:
   ```
   mkdir -p ~/ai/secrets && chmod 700 ~/ai/secrets
   # copy the config.env block of secrets.env.example into ~/ai/config.env
   # copy the secrets.env block into ~/ai/secrets/secrets.env, fill in values
   chmod 600 ~/ai/secrets/secrets.env
   ```
4. Load the helpers: add to `~/.zshrc`, then `source ~/.zshrc`
   ```
   [ -r "$HOME/ai/shell/ai.zsh" ] && source "$HOME/ai/shell/ai.zsh"
   ```
5. Link own content into `~/.claude` (back up anything already there first):
   ```
   mkdir -p ~/.claude/skills ~/.claude/agents
   ln -s ~/ai/skills/crucible ~/.claude/skills/crucible
   ln -s ~/ai/skills/csharp-daily ~/.claude/skills/csharp-daily
   ln -s ~/ai/agents/ui-verifier.md ~/.claude/agents/ui-verifier.md
   ln -s ~/ai/bin/statusline-command.sh ~/.claude/statusline-command.sh
   ln -s ~/ai/CLAUDE.md ~/.claude/CLAUDE.md
   ```
6. Create `~/.claude/settings.json` from `settings.example.json` and add the Tavily key.
7. Reinstall installer-managed items listed in `manifest/skills.md` (SuperClaude, plugins, mattpocock skills, graphify).
8. Verify: open a new terminal, run `type claude-as`, then `claude-as ojemba`.
