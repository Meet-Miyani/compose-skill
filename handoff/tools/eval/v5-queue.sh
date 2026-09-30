#!/bin/bash
# v5 queue for one tool: 2 models x 8 tasks x 3 arms = 48 cells, run in task order with arms and models
# interleaved so time-of-day and plan-limit effects spread evenly across arms.
# A run that dies on a plan usage/rate limit is deleted and retried after 30 min (at most 16 waits per tool);
# any other failure is kept as a real result. Finished cells are skipped, so the queue can be restarted.
# Usage: v5-queue.sh <claude|codex|agy>
set -u
REPO=/Users/meetmiyani/Documents/MeetMiyani/MEET/skills-main/compose-skill
TOOL=$1
case "$TOOL" in
  claude) MODELS="sonnet opus" ;;
  codex)  MODELS="gpt-6-luna gpt-6-sol" ;;
  agy)    MODELS="gemini-3.8-flash-medium gemini-3.1-pro-high" ;;
esac
LOGF=$REPO/handoff/work/scratch/v5/queue-$TOOL.log
waits=0
for T in T1 T2 T3 T4 T5 T6 T7 T8; do
  for ARM in nokit generic kit; do
    for M in $MODELS; do
      OUT=$REPO/handoff/work/scratch/v5/runs/$M/$T-$ARM
      while :; do
        [ -f "$OUT/meta.txt" ] && break
        echo "$(date '+%F %T') start $M $T $ARM" >> "$LOGF"
        bash "$REPO/handoff/tools/eval/v5-run.sh" "$TOOL" "$M" "$T" "$ARM" >> "$LOGF" 2>&1
        if [ -f "$OUT/meta.txt" ] && ! grep -q "agent_exit=0" "$OUT/meta.txt" && \
           cat "$OUT/agent.err" "$OUT/agent.jsonl" 2>/dev/null | tail -c 20000 | \
           grep -qiE "usage limit|rate.limit|limit reached|quota|resource_exhausted|hit your limit|too many requests"; then
          waits=$((waits + 1))
          echo "$(date '+%F %T') LIMIT $M $T $ARM; retry in 30 min (wait $waits)" >> "$LOGF"
          rm -rf "$OUT"
          [ $waits -gt 16 ] && { echo "$(date '+%F %T') too many limit waits; stopping $TOOL" >> "$LOGF"; exit 4; }
          sleep 1800
          continue
        fi
        echo "$(date '+%F %T') done  $M $T $ARM $(tr '\n' ' ' < "$OUT/meta.txt" 2>/dev/null)" >> "$LOGF"
        break
      done
    done
  done
done
echo "$(date '+%F %T') QUEUE COMPLETE $TOOL" >> "$LOGF"
