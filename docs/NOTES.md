# lclayout (LibreCell), working notes

Layout generation tool for the autonomous sky130 cell flow. Repo cloned here: `layout-gen/lclayout`.
Maintainer: Thomas Kramer (codeberg.org/librecell/lclayout). Version 0.0.18 (Alpha).

## Install (done 2026-06-30)
Installed into the micromamba **eda env** (`~/eda-env`), which is the active Python (3.14.6):
```
~/eda-env/bin/pip install ./lclayout        # pulls klayout, z3-solver, pysmt, networkx, scipy, liberty-parser
~/eda-env/bin/pip install matplotlib        # optional dep, needed by the router's inspect module
```
- **klayout ships a cp314 wheel (0.30.9)** → Python 3.14 works, no version problem.
- Z3 SMT solver is the engine for DRC cleaning + routing constraints.

## ⚠️ REPRODUCIBILITY, set PYTHONHASHSEED (hard requirement for our flow)
From the README, verbatim:
> You may want to generate standard cells in a fully reproducible manner. Right now there is some
> non determinism in LibreCell that has not been investigated yet. The current workaround is to set
> the PYTHONHASHSEED environment variable.  `export PYTHONHASHSEED=42`

ALWAYS prefix runs:
```
PYTHONHASHSEED=42 lclayout ...
```
**Why this matters for us:** a non deterministic generator breaks golden-diff/regression (spec 7F) and
char determinism (1K6), same netlist could yield different layouts run to run. It's a *workaround*, not a
fix → there may be residual non determinism. **TODO: verify by generating twice and diffing the GDS** before
trusting it for regression.

## Invocation (I/O)
```
PYTHONHASHSEED=42 lclayout --netlist cells.sp --tech TECH.py --cell CELLNAME --output-dir OUTDIR
```
- INPUTS: transistor SPICE netlist (`--netlist`, the cell as a `.subckt`), PDK tech file (`--tech`, Python, 
  encodes layers/rules/grid/cell-template), cell name (`--cell`).
- OUTPUTS per cell: `.gds` (geometry), `.lef` (P&R abstract: pins/blockages), `.mag` (Magic), `.oas` (OASIS).
- DRC + LVS are done **internally** (Z3 DRC clean + LVS vs the input netlist) → output is clean by construction.

## Capability ladder, results on the BUNDLED DUMMY TECH (2026-06-30)
Ran `examples/cells.sp` across the difficulty ladder. 13/14 PASS (DRC+LVS clean, GDS written):
- ✅ INVX1, NAND2/3, NOR2/3, AOI21/22, OAI22, MUX2, XOR2  (~1s each)
- ✅ **LATCH, DFFPOSX1 (6.5s), DFFSR (31s)**, sequentials work, better than the "weak on sequentials" reputation
- ❌ **FAX1** (full adder), internal router bug: "Node reserved for net VDD but used for net GND" (long tail, likely fixable)
- Runtime scales with complexity: ~1s (INV) → 31s (DFFSR).
- Example AND2X1 = 1.80 × 2.76 µm; render at `layout-gen/AND2X1_render.png`.

## ⚠️ Big caveat: this is the DUMMY tech, NOT sky130
Dummy rules are simpler/more permissive than sky130. Sequentials passing here is encouraging but NOT proof
they pass on sky130 (harder rules → bigger SMT problems → longer runtime, possible new failures).

## sky130 tech.py, community reference FOUND (2026-06-30)
A real sky130 lclayout tech file exists: **LibreSilicon StdCellLib `Tech.SKY130/librecell_tech.py`**
(github.com/thesourcerer8/StdCellLib). Downloaded to `layout-gen/sky130-tech-ref/librecell_tech.py`.
- Same structure as dummy_tech.py, real sky130 layer:datatype numbers (diff (65,20), nwell (64,20),
  poly (66,20), mcon (67,44), tap (65,44)) + sky130 rules (gate_length 150nm poly.1a, gate_ext 130nm poly.8).
- **Test (INVX1, our lclayout 0.0.18):** STRUCTURALLY COMPATIBLE, parses + runs full place/route/DRC-clean
  (SMT SAT). BUT **LVS FAILED** ("netlists don't match"), no GDS written. Warnings: missing via weights
  metal1→pplus/nplus; **pplus==nplus==(65,44)** (same layer → breaks n+/p+ device recognition).
- Targets LibreSilicon's TALLER cell (unit_cell_height=3330nm), NOT our 9T/2.72µm. Has TODOs
  (transistor_offset_y tuning, nwell_pin GDS uncertainty).
- **Verdict: strong starting point, not drop in.** Task = adapt+fix+verify, not build from scratch:
  (1) retarget cell template to 9T/2.72µm low V; (2) fix pplus/nplus collision + via weights;
  (3) feed a proper sky130 netlist (real device models + bulk ties, dummy cells.sp is generic, likely
  the LVS mismatch cause); (4) cross check rule numbers vs magic sky130A.tech.

