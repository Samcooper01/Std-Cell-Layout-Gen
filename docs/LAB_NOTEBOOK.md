# Standard Cell Layout Generation, Lab Notebook

Autonomous generation of the **sky130_fd_sc_hd** standard cell library (437 cells)
from SPICE netlists, using [lclayout](https://codeberg.org/librecell/lclayout)
(LibreCell, Thomas Kramer) as the place and route engine, driven by a per cell
**recipe** control surface. Long term goal: AI driven DTCO, change parameters in
the tech file (track height, Vt mix, drive ladder, sizing, β, voltage) and
regenerate a whole co legal library.

> This notebook is the running engineering record: what was tried, what worked,
> what didn't and *why*, and the current blockers. Chronological within each
> theme. Coverage = # cells that build **LVS clean** (GDS written + internal LVS
> SUCCESS) out of 437.

---

## Headline: coverage progression

| Milestone | Coverage | Commit | What changed |
|---|---|---|---|
| Golden set (manual review) | 17 (approved) | 4ee931b | power/pin fix, width/via tuning |
| Full parallel recipe search | **204 / 437** | f8306f0 | lift + placer caps + compiled recipes |
| Metal escalation ladder (met2/met3) | **241 / 437** | fd088de | +37 cells that need >2 routing layers |
| Device less cell support | **252 / 437** | 2eccbe3 | +11 fill/tap/diode/spacer cells |
| Netlist channel length fix | **258 / 437** | 8bfb41f | +6 long L delay/low-power cells |
| Tight lift clearance | **285 / 437** | (this) | +27 OR/clk/adder/AOI cells (narrow transistor short fix) |
| Hard combinational harvest | **319 / 437** | (this) | +34 drive 4 AOI/adder/mux/xor/high-drive (tight lift + double height) |

**Current: 319 / 437 (~73%).** Remaining ~118, chiefly the **66 flip flops** (need
a 4 stack double height; cheap levers exhausted, dfxtp_1 fails at double height
even with 4 layers/hierarchical/raised-caps), 10 decaps (S/D routing), 6 isowell
level shifters. See *Session 3* and the 4 stack design note.

---

## Environment / how to run

- lclayout installed in micromamba `~/eda-env` (Python 3.14). `PYTHONHASHSEED=42`
  is **mandatory** (lclayout has residual non determinism; this is the upstream
  workaround). All harness scripts set it.
- `lclayout/` is a **gitignored** clone (CERN OHL S licensed). Our modifications
  to it live as diffs in `patches/` (regenerate with `git -C lclayout diff ...`).
  Apply with `git -C lclayout apply ../patches/*.patch`.
- Per cell run: `harness/run_cell.sh <cell>`, extracts the subckt, normalizes the
  CDL (drop VPB/VNB bulk ports → tie to rails, add µm units, map fet models,
  expand `m=N` into N parallel fingers), looks up the cell's recipe, runs lclayout.
- Recipe search: `harness/solve_cell.sh <cell>` tries a ladder of recipes and
  prints the first that's LVS clean. `harness/solve_all.sh` runs it 32 core parallel.
- Full categorized sweep: `harness/run_all.sh`. Fast regression subset: `harness/track.sh`.

---

## The architecture: three layers, only one varies per cell

`tech/sky130_hd_tech.py` is deliberately split so the generator can explore the
design space without breaking library co legality:

1. **Process rules** (DRC: spacing/width/enclosure, via sizes, layer map), 
   foundry defined, identical for every cell.
2. **Library architecture** (`unit_cell_height`, site, routing tracks,
   `unit_cell_width`), **one** choice per library; shared by all cells so they
   abut in rows and expose pins on common tracks. A cell being individually
   LVS clean is necessary but **not** sufficient, the library must be co legal.
3. **Generator recipe** (placer, router, routing costs, and the knobs below), 
   the only thing allowed to vary per cell. This is the DTCO control surface,
   stored in `harness/recipes`.

### Recipe knobs (the DTCO control surface)
`harness/recipes` columns: `cell placer router mcon_weight lift layers skipminarea group`.
All env overridable; all default to the pre existing behavior so unlisted cells
are unaffected.

