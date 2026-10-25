# The Tech File: `tech/sky130_hd_tech.py`

This is **the artifact of the whole project**. It is the file lclayout reads to know how to
turn a transistor netlist into a legal sky130 layout. Everything else (the harness, the
recipes, the runs) exists to develop and exercise this one file.

It is written in three conceptual layers, and the split is the core idea of the generator:

| Layer | What it holds | How often it changes |
|---|---|---|
| **1. Process rules / DRC** | layer map, spacings, widths, vias, enclosures, transistor rules, routing costs | **never** (foundry defined, same for every cell) |
| **2. Library architecture** | row height, gate pitch, routing grid, power rails, pins | **once per library** (shared by all cells) |
| **3. Per cell recipe** | placer, router, routing costs, escalation knobs | **per cell** (safe to vary) |

The rule that makes this work: **only layer 3 may vary per cell.** Because layers 1 and 2 are
identical for every cell, all the generated cells abut in rows and present their pins on the
same tracks, so a block can be assembled from them. That property is called being **co legal**,
and it is the precondition for the north star: change one layer 2 number, regenerate the whole
library, and every cell is still co legal (automated Design Technology Co Optimization).

How a per cell recipe reaches the tech file: `src/cellgen/run_cell.sh` reads the cell's line
from `recipes/recipes`, exports the recipe as environment variables and passes the placer and
router as command line flags, then runs lclayout with this tech file. The tech file reads those
environment variables, so a recipe overrides only the layer 3 knobs and never touches layers 1
or 2.

```
recipes/recipes  ->  run_cell.sh  ->  env vars + CLI flags  ->  lclayout(tech = sky130_hd_tech.py)
```

DRC below means Design Rule Check: the geometric rules the foundry guarantees will print and
work. LVS means Layout Versus Schematic: the check that the drawn layout matches the netlist.

---

## Layer 1: Process rules / DRC (foundry defined, never varies)

These encode the sky130 design rules and electrical data. They are identical for every cell and
must never be a per cell knob, or the output would not be manufacturable.

### Units and layer identity

| Item | Value | Meaning |
|---|---|---|
| `db_unit` | 1e-9 (1 nm) | the smallest length the layout can express; every coordinate is an integer number of these |
| `nm`, `um` | 1, 1000 | unit helpers, so `690*nm` reads naturally |
| `grid` | 5 | the base grid step that shapes snap to |
| `transistor_channel_width_sizing` | 1 | a scale factor applied to transistor widths (1 = exactly as in the netlist) |
| **GDS layer map** | `diffusion=(65,20)`, `nwell=(64,20)`, `poly=(66,20)`, `li1=(67,20)`, `mcon=(67,44)`, `metal1=(68,20)`, `via1=(68,44)`, `metal2=(69,20)`, `via2=(69,44)`, `metal3=(70,20)`, `pplus/nplus=(65,44)`, `abutment_box=(235,4)`, plus a `,5` label and `,16` pin datatype for each drawn layer | **GDSII (Graphic Design System II)** is the standard file format for chip layout, the file you hand to the foundry. Inside it, every polygon is tagged with a **layer number and a datatype number** (a two number pair). A **GDS layer map** is the table that says which pair each physical mask layer uses, so a shape tagged `(65,20)` is read as diffusion, `(66,20)` as poly, `(68,20)` as metal1, and so on. These pairs are fixed by the foundry (SkyWater for sky130). The **GDS writer** is the stage of lclayout that takes the finished layout and writes out the GDSII file, stamping every shape with the correct pair from this map, so the foundry reads each shape as the layer it is meant to be |
| `output_map`, `output_map_magic` | dictionaries | remap lclayout's internal layer names onto the sky130 GDS numbers above (and onto Magic layer names for the Magic view) |
| `routing_layers` | li1 and met1 route; diffusion is contact only | which layers the router may lay wire on. Diffusion is allowed for shapes but not routing, so contacts still get their required surround |
| `connectable_layers` | `{nwell, pwell, poly}` | layers the tool may freely merge or extend to fix a spacing or notch problem, because doing so does not change the circuit |

### Geometry rules (DRC)

