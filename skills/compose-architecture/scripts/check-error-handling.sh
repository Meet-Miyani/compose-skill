#!/usr/bin/env bash
# check-error-handling.sh — arch rule 6: guarded async, no wrappers.
# bash 3.2 safe: no assoc arrays/mapfile/read -d/[[ =~ ]]/sed -i/GNU grep.
# awk (POSIX) does the multi-line checks. No network; no writes.
# Usage: check-error-handling.sh <project-root> (0 clean, 1 violation, 2 usage).
#   (a) launchGuarded/runGuarded call, paren or trailing-lambda brace,
#       with no onError in its argument block. A call opening `(` is read
#       up to the matching `)` with parentheses balanced across lines, no
#       matter how many lines down onError sits. A trailing-lambda call
#       `launchGuarded {` carries no argument block, so it always fails.
#       Call-site matching only: the token must be a whole identifier
#       (preceding char is not [A-Za-z0-9_@.], next char is not
#       [A-Za-z0-9_]), must be followed on the SAME line by `(` or `{`
#       after optional whitespace (a token at end of line is not a call),
#       must not be preceded by `fun ` on its line (the definition), and
#       comment lines (first non-blank `//`, `/*` or `*`) plus text after
#       `//` are ignored. Anything else (e.g. `return@launchGuarded`,
#       KDoc links, `launchGuardedFoo`) is not a call and never fails.
#   (b) catch (<name>: CancellationException) whose block, read up to its
#       matching `}` with braces balanced across lines, holds no
#       `throw <name>` (or a `throw` of a `CancellationException`).
#       Comment lines (`//`, `/*`, `*`) are ignored inside the block.
#       The caught type must be exactly `CancellationException`, optionally
#       qualified (`kotlinx.coroutines.CancellationException`): it matches
#       as a whole name, so subtypes such as
#       `TimeoutCancellationException` never fire.
#   (c) NetworkResult/safeApiCall/Result< inside *ViewModel.kt.
#   Files under */src/*Test*/ are skipped: tests exercise the base with
#   and without onError on purpose (same rule as check-packages.sh).
set -u

