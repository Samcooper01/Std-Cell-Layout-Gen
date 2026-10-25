# Modifying the sky130 Standard Cell Library to Improve PPA, Research Findings

*Deep research report, 2026-06-23. 19 sources fetched, 89 claims extracted, 25 adversarially verified (21 confirmed, 4 refuted). For: Sam's first foundational PD paper (project #1, std cell choices on sky130).*

---

## Headline

For a solo engineer on open tools, the most tractable **and** publishable lever is
**re characterization + targeted re sizing / Vt tuning of ~10 to 20 high leverage cells**, 
NOT building a whole library or trying to beat the foundry cells head on.

**The key opportunity:** almost every *quantitative* result in the literature is on a
**non-sky130 node**. Sky130-specific numbers for these techniques largely don't exist yet.
That gap is the contribution.

---

## The levers, by PPA axis (all verified 3-0 unless noted)

| Technique | Axis | Magnitude | Solo feasibility | Sky130-grounded? |
|---|---|---|---|---|
| Re size cells for near threshold / low Vdd (~0.6V) | Power/energy ↓ | **23% avg, 31% best** energy vs nominal sized | High | ❌ non-sky130, **gap to fill** |
| Vt swap (library level multi Vt) | Leakage ↓ | **hdll = 5 to 10× lower leakage** than hd (0.08 vs 0.86 nA/kGate) at ~25% less density | High (sky130 ships it as proof) | ✅ sky130 fact |
| Cell height / track count tuning | Density ↔ perf | 14 track ~20% faster but ~62% more leakage vs 10 track | Med High | ✅ heights documented |
| Transistor stacking / MTCMOS stack forcing | Standby leakage ↓ | standby leakage → ~9 to 12% of dual Vt baseline, at ~115 to 133% area | Medium (needs sleep signal infra absent from hd) | ❌ non-sky130 |
| Re characterization quality (slew/load grid, corners) | Accuracy / all | enabling lever; finer grids = better models | High (pure tooling) | ✅ CharLib supports it |

### sky130 multi Vt detail (important nuance)
- Multi Vt is **library level, not per cell**.
- 1.8V devices: **standard**, **low Vt** (NMOS+PMOS), **high Vt (PMOS only, NO high Vt NMOS)**.
- `hd` = standard devices; `hdll` = high Vt PMOS; `ms` = low Vt NMOS; `hs` = low Vt both; `ls/lp` = high Vt PMOS.
- Measured TT Vt: NMOS 0.434V (lvt) vs 0.538V (std); PMOS −0.651V (lvt) vs −1.050V (std).
- Per cell Vt mixing *inside* hd requires a **custom redraw**, not a stock option (this is a paper).

### Cell heights (the density/perf axis as discrete libraries)
- hd / hdll: 0.46 × 2.72 µm, **9 met1 tracks**
- hs / ms / ls / lp: 0.48 × 3.33 µm, **~11 tracks**
- hvl: 0.48 × 4.07 µm, **14 tracks**

---

## ML angle (the career through line)

