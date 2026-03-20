#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════╗
# ║  Agent Skill Scanner v2                                         ║
# ║  Validates skill packages against the agentskills.io spec       ║
# ║  and best practices. Runs locally and in CI (GitHub Actions).   ║
# ║                                                                 ║
# ║  Spec:  https://agentskills.io/specification                    ║
# ║  Guide: https://agentskills.io/skill-creation                   ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Usage:
#   ./scripts/validate.sh              # full scan
#   ./scripts/validate.sh --help       # show usage
#
# Environment:
#   CI=true    — emits GitHub Actions annotations (auto-detected)
#   NO_COLOR=1 — disable colored output

ERRORS=0
WARNINGS=0
INFO_COUNT=0
CHECKS_RUN=0
CURRENT_SECTION=""
CI="${CI:-false}"
NO_COLOR="${NO_COLOR:-0}"
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

# ── Colors & formatting ───────────────────────────────────────────

if [ "$NO_COLOR" = "1" ]; then
  _red()    { printf '%s' "$*"; }
  _green()  { printf '%s' "$*"; }
  _yellow() { printf '%s' "$*"; }
  _blue()   { printf '%s' "$*"; }
  _cyan()   { printf '%s' "$*"; }
  _bold()   { printf '%s' "$*"; }
  _dim()    { printf '%s' "$*"; }
else
  _red()    { printf "\033[0;31m%s\033[0m" "$*"; }
  _green()  { printf "\033[0;32m%s\033[0m" "$*"; }
  _yellow() { printf "\033[0;33m%s\033[0m" "$*"; }
  _blue()   { printf "\033[0;34m%s\033[0m" "$*"; }
  _cyan()   { printf "\033[0;36m%s\033[0m" "$*"; }
  _bold()   { printf "\033[1m%s\033[0m" "$*"; }
  _dim()    { printf "\033[2m%s\033[0m" "$*"; }
fi

# ── Logging ────────────────────────────────────────────────────────

_error() {
  ERRORS=$((ERRORS + 1))
  echo "  $(_red "ERROR") $*"
  echo "ERROR|${CURRENT_SECTION}|$*" >> "$FINDINGS_FILE"
}

_warn() {
  WARNINGS=$((WARNINGS + 1))
  echo "  $(_yellow "WARN ") $*"
  echo "WARN|${CURRENT_SECTION}|$*" >> "$FINDINGS_FILE"
}

_pass() {
  echo "  $(_green "PASS ") $*"
}

_info() {
  INFO_COUNT=$((INFO_COUNT + 1))
  echo "  $(_blue "INFO ") $*"
  echo "INFO|${CURRENT_SECTION}|$*" >> "$FINDINGS_FILE"
}

_detail() {
  echo "         $(_dim "$*")"
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
  echo ""
  echo "  $(_bold "[$CHECKS_RUN]") $(_bold "$1")"
  echo "  $(_dim "$(printf '%.0s─' $(seq 1 60))")"
}

file_lines() { wc -l < "$1" | tr -d ' '; }
file_chars() { wc -c < "$1" | tr -d ' '; }
estimate_tokens() { echo $(( $(file_chars "$1") / 4 )); }

# ════════════════════════════════════════════════════════════════════
#  CHECKS
# ════════════════════════════════════════════════════════════════════

# ── [1] Skill Structure ───────────────────────────────────────────

check_structure() {
  section "Skill Structure"

  # SKILL.md — required
  if [ ! -f "$SKILL_FILE" ]; then
    _error "SKILL.md not found — required by agentskills.io spec"
    ci_annotate "error" "file=SKILL.md::SKILL.md not found"
    return
  fi
  _pass "SKILL.md ($(file_lines "$SKILL_FILE") lines, $(file_chars "$SKILL_FILE") bytes)"

  # README.md — recommended
  if [ ! -f "README.md" ]; then
    _warn "README.md missing — recommended for discoverability and GitHub rendering"
    ci_annotate "warning" "file=README.md::README.md missing (recommended)"
  else
    _pass "README.md ($(file_lines README.md) lines)"
  fi

  # Optional directories
  local dirs=("references" "scripts" "assets" "agents")
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      local count
      count=$(find "$dir" -type f | wc -l | tr -d ' ')
      _pass "$dir/ ($count files)"
    fi
  done

  if [ ! -d "references" ]; then
    _info "No references/ directory"
    _detail "Add reference docs for progressive disclosure of complex content"
  fi

  # LICENSE file
  if [ -f "LICENSE" ] || [ -f "LICENSE.md" ] || [ -f "LICENSE.txt" ]; then
    _pass "License file found"
  fi
}