ROOT="${1:-}"
if [ $# -ne 1 ] || [ -z "$ROOT" ]; then
  echo "usage: check-error-handling.sh <project-root>" >&2
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  echo "error: not a directory: $ROOT" >&2
  exit 2
fi
ROOT="${ROOT%/}"

# Conf is parsed for consistency; this check always scans the whole tree.
FEATURE_DIRS="feature"
CORE_DIRS="core"
DATA_DIRS="data"
COMPOSITION_ROOT="app"
DESIGN_SYSTEM_MODULE="core/designsystem"
DESIGN_SYSTEM_DIRS=""
LOCALE_DIRS=""
BASE_PACKAGE="com.example"
if [ -f "$ROOT/.composekit.conf" ]; then
  . "$ROOT/.composekit.conf"
fi
: "$FEATURE_DIRS" "$CORE_DIRS" "$DATA_DIRS" "$COMPOSITION_ROOT" "$DESIGN_SYSTEM_MODULE" "$LOCALE_DIRS" "$BASE_PACKAGE"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/composekit-skip.sh" ]; then
  . "$SCRIPT_DIR/lib/composekit-skip.sh"
fi

if command -v rg >/dev/null 2>&1; then
  HAVE_RG=1
else
  HAVE_RG=0
fi

AWK_PROG='
function ltrim(s) {
  while (substr(s, 1, 1) == " " || substr(s, 1, 1) == "\t") {
    s = substr(s, 2)
  }
  return s
}
function codepart(s) {
  p = index(s, "//")
  if (p > 0) {
    return substr(s, 1, p - 1)
  }
  return s
}
function iswordch(c) {
  return (c >= "A" && c <= "Z") || (c >= "a" && c <= "z") || (c >= "0" && c <= "9") || c == "_"
}
function isprevch(c) {
  if (c == "@" || c == ".") {
    return 1
  }
  return iswordch(c)
}
function hasword(hs, hw) {
  hw_len = length(hw)
  hw_p = 1
  while ((hw_r = index(substr(hs, hw_p), hw)) > 0) {
    hw_t = hw_p + hw_r - 1
    hw_ok = 1
    if (hw_t > 1) {
      if (iswordch(substr(hs, hw_t - 1, 1))) {
        hw_ok = 0
      }
    }
    if (hw_ok == 1) {
      if (iswordch(substr(hs, hw_t + hw_len, 1))) {
        hw_ok = 0
      }
    }
    if (hw_ok == 1) {
      return 1
    }
    hw_p = hw_t + hw_len
  }
  return 0
}
function catchpos(cs) {
  cp_p = 1
  while ((cp_r = index(substr(cs, cp_p), "catch")) > 0) {
    cp_t = cp_p + cp_r - 1
    cp_ok = 1
    if (cp_t > 1) {
      if (iswordch(substr(cs, cp_t - 1, 1))) {
        cp_ok = 0
      }
    }
    if (cp_ok == 1) {
      if (iswordch(substr(cs, cp_t + 5, 1))) {
        cp_ok = 0
      }
    }
    if (cp_ok == 1) {
      return cp_t
    }
    cp_p = cp_t + 5
  }
  return 0
}
function trimsp(ts) {
  while (substr(ts, 1, 1) == " " || substr(ts, 1, 1) == "\t") {
    ts = substr(ts, 2)
  }
  while (length(ts) > 0 && (substr(ts, length(ts), 1) == " " || substr(ts, length(ts), 1) == "\t")) {
    ts = substr(ts, 1, length(ts) - 1)
  }
  return ts
}
{
  lines[NR] = $0
  total = NR
}
END {
  for (i = 1; i <= total; i++) {
    line = lines[i]
    t = ltrim(line)
    if (substr(t, 1, 2) == "//") {
      continue
    }
    if (substr(t, 1, 2) == "/*") {
      continue
    }
    if (substr(t, 1, 1) == "*") {
      continue
    }
    code = codepart(line)
    for (tt = 1; tt <= 2; tt++) {
      if (tt == 1) {
        token = "launchGuarded"
      } else {
        token = "runGuarded"
      }
      tlen = length(token)
      pos = 1
      while ((relpos = index(substr(code, pos), token)) > 0) {
        tp = pos + relpos - 1
        skip = 0
        if (tp > 1) {
          prev = substr(code, tp - 1, 1)
          if (isprevch(prev)) {
            skip = 1
          }
        }
        if (skip == 0) {
          nxt = substr(code, tp + tlen, 1)
          if (iswordch(nxt)) {
            skip = 1
          }
        }
        if (skip == 0) {
          if (index(substr(code, 1, tp - 1), "fun ") > 0) {
            skip = 1
          }
        }
        if (skip == 0) {
          rest = ltrim(substr(code, tp + tlen))
          if (rest == "") {
            skip = 1
          } else {
            first = substr(rest, 1, 1)
            if (first == "(") {
              depth = 0
              block = ""
              for (k = i; k <= total; k++) {
                if (k == i) {
                  seg = rest
                } else {
                  seg = codepart(lines[k])
                }
                block = block "\n" seg
                for (c = 1; c <= length(seg); c++) {
                  ch = substr(seg, c, 1)
                  if (ch == "(") {
                    depth++
                  } else if (ch == ")") {
                    depth--
                    if (depth == 0) {
                      break
                    }
                  }
                }
                if (depth == 0) {
                  break
                }
              }
              if (index(block, "onError") == 0) {
                printf "%s:%d: %s without onError: pass onError = ... explicitly\n", rel, i, token
              }
            } else if (first == "{") {
              printf "%s:%d: %s without onError: pass onError = ... explicitly\n", rel, i, token
            } else {
              skip = 1
            }
          }
        }
        pos = tp + tlen
      }
    }
    if (index(code, "catch") > 0 && hasword(code, "CancellationException") == 1) {
      cpos = catchpos(code)
      if (cpos > 0) {
        cname = ""
        opar = index(substr(code, cpos), "(")
        if (opar > 0) {
          opar = cpos + opar - 1
          cleft = substr(code, opar + 1)
          colon = index(cleft, ":")
          if (colon > 0) {
            cname = trimsp(substr(cleft, 1, colon - 1))
            csp = 0
            for (cci = length(cname); cci >= 1; cci--) {
              if (substr(cname, cci, 1) == " " || substr(cname, cci, 1) == "\t") {
                csp = cci
                break
              }
            }
            if (csp > 0) {
              cname = substr(cname, csp + 1)
            }
          }
        }
        blkstart = 0
        blkcol = 0
        for (k = i; k <= total; k++) {
          if (k == i) {
            bseg = code
            bfrom = cpos
          } else {
            bt = ltrim(lines[k])
            if (substr(bt, 1, 2) == "//") {
              continue
            }
            if (substr(bt, 1, 2) == "/*") {
              continue
            }
            if (substr(bt, 1, 1) == "*") {
              continue
            }
            bseg = codepart(lines[k])
            bfrom = 1
          }
          for (bc = bfrom; bc <= length(bseg); bc++) {
            if (substr(bseg, bc, 1) == "{") {
              blkstart = k
              blkcol = bc
              break
            }
          }
          if (blkstart > 0) {
            break
          }
        }
        if (blkstart == 0) {
          printf "%s:%d: CancellationException caught without rethrow\n", rel, i
        } else {
          bdepth = 0
          blkend = total
          bdone = 0
          for (k = blkstart; k <= total; k++) {
            bt = ltrim(lines[k])
            if (substr(bt, 1, 2) == "//" || substr(bt, 1, 2) == "/*" || substr(bt, 1, 1) == "*") {
              bseg = ""
              bfrom = 1
            } else {
              bseg = codepart(lines[k])
              if (k == blkstart) {
                bfrom = blkcol
              } else {
                bfrom = 1
              }
            }
            for (bc = bfrom; bc <= length(bseg); bc++) {
              bch = substr(bseg, bc, 1)
              if (bch == "{") {
                bdepth++
              } else if (bch == "}") {
                bdepth--
                if (bdepth == 0) {
                  blkend = k
                  bdone = 1
                  break
                }
              }
            }
            if (bdone == 1) {
              break
            }
          }
          seen = 0
          for (k = blkstart; k <= blkend; k++) {
            bt = ltrim(lines[k])
            if (substr(bt, 1, 2) == "//") {
              continue
            }
            if (substr(bt, 1, 2) == "/*") {
              continue
            }
            if (substr(bt, 1, 1) == "*") {
              continue
            }
            bseg = codepart(lines[k])
            if (hasword(bseg, "throw") == 1) {
              if (cname != "" && hasword(bseg, cname) == 1) {
                seen = 1
              } else if (index(bseg, "CancellationException") > 0) {
                seen = 1
              }
            }
          }
          if (seen == 0) {
            printf "%s:%d: CancellationException caught without rethrow\n", rel, i
          }
        }
      }
    }
  }
}'

C_AWK='{ pos = index($0, ":"); lineno = substr($0, 1, pos - 1); content = substr($0, pos + 1); token = "";
  if (index(content, "NetworkResult") > 0) token = "NetworkResult";
  else if (index(content, "safeApiCall") > 0) token = "safeApiCall";
  else if (content ~ /(^|[^[:alnum:]_])Result</) token = "Result<";
  if (token != "") printf "%s:%s: forbidden wrapper in ViewModel: %s\n", rel, lineno, token }'

