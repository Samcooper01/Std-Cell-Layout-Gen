# status/

A live scoreboard of the whole library: does every cell close on the current place and
route flow, how long it takes, and the artifacts to prove it.

- **[STATUS.md](STATUS.md)** is the table. All 437 `sky130_fd_sc_hd` cells, grouped into the
  16 functional categories, one row each. Columns:
  - **Status**: closed (builds DRC and LVS clean on its committed recipe) or open.
  - **Time (s)**: wall clock seconds for that cell's run.
  - **Log**: the verbose lclayout run log (every stage, every routing iteration, the LVS result).
  - **Layout**: a PNG render of the finished layout, viewable in the browser.
  - **Files**: the raw output files, GDS and LEF, for that cell.
- **`logs/<cell>.log`**: per cell verbose run logs.
- **`renders/<cell>.png`**: per cell layout renders.
- **`outputs/<cell>/`**: per cell GDS and LEF.
- **`results.tsv`**: machine readable `cell<TAB>closed|open<TAB>seconds` (the table is generated from this).

## Regenerate

```bash
# run the whole library and populate everything above
PAR=6 TIMEOUT=900 src/cellgen/run_status.sh

# or just refresh the table from an existing results.tsv
src/cellgen/gen_status.sh
```

Open cells only get a log (no render or outputs, since there is no clean layout to show).
