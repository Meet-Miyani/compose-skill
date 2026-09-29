#!/bin/bash
# Run one Codex model over the 3 harness tasks x 2 arms; stop early if plan usage gets high.
# Usage: batch-codex.sh <model>
H=/private/tmp/claude-501/-Users-meetmiyani-Documents-MeetMiyani-MEET-skills-main-compose-skill/6e711724-74a1-4acc-9d65-5cc44a95b81f/scratchpad/harness
MODEL=$1
for t in HT-01 HT-02 HT-03; do
  for a in kit nokit; do
    echo "== $MODEL $t $a $(date +%H:%M)"
    bash "$H/run-codex.sh" "$MODEL" "$t" "$a"
    M="$H/runs/$MODEL/$t-$a/meta.txt"
    five=$(grep -o 'five_hour_used=[0-9.]*' "$M" | cut -d= -f2)
    week=$(grep -o 'weekly_used=[0-9.]*' "$M" | cut -d= -f2)
    if python3 -c "import sys; sys.exit(0 if float('${five:-0}') > 60 or float('${week:-0}') > 30 else 1)"; then
      echo "USAGE GUARD: five_hour=${five}% weekly=${week}%; stopping batch"
      exit 0
    fi
  done
done
echo "BATCH DONE"
