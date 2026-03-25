#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════╗
# ║  Agent Skill Scanner v4                                         ║
# ║  Validates skill packages against the agentskills.io spec       ║
# ║  and best practices. Runs locally and in CI (GitHub Actions).   ║
# ║                                                                 ║
# ║  Spec:  https://agentskills.io/specification                    ║
# ║  Guide: https://agentskills.io/skill-creation                   ║
# ║                                                                 ║
# ║  Token Estimation:                                              ║
# ║  - Uses character/4 approximation (industry standard)           ║
# ║  - Accurate within ~10% for English text                        ║
# ║  - Based on OpenAI tiktoken cl100k_base encoding                ║
# ║                                                                 ║
# ║  Quality Score: 0-100 across 5 dimensions                       ║
# ║  - Description Quality (30)  · Spec Compliance (20)             ║
# ║  - Instruction Clarity (25)  · Progressive Disclosure (15)      ║
# ║  - Security (10)                                                ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Usage:
#   ./scripts/validate.sh              # full scan
#   ./scripts/validate.sh --help       # show usage
#
# Environment:
#   CI=true    — emits GitHub Actions annotations (auto-detected)
#   NO_COLOR=1 — disable colored output

SCAN_START=$SECONDS

ERRORS=0
WARNINGS=0
INFO_COUNT=0
CHECKS_RUN=0
TOTAL_CHECKS=15
CURRENT_SECTION=""
CI="${CI:-false}"
NO_COLOR="${NO_COLOR:-0}"
OUTPUT_MODE="terminal"
SKILL_FILE="SKILL.md"
SKILL_DIR="$(basename "$(pwd)")"

FINDINGS_FILE=$(mktemp)
trap 'rm -f "$FINDINGS_FILE"' EXIT

# ── Spec limits (agentskills.io/specification) ─────────────────────

NAME_MAX_LEN=64
DESC_MAX_LEN=1024
DESC_MIN_USEFUL=30
BODY_MAX_LINES=500
TOKEN_BUDGET=5000
COMPAT_MAX_LEN=500

# ── Token budget zones ────────────────────────────────────────────

TOKEN_SAFE_ZONE=3500
TOKEN_WARN_ZONE=5000
TOKEN_DANGER_ZONE=8000

REF_TOKEN_SAFE=2000
REF_TOKEN_WARN=3500
REF_TOKEN_DANGER=4500

TOTAL_TOKEN_SAFE=50000
TOTAL_TOKEN_WARN=100000
TOTAL_TOKEN_DANGER=200000

# ── Score trackers (populated during checks, consumed by scoring) ──

_S_HAS_NAME=false
_S_NAME_OK=false
_S_HAS_DESC=false
_S_DESC_LEN=0
_S_DESC_WHAT=false
_S_DESC_WHEN=false
_S_DESC_FIRST_PERSON=false
_S_DESC_GENERIC=false
_S_DESC_NEGATIVES=false
_S_CODE_BLOCKS=0
_S_HEADINGS=0
_S_REF_LINKS=0
_S_BODY_LINES=0
_S_BODY_TOKENS=0
_S_HAS_REFS_DIR=false
_S_REFS_LINKED=0
_S_REFS_TOTAL=0
_S_FENCES_OK=true
_S_SECRETS=0
_S_HARDCODED=0
_S_DANGEROUS=0

QUALITY_SCORE=0
QUALITY_GRADE="F"
QUALITY_DESC=0
QUALITY_CLARITY=0
QUALITY_SPEC=0
QUALITY_PROGRESSIVE=0
QUALITY_SECURITY=0

# ── Colors & formatting ───────────────────────────────────────────

if [ "$NO_COLOR" = "1" ]; then
  _red()         { printf '%s' "$*"; }
  _green()       { printf '%s' "$*"; }
  _yellow()      { printf '%s' "$*"; }
  _blue()        { printf '%s' "$*"; }
  _cyan()        { printf '%s' "$*"; }
  _magenta()     { printf '%s' "$*"; }
  _bold()        { printf '%s' "$*"; }
  _dim()         { printf '%s' "$*"; }
  _bold_green()  { printf '%s' "$*"; }
  _bold_red()    { printf '%s' "$*"; }
  _bold_yellow() { printf '%s' "$*"; }
  _bold_cyan()   { printf '%s' "$*"; }
else
  _red()         { printf "\033[0;31m%s\033[0m" "$*"; }
  _green()       { printf "\033[0;32m%s\033[0m" "$*"; }
  _yellow()      { printf "\033[0;33m%s\033[0m" "$*"; }
  _blue()        { printf "\033[0;34m%s\033[0m" "$*"; }
  _cyan()        { printf "\033[0;36m%s\033[0m" "$*"; }
  _magenta()     { printf "\033[0;35m%s\033[0m" "$*"; }
  _bold()        { printf "\033[1m%s\033[0m" "$*"; }
  _dim()         { printf "\033[2m%s\033[0m" "$*"; }
  _bold_green()  { printf "\033[1;32m%s\033[0m" "$*"; }
  _bold_red()    { printf "\033[1;31m%s\033[0m" "$*"; }
  _bold_yellow() { printf "\033[1;33m%s\033[0m" "$*"; }
  _bold_cyan()   { printf "\033[1;36m%s\033[0m" "$*"; }
fi

# ── Logging ────────────────────────────────────────────────────────

_error() {
  ERRORS=$((ERRORS + 1))
  [ "$OUTPUT_MODE" = "terminal" ] && echo "  $(_red "✗ ERROR") $*" || true
  echo "ERROR|${CURRENT_SECTION}|$*" >> "$FINDINGS_FILE"
}

_warn() {
  WARNINGS=$((WARNINGS + 1))
  [ "$OUTPUT_MODE" = "terminal" ] && echo "  $(_yellow "! WARN ") $*" || true
  echo "WARN|${CURRENT_SECTION}|$*" >> "$FINDINGS_FILE"
}

_pass() {
  [ "$OUTPUT_MODE" = "terminal" ] && echo "  $(_green "✓ PASS ") $*" || true
}

_info() {
  INFO_COUNT=$((INFO_COUNT + 1))
  [ "$OUTPUT_MODE" = "terminal" ] && echo "  $(_blue "ℹ INFO ") $*" || true
  echo "INFO|${CURRENT_SECTION}|$*" >> "$FINDINGS_FILE"
}

_detail() {
  [ "$OUTPUT_MODE" = "terminal" ] && echo "         $(_dim "$*")" || true
}

ci_annotate() {
  local level="$1"; shift
  if [ "$CI" = "true" ]; then
    echo "::${level} $*"
  fi
}

section() {
  CHECKS_RUN=$((CHECKS_RUN + 1))
  CURRENT_SECTION="$1"
  if [ "$OUTPUT_MODE" = "terminal" ]; then
    echo ""
    echo "  $(_bold_cyan "[$CHECKS_RUN/$TOTAL_CHECKS]") $(_bold "$1")"
    echo "  $(_dim "$(printf '%.0s─' $(seq 1 60))")"
  fi
}

file_lines() { wc -l < "$1" | tr -d ' '; }
file_chars() { wc -c < "$1" | tr -d ' '; }
file_words() { wc -w < "$1" | tr -d ' '; }

estimate_tokens() {
  local chars
  chars=$(file_chars "$1")
  echo $(( chars / 4 ))
}

estimate_tokens_detailed() {
  local file="$1"
  local chars words lines char_tokens word_tokens
  chars=$(file_chars "$file")
  words=$(file_words "$file")
  lines=$(file_lines "$file")
  char_tokens=$(( chars / 4 ))
  word_tokens=$(( (words * 13) / 10 ))
  echo "$char_tokens|$chars|$words|$lines|$word_tokens"
}

token_zone_color() {
  local tokens="$1" safe="$2" warn="$3"
  if [ "$tokens" -le "$safe" ]; then
    echo "green"
  elif [ "$tokens" -le "$warn" ]; then
    echo "yellow"
  else
    echo "red"
  fi
}

format_tokens_colored() {
  local tokens="$1" safe="$2" warn="$3" label="${4:-tokens}"
  local zone
  zone=$(token_zone_color "$tokens" "$safe" "$warn")
  case "$zone" in
    green)  printf "%s" "$(_green "~$tokens $label")" ;;
    yellow) printf "%s" "$(_yellow "~$tokens $label")" ;;
    red)    printf "%s" "$(_red "~$tokens $label")" ;;
  esac
}

token_zone_indicator() {
  local tokens="$1" safe="$2" warn="$3"
  local zone pct
  zone=$(token_zone_color "$tokens" "$safe" "$warn")
  pct=$(( (tokens * 100) / warn ))
  case "$zone" in
    green)
      if [ "$NO_COLOR" = "1" ]; then echo "[SAFE $pct%]"
      else echo "$(_green "[SAFE $pct%]")"; fi ;;
    yellow)
      if [ "$NO_COLOR" = "1" ]; then echo "[WARN $pct%]"
      else echo "$(_yellow "[WARN $pct%]")"; fi ;;
    red)
      if [ "$NO_COLOR" = "1" ]; then echo "[HIGH $pct%]"
      else echo "$(_red "[HIGH $pct%]")"; fi ;;
  esac
}

# ── Visual helpers ─────────────────────────────────────────────────

bar_gauge() {
  local value="$1" max="$2" width="${3:-20}"
  local pct filled empty bar=""
  if [ "$max" -le 0 ]; then pct=0
  else pct=$(( (value * 100) / max )); fi
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( (pct * width) / 100 ))
  empty=$(( width - filled ))
  local i
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  echo "$bar"
}

bar_gauge_colored() {
  local value="$1" max="$2" width="${3:-20}" safe="${4:-0}" warn="${5:-0}"
  local pct gauge
  if [ "$max" -le 0 ]; then pct=0
  else pct=$(( (value * 100) / max )); fi
  [ "$pct" -gt 100 ] && pct=100
  gauge=$(bar_gauge "$value" "$max" "$width")

  if [ "$safe" -gt 0 ] && [ "$warn" -gt 0 ]; then
    local zone
    zone=$(token_zone_color "$value" "$safe" "$warn")
    case "$zone" in
      green)  printf "%s %s" "$(_green "$gauge")" "$(_green "${pct}%")" ;;
      yellow) printf "%s %s" "$(_yellow "$gauge")" "$(_yellow "${pct}%")" ;;
      red)    printf "%s %s" "$(_red "$gauge")" "$(_red "${pct}%")" ;;
    esac
  else
    printf "%s %d%%" "$gauge" "$pct"
  fi
}

letter_grade() {
  local score="$1"
  if   [ "$score" -ge 95 ]; then echo "A+"
  elif [ "$score" -ge 90 ]; then echo "A"
  elif [ "$score" -ge 85 ]; then echo "A-"
  elif [ "$score" -ge 80 ]; then echo "B+"
  elif [ "$score" -ge 75 ]; then echo "B"
  elif [ "$score" -ge 70 ]; then echo "B-"
  elif [ "$score" -ge 65 ]; then echo "C+"
  elif [ "$score" -ge 60 ]; then echo "C"
  elif [ "$score" -ge 55 ]; then echo "C-"
  elif [ "$score" -ge 50 ]; then echo "D"
  else echo "F"
  fi
}

grade_color() {
  local score="$1" grade
  grade=$(letter_grade "$score")
  if   [ "$score" -ge 85 ]; then printf "%s" "$(_bold_green "$grade")"
  elif [ "$score" -ge 65 ]; then printf "%s" "$(_bold_yellow "$grade")"
  else printf "%s" "$(_bold_red "$grade")"
  fi
}

safe_count() {
  local result
  result=$("$@" 2>/dev/null | tr -d ' ' || true)
  if [ -z "$result" ] || ! [[ "$result" =~ ^[0-9]+$ ]]; then
    echo "0"
  else
    echo "$result"
  fi
}

# ════════════════════════════════════════════════════════════════════
#  CHECKS
# ════════════════════════════════════════════════════════════════════

# ── [1] Skill Structure ───────────────────────────────────────────

