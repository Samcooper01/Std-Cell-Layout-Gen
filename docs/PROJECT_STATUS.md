# Project Status, sky130 Std Cell Automation

**As of:** 2026-07-07 · branch `sky130-port` @ `fbdeebb`

## What this project is
Autonomously generate the **sky130_fd_sc_hd** standard cell library (437 cells) directly
from SPICE netlists, using **lclayout** (LibreCell) as the place and route engine, driven by
a per cell **recipe** control surface. Z3 (SMT) does the DRC clean routing.

**North star:** AI driven **DTCO**, change tech file parameters (track height, Vt mix, drive
ladder, β, voltage) and regenerate a whole *co legal* library, not just one cell.

## Where we are: **319 / 437 LVS clean (~73%)**

Coverage ladder (each step = a new recipe knob, not hand layout):

| Milestone | Cells | Knob unlocked |
|---|---|---|
| Golden set | 17 | baseline |
| Parallel recipe search | 204 | auto sweep recipes 32 core |
| Metal escalation | 241 | met2 / met3 routing layers |
| Device less cells | 252 | fillers/taps/decap handling |
| Netlist L fix | 258 | honor channel length from netlist |
| Tight lift clearance | 285 | relaxed li1 spacing |
| Hard combinational harvest | **319** | tight lift + double height on drive 4 AOI/adder/mux/xor |

## Architecture (why this stays co legal)
Three layer tech split in `tech/sky130_hd_tech.py`:
1. **Process rules / DRC**, foundry fixed, never varies.
2. **Library architecture**, unit cell height, track count, set once per library.
3. **Per cell recipe**, the *only* thing that varies per cell.

Recipe knobs: metal escalation (met2/met3), tight lift clearance, double height fallback
(`RECIPE_HEIGHT_MULT=2`), finger grouping (`RECIPE_GROUP_FINGERS`), netlist channel length,
skipminarea. Harness: `harness/solve_all.sh` runs the recipe sweep 32 core parallel.
`PYTHONHASHSEED=42` is **mandatory** (pins lclayout's residual non determinism).

## The blocker (the remaining ~118 cells)
Dominated by **~66 flip flops**. The cheap recipe levers are exhausted; two framings converge:

- **Tactical:** flops need a **4 stack double height** layout (devices split across two rows so
  the cell gets *narrower*). Current 2 stack double height leaves them too wide → the router
  times out. `dfxtp_1` fails even at double height with 4 layers / hierarchical / raised caps.
  This needs a real change to lclayout's cell template.
- **Root cause (Blocker #1, placement quality):** lclayout's placer optimizes *estimated
  wirelength*, not **routability**, poor transistor ordering, misaligned P/N gate columns,
  avoidable net crossings. The foundry fits the same cells in **2 layers** via better placement
  (Euler path diffusion sharing + gate alignment); our row is actually *taller* than foundry hd
  (3.33 vs 2.72 µm) so we have *more* tracks, not fewer. **Fix = a BonnCell style
  routability aware placement pass** (dual Euler path, reward gate alignment, penalize
  crossings). This is also the piece that generalizes to new tech params, the DTCO north star.

Smaller residual classes: converge but LVS fail routing shorts (e.g. `a221o_2` mis route),
10 decaps, 6 isowell level shifters.

## Strategy: the sharpest next target
Per the DTCO scoping, the paper needs only the **~50 workhorse cells**, not all 437. We have
**47/53**; the gap is **1 to 2 DFFs + conb_1**. So the single highest value unlock is
**cracking one DFF (`dfxtp_1`)**, it closes the DTCO cell set *and* is the gateway to the
other ~65 flops. That makes the routability aware placer both the deepest blocker and the
sharpest target, validated first on one cell.

## Work in flight (worktrees)
- `wt-placement` @ `776180b`, routability aware placement pass (the #1 fix)
- `wt-router-shorts` @ `ac5c6fe`, converge but LVS fail shorts
- `wt-physical-cleanup` @ `4ebab11`, DRC nits / min area cleanup

Main line (`sky130-port`, 319) is the regression baseline; any placer change re tests against it.

## Recommended next move
Build the **routability aware placement pass**, prove it on **`dfxtp_1`**, regression test
against the committed **319**. Deep, multi day work, best started fresh.
