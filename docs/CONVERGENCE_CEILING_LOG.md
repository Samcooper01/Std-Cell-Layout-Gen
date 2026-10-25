# Convergence Ceiling, full library close out effort

**Objective (Sam, 2026-07-07):** Converge as many of the 437 sky130_fd_sc_hd cells as
possible, area be damned, to (a) establish the empirical ceiling of the CURRENT placer +
router, and (b) for cells that still fail even with larger area, try ANYTHING to close them.
Document every step; save checkpoints.

This log is the running journal. Every attempt, success or failure, gets an entry with the
reason. Checkpoints: per cell GDS/LEF under `.work/ceiling/max/<cell>/out/`, winning recipes in
`.work/ceiling/ceiling.tsv`, and git commits on branch `convergence-ceiling` for any tooling
changes (patches mirrored to `patches/`).

---

## 0. Environment rebuild (prerequisite, native Linux had no toolchain)
The repo migrated to native Linux but `~/eda-env` (micromamba) did not. Rebuilt lclayout's
runtime as a plain venv at `~/eda-env` (the path the harness puts on PATH), no sudo:
- `python3 -m venv --without-pip ~/eda-env` + `get-pip.py` (system had no `python3-venv`).
- `pip install --editable lclayout` → klayout 0.30.9, z3-solver, numpy 2.2.6, networkx; added
  `matplotlib` (imported by lclayout but missing from its pyproject deps).
- Verified end to end: `inv_1` → GDS + `LVS result: SUCCESS`, SIZE 1.38 × 3.33.
- NOTE: host Python is 3.10 (old env was 3.14); determinism still pinned by `PYTHONHASHSEED=42`.
  Iteration counts may differ slightly from pre migration logs.

## 1. Phase A, max area assault with the CURRENT placer/router
Two stages, driven by `harness/orchestrator.sh` (autonomous, detached under `systemd --user`,
sleep inhibited 8.6h, 7.0h internal deadline guard).

**Stage 1, baseline** (`harness/baseline.sh`): build all 437 at their committed recipes,
record pass/fail + area. Result: **CLEAN 240 / TIMEOUT 155 / NOGDS 42 → open set = 197.**
  - Caveat: CLEAN=240 is LOAD DEPRESSED (28 parallel solvers + 150 s timeout pushed ~80
    normally passing cells into timeout). True committed coverage is ~319 (git `fbdeebb`).
    Stage 2 recovers these via rung 0.

**Stage 2, max effort ladder** (`harness/ceiling.sh`) over the 197 open cells. Per cell,
cheapest area first, timeout GROWS with rung; records the *minimum* area that closes:
  - rung 0: the cell's own committed recipe (240 s), closes here ⇒ "committed / no bloat".
  - then escalate: metal 3→4 layers, height_mult 1→2→3→4 (i.e. up to 4× the tracks / area),
    both placers (meta, hierarchical), tight lift + skip min area, timeouts 120 s → 1800 s.
  - Area knob = `RECIPE_HEIGHT_MULT` (unit_cell_height 3330 nm × mult; there is no separate
    track knob, tracks = height / 135 nm). Metal knob = `RECIPE_NUM_LAYERS` (2..4).

### INCIDENT (22:32 to 23:20), false negative bug in ceiling.sh worker, fixed + restarted
First Stage 2 launch mislabeled genuinely closed cells as UNSOLVED. Caught at ~21/197 when
combinational cells that clearly build (a21oi_4, clkinv_16) came back UNSOLVED.
- **Symptom:** cell dirs had a valid GDS + `LVS result: SUCCESS` in last.log, yet ceiling.tsv
  said UNSOLVED with hm/nl set to the closing rung but wd/ht/area = NA.
- **Root cause:** `record_close` is a shell function but only `worker` was exported
  (`export -f worker`). In the `xargs -P … bash -c 'worker'` subshells, `record_close` was
  undefined, so on every successful rung it errored silently ("command not found"); `res` never
  became CLOSED, but the same line `hm=…; nl=…; break` still ran → false UNSOLVED + early break.
