# The Place and Route Engine (lclayout)

The generator does not draw cells itself. It drives **lclayout** (LibreCell), a place and route
(PnR) engine that lays out **one cell at a time**: given a transistor netlist and the tech file,
it produces a manufacturable layout and checks it. This doc walks the whole pipeline with
pointers into the actual code under `lclayout/src/lclayout/`.

We adapted lclayout for sky130; the tech file (`docs/TECH_FILE.md`) and a few source patches
(`patches/`) are ours, but the engine and its stages below are lclayout's.

## Inputs and outputs

| | What | Where it comes from |
|---|---|---|
| **In** | SPICE netlist of one cell (its transistors and pin nets) | extracted per cell from `cells/sky130_hd_all_cells.sp` by `src/cellgen/run_cell.sh`, passed as `--netlist` |
| **In** | tech file (process rules, architecture, recipe hooks) | `tech/sky130_hd_tech.py`, passed as `--tech` |
| **In** | placer and router choice, output dir, cell name | CLI flags `--placer`, `--signal-router`, `--cell`, `--output-dir` |
| **In** | per cell recipe knobs | `RECIPE_*` environment variables, read by the tech file and the patched sources |
| **In** (optional) | a saved transistor placement | `--placement-file`, loaded or written by `create_cell_layout` |
| **Out** | the layout | **GDSII**, plus **LEF**, **Magic .mag**, and **OASIS**, written by `tech.output_writers` |
| **Out** | pass or fail | an **LVS** result, logged as `LVS result: SUCCESS` or `FAILED`; the harness treats SUCCESS as "cell closed" |

## Entry point

`run_cell.sh` calls `lclayout --tech ... --netlist ... --cell ... --placer ... --signal-router ...`,
which runs `main()` (`standalone.py:847`). `main()` builds the chosen placer and router from two
small registries and then calls `create_cell_layout()` (`standalone.py:771`), the function that
runs every stage below.

### The placer registry (`standalone.py:857`)
The `--placer` flag picks one. Every placer takes the transistor list and returns a lazy
sequence of placement candidates (transistor orderings) that the place and route loop tries in
turn.

- **`flat` -> `EulerPlacer`** (`place/euler_placer.py:676`): the base engine. It places every
  transistor in one pass on a 2 by n grid (PMOS on the top stack, NMOS on the bottom) and orders
  them along **Euler tours** through the diffusion graph, so adjacent transistors share diffusion.
  Most thorough, but it enumerates Euler tours and does not scale: the tour count is capped
  (`euler_placer.py:35`), so large cells overflow the budget.
- **`hierarchical` -> `HierarchicalPlacer`** (`place/euler_placer.py:274`): divide and conquer. It
  splits the circuit into subcircuits (nmos only and pmos only groups), places each one
  independently, then combines them. Scales to bigger cells than flat Euler at some cost in
  quality.
- **`meta` -> `MetaTransistorPlacer`** (`place/meta_placer.py:19`): a **dispatcher, not an
  algorithm**. It estimates the cell's placement complexity and picks a suited engine, the
  accurate but slow one for small cells and a faster lower quality one for big cells. Its own
  docstring calls it "kind of a stupid fix because there's no good enough placement engine",
  which is exactly the gap `docs/PROJECT_STATUS.md` targets.
- **`smt` -> `SMTPlacer`** (`place/smt_placer.py:18`): formulates placement as an SMT problem and
  solves it with **Z3**, under constraints such as facing gates must share a net and minimize the
  net bounding boxes (`smt_placer.py:19`). Can find optimal placements but is slow, so it is used
  rarely.

### The router registry (`standalone.py:864`)
The `--signal-router` flag picks one. These are **detail routers**: each routes **one net** at a
time. The PathFinder loop (below) calls the chosen one over and over across all nets while it
negotiates congestion.

- **`dijkstra` -> `DijkstraRouter`** (`graphrouter/signal_router.py:89`): connects a net's
  terminals with a spanning tree built from **Dijkstra shortest paths**. Fast, and the default,
  but the registry notes it is "not stable" (a small change can shift the result).
- **`steiner` -> `ApproxSteinerTreeRouter`** (`graphrouter/signal_router.py:60`): builds an
  **approximate Steiner tree** over the net's terminals (it may add intermediate branch points to
  shorten the total wire). Slower, but gives lower wirelength routes, which the registry calls
  "best results".
- (also present but not in the registry: `AStarRouter`, an A star shortest path router,
  `graphrouter/signal_router.py:37`.)

## The pipeline (in order)

`create_cell_layout` (`standalone.py:771`) runs these:

**0. Load and check the tech file.** `_00_00_check_tech` (`standalone.py:156`),
`_00_01_prepare_tech` (`standalone.py:161`) validate the rules and precompute derived values.

**1. Load the netlist.** `_01_load_netlist` (`standalone.py:165`) parses the cell's SPICE subckt
into an abstract set of transistors and the pin nets (via `lccommon/net_util.py`
`load_transistor_netlist`). Output: the transistor list the placer will order.

**2. Placement.** `_03_1_init_placer` (`standalone.py:225`) calls `placer.place(transistors)`,
which returns a **lazy sequence of placement candidates** (different transistor orderings). The
placer is Euler path based (`place/euler_placer.py`, wrapped by `place/meta_placer.py` for the
`meta` option): it orders the devices in the row so that neighbors **share source and drain
diffusion**, which minimizes diffusion breaks and cell width. This stage is the current quality
blocker, see `docs/PROJECT_STATUS.md`.

**3. Place and route loop** (`standalone.py:810`, up to `place_max_candidates` tries). For each
placement candidate:
- **3a. Next placement** `_03_2_next_placement` (`standalone.py:231`): pull the next ordering.
- **3b. Set up the canvas** `_02_setup_layout` (`standalone.py:206`).
- **3c. Draw transistors** `_04_draw_transistors` (`standalone.py:246`): draw diffusion, poly
  gates, and contacts for each device at its placed column.