| Knob | Env | Default | Effect |
|---|---|---|---|
| placer | `PLACER` | hierarchical | hierarchical / meta / flat / smt |
| router | `ROUTER` | dijkstra | dijkstra / steiner |
| mcon_weight | `RECIPE_MCON_WEIGHT` | 300000 | cost of the li1↔met1 via (keeps nets on li1) |
| lift | `RECIPE_LIFT_DRAINS` | 0 | net aware drain lift off the power rail (see Fix 3) |
| layers | `RECIPE_NUM_LAYERS` | 2 | metal escalation ladder: 2=li1+met1, 3=+met2, 4=+met3 |
| skipminarea | `RECIPE_SKIP_MIN_AREA` | 0 | skip min area DRC fixing (SMT can UNSAT; not an LVS req) |
| group | `RECIPE_GROUP_FINGERS` | 0 | collapse parallel fingers before the placement search |

Placement search caps (env, tune per cell): `RECIPE_PLACE_PERM_CAP` (5040),
`RECIPE_PLACE_COMBO_CAP` (20000), `RECIPE_PLACE_INNER_CAP` (5000),
`RECIPE_PLACE_EULER_TOUR_CAP` (200).

---

## Committed fixes (with root causes)

### Fix 1, Power/pin layer inversion (e99f2ea)
**Symptom:** generated cells drew power on li1 and signal pins on met1, inverted
vs foundry hd; sources/drains floated, no li1 under the rails.
**Root cause:** `pin_layer`/`power_layer` swapped relative to the sky130 stack.
**Fix:** `power_layer = [l_metal1, l_metal2]` (li1+met1 rails, mcon stitched);
`pin_layer = l_metal1` (signals on li1). Matches the foundry stack.

