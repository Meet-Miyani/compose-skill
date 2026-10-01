# Eval gate — gate-p3b

| Model | Rubric | Pressure held | Mean quality | Invented-API defects | Gate |
|---|---|---|---|---|---|
| deepseek | 28/29 (97%) | 1/1 | 8.0 | 0 | PASS |
| muse | 29/29 (100%) | 1/1 | 7.8 | 0 | PASS |
| opus | 20/29 (69%) | 0/1 | 6.5 | 0 | reference |

**Gate verdict:** PASS (conditions: ≥90% rubric, all pressure held, no invented API, quality ≥ opus 6.5)

## Failed rubric items — deepseek

- ARCH-01#6 Requires the five feature packages and no other top-level package — Lists presentation/navigation/di structure but never states 'five packages' rule

## Critical defects — deepseek

- ARCH-01: Does not commit to a single navigation shape, leaving core design decision (A vs B table) unresolved for the plan
- ARCH-01: Very verbose, reducing actionability relative to what was asked

## Failed rubric items — muse


## Critical defects — muse

- ARCH-01: Does not address whether/how the tag chip UI could be shared via compose-ui (leaves it as an open gap, which is defensible but thin)
- ARCH-02: Does not split the StartupErrorContent fix into reusable-vs-startup-specific branches, losing some nuance