# ── [2] Frontmatter ───────────────────────────────────────────────

check_frontmatter() {
  [ ! -f "$SKILL_FILE" ] && return

  section "Frontmatter (agentskills.io spec)"

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
    local inline_desc
    inline_desc=$(echo "$frontmatter" | sed -n "${desc_line}p" | sed 's/^description:[[:space:]]*//')

    if [ -n "$inline_desc" ] && ! echo "$inline_desc" | grep -qE '^\s*[>|]\s*$'; then
      desc="$inline_desc"
    else
      desc=$(echo "$frontmatter" | sed -n "$((desc_line+1)),\$p" | sed '/^[a-zA-Z_-]*:/,$d' | tr '\n' ' ' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    fi

    local desc_len=${#desc}

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

      # Quality: too short to be useful
      if [ "$desc_len" -lt "$DESC_MIN_USEFUL" ]; then
        _warn "description is very short ($desc_len chars) — likely won't trigger well"
        _detail "Good: 'Extract text and tables from PDF files, fill forms, merge"
        _detail "       documents. Use when working with PDF documents.'"
        _detail "Bad:  'Helps with PDFs.'"
        ci_annotate "warning" "file=$SKILL_FILE::description too short for reliable triggering"
      fi

      # Quality: should say WHAT and WHEN
      local has_what=false has_when=false
      if echo "$desc" | grep -qiE 'build|create|generate|extract|analyze|process|manage|handle|configure|review|refactor|optimize|test|debug|deploy|format|validate|convert|transform|monitor|implement'; then
        has_what=true
      fi
      if echo "$desc" | grep -qiE 'use when|when working|when the user|when handling|if the user|for tasks|for working|designed for|use this|use for'; then
        has_when=true
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
    fi
  fi

  # ── optional fields ──
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

  # Line count
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

  # Token budget
  if [ "$token_est" -gt "$TOKEN_BUDGET" ]; then
    _warn "~$token_est tokens (spec recommends <$TOKEN_BUDGET on activation)"
    _detail "Progressive disclosure: SKILL.md body loads fully on activation"
    _detail "Keep instructions concise, move reference material to references/"
    ci_annotate "warning" "file=$SKILL_FILE::Estimated $token_est tokens exceeds $TOKEN_BUDGET budget"
  else
    _pass "~$token_est tokens (budget: $TOKEN_BUDGET)"
  fi

  # Structure analysis (grep the file directly to avoid subshell/quoting issues)
  local heading_count
  heading_count=$(tail -n +"$((body_start + 1))" "$SKILL_FILE" | grep -c '^#' 2>/dev/null || true)
  heading_count=${heading_count:-0}

  if [ "$heading_count" -eq 0 ]; then
    _warn "No headings in body — add structure for readability"
  else
    _pass "$heading_count heading(s) providing structure"
  fi

  # Check for code examples (fenced blocks or inline code)
  local fence_pattern='```'
  local code_fence_count
  code_fence_count=$(grep -cF "$fence_pattern" "$SKILL_FILE" 2>/dev/null || true)
  code_fence_count=${code_fence_count:-0}
  local code_pairs=$(( code_fence_count / 2 ))

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

  # Check for reference links (progressive disclosure pattern)
  local ref_link_count
  ref_link_count=$(tail -n +"$((body_start + 1))" "$SKILL_FILE" | grep -cE '\]\(references/' 2>/dev/null || true)
  ref_link_count=${ref_link_count:-0}
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

  # Extract link targets: sed pulls "path" out of "](path)" patterns
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

    # Extract link targets: find all ](…) and pull out the path
    # Uses tr to split on ] then grep/sed to isolate (path) targets
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

  while IFS= read -r file; do
    total=$((total + 1))
    local lines
    lines=$(file_lines "$file")

    if [ "$lines" -eq 0 ]; then
      _warn "$file is empty (0 lines)"
      ci_annotate "warning" "file=$file::Empty reference file"
      empty=$((empty + 1))
      continue
    fi

    if echo "$ref_links" | grep -qF "$file"; then
      linked=$((linked + 1))
      _pass "$file ($lines lines)"
    else
      orphaned=$((orphaned + 1))
      _warn "$file ($lines lines) — $(_yellow "orphaned")"
      _detail "Not linked from SKILL.md — agents won't discover this file"
      ci_annotate "warning" "file=$file::Not linked from SKILL.md (orphaned)"
    fi
  done < <(find references -name '*.md' -type f | sort)

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
  _detail "Total: $total | Linked: $linked | Orphaned: $orphaned | Empty: $empty | Missing: $missing"
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

    # Check if documented in SKILL.md
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

  # Check for sensitive files
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

  # Check for development artifacts
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

# ── [10] Agent Metadata ──────────────────────────────────────────

check_agents_metadata() {
  section "Agent Metadata (Codex)"

  if [ ! -f "agents/openai.yaml" ]; then
    _info "No agents/openai.yaml — optional, configures Codex app UI and policy"
    return
  fi

  _pass "agents/openai.yaml present"

  # interface block
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

    # Icon validation
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

  # policy block
  if grep -q '^policy:' agents/openai.yaml; then
    if grep -q 'allow_implicit_invocation:' agents/openai.yaml; then
      local implicit
      implicit=$(grep 'allow_implicit_invocation:' agents/openai.yaml | sed 's/.*allow_implicit_invocation:[[:space:]]*//')
      _pass "allow_implicit_invocation: $implicit"
    fi
  fi

  # dependencies block
  if grep -q '^dependencies:' agents/openai.yaml; then
    _pass "dependencies declared"
  fi
}

# ════════════════════════════════════════════════════════════════════
#  REPORT
# ════════════════════════════════════════════════════════════════════

print_report() {
  echo ""
  echo ""

  _pad() {
    local text="$1" width="$2"
    local visible
    visible=$(echo "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local pad_len=$(( width - ${#visible} ))
    if [ "$pad_len" -lt 0 ]; then pad_len=0; fi
    printf '%s%*s' "$text" "$pad_len" ""
  }

  local W=54
  local line
  line=$(printf '%.0s═' $(seq 1 $W))
  local thin_line
  thin_line=$(printf '%.0s─' $(seq 1 $W))

  # ── Summary box ──
  echo "  $(_bold "╔${line}╗")"
  echo "  $(_bold "║")$(_pad "                    SCAN REPORT                       " $W)$(_bold "║")"
  echo "  $(_bold "╠${line}╣")"
  echo "  ║$(printf '%*s' $W "")║"
  echo "  ║  $(_pad "Checks run :  $CHECKS_RUN" 52)║"
  echo "  ║  $(_pad "$(_red "Errors")     :  $ERRORS" 52)║"
  echo "  ║  $(_pad "$(_yellow "Warnings")   :  $WARNINGS" 52)║"
  echo "  ║  $(_pad "$(_blue "Info")       :  $INFO_COUNT" 52)║"
  echo "  ║$(printf '%*s' $W "")║"

  local result_text
  if [ "$ERRORS" -gt 0 ]; then
    result_text=$(_red "FAIL")
  elif [ "$WARNINGS" -gt 0 ]; then
    result_text=$(_yellow "PASS with warnings")
  else
    result_text=$(_green "ALL CLEAR")
  fi
  echo "  ║  $(_pad "Result     :  $result_text" 52)║"

  echo "  ║$(printf '%*s' $W "")║"
  echo "  $(_bold "╚${line}╝")"

  # ── Detailed findings ──
  local total_findings
  total_findings=$(wc -l < "$FINDINGS_FILE" | tr -d ' ')

  if [ "$total_findings" -gt 0 ]; then
    echo ""
    echo "  $(_bold "┌${thin_line}┐")"
    echo "  $(_bold "│")$(_pad "                 DETAILED FINDINGS                     " $W)$(_bold "│")"
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
      echo "  $(_dim "$(printf '%.0s─' $(seq 1 52))")"

      local prev_section=""
      while IFS='|' read -r _ sec msg; do
        if [ "$sec" != "$prev_section" ]; then
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
    echo "  $(_dim "$(printf '%.0s─' $(seq 1 56))")"
  else
    echo ""
    echo "  $(_green "No findings — skill package is in perfect shape.")"
  fi

  echo "  $(_dim "Validated against agentskills.io/specification")"
  echo ""

  # ── CI job summary ──
  if [ "$CI" = "true" ]; then
    {
      echo "## Skill Scan Report"
      echo ""
      if [ "$ERRORS" -gt 0 ]; then
        echo "❌ **FAIL** — $ERRORS error(s), $WARNINGS warning(s)"
      elif [ "$WARNINGS" -gt 0 ]; then
        echo "⚠️ **PASS with $WARNINGS warning(s)**"
      else
        echo "✅ **All checks passed**"
      fi
      echo ""
      echo "| Metric | Count |"
      echo "|--------|-------|"
      echo "| Checks | $CHECKS_RUN |"
      echo "| Errors | $ERRORS |"
      echo "| Warnings | $WARNINGS |"
      echo "| Info | $INFO_COUNT |"

      if [ "$total_findings" -gt 0 ]; then
        echo ""
        echo "### Findings"
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

        _ci_findings "ERROR" "❌"
        _ci_findings "WARN"  "⚠️"
        _ci_findings "INFO"  "💡"
      fi

      echo ""
      echo "_Validated against [agentskills.io/specification](https://agentskills.io/specification)_"
    } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
  fi
}

# ════════════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════════════

show_help() {
  echo ""
  echo "  $(_bold "Agent Skill Scanner v2")"
  echo ""
  echo "  Validates skill packages against the agentskills.io specification"
  echo "  and community best practices for AI agent skills."
  echo ""
  echo "  $(_bold "Usage:")"
  echo "    ./scripts/validate.sh          Run full scan"
  echo "    ./scripts/validate.sh --help   Show this help"
  echo ""
  echo "  $(_bold "Environment:")"
  echo "    CI=true      Emit GitHub Actions annotations + job summary"
  echo "    NO_COLOR=1   Disable colored output"
  echo ""
  echo "  $(_bold "Checks (10):")"
  echo "    $(_cyan " 1.") Skill structure       Required/optional files and directories"
  echo "    $(_cyan " 2.") Frontmatter spec      name, description, optional field validation"
  echo "    $(_cyan " 3.") Body & disclosure      Line count, token budget, structure, code examples"
  echo "    $(_cyan " 4.") Internal links         All links resolve to existing files"
  echo "    $(_cyan " 5.") Reference files        Linked, orphaned, empty, and missing detection"
  echo "    $(_cyan " 6.") Markdown syntax        Unclosed code blocks"
  echo "    $(_cyan " 7.") Reference nesting      No deep cross-reference chains"
  echo "    $(_cyan " 8.") Scripts                Executable permissions, documentation"
    echo "    $(_cyan " 9.") Repository hygiene      Sensitive files, development artifacts"
  echo "    $(_cyan "10.") Agent metadata         agents/openai.yaml validation"
  echo ""
  echo "  $(_bold "Severity:")"
  echo "    $(_red "ERROR")  Spec violation or broken content — must fix"
  echo "    $(_yellow "WARN ")  Best practice issue — should fix"
  echo "    $(_blue "INFO ")  Suggestion — nice to have"
  echo "    $(_green "PASS ")  Check passed"
  echo ""
  echo "  $(_bold "Spec:")"
  echo "    https://agentskills.io/specification"
  echo ""
}

main() {
  case "${1:-}" in
    --help|-h)
      show_help
      exit 0
      ;;
  esac

  echo ""
  echo "  $(_bold "╔══════════════════════════════════════╗")"
  echo "  $(_bold "║      Agent Skill Scanner  v2         ║")"
  echo "  $(_bold "╚══════════════════════════════════════╝")"
  echo ""
  if [ "$CI" = "true" ]; then
    _detail "Mode : CI (GitHub Actions annotations + job summary)"
  else
    _detail "Mode : Local"
  fi
  _detail "Skill: $(pwd)"
  _detail "Spec : agentskills.io/specification"

  check_structure
  check_frontmatter
  check_body
  check_links
  check_references
  check_markdown
  check_reference_depth
  check_scripts
  check_repo_hygiene
  check_agents_metadata

  print_report

  [ "$ERRORS" -gt 0 ] && exit 1
  exit 0
}

main "$@"