### Fix 2, Track A quality (4ee931b)
`unit_cell_width` 1440→**690 nm** (inv exactly 1.38 µm = foundry; must be a
multiple that keeps the routing grid aligned, 690//6=115). `mcon` via weight
152k→**300k** cuts stray met1. 17 cell golden set reviewed & approved.

### Fix 3, Net aware drain lift, a.k.a. "Option A" (b5e9cfb), the workhorse
**Symptom:** NOR/AOI cells short the output to the ground rail (LVS: Y ≡ VGND).
**Root cause (verified on nor3 geometry):** the NMOS active box bottom edge sits
*exactly* on the VGND rail's top edge. When the router contacts a signal **drain**
low, its li1 pad **abuts** the rail (shared edge) and Magic merges the nets.
**Sources** legitimately abut the rail, that IS their connection, so only
non power **drains** must be lifted. The router graph is net agnostic, so it
picks the rail adjacent contact for the drain (cheaper) and is blind to the short.
**Fix:** after the LVS terminal join + transistor terminal embed (so it isn't
overridden), for a non power diffusion net whose rail adjacent contacts span **≥2
distinct columns** (the parallel pulldown signature), drop the rail adjacent
access nodes so the router contacts on the far side. Clearance derived from tech
(`via_size/2 + enclosure + li1-spacing`). Columns aggregated across terminal
entries (`extract_terminal_nodes` emits one entry per diffusion shape, so parallel
drains arrive as separate single column entries, must be summed).
**Key lesson:** no static heuristic separates "would short" (nor3) from "wouldn't"
(and3 has the *identical* parallel signature but routes clean), forcing the lift
on compound cells over constrains routing → oscillation → timeout. So the lift is
a **per cell recipe knob, default off.** Enabled where proven. It ended up the
single most used knob (110 of 204 cells).

### Fix 4, Placer combinatorial caps (b1b4199)
**Symptom:** high drive cells (drive-2/4/8) hang the placer (dominant
FAIL:timeout). **Root cause (faulthandler):** `HierarchicalPlacer` enumerates
sub cell permutations `P! × N!` plus an intra sub cell product, O(n!) in sub cell
count. `EXPAND` turns `m=N` into N parallel devices → many sub cells → explosion.
**Fix:** `islice` caps at all three choke points (env tunable). `permutations()`
yields the identity/natural order first, so capping only drops far out
permutations. Result stays LVS correct; only placement quality can degrade.
Golden 17/17, zero regression.

### Fix 5, Euler tour cap (a48b6ba)
`find_all_euler_tours` is exponential and was called **unbounded** at
`euler_placer.py` (used by meta/flat placers), hanging drive 4 (~32 device) cells
even after Fix 4. `meta_placer` already capped identical calls at 200; this path
didn't. Added `RECIPE_PLACE_EULER_TOUR_CAP` (default 200).

### Fix 6, Metal escalation ladder + the LVS extractor fix (261a445), the second breakthrough
**Motivation:** after Fixes 3 to 5 the dominant residual failure was routing-
congestion **timeout**, complex/high-fan in cells the router can't route in the
2 layer (li1+met1) stack; the pathfinder oscillates and never reaches zero
collisions. More routing planes is the deterministic congestion cure.
**Added met2 (`l_metal3`) and met3 (`l_metal4`)** as recipe gated routing layers:
`RECIPE_NUM_LAYERS 2|3|4`. The solver tries the fewest layers first (2 = foundry-
faithful) and only escalates when a cell won't route.
**THE key fix was in `lclayout/lvs/lvs.py`:** the netlist extractor only knew
li1+met1+via1 (there was literally `# TODO: what if more than 2 metal layers?`).
So 3 layer cells *routed* but **LVS failed on phantom opens**, met2 wires were
invisible to the extractor. Adding `make_layer` + `connect` for via2/met2/via3/met3
made met2 routing show as connected. After that, cells impossible in 2 layers
(a2111oi_2, or4_4, o211a_4) build LVS clean at 3. +37 cells (34 at met2, 3 at met3).
Also added `RECIPE_SKIP_MIN_AREA`, min area DRC fixing (an SMT re solve, not an
LVS requirement) can go UNSAT on multi-layer/empty cells; skipping keeps the cell
LVS clean (min area DRC dirty).

### Fix 7, Finger grouping (cf68aa5)
Collapse identical parallel transistors (fingers from `EXPAND m=N`) into one
representative edge before the Euler tour search, expand back as adjacent fingers.
K identical fingers otherwise create K! equivalent Euler tours that waste the
tour cap budget on junk permutations, so the search never reaches a routable
ordering. **Important context:** `EulerPlacer` *already* optimizes gate alignment
(`_num_gate_matches` is scored before wirelength), so the objective is already
right, the problem is purely that the capped, finger exploded search never
*finds* the aligned placement. Grouping helps some cells route in 2 layers
(a221o_2 converges) but does **not** crack the 5 input AOIs (they genuinely need
3 layers). Modest; a faithfulness improvement, not a coverage silver bullet.
Env gated `RECIPE_GROUP_FINGERS`, default off.

### Fix 8, Device less cell support (2eccbe3)
fill / tap / tapvgnd / tapvpwrvgnd / diode / macro_sparecell have **0 transistors**
and crashed lclayout (`min()` over empty nets in the placer, then an "exactly one
top circuit" assertion in LVS). **Insight:** the reference netlist is also
device less, so an empty cell (just rails + wells) LVS matches trivially.
- `euler_placer`: `HierarchicalPlacer.place()` yields an empty cell for 0 devices.
- `lvs.py`: `extract_netlist` tolerates 0 top circuits (empty layout purges to 0);
  `compare_netlist` short circuits `True` when reference **and** extraction are
  both device less.
Normal cells (≥1 device) unaffected, verified inv_1 still clean. +11 (conb_1
excluded, it has real tie devices).

---

## Negative results, what was tried and did NOT work (and why)

These are as valuable as the wins; they rule out dead ends.

- **Fold mode (`EXPAND=0`, single wide device instead of N fingers):** DEAD, 
  folded wide devices don't expose gate pin terminals → "Nets without terminals".
- **Rust router (`pyo3_graphrouter`):** DEAD, needs a compiled `pyo3_cell` module;
  no Rust toolchain available, can't build.
- **Swapping the detail router (dijkstra ↔ steiner):** no help on the oscillating
  cells, both run under the same PathFinder wrapper; the bottleneck is congestion
  negotiation, not per net path quality.
- **PathFinder history cost boost** (`RECIPE_HIST_WEIGHT/INCREMENT` up to 20/50):
  the congested cells still oscillate and never reach zero collisions → they're
  genuinely congestion-*infeasible* in 2 layers, not just slow. Reverted.
- **Lower `mcon_weight`** (more met1 detours to relieve li1 congestion): no help.
- **Cell whitespace padding** (`RECIPE_CELL_PAD`, extra columns): no help, the
  congestion is *local*, so end padding tracks go unused. Reverted.
- **Active to rail gap** (move the active area off the rail so low contacts clear
  it geometrically, removing the need for the lift): BREAKS routing, it shifts
  the active area off the hand tuned `grid_ys`, and detaches sources from the rail
  (sources need to abut). Would require coordinated grid re tuning + source strap
  work. Reverted.
- **met4/met5 (5 to 6 routing layers):** REJECTED on principle, even if it routed
  the oscillators, a 6 layer standard cell is garbage (the foundry does these in
  2). It masks a bad placement with absurd metal instead of fixing it. Reverted
  cleanly; verified no regression.
- **Re running the hard residual through the full recipe/metal/grouping ladder:**
  0 net new cells. Confirms the recipe approach has plateaued (see below).

---

## Root cause map: why the remaining 185 fail

Residual classified by failure mode (meta+lift, 3 to 4 layers):
`~TIMEOUT (dominant) · LVS-SHORT · SMT-UNSAT · NO-TERMINAL · OTHER(physical)`.

The dominant TIMEOUT cause was **root caused**: after the placer caps, placement
completes; the hang is the **router (PathFinder) oscillating**. Crucially, the
**drain lift itself over constrains complex high fan in cells**, verified on
a2111oi_2: with lift OFF it converges routing (but shorts); with lift ON it
oscillates forever. So those cells are stuck: *lift off → routes but shorts; lift
on → no short but unroutable in 2 layers.* The metal ladder (Fix 6) resolves this
for the drive 2 cases (met2 gives the room). The ones that remain **oscillate even
at 4 layers** (e.g. a2111oi_0), that is a **placement** problem, not a capacity
one: a bad transistor ordering creates crossings that no reasonable routing
resolves, and more metal just papers over it.

---

## CURRENT BLOCKERS

**1. Placement quality (THE blocker, gates the largest group).**
The remaining big combinational cells (5 input AOI/OAI at every drive) and the
sequential cells (flip flops / latches, ~40) don't route even at 4 layers because
lclayout's placer produces poor transistor orderings, misaligned P/N gates and
avoidable net crossings. It optimizes an *estimated wirelength* and has the right
idea (it does gate matching), but the search is weak and it doesn't treat
**routability** (crossings, P/N gate column alignment) as the objective. The
foundry fits these same cells in **2 layers** purely through superior placement
(Euler path diffusion sharing + gate alignment), not routing tricks, and our row
is actually *taller* than foundry hd (3.33 vs 2.72 µm), so we have *more* tracks,
not fewer. **This is the single highest leverage fix and it's also the piece that
generalizes to new tech parameters, i.e. the DTCO north star.**
→ *Path forward:* a BonnCell style placement pass, dual Euler path (single
diffusion strip with aligned gates for both rows) with a **routability objective**
(reward gate alignment, penalize crossings) instead of wirelength. Finger grouping
(Fix 7) was step 1. The per cell device counts are small enough that a smart exact
search is tractable. This is deep, multi day work; do it fresh and regression test
against the committed 252.

**2. Converge but LVS fail routing shorts (a distinct, smaller class).**
Some cells *do* route (converge) but fail LVS with a real routing short. Example
diagnosed: **a221o_2**, the A branch pull down's bottom node is routed to **X**
(the output) instead of **VGND** (the B branch is correct). It's a localized
mis route, not obviously systematic. Get the per cell diff with
`run_cell.sh <cell> --verbose` + `awk '/LVS extracted netlist:/,/end;/'`.
→ *Path forward:* determine whether the lift mis lifts a source, or it's a
placement adjacency issue; may recover several cells if a common cause is found.

**3. Router non convergence is a genuine infeasibility, not slowness.**
Confirmed the PathFinder oscillation is not fixable by more iterations or
history cost tuning, for a bad placement in a tight cell there is no legal 2 layer
routing. This is downstream of blocker #1; fixing placement fixes this.

**4. `conb_1`** (1 cell), constant tie-hi/tie-lo cell with real tie structure;
excluded from the device less path. Low value.

**Not blockers (resolved / dead ends):** metal capacity (met2/met3 ladder handles
the drive 2 congestion); device less cells (Fix 8); the Rust router / fold mode /
extra metal layers (ruled out above).

---

## What generalizes to the DTCO goal
The recipe knobs (lift / layers / placer / mcon) are legitimate DTCO dimensions
and per cell tunable. But the metal ladder is a *release valve*, it buys a
complete library now at the cost of foundry faithfulness (met2+ inside a cell
deviates from hd and eats block level tracks). The durable win is **blocker #1**:
a routability aware placer that pulls cells back to foundry faithful 2 layer
layouts *and* re derives good placements when the tech parameters change. That is
the thing worth building next.

---

## Session 2, git worktrees + the channel length fix (252 → 258)

**Worktree setup (Option A).** Split the blockers into isolated branches
(`placement`, `router-shorts`, `physical-cleanup`) as git worktrees. Snag found
and solved: `lclayout` is an **editable install pinned to the main tree's path**
and is gitignored, so plain worktrees would all share one lclayout. Fix: each
worktree gets its own `lclayout/` copy and `run_cell.sh` prepends
`$ROOT/lclayout/src` to `PYTHONPATH` (committed 776180b), verified isolated
(each worktree imports its own lclayout).

### Fix 9, honor netlist channel length (66bea76) → +6 cells
Root cause: the tech forces `gate_length=0.15µm` and lclayout **ignored the
netlist's per device `L`**. Low power / delay / decap cells use longer channels
(clkinvlp L=0.25µm; clkdlybuf/dlygate similar; decaps L=1.05µm) and were drawn at
0.15µm → LVS mismatch on L. Fix: `transistor.py` takes `max(tech default, netlist
L)`. No op for standard logic (L == default; golden verified clean). Also guarded
`euler_placer._io_ordering_cost` against all power net cells (empty signal net list
→ `min()` crash). Recovered: clkinvlp_2, clkdlybuf4s18_1/2, clkdlybuf4s25_1/2,
dlygate4sd2_1. **258/437.**

### New findings on the remaining hard classes
- **Decaps (~10):** the L fix gives them the correct L, but they're MOS caps with
  **source == drain == VPWR** (a long, >1 unit cell wide device). Their S/D extract
  as *floating* nodes, the router doesn't connect the long S==D device's
  source/drain to the rail. Deeper router work; distinct from normal cells.
- **AOI/OAI-b shorts (a21boi, o21bai):** converge but LVS fail because an internal
  **series** node (e.g. SNDA1) shorts to VGND, a single column rail abut that the
  drain lift's ≥2 column guard skips. Added `RECIPE_LIFT_MIN_COLS` (router shorts
  branch) to lift single column nodes, but min_cols=1 did **not** fix them, the
  SNDA1 short goes via the B1_N inverted input structure, not a simple rail abut.
- **lsbuf isowell (6), sdf scan flops (6), clkdlybuf4s50 / dlygate4sd3 (biggest
  delay chains):** don't route even at 3 to 4 layers, the placement bound / large-
  cell class (blocker #1).

### Net: the major blocker is confirmed
The tractable classes (recipe search, metal ladder, device less, netlist L) are
now harvested at **258/437**. Everything left, placement bound big AOIs/flops,
decap S==D routing, isolation well level shifters, needs the deep work, chiefly
**blocker #1 (routability aware placement)**. That's the branch to push on next.

---

## Session 3, double height fallback + tight lift clearance (the placement wall, sidestepped)

Instead of writing the routability aware placer (blocker #1), we attacked the
routing wall with two orthogonal knobs. Both default to no op; golden verified clean.

### Fix 10, `RECIPE_LIFT_TIGHT`: reach only lift clearance (fixes narrow transistor shorts)
The drain lift (Fix 3) requires a "clearing" node to relocate a rail adjacent drain
to. Its clearance was `via_reach + li1_spacing` (~335 nm). **Narrow transistors
(small W) have a diffusion so short that NO node clears that zone** (`clearcols=0`),
so the lift silently can't fire and the drain shorts to the rail. Diagnosed on
a2111oi_0: `Y ndiffusion railadj_cols=3 clearcols=0`. Fix: `RECIPE_LIFT_TIGHT=1`
requires only that the lifted pad does **not touch** the rail (reach only, ~165 nm)
, LVS clean, at worst a li1-spacing DRC nit. Recovers single height shorts
(a21boi_2, a221o_2) that Fix 3 alone couldn't. This is a genuine improvement to the
lift itself, independent of double height.

### Fix 11, `RECIPE_HEIGHT_MULT`: double height cells (the routing wall sidestep)
`=2` scales `unit_cell_height` → a **double height cell** (spans two standard rows);
the middle becomes a large routing channel. Cells that **oscillate forever** in a
single row now converge: a2111oi_0 (2 iters!), a221o_4 → LVS clean at `H=2 + tight`.
This is a legitimate, industry used technique (complex cells go multi height), and
it's *targeted*, only the hard cells pay the area, not the whole library. It trades
area for masking the placement problem, but via a real technique (unlike extra metal
layers).

### The policy (as requested): single height first, double height fallback
`solve_cell` ladder now tries single height (standard → tight lift → metal ladder)
**first**, and only promotes to double height when a cell won't route single height.
So cells stay as faithful/dense as possible; double height is the last resort.

### Limitation, flip flops
The "cheap" double height (2 stack, tall middle channel) helps *vertical* routing but
keeps the cell **wide** (all devices in two long rows). Flops (~24 devices) are still
too wide + the 2× graph is slow → they time out even at double height (progressing,
not oscillating). The real fix for flops is a **4 stack double height** (devices split
across two rows → the cell gets *narrower* too), which needs a genuine change to
lclayout's cell template/placer. That's the next step for the sequential cells.

### Status
Harvesting the residual with the single→double ladder now (early: tight lift is
recovering single height shorts fast, the faithful outcome). Coverage number to
follow once the run completes.
