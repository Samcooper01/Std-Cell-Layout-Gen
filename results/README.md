# Results

Curated, committed evidence for the generator (the paper draws on this). Raw per run
output stays in the gitignored `.work/`; only distilled tables and renders land here.

## Coverage, sky130_fd_sc_hd (437 cells)

**319 / 437 (~73%) build DRC + LVS clean** at their committed recipe (git `fbdeebb`).
The gap is dominated by the sequential family.

| Family | Cells | Notes |
|---|--:|---|
| Combinational (inv/buf/gates/AOI/OAI/xor/mux/adder/tristate) | 292 | most clean; high drive AOI/OAI + adders are the hard combinational cases |
| Flip flops | 45 | **dominate the un converged set, placement bound** |
| Latches | 23 | partial |
| Clock & delay | 14 | partial |
| Fill / physical | 16 | need dedicated templates, not routing |
| Low power / level shift / isolation | 34 | multi voltage domain; need isolated well template |

See `docs/CELL_TAXONOMY.md` for the full per category cell list.

## Key finding (drives the roadmap)

From the max effort convergence run (`docs/CONVERGENCE_CEILING_LOG.md`): the un converged
cells are **placement bound, not area bound**. Placement is fast (~19 s avg) but hands the
router an un routable transistor ordering, so routing grinds ~21 iterations and quits in
**53% of hard attempts**, and no amount of extra area/metal rescues it. The next unlock is a
**routability aware placement pass**, not more knobs.

## `renders/`
PNG layout renders written by `src/cellgen/render.py` (gitignored; regenerate on demand).