check_structure() {
  section "Skill Structure"

  if [ ! -f "$SKILL_FILE" ]; then
    _error "SKILL.md not found — required by agentskills.io spec"
    ci_annotate "error" "file=SKILL.md::SKILL.md not found"
    return
  fi
  _pass "SKILL.md ($(file_lines "$SKILL_FILE") lines, $(file_chars "$SKILL_FILE") bytes)"

  if [ ! -f "README.md" ]; then
    _warn "README.md missing — recommended for discoverability and GitHub rendering"
    ci_annotate "warning" "file=README.md::README.md missing (recommended)"
  else
    _pass "README.md ($(file_lines README.md) lines)"
  fi

  local dirs=("references" "scripts" "assets" "agents")
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      local count
      count=$(find "$dir" -type f | wc -l | tr -d ' ')
      _pass "$dir/ ($count files)"
      if [ "$dir" = "references" ]; then
        _S_HAS_REFS_DIR=true
      fi
    fi
  done

  if [ ! -d "references" ]; then
    _info "No references/ directory"
    _detail "Add reference docs for progressive disclosure of complex content"
  fi

  if [ -f "LICENSE" ] || [ -f "LICENSE.md" ] || [ -f "LICENSE.txt" ]; then
    _pass "License file found"
  fi
}

# ── [2] Frontmatter ───────────────────────────────────────────────