Characterization is the bottleneck of every redraw iteration; ML is the demonstrated fix, 
but **not yet on sky130** (that's the open question / a paper of its own):
- **GNN surrogate**: delay/power/pin-cap **~100× faster than SPICE**, MAPE ≤ 0.95%, 512 unseen corners, on 45nm. (arXiv 2312.12784)
- **GPR + active learning**: builds CCS models with **~27% of full grid SPICE sims**, on TSMC 22nm. (arXiv 2505.10799)
- **Open question:** retarget either to sky130 device models, accuracy? training data cost?

---

## Honest flags, 4 claims KILLED in verification (do NOT repeat)

1. ❌ "Finer grained intermediate inverter drive strengths cut gate count up to 6%", refuted (1-2).
2. ❌ Community **`sky130_as_sc_hs`** library is **NOT complete**; claim it **beats stock hd** refuted (0-3).
   Use only as prior art / cautionary example, never as a baseline beater.
3. ❌ "P/N-ratio under full diffusion as *the* core technique", downgraded (1-2).
4. (MTCMOS adds area + needs sleep signal infra absent from stock hd, real integration cost.)

**Dominant caveat:** node transferability. The strong numbers (23/31% near threshold; cell height;
MTCMOS; GNN 100×; GPR 27%) are all on non-sky130 tech. They establish *mechanisms and rough
magnitudes*, not sky130 results. Only the PDK facts (multi Vt options, hdll 5-10×, heights) and the
tooling (CharLib, IEEE sky130 flow) are directly sky130-grounded.

---

## Top 3 publishable directions (ranked)

1. **⭐ Near threshold re sizing of ~10 to 20 sky130 hd cells** *(the recommendation)*
   Strongest mechanism (23 to 31% energy), never measured on sky130. Redraw + recharacterize a
   high leverage cell set optimized for ~0.6V; report the sky130-specific delta. Bounded + novel.

2. **ML characterization surrogate retargeted to sky130**
   High ML signal (career angle), self contained, and it's the *engine* that makes #1 fast.
   Could be paper #1's companion or its tooling.

3. **Custom per cell Vt mix inside hd**
   hd uses standard devices; hdll proves the high Vt PMOS win. Build a *selectively* Vt mixed
   variant, quantify the leakage/speed Pareto. Novel because stock sky130 multi Vt is library level.

---

## The clean experiment for direction #1 (iso frequency / iso area)

1. **Pick the cell set by leverage**: inverters, NAND2/NOR2, AOI/OAI, a flop, cells that dominate real netlists.
2. **Two libraries, identical except your cells**: stock sky130_fd_sc_hd vs your variant.
   Re characterize **both** with the **same CharLib config** (same slew/load grid, same corners),
   so the comparison isn't contaminated by characterization differences.
3. **Real switching activity**: synthesize a benchmark (OpenROAD example / small RISC V core) →
   run a representative workload → capture **VCD/SAIF** → drive power analysis with real activity.
   (This step separates a real result from a meaningless one.)
4. **Iso frequency**: constrain both flows to the **same target clock**; compare energy/op + leakage
   at equal Fmax. (Or iso energy → compare Fmax.) Never compare unconstrained.
5. **Iso area / report area honestly**: hold area ~equal or report the delta explicitly so a power
   win isn't a hidden area trade.
6. **Isolate cell effect from P&R noise**: same floorplan, seeds, constraints across both runs; report variance.

**Contribution sentence:** *"We quantify, for the first time on sky130, the energy/leakage benefit of
near threshold re sizing on N high usage cells under iso frequency comparison with realistic switching activity."*

---

## Key tools & references

- **CharLib**, github.com/stineje/CharLib (ngspice/Xyce, NLDM, configurable grids); IEEE MWSCAS 2024 (doc 10658687)
- **IEEE sky130 characterization flow**, Magic → RC extracted SPICE → .lib/.lef (IEEE doc 10534506)
- **Near threshold sizing**, ResearchGate 278711536; IEEE 9994729 (cell height + P/N)
- **MTCMOS stack forcing**, arXiv 0710.4762
- **ML surrogates**, GNN: arXiv 2312.12784; GPR + active learning: arXiv 2505.10799
- **SkyWater PDK device/library facts**, skywater pdk.readthedocs.io (foundry provided libraries; device details)
- **Prior art / cautionary**, github.com/AvalonSemiconductors/sky130_as_sc_hs (incomplete; do not cite as a win)

---

## Open questions to resolve next (from the research)

1. Actual measured sky130_fd_sc_hd PPA delta from re-sizing/Vt-swapping 10 to 20 cells for near-threshold/low-leakage, all current numbers are other nodes.
2. *Which* 10 to 20 cells give the highest leverage per redraw effort; are there genuinely missing complex cells in hd worth adding?
3. Can GNN/GPR surrogates retarget to sky130 with acceptable accuracy, and at what training data cost?
4. What realistic switching activity model best isolates the cell level improvement from synthesis/P&R noise in OpenROAD/OpenSTA?
