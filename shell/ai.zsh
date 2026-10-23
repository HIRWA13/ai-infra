# Claude Code launcher helpers. Secrets come from ~/.config/ai/secrets.env.
_AI_SECRETS="$HOME/.config/ai/secrets.env"
[ -r "$_AI_SECRETS" ] && { set -a; source "$_AI_SECRETS"; set +a; }

export ANTHROPIC_BASE_URL="$AI_BASE_URL"
export ANTHROPIC_MODEL="$AI_MODEL"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="$AI_HAIKU_MODEL"
export ANTHROPIC_DEFAULT_SONNET_MODEL="$AI_SONNET_MODEL"
export ANTHROPIC_DEFAULT_OPUS_MODEL="$AI_OPUS_MODEL"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export DISABLE_TELEMETRY=1
export DISABLE_ERROR_REPORTING=1
export DISABLE_BUG_COMMAND=1
export CLAUDE_CODE_DISABLE_ARTIFACT=1

_ai_token() {
  case "$1" in
    ojemba)  print -r -- "$AI_TOKEN_OJEMBA" ;;
    project) print -r -- "$AI_TOKEN_PROJECT" ;;
    *) print -u2 "unknown profile: $1 (use ojemba|project)"; return 1 ;;
  esac
}

claude-as() {
  local token; token="$(_ai_token "$1")" || return 1; shift
  ANTHROPIC_AUTH_TOKEN="$token" claude "$@"
}

sbx-as() {
  local profile="$1" token; token="$(_ai_token "$profile")" || return 1; shift
  sbx run --name "$profile-$(basename "$PWD")" \
    --env ANTHROPIC_AUTH_TOKEN="$token" \
    --env ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL" \
    --env ANTHROPIC_MODEL="$ANTHROPIC_MODEL" \
    --env ANTHROPIC_DEFAULT_SONNET_MODEL="$ANTHROPIC_DEFAULT_SONNET_MODEL" \
    --env ANTHROPIC_DEFAULT_HAIKU_MODEL="$ANTHROPIC_DEFAULT_HAIKU_MODEL" \
    --env ANTHROPIC_DEFAULT_OPUS_MODEL="$ANTHROPIC_DEFAULT_OPUS_MODEL" \
    --env CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
    --env DISABLE_TELEMETRY=1 \
    --env DISABLE_ERROR_REPORTING=1 \
    --env DISABLE_BUG_COMMAND=1 \
    --env CLAUDE_CODE_DISABLE_ARTIFACT=1 \
    claude "$PWD" -- "$@"
}

alias ojemba-claude='claude-as ojemba'
alias project-claude='claude-as project'
sbx-ojemba()  { sbx-as ojemba "$@"; }
sbx-project() { sbx-as project "$@"; }