check_frontmatter() {
  [ ! -f "$SKILL_FILE" ] && return

  section "Frontmatter & Description Quality"

  local first_line
  first_line=$(head -1 "$SKILL_FILE")
  if [ "$first_line" != "---" ]; then
    _error "Line 1: Expected '---' delimiter, found: '$first_line'"
    ci_annotate "error" "file=$SKILL_FILE,line=1::Missing YAML frontmatter delimiter"
    return
  fi

  local frontmatter
  frontmatter=$(sed -n '2,/^---$/p' "$SKILL_FILE" | sed '$d')

  # ── name ──
  local name
  name=$(echo "$frontmatter" | grep '^name:' | head -1 | sed 's/^name:[[:space:]]*//')

  if [ -z "$name" ]; then
    _error "Required field 'name' missing"
    ci_annotate "error" "file=$SKILL_FILE::Missing required 'name' field"
  else
    _S_HAS_NAME=true
    local name_len=${#name}
    local name_ok=true

    if [ "$name_len" -gt "$NAME_MAX_LEN" ]; then
      _error "name '$name' is $name_len chars (max $NAME_MAX_LEN)"
      ci_annotate "error" "file=$SKILL_FILE::name exceeds $NAME_MAX_LEN chars"
      name_ok=false
    fi

    if echo "$name" | grep -qE '[A-Z]'; then
      _error "name '$name' has uppercase — spec requires lowercase only"
      ci_annotate "error" "file=$SKILL_FILE::name must be lowercase"
      name_ok=false
    fi

    if echo "$name" | grep -qE '[^a-z0-9-]'; then
      _error "name '$name' has invalid chars — only a-z, 0-9, hyphens allowed"
      ci_annotate "error" "file=$SKILL_FILE::name contains invalid characters"
      name_ok=false
    fi

    if echo "$name" | grep -qE '^-|-$'; then
      _error "name '$name' starts or ends with hyphen"
      ci_annotate "error" "file=$SKILL_FILE::name starts/ends with hyphen"
      name_ok=false
    fi

    if echo "$name" | grep -qF -- '--'; then
      _error "name '$name' has consecutive hyphens (--)"
      ci_annotate "error" "file=$SKILL_FILE::name has consecutive hyphens"
      name_ok=false
    fi

    if [ "$name_ok" = true ]; then
      _pass "name: '$name' ($name_len chars)"
      _S_NAME_OK=true
    fi

    if [ "$name" != "$SKILL_DIR" ]; then
      _warn "name '$name' ≠ directory '$SKILL_DIR'"
      _detail "Spec: name should match parent directory name"
      ci_annotate "warning" "file=$SKILL_FILE::name doesn't match directory name"
    else
      _pass "name matches directory name"
    fi
  fi

  # ── description ──
  local desc_line desc=""
  desc_line=$(echo "$frontmatter" | grep -n '^description:' | head -1 | cut -d: -f1)

  if [ -z "$desc_line" ]; then
    _error "Required field 'description' missing"
    ci_annotate "error" "file=$SKILL_FILE::Missing required 'description' field"
  else
    _S_HAS_DESC=true
    local inline_desc
    inline_desc=$(echo "$frontmatter" | sed -n "${desc_line}p" | sed 's/^description:[[:space:]]*//')

    if [ -n "$inline_desc" ] && ! echo "$inline_desc" | grep -qE '^\s*[>|]\s*$'; then
      desc="$inline_desc"
    else
      desc=$(echo "$frontmatter" | sed -n "$((desc_line+1)),\$p" | sed '/^[a-zA-Z_-]*:/,$d' | tr '\n' ' ' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    fi

    local desc_len=${#desc}
    _S_DESC_LEN=$desc_len

    if [ "$desc_len" -eq 0 ]; then
      _error "description is empty"
      ci_annotate "error" "file=$SKILL_FILE::description is empty"
    else
      if [ "$desc_len" -gt "$DESC_MAX_LEN" ]; then
        _warn "description is $desc_len chars (spec max: $DESC_MAX_LEN)"
        ci_annotate "warning" "file=$SKILL_FILE::description exceeds $DESC_MAX_LEN chars"
      else
        _pass "description length: $desc_len chars (limit: $DESC_MAX_LEN)"
      fi

      if [ "$desc_len" -lt "$DESC_MIN_USEFUL" ]; then
        _warn "description is very short ($desc_len chars) — likely won't trigger well"
        _detail "Good: 'Extract text and tables from PDF files, fill forms, merge"
        _detail "       documents. Use when working with PDF documents.'"
        _detail "Bad:  'Helps with PDFs.'"
        ci_annotate "warning" "file=$SKILL_FILE::description too short for reliable triggering"
      fi

      # WHAT and WHEN analysis
      local has_what=false has_when=false
      if echo "$desc" | grep -qiE 'build|create|generate|extract|analyze|process|manage|handle|configure|review|refactor|optimize|test|debug|deploy|format|validate|convert|transform|monitor|implement'; then
        has_what=true
        _S_DESC_WHAT=true
      fi
      if echo "$desc" | grep -qiE 'use when|when working|when the user|when handling|if the user|for tasks|for working|designed for|use this|use for'; then
        has_when=true
        _S_DESC_WHEN=true
      fi

      if [ "$has_what" = true ] && [ "$has_when" = true ]; then
        _pass "description covers WHAT and WHEN to use"
      elif [ "$has_what" = false ] && [ "$has_when" = false ]; then
        _warn "description may lack WHAT the skill does and WHEN to use it"
        _detail "Spec: 'Describes what the skill does and when to use it'"
      elif [ "$has_when" = false ]; then
        _info "description explains WHAT but could clarify WHEN to trigger"
        _detail "Adding 'Use when...' helps agents decide when to activate"
      fi

      # ── [NEW] First-person voice ──
      if echo "$desc" | grep -qiE '\bI can\b|\bI will\b|\bI help\b|\bI am\b|\bI provide\b|\bmy skill\b'; then
        _warn "description uses first-person voice ('I can', 'I will', etc.)"
        _detail "Descriptions are injected into the agent system prompt — first-person"
        _detail "mixes viewpoints and confuses agent reasoning. Use third person instead"
        ci_annotate "warning" "file=$SKILL_FILE::description uses first-person voice"
        _S_DESC_FIRST_PERSON=true
      else
        _pass "description uses correct voice (not first-person)"
      fi

      # ── [NEW] Generic verb detection ──
      local generic_matches
      generic_matches=$(echo "$desc" | grep -oiE '\b(manage|handle|deal with|work with|help with|assist with|take care of)\b' 2>/dev/null | head -3 || true)
      if [ -n "$generic_matches" ]; then
        local generic_list
        generic_list=$(echo "$generic_matches" | tr '\n' ', ' | sed 's/,$//')
        _info "description contains generic verbs: $generic_list"
        _detail "Specific verbs (extract, generate, validate) improve trigger precision"
        _S_DESC_GENERIC=true
      else
        _pass "description uses specific action verbs"
      fi

      # ── [NEW] Negative trigger detection ──
      if echo "$desc" | grep -qiE 'not for|not designed for|do not use|does not|don.t use'; then
        _pass "description includes boundary markers (negative triggers)"
        _S_DESC_NEGATIVES=true
      else
        _info "no negative triggers ('NOT for...', 'Do not use when...')"
        _detail "Negative triggers prevent mis-activation when many skills are loaded"
      fi
    fi
  fi

  # ── optional fields ──
  echo ""
  _detail "Optional fields:"

  if echo "$frontmatter" | grep -q '^license:'; then
    local license_val
    license_val=$(echo "$frontmatter" | grep '^license:' | sed 's/^license:[[:space:]]*//')
    _pass "license: $license_val"
  else
    _info "No license field — recommended for shared/public skills"
  fi

  if echo "$frontmatter" | grep -q '^compatibility:'; then
    local compat
    compat=$(echo "$frontmatter" | grep '^compatibility:' | sed 's/^compatibility:[[:space:]]*//')
    local compat_len=${#compat}
    if [ "$compat_len" -gt "$COMPAT_MAX_LEN" ]; then
      _warn "compatibility is $compat_len chars (spec max: $COMPAT_MAX_LEN)"
    else
      _pass "compatibility field present ($compat_len chars)"
    fi
  fi

  if echo "$frontmatter" | grep -q '^metadata:'; then
    _pass "metadata field present"
    if echo "$frontmatter" | grep -q '^\s*version:'; then
      _pass "metadata.version set"
    fi
    if echo "$frontmatter" | grep -q '^\s*author:'; then
      _pass "metadata.author set"
    fi
  fi

  if echo "$frontmatter" | grep -q '^allowed-tools:'; then
    _pass "allowed-tools field present (experimental)"
  fi
}

# ── [3] Body Content & Progressive Disclosure ─────────────────────

check_body() {
  [ ! -f "$SKILL_FILE" ] && return

  section "Body Content & Progressive Disclosure"

  local body_start
  body_start=$(grep -n '^---$' "$SKILL_FILE" | sed -n '2p' | cut -d: -f1)

  if [ -z "$body_start" ]; then
    _error "No closing frontmatter delimiter (---) found"
    ci_annotate "error" "file=$SKILL_FILE::Missing closing frontmatter delimiter"
    return
  fi

  local body_lines token_est
  body_lines=$(tail -n +"$((body_start + 1))" "$SKILL_FILE" | wc -l | tr -d ' ')
  token_est=$(estimate_tokens "$SKILL_FILE")

  _S_BODY_LINES=$body_lines
  _S_BODY_TOKENS=$token_est

  # Line count with bar gauge
  if [ "$body_lines" -eq 0 ]; then
    _error "SKILL.md body is empty — agents need instructions"
    ci_annotate "error" "file=$SKILL_FILE::Empty body"
  elif [ "$body_lines" -gt "$BODY_MAX_LINES" ]; then
    _warn "Body: $body_lines lines (spec recommends <$BODY_MAX_LINES)"
    _detail "Move detailed content to references/ for on-demand loading"
    ci_annotate "warning" "file=$SKILL_FILE::Body exceeds $BODY_MAX_LINES lines"
  else
    _pass "Body: $body_lines lines (limit: $BODY_MAX_LINES)"
  fi
  local lines_gauge
  lines_gauge=$(bar_gauge_colored "$body_lines" "$BODY_MAX_LINES" 20 "$(( BODY_MAX_LINES * 70 / 100 ))" "$BODY_MAX_LINES")
  [ "$OUTPUT_MODE" = "terminal" ] && echo "         $lines_gauge" || true

  # Token budget with bar gauge
  if [ "$token_est" -gt "$TOKEN_BUDGET" ]; then
    _warn "~$token_est tokens (spec recommends <$TOKEN_BUDGET on activation)"
    _detail "Progressive disclosure: SKILL.md body loads fully on activation"
    _detail "Keep instructions concise, move reference material to references/"
    ci_annotate "warning" "file=$SKILL_FILE::Estimated $token_est tokens exceeds $TOKEN_BUDGET budget"
  else
    _pass "~$token_est tokens (budget: $TOKEN_BUDGET)"
  fi
  local token_gauge
  token_gauge=$(bar_gauge_colored "$token_est" "$TOKEN_DANGER_ZONE" 20 "$TOKEN_SAFE_ZONE" "$TOKEN_WARN_ZONE")
  [ "$OUTPUT_MODE" = "terminal" ] && echo "         $token_gauge" || true

  # Structure analysis
  local heading_count
  heading_count=$(tail -n +"$((body_start + 1))" "$SKILL_FILE" | grep -c '^#' 2>/dev/null || true)
  heading_count=${heading_count:-0}
  _S_HEADINGS=$heading_count

  if [ "$heading_count" -eq 0 ]; then
    _warn "No headings in body — add structure for readability"
  else
    _pass "$heading_count heading(s) providing structure"
  fi

  # Code examples
  local fence_pattern='```'
  local code_fence_count
  code_fence_count=$(grep -cF "$fence_pattern" "$SKILL_FILE" 2>/dev/null || true)
  code_fence_count=${code_fence_count:-0}
  local code_pairs=$(( code_fence_count / 2 ))
  _S_CODE_BLOCKS=$code_pairs

  local inline_code_count
  inline_code_count=$(grep -c '`[^`]' "$SKILL_FILE" 2>/dev/null || true)
  inline_code_count=${inline_code_count:-0}

  if [ "$code_pairs" -gt 0 ]; then
    _pass "$code_pairs fenced code example(s) in body"
  elif [ "$inline_code_count" -gt 0 ]; then
    _pass "$inline_code_count line(s) with inline code references"
  else
    _info "No code examples in body — consider adding for clarity"
  fi

  # Reference links (progressive disclosure pattern)
  local ref_link_count
  ref_link_count=$(tail -n +"$((body_start + 1))" "$SKILL_FILE" | grep -cE '\]\(references/' 2>/dev/null || true)
  ref_link_count=${ref_link_count:-0}
  _S_REF_LINKS=$ref_link_count

  if [ "$ref_link_count" -gt 0 ]; then
    _pass "$ref_link_count reference link(s) — using progressive disclosure"
  elif [ -d "references" ]; then
    local ref_file_count
    ref_file_count=$(find references -name '*.md' -type f | wc -l | tr -d ' ')
    if [ "$ref_file_count" -gt 0 ]; then
      _warn "references/ has $ref_file_count files but body has no links to them"
      _detail "Link references from SKILL.md body so agents can load them on demand"
    fi
  fi
}

# ── [4] Internal Links ────────────────────────────────────────────

check_links() {
  [ ! -f "$SKILL_FILE" ] && return

  section "Internal Links"

  local link_data
  link_data=$(grep -nF '](' "$SKILL_FILE" || true)

  if [ -z "$link_data" ]; then
    _info "No internal links in SKILL.md"
    return
  fi

  local checked=0 broken=0

  while IFS= read -r match; do
    local line_num line_content
    line_num=$(echo "$match" | cut -d: -f1)
    line_content=$(echo "$match" | cut -d: -f2-)

    local targets
    targets=$(echo "$line_content" | tr ']' '\n' | grep '^(' | sed 's/^(\([^)]*\)).*/\1/' | sed '/^$/d')

    [ -z "$targets" ] && continue

    while IFS= read -r link_path; do
      case "$link_path" in http*|https*|"#"*|"") continue ;; esac

      local file_path
      file_path=$(echo "$link_path" | cut -d'#' -f1)
      [ -z "$file_path" ] && continue

      checked=$((checked + 1))
      if [ -f "$file_path" ]; then
        _pass "Line $line_num: $link_path → $(file_lines "$file_path") lines"
      else
        _error "Line $line_num: $link_path → FILE NOT FOUND"
        ci_annotate "error" "file=$SKILL_FILE,line=$line_num::Broken link: $link_path"
        broken=$((broken + 1))
      fi
    done <<< "$targets"
  done <<< "$link_data"

  echo ""
  _detail "Checked $checked link(s), $broken broken"
}

# ── [5] Reference Files ──────────────────────────────────────────

check_references() {
  [ ! -d "references" ] && return

  section "Reference Files"

  local ref_links=""
  if [ -f "$SKILL_FILE" ]; then
    ref_links=$(grep -oE '\]\(references/[^)]+\)' "$SKILL_FILE" | sed 's/\](\(.*\))/\1/' | cut -d'#' -f1 | sort -u || true)
  fi

  local total=0 linked=0 orphaned=0 empty=0

  echo ""
  printf "  $(_dim "  %-35s  %-8s  %-8s  %s")\n" "FILE" "LINES" "STATUS" ""
  echo "  $(_dim "  $(printf '%.0s─' $(seq 1 56))")"

  while IFS= read -r file; do
    total=$((total + 1))
    local lines
    lines=$(file_lines "$file")

    if [ "$lines" -eq 0 ]; then
      printf "  $(_yellow "  %-35s  %-8s  %-8s")\n" "$(basename "$file")" "0" "EMPTY"
      _warn "$file is empty (0 lines)"
      ci_annotate "warning" "file=$file::Empty reference file"
      empty=$((empty + 1))
      continue
    fi

    if echo "$ref_links" | grep -qF "$file"; then
      linked=$((linked + 1))
      printf "  $(_green "  %-35s  %-8s  %-8s")\n" "$(basename "$file")" "$lines" "LINKED"
    else
      orphaned=$((orphaned + 1))
      printf "  $(_yellow "  %-35s  %-8s  %-8s")\n" "$(basename "$file")" "$lines" "ORPHAN"
      _warn "$file — $(_yellow "orphaned")"
      _detail "Not linked from SKILL.md — agents won't discover this file"
      ci_annotate "warning" "file=$file::Not linked from SKILL.md (orphaned)"
    fi
  done < <(find references -name '*.md' -type f | sort)

  _S_REFS_TOTAL=$total
  _S_REFS_LINKED=$linked

  # Missing references (linked in SKILL.md but don't exist)
  local missing=0
  if [ -n "$ref_links" ]; then
    for ref in $ref_links; do
      if [ ! -f "$ref" ]; then
        _error "$ref → linked in SKILL.md but file is missing"
        ci_annotate "error" "file=$ref::Referenced in SKILL.md but does not exist"
        missing=$((missing + 1))
      fi
    done
  fi

  echo ""
  echo "  $(_dim "  ┌──────────────────────────────────────────┐")"
  printf "  $(_dim "  │") Total: %-4s  Linked: %-4s  Orphaned: %-4s$(_dim "│")\n" "$total" "$linked" "$orphaned"
  printf "  $(_dim "  │") Empty: %-4s  Missing: %-4s               $(_dim "│")\n" "$empty" "$missing"
  echo "  $(_dim "  └──────────────────────────────────────────┘")"
}

# ── [6] Markdown Syntax ──────────────────────────────────────────

check_markdown() {
  section "Markdown Syntax"

  local pattern file_count=0 issues=0
  pattern='```'

  while IFS= read -r file; do
    file_count=$((file_count + 1))
    local count
    count=$(grep -cF "$pattern" "$file" 2>/dev/null || true)
    count=${count:-0}

    if [ "$count" -gt 0 ] && [ $((count % 2)) -ne 0 ]; then
      _warn "$file — unclosed code block ($count fences)"
      grep -nF "$pattern" "$file" 2>/dev/null | while IFS= read -r m; do
        _detail "Line $(echo "$m" | cut -d: -f1): $(echo "$m" | cut -d: -f2-)"
      done
      ci_annotate "warning" "file=$file::Unclosed code block ($count fences)"
      issues=$((issues + 1))
    fi
  done < <(find . -name '*.md' -not -path './.git/*' | sort)

  if [ "$issues" -eq 0 ]; then
    _pass "All $file_count markdown files have balanced code fences"
  else
    _S_FENCES_OK=false
  fi
}

# ── [7] Reference Nesting ────────────────────────────────────────

check_reference_depth() {
  [ ! -d "references" ] && return

  section "Reference Nesting"

  local deep_refs=0
  while IFS= read -r file; do
    local nested
    nested=$(grep -cE '\]\(references/' "$file" 2>/dev/null || true)
    if [ "$nested" -gt 0 ]; then
      _warn "$file → $nested cross-reference(s) to other reference files"
      _detail "Spec: keep file references one level deep from SKILL.md"
      ci_annotate "warning" "file=$file::Cross-references between reference files"
      deep_refs=$((deep_refs + 1))
    fi
  done < <(find references -name '*.md' -type f | sort)

  if [ "$deep_refs" -eq 0 ]; then
    _pass "No nested reference chains — clean one-level structure"
  else
    _detail "$deep_refs file(s) with cross-references"
  fi
}

# ── [8] Scripts Validation ───────────────────────────────────────

check_scripts() {
  [ ! -d "scripts" ] && return

  section "Scripts"

  local total=0 executable=0 not_executable=0 documented=0

  while IFS= read -r script; do
    total=$((total + 1))
    local basename_script
    basename_script=$(basename "$script")

    if [ -x "$script" ]; then
      executable=$((executable + 1))
      _pass "$script (executable, $(file_lines "$script") lines)"
    else
      not_executable=$((not_executable + 1))
      _warn "$script is not executable"
      _detail "Run: chmod +x $script"
      ci_annotate "warning" "file=$script::Script is not executable"
    fi

    if [ -f "$SKILL_FILE" ] && grep -qF "$basename_script" "$SKILL_FILE"; then
      documented=$((documented + 1))
    fi
  done < <(find scripts -type f | sort)

  if [ "$total" -gt 0 ] && [ "$documented" -eq 0 ] && [ -f "$SKILL_FILE" ]; then
    _info "No scripts referenced in SKILL.md body"
    _detail "Document available scripts so agents know what tools they can run"
  elif [ "$documented" -gt 0 ]; then
    _pass "$documented of $total script(s) documented in SKILL.md"
  fi
}

# ── [9] Package Integrity ────────────────────────────────────────

check_repo_hygiene() {
  section "Repository Hygiene"

  local sensitive
  sensitive=$(find . -maxdepth 3 \
    \( -name '.env' -o -name '*.key' -o -name '*.pem' -o -name 'credentials*' \) \
    -not -path './.git/*' 2>/dev/null || true)

  if [ -n "$sensitive" ]; then
    _warn "Possible sensitive files detected"
    echo "$sensitive" | while IFS= read -r f; do
      _detail "  $f"
    done
  else
    _pass "No sensitive files (.env, .key, .pem, credentials)"
  fi

  local artifacts
  artifacts=$(find . -maxdepth 3 \
    \( -name 'node_modules' -o -name '__pycache__' -o -name '.DS_Store' \) \
    -not -path './.git/*' 2>/dev/null || true)

  if [ -n "$artifacts" ]; then
    _warn "Development artifacts found — add to .gitignore"
    echo "$artifacts" | while IFS= read -r f; do
      _detail "  $f"
    done
  else
    _pass "No development artifacts (node_modules, __pycache__, .DS_Store)"
  fi
}

# ── [10] Token Budget Analysis ────────────────────────────────────

check_token_budget() {
  section "Token Budget Analysis"

  if [ "$OUTPUT_MODE" = "terminal" ]; then echo ""; fi
  _detail "Token estimation: chars/4 (tiktoken cl100k_base approximation)"
  _detail "Zone thresholds based on agentskills.io and context engineering best practices"
  if [ "$OUTPUT_MODE" = "terminal" ]; then echo ""; fi

  local total_tokens=0
  local total_chars=0
  local total_words=0
  local total_lines=0
  local file_count=0

  # ── SKILL.md analysis ──
  if [ -f "$SKILL_FILE" ]; then
    local skill_data skill_tokens skill_chars skill_words skill_lines
    skill_data=$(estimate_tokens_detailed "$SKILL_FILE")
    skill_tokens=$(echo "$skill_data" | cut -d'|' -f1)
    skill_chars=$(echo "$skill_data" | cut -d'|' -f2)
    skill_words=$(echo "$skill_data" | cut -d'|' -f3)
    skill_lines=$(echo "$skill_data" | cut -d'|' -f4)

    local zone_indicator
    zone_indicator=$(token_zone_indicator "$skill_tokens" "$TOKEN_SAFE_ZONE" "$TOKEN_WARN_ZONE")

    if [ "$OUTPUT_MODE" = "terminal" ]; then
      echo "  $(_bold "SKILL.md") $zone_indicator"
      echo "    ├─ $(format_tokens_colored "$skill_tokens" "$TOKEN_SAFE_ZONE" "$TOKEN_WARN_ZONE" "tokens")"
      local skill_gauge
      skill_gauge=$(bar_gauge_colored "$skill_tokens" "$TOKEN_DANGER_ZONE" 20 "$TOKEN_SAFE_ZONE" "$TOKEN_WARN_ZONE")
      echo "    ├─ $skill_gauge"
      echo "    ├─ $skill_chars chars | $skill_words words | $skill_lines lines"
      echo "    └─ Budget: $TOKEN_WARN_ZONE tokens recommended"
    fi

    total_tokens=$((total_tokens + skill_tokens))
    total_chars=$((total_chars + skill_chars))
    total_words=$((total_words + skill_words))
    total_lines=$((total_lines + skill_lines))
    file_count=$((file_count + 1))

    if [ "$skill_tokens" -gt "$TOKEN_DANGER_ZONE" ]; then
      _warn "SKILL.md exceeds danger zone (~$skill_tokens tokens > $TOKEN_DANGER_ZONE)"
      _detail "Consider moving content to references/ for on-demand loading"
    fi
  fi

  # ── Reference files analysis ──
  if [ -d "references" ]; then
    if [ "$OUTPUT_MODE" = "terminal" ]; then
      echo ""
      echo "  $(_bold "Reference Files:")"
      echo ""
      printf "    $(_dim "%-35s  %-12s  %-6s  %-6s")\n" "FILE" "ZONE" "TOKENS" "LINES"
      echo "    $(_dim "$(printf '%.0s─' $(seq 1 62))")"
    fi

    local ref_total=0
    local ref_files=0
    local largest_ref=""
    local largest_ref_tokens=0

    while IFS= read -r file; do
      local ref_data ref_tokens ref_chars ref_words ref_lines
      ref_data=$(estimate_tokens_detailed "$file")
      ref_tokens=$(echo "$ref_data" | cut -d'|' -f1)
      ref_chars=$(echo "$ref_data" | cut -d'|' -f2)
      ref_words=$(echo "$ref_data" | cut -d'|' -f3)
      ref_lines=$(echo "$ref_data" | cut -d'|' -f4)

      local zone_indicator
      zone_indicator=$(token_zone_indicator "$ref_tokens" "$REF_TOKEN_SAFE" "$REF_TOKEN_WARN")

      local basename_file
      basename_file=$(basename "$file")
      [ "$OUTPUT_MODE" = "terminal" ] && printf "    %-35s  %-12s  ~%-6d  %d\n" "$basename_file" "$(echo "$zone_indicator" | sed 's/\x1b\[[0-9;]*m//g')" "$ref_tokens" "$ref_lines" || true

      ref_total=$((ref_total + ref_tokens))
      ref_files=$((ref_files + 1))
      total_tokens=$((total_tokens + ref_tokens))
      total_chars=$((total_chars + ref_chars))
      total_words=$((total_words + ref_words))
      total_lines=$((total_lines + ref_lines))
      file_count=$((file_count + 1))

      if [ "$ref_tokens" -gt "$largest_ref_tokens" ]; then
        largest_ref_tokens=$ref_tokens
        largest_ref="$basename_file"
      fi

      if [ "$ref_tokens" -gt "$REF_TOKEN_DANGER" ]; then
        _warn "$basename_file is too large (~$ref_tokens tokens > $REF_TOKEN_DANGER)"
        _detail "Split into base + advanced files (e.g., topic.md + topic-advanced.md)"
      elif [ "$ref_tokens" -gt "$REF_TOKEN_WARN" ]; then
        _warn "$basename_file is getting large (~$ref_tokens tokens > $REF_TOKEN_WARN)"
        _detail "Tighten prose: tables over paragraphs, cross-link shared patterns, trim tutorial content"
      fi
    done < <(find references -name '*.md' -type f | sort)

    if [ "$OUTPUT_MODE" = "terminal" ]; then
      echo ""
      echo "    $(_dim "Reference subtotal: ~$ref_total tokens across $ref_files files")"
      if [ -n "$largest_ref" ]; then
        echo "    $(_dim "Largest reference: $largest_ref (~$largest_ref_tokens tokens)")"
      fi
    fi
  fi

  # ── README analysis ──
  if [ -f "README.md" ]; then
    local readme_data readme_tokens readme_lines
    readme_data=$(estimate_tokens_detailed "README.md")
    readme_tokens=$(echo "$readme_data" | cut -d'|' -f1)
    readme_lines=$(echo "$readme_data" | cut -d'|' -f4)

    if [ "$OUTPUT_MODE" = "terminal" ]; then
      echo ""
      echo "  $(_bold "README.md") $(_dim "(not loaded by agents, for humans)")"
      echo "    └─ ~$readme_tokens tokens | $readme_lines lines"
    fi
  fi

  # ── Total package summary ──
  if [ "$OUTPUT_MODE" = "terminal" ]; then
    echo ""
    echo "  $(_bold "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")"

    local total_zone_indicator
    total_zone_indicator=$(token_zone_indicator "$total_tokens" "$TOTAL_TOKEN_SAFE" "$TOTAL_TOKEN_WARN")

    echo "  $(_bold "TOTAL SKILL PACKAGE") $total_zone_indicator"
    echo ""
    echo "    $(format_tokens_colored "$total_tokens" "$TOTAL_TOKEN_SAFE" "$TOTAL_TOKEN_WARN" "tokens") (estimated)"
    local total_gauge
    total_gauge=$(bar_gauge_colored "$total_tokens" "$TOTAL_TOKEN_DANGER" 25 "$TOTAL_TOKEN_SAFE" "$TOTAL_TOKEN_WARN")
    echo "    $total_gauge"
    echo "    $total_chars chars | $total_words words | $total_lines lines | $file_count files"
    echo ""
  fi

  local uses_progressive=false
  if [ -d "references" ] && [ -f "$SKILL_FILE" ]; then
    local ref_link_count
    ref_link_count=$(grep -cE '\]\(references/' "$SKILL_FILE" 2>/dev/null || true)
    ref_link_count=${ref_link_count:-0}
    if [ "$ref_link_count" -gt 0 ]; then
      uses_progressive=true
    fi
  fi

  local ctx_200k_pct ctx_128k_pct skill_only_200k_pct
  ctx_200k_pct=$(( (total_tokens * 100) / 200000 ))
  ctx_128k_pct=$(( (total_tokens * 100) / 128000 ))
  if [ -f "$SKILL_FILE" ]; then
    skill_only_200k_pct=$(( (_S_BODY_TOKENS * 100) / 200000 ))
  else
    skill_only_200k_pct=0
  fi

  if [ "$OUTPUT_MODE" = "terminal" ]; then
    echo "  $(_bold "Context Window Impact:")"
    echo "    $(_dim "Agent tools (Cursor, Windsurf, Copilot) typically use ~200K context")"
    echo "    $(_dim "regardless of the underlying model's max window.")"
    echo ""
    echo "    ├─ Agent context (200K):  ~${ctx_200k_pct}% if all files loaded"
    echo "    ├─ Agent context (128K):  ~${ctx_128k_pct}% if all files loaded"
    if [ "$uses_progressive" = true ]; then
      echo "    ├─ $(_green "SKILL.md only:       ~${skill_only_200k_pct}% of 200K") (initial activation cost)"
      echo "    └─ $(_dim "Progressive disclosure — references load on demand, not upfront")"
    else
      echo "    └─ $(_yellow "Monolithic — entire skill loads at once (no references/ linked)")"
    fi
    echo ""
  fi
  if [ "$uses_progressive" = true ]; then
    if [ "$total_tokens" -le "$TOTAL_TOKEN_SAFE" ]; then
      _pass "Package is well-optimized for token efficiency"
    elif [ "$total_tokens" -le "$TOTAL_TOKEN_WARN" ]; then
      _pass "Package size is fine — progressive disclosure loads files on demand"
    else
      _info "Large package (~$total_tokens tokens) — ensure no dead/orphaned references"
      _detail "Total size is informational with progressive disclosure; individual file sizes are the real quality gate"
    fi
  else
    if [ "$total_tokens" -le "$TOKEN_BUDGET" ]; then
      _pass "Monolithic skill is within token budget"
    elif [ "$total_tokens" -le "$TOKEN_DANGER_ZONE" ]; then
      _warn "Monolithic skill (~$total_tokens tokens) exceeds $TOKEN_BUDGET budget"
      _detail "Move detailed content to references/ for on-demand loading"
    else
      _warn "Monolithic skill (~$total_tokens tokens) is very large"
      _detail "Split into SKILL.md + references/ for progressive disclosure"
    fi
  fi
}

# ── [11] Content Quality Metrics ─────────────────────────────────

check_content_quality() {
  section "Content Quality Metrics"

  local total_code_blocks=0
  local total_headings=0

  if [ -f "$SKILL_FILE" ]; then
    local code_blocks headings internal_links external_links
    code_blocks=$(safe_count grep -c '```' "$SKILL_FILE")
    code_blocks=$((code_blocks / 2))

    headings=$(safe_count grep -c '^#' "$SKILL_FILE")
    internal_links=$(safe_count grep -c '\](references/' "$SKILL_FILE")
    external_links=$(safe_count grep -cE '\]\(https?://' "$SKILL_FILE")

    echo ""
    echo "  $(_bold "SKILL.md Structure:")"
    echo "    ├─ $headings heading(s) providing navigation"
    echo "    ├─ $code_blocks code example(s)"
    echo "    ├─ $internal_links internal link(s) to references"
    echo "    └─ $external_links external link(s)"

    total_code_blocks=$code_blocks
    total_headings=$headings

    if [ "$headings" -lt 3 ]; then
      _info "Consider adding more headings for better navigation"
    fi

    if [ "$code_blocks" -lt 2 ]; then
      _info "Consider adding code examples for clarity"
    fi
  fi

  if [ -d "references" ]; then
    echo ""
    echo "  $(_bold "Reference Files Quality:")"

    local ref_with_code=0
    local ref_without_code=0
    local total_ref_headings=0

    while IFS= read -r file; do
      local file_code_blocks file_headings
      file_code_blocks=$(safe_count grep -c '```' "$file")
      file_code_blocks=$((file_code_blocks / 2))
      file_headings=$(safe_count grep -c '^#' "$file")

      total_code_blocks=$((total_code_blocks + file_code_blocks))
      total_ref_headings=$((total_ref_headings + file_headings))

      if [ "$file_code_blocks" -gt 0 ]; then
        ref_with_code=$((ref_with_code + 1))
      else
        ref_without_code=$((ref_without_code + 1))
      fi
    done < <(find references -name '*.md' -type f)

    local ref_count
    ref_count=$(find references -name '*.md' -type f | wc -l | tr -d ' ')

    echo "    ├─ $ref_with_code of $ref_count files contain code examples"
    echo "    ├─ $total_ref_headings total headings across references"
    echo "    └─ $total_code_blocks total code blocks in package"

    if [ "$ref_without_code" -gt 0 ]; then
      _info "$ref_without_code reference file(s) have no code examples"
      _detail "Code examples help agents understand expected patterns"
    fi
  fi

  # Keyword density analysis
  if [ -f "$SKILL_FILE" ]; then
    echo ""
    echo "  $(_bold "Trigger Keyword Analysis:")"

    local compose_mentions kotlin_mentions android_mentions kmp_mentions
    compose_mentions=$(grep -ioE '(compose|composable|@Composable|jetpack)' "$SKILL_FILE" 2>/dev/null | wc -l | tr -d ' ' || true)
    kotlin_mentions=$(grep -ioE '(kotlin|coroutine|flow|stateflow|channel)' "$SKILL_FILE" 2>/dev/null | wc -l | tr -d ' ' || true)
    android_mentions=$(grep -ioE '(android|viewmodel|hilt|koin|room|datastore)' "$SKILL_FILE" 2>/dev/null | wc -l | tr -d ' ' || true)
    kmp_mentions=$(grep -ioE '(multiplatform|kmp|cmp|commonmain|ios|desktop)' "$SKILL_FILE" 2>/dev/null | wc -l | tr -d ' ' || true)

    compose_mentions=${compose_mentions:-0}
    kotlin_mentions=${kotlin_mentions:-0}
    android_mentions=${android_mentions:-0}
    kmp_mentions=${kmp_mentions:-0}

    echo "    ├─ Compose/UI:     $compose_mentions mentions"
    echo "    ├─ Kotlin/Flow:    $kotlin_mentions mentions"
    echo "    ├─ Android/DI:     $android_mentions mentions"
    echo "    └─ Multiplatform:  $kmp_mentions mentions"

    local total_keywords=$((compose_mentions + kotlin_mentions + android_mentions + kmp_mentions))
    if [ "$total_keywords" -lt 10 ]; then
      _info "Low keyword density may reduce skill trigger accuracy"
      _detail "Ensure description and body mention key terms agents should recognize"
    else
      _pass "Good keyword coverage for skill triggering ($total_keywords mentions)"
    fi
  fi
}

# ── [12] Agent Metadata ──────────────────────────────────────────

check_agents_metadata() {
  section "Agent Metadata (Codex)"

  if [ ! -f "agents/openai.yaml" ]; then
    _info "No agents/openai.yaml — optional, configures Codex app UI and policy"
    return
  fi

  _pass "agents/openai.yaml present"

  if grep -q '^interface:' agents/openai.yaml; then
    if grep -q 'display_name:' agents/openai.yaml; then
      local display_name
      display_name=$(grep 'display_name:' agents/openai.yaml | sed 's/.*display_name:[[:space:]]*//' | tr -d '"')
      _pass "display_name: '$display_name'"
    else
      _info "No display_name — Codex uses skill name"
    fi

    if grep -q 'short_description:' agents/openai.yaml; then
      _pass "short_description set"
    else
      _info "No short_description — Codex uses SKILL.md description"
    fi

    if grep -q 'default_prompt:' agents/openai.yaml; then
      _pass "default_prompt set"
    fi

    if grep -q 'brand_color:' agents/openai.yaml; then
      _pass "brand_color set"
    fi

    local icon_fields
    icon_fields=$(grep -oE '(icon_small|icon_large):[[:space:]]*"[^"]+"' agents/openai.yaml 2>/dev/null || true)
    if [ -n "$icon_fields" ]; then
      echo "$icon_fields" | while IFS= read -r line; do
        local field icon_path
        field=$(echo "$line" | cut -d: -f1 | tr -d ' ')
        icon_path=$(echo "$line" | sed 's/.*"\(.*\)"/\1/')
        if [ -f "$icon_path" ]; then
          _pass "$field: $icon_path"
        else
          _warn "$field: '$icon_path' → file not found"
          ci_annotate "warning" "file=agents/openai.yaml::$field file missing: $icon_path"
        fi
      done
    fi
  fi

  if grep -q '^policy:' agents/openai.yaml; then
    if grep -q 'allow_implicit_invocation:' agents/openai.yaml; then
      local implicit
      implicit=$(grep 'allow_implicit_invocation:' agents/openai.yaml | sed 's/.*allow_implicit_invocation:[[:space:]]*//')
      _pass "allow_implicit_invocation: $implicit"
    fi
  fi

  if grep -q '^dependencies:' agents/openai.yaml; then
    _pass "dependencies declared"
  fi
}

# ── [13] Security Scan ───────────────────────────────────────────

check_security() {
  section "Security Scan"

  local secret_count=0
  local path_count=0
  local cmd_count=0

  # ── Secrets detection (11 patterns from skill-tools / skill-validator) ──
  local -a secret_patterns=(
    'sk-[a-zA-Z0-9]{20,}'
    'sk_live_[a-zA-Z0-9]+'
    'sk_test_[a-zA-Z0-9]+'
    'ghp_[a-zA-Z0-9]{36}'
    'gho_[a-zA-Z0-9]{36}'
    'ghu_[a-zA-Z0-9]{36}'
    'ghs_[a-zA-Z0-9]{36}'
    'ghr_[a-zA-Z0-9]{36}'
    'xoxb-[a-zA-Z0-9-]+'
    'xoxp-[a-zA-Z0-9-]+'
    'AKIA[0-9A-Z]{16}'
  )

  while IFS= read -r file; do
    for pattern in "${secret_patterns[@]}"; do
      local matches
      matches=$(grep -nE "$pattern" "$file" 2>/dev/null | head -1 || true)
      if [ -n "$matches" ]; then
        secret_count=$((secret_count + 1))
        local line_num
        line_num=$(echo "$matches" | cut -d: -f1)
        _error "$file:$line_num — potential secret/API key detected"
        _detail "Pattern: $pattern"
        ci_annotate "error" "file=$file,line=$line_num::Potential secret detected"
      fi
    done

    # PEM private key headers
    local pem_match
    pem_match=$(grep -n 'BEGIN.*PRIVATE KEY' "$file" 2>/dev/null | head -1 || true)
    if [ -n "$pem_match" ]; then
      secret_count=$((secret_count + 1))
      local line_num
      line_num=$(echo "$pem_match" | cut -d: -f1)
      _error "$file:$line_num — private key header detected"
      ci_annotate "error" "file=$file,line=$line_num::Private key detected"
    fi

    # JWT tokens
    local jwt_match
    jwt_match=$(grep -nE 'eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.' "$file" 2>/dev/null | head -1 || true)
    if [ -n "$jwt_match" ]; then
      secret_count=$((secret_count + 1))
      local line_num
      line_num=$(echo "$jwt_match" | cut -d: -f1)
      _error "$file:$line_num — JWT token detected"
      ci_annotate "error" "file=$file,line=$line_num::JWT token detected"
    fi
  done < <(find . -name '*.md' -not -path './.git/*' | sort)

  _S_SECRETS=$secret_count

  if [ "$secret_count" -eq 0 ]; then
    _pass "No API keys or secrets detected (13 patterns checked)"
  fi

  # ── Hardcoded absolute paths ──
  echo ""
  _detail "Checking for hardcoded paths..."

  while IFS= read -r file; do
    local path_matches
    path_matches=$(grep -nE '(/Users/[a-zA-Z]|/home/[a-zA-Z]|C:\\Users\\)' "$file" 2>/dev/null || true)
    if [ -n "$path_matches" ]; then
      while IFS= read -r match; do
        path_count=$((path_count + 1))
        local line_num
        line_num=$(echo "$match" | cut -d: -f1)
        _warn "$file:$line_num — hardcoded absolute path"
        _detail "$(echo "$match" | cut -d: -f2- | sed 's/^[[:space:]]*//' | head -c 80)"
      done <<< "$path_matches"
    fi
  done < <(find . -name '*.md' -not -path './.git/*' | sort)

  _S_HARDCODED=$path_count

  if [ "$path_count" -eq 0 ]; then
    _pass "No hardcoded absolute paths"
  fi

  # ── Dangerous commands ──
  echo ""
  _detail "Checking for dangerous commands..."

  local -a dangerous_patterns=(
    'rm -rf /'
    'sudo rm '
    'DROP TABLE'
    'DROP DATABASE'
    'chmod 777'
  )
  local -a dangerous_regex=(
    'curl .*\| *sh'
    'wget .*\| *sh'
  )

  while IFS= read -r file; do
    for pattern in "${dangerous_patterns[@]}"; do
      local matches
      matches=$(grep -nF "$pattern" "$file" 2>/dev/null | head -1 || true)
      if [ -n "$matches" ]; then
        cmd_count=$((cmd_count + 1))
        local line_num
        line_num=$(echo "$matches" | cut -d: -f1)
        _warn "$file:$line_num — potentially dangerous command"
        _detail "Matched: $pattern"
        ci_annotate "warning" "file=$file,line=$line_num::Dangerous command pattern"
      fi
    done
    for pattern in "${dangerous_regex[@]}"; do
      local matches
      matches=$(grep -nE "$pattern" "$file" 2>/dev/null | head -1 || true)
      if [ -n "$matches" ]; then
        cmd_count=$((cmd_count + 1))
        local line_num
        line_num=$(echo "$matches" | cut -d: -f1)
        _warn "$file:$line_num — potentially dangerous command"
        _detail "Matched: $pattern"
        ci_annotate "warning" "file=$file,line=$line_num::Dangerous command pattern"
      fi
    done
  done < <(find . -name '*.md' -not -path './.git/*' | sort)

  _S_DANGEROUS=$cmd_count

  if [ "$cmd_count" -eq 0 ]; then
    _pass "No dangerous shell commands detected"
  fi

  echo ""
  echo "  $(_dim "  ┌─────────────────────────────────────────────┐")"
  printf "  $(_dim "  │") Secrets: %-4s  Paths: %-4s  Commands: %-4s $(_dim "│")\n" "$secret_count" "$path_count" "$cmd_count"
  echo "  $(_dim "  └─────────────────────────────────────────────┘")"
}

# ── [14] Heading Hierarchy & Duplicates ──────────────────────────

check_heading_hierarchy() {
  section "Heading Hierarchy & Duplicates"

  local skip_issues=0
  local dup_issues=0
  local files_checked=0

  while IFS= read -r file; do
    files_checked=$((files_checked + 1))

    local prev_level=0
    local line_num=0
    local headings_seen=""

    while IFS= read -r line; do
      line_num=$((line_num + 1))
      case "$line" in
        '#'*)
          local stripped_prefix
          stripped_prefix="${line%%[^#]*}"
          local level=${#stripped_prefix}
          local text
          text=$(echo "$line" | sed 's/^#* *//')

          # MD001: heading level increment check
          if [ "$prev_level" -gt 0 ] && [ "$level" -gt "$((prev_level + 1))" ]; then
            skip_issues=$((skip_issues + 1))
            _warn "$file:$line_num — heading skip H$prev_level → H$level"
            _detail "$text"
            ci_annotate "warning" "file=$file,line=$line_num::Heading level skip (H$prev_level to H$level)"
          fi
          prev_level=$level

          # MD024: duplicate heading check (same level, same text)
          local key="${level}:${text}"
          if echo "$headings_seen" | grep -qF "<<${key}>>"; then
            dup_issues=$((dup_issues + 1))
            _warn "$file:$line_num — duplicate heading: '$text' (H$level)"
            ci_annotate "warning" "file=$file,line=$line_num::Duplicate heading '$text'"
          fi
          headings_seen="${headings_seen}<<${key}>>"
          ;;
      esac
    done < "$file"
  done < <(find . -name '*.md' -not -path './.git/*' | sort)

  if [ "$skip_issues" -eq 0 ]; then
    _pass "No heading level skips across $files_checked files (MD001)"
  fi

  if [ "$dup_issues" -eq 0 ]; then
    _pass "No duplicate sibling headings across $files_checked files (MD024)"
  fi

  echo ""
  _detail "Checked $files_checked files | Level skips: $skip_issues | Duplicates: $dup_issues"
}

# ── [15] Quality Score ───────────────────────────────────────────

compute_quality_score() {
  section "Quality Score"

  local desc_score=0
  local clarity_score=0
  local spec_score=0
  local progressive_score=0
  local security_score=10

  _check_mark() {
    if [ "$1" = "1" ]; then printf "%s" "$(_green "✓")"; else printf "%s" "$(_red "✗")"; fi
  }

  # ── Description Quality (30 pts) ──
  local d1=0 d2=0 d3=0 d4=0 d5=0 d6=0 d7=0
  [ "$_S_HAS_DESC" = true ]              && { desc_score=$((desc_score + 5)); d1=1; }
  [ "$_S_DESC_LEN" -ge "$DESC_MIN_USEFUL" ] && { desc_score=$((desc_score + 3)); d2=1; }
  [ "$_S_DESC_WHAT" = true ]             && { desc_score=$((desc_score + 5)); d3=1; }
  [ "$_S_DESC_WHEN" = true ]             && { desc_score=$((desc_score + 5)); d4=1; }
  [ "$_S_DESC_FIRST_PERSON" = false ]    && { desc_score=$((desc_score + 4)); d5=1; }
  [ "$_S_DESC_GENERIC" = false ]         && { desc_score=$((desc_score + 4)); d6=1; }
  [ "$_S_DESC_NEGATIVES" = true ]        && { desc_score=$((desc_score + 4)); d7=1; }

  # ── Instruction Clarity (25 pts) ──
  local c1=0 c2=0 c3=0 c4=0 c5=0 c6=0
  [ "$_S_CODE_BLOCKS" -ge 1 ] && { clarity_score=$((clarity_score + 5)); c1=1; }
  [ "$_S_CODE_BLOCKS" -ge 3 ] && { clarity_score=$((clarity_score + 5)); c2=1; }
  [ "$_S_HEADINGS" -ge 3 ]    && { clarity_score=$((clarity_score + 5)); c3=1; }
  [ "$_S_HEADINGS" -ge 5 ]    && { clarity_score=$((clarity_score + 3)); c4=1; }
  [ "$_S_REF_LINKS" -gt 0 ]   && { clarity_score=$((clarity_score + 4)); c5=1; }
  [ "$_S_REF_LINKS" -ge 5 ]   && { clarity_score=$((clarity_score + 3)); c6=1; }

  # ── Spec Compliance (20 pts) ──
  local s1=0 s2=0 s3=0 s4=0 s5=0 s6=0
  [ "$_S_HAS_NAME" = true ]                  && { spec_score=$((spec_score + 4)); s1=1; }
  [ "$_S_NAME_OK" = true ]                   && { spec_score=$((spec_score + 4)); s2=1; }
  [ "$_S_HAS_DESC" = true ]                  && { spec_score=$((spec_score + 4)); s3=1; }
  [ "$_S_BODY_TOKENS" -le "$TOKEN_BUDGET" ]  && { spec_score=$((spec_score + 4)); s4=1; }
  [ "$_S_BODY_LINES" -le "$BODY_MAX_LINES" ] && { spec_score=$((spec_score + 2)); s5=1; }
  [ "$_S_FENCES_OK" = true ]                 && { spec_score=$((spec_score + 2)); s6=1; }

  # ── Progressive Disclosure (15 pts) ──
  local p1=0 p2=0 p3=0 p4=0
  [ "$_S_HAS_REFS_DIR" = true ] && { progressive_score=$((progressive_score + 5)); p1=1; }
  [ "$_S_REFS_LINKED" -gt 0 ]  && { progressive_score=$((progressive_score + 5)); p2=1; }
  if [ "$_S_REFS_TOTAL" -gt 0 ] && [ "$_S_REFS_LINKED" -eq "$_S_REFS_TOTAL" ]; then
    progressive_score=$((progressive_score + 3)); p3=1
  fi
  [ "$_S_BODY_LINES" -lt "$BODY_MAX_LINES" ] && { progressive_score=$((progressive_score + 2)); p4=1; }

  # ── Security (10 pts — start at 10, deduct for issues) ──
  local x1=1 x2=1 x3=1
  if [ "$_S_SECRETS" -gt 0 ]; then security_score=$((security_score - 5)); x1=0; fi
  if [ "$_S_HARDCODED" -gt 0 ]; then security_score=$((security_score - 3)); x2=0; fi
  if [ "$_S_DANGEROUS" -gt 0 ]; then security_score=$((security_score - 2)); x3=0; fi
  [ "$security_score" -lt 0 ] && security_score=0

  local total_score=$((desc_score + clarity_score + spec_score + progressive_score + security_score))

  QUALITY_SCORE=$total_score
  QUALITY_GRADE=$(letter_grade "$total_score")
  QUALITY_DESC=$desc_score
  QUALITY_CLARITY=$clarity_score
  QUALITY_SPEC=$spec_score
  QUALITY_PROGRESSIVE=$progressive_score
  QUALITY_SECURITY=$security_score

  # ── Display: clean bar chart overview (terminal only) ──
  if [ "$OUTPUT_MODE" = "terminal" ]; then

  _dim_bar() {
    local name="$1" score="$2" max="$3"
    local gauge pct
    if [ "$max" -le 0 ]; then pct=0
    else pct=$(( (score * 100) / max )); fi
    gauge=$(bar_gauge "$score" "$max" 15)

    local colored_gauge
    if [ "$pct" -ge 80 ]; then
      colored_gauge=$(_green "$gauge")
    elif [ "$pct" -ge 60 ]; then
      colored_gauge=$(_yellow "$gauge")
    else
      colored_gauge=$(_red "$gauge")
    fi

    if [ "$score" -eq "$max" ]; then
      printf "    %-24s %s  %2d / %-2d  $(_green "✓")\n" "$name" "$colored_gauge" "$score" "$max"
    else
      printf "    %-24s %s  %2d / %-2d\n" "$name" "$colored_gauge" "$score" "$max"
    fi
  }

  echo ""
  echo "  $(_bold "Score Overview:")"
  echo ""
  _dim_bar "Description Quality" "$desc_score" "30"
  _dim_bar "Instruction Clarity" "$clarity_score" "25"
  _dim_bar "Spec Compliance" "$spec_score" "20"
  _dim_bar "Progressive Disclosure" "$progressive_score" "15"
  _dim_bar "Security" "$security_score" "10"

  echo ""
  echo "    $(_dim "$(printf '%.0s─' $(seq 1 52))")"

  local total_gauge
  total_gauge=$(bar_gauge "$total_score" 100 20)
  local colored_total
  if [ "$total_score" -ge 85 ]; then
    colored_total=$(_bold_green "$total_gauge")
  elif [ "$total_score" -ge 65 ]; then
    colored_total=$(_bold_yellow "$total_gauge")
  else
    colored_total=$(_bold_red "$total_gauge")
  fi

  printf "    %-24s %s  %d/100   Grade: %s\n" "$(_bold "TOTAL")" "$colored_total" "$total_score" "$(grade_color "$total_score")"

  fi  # end terminal-only display

  # ── Collect failed sub-checks with sources and actionable fixes ──
  # Sources verified against:
  #   [spec]       agentskills.io/specification
  #   [official]   agentskills.io/skill-creation/best-practices
  #                agentskills.io/skill-creation/optimizing-descriptions
  #   [community]  mdskills.ai/docs/skill-best-practices

  local fix_count=0
  local -a fix_labels=()
  local -a fix_sources=()
  local -a fix_dims=()

  [ "$d1" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Description"); fix_labels+=("Add a 'description:' field to frontmatter (+5)"); fix_sources+=("spec: required field — agentskills.io/specification#description-field"); }
  [ "$d2" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Description"); fix_labels+=("Write a longer description (>=${DESC_MIN_USEFUL} chars) (+3)"); fix_sources+=("official: 'A few sentences to a short paragraph' — agentskills.io/skill-creation/optimizing-descriptions"); }
  [ "$d3" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Description"); fix_labels+=("Add action verbs: build, generate, validate, extract, etc. (+5)"); fix_sources+=("spec: 'Describes what the skill does' — agentskills.io/specification#description-field"); }
  [ "$d4" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Description"); fix_labels+=("Add 'Use when...' trigger phrase to description (+5)"); fix_sources+=("official: 'Use imperative phrasing: Use this skill when...' — agentskills.io/skill-creation/optimizing-descriptions"); }
  [ "$d5" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Description"); fix_labels+=("Rewrite in third person — remove 'I can/will/help' (+4)"); fix_sources+=("community: 'first person causes discovery problems' — mdskills.ai/docs/skill-best-practices"); }
  [ "$d6" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Description"); fix_labels+=("Replace generic verbs (manage, handle) with specific ones (+4)"); fix_sources+=("community: 'Be specific about format, operation, trigger' — mdskills.ai/docs/skill-best-practices"); }
  [ "$d7" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Description"); fix_labels+=("Add boundary markers: 'Not for...', 'Do not use when...' (+4)"); fix_sources+=("official: 'Add specificity about what the skill does not do' — agentskills.io/skill-creation/optimizing-descriptions"); }
  [ "$c1" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Clarity"); fix_labels+=("Add at least 1 fenced code block to SKILL.md body (+5)"); fix_sources+=("spec: recommended section 'Examples of inputs and outputs' — agentskills.io/specification#body-content"); }
  [ "$c2" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Clarity"); fix_labels+=("Add 3+ code examples to SKILL.md (+5)"); fix_sources+=("official: 'a working example tends to outperform exhaustive documentation' — agentskills.io/skill-creation/best-practices"); }
  [ "$c3" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Clarity"); fix_labels+=("Add 3+ markdown headings for navigation (+5)"); fix_sources+=("community: 'structure for agent scanning' — mdskills.ai/docs/skill-best-practices"); }
  [ "$c4" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Clarity"); fix_labels+=("Add 5+ headings for deeper structure (+3)"); fix_sources+=("community: structured content aids agent navigation — mdskills.ai/docs/skill-best-practices"); }
  [ "$c5" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Clarity"); fix_labels+=("Link to at least one reference file from SKILL.md body (+4)"); fix_sources+=("official: 'tell the agent when to load each file' — agentskills.io/skill-creation/best-practices"); }
  [ "$c6" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Clarity"); fix_labels+=("Link to 5+ reference files for full coverage (+3)"); fix_sources+=("official: progressive disclosure via on-demand loading — agentskills.io/specification#progressive-disclosure"); }
  [ "$s4" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Spec"); fix_labels+=("Reduce SKILL.md to <$TOKEN_BUDGET tokens — move content to references/ (+4)"); fix_sources+=("spec: '<5000 tokens recommended' — agentskills.io/specification#progressive-disclosure"); }
  [ "$s5" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Spec"); fix_labels+=("Reduce SKILL.md body to <$BODY_MAX_LINES lines (+2)"); fix_sources+=("spec: 'under 500 lines' — agentskills.io/specification#progressive-disclosure"); }
  [ "$s6" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Spec"); fix_labels+=("Fix unclosed code fences in markdown files (+2)"); fix_sources+=("spec: valid markdown required for agent parsing"); }
  [ "$p1" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Disclosure"); fix_labels+=("Create a references/ directory for detailed docs (+5)"); fix_sources+=("spec: optional directory for on-demand loading — agentskills.io/specification#references"); }
  [ "$p2" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Disclosure"); fix_labels+=("Add links to reference files from SKILL.md body (+5)"); fix_sources+=("official: 'tell the agent when to load each file' — agentskills.io/skill-creation/best-practices"); }
  [ "$p3" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Disclosure"); fix_labels+=("Link all reference files from SKILL.md — orphaned files found (+3)"); fix_sources+=("spec: 'use relative paths from skill root' — agentskills.io/specification#file-references"); }
  [ "$p4" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Disclosure"); fix_labels+=("Keep body under $BODY_MAX_LINES lines (+2)"); fix_sources+=("spec: 'under 500 lines' — agentskills.io/specification#progressive-disclosure"); }
  [ "$x1" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Security"); fix_labels+=("Remove detected API keys/secrets from markdown files (+5)"); fix_sources+=("community: 'Never hardcode credentials' — mdskills.ai/docs/skill-best-practices"); }
  [ "$x2" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Security"); fix_labels+=("Replace hardcoded paths (/Users/...) with relative paths (+3)"); fix_sources+=("spec: 'use relative paths from the skill root' — agentskills.io/specification#file-references"); }
  [ "$x3" = "0" ] && { fix_count=$((fix_count+1)); fix_dims+=("Security"); fix_labels+=("Remove or guard dangerous commands (rm -rf, chmod 777) (+2)"); fix_sources+=("community: 'Shell commands need guardrails' — mdskills.ai/docs/skill-best-practices"); }

  # ── Display: "How to Improve" section with sourced fixes (terminal only) ──
  if [ "$OUTPUT_MODE" = "terminal" ]; then
    if [ "$fix_count" -gt 0 ]; then
      echo ""
      echo ""
      echo "  $(_bold "┌────────────────────────────────────────────────────────┐")"
      echo "  $(_bold "│")  $(_bold "HOW TO REACH 100/100")  $(_dim "($fix_count items, by impact)")          $(_bold "│")"
      echo "  $(_bold "└────────────────────────────────────────────────────────┘")"

      local prev_dim=""
      local i
      for ((i=0; i<fix_count; i++)); do
        local dim="${fix_dims[$i]}"
        local label="${fix_labels[$i]}"
        local source="${fix_sources[$i]}"

        if [ "$dim" != "$prev_dim" ]; then
          echo ""
          echo "  $(_bold_cyan "$dim:")"
          prev_dim="$dim"
        fi

        echo "    $(_yellow "→") $label"
        echo "      $(_dim "$source")"
      done

      echo ""
      echo "  $(_dim "Sources: spec = agentskills.io/specification")"
      echo "  $(_dim "         official = agentskills.io/skill-creation/*")"
      echo "  $(_dim "         community = mdskills.ai/docs/skill-best-practices")"
    else
      echo ""
      _pass "Perfect score — no improvements needed"
    fi
  fi
}

# ════════════════════════════════════════════════════════════════════
#  OUTPUT MODES
# ════════════════════════════════════════════════════════════════════

print_json() {
  local elapsed=$(( SECONDS - SCAN_START ))

  # Collect findings into JSON arrays
  local errors_json="[]" warnings_json="[]" info_json="[]"

  local err_items=""
  while IFS='|' read -r sev sec msg; do
    [ -z "$sev" ] && continue
    msg=$(echo "$msg" | sed 's/"/\\"/g')
    sec=$(echo "$sec" | sed 's/"/\\"/g')
    case "$sev" in
      ERROR) err_items="${err_items}{\"section\":\"$sec\",\"message\":\"$msg\"}," ;;
    esac
  done < "$FINDINGS_FILE"

  local warn_items=""
  while IFS='|' read -r sev sec msg; do
    [ -z "$sev" ] && continue
    msg=$(echo "$msg" | sed 's/"/\\"/g')
    sec=$(echo "$sec" | sed 's/"/\\"/g')
    case "$sev" in
      WARN) warn_items="${warn_items}{\"section\":\"$sec\",\"message\":\"$msg\"}," ;;
    esac
  done < "$FINDINGS_FILE"

  local info_items=""
  while IFS='|' read -r sev sec msg; do
    [ -z "$sev" ] && continue
    msg=$(echo "$msg" | sed 's/"/\\"/g')
    sec=$(echo "$sec" | sed 's/"/\\"/g')
    case "$sev" in
      INFO) info_items="${info_items}{\"section\":\"$sec\",\"message\":\"$msg\"}," ;;
    esac
  done < "$FINDINGS_FILE"

  # Strip trailing commas and wrap
  err_items="${err_items%,}"
  warn_items="${warn_items%,}"
  info_items="${info_items%,}"
  [ -n "$err_items" ] && errors_json="[$err_items]"
  [ -n "$warn_items" ] && warnings_json="[$warn_items]"
  [ -n "$info_items" ] && info_json="[$info_items]"

  local result="PASS"
  [ "$WARNINGS" -gt 0 ] && result="PASS_WITH_WARNINGS"
  [ "$ERRORS" -gt 0 ] && result="FAIL"

  cat <<ENDJSON
{
  "version": "4.0",
  "skill": "$(pwd)",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "duration_seconds": $elapsed,
  "result": "$result",
  "counts": {
    "checks": $CHECKS_RUN,
    "errors": $ERRORS,
    "warnings": $WARNINGS,
    "info": $INFO_COUNT
  },
  "quality_score": {
    "total": $QUALITY_SCORE,
    "grade": "$QUALITY_GRADE",
    "dimensions": {
      "description_quality": { "score": $QUALITY_DESC, "max": 30 },
      "instruction_clarity": { "score": $QUALITY_CLARITY, "max": 25 },
      "spec_compliance": { "score": $QUALITY_SPEC, "max": 20 },
      "progressive_disclosure": { "score": $QUALITY_PROGRESSIVE, "max": 15 },
      "security": { "score": $QUALITY_SECURITY, "max": 10 }
    }
  },
  "token_analysis": {
    "skill_md_tokens": $_S_BODY_TOKENS,
    "body_lines": $_S_BODY_LINES,
    "code_blocks": $_S_CODE_BLOCKS,
    "headings": $_S_HEADINGS,
    "reference_links": $_S_REF_LINKS,
    "reference_files_total": $_S_REFS_TOTAL,
    "reference_files_linked": $_S_REFS_LINKED
  },
  "findings": {
    "errors": $errors_json,
    "warnings": $warnings_json,
    "info": $info_json
  }
}
ENDJSON
}

print_markdown() {
  local elapsed=$(( SECONDS - SCAN_START ))

  local result_icon result_text
  if [ "$ERRORS" -gt 0 ]; then
    result_icon="x" result_text="FAIL — $ERRORS error(s), $WARNINGS warning(s)"
  elif [ "$WARNINGS" -gt 0 ]; then
    result_icon="!" result_text="PASS with $WARNINGS warning(s)"
  else
    result_icon="+" result_text="All checks passed"
  fi

  cat <<ENDMD
# Agent Skill Scan Report

**Score: $QUALITY_SCORE/100 ($QUALITY_GRADE)** | Result: $result_text | Duration: ${elapsed}s

## Score Breakdown

| Dimension | Score | Max | % |
|---|---|---|---|
| Description Quality | $QUALITY_DESC | 30 | $(( (QUALITY_DESC * 100) / 30 ))% |
| Instruction Clarity | $QUALITY_CLARITY | 25 | $(( (QUALITY_CLARITY * 100) / 25 ))% |
| Spec Compliance | $QUALITY_SPEC | 20 | $(( (QUALITY_SPEC * 100) / 20 ))% |
| Progressive Disclosure | $QUALITY_PROGRESSIVE | 15 | $(( (QUALITY_PROGRESSIVE * 100) / 15 ))% |
| Security | $QUALITY_SECURITY | 10 | $(( (QUALITY_SECURITY * 100) / 10 ))% |
| **Total** | **$QUALITY_SCORE** | **100** | **${QUALITY_SCORE}%** |

## Summary

| Metric | Count |
|---|---|
| Sections checked | $CHECKS_RUN |
| Errors | $ERRORS |
| Warnings | $WARNINGS |
| Suggestions | $INFO_COUNT |

## Token Analysis

| File | Tokens | Lines |
|---|---|---|
| SKILL.md | ~$_S_BODY_TOKENS | $_S_BODY_LINES |
| Reference files | $_S_REFS_TOTAL files | $_S_REFS_LINKED linked |
ENDMD

  # Findings
  local total_findings
  total_findings=$(wc -l < "$FINDINGS_FILE" | tr -d ' ')

  if [ "$total_findings" -gt 0 ]; then
    echo ""
    echo "## Findings"
    echo ""

    local has_errors has_warnings has_info
    has_errors=$(grep -c "^ERROR|" "$FINDINGS_FILE" 2>/dev/null || true)
    has_warnings=$(grep -c "^WARN|" "$FINDINGS_FILE" 2>/dev/null || true)
    has_info=$(grep -c "^INFO|" "$FINDINGS_FILE" 2>/dev/null || true)

    if [ "${has_errors:-0}" -gt 0 ]; then
      echo "### Errors"
      echo ""
      grep "^ERROR|" "$FINDINGS_FILE" | while IFS='|' read -r _ sec msg; do
        echo "- **$sec**: $msg"
      done
      echo ""
    fi

    if [ "${has_warnings:-0}" -gt 0 ]; then
      echo "### Warnings"
      echo ""
      grep "^WARN|" "$FINDINGS_FILE" | while IFS='|' read -r _ sec msg; do
        echo "- **$sec**: $msg"
      done
      echo ""
    fi

    if [ "${has_info:-0}" -gt 0 ]; then
      echo "### Suggestions"
      echo ""
      grep "^INFO|" "$FINDINGS_FILE" | while IFS='|' read -r _ sec msg; do
        echo "- **$sec**: $msg"
      done
      echo ""
    fi
  fi

  echo "---"
  echo ""
  echo "_Validated against [agentskills.io/specification](https://agentskills.io/specification) | Scanner v4.0 | $(date '+%Y-%m-%d %H:%M:%S')_"
}

print_score_only() {
  if [ "$NO_COLOR" = "1" ]; then
    echo "$QUALITY_SCORE/100 $QUALITY_GRADE"
  else
    echo "$QUALITY_SCORE/100 $(grade_color "$QUALITY_SCORE")"
  fi
  [ "$ERRORS" -gt 0 ] && exit 1
  exit 0
}

# ════════════════════════════════════════════════════════════════════
#  REPORT (terminal)
# ════════════════════════════════════════════════════════════════════

print_report() {
  echo ""
  echo ""

  local elapsed=$(( SECONDS - SCAN_START ))

  _pad() {
    local text="$1" width="$2"
    local visible
    visible=$(echo "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local pad_len=$(( width - ${#visible} ))
    if [ "$pad_len" -lt 0 ]; then pad_len=0; fi
    printf '%s%*s' "$text" "$pad_len" ""
  }

  local W=58
  local line
  line=$(printf '%.0s═' $(seq 1 $W))
  local thin_line
  thin_line=$(printf '%.0s─' $(seq 1 $W))

  # ── Summary box ──
  echo "  $(_bold "╔${line}╗")"
  echo "  $(_bold "║")$(_pad "" $W)$(_bold "║")"
  echo "  $(_bold "║")$(_pad "          AGENT SKILL SCAN REPORT                       " $W)$(_bold "║")"
  echo "  $(_bold "║")$(_pad "                Scanner v4.0                             " $W)$(_bold "║")"
  echo "  $(_bold "║")$(_pad "" $W)$(_bold "║")"
  echo "  $(_bold "╠${line}╣")"
  echo "  ║$(_pad "" $W)║"
  echo "  ║  $(_pad "Checks run     :  $CHECKS_RUN sections" $(( W - 2 )))║"
  echo "  ║  $(_pad "$(_red "Errors")         :  $ERRORS" $(( W - 2 )))║"
  echo "  ║  $(_pad "$(_yellow "Warnings")       :  $WARNINGS" $(( W - 2 )))║"
  echo "  ║  $(_pad "$(_blue "Info")           :  $INFO_COUNT" $(( W - 2 )))║"
  echo "  ║  $(_pad "Duration       :  ${elapsed}s" $(( W - 2 )))║"
  echo "  ║$(_pad "" $W)║"
  echo "  $(_bold "╠${line}╣")"
  echo "  ║$(_pad "" $W)║"

  local result_text
  if [ "$ERRORS" -gt 0 ]; then
    result_text=$(_bold_red "FAIL")
  elif [ "$WARNINGS" -gt 0 ]; then
    result_text=$(_bold_yellow "PASS with warnings")
  else
    result_text=$(_bold_green "ALL CLEAR")
  fi

  echo "  ║  $(_pad "Result         :  $result_text" $(( W - 2 )))║"
  echo "  ║  $(_pad "Quality Score  :  $QUALITY_SCORE/100  ($(grade_color "$QUALITY_SCORE"))" $(( W - 2 )))║"
  echo "  ║$(_pad "" $W)║"
  echo "  $(_bold "╠${line}╣")"
  echo "  ║$(_pad "" $W)║"
  echo "  ║  $(_pad "Description    :  $QUALITY_DESC/30" $(( W - 2 )))║"
  echo "  ║  $(_pad "Clarity        :  $QUALITY_CLARITY/25" $(( W - 2 )))║"
  echo "  ║  $(_pad "Spec           :  $QUALITY_SPEC/20" $(( W - 2 )))║"
  echo "  ║  $(_pad "Progressive    :  $QUALITY_PROGRESSIVE/15" $(( W - 2 )))║"
  echo "  ║  $(_pad "Security       :  $QUALITY_SECURITY/10" $(( W - 2 )))║"
  echo "  ║$(_pad "" $W)║"
  echo "  $(_bold "╚${line}╝")"

  # ── Detailed findings ──
  local total_findings
  total_findings=$(wc -l < "$FINDINGS_FILE" | tr -d ' ')

  if [ "$total_findings" -gt 0 ]; then
    echo ""
    echo "  $(_bold "┌${thin_line}┐")"
    echo "  $(_bold "│")$(_pad "                  DETAILED FINDINGS                       " $W)$(_bold "│")"
    echo "  $(_bold "└${thin_line}┘")"

    _print_findings_by_severity() {
      local severity="$1" label="$2" color_fn="$3"
      local matches
      matches=$(grep "^${severity}|" "$FINDINGS_FILE" 2>/dev/null || true)
      [ -z "$matches" ] && return

      local count
      count=$(echo "$matches" | wc -l | tr -d ' ')

      echo ""
      echo "  $($color_fn "$label ($count)")"
      echo "  $(_dim "$(printf '%.0s─' $(seq 1 56))")"

      local prev_section=""
      while IFS='|' read -r _ sec msg; do
        if [ "$sec" != "$prev_section" ]; then
          echo ""
          echo "  $(_dim "[$sec]")"
          prev_section="$sec"
        fi
        echo "    $($color_fn "▸") $msg"
      done <<< "$matches"
    }

    _print_findings_by_severity "ERROR" "ERRORS" "_red"
    _print_findings_by_severity "WARN"  "WARNINGS" "_yellow"
    _print_findings_by_severity "INFO"  "SUGGESTIONS" "_blue"

    echo ""
    echo "  $(_dim "$(printf '%.0s─' $(seq 1 60))")"
  else
    echo ""
    echo "  $(_bold_green "No findings — skill package is in perfect shape.")"
  fi

  echo ""
  echo "  $(_dim "Validated against agentskills.io/specification")"
  echo "  $(_dim "Scored using skill-tools 5-dimension rubric (0-100)")"
  echo ""

  # ── CI job summary ──
  if [ "$CI" = "true" ]; then
    {
      echo "## Agent Skill Scan Report"
      echo ""
      if [ "$ERRORS" -gt 0 ]; then
        echo "**FAIL** — $ERRORS error(s), $WARNINGS warning(s)"
      elif [ "$WARNINGS" -gt 0 ]; then
        echo "**PASS with $WARNINGS warning(s)**"
      else
        echo "**All checks passed**"
      fi
      echo ""
      echo "**Quality Score: $QUALITY_SCORE/100 (Grade: $QUALITY_GRADE)**"
      echo ""
      echo "| Metric | Count |"
      echo "|--------|-------|"
      echo "| Checks | $CHECKS_RUN |"
      echo "| Errors | $ERRORS |"
      echo "| Warnings | $WARNINGS |"
      echo "| Info | $INFO_COUNT |"
      echo "| Duration | ${elapsed}s |"
      echo ""
      echo "| Dimension | Score |"
      echo "|-----------|-------|"
      echo "| Description Quality | $QUALITY_DESC/30 |"
      echo "| Instruction Clarity | $QUALITY_CLARITY/25 |"
      echo "| Spec Compliance | $QUALITY_SPEC/20 |"
      echo "| Progressive Disclosure | $QUALITY_PROGRESSIVE/15 |"
      echo "| Security | $QUALITY_SECURITY/10 |"
      echo "| **Total** | **$QUALITY_SCORE/100 ($QUALITY_GRADE)** |"

      if [ "$total_findings" -gt 0 ]; then
        echo ""
        echo "### Findings"
        echo ""
        echo "<details>"
        echo "<summary>Click to expand ($total_findings findings)</summary>"
        echo ""

        _ci_findings() {
          local severity="$1" icon="$2"
          local matches
          matches=$(grep "^${severity}|" "$FINDINGS_FILE" 2>/dev/null || true)
          [ -z "$matches" ] && return

          while IFS='|' read -r _ sec msg; do
            echo "- ${icon} **${sec}**: ${msg}"
          done <<< "$matches"
        }

        _ci_findings "ERROR" "x"
        _ci_findings "WARN"  "!"
        _ci_findings "INFO"  "i"

        echo ""
        echo "</details>"
      fi

      echo ""
      echo "_Validated against [agentskills.io/specification](https://agentskills.io/specification) | Score: $QUALITY_SCORE/100 ($QUALITY_GRADE)_"
    } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
  fi
}

# ════════════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════════════

show_help() {
  echo ""
  echo "  $(_bold "Agent Skill Scanner v4")"
  echo ""
  echo "  Validates skill packages against the agentskills.io specification"
  echo "  and community best practices for AI agent skills."
  echo "  Computes a quality score (0-100) across 5 dimensions."
  echo ""
  echo "  $(_bold "Usage:")"
  echo "    ./scripts/validate.sh                Run full scan (terminal)"
  echo "    ./scripts/validate.sh --json        Output as JSON"
  echo "    ./scripts/validate.sh --md          Output as Markdown report"
  echo "    ./scripts/validate.sh --score-only  Print score and grade only"
  echo "    ./scripts/validate.sh --help        Show this help"
  echo ""
  echo "  $(_bold "Output Modes:")"
  echo "    $(_cyan "--json")         Machine-readable JSON (pipe to jq, feed to web tools)"
  echo "    $(_cyan "--md")           Markdown report (save to file, paste in PRs/docs)"
  echo "    $(_cyan "--score-only")   Quick score check (e.g., in pre-commit hooks)"
  echo "    $(_dim "(default)")      Rich terminal output with colors and bar charts"
  echo ""
  echo "  $(_bold "Environment:")"
  echo "    CI=true      Emit GitHub Actions annotations + job summary"
  echo "    NO_COLOR=1   Disable colored output"
  echo ""
  echo "  $(_bold "Checks (15 sections, 20+ individual checks):")"
  echo "    $(_cyan " 1.") Skill structure        Required/optional files and directories"
  echo "    $(_cyan " 2.") Frontmatter & desc     name, description, voice, verbs, negative triggers"
  echo "    $(_cyan " 3.") Body & disclosure      Line count, token budget, structure, code examples"
  echo "    $(_cyan " 4.") Internal links         All links resolve to existing files"
  echo "    $(_cyan " 5.") Reference files        Linked, orphaned, empty, and missing detection"
  echo "    $(_cyan " 6.") Markdown syntax        Unclosed code blocks"
  echo "    $(_cyan " 7.") Reference nesting      No deep cross-reference chains"
  echo "    $(_cyan " 8.") Scripts                Executable permissions, documentation"
  echo "    $(_cyan " 9.") Repository hygiene     Sensitive files, development artifacts"
  echo "    $(_cyan "10.") Token budget           Per-file and total token analysis with zones"
  echo "    $(_cyan "11.") Content quality        Code examples, headings, keyword density"
  echo "    $(_cyan "12.") Agent metadata         agents/openai.yaml validation"
  echo "    $(_cyan "13.") Security scan          API keys, secrets, hardcoded paths, dangerous commands"
  echo "    $(_cyan "14.") Heading hierarchy      Level skip detection (MD001), duplicate headings (MD024)"
  echo "    $(_cyan "15.") Quality score          0-100 score across 5 dimensions with letter grade"
  echo ""
  echo "  $(_bold "Quality Score Dimensions:")"
  echo "    Description Quality  (30 pts)  Length, specificity, voice, verbs, triggers"
  echo "    Instruction Clarity  (25 pts)  Code blocks, headings, reference links"
  echo "    Spec Compliance      (20 pts)  Required fields, name format, token/line limits"
  echo "    Progressive Discl.   (15 pts)  References dir, linking, body size"
  echo "    Security             (10 pts)  No secrets, paths, or dangerous commands"
  echo ""
  echo "  $(_bold "Letter Grades:")"
  echo "    $(_bold_green "A+") 95+   $(_bold_green "A") 90+   $(_bold_green "A-") 85+   $(_bold_yellow "B+") 80+   $(_bold_yellow "B") 75+"
  echo "    $(_bold_yellow "B-") 70+   $(_bold_yellow "C+") 65+   $(_bold_red "C") 60+    $(_bold_red "C-") 55+   $(_bold_red "D") 50+    $(_bold_red "F") <50"
  echo ""
  echo "  $(_bold "Token Zones:")"
  echo "    $(_green "[SAFE]")   Well within budget, efficient"
  echo "    $(_yellow "[WARN]")   At or near recommended limits"
  echo "    $(_red "[HIGH]")   Exceeding recommendations, consider optimization"
  echo ""
  echo "  $(_bold "Token Estimation:")"
  echo "    Uses chars/4 approximation (industry standard for tiktoken cl100k_base)"
  echo "    SKILL.md budget: <5000 tokens | Reference: <4000 tokens each"
  echo "    Total package: <50000 tokens recommended"
  echo ""
  echo "  $(_bold "Severity:")"
  echo "    $(_red "✗ ERROR")  Spec violation or broken content — must fix"
  echo "    $(_yellow "! WARN ")  Best practice issue — should fix"
  echo "    $(_blue "ℹ INFO ")  Suggestion — nice to have"
  echo "    $(_green "✓ PASS ")  Check passed"
  echo ""
  echo "  $(_bold "References:")"
  echo "    Spec:    https://agentskills.io/specification"
  echo "    Scoring: https://agentskills.io/skill-creation/best-practices"
  echo "    Tokens:  https://agentpatterns.ai/context-engineering/context-budget-allocation/"
  echo ""
}

_suppress_terminal() {
  [ "$OUTPUT_MODE" != "terminal" ]
}

main() {
  # Parse CLI flags
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h) show_help; exit 0 ;;
      --json) OUTPUT_MODE="json"; NO_COLOR=1 ;;
      --md|--markdown) OUTPUT_MODE="markdown"; NO_COLOR=1 ;;
      --score-only|--score) OUTPUT_MODE="score-only" ;;
      *) echo "Unknown flag: $1"; echo "Run with --help for usage."; exit 2 ;;
    esac
    shift
  done

  if ! _suppress_terminal; then
    echo ""
    echo "  $(_bold "╔══════════════════════════════════════════════════════════╗")"
    echo "  $(_bold "║")                                                          $(_bold "║")"
    echo "  $(_bold "║")        $(_bold_cyan "A G E N T   S K I L L   S C A N N E R")            $(_bold "║")"
    echo "  $(_bold "║")                      $(_dim "v 4 . 0")                             $(_bold "║")"
    echo "  $(_bold "║")                                                          $(_bold "║")"
    echo "  $(_bold "╚══════════════════════════════════════════════════════════╝")"
    echo ""
    if [ "$CI" = "true" ]; then
      _detail "Mode : CI (GitHub Actions annotations + job summary)"
    else
      _detail "Mode : Local"
    fi
    _detail "Skill: $(pwd)"
    _detail "Spec : agentskills.io/specification"
    _detail "Date : $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "  $(_dim "Running $TOTAL_CHECKS sections with 20+ individual checks...")"
  fi

  if [ "$OUTPUT_MODE" != "terminal" ]; then
    exec 3>&1 1>/dev/null
  fi

  check_structure
  check_frontmatter
  check_body
  check_links
  check_references
  check_markdown
  check_reference_depth
  check_scripts
  check_repo_hygiene
  check_token_budget
  check_content_quality
  check_agents_metadata
  check_security
  check_heading_hierarchy
  compute_quality_score

  if [ "$OUTPUT_MODE" != "terminal" ]; then
    exec 1>&3 3>&-
  fi

  case "$OUTPUT_MODE" in
    json)       print_json ;;
    markdown)   print_markdown ;;
    score-only) print_score_only ;;
    *)          print_report ;;
  esac

  [ "$ERRORS" -gt 0 ] && exit 1
  exit 0
}

main "$@"
