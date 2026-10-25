# Standard Cell Library Flow, Master Qualification Checklist
**Purpose:** the complete, de duplicated set of every foundry / library team check, organized in the execution order of an *autonomous* sky130 cell generation + characterization flow. This is the spec the generator must reproduce per cell (+ once per library). Synthesized from a 5 domain deep research sweep (physical/DFM, characterization/views, reliability, variation/corners, library architecture), then extended by a round 2 deep check (layout generation algorithms, flow orchestration/infrastructure, adversarial completeness critic), which added Stage 2's full pipeline, Stage 7 (orchestration), the Stage 1·0 input side pre flight, testbench/grid methodology, golden library calibration, and the sky130-specific gotchas marked **[r2]**.

**Legend**
- **Tier:** `E` = research grade essential · `P` = production/foundry-only (skippable for a research cell, but state the exclusion) · `N/A` = not applicable to sky130 (130nm single patterning, NLDM only PDK)
- **Auto (open source sky130):** ✅ turnkey FOSS · 🟡 scriptable, no turnkey tool · ❌ commercial tool or silicon required
- **Status** = our WP=0.76 lvt inverter: ✔ done · ◐ partial · ☐ todo
- **OSS tool map:** Magic (DRC/extract/LEF/antenna) · netgen (LVS/ERC) · klayout (DRC/fill/XOR) · cvc_rv + extra_be_checks (voltage aware ERC/soft-connect) · open_pdks (check_density.py / generate_fill.py) · ngspice/Xyce (SPICE) · CharLib / lctime / libretto (characterizers) · OpenSTA (lib lint/STA) · yosys+eqy (LEC) · OpenROAD/OpenLane (P&R flow) · PDNSim (IR/EM) · Fault (ATPG)

---

## STAGE 0, Library architecture (decide ONCE per library)

### 0A. Architecture decisions
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|0A1|Track/row height (sky130 hd=9T-equiv; hs/ms/ls/lp/hdll/hvl families)|LEF SITE + tracks|✅|E|✔ 9T|
|0A2|Routing/pin grid (pitch, offset, on grid pins, M1 access)|tracks + LEF|✅|E|◐ designed|
|0A3|Vt flavor / channel length plan (sky130: implant Vt; LVT PMOS Lmin=0.35µm constraint)|per flavor build|🟡|E|✔ lvt|
|0A4|Beta (Wp/Wn) convention / skew target|SPICE sizing|✅|E|✔ β≈1.8|
|0A5|Drive strength ladder (X1/X2/X4/X8…)|param cell gen|🟡|E|◐ philosophy|
|0A6|Power rail + well architecture, rail width, tap strategy|LEF/GDS template|✅|E|✔ 0.48µm rail|
|0A7|Abutment/boundary contract (any 2 cells adjacent → DRC clean)|edge template + Magic DRC|🟡|E|◐ designed|
|0A8|Naming taxonomy (func+drive; GDS/LEF/lib/Verilog parity)|schema doc|✅|E|☐|
|0A9|Pin naming / polarity / CLK·RST·SET·SCAN conventions|convention doc|✅|E|☐|

### 0B. Cell list completeness audit ("did you forget a cell")
| # | Item | Tier | Status | Note |
|---|---|---|---|---|
|0B1|Combinational: INV/BUF, NAND/NOR/AND/OR 2-4in, AOI/OAI, XOR/XNOR, MUX, MAJ, adders|E|◐ INV only||
|0B2|Sequential: DFF (rst/set/scan/en perms), latches, scan FF, with/without Q̄|E|☐||
|0B3|Clock/CTS: balanced clock buf/inv, delay cells|E|☐||
|0B4|ICG integrated clock gate (latch based) + liberty `clock_gating_integrated_cell`|E|☐|forgotten attr|
|0B5|Tie hi / tie lo (conb)|E|☐||
|0B6|Filler cells (multiple widths)|E|☐|physical only|
|0B7|Decap cells, graded values|E|☐|physical only|
|0B8|Tap / well tie cells (satisfy max tap distance)|E|☐|physical only, **forgotten**|
|0B9|Endcap / boundary (row terminators)|E|☐|physical only, **forgotten**|
|0B10|Antenna diode cells|E|☐|physical only|
|0B11|**Physical only classification list** (LEF/GDS but no liberty fn → synth/LEC ignore)|E|☐|**most forgotten audit**|
|0B12|Spare / ECO gate array cells|P|☐||
|0B13|DFT: scan mux, lockup latch (cross clock scan)|P|☐||
|0B14|Level shifter HL/LH (multi VDD), sky130 has no turnkey, must build dual rail|P|☐||
|0B15|Isolation cells (ISO) + always on pin|P|☐||
|0B16|Retention flops (save/restore, always on rail)|P|☐||
|0B17|Power switch / header footer (MTCMOS)|P|☐||
|0B18|Always on buffers|P|☐||
|0B19|I/O + ESD pad cells (separate sky130_fd_io lib)|P|☐||

### 0C. Additional architecture decisions [r2]
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|0C1|**Body bias pin architecture (VPB/VNB)**, sky130 4 term cells expose bulk pins; decide tied to rail (no bias) vs routed (bias capable); propagates to pg_pin/LEF/char|template|✅|E (default tie)|☐|
|0C2|Multi-/double-height cell policy (large flops/complex AOI exceed 1 row → different site/rail/abut contract)|extended template|🟡|P|☐|
|0C3|Target tool feature contract (state OpenSTA/OpenROAD + the *minimum* LEF/lib subset they consume → drives view gen scoping, see 4D)|planning|✅|E|☐|
|0C4|**PDK variant + version lock**, sky130A vs sky130B differ (models/DRC/tech); lock variant + open_pdks commit + ngspice model hash in manifest|manifest assert|✅|E|☐ **sky130 trap**|

---

## STAGE 1, Per cell electrical design & pre layout characterization (schematic SPICE)

