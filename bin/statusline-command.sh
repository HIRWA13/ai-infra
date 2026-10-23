#!/usr/bin/env bash
# ~/.claude/statusline-command.sh
# Claude Code custom statusline

INPUT=$(cat)

# ANSI 256-color sequences (not truecolor)
ESC=$'\033'
RESET="${ESC}[0m"
DIM="${ESC}[2m"

c256() { printf "${ESC}[38;5;%sm" "$1"; }

C_PURPLE=$(c256 141)
C_ORANGE=$(c256 209)
C_GREEN=$(c256 40)
C_AMBER=$(c256 220)
C_RED_ORANGE=$(c256 202)
C_GREY=$(c256 248)

# Portable md5 hash (macOS + Linux)
md5hash() {
    printf '%s' "$1" | md5sum 2>/dev/null | cut -c1-12 \
    || printf '%s' "$1" | md5 2>/dev/null | cut -c1-12 \
    || printf '%s' "unknown"
}

# Portable file mtime
file_mtime() {
    stat -f %m "$1" 2>/dev/null \
    || stat -c %Y "$1" 2>/dev/null \
    || echo 0
}

# ── Parse JSON via python3 ──────────────────────────────────────────────────
PY_RESULT=$(printf '%s' "$INPUT" | python3 -c "
import json, sys, os, datetime, re

data = json.load(sys.stdin)

def out(k, v):
    v = str(v).replace(chr(39), chr(39)+chr(92)+chr(39)+chr(39))
    print(f\"{k}='{v}'\")

# Model -----------------------------------------------------------------------
env_model = os.environ.get('ANTHROPIC_MODEL', '').strip()
model_id  = env_model \
            or data.get('model', {}).get('id', '') \
            or data.get('model', {}).get('display_name', '')

def friendly(mid):
    # Normalize: replace dots with hyphens so 'claude-sonnet-4.6' == 'claude-sonnet-4-6'
    m = mid.lower().replace('.', '-')
    for pat, name in [
        ('claude-opus-4-6',   'Opus 4.6'),
        ('opus-4-6',          'Opus 4.6'),
        ('claude-sonnet-4-6', 'Sonnet 4.6'),
        ('sonnet-4-6',        'Sonnet 4.6'),
        ('claude-haiku-4-5',  'Haiku 4.5'),
        ('haiku-4-5',         'Haiku 4.5'),
        ('claude-opus-4',     'Opus 4'),
        ('claude-sonnet-4',   'Sonnet 4'),
        ('claude-haiku-4',    'Haiku 4'),
        ('claude-opus-3-7',   'Opus 3.7'),
        ('claude-sonnet-3-7', 'Sonnet 3.7'),
        ('claude-haiku-3-5',  'Haiku 3.5'),
        ('opus',   'Opus'),
        ('sonnet', 'Sonnet'),
        ('haiku',  'Haiku'),
    ]:
        if pat in m:
            return name
    return mid

model_name = friendly(model_id) if model_id else 'Claude'

# Context window --------------------------------------------------------------
ctx      = data.get('context_window', {})
max_tok   = int(ctx.get('max_tokens', 0))
used_pct  = float(ctx.get('used_percentage', 0))
total_tok = int(ctx.get('total_input_tokens', 0))

ctx_size = ''
if   max_tok >= 1_000_000: ctx_size = f'{max_tok/1_000_000:.1f}M'
elif max_tok >= 1000:       ctx_size = f'{max_tok//1000}K'

total_tok_str = ''
if   total_tok >= 1_000_000: total_tok_str = f'{total_tok/1_000_000:.1f}M'
elif total_tok >= 1000:      total_tok_str = f'{total_tok/1000:.1f}k'
elif total_tok > 0:          total_tok_str = str(total_tok)

session_id = data.get('session_id', 'unknown')

# Rate limits -----------------------------------------------------------------
now_utc = datetime.datetime.now(datetime.timezone.utc)

def parse_dt(s):
    if not s: return None
    try:    return datetime.datetime.fromisoformat(s.replace('Z', '+00:00'))
    except: return None

def fmt_td(secs):
    s = int(secs)
    if s <= 0: return ''
    d, s = divmod(s, 86400)
    h, m = divmod(s, 3600)
    m //= 60
    return f'{d}d {h}h' if d else f'{h}h {m}m'

def burn_warn(pct, ra_str, window_secs):
    ra = parse_dt(ra_str)
    if not ra: return ''
    rem     = max(0, (ra - now_utc).total_seconds())
    elapsed = window_secs - rem
    if elapsed <= 0: return ''
    proj = float(pct) * window_secs / elapsed
    return chr(0x1F525) if proj > 100 else ('\u26a0\ufe0f ' if proj > 80 else '')

rl_5h = rl_7d = ''
for rl in data.get('rate_limits', []):
    w    = str(rl.get('window', '')).lower()
    p    = float(rl.get('used_percentage', 0))
    ra_s = rl.get('resets_at', '')
    ra   = parse_dt(ra_s)
    reset = fmt_td((ra - now_utc).total_seconds()) if ra and ra > now_utc else ''
    pct_s = f'{p:.0f}%'
    if '5h' in w:
        warn  = burn_warn(p, ra_s, 18000)
        rl_5h = '\u23f1\ufe0f  ' + warn + pct_s + (f' \u21ba {reset}' if reset else '')
    elif '7d' in w:
        warn  = burn_warn(p, ra_s, 604800)
        rl_7d = '\U0001f4c5 ' + warn + pct_s + (f' \u21ba {reset}' if reset else '')

# Cache -----------------------------------------------------------------------
cache = data.get('cache', {})
cr    = int(cache.get('cache_read_tokens',  0))
cw    = int(cache.get('cache_write_tokens', 0))
ci    = int(cache.get('input_tokens',       0))
total = ci + cw + cr
cache_pct = str(cr * 100 // total) if cr > 0 and total > 0 else ''

out('MODEL_NAME', model_name)
out('CTX_SIZE',   ctx_size)
out('CTX_PCT',    f'{used_pct:.1f}')
out('TOTAL_TOK',  total_tok_str)
out('SESSION_ID', session_id)
out('RL_5H',      rl_5h)
out('RL_7D',      rl_7d)
out('CACHE_PCT',  cache_pct)
" 2>/dev/null) || PY_RESULT=""

[ -n "$PY_RESULT" ] && eval "$PY_RESULT"

MODEL_NAME="${MODEL_NAME:-Claude}"
CTX_SIZE="${CTX_SIZE:-}"
CTX_PCT="${CTX_PCT:-0}"
TOTAL_TOK="${TOTAL_TOK:-}"
SESSION_ID="${SESSION_ID:-unknown}"
RL_5H="${RL_5H:-}"
RL_7D="${RL_7D:-}"
CACHE_PCT="${CACHE_PCT:-}"

# ── Context burn-rate rolling average (awk) ─────────────────────────────────
SESSION_HASH=$(md5hash "$SESSION_ID")
BURN_FILE="/tmp/claude_ctx_burn_${SESSION_HASH}.txt"
{ printf '%s %s\n' "$(date +%s)" "$CTX_PCT" >> "$BURN_FILE"; } 2>/dev/null || true
{ tail -n 20 "$BURN_FILE" > "${BURN_FILE}.tmp" && mv "${BURN_FILE}.tmp" "$BURN_FILE"; } 2>/dev/null || true

CTX_EXTRAS=$(awk '
{
    pct[NR] = $2 + 0
    n = NR
}
END {
    if (n < 2) exit

    last_delta = pct[n] - pct[n-1]

    sum_d = 0; cnt = 0
    for (i = 2; i <= n; i++) {
        d = pct[i] - pct[i-1]
        if (d > 0) { sum_d += d; cnt++ }
    }

    trend = ""
    if (last_delta > 5) trend = "\342\226\262"      # ▲
    else if (last_delta > 1) trend = "\342\206\221"  # ↑

    msgs_left = ""
    if (cnt > 0) {
        avg = sum_d / cnt
        if (avg >= 0.05) {
            rem = 100 - pct[n]
            if (rem > 0) {
                msgs = int(rem / avg)
                if (msgs > 0) msgs_left = "~" msgs " msgs left"
            }
        }
    }

    out = trend
    if (msgs_left != "") {
        if (out != "") out = out " "
        out = out msgs_left
    }
    if (out != "") print out
}
' "$BURN_FILE" 2>/dev/null)

# ── Section 1: Model (purple 141) ──────────────────────────────────────────
CTX_PART=""
[ -n "$CTX_SIZE" ] && CTX_PART=" ($CTX_SIZE)"
SECTION_MODEL="${C_PURPLE}✨ ${MODEL_NAME}${CTX_PART}${RESET}"

# ── Section 2: Context window (color-coded) ─────────────────────────────────
PCT_INT="${CTX_PCT%%.*}"
if   [ "${PCT_INT:-0}" -ge 85 ] 2>/dev/null; then CTX_C="$C_RED_ORANGE"
elif [ "${PCT_INT:-0}" -ge 60 ] 2>/dev/null; then CTX_C="$C_AMBER"
else CTX_C="$C_GREEN"
fi
CTX_INNER="${CTX_PCT}%"
[ -n "$CTX_EXTRAS" ] && CTX_INNER+=" ${CTX_EXTRAS}"
if [ -n "$TOTAL_TOK" ]; then
    SECTION_CTX="${CTX_C}🧠 ${TOTAL_TOK} (${CTX_INNER})${RESET}"
else
    SECTION_CTX="${CTX_C}🧠 ${CTX_INNER}${RESET}"
fi

# ── Section 3: Rate limits (orange 209) — only when present ─────────────────
SECTION_RL=""
if [ -n "$RL_5H" ] || [ -n "$RL_7D" ]; then
    RL_PIECES=()
    [ -n "$RL_5H" ] && RL_PIECES+=("${C_ORANGE}${RL_5H}${RESET}")
    [ -n "$RL_7D" ] && RL_PIECES+=("${C_ORANGE}${RL_7D}${RESET}")
    SECTION_RL="${RL_PIECES[0]}"
    [ "${#RL_PIECES[@]}" -gt 1 ] && SECTION_RL+=" ${DIM}│${RESET} ${RL_PIECES[1]}"
fi

# ── Section 4: Cache hit ratio — only when cache_read > 0 ───────────────────
SECTION_CACHE=""
if [ -n "$CACHE_PCT" ] && [ "$CACHE_PCT" != "0" ]; then
    if   [ "${CACHE_PCT:-0}" -ge 80 ] 2>/dev/null; then CC="$C_GREEN"
    elif [ "${CACHE_PCT:-0}" -ge 50 ] 2>/dev/null; then CC="$C_AMBER"
    else CC="$C_GREY"
    fi
    SECTION_CACHE="${CC}♻️  ${CACHE_PCT}%${RESET}"
fi

# ── Section 5: LiteLLM budget — only when env vars present ──────────────────
SECTION_BUDGET=""
if [ -n "${ANTHROPIC_AUTH_TOKEN:-}" ] && [ -n "${ANTHROPIC_BASE_URL:-}" ]; then
    KEY_HASH=$(md5hash "$ANTHROPIC_AUTH_TOKEN")
    BUDGET_CACHE="/tmp/litellm_budget_cache_${KEY_HASH}.json"

    NEEDS_REFRESH=true
    if [ -f "$BUDGET_CACHE" ]; then
        MTIME=$(file_mtime "$BUDGET_CACHE")
        NOW=$(date +%s)
        AGE=$(( NOW - MTIME ))
        [ "$AGE" -lt 120 ] && NEEDS_REFRESH=false
    fi

    if [ "$NEEDS_REFRESH" = true ]; then
        curl -s -m 5 \
            -H "Authorization: Bearer ${ANTHROPIC_AUTH_TOKEN}" \
            "${ANTHROPIC_BASE_URL%/}/key/info" \
            -o "$BUDGET_CACHE" 2>/dev/null || rm -f "$BUDGET_CACHE"
    fi

    if [ -f "$BUDGET_CACHE" ]; then
        export BUDGET_CACHE
        SECTION_BUDGET=$(python3 - << 'PYEOF'
import json, sys, os, datetime, re

ESC = '\033'
def c(n): return f'{ESC}[38;5;{n}m'
RESET = f'{ESC}[0m'
DIM   = f'{ESC}[2m'
C_G   = c(40)   # green
C_A   = c(220)  # amber
C_R   = c(202)  # red-orange

try:
    with open(os.environ['BUDGET_CACHE']) as f:
        d = json.load(f)
except:
    sys.exit(0)

info   = d.get('info', d)
spend  = float(info.get('spend', 0) or 0)
budget = float(info.get('max_budget', 0) or 0)
if budget <= 0:
    sys.exit(0)

alias_raw  = info.get('key_alias', '') or info.get('key_name', '') or ''
budget_dur = str(info.get('budget_duration', '') or '')
reset_at_s = info.get('budget_reset_at', '') or info.get('expires', '') or ''

# Extract project from customer_prod_First.Last_PROJECT[__DEPT__NUM]
project = alias_raw
m = re.match(r'customer_prod_[A-Za-z]+\.[A-Za-z]+_([^_]+?)(?:__.*)?$', alias_raw)
if m:
    project = m.group(1)
elif '_' in alias_raw:
    project = alias_raw.rsplit('_', 1)[-1]
if len(project) > 12:
    project = project[:12] + '\u2026'

pct   = spend / budget * 100
color = C_R if pct >= 80 else (C_A if pct >= 50 else C_G)

dur_m = re.match(r'(\d+)d', budget_dur)
reset_days = (dur_m.group(1) + 'd') if dur_m else (budget_dur or '')

# Projection (only when >= 3 billing days elapsed)
proj_s = ''
now = datetime.datetime.now(datetime.timezone.utc)
if reset_at_s and dur_m:
    try:
        dur_days     = int(dur_m.group(1))
        ra           = datetime.datetime.fromisoformat(reset_at_s.replace('Z', '+00:00'))
        period_start = ra - datetime.timedelta(days=dur_days)
        elapsed      = (now - period_start).total_seconds() / 86400
        remaining    = dur_days - elapsed
        if elapsed >= 3 and remaining > 0:
            daily     = spend / elapsed
            projected = spend + daily * remaining
            if projected > budget * 1.2:
                pc, pi = C_R, '\U0001f4c9'   # 📉 red
            elif projected > budget:
                pc, pi = C_A, '\U0001f4c9'   # 📉 amber
            else:
                pc, pi = C_G, '\U0001f4c8'   # 📈 green
            proj_s = f' \u00b7 {pc}{pi} ${projected:.2f}{RESET}'
    except:
        pass

line  = f'{color}\U0001f4b3 {project} {DIM}\u2502{RESET} '
line += f'{color}\U0001f4b0 ${spend:.2f} / ${budget:.2f} ({pct:.0f}%)'
if reset_days:
    line += f' \u00b7 \u21ba {reset_days}'
line += proj_s + RESET
print(line)
PYEOF
        ) || true
    fi
fi

# ── Assemble all sections with dimmed │ separator ───────────────────────────
SEP=" ${DIM}│${RESET} "
LINE="$SECTION_MODEL${SEP}$SECTION_CTX"
[ -n "$SECTION_RL"     ] && LINE+="${SEP}${SECTION_RL}"
[ -n "$SECTION_CACHE"  ] && LINE+="${SEP}${SECTION_CACHE}"
[ -n "$SECTION_BUDGET" ] && LINE+="${SEP}${SECTION_BUDGET}"

printf "%b\n" "$LINE"