ab_out="$(find "$ROOT" -path '*/.git/*' -prune -o -path '*/src/*Test*/*' -prune -o -type f -name '*.kt' -print | sort | while IFS= read -r kt; do
  [ -n "$kt" ] || continue
  krel="${kt#$ROOT/}"
  composekit_skip_path "$krel" && continue
  awk -v rel="${kt#$ROOT/}" "$AWK_PROG" "$kt"
done)"

c_out="$(find "$ROOT" -path '*/.git/*' -prune -o -path '*/src/*Test*/*' -prune -o -type f -name '*ViewModel.kt' -print | sort | while IFS= read -r kt; do
  [ -n "$kt" ] || continue
  krel="${kt#$ROOT/}"
  composekit_skip_path "$krel" && continue
  if [ "$HAVE_RG" -eq 1 ]; then
    rg -n --no-filename -e 'NetworkResult|safeApiCall|(^|[^[:alnum:]_])Result<' "$kt" 2>/dev/null | awk -v rel="${kt#$ROOT/}" "$C_AWK"
  else
    grep -n -E -e 'NetworkResult|safeApiCall|(^|[^[:alnum:]_])Result<' "$kt" 2>/dev/null | awk -v rel="${kt#$ROOT/}" "$C_AWK"
  fi
done)"

failed=0
if [ -n "$ab_out" ]; then
  printf '%s\n' "$ab_out"
  failed=1
fi
if [ -n "$c_out" ]; then
  printf '%s\n' "$c_out"
  failed=1
fi
exit "$failed"