### 1·0. Pre flight: input / netlist / simulator audit [r2], RUN BEFORE ANY CHAR
*(v1's single largest gap: characterization silently assumed a correct netlist + configured simulator already existed. A beautiful .lib for a functionally wrong or mis binned cell looks valid.)*
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|P1|Source netlist **functional proof** (transistor→Boolean over all 2^n vectors; PUN/PDN complementarity, no sneak paths/always-on fight, latch storage loop intact)|ngspice DC + truth extract|✅|E|☐|
|P2|Electrical sanity / DC op point audit (no floating nodes; 4 term bulk ties VPB/VNB; S/D not reversed; supply name typos)|ngspice `.op` + lint|✅|E|☐|
|P3|**Corner file + MC switch audit**, sky130 `.lib` sections tt/ss/ff/sf/fs are **PROCESS ONLY** (V&T are yours to sweep); `mc_mm_switch`=local mismatch, `mc_pr_switch`=global; `tt` vs `tt_mm`|config linter|✅|E|☐ **silent error trap**|
|P4|**W/L bin center compliance**, BSIM4 is binned; arbitrary W lands in a gap/boundary → I V discontinuity + non monotonic char; the drive ladder must sit at bin centers|bin map script|✅|E|☐|
|P5|Vt flavor model consistency (nfet_01v8 vs _lvt/_hvt matches LEF/lib naming; enforce LVT PMOS Lmin=0.35µm)|netlist lint|✅|E|✔ lvt known|
|P6|**Numerical sign off of the char setup**, pin `.spiceinit` `.options` (reltol/abstol/vntol/gmin/method/trtol/maxstep); convergence study: re run tighter, assert Δ<bound|ngspice|✅|E|☐|

### 1A. Design + corner space
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1A1|Transistor sizing (EDP/β optimization)|ngspice + scripts|✅|E|✔|
|1A2|Functional / truth table verification|ngspice DC|✅|E|✔|
|1A3|Process corners tt/ss/ff/sf/fs|.lib corners|✅|E|✔ 5|
|1A4|Cross/skew corners sf,fs **with separate rise/fall + NM**|.lib|✅|E|◐ verify split|
|1A5|Temperature corners **incl. inversion crossover** (cold may be slow binder at 0.9V)|.temp sweep|✅|E|◐ only 2T, **gap: locate ZTC**|
|1A6|**Multi Vdd grid** (the V in PVT)|.param vdd|✅|E|☐ **GAP, only 0.9V**|
|1A7|Full PVT cross product (real lib ≈18-30 views, not a diagonal)|matrix script|✅|E|☐ sparse|
|1A8|Worst logic state / input condition corner (per arc)|vector enum|✅|E|◐|
|1A9|RC interconnect corners (cmin/cmax/rcmin/rcmax), applied at STA, **out of cell scope**|OpenROAD MMMC|🟡|P|n/a|

### 1B. Vmin / low voltage (the headline checks for THIS cell)
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1B1|**Vmin sweep** (lowest Vdd: switches + meets NM, at ss+worst mismatch)|ngspice Vdd sweep|✅|E|☐ **#1 GAP**|
|1B2|Near-/sub-threshold characterization (tables extend into exp region)|ngspice fine steps|✅|E|☐ GAP|
|1B3|Vmin shift under local mismatch (ΔVmin at 3σ/4.5σ)|MC @ several Vdd|🟡|E|☐ GAP|

### 1C. Monte Carlo / statistical (biggest methodological hole)
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1C1|Global process MC (`mc_pr_switch=1`)|ngspice + seeds|✅|E|☐ **GAP**|
|1C2|**Local mismatch MC** (`mc_mm_switch=1`, σVt), dominates at low Vdd|ngspice + seeds|✅|E|☐ **GAP, top priority**|
|1C3|Combined global+local MC|ngspice both=1|✅|E|☐|
|1C4|Sample-count/convergence (200-1k for μ/σ; 10k+/importance-sampling for ≥4.5σ tails)|policy|✅/❌tail|E/P|☐|
|1C5|Metrics per run: delay, slew, **leakage(log normal)**, NM, energy, Vmin pass/fail|post proc|✅|E|☐|
|1C6|Distribution moments μ/σ/skew/kurtosis (feed LVF)|post proc|✅|E|☐|
|1C7|Sensitivity / dominant parameter analysis (cheap LVF without full MC)|DOE/regression|✅|research valuable|☐|
|1C8|Seed reproducibility + sample archival (auditable autonomous flow)|seed list|✅|E|☐|
|1C9|Global vs local correlation handling (don't double count)|2 switch method|✅|E|☐|

### 1D. Timing tables (Liberty)
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1D1|NLDM delay (cell_rise/fall) 2 D LUT|CharLib/lctime+ngspice|✅|E|◐ few pts|
|1D2|NLDM transition (rise/fall_transition)|same|✅|E|◐|
|1D3|Slew×load grid def (index_1/2, lu_table_template)|config|✅|E|◐|
|1D4|Rise/fall separation per arc|all|✅|E|✔|
|1D5|Unateness / timing_sense|auto from logic|✅|E|✔|
|1D6|timing_type classification (comb/edge/tristate/clear/preset)|characterizer|✅|E|✔|
|1D7|related_pin / related_output_pin tagging|characterizer|✅|E|✔|
|1D8|Conditional/state-dependent arcs (when + sdf_cond)|Liberate; lctime 🟡|🟡|E|☐ (n/a INV)|
|1D9|Multi stage internal node arc handling|🟡 OSS limited|🟡|E|☐ (n/a INV)|
|1D10|CCS timing (output_current waveforms)|Liberate|❌|P|☐|
|1D11|CCS receiver cap (C1/C2 pre/post-50%, Miller)|Liberate|❌|P|☐|
|1D12|ECSM timing + receiver|Liberate|❌|P|☐|

### 1E. Constraint characterization (sequentials)
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1E1|Setup (rise/fall_constraint)|lctime/CharLib|✅|E|☐ no seq yet|
|1E2|Hold|same|✅|E|☐|
|1E3|Recovery / Removal (async set/reset)|same|✅|E (if async)|☐|
|1E4|**Setup/hold failure criterion def** (X% Clk→Q pushout, bisection), governs all constraint values|config|✅|E|☐ **correctness critical, easy to botch**|
|1E5|Min pulse width (constraint_high/low) **+ statistical, not corner only**|CharLib/lctime|✅|E|☐ GAP|
|1E6|Min period|characterizer|✅|P|☐|
|1E7|nochange / non seq skew / clock gating check arcs|Liberate|🟡|P|☐|
|1E8|Statistical setup/hold σ (→ LVF constraint tables)|MC|🟡|research valuable|☐|

### 1F. Design limits (.lib)
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1F1|Input pin cap per pin (capacitance, rise/fall_cap, ranges)|measured|✅|E|◐|
|1F2|max_transition (pin + library)|policy|✅|E|☐|
|1F3|max_capacitance per output (from grid edge/EM/slew)|characterizer|✅|E|☐|
|1F4|max_fanout / min_fanout|policy|✅|P|☐|
|1F5|min_capacitance|characterizer|✅|P|☐|
|1F6|Library defaults (default_max_*, fanout_load, units)|header|✅|E|☐|

### 1G. Power characterization
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1G1|Internal/switching energy tables (rise/fall_power, slew×load)|CharLib/lctime|✅|E|◐|
|1G2|Switching vs internal (short circuit) energy separation|subtract CV²|✅|E|◐|
|1G3|Intrinsic/hidden power (input toggles, output doesn't)|Liberate;CharLib 🟡|🟡|E|☐|
|1G4|State dependent internal power (when)|🟡|🟡|P|☐|
|1G5|cell_leakage_power default|characterizer|✅|E|✔|
|1G6|**Leakage state tables** (per input vector, 2^N states; log normal)|CharLib/lctime|✅|E|☐ GAP|
|1G7|pg_pin / related_pg_pin binding (multi rail; VPWR/VGND/VPB/VNB)|header|✅|E|☐|
|1G8|power_down_function|attr|✅|P|☐|

### 1H. Noise / SI characterization
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1H1|**Static noise margin / VTC / SNM** (V_IL/IH/OL/OH, butterfly)|ngspice DC|✅|E|✔ **done, 10 corners**|
|1H2|Glitch / dynamic noise margin propagation|ngspice glitch tb|✅|research valuable|☐|
|1H3|CCS noise (CCSN ccb groups), receiver/miller model|Liberate|❌|P|☐|
|1H4|dc_current 2 D I(V) surface|Liberate|❌|P|☐|
|1H5|Propagated noise model (height/width/peak)|Liberate|❌|P|☐|

### 1I. Statistical timing model outputs (.lib variation views)
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1I1|OCV flat derate (early/late), appropriate baseline at 130nm|OpenSTA set_timing_derate|✅|E|☐|
|1I2|**LVF** (per arc σ tables: delay/slew/constraint, mean+σ+skew)|custom MC→emit|🟡|research DIFFERENTIATOR|☐|
|1I3|POCV/SOCV (σ/mean per cell)|derive from MC|🟡|P|☐|
|1I4|AOCV depth/distance tables|MC over chains|❌|P|☐|
|1I5|Sigma target (3σ logic / 4.5σ replicated / 6σ memory), declare it|policy|✅|E|☐ pick 3σ|
|1I6|Min/max (setup/hold) split derates|2 sets|✅|E|☐|

### 1J. Characterization QA / validation
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1J1|Arc + state coverage completeness (no missing when branch)|🟡 inside view|🟡|E|☐|
|1J2|Auto stimulus/state derivation from netlist|lctime (SAT recovery)|🟡|E|☐|
|1J3|Monotonicity check (delay/trans/power ↑ with load+slew)|script|🟡|E|☐|
|1J4|Negative value / negative delay / negative constraint flag|script|🟡|E|☐|
|1J5|Outlier / table smoothness (SPICE convergence artifacts)|script|🟡|E|☐|
|1J6|**Golden SPICE re sim correlation** (resim sampled arcs, error %)|ngspice|✅|E|☐ **key**|
|1J7|Interpolation/grid-adequacy (mid point resim error)|script|🟡|E|☐|
|1J8|Liberty syntax/semantic lint|OpenSTA read_liberty|✅|E|☐|
|1J9|Function attr vs SPICE truth vs Verilog equivalence|yosys/ngspice|✅|E|☐|
|1J10|Structural consistency (pin lists, index lengths, units, templates)|parser lint|✅|E|☐|

### 1K. Characterization testbench & slew/load-grid methodology [r2], HOW to choose the grid
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1K1|**FO4 anchoring of the slew/load grid** (center load index on FO4≈4·Cin, slew index on slew@FO4, geometric spread; bracket real usage so STA never extrapolates past max_transition/max_cap; FO4 shifts per corner → anchor per corner)|pre char calib sim|✅|E|☐|
|1K2|**Reference inverter chain stimulus** (drive input from an upstream inverter, NOT an ideal ramp; real RC like slew or delays are optimistic and won't correlate to silicon/STA)|tb template|✅|E|◐ our tb uses 50ps PULSE, upgrade to ref driver|
|1K3|**Trip point declaration + header match** (input/output_threshold 50%, slew_lower/upper 20-80 vs 10-90, slew_derate; testbench `.measure` MUST equal the Liberty header or STA reads back a systematic skew)|assert|✅|E|☐|
|1K4|Input cap measurement methodology (rise/fall separate, Miller during switching, V dependence; charge based; feeds 1K1 + max_cap)|ngspice|✅|E|◐|
|1K5|Output load model (lumped C ok for NLDM, but document the assumption + value range + receiver pin cap)|, |✅|E (doc)|☐|
|1K6|Char determinism / bit reproducibility (single thread golden mode + pinned versions so golden diff is meaningful)|container|✅|E|☐|

### 1L. Golden library calibration [r2], cheap, decisive
| # | Item | Tool | Auto | Tier | Status |
|---|---|---|---|---|---|
|1L1|**Re characterize a SkyWater cell with OUR flow, diff vs the released .lib** (sky130_fd_sc_hd__inv_1 + a flop), diff `cell_rise/fall` + `rise/fall_transition` tables; disagreement >few% ⇒ testbench/threshold/grid/model setup is wrong. The single best validation, far cheaper than silicon. **Must run at `tt_025C_1v80` using their 7×7 grid + 50%-delay/20-80%-slew trips, NOT at 0.9V (no golden data exists below 1.28V).**|lib vs lib diff|✅|E|☐ **DO THIS EARLY** [sky]|
|1L2|Path level correlation (our .lib→OpenSTA delay on a ring/chain vs ngspice resim; bounds accumulated NLDM interpolation error end to end, not just per arc)|OpenSTA vs ngspice|✅|E|☐|

---

## STAGE 2, Layout generation
The hardest stage, **NP complete at every sub stage**, tractable only because cells are small. Difficulty: 🟢 EASY · 🟡 MED · 🔴 HARD. Prior art: **lclayout/LibreCell** (search based: Euler placement + grid graph router; covers combinational end to end) vs **laygo2/BAG** (template and grid: authored topology, better for sequentials). [r2, was a 1 line placeholder in v1.]

**2A. Input prep**, 2A1 logic→transistor netlist PUN/PDN synth (series=AND/parallel=OR, dual) 🟢comb/🔴seq+pass gate (author topology) · 2A2 CDL source of truth + device graph 🟢 · 2A3 netlist normalize/merge/**partition** (optimality vs runtime knob; bad cuts forfeit diffusion sharing) 🟡

**2B. Sizing→folding**, 2B1 size ingestion (W/L from upstream LE/char loop) 🟢 · 2B2 **folding/fingering** (nf=⌈W/Wmax⌉; even/odd parity flips free terminal; couples to Euler; 🔴 at high drive) 🟡

**2C. Ordering / Euler / diffusion sharing, THE CRUX**, 2C1 diffusion share chaining (multigraph trail) 🟡→🔴 · 2C2 **dual P over N Euler path** (one common gate order, both rows continuous; Uehara, VanCleemput): 🟢 inv, 🟡 nand/nor, 🔴 AOI/MUX/XOR/adder (no common path → multi chain + dummy breaks), seq hardest · 2C3 diffusion-break/dummy-gate insertion 🟡 · 2C4 chain flip/order, multi chain 🟡→🔴

**2D. Placement**, 2D1 two row P over N (from Euler order) 🟢 · 2D2 gate column poly alignment (mismatched finger counts force dummies) 🟢→🟡 · 2D3 **intra cell ordering for routability/pin-access** (the area↔pin access trade off) 🔴 · 2D4 gate/route pitch gear ratio 🟡 (benign at sky130)

**2E. In cell routing**, 2E0 routing graph construction (legal li1/met1/poly/licon/mcon points+edges, DRC legal by construction) 🟡 · 2E1 poly gate connect 🟢🟡 · 2E2 S/D→rail 🟢 · 2E3 **internal net routing, the core router** (Steiner/min-cost flow global + maze/A*+rip up detailed, or ILP/PB exact) 🔴 NP complete; single-li1 congestion binds · 2E4 output net + pin reachability 🟡 · 2E5 track assign + layer/via planning (li1 vs met1, min vias, preserve pin tracks) 🟡→🔴

**2F. Pin/port gen**, 2F1 pin on grid + multiple access points (**pin density wall** on wide cells) 🟡→🔴 · 2F2 pin label/text + LEF MACRO PIN 🟢 · 2F3 OBS/blockage gen (over block kills routability) 🟢🟡

**2G. Rails/well/tap/boundary geometry**, 2G1 power rails 🟢 · 2G2 nwell+boundary (half rule to edge) 🟢🟡 · 2G3 well/sub tap insertion (in cell vs library; max tap dist) 🟡 · 2G4 PR-boundary/abut box (width=int poly pitch) 🟢 · 2G5 endcap/boundary dummy poly 🟢🟡 · 2G6 implant nsdm/psdm + Vt implant to edge 🟢🟡

**2H. Template/row-arch enforcement**, 2H1 row-height/track-count frame (laygo2 grid+template) 🟡 once · 2H2 site/placement-grid quantization 🟢

**2I. Parameterization**, 2I1 drive strength X1/X2/X4/X8 (scale W/fingers; higher X → routing/pin congestion, may need re order not just scale) 🟡 · 2I2 cell-family/Vt-variant batch (hardest member dominates) 🟡

**2J. Abutment by construction**, 2J1 half rule edges (well/implant/poly-endcap/rail all simultaneously) 🟡 · 2J2 mirror/flip safety (rail+well symmetry) 🟡

**2K. Optimization + search**, 2K1 objective (area/routability/pin-access/WL/via, conflicting Pareto) 🔴 · 2K2 search (exhaustive+prune / B&B / simulated anneal [lclayout fork] / RL) 🔴 blowup on complex+seq · 2K3 legalize: construct legal by grid (preferred) vs post repair 🟡/🔴

**2L. Tech portability + emit**, 2L1 rule/tech-data driven (lclayout tech.py / laygo2 *_tech; author sky130 tech file once) 🟡 · 2L2 emit GDS/LEF/abstract + metadata (gdstk/klayout/Magic) 🟢

**2M. Forgotten sub problems**, antenna diode stub + LEF antenna areas · dummy-diffusion/parity fill · notch/min-area healing · via/contact arrays (licon/mcon enclosure asymmetry) · floating poly tie off · **multi-row/double-height** (🔴 seq/large)

> **Difficulty map:** comb simple (inv/buf/nand/nor) = lclayout end to end *today*. Complex (AOI/OAI/MUX/XOR/adder) = 🔴 at 2C2/2D3/2E3/2F1. Sequential (latch/DFF/scan) = 🔴🔴, topology must be *authored* (2A1), Euler ill posed across feedback, often multi row; open source autogen here is immature (template/laygo2-style is the pragmatic route).

---

## STAGE 3, Physical verification (on the GDS)

### 3A. DRC sub families
width · same layer spacing · inter layer spacing (poly OD, nwell OD, tap opposite diff) · min area · min hole/slot area · enclosure (licon in li, mcon in-met1, poly/nwell surround) · extension/endcap · end of line (EOL) · notch · corner to corner · grid snap (5nm) · angle/Manhattan · width dependent (wide metal) spacing · via/contact rules (exact size, array pitch, stacked via N1) · implant nsdm/psdm · well (nwell width/spacing, deep nwell) · HV/thick-ox spacing (if HV devices). **Tool:** magic/klayout DRC. **Auto** ✅ **Tier** E. *(min/max-edge length, jog/step, forbidden pitch = 🟡 P.)*
> ⚠️ Some sky130 rules are marked "verify manually" in the deck → **not auto verifiable**; flag as a coverage gap.

### 3B. Antenna (PAE)
metal antenna ratio (per layer cumulative) ✅E · poly antenna ratio ✅E · via/sidewall ratio 🟡P · diffusion diode exemption ✅E · cumulative "connected up" antenna (true value only post route) 🟡 E-block/P-cell. **Tool:** magic `antennacheck` (needs extract first).

### 3C. Density / fill / CMP
min metal density (per window) ✅E · max metal density ✅E · poly density 🟡P · OD/active density 🟡P · density gradient 🟡P · **metal fill insertion** (✅E block / N/A intra cell) · poly/OD/tap FEOL fill 🟡P · fill DRC re run after fill ✅E · wide metal slotting 🟡P · CMP planarity hotspot sim ❌P (no OSS). **Tool:** open_pdks check_density.py / generate_fill.py; klayout.

### 3D. Litho / DFM (production, mostly no OSS for sky130)
LFD litho hotspot ❌P · OPC/ORC verify ❌P · process-window/PV-band ❌P · pin access printability (🟡 access / ❌ litho) · critical area analysis (CAA) ❌P · DFM yield score ❌P · recommended (vs required) rules 🟡P.

### 3E. Multi patterning, **N/A sky130 (single patterning 130nm)**
two-coloring/LELE, odd cycle, stitch, anchor/pre-color, same/opposite-mask spacing, mask density per color, SADP mandrel/cut, *enumerated for completeness; the generator should explicitly skip these and log "single patterned node."*

### 3F. Redundant via
redundant via candidacy / via doubling 🟡P · single via report 🟡P · via array legality (just DRC on array) ✅E. **Tool:** OpenROAD via insertion; klayout.

### 3G. ERC (electrical rule check at layout)
floating gate ✅E · missing well/substrate tap ✅E · gate on diffusion ✅E · floating/unbiased well ✅E · **soft connection** (high R well only connection) ✅E · VDD/VSS short or reversal ✅E · voltage aware overstress/leakage 🟡 (E multi rail) · dangling/floating net + unconnected pin ✅E. **Tool:** netgen + cvc_rv + extra_be_checks.

### 3H. Latchup, geometric portion
max distance to well/sub tap ✅E · n tap↔p tap / guard ring spacing ✅E · OD to opposite well tap spacing ✅E · tap coverage/density per area 🟡E(row) · nwell/substrate continuity across abutment ✅E. **Tool:** magic/klayout DRC.

### 3I. Layout dependent effect geometric markers (electrical impact → char)
WPE (well proximity) 🟡P · LOD/STI-stress SA/SB 🟡P(E if drive strength parametrized on LOD) · OD to OD stress 🟡P · poly spacing effect 🟡P · diffusion-sharing/shared-OD consistency ✅P.

### 3J. Boundary / abutment / tiling (std cell specific)
boundary on grid + fixed height + site aligned ✅E · power rail abutment continuity ✅E · nwell/implant edge continuity ✅E · half-rule/boundary-straddle DRC ✅E · edge keepout/overhang ✅E · endcap/welltie compatibility 🟡P · filler/decap abut legality ✅E · mirror/flip (N/FS/FN/S) DRC clean ✅E · **self array DRC** (place cell in NxM mirrored array, re DRC, single most important abutment catch) ✅E · double height rail/well alignment ✅P.

### 3K. Pin / routability
pin on routing grid ✅E · pin accessibility / #access points 🟡P(E quality) · min pin area + label on pin ✅E · pin to pin & pin to rail spacing ✅E · OBS vs track consistency 🟡P.

### 3L. GDS integrity
layer map / datatype purpose correctness ✅E · off-grid/acute-angle/self-intersect sanity ✅E · cell name validity ✅E · stream out cleanliness ✅E.

### 3M. sky130-specific physical gotchas [r2], named traps the generic DRC families miss
- **Dual DRC deck (run BOTH):** Magic's full rules deck ⊃ the foundry manufacturing deck; klayout's deck is the **sign off subset** (what SkyWater actually rejects) and is more permissive, they **disagree by design**. Run magic + klayout + `mpw-precheck` and reconcile. ✅E.
- **Max tap distance across ABUTTED cells:** `hd` cells lack internal taps and rely on a staggered tap cell grid → the library must guarantee any legal abutment still meets max tap dist (a whole library placement context proof, not single cell DRC). ✅E.
- **licon/mcon stack** enclosure / min count / spacing inside cells (autogen frequently violates; asymmetric enclosure is fiddly). ✅E.
- **li1 in cell R + extraction config:** li1 is high R, non preferred direction → PEX must extract *with* li1 R; pin the `ext2spice` style (R+C vs C only, cthresh/rthresh). ✅E.
- **On manufacturing grid snap** (1nm dbu / 5nm grid; off grid geometry passes some DRC but breaks fracture/abutment). ✅E.

---

## STAGE 4, Connectivity & view generation/consistency

### 4A. LVS family
LVS layout↔CDL (device+net) ✅E · device param W/L/M match ✅E · shorts/opens extraction ✅E · hierarchy/black-box consistency 🟡P · XOR layout vs golden regression ✅E. **Tool:** magic extract + netgen; klayout XOR.

### 4B. View generation (deliverables)
GDSII/OASIS ✅E · tech LEF (layers/vias/rules/antenna/density) ✅E · cell LEF abstract (boundary/pins/OBS/site/symmetry + **antenna gate/diff area**) ✅E · .lib per corner (NLDM ✅E; CCS/ECSM ❌P) · .db binary ❌P (OSS reads .lib) · CDL netlist ✅E · pre layout SPICE ✅E · extracted PEX SPICE/DSPF ✅E · functional Verilog (+specify, UDP) ✅E · ATPG/SDF Verilog 🟡P · layer map file ✅E · FRAM/Milkyway/OA DB ❌P · datasheet 🟡P · **manifest/checksum/version** ✅E.

### 4C. Cross view equivalence (the "top forgotten sign off")
LEF vs GDS pin/OBS/boundary 🟡E · antenna model vs GDS 🟡P · .lib vs SPICE NLDM correlation ✅E · Verilog vs truth table / LEC ✅E (yosys eqy) · **pin name + direction + order across ALL five views** ✅E · pg_pin consistency across lib/LEF/CDL/Verilog ✅E · lib vs LEF attr (direction/clock/cap) ✅E · cross view naming/case ✅E.

### 4D. sky130 LVS/LEF specifics, pin access & OSS flow scoping [r2]
- **Router pin access legality:** DRC clean ≠ routable. `hd` exposes pins on li1+met1, but OpenROAD often treats li1 as ~unroutable for signal → met1 access matters; this is a distinct sign off (not "a pin exists"). ✅E (OpenROAD trial route / grid access script).
- LEF **OBS** correctness (missing → router shorts into the cell; over block → unroutable). ✅E.
- LEF **SITE/SYMMETRY/ORIGIN/FOREIGN/CLASS/SOURCE** structural QA (wrong values break legalize/flip/abut subtly). ✅E.
- **LVS PR name + param mapping:** extracted devices must map to `sky130_fd_pr__*` subckts with matched params; the antenna diode **perimeter** model bug & `sim2spice` aliasing are frequent LVS mismatch sources. ✅E (netgen).
- **Liberty header/units self consistency** (time/cap/voltage/current/leakage units, nom_PVT, default_operating_conditions, lu_table_template reuse, voltage_map, consistent across the corner set or STA silently misreads ns vs ps). ✅E.
- **OSS flow feature subset scoping:** OpenSTA consumes **NLDM only** (NOT CCS timing / LVF / POCV / AOCV / CCS noise) → generate NLDM (+ maybe ECSM); CCS/LVF is effort with no OSS consumer. A planning decision, belongs in 0C3. E.
- Sequential ff/latch/statetable semantic verify (next_state/clocked_on/clear/preset match the function; LEC can miss a shared bug). ✅E.
- Verilog `specify`/timing-check/X-prop completeness ($setup/$hold/$width, timescale, celldefine). ✅E (iverilog/verilator).

---

## STAGE 5, Reliability / electrical signoff
**sky130 ships NO official EM/aging/ESD/latchup/thermal models** → almost all of this is ❌ **P** (commercial Voltus/RedHawk/Calibre-PERC or silicon). State the exclusion explicitly in the paper. The few that ARE doable open source are marked.

- **EM:** signal avg(J) / RMS(Joule) / peak · power EM rail/strap (🟡 **research relevant** rail sanity via PDNSim) · per via EM · via array current crowding · Blech short length immunity (explains why intra cell EM is usually waived) · Black's MTTF basis · statistical EM budgeting · self heat derated Jmax. *(all ❌P except rail density 🟡)*
- **IR drop:** **static IR (✅E, PDNSim/OpenROAD)** · static ground bounce ✅E · dynamic/transient IR ❌P · effective rail/pin R 🟡P · vectorless worst IR ❌P · decap adequacy ❌P.
- **Self-heating/thermal:** device ΔT · interconnect Joule ΔT · Tj map. *(all ❌P; low priority at 130nm planar.)*
- **Aging:** HCI · NBTI · PBTI · gate ox TDDB · BEOL/inter-metal TDDB · SILC · aging aware timing derate. *(all ❌P, no sky130 aging model.)*
- **ESD:** HBM · CDM (most core relevant) · MM · P2P discharge R · CD path · clamp/missing-protection. *(❌P, IO/level-shifter cells.)*
- **Latchup (electrical):** SCR holding V/I (Vh/Ih) · well tie effectiveness (🟡 **research relevant**, tap placement is a real cell decision) · guard ring injection · single event latchup. *(❌P except tap effectiveness 🟡.)*
- **Soft error:** SEU/Qcrit (🟡 ngspice charge injection, **E only if rad-hard/SER paper**) · SET masking · SEMU/MCU · alpha/neutron FIT. *(P unless SER thesis.)*
- **Connectivity/via integrity:** P2P resistance (🟡 research relevant sanity) · weak/redundant-via (🟡 OpenROAD inserts) · resistive-open/mouse-bite 🟡 · via current crowding ❌P.
- **Other:** stress-migration/SIV (via near wide metal) ❌P · electrical overstress EOS ❌P · metal slotting reliability 🟡P · CMP dishing reliability ❌P · power up in rush (power switch cells) ❌P · LDE stress aging interaction 🟡P.

---

## STAGE 6, Whole library QA, tool qualification, regression, release

### 6A. Library wide QA sweeps
all cells DRC ✅E · all cells LVS ✅E · all cells+abutment pairs DRC ✅E · antenna completeness 🟡E · **corner/PVT coverage matrix completeness** ✅E · **cross view pin consistency audit (whole lib)** 🟡E · char quality QA (SPICE vs model error %, grid adequacy, non convergence list) 🟡E · **don't-use/dont-touch/physical-only list correctness** ✅E.

### 6B. EDA tool qualification (does the lib actually work in a flow)
test synthesis (yosys/ABC maps everything, full coverage) ✅E · **test P&R RTL2GDS on a benchmark, clean DRC/LVS/antenna, routable** ✅E (the real qualification) · STA closure sanity ✅E · LEC RTL↔netlist ✅E · gate sim + SDF back annotation ✅E · ATPG fault coverage per cell 🟡P(E if DFT) · CTS (clock subset builds a tree, ICG handled) ✅E · power analysis qual ✅E · UPF/low-power flow qual ❌P.

### 6C. Silicon validation / model to hardware (all ❌P, needs fab)
test-chip/shuttle (Efabless/TinyTapeout) · ring oscillator correlation structures · char vs silicon recalibration · Fmax vs leakage shmoo · reliability/aging silicon. *(Tier P; ESSENTIAL only if the paper claims silicon correlation.)*

### 6D. Regression / version control / CI
full library QA regression on every release ✅E · golden vs new diff (timing/power/area/LEF/GDS deltas) 🟡E · GDS XOR vs prior release ✅E · version/provenance (source, PDK rev, tool hashes pinned) ✅E · release sign off gate (all green → tag) ✅E.

### 6E. Documentation
databook/datasheet (per cell truth/pins/timing/power/footprint) 🟡P · **characterization report** (methodology/corners/grids/accuracy/limits) 🟡E (= the paper) · architecture/methodology spec ✅E · usage notes (don't use list, special cell insertion, errata) ✅P.

### 6F. Final release level sign off (easily forgotten)
**PDK version compatibility lock** + re qual on PDK bump ✅E · **license / IP clearance / export header stamping (IBM OSPO note applies)** ✅E · cross tool stream round trip (Magic↔klayout↔OpenROAD parse clean) ✅E · library level density/CMP-readiness 🟡P · ESD/latchup architecture sign off (tap spacing whole lib) 🟡P · LVF/statistical data gen 🟡P · CCS-noise/SI model gen ❌P · EM/IR rail model per cell 🟡P.

### 6G. Round 2 additions [r2]
- **Characterization assumptions & limitations doc** (explicit record of corners skipped / arcs approximated / ramp vs real slew / lumped C / MC sample size / derates omitted), *this is the paper's methods section*; without it downstream users over trust the lib. ✅E.
- **Compute/runtime budget + sampling policy at library scale** (full PVT×MC×all arcs is enormous; corner subsetting, which cells get full MC vs scaled, absent = the flow never finishes). 🟡E.
- **Known PDK bug regression / waiver list** (sky130 has documented bugs: clkdlybuf poly overlap DRC, antenna diode perimeter LVS, missing diode timing libs, track so autogen doesn't silently inherit/re-introduce them). ✅E.
- **Explicit reliability DEFERRAL with rationale** (Stage 5 EM/aging/ESD/SEU/thermal have no OSS sign off tool + no silicon → mark production only as a *documented scoping decision* so reviewers don't read absence as oversight). E (scoping).

---

## STAGE 7, Flow orchestration & infrastructure [r2], the meta layer that makes it autonomous (absent in v1)
Wraps Stages 0 to 6. Recommended OSS stack: **Snakemake (DAG) on Nix (hermetic env) + volare pinned sky130 + DuckDB results + GitHub Actions CI + golden metric diff.** Difficulty 🟢/🟡/🔴.

**7A. Input/config (human specifies once)**, library arch config (track/site/stack/rails/Vt/Vdd/corner-list/default grids) 🟡 · per cell recipe (function/pins/drive-strengths/netlist-source/targets, with library default inheritance) 🟡 · generation params (sizing seeds/β/folding/tech.py pointer) 🔴 brittle to PDK rev · **target/spec contract = machine readable "definition of done"** (delay@FO4/leakage/area/β-tol/monotonic; vague targets ⇒ loop never terminates) 🟡 · config schema validation (jsonschema/pydantic) + `--dry-run` DAG validate 🟢

**7B. The closed loop (generate→DRC→LVS→extract→char→measure→resize), the core IP**, loop driver/state-machine (accept/resize/abandon) 🔴 hardest to get right · **convergence engine** (in tol + monotonic + DRC/LVS-clean vs give up after N / oscillation detect; needs damping + max iter + reason codes) 🔴 non termination risk · feedback transform (measured miss → param delta; wrong sensitivity sign → divergence; LE priors bound it) 🔴 · stage gating (never char a DRC/LVS-failed layout; never trust un LVS'd extraction) 🟢 but forgetting = valid looking garbage lib

**7C. Sizing/optimization loop (SPICE in loop)**, search (LE seed + secant/Nelder-Mead/evolutionary; SPICE call cost makes naive search intractable → bound the space first) 🔴 · drive strength family gen (scale/fold from X1, re verify each) 🟡 · objective evaluator (`.measure`→EDP/PDP/β/area) 🟡 · search cache (memoize by hash of netlist+corner) 🟢

**7D. Orchestration / parallel / compute**, stage DAG (gen→DRC→LVS→PEX→char→merge→QA→package; content hash not timestamp) 🟡 · **matrix expansion** cell×corner×arc×(slew×load) = 10⁵, 10⁶ sims → fan out, process per job (ngspice single threaded → many procs not threads) 🟡 · resource throttling (concurrent-proc/mem/disk caps; waveform bloat → OOM/disk-full) 🟢 · **retry on non convergence ladder** (relax `.options` → quarantine) 🔴 dominant long tail cost · job failure isolation + resume (`--keep-going`/`--rerun-incomplete`; idempotent/atomic writes) 🟢

**7E. Caching / provenance / robustness**, **input hash fingerprint** (netlist+sizing+PDK rev+model+sweep+tool ver → skip unchanged; incomplete hash = silent stale = classic bug) 🟡 · hermetic env + PDK rev + deterministic seed pins; run manifest (resolved config + versions + git SHA); lockfiles 🟢🟡 (cf. our magic too old bug) · structured logging + reason codes (debugging 10⁵ jobs impossible without) 🟡 · **long tail edge case register** (sanctioned manual-override/waiver, the 95→100% is where autonomy breaks) 🟡 · sanity assertions (monotonic/no-neg-delay/β-band) 🟢

**7F. Data / regression / release**, results DB (DuckDB/Parquet, flat files make reporting/regression impossible) + retention/GC 🟡 · golden metric diff + tolerance bands (too tight=noise fail, too loose=miss regression) 🟡 · CI (fast smoke subset on change + nightly full; QA gate blocks release) 🟡 · **multi corner Liberty structural consistency** (all corner .libs identical structure for STA scaling, asymmetry silently breaks derating) 🔴 · deliverable bundle + semver + manifest + integrity; **RTL2GDS benchmark gate** (harden a small core with the lib in CI = the real qualification) 🟡

> **Where autonomy actually breaks (the HARD core):** convergence logic (7B), SPICE in loop sizing (7C), non convergence long tail (7D retry / 1·0-P6), multi corner Liberty consistency (7F), and scale to-100s-of cells (DB + cache + budget from day one). Everything else is plumbing.

---

## SkyWater conformance reference [sky], the abstract checklist pinned to SkyWater's concrete practice
*(Final check: validated against SkyWater's own sign off decks + how they actually characterized `sky130_fd_sc_hd`.)*

**Two enforcement tiers, conflating them is the classic "did I miss a step?" trap:**
- **Tier 1, cell/block sign off (YOUR job):** the magic+klayout dual DRC deck, antenna ERC, netgen LVS, latchup/tap, 5nm grid, **GDS layer:datatype map compliance**. Foundry rules live in the open_pdks-shipped decks.
- **Tier 2, shuttle integration acceptance (only when you wrap the lib into `user_project_wrapper` and submit to efabless/Caravel):** `mpw_precheck`, XOR vs golden wrapper, OEB, GPIO defines, manifest, makefile, default content, docs, license/SPDX, topcell name, illegal cellname, fixed **2.92×3.52 mm** user area. These are **chip submission** gates, NOT library steps; the **seal-ring/padframe is foundry provided, don't draw it**. Keep them as a Stage 7 integration checklist only.

**Tier 1 gates we under specified (now added above as [r2]/[sky]; restated for conformance):**
- **GDS layer:datatype map compliance**, pins on the pin datatype (e.g. met1 `68/16`), labels on label datatype (`68/5`), drawing on drawing; foreign (layer:dt) pairs are stripped/rejected, and the router/abstract-extractor mis reads cells if pins aren't on the pin purpose. *Verify every shape against the shipped `sky130.layermap` / `gds_layers.csv` (layer numbers solid; reconcile exact pin/label datatypes).*
- **`drc style drc(full)` enforcement**, the `drc(fast)` style silently skips rules → 0 errors on a dirty layout; assert `full` in CI.
- **Verify manually merge rules at abutment**, SkyWater states sub min space **nwell/nsdm/psdm/npc** features are NOT auto flagged and "must be manually merged by drawing," and enclosures don't apply at butting edges/corners → exactly the abutted std cell well/implant-merge failure; add a manual implant/well-merge audit to the self array DRC (3J).
- **`areaid.lowTapDensity` (GDS `81/14`) marker**, latchup DRC needs it drawn around low tap density core; not auto inserted by some flows → inject at the block/tapeout step.
- **Density is a 700µm block gate, not a cell gate**, `check_density.py` rejects <700µm²; per cell density is meaningless → density/fill belongs at Stage 6 test P&R (windows: FOM ~33-57, LI1/MET1-4 35-60, MET5 45-76%; `generate_fill.py`).
- **SPDX headers + collision safe namespaced cell names** (`<lib>__<cell>`) from day one → shuttle ready later.
- Antenna ratios (concrete, no diode): **Poly 50 / LI 75 / Met1-5 400 / licon mcon ~3 / via-via4 ~6**; with diode relaxation formula; runs on an **extracted** netlist (≠ the cvc_rv ERC).

**SkyWater's concrete characterization recipe (match, or consciously deviate):**
- **Process corners: tt/ss/ff ONLY** for digital (sf/fs are NOT used, our 5 is conservative extra). nmos first naming (fs = fastN/slowP).
- **Temps: −40 / 25 / 100 °C** (hd). Nominal sign off center = **`tt_025C_1v80`**.
- **Voltages: hd ≈10 points, 1.28 to 1.95V → 16 named P/T/V corners** (e.g. `ss_n40C_1v60`, `ff_n40C_1v95`, `tt_025C_1v80`). hs/ms/ls 1.60 to 1.95; lp 1.55 to 2.0; hvl 1.65 to 5.5.
- **NLDM 7×7 geometric grid:** index_1 input slew 0.01→1.5 ns `[0.01, 0.023, 0.053, 0.122, 0.282, 0.651, 1.5]`; index_2 output load 0.0005→0.1996 pF.
- **Trip points:** delay @ **50%**; slew **20 to 80%**; `slew_derate=1.0`; units **ns/V/pF**.
- **Models: NLDM only** (NO CCS *timing*, don't build it); **ccsnoise** receiver views on ~2 extreme corners (`ff_n40C_1v95`, `ss_n40C_1v60`); **pwrlkg** only in `ms` (hd embeds leakage in the main lib = our style).
- **No Monte Carlo** in their char (corners suffice at 1.8V, but see 0.9V note below).
- **Views per cell:** GDS + CDL(LVS) + .spice(sim) + LEF/.magic.lef(abstract) + .v(behavioral/functional/blackbox/specify) + lib.json. **Physical only cells shipped:** `fill_1/2/4/8`, `decap_3..12`, `conb_1`(tie), `diode_2/8`(antenna), `tapvpwrvgnd_1`(tap), endcap.
- **Build:** per corner `<cell>__<corner>.lib.json` fragments + `__common.lib.json`, merged by `skywater_pdk/liberty.py`.
- **Known bad cells they ship (waiver list seed):** `dfxtp` behavioral D unconnected (#329); `buf_16` & `clkdlybuf4s15_1` poly contact DRC (#293/#261); `dlclkp_1` lib error (#183); non hd diode cells lack timing libs (#358).
- **Unreproducible by design:** their actual SPICE characterizer *engine* was never published → match the **observable deliverable** (corners/grid/trips/views), not the engine.

**Our inverter vs SkyWater hd, gap table:**
| Dimension | SkyWater hd | Us | Verdict |
|---|---|---|---|
| Process corners | tt/ss/ff (3) | 5 | OK (exceed) |
| Temps | −40/25/100 (3) | 2 | **add 1** |
| Voltages | ~10 (1.28 to 1.95) | 1 (0.9) | **conscious deviation; add multi V grid for STA** |
| P/T/V corners | 16 | ~10 | **under** |
| NLDM grid + trips | 7×7, 50%/20-80% | ✓ | **verify ours matches exactly** |
| dynamic internal_power | gridded | ? | **confirm gridded LUT, not scalar** |
| leakage | yes | yes | OK |
| ccsnoise views | 2 to 4 corners | none | **add ≥2 extreme corners (or declare lp style none)** |
| pwrlkg | ms only | none | OK (hd style) |
| CCS timing | none | n/a | OK, don't build |
| Monte Carlo | none | planned | **MANDATORY at 0.9V** |
| golden cal | n/a | planned | **do at 1.80V, their grid** |
| physical cells | yes | ? | **confirm present** |
| non-.lib views (gds/cdl/lef/.v) | yes | ? | **confirm present** |

**★ The 0.9V deviation (most important conformance finding):** 0.9V is **~0.65V below SkyWater's lowest characterized point (1.28V)**. Consequences:
1. **No golden reference exists at 0.9V** → validate the *flow* via golden cal (1L1) at **1.80V** with their grid/trips, then trust the *same flow* extrapolated down.
2. **Monte Carlo mismatch moves from optional → MANDATORY**, near threshold, σVt dominates and corner only char badly under predicts spread (use `sky130_fd_pr` `MC_MM_SWITCH`/`AGAUSS`). This is *why* SkyWater could skip MC (comfortable at 1.8V) and we cannot.
3. **SNM is the binding constraint, not timing**, weight it.
4. **Per cell Vmin must be FOUND, not assumed**, AOI/OAI stacks and sequentials have higher Vmin than inv/nand; 0.9V may not work for all cells.
5. **Document the deviation in lib naming/README**, our `0v72/0v81/0v90/0v99` grid is our own, justified by the near threshold target, and is NOT comparable to SkyWater's silicon qualified data. Adopt their token scheme (`tt_025C_0v90`) for tool compatibility and to make the deviation explicit.

---

## Our status & the prioritized gap list (WP=0.76 lvt inverter)
**Done (✔):** sizing, functional, 5 process × 2 temp corners, static noise-margin/VTC across 10 PVT points, leakage default. ≈ all in the electrical/characterization family (done early because they drove sizing).

**Pre layout gaps to close before drawing (highest value first):**
1. **Monte Carlo, local mismatch σVt (1C2)** then global+combined, *the* methodological hole; everything statistical depends on it, and our fs corner NM_H is already marginal (32mV).
2. **Vmin sweep + near threshold (1B1-3)**, the headline number for a low voltage cell; we never swept Vdd.
3. **Multi Vdd grid (1A6)** + **temperature inversion / ZTC location (1A5)**, confirm whether cold, not hot, is the slow delay binder at 0.9V.
4. **Per state leakage tables (1G6)**, **min pulse width (1E5)**, **golden SPICE correlation (1J6)**.
5. **[r2] Cheapest, highest confidence validations, do these FIRST:** input side pre flight audit (1·0, esp. P3 corner-file/MC-switch + P4 W/L bin center), **golden library re char of sky130_fd_sc_hd__inv_1 vs the released .lib (1L1)**, and upgrade the testbench to a **reference inverter driver (1K2)** with an **FO4-anchored grid (1K1)**. These catch systematic setup errors our internal QA can't, and validate the whole harness before we trust any of our own numbers.

**Everything in Stages 3-6 is post draw** and starts the moment the generator emits GDS. Research grade credible bar = DRC + LVS + extracted timing + noise (+ MC + Vmin); the EM/aging/ESD/silicon suite is production only for sky130 and should be explicitly scoped out, not silently skipped.
