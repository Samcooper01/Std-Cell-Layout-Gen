# sky130-cellgen

**A recipe driven generator that turns transistor netlists into DRC/LVS-clean sky130
standard cell layouts, automatically, and re runnable when the technology changes.**

Given a cell's SPICE netlist, it places and routes a manufacturable layout with no human
drawing, using the [lclayout](https://codeberg.org/tok/librecell) (LibreCell) engine driven by
a small per cell **recipe** of algorithm knobs. Process rules and library architecture stay
fixed and shared, so every generated cell is co legal, change a tech parameter, re run, get a
new co legal library. That last property is the north star: **automated Design Technology
Co Optimization (DTCO)** on an open PDK (Process Design Kit).

Status: **319 / 437 `sky130_fd_sc_hd` cells build clean (~73%)**. See `results/`.

---

## Quickstart

```bash
# 1. one-time setup (see requirements.txt)
python3 -m venv ~/eda-env
~/eda-env/bin/pip install -r requirements.txt
git clone https://codeberg.org/tok/librecell.git lclayout   # the P&R engine (gitignored)
(cd lclayout && git apply ../patches/*.patch)                # our tracked fixes
~/eda-env/bin/pip install -e ./lclayout
export PATH="$HOME/eda-env/bin:$PATH"

# 2. build ONE cell and verify it's DRC/LVS-clean
tests/build_cell.sh inv_1

# 3. build it AND render the layout to a PNG
tests/build_cell.sh inv_1 --render        # -> results/renders/inv_1.png

# 4. run the golden-cell regression (what CI runs)
tests/run_goldens.sh
```

`PYTHONHASHSEED=42` is set inside the scripts, lclayout has residual nondeterminism and this
pins it for reproducible layouts.

## Repository layout

| Path | What it is |
|---|---|
| `cells/sky130_hd_all_cells.sp` | The 437 cell netlist corpus (input). |
| `tech/sky130_hd_tech.py` | **The artifact**, the sky130 tech file: process DRC · library architecture · per cell recipe knobs (the 3 layer split). |
| `recipes/recipes` | Per cell recipe lines (the only thing that varies per cell). |
| `recipes/cell_categories.tsv` | Cell → functional category map (16 categories). |
| `src/cellgen/` | The generator: `run_cell.sh` (build one cell), `render.py` (view a layout), plus the research harness (`ceiling.sh`, `solve_*.sh`, `classify_cells.sh`, …). |
| `tests/` | `build_cell.sh`, `run_goldens.sh`, `goldens.txt`, the regression gate. |
| `docs/` | All documentation, indexed in [`docs/README.md`](docs/README.md): the tech file explained (`TECH_FILE.md`), cell taxonomy, visual schematics, flow spec, status, and logs. |
| `results/` | Curated coverage tables + layout renders (the paper's evidence). |
| `patches/` | Our tracked diffs against the lclayout clone. |
| `lclayout/` | The cloned P&R engine (gitignored, external, install per Quickstart). |
| `.work/` | Generated output + run logs (gitignored). |

## How it works

Every cell flows through the same pipeline:

```
SPICE netlist ─► tech + recipe ─► lclayout place & route (Z3 SMT) ─► LVS ─► GDS + LEF
```

The **recipe** is the idea. `tech/sky130_hd_tech.py` is split into three layers:
1. **Process rules / DRC**, foundry fixed, never varies.
2. **Library architecture**, row height, site, tracks, set once, shared by all cells.
3. **Per cell recipe**, the *only* per cell variation (placer, router, metal layers, lift,
   height multiplier, …), read from `recipes/recipes` and overridable by environment variables.

Because only layer 3 varies, every cell abuts and stays co legal, the precondition for
regenerating a whole library after a technology change.

## Where it stands & what's next

The un converged cells (chiefly the 45 flip flops) are **placement bound, not area bound**:
routing fails to converge because the placer produces un routable transistor orderings, and no
amount of extra area or metal fixes it. The next unlock is a **routability aware placement
pass**, see `docs/PROJECT_STATUS.md` and `docs/CONVERGENCE_CEILING_LOG.md`.

## License & citation

**Not yet licensed for distribution**, pending IBM OSPO / IP review (see `LICENSE`). Do not
redistribute until a license is added. Built on lclayout/LibreCell (CERN OHL S) and the
SkyWater sky130 PDK (Apache 2.0).