- **3d. Draw the cell template** `_05_draw_cell_template` (`standalone.py:260`): draw the wells
  (nwell and pwell), the VPWR and VGND power rails, and the diffusion contact access. **The net
  aware drain lift runs here** (`router.py:436` to `:505`), the fix that keeps parallel drain
  contacts off the rail (see the `RECIPE_LIFT_*` knobs in `docs/TECH_FILE.md`).
- **3e. Route** `_06_route` (`standalone.py:317`): build the routing grid graph
  (`router.py` `create_routing_graph_base_v2`, `router.py:380`, over li1 and met1, plus met2 and
  met3 when `RECIPE_NUM_LAYERS` asks) and route every signal net with `DefaultRouter.route`
  (`router.py:207`). If routing succeeds it logs `Routing successful` and breaks the loop; if not,
  it tries the next placement candidate.

**4. Commit routes.** `_08_draw_routes` (`standalone.py:355`) turns the routed paths into shapes.

**5. Well taps.** `_08_2_insert_well_taps` (`standalone.py:364`) and `_08_03_connect_well_taps`
(`standalone.py:841`) find and connect body taps. sky130 hd logic cells are tapless, so this is
mostly inert here (`enable_well_taps = False`); taps live in the separate `tap` cells.

**6. Post process (DRC clean up).** `_09_post_process` (`standalone.py:842`):
`fill_all_notches` (`standalone.py:610`) removes notch violations, `fix_min_area`
(`standalone.py:615`, defined `:1074`) grows shapes that are below the minimum area, and the pin
shapes are drawn. Min area and notch fixing are done by the **Z3 SMT solver** in
`drc_cleaner/` (`drc_cleaner.py`, `drc_theorem_proofs.py`), which legalizes shapes within the
rules. `RECIPE_SKIP_MIN_AREA` skips the min area part.

**7. LVS** (`standalone.py:1015` to `:1050`, using `lvs/lvs.py`): the drawn layout is extracted
into a netlist and compared, device by device and net by net, against the input netlist. It logs
`LVS result: SUCCESS` or `FAILED`. This is the gate the harness reads.

**8. Write outputs** (`standalone.py:1057`): each writer in `tech.output_writers` emits its file,
`writer/gds_writer.py`, `writer/lef_writer.py`, `writer/magic_writer.py`, `writer/oasis_writer.py`.

## The two algorithms that matter

**Placement (Euler path).** `place/euler_placer.py`, `place/eulertours.py`. The transistor row is
modeled as a graph and ordered along an **Euler path** so adjacent transistors abut on shared
diffusion. That minimizes width, but it optimizes width, not routability, which is why hard cells
route poorly (the placement thesis in `docs/PROJECT_STATUS.md`).

**Routing (negotiated congestion).** `graphrouter/pathfinder.py` runs the **PathFinder**
algorithm (`pathfinder.py:31`, up to 1000 iterations): route every net greedily, detect grid
nodes used by more than one net, raise those nodes' cost by a usage history, then rip up and
reroute. It repeats until no node is illegally shared. Each pass is a `Routing iteration N` log
line. The per net detail router is Dijkstra shortest path or an approximate Steiner tree
(`graphrouter/signal_router.py`), running on the grid graph from `routing_graph.py`. An SMT based
router (`graphrouter/smt_router.py`) and SMT placer (`place/smt_placer.py`) also exist as options.

## Where the recipe knobs plug in
The `PLACER` and `ROUTER` flags select the engines (registries above). The `RECIPE_*` variables
are read by the tech file and the patched sources: `RECIPE_NUM_LAYERS` adds layers to the routing
grid, `RECIPE_MCON_WEIGHT` and the weight tables bias the router, `RECIPE_LIFT_*` control the
drain lift in stage 3d, `RECIPE_HEIGHT_MULT` changes the canvas height, and `RECIPE_SKIP_MIN_AREA`
skips the stage 6 min area pass. Full list in `docs/TECH_FILE.md`.

## Module map

| Path (under `lclayout/src/lclayout/`) | Role |
|---|---|
| `standalone.py` | the orchestrator: `main()` and `create_cell_layout()`, runs every stage |
| `../lccommon/net_util.py` | parse the SPICE netlist into transistors and nets |
| `place/euler_placer.py`, `meta_placer.py`, `smt_placer.py`, `eulertours.py`, `partition.py` | placement engines |
| `router.py` | the `DefaultRouter`: builds the routing graph, runs the drain lift, calls the graph router |
| `routing_graph.py` | build the grid graph the router runs on |
| `graphrouter/pathfinder.py` | negotiated congestion loop (rip up and reroute) |
| `graphrouter/signal_router.py`, `hv_router.py`, `smt_router.py`, `min_area_router.py`, `multi_via_router.py` | per net routers and specialized routers |
| `layout/transistor.py`, `cell_template.py`, `welltap.py`, `notch_removal.py`, `layers.py`, `grid.py` | drawing the device and cell geometry |
| `drc_cleaner/` | Z3 SMT DRC clean up (min area, notches) |
| `lvs/lvs.py` | layout versus schematic check |
| `writer/gds_writer.py`, `lef_writer.py`, `magic_writer.py`, `oasis_writer.py` | emit the output files |
| `tech_util.py`, `data_types.py` | tech helpers and shared types |

## Where to look next
- The tech file that configures all of this: `docs/TECH_FILE.md`.
- Why each of our patches and knobs exists: `docs/LAB_NOTEBOOK.md`.
- The current placement blocker and the plan: `docs/PROJECT_STATUS.md`.