## sky130 PDK source files (on disk) for building/verifying the tech
Base: `~/.ciel/ciel/sky130/versions/0fe599b2.../sky130A`
- DRC rules + layer:dt map: `libs.tech/magic/sky130A.tech` (style drc ~L1440, cifoutput gdsii ~L691)
- routing layers/pitch/dir/vias: `libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef`
  (li1=V pitch .46 w.17; met1=H pitch .34 w.14; met2=V .46; vias licon/mcon .17, via .15, via2 .20)
- routing tracks: `libs.tech/openlane/sky130_fd_sc_hd/tracks.info` (met1 pitch 0.34 → 9T=8×0.34=2.72µm)
- klayout signoff DRC: `libs.tech/klayout/drc/sky130A.lydrc`
- online readable rules: skywater pdk.readthedocs.io/en/main/rules/

## EMPIRICAL: ran the REAL hd inv_1 netlist through community tech (2026-06-30)
Extracted real `sky130_fd_sc_hd__inv_1` from the hd CDL (`hd_inv_1.cdl`): nfet_01v8/pfet_01v8_hvt,
pins A VGND VNB VPB VPWR Y, WN=0.65 WP=1.0.
- lclayout RECOGNIZES sky130 netlists: channel type = model.startswith('n')→NMOS else PMOS (nfet→N, pfet→P);
  supply/ground sets = {vcc,vdd,vpwr}/{gnd,vss,vgnd} (so VPWR/VGND work). VPB/VNB NOT recognized → treated
  as signal nets (lccommon/net_util.py).
- **RESULT: FAILS at ROUTING, "Net 'A' has no routing terminal" / "Nets without terminals."** Parsing OK,
  placement OK, routing fails (never reaches LVS/DRC). Tying VPB→VPWR/VNB→VGND did NOT fix it → bulk nets
  are NOT the blocker. The GATE net can't get a routing terminal.
- **Root cause: the community tech's grid/contact/cell-template setup is HAND HACKED for LibreSilicon's
  3330nm cell** (grid_ys[2]+=110, grid_ys[14]-=10 magic numbers, routing_grid_pitch_y=135nm) and is FRAGILE
  to cell geometry, it ran place/route/DRC on the small dummy INVX1 (WN0.25/WP0.5, only LVS failed) but
  fails earlier at routing on the real hd inv (WN0.65/WP1.0). The grid/cell machinery doesn't generalize.

## Re prioritized to do (empirically corrected)
1. **#1 blocker = cell template + routing grid + contact setup**, NOT the implant/LVS bug (never reach LVS).
   The hand hacked grid_ys must be REPLACED (not tweaked) + retargeted to real sky130 9T/2.72µm cell.
   The tech's RULE VALUES are good (real sky130 numbers w/ rule names), the GEOMETRY/GRID machinery is broken.
2. Then: split n+/p+ implant (pplus==nplus==(65,44) bug) + add NPC layer + fix via weights (metal1→pplus/nplus).
3. Then: LVS + the WP=0.76 lvt inverter.
Possible alt path: build sky130 tech INCREMENTALLY from the WORKING dummy_tech structure, swapping in sky130
layers/rules group by group + testing each, may be cleaner than debugging the community tech's grid hacks.
Next debug option: `--debug-routing-graph` to pinpoint the missing terminal cause.

## LADDER BASELINE: community tech on real hd cells (2026-06-30)
Ran 12 hd cells (inv_1,clkinv_1,buf_1,nand2_1,nor2_1,and2_1,or2_1,o21ai_1,a21oi_1,nand3_1,mux2_1,xor2_1)
through lclayout PnR + community tech, bulk tied VPB→VPWR/VNB→VGND. **RESULT: 0/12 pass, ALL fail
IDENTICALLY at "ROUTING: net has no routing terminal."** Single systematic root cause = the hand hacked
cell-template/grid section (librecell_tech.py ~L219-428: 3330nm cell, routing_grid_pitch_y=135, grid_ys[]
magic pokes), not cell specific. Gate net can't get a routing access point (poly→licon→li1 not landing on a
grid node). Fixing that ONE thing should unblock the whole ladder. Scripts: layout-gen/ladder_run/.
Direction options: (a) --debug routing graph to see the missing terminal; (b) retarget cell-template/grid to
clean 9T/2.72µm; (c) build sky130 tech INCREMENTALLY from working dummy_tech, swapping sky130 values group by-
group + testing each (safest, always a working baseline, pinpoints which change breaks routing).

---

# SESSION 2 (2026-06-30): corrected root cause + full library characterization

## ⚠️ Session 1 conclusions above were WRONG, corrected here
The "hand hacked grid is the #1 blocker" conclusion (lines 84-108) was a **misdiagnosis**.
The real universal blocker was **W/L unit misinterpretation** (bare microns read as METERS →
transistors 1e6× too large → no routing terminal). The community grid is *fragile* but NOT the
primary blocker. Lesson: verify the hypothesis before declaring root cause.