| Item | Example value | Meaning |
|---|---|---|
| `min_spacing` | nwell to nwell 1270 nm, via 190 nm, via2/via3 260 nm | the minimum gap between two shapes on the given layers, so they do not short or blur together when printed |
| `minimum_width` | around 130 to 140 nm per layer | the narrowest a shape on a layer may be; anything thinner will not print reliably |
| `minimum_notch` | 130 nm for metals, 650 nm for wells | the smallest inward notch (concave gap) a shape may have; sharp notches are hard to print |
| `minimum_enclosure` | via and tap and well enclosures | how far an outer layer must extend past an inner one, for example metal surrounding a via so the two reliably connect |
| `min_area` | per layer, wells 5x130 nm scale | the smallest total area a shape may have; tiny islands do not print (this step alone can be skipped per cell, see `RECIPE_SKIP_MIN_AREA`) |
| `via_size` | per via and contact type | the fixed size of each contact or via cut |
| `wire_width`, `wire_width_horizontal` | per layer | the default width the router draws a wire at on each layer |
| the auto derive block (end of file) | computed | grows any contact spacing that is smaller than the diffusion spacing plus two enclosures. Those `Minimum Spacing ... Fixing` lines in the run logs come from here |

### Transistor rules

| Item | Value | Meaning |
|---|---|---|
| `gate_length` (and pmos/nmos) | 150 nm | the transistor channel length, the poly width crossing the diffusion; this is the node dimension |
| `gate_extension` | 130 nm | how far poly must extend past the edge of the diffusion so the gate fully covers the channel |
| `minimum_gate_width_nfet/pfet` | 150 nm | the smallest transistor width allowed |
| `minimum_pin_width` | 130 nm | the smallest a pin shape may be |

### Routing cost model (electrical data, guides the router)

These are not shapes; they are costs that steer the router toward good wires. The base numbers
come from the sky130 layer resistances, so they are process data.

| Item | Value | Meaning |
|---|---|---|
| `weights_horizontal`, `weights_vertical` | li1 1280, met1/met2/met3 125, poly 482000, diffusion 120000+ | the routing cost per unit length on each layer, set to the layer's sheet resistance, so the router prefers low resistance metal over high resistance poly or diffusion |
| `via_weights` | licon 15000, **mcon = `RECIPE_MCON_WEIGHT`**, via 150000 | the cost of each via, so the router avoids needless layer changes. The li1 to met1 (mcon) cost is the one entry a per cell recipe can override (layer 3) |
| `orientation_change_penalty` | 100000 | extra cost every time a wire turns, to discourage zig zag routes |
| `viafactor` | 1 | a global multiplier applied to all via costs |
| `multi_via` | per layer pair | how many via cuts to place in parallel for a connection (redundancy and lower resistance) |

---

## Layer 2: Library architecture (one choice per library, shared by all cells)

These set the shape of the standard cell row. They are the same for every cell so the cells
tile together. Changing one is a deliberate library level decision, not a per cell one.

| Parameter | Value | Meaning |
|---|---|---|
| `unit_cell_width` | **690 nm** | the gate pitch (spacing between gate columns). Chosen so `inv_1` comes out exactly 1.38 um, which is 3 times the 0.46 um hd site. It also sets the x routing grid (`routing_grid_pitch_x = unit_cell_width // 6 = 115 nm`), so 690 keeps the grid aligned to the transistor terminals |
| `unit_cell_height` | **3330 nm** (base) | the row height. Note this is taller than the foundry hd row of 2.72 um, so our cells have more routing tracks than the foundry's. Scaled by `RECIPE_HEIGHT_MULT` (layer 3) for double height cells |
| `routing_grid_pitch_x` | 115 nm | horizontal routing grid (derived from the gate pitch) |
| `routing_grid_pitch_y` | 135 nm | vertical routing grid; the track count is `unit_cell_height / 135` |
| `grid_offset_x / y` | pitch_x / 0 | where the routing grid starts |
| `power_rail_width` | 480 nm | width of the VPWR and VGND rails |
| `power_layer` | `[li1, met1]` | the rails are drawn on **both** li1 and met1 and stitched together with mcon vias along the rail, matching sky130 hd |
| `pin_layer` | met1 | the layer cell input and output pins are exposed on, so the block level router can reach them |
| `transistor_offset_y` | 240 nm | distance from the active area to the cell boundary |
| `enable_well_taps` | False | whether every cell gets its own well tap. False here because hd logic cells are tapless; taps live in separate tap cells inserted periodically during place and route |
| `output_writers` | GDS, LEF, Magic, OASIS | which output files to emit |
| `obstruction_layers` | list | which layers go into the LEF obstruction section, so the block router knows where it may not route over a cell |
| derived grid (`middle`, `gridpoints`, `grid_ys`, `power_vias`) | computed | the actual routing track y positions and power via placement, calculated from the height and pitch above. Not a knob, but it is where those numbers turn into real tracks |

