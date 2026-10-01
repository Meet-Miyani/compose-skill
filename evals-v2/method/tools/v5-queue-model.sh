#!/bin/bash
# v5 queue for ONE model (owner, 2026-10-01: run Luna and Sol in parallel). Same cell order as v5-queue.sh
# (tasks in order, arms interleaved). Safe to run beside other queues:
#   - each cell is claimed with an atomic lock dir, so no two queues ever run the same cell
#   - a new cell waits while free memory is under 25%, so an out-of-memory build is never scored as a failure
#   - plan-limit failures are deleted and retried after 30 min (at most 16 waits), as in v5-queue.sh
#   - the PAUSE flag is honoured by v5-run.sh between cells
# Usage: v5-queue-model.sh <claude|codex|agy> <model>
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
W=$REPO/evals-v2/method/work/v5
TOOL=$1; M=$2
LOGF=$W/queue-$TOOL-$M.log
waits=0
free_pct() { memory_pressure 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2); print $2}'; }
for T in T1 T2 T3 T4 T5 T6 T7 T8; do
  for ARM in nokit generic kit; do
    OUT=$W/runs/$M/$T-$ARM; LOCK=$W/locks/$M-$T-$ARM
    mkdir -p "$W/locks"
    while :; do
      [ -f "$OUT/meta.txt" ] && break
      mkdir "$LOCK" 2>/dev/null || { sleep 30; continue; }   # another queue owns this cell; wait for it
      while [ "$(free_pct)" -lt 25 ] 2>/dev/null; do echo "$(date '+%F %T') low memory ($(free_pct)%), waiting" >> "$LOGF"; sleep 60; done
      echo "$(date '+%F %T') start $M $T $ARM" >> "$LOGF"
      bash "$REPO/evals-v2/method/tools/v5-run.sh" "$TOOL" "$M" "$T" "$ARM" >> "$LOGF" 2>&1
      if [ -f "$OUT/meta.txt" ] && ! grep -q "agent_exit=0" "$OUT/meta.txt" && \
         cat "$OUT/agent.err" "$OUT/agent.jsonl" 2>/dev/null | tail -c 20000 | \
         grep -qiE "usage limit|rate.limit|limit reached|quota|resource_exhausted|hit your limit|too many requests"; then
        waits=$((waits + 1)); echo "$(date '+%F %T') LIMIT $M $T $ARM; retry in 30 min (wait $waits)" >> "$LOGF"
        rm -rf "$OUT"; rmdir "$LOCK"
        [ $waits -gt 16 ] && { echo "$(date '+%F %T') too many limit waits; stopping" >> "$LOGF"; exit 4; }
        sleep 1800; continue
      fi
      rmdir "$LOCK"
      echo "$(date '+%F %T') done  $M $T $ARM $(tr '\n' ' ' < "$OUT/meta.txt" 2>/dev/null)" >> "$LOGF"
      break
    done
  done
done
echo "$(date '+%F %T') QUEUE COMPLETE $M" >> "$LOGF"
