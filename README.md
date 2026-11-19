# ai-infra

A personal Claude Code setup kept in one repo: skills, agents, scripts, shell helpers and global instructions. It is a template to fork and adapt, not a drop-in package. Several pieces are specific to the original author and need replacing first (see [What to customize](#what-to-customize)).

- `skills/` own skills, symlinked into `~/.claude/skills`
- `agents/` own agents, symlinked into `~/.claude/agents`
- `bin/` scripts: `statusline-command.sh`, `kaboom` (task loop), `ui-verify` (browser verification)
- `manifest/` third-party skills and where they come from (not tracked here)
- `shell/ai.zsh` zsh helpers (`claude-as`, `sbx-as`) sourced from `.zshrc`
- `CLAUDE.md` global instructions, symlinked to `~/.claude/CLAUDE.md`
- `settings.example.json` key-free example of `~/.claude/settings.json`

## Requirements

- macOS or Linux with `zsh`, `git`, `jq`
- [Claude Code](https://claude.com/claude-code)
- Optional: `sbx` (sandbox runner, used by `sbx-as` and the default `kaboom` runner), `gh`, Node/`npx` (for `ui-verify`'s Chrome DevTools MCP), a Tavily API key (web search)
- An Anthropic-compatible endpoint and token(s) if you use the `claude-as` helpers. Plain Claude Code login works without them.

## Config and secrets (both gitignored)

- `config.env` base URL and model names
- `secrets/secrets.env` tokens only (`chmod 600`)

Variable names are listed in `secrets.env.example`. Edit by hand; changes apply in a new terminal or after `source ~/.zshrc`. Installer-managed things (SuperClaude, plugins, `~/.agents` skills) are not tracked.

## Setup

1. Install the requirements above.
2. Clone (or your fork) into `~/ai`:
   ```
   git clone https://github.com/HIRWA13/ai-infra.git ~/ai
   ```
   The paths `~/ai` and `~/.claude` are assumed by the scripts and skills. If the repo is private, you need read access to it.
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
5. Link content into `~/.claude` (back up anything already there first):
   ```
   mkdir -p ~/.claude/skills ~/.claude/agents
   for s in crucible csharp-daily kaboom-plan ui-verify; do ln -s ~/ai/skills/$s ~/.claude/skills/$s; done
   ln -s ~/ai/agents/ui-verifier.md ~/.claude/agents/ui-verifier.md
   ln -s ~/ai/bin/statusline-command.sh ~/.claude/statusline-command.sh
   ```
   Link `CLAUDE.md` only after editing it for yourself (see below): `ln -s ~/ai/CLAUDE.md ~/.claude/CLAUDE.md`
6. Create `~/.claude/settings.json` from `settings.example.json`. Set the `statusLine.command` path to your own home directory and add your Tavily key (or remove the Tavily entries).
7. Install the third-party items listed in `manifest/skills.md` (SuperClaude, plugins, mattpocock skills, graphify). `CLAUDE.md` imports SuperClaude files, so skip them only if you also remove those imports.
8. Verify: open a new terminal and run `type claude-as`.

## What to customize

- **Profiles in `shell/ai.zsh`**: `ojemba`, `project` and `mw` are the author's work accounts, and `mw` defaults to a MaibornWolff gateway URL. Rename them, change the URLs, and match the `AI_TOKEN_*` names in `secrets.env.example`. Note the script always exports `ANTHROPIC_BASE_URL` and the model variables from `config.env`; leave them filled in or remove those lines if you use the standard Anthropic login.
- **`CLAUDE.md`**: the author's personal instructions (SuperClaude imports, skill triggers, commit rules). Replace with your own.
- **`kaboom`**: defaults to the `sbx-project` runner. Set `RUNNER` in your project's `config.env` if you use something else.
- **Skills**: `crucible` and the `ui-verify` skill refer to the author by name or assume `~/ai`. Review before use.