---

## Layer 3: Per cell recipe knobs (the only thing that varies per cell)

These are read from environment variables (or command line flags), so the per cell line in
`recipes/recipes` sets them. The output still obeys layers 1 and 2, so a cell stays co legal no
matter which of these it uses.

| Knob | Default | What it does | Read in |
|---|---|---|---|
| `PLACER` | `hierarchical` | transistor placement algorithm (`meta`, `hierarchical`, `flat`, `smt`) | CLI flag |
| `ROUTER` | `dijkstra` | signal router (`dijkstra`, `steiner`) | CLI flag |
| `RECIPE_MCON_WEIGHT` | `300000` | routing cost of the li1 to met1 via; higher keeps short intra cell nets on li1 instead of hopping to met1 | tech file, `via_weights` |
| `RECIPE_LIFT_DRAINS` | `0` | lift parallel drain contacts off the same polarity rail so their li1 pads cannot merge with it; fixes the NOR and AOI parallel pulldown short | tech file + `router.py` |
| `RECIPE_NUM_LAYERS` | `2` | metal escalation ladder: 2 = li1 + met1 (foundry faithful), 3 = add met2, 4 = add met3. The solver tries 2 first and climbs only if a cell will not route | tech file, `routing_layers` |
| `RECIPE_HEIGHT_MULT` | `1` | row height multiplier; 2 makes a **double height** cell (spans two rows) with a big routing channel, the automatable fallback for flops and large AOIs | tech file, `unit_cell_height` |
| `RECIPE_SKIP_MIN_AREA` | `0` | skip the min area shape growth (a DRC nicety, not required for LVS); lets a cell close when min area fixing would otherwise fail | tech file |
| `RECIPE_GROUP_FINGERS` | `0` | collapse identical parallel transistors (fingers) into one group during placement, to simplify hard layouts | `euler_placer.py` patch |
| `RECIPE_LIFT_TIGHT` | `0` | tunes `RECIPE_LIFT_DRAINS`: how far the lift must move a signal contact off the rail. Default requires full DRC spacing (safe, but needs vertical room); `1` requires only that the contact does not touch the rail. Use `1` for narrow (small width) transistors whose diffusion is too short to fit full spacing: the lift still fires and stops the short (LVS clean) at the cost of a small li1 spacing DRC nit | `router.py` patch |
| `RECIPE_LIFT_MIN_COLS` | `2` | tunes `RECIPE_LIFT_DRAINS`: how many gate columns of rail adjacent signal contacts must line up before the lift fires. Default `2` targets only the real parallel drain short (two or more parallel devices packing li1 against the rail); a single contact is left for the router to route up on its own. With more room (extra metal layers or a double height cell) set `1` to lift single contacts too | `router.py` patch |

### A subtlety worth knowing
Two of these knobs, `RECIPE_HEIGHT_MULT` and `RECIPE_NUM_LAYERS`, technically touch the
architecture (row height and available layers). They are still safe to vary per cell because
they preserve co legality: a double height cell still abuts its neighbors (it just spans two
rows), and a cell that uses more metal layers still routes on shared, legal tracks. The base
architecture stays fixed; these only add room in a co legal way. Everything else in layer 3 is
purely a hint to lclayout's algorithms and does not change the cell's footprint at all.

---

## Coverage note
Every parameter group in `tech/sky130_hd_tech.py` is represented above. The only things not
listed one by one are the roughly 30 GDS label and pin datatypes (they follow the fixed pattern
`drawing ,20 / label ,5 / pin ,16` shown in the layer map) and the derived grid arithmetic at
the end of the file (computed from the layer 2 numbers, not configured). If you want those
spelled out too, say so and I will add them.

## Where to look
- The tech file itself: `tech/sky130_hd_tech.py` (573 lines, three layers as above).
- Per cell recipes: `recipes/recipes` (one line per cell) and the defaults in `run_cell.sh`.
- Our local changes to the lclayout engine that read some layer 3 knobs: `patches/` and the
  patched sources under `lclayout/src/`.
- The lab notebook `docs/LAB_NOTEBOOK.md` records why each of these knobs was added.