- **Fix:** `export -f worker record_close` (+ defensively redirect child stdin `</dev/null` on
  both run_cell invocations, so a here string LADDER can't be consumed by a child).
- **Verified** in the real path: `bash -c 'worker' _ inv_1` → `CLOSED committed 1.38x3.33`.
- **Restarted** Stage 2 at ~23:20 with the fixed worker, deadline trimmed to 6.5h (window ends
  ~06:30). Compute cost of the bug: ~50 min; layouts it produced were valid (search was correct,
  only the bookkeeping was wrong), so nothing scientific was lost.

### INCIDENT 2 (00:05), OOM crash; the box went DOWN. Root caused + refit.
The fixed run (23:15) processed only **23/197** before dying. The hard cells reached the
memory heavy escalation rungs (h≥2 × 4 metal layers), each Z3 solve ballooning to **~6.3 GB
RSS**. At **28 way** that demanded ~170 GB on a 62 GB box → kernel OOM killer began killing
`lclayout` at 00:05, the desktop thrashed and went unresponsive, and the machine stayed down
until Sam rebooted it at 07:30. Kernel log: `Out of memory: Killed process (lclayout)
anon rss:6347884kB`.
- Cells done before crash: 16 CLOSED (all single height, committed or metal/tight-lift; area
  bloat never reached), 7 UNSOLVED (conb_1 R/C netlist; decap_3/4/6/8/12 template gap; clkinvlp_4).
  These were the early *easy* cells, the flip flops were never reached, so nothing learned re: flops.
- **Fix (Sam chose stability first):** run the whole thing inside a memory capped systemd user
  service (`systemd-run --user -p MemoryMax=52G -p MemorySwapMax=0`) so the box can NEVER go down
  again (kernel evicts only our cgroup); per solve `ulimit -v 12G` (runaway → clean UNSOLVED);
  parallelism 28 → **10**. Relaunched 2026-07-08 ~07:40, monitored, 10h deadline.

### Instrumentation added (08:16), full per cell / per step logging, then restarted
Per Sam's request to profile how long each step of the flow takes per cell, `ceiling.sh` now:
- runs lclayout with `-v` and saves **every rung's full log** to `max/<cell>/rungNN_<tag>.log`
  (previously each rung overwrote one `last.log`, almost all timing was being discarded);
- emits **`max/<cell>/timeline.tsv`**, one row per rung with per stage durations parsed from
  lclayout's timestamps: setup / placement / routing (+iteration count) / min area / LVS, plus
  rung wall time, lclayout total, and cell size.
- Verified on a real cell (a211oi_2 committed: place 3s, route 45s, min area 10s → the routing
  dominance we expected). Disk is a non issue (1.7 TB free). Restarted under the memory capped
  service at 08:16, PAR=10, 10h deadline.

### INCIDENT 3 (08:16 run), escalation ladder silently broken by `env <shell-function>`
The full logging run finished suspiciously fast (~1 h, 08:16→09:12): **44 CLOSED / 153 UNSOLVED,
0 area escalated**. Diagnosis: in the logging rewrite the ladder called each attempt as
`env PLACER=... run_attempt ...`, but **`env` cannot invoke a shell function**, it execs external
programs only. So every escalation rung errored instantly; cells failing the committed rung 0 fell
straight to UNSOLVED. Proof: zero `rung01_*.log` files existed across all 197 cells.
- Testing gap that hid it: the pre launch test used `inv_1`, which closes at rung 0 and never
  enters the escalation loop, so the broken path was never exercised.
- **Fix:** `export` the recipe vars into the environment (run_cell.sh, an external script, inherits
  them), instead of `env <function>`. **Verified on the real failure path** (and4bb_2: fails
  committed → closes at rung 1 `meta/L3/h1`, both rung logs written, correct ceiling.tsv row).
- Restarted 17:35, PAR=10, mem capped, full logging. Expected to run overnight now that escalation
  actually executes (the bugged run was fast precisely because it did nothing).
- The invalid 08:16 result is archived as `.work/ceiling/ceiling_BUGGED_envfn_*.tsv`.

### Phase A results, [PENDING: filled at run completion]
<!-- total converged / 437; committed vs area bloated (h>=2) breakdown; area distribution;
     per failure class table with root causes. -->

## 2. Phase B, "try anything" on the still unclosed cells
Only after Phase A. Escalation tiers beyond the current knobs (each attempt logged below):
- **Tier 2 (no code change):** alternate router (steiner), alternate placers (flat/smt),
  `--placement-file` with hand crafted transistor orderings, netlist preprocessing (finger
  splitting / device folding hints), further tech relaxation.
- **Tier 3 (code change, checkpointed on branch `convergence-ceiling`):** fix lclayout's SPICE
  reader for R/C devices (unblocks conb_1 & friends), add isowell / decap / tie templates,
  patch the placer (e.g. Euler path ordering) or router. Big items (Euler path placer) may only
  be *started* overnight, documented as such, not overclaimed.

### Phase B attempts, [chronological; appended live]
<!-- one entry per attempt: cell(s), what I tried, command/patch, outcome, reason. -->
