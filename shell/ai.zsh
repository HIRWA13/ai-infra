# Claude Code launcher helpers. Config: ~/ai/config.env (gitignored). Tokens: ~/ai/secrets/secrets.env (gitignored).
_AI_HOME="${${(%):-%x}:A:h:h}"
for _f in "$_AI_HOME/config.env" "$_AI_HOME/secrets/secrets.env"; do
  [ -r "$_f" ] && { set -a; source "$_f"; set +a; }
done
unset _f
export PATH="$_AI_HOME/bin:$PATH"

export ANTHROPIC_BASE_URL="$AI_BASE_URL"
export ANTHROPIC_MODEL="$AI_MODEL"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="$AI_HAIKU_MODEL"
export ANTHROPIC_DEFAULT_SONNET_MODEL="$AI_SONNET_MODEL"
export ANTHROPIC_DEFAULT_OPUS_MODEL="$AI_OPUS_MODEL"

_ai_token() {
  case "$1" in
    ojemba)  print -r -- "$AI_TOKEN_OJEMBA" ;;
    project) print -r -- "$AI_TOKEN_PROJECT" ;;
    mw)      print -r -- "$AI_TOKEN_MW" ;;
    *) print -u2 "unknown profile: $1 (use ojemba|project|mw)"; return 1 ;;
  esac
}

_ai_url() {
  case "$1" in
    mw) print -r -- "${AI_BASE_URL_MW:-https://aikeys.maibornwolff.de}" ;;
    *)  print -r -- "$AI_BASE_URL" ;;
  esac
}

claude-as() {
  local token url; token="$(_ai_token "$1")" || return 1; url="$(_ai_url "$1")"; shift
  ANTHROPIC_AUTH_TOKEN="$token" ANTHROPIC_BASE_URL="$url" claude "$@"
}

sbx-as() {
  local profile="$1" token url; token="$(_ai_token "$profile")" || return 1; url="$(_ai_url "$profile")"; shift
  sbx run --name "$profile-$(basename "$PWD")" \
    --env ANTHROPIC_AUTH_TOKEN="$token" \
    --env ANTHROPIC_BASE_URL="$url" \
    --env ANTHROPIC_MODEL="$ANTHROPIC_MODEL" \
    --env ANTHROPIC_DEFAULT_SONNET_MODEL="$ANTHROPIC_DEFAULT_SONNET_MODEL" \
    --env ANTHROPIC_DEFAULT_HAIKU_MODEL="$ANTHROPIC_DEFAULT_HAIKU_MODEL" \
    --env ANTHROPIC_DEFAULT_OPUS_MODEL="$ANTHROPIC_DEFAULT_OPUS_MODEL" \
    claude "$PWD" -- "$@"
}

alias ojemba-claude='claude-as ojemba'
alias project-claude='claude-as project'
alias mw-claude='claude-as mw'
sbx-ojemba()  { sbx-as ojemba "$@"; }
sbx-project() { sbx-as project "$@"; }
sbx-mw()      { sbx-as mw "$@"; }