## Universal harness fixes that unblocked the simple cells (committed)
1. **W/L units**: append `u` to w=/l= (lclayout reads bare numbers as meters).
2. **Device model + ports**: map nfet*→nmos, pfet*→pmos; drop VPB/VNB from SUBCKT header but
   keep bulk tied to rails (lclayout nmos/pmos are 3 terminal; LVS compares class names).
3. **Multipliers → parallel devices (EXPAND)**: `m=N` becomes N separate parallel devices, NOT
   one folded wide W. Folding made drive 4 generate a single transistor whose W (4.0µm) exceeds
   unit_cell_height (3.33µm) → "device taller than cell" → no gate terminal. (commit f41d0a2)
4. **Placer = hierarchical**: default meta/Euler stalls on the many devices expansion produces.
5. **Tapless**: sky130 hd logic cells have NO tap (verified by GDS layer scan AND Magic render:
   taps live only in tap_1/tapvpwrvgnd_1). Patched lclayout `enable_well_taps` flag, set False.

## FULL LIBRARY FAILURE TAXONOMY (81 cell partial baseline, fold harness, alphabetical = hardest first)
| Outcome | Count | What it means |
|---|---|---|
| PASS:clean | 18 | DRC+LVS clean, **almost all are drive 1** (incl. complex AOI a311oi_1, a41o_1) |
| FAIL:routing | 31 | drive 4: fold→"device taller than cell". EXPAND+hierarchical fixes the routing, but then → FAIL:lvs |
| FAIL:lvs | 21 | **the dominant true blocker**, net merge short (output Y merged with VGND/internal net) |
| FAIL:placement | 6 | same net merge bug caught earlier: "Node reserved for net Y but used for net PNDA" |
| FAIL:timeout | 2 | hierarchical placer slow on high drive expanded cells |

**Pattern: drive 1 cells across MOST logic families PASS. Drive-2/4 and complex multi branch
gates FAIL**, almost all trace to ONE lclayout bug (below). With EXPAND+hierarchical the
FAIL:routing cells convert to FAIL:lvs (they now place+route+DRC clean but short), confirming
the single root cause.

## ★ THE DOMINANT BLOCKER = an lclayout PLACER/ROUTER bug, NOT a tech file issue
**Symptom (nor3_1, the clean minimal repro):** 3 parallel NMOS share diffusion as Y│VGND│Y│VGND.
The router connects the two Y diffusion regions with a li1 wire that runs straight THROUGH the
intervening VGND contact → Y and VGND merge into one net (extracted: `'VGND,Y'='VGND,Y'`, all
NMOS S=D shorted). lclayout's router even *detects* this (router.py:412 `"Short circuit of nets
detected"`) but only logs it and emits the shorted layout; LVS then catches it.
- nor2 (Y│VGND│Y, single middle node) passes; nor3 (two interleaved Y and two VGND regions) shorts.
- Sibling bug in euler_placer.py `_remove_gaps`/`__need_gap` (flip unaware `left.drain_net !=
  right.source_net`) removes a needed diffusion gap → the FAIL:placement variant.

**Five tech level levers tried on nor3, ALL failed** (proves it is NOT tech fixable):
1. Cheaper metal1→metal2 via weight (152000→2000), still shorts.
2. Clean uniform routing grid (removed the grid_ys[14]-=10 hand hacks), still shorts.
3. `--signal-router steiner` (vs dijkstra), still shorts.
4. `--placer hierarchical`, still shorts.
5. li1 (l_metal1) restricted to vertical only routing (force horizontal onto met1), still shorts.

→ **Conclusion: the full hd library is NOT achievable by tech file tuning alone.** lclayout
(self described "very early stage, not ready for productive use") cannot correctly route
interleaved parallel device source/drain nets. Closing this needs lclayout placer/router
development (better diffusion gap insertion + short free net routing) OR a more capable
generator (e.g. SMTCell, designed for full design rule SMT encoding + retargeting).

**This IS the Paper 2 result, not a setback:** it precisely characterizes where the leading
open source cell generator breaks on a real foundry library, defining the gap a better
(SMT/ML-guided) generator must close. The net merge short is exactly the kind of constraint a
correct SMT placement/routing formulation guarantees away.

## Harness/infra added this session (committed)
- `harness/run_all.sh`, runs all 437 cells, categorizes each outcome → `.work/results.txt`.
- `run_cell.sh` env knobs: `RUN_WORK` (isolated work dir), `RUN_TECH` (test tech copies),
  `EXPAND` (0=fold/1=expand, default 1), `PLACER` (default hierarchical).

## State to resume from
- Branch `sky130-port`, HEAD = commit f41d0a2 (harness: expand + hierarchical + runner).
- A full categorization run with the NEW harness was started but is SLOW (hierarchical+expand
  takes up to ~75-150s/cell on high drive cells). Re launch: `harness/run_all.sh` (bg).
- Next decision (for Sam): (a) attempt lclayout router/placer patches to fix the net merge short
  [= tool development, becomes Paper 2 work]; (b) accept lclayout's envelope and characterize it
  fully as the published "gap" result; (c) evaluate SMTCell as the retargetable generator.
