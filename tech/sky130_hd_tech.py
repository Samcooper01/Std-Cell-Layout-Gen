import os
from lclayout.layout.layers import *
from lclayout.writer.magic_writer import MagWriter
from lclayout.writer.lef_writer import LefWriter
from lclayout.writer.gds_writer import GdsWriter
from lclayout.writer.oasis_writer import OasisWriter

# ===========================================================================
# PER CELL RECIPE KNOBS  (LAYER 3, generator/solver settings that are SAFE to
# vary per cell without breaking library co legality).
#
# This file has three conceptual layers; only the third may vary per cell:
#   1. Process rules   (DRC: spacing/width/enclosure, via sizes, layer map), 
#      foundry defined, identical for every cell.
#   2. Library arch    (unit_cell_height, site/placement grid, routing tracks,
#      unit_cell_width), ONE choice per library, shared by all cells so they
#      abut in rows and expose pins on common tracks. Varying these per cell
#      would misalign pins/rows and break block assembly even if each cell is
#      individually LVS-clean.
#   3. Generator recipe (placer, router, routing costs), heuristics for
#      lclayout's algorithms; safe to vary per cell because the output still
#      obeys layers 1 and 2.
#
# The harness (harness/recipes + run_cell.sh) sets these per cell.  Placer and
# router are CLI flags; the tech resident knobs below read from the environment
# so a per cell recipe can override them:
#   RECIPE_MCON_WEIGHT : li1<->met1 (mcon) routing via cost. Higher keeps short
#                        intra cell nets on li1 instead of detouring to met1.
#   RECIPE_LIFT_DRAINS : 0/1. When 1, the router lifts parallel signal (drain)
#                        diffusion contacts off the same polarity power rail so
#                        their li1 pad cannot abut the rail and merge nets. Fixes
#                        the NOR/AOI parallel pulldown short (nor3/nor4/o21ai/...).
#                        DEFAULT 0: only cells that actually short need it; forcing
#                        it on compound cells (and3/mux2...) over constrains routing
#                        and can make them unroutable, so it is opt in per cell.
# NOTE: unit_cell_width/height and DRC are deliberately NOT recipe knobs.
recipe_mcon_weight = int(os.environ.get("RECIPE_MCON_WEIGHT", "300000"))
lift_signal_drains = bool(int(os.environ.get("RECIPE_LIFT_DRAINS", "0")))
#   RECIPE_NUM_LAYERS : how many routing layers the cell may use, an escalation
#                       ladder for congested cells that cannot route in the
#                       foundry faithful 2 layer stack:
#                         2 -> li1 + met1                 (DEFAULT, = sky130 hd)
#                         3 -> li1 + met1 + met2
#                         4 -> li1 + met1 + met2 + met3
#                       The solver tries 2 first and only escalates when a cell
#                       won't route, so cells stay on the fewest layers that work.
#                       Default 2 => zero change for the committed 2 layer cells.
recipe_num_layers = int(os.environ.get("RECIPE_NUM_LAYERS", "2"))
# ===========================================================================

# Physical size of one data base unit in meters.
# BUT GDS2 requires the database units to be in nanometers, and lclayout cannot convert to nanometers automatically yet
db_unit = 1e-9

# Lambda - how many db_units is 1 lambda?
l = 55  # unused
grid = 5 # grid basis
um = 1000
nm = 1

# Scale transistor width.
transistor_channel_width_sizing = 1

# GDS2 layer numbers for final output.
my_diffusion = (65, 20) # = ndiffusion+pdiffusion
my_diffusion_label = (65, 6)
my_diffusion_pin = (65, 16)
#my_pdiffusion = (1, 7) -> my_diffusion

my_nwell = (64, 20)
my_nwell_label = (64, 5)
my_nwell_pin = (64, 16) #  (64, 0) !!! both GDS definitions were found in the Skywater documentation, please check which are correct.

my_pwell = (64, 13) # This layer is only used for resistors, which we dont need here

my_poly = (66, 20) # poly silicium for gates -> poly + ntransistor + ptransistor
my_poly_gate = (66, 9) # poly gates? Why do we have a second layer for gates?
my_poly_label = (66, 5)

my_licon1 = (66, 44) # licon1 is used to contact both polysilicon and diffusion in SKY130.
my_li1 = (67, 20) # "Local Interconnect"  (like the first metal layer)
my_li1_label = (67, 5)
my_li1_pin = (67, 16)

my_mcon = (67, 44) # connecting li1 to metal1
my_metal1 = (68, 20)
my_metal1_label = (68, 5)
my_metal1_pin = (68, 16)
my_via1 = (68, 44)     # sky130 'via', met1 <-> met2
my_metal2 = (69, 20)   # sky130 met2
my_metal2_label = (69, 5)
my_metal2_pin = (69, 16)
my_via2 = (69, 44)     # sky130 'via2', met2 <-> met3
my_metal3 = (70, 20)   # sky130 met3
my_metal3_label = (70, 5)
my_metal3_pin = (70, 16)
my_abutment_box = (235, 4) # prBndry  ???
#my_outline = (235, 5) # 

my_pplus = (65,44) # TAP.DRAWING
my_nplus = (65,44) # TAP.DRAWING

# lclayout internally uses its own layer numbering scheme.
# For the final output the layers can be remapped with a mapping
# defined in this dictioinary.
output_map = {
    l_ndiffusion: my_diffusion,
    l_pdiffusion: my_diffusion,
    l_nwell: my_nwell, # [my_nwell, my_nwell2],  # Map l_nwell to two output layers.
    l_pwell: my_pwell,  # Output layer for pwell. Uncomment this if needed. For instance for twin-well processes.
    l_poly: my_poly,
    l_poly_contact: my_licon1,
    l_pdiff_contact: my_licon1,
    l_ndiff_contact: my_licon1,
    l_metal1: my_li1, # Metal1 from lclayout gets li1 from SKY130
    l_metal1_label: my_li1_label,
    l_metal1_pin: my_li1_pin,
    l_via1: my_mcon,
    l_metal2: my_metal1, # Metal2 from lclayout gets met1 from SKY130
    l_metal2_label: my_metal1_label,
    l_metal2_pin: my_metal1_pin,
    l_via2: my_via1,       # lclayout via2 -> sky130 'via' (met1<->met2)
    l_metal3: my_metal2,   # lclayout metal3 -> sky130 met2
    l_metal3_label: my_metal2_label,
    l_metal3_pin: my_metal2_pin,
    l_via3: my_via2,       # lclayout via3 -> sky130 'via2' (met2<->met3)
    l_metal4: my_metal3,   # lclayout metal4 -> sky130 met3
    l_metal4_label: my_metal3_label,
    l_metal4_pin: my_metal3_pin,
    l_abutment_box: my_abutment_box,
    #l_outline: my_outline,
    l_pplus: my_pplus,
    l_nplus: my_nplus,
    l_border_vertical: (142, 1),
    l_border_horizontal: (142, 2),
}

# These are only the obstruction layers, only these layers will be generated into the OBS section of the LEF files
obstruction_layers = [
    l_poly_contact,
    l_pdiff_contact,
    l_ndiff_contact,
    l_metal1, # Metal1 from lclayout gets li1 from SKY130
    l_via1,
    l_metal2, # Metal2 from lclayout gets met1 from SKY130
    l_via2,
    l_metal3, # met2
    l_via3,
    l_metal4, # met3
]

output_map_magic = {
            l_nwell: 'nwell',
            l_pwell: 'pwell',
            l_via1: 'viali',
            l_poly: 'poly',
            l_abutment_box: ['abutment'],
            l_metal1: 'li1',
            l_metal2: 'met1',
            l_metal1_label: 'li1',
            l_metal2_label: 'met1',
            l_metal1_pin: 'li1',
            l_metal2_pin: 'met1',
            l_via2: 'via',
            l_metal3: 'met2',
            l_metal3_label: 'met2',
            l_metal3_pin: 'met2',
            l_via3: 'via2',
            l_metal4: 'met3',
            l_metal4_label: 'met3',
            l_metal4_pin: 'met3',
            l_ndiffusion: 'ndiffusion',
            l_pdiffusion: 'pdiffusion',
            l_poly_contact: 'polycont',
            l_pdiff_contact: 'pdiffc',
            l_ndiff_contact: 'ndiffc',
            l_nplus: 'allnactivetap',
            l_pplus: 'allpactivetap'
}


# Define a list of output writers.
output_writers = [
    MagWriter(
        tech_name='sky130A',
        scale_factor=0.2, # Scale all coordinates by this factor (rounded down to next integer).
        magscale=[1,2],
        output_map=output_map_magic
    ),

    LefWriter(
        db_unit=1e-6, # LEF Fileformat always needs Microns
        obstruction_layers=obstruction_layers,
        output_map=output_map_magic,  # Not supported yet but will be soon
        use_rectangles_only=True,
        site="unit"
    ),

    GdsWriter(
        db_unit=db_unit,
        output_map=output_map
    ),

    OasisWriter(
        db_unit=db_unit,
        output_map=output_map
    )

]

# Define how layers can be used for routing.
# Example for a layer that can be used for horizontal and vertical tracks: {'MyLayer1' : 'hv'}
# Example for a layer that can be contacted but not used for routing: {'MyLayer2' : ''}
routing_layers = {
    l_ndiffusion: '', # Allow adding shapes on diffusion layer but without using it for routing. This is used to automatically add the necessary enclosure around contacts.
    l_pdiffusion: '', # Allow adding shapes on diffusion layer but without using it for routing. This is used to automatically add the necessary enclosure around contacts.
    l_poly: '',
    l_metal1: 'hv',
    l_metal2: 'hv',
}
# Escalation ladder (RECIPE_NUM_LAYERS): met2/met3 become routing layers only
# when a congested cell needs them. Default 2 => only li1(l_metal1)+met1(l_metal2),
# i.e. no change for the committed 2 layer cells.
if recipe_num_layers >= 3:
    routing_layers[l_metal3] = 'hv'   # sky130 met2
if recipe_num_layers >= 4:
    routing_layers[l_metal4] = 'hv'   # sky130 met3

# Minimum spacing rules for layer pairs.
min_spacing = {
    (l_ndiffusion, l_ndiffusion): 270*nm, # (difftap.3)
    #(l_ndiffusion, l_outline): 270/2*nm, # (difftap.3)
    (l_pdiffusion, l_ndiffusion): 270*nm, # (difftap.3)
    #(l_pdiffusion, l_outline): 270/2*nm, # (difftap.3)
    (l_pdiffusion, l_pdiffusion): 270*nm, # (difftap.3)
    (l_ndiffusion, l_poly_contact): 190*nm, # (licon.14)
    (l_pdiffusion, l_poly_contact): 190*nm, # (licon.14)
    (l_nwell, l_nwell): 1270*nm, # (nwell.2a)
    (l_nwell, l_pwell): 250*nm, # p_well not needed for SKY130, but lclayout uses it for sizing the wells!
    (l_pwell, l_pwell): 1270*nm, # p_well not needed for SKY130
    (l_poly, l_ndiffusion): 75*nm, # (poly.4)
    (l_poly, l_pdiffusion): 75*nm, # (poly.4)
    (l_poly, l_poly): 210*nm, # (poly.2)
    #(l_poly, l_outline): 210/2*nm, # (poly.2) 
    (l_poly, l_pdiff_contact): 155*nm, # 55*nm # (licon.11)
    (l_poly, l_ndiff_contact): 155*nm, # 55*nm # (licon.11)
    (l_pdiff_contact, l_pdiff_contact): 270*nm, # (difftap.3)
    #(l_pdiff_contact, l_outline): 270/2*nm, # (difftap.3)
    (l_ndiff_contact, l_ndiff_contact): 270*nm, # (difftap.3)
    #(l_ndiff_contact, l_outline): 270/2*nm, # (difftap.3)
    (l_pdiff_contact, l_ndiff_contact): 270*nm, # (difftap.3)
    (l_metal1, l_metal1): 170*nm, # (li.3) # !!!! WARNING: Spacing to huge_met1 (>=?nm) needs to be 280nm !
    #(l_metal1, l_outline): 170/2*nm, # (li.3) # !!!! WARNING: Spacing to huge_met1 (>=?nm) needs to be 280nm !
#    (l_metal1, l_border_vertical): 190*nm, # To move the VIAs at the right place
#    (l_metal2, l_border_vertical): 190*nm, # To move the VIAs at the right place

    (l_metal2, l_metal2): 140*nm, # (m1.2) # huge_met2
    (l_metal3, l_metal3): 140*nm, # met2 (m2.2)
    (l_metal4, l_metal4): 140*nm, # met3 (placeholder; real m3.2=300nm)
    # We need metal2 at the border for the power lanes, so we dont put border rules
    (l_via1, l_via1): 190*nm, # (ct.2)
    (l_via2, l_via2): 260*nm, # met1<->met2 via spacing (>= met2 width 140 + 2*encl 60)
    (l_via3, l_via3): 260*nm, # met2<->met3 via2 spacing
    #(l_via1, l_outline): 190/2*nm, # (ct.2)
    #(l_via1, l_diff_contact): 2*l, # NO RULES FOR LICON MCON spacing found
    #(l_via1, l_ndiffusion): 2*l, # NO RULES FOR MCON DIFF spacing found
    #(l_via1, l_pdiffusion): 2*l, # NO RULES FOR MCON DIFF spacing found
    (l_poly_contact, l_pdiff_contact): 170*nm, # (licon.2)
    #(l_poly_contact, l_outline): 170/2*nm, # (licon.2)
    (l_poly_contact, l_ndiff_contact): 170*nm, # (licon.2)
    (l_ndiffusion, l_pplus): 75*nm,
    (l_pdiffusion, l_nplus): 75*nm,
}

# Layer for the pins.
# sky130 hd puts signal pins (A, Y, ...) on li1 (locali). lclayout.metal1 = sky130.li1,
# so signal pins go on l_metal1. (Previously l_metal2=met1, which inverted the stack:
# signals ended up on met1 and power on li1, opposite of the foundry cells.)
pin_layer = l_metal1 # lclayout.metal1 = sky130.li1

# Power stripe layer.
# sky130 hd draws the VPWR/VGND rails on BOTH li1 and met1, stitched together with mcon
# vias along the rail. lclayout draws the rail on every layer in this list and, when the
# list has >1 entry, auto stitches consecutive layers with the corresponding via
# (via_layers[l_metal1][l_metal2] = mcon). With only [l_metal1] the met1 rail was absent /
# a dangling unstitched strip. l_metal1=li1, l_metal2=met1.
power_layer = [l_metal1, l_metal2]

# Layers that can be connected/merged without changing the schematic.
# This can be used to resolve spacing/notch violations by just filling the space.
connectable_layers = {l_nwell, l_pwell, l_poly}
# Width of the gate polysilicon stripe.
# is reused as the minimum_width for the l_poly layer
gate_length = 150*nm # (poly.1a)
gate_length_pmos = gate_length
gate_length_nmos = gate_length

# Minimum length a polysilicon gate must overlap the silicon.
gate_extension = 130*nm # (poly.8)

# Minimum distance of active area to upper or lower boundary of the cell. Basically determines the y offset of the transistors.
transistor_offset_y = 240*nm # !!! This likely needs to be tuned later on # The 150/2*nm might have to be removed

# Standard cell dimensions.
# A 'unit cell' corresponds to the dimensions of the smallest possible cell. Usually an inverter.
# `unit_cell_width` also corresponds to the pitch of the gates because gates are spaced on a regular grid.
# RECIPE_WIDTH_MULT (default 1): INTEGER gate-pitch multiplier. =2 spaces the gates
# twice as far apart, opening vertical routing channels between them without changing
# the transistors, and is the lever for congested cells that the note below flagged as
# missing ("mux2-class cells need more width"). It must be an integer: routing_grid_pitch_x
# = unit_cell_width//6, and an integer multiple keeps that grid a superset of the terminal-
# aligned 115nm grid (2*690//6 = 230 = 2*115), and keeps the cell boundary site-legal so
# cells still abut. Non-integer widths (460/920/1150) misalign the grid and fail to route.
_width_mult = int(os.environ.get("RECIPE_WIDTH_MULT", "1"))
unit_cell_width = 690*nm * _width_mult # gate pitch. Was 1440 -> inv came out 2.88um (2.09x
# foundry's 1.38um). 690 makes inv_1 exactly 1.38um (=3x the 0.46um hd site) and keeps
# simple/mid cells LVS-clean. Note routing_grid_pitch_x = unit_cell_width//6, so this also
# sets the x routing grid; 690 (//6=115) keeps the grid aligned to transistor terminals.
# mux2-class cells that need more width now set RECIPE_WIDTH_MULT>=2. # 480*3, 1380, 920
# RECIPE_HEIGHT_MULT (default 1): cell row height multiplier. =2 makes a
# DOUBLE HEIGHT cell (spans two standard rows) so the middle becomes a large
# routing channel -- the automatable fallback for complex cells (flops, big AOIs)
# that won't route in a single row. The solver tries single height first and only
# promotes to double height on failure. Default 1 => no change to committed cells.
_height_mult = int(os.environ.get("RECIPE_HEIGHT_MULT", "1"))
unit_cell_height = 3330*nm * _height_mult # (unit SITE) # 2720*nm base; x_height_mult for multi-row cells
#assert unit_cell_height >= 16*um, "minimum 16um due to pwell width + nwell pwell spacing"
# due to nwell size and spacing requirements routing_grid_pitch_y * 8 # * 8

# Routing pitch
routing_grid_pitch_x = unit_cell_width // 6 # // 4
routing_grid_pitch_y = 135*nm # unit_cell_height // 8 // 2

# Translate routing grid such that the bottom left grid point is at (grid_offset_x, grid_offset_y)
grid_offset_x = routing_grid_pitch_x
grid_offset_y = 0 # (routing_grid_pitch_y // 2 ) -10

# Width of power rail.
power_rail_width = 480*nm # compatible to SKY130 #  3*130*nm # decided by the standard cell library architect

# sky130 hd LOGIC cells are tapless: well/substrate taps live in separate tap cells
# (tapvpwrvgnd, tap), inserted periodically by P&R. So we skip lclayout's per cell well tap
# insertion (verified: inv/nor3/nand4/a311o have no tap layer 65/44; only tap* cells do).
# Forcing a tap into every cell also fails to route in packed cells (e.g. nor3). The tap
# cells themselves will be generated separately with this re-enabled.
enable_well_taps = False

# Minimum width of polysilicon gate stripes.
# It increases w and l from the spice netlist, so it must be width from the spice netlist
minimum_gate_width_nfet = 150*nm # (poly.1a)
minimum_gate_width_pfet = 150*nm # (poly.1a)

# Minimum width for pins.
minimum_pin_width = 130*nm 

# Width of routing wires.
wire_width = {
    l_ndiffusion: 150*nm, # (difftap.1)
    l_pdiffusion: 150*nm, # (difftap.2)
    l_poly: 150*nm,   # (poly.1a)
    l_metal1: 170*nm, # (li.1)
    l_metal2: 140*nm, # (m1.1)
    l_metal3: 140*nm, # met2 (m2.1), escalation layer
    l_metal4: 140*nm, # met3 (placeholder; real m3.1=300nm, refine for DRC-exactness)
}

# Width of horizontal routing wires (overwrites `wire_width`).
wire_width_horizontal = {
    l_ndiffusion: 150*nm, # (difftap.1)
    l_pdiffusion: 150*nm, # (difftap.2)
    l_poly: 150*nm,   # (poly.1a)
    l_metal1: 170*nm, # (li.1)
    l_metal2: 140*nm, # (m1.1)
    l_metal3: 140*nm, # met2
    l_metal4: 140*nm, # met3
}

# Side lengths of vias (square shaped).
via_size = {
    l_poly_contact: 170*nm, # (ct.1)
    l_ndiff_contact: 170*nm, # (ct.1)
    l_pdiff_contact: 170*nm, # (ct.1)
    l_via1: 170*nm, # (licon.1)
    l_via2: 170*nm, # met1<->met2 via (real via.1a=150nm; mirror mcon for consistency)
    l_via3: 170*nm, # met2<->met3 via2
}

# Minimum width rules.
minimum_width = {
    l_ndiffusion: 150*nm, # (difftap.1)
    l_pdiffusion: 150*nm, # (difftap.1)
    l_poly: gate_length,
    l_metal1: 170*nm, # (li.1)
    l_metal2: 140*nm, # (m1.1)
    l_metal3: 140*nm, # met2
    l_metal4: 140*nm, # met3
    l_nwell: 1000*nm
}

# Minimum enclosure rules.
# Syntax: {(outer layer, inner layer): minimum enclosure, ...}
minimum_enclosure = {
    # Via enclosure
    (l_ndiffusion, l_ndiff_contact): 60*nm, # (licon.5a)
    (l_pdiffusion, l_pdiff_contact): 60*nm, # (licon.5a)
    (l_poly, l_poly_contact): 80*nm, # (licon.8a) !!! OR (licon.4) ?
    (l_metal1, l_pdiff_contact): 80*nm, # (li.5)
    (l_metal1, l_ndiff_contact): 80*nm, # (li.5)
    (l_metal1, l_poly_contact): 80*nm, # (li.5)
    (l_metal1, l_via1): 0*nm, # this was 0,# (ct.4)
    (l_metal2, l_via1): 60*nm,# (m1.4)
    (l_metal2, l_via2): 60*nm,# met1 encloses via to met2
    (l_metal3, l_via2): 60*nm,# met2 encloses via
    (l_metal3, l_via3): 60*nm,# met2 encloses via2
    (l_metal4, l_via3): 60*nm,# met3 encloses via2

    # l_*well must overlap l_*diffusion
#    (l_nwell, l_pdiffusion): 180*nm+130*nm, # (difftap.8) # This causes notches, I am trying to get rid of them
    (l_pwell, l_ndiffusion): 180*nm, # (difftap.8)
    (l_abutment_box, l_nwell): 0, # The nwell and pwell should not go beyond the abutment
    (l_abutment_box, l_pwell): 0,
    (l_nplus, l_ndiff_contact): 80*nm,  # Implicitly encodes the size of well taps.
    (l_pplus, l_pdiff_contact): 80*nm,  # Implicitly encodes the size of well taps.

}

# Minimum notch rules.
minimum_notch = {
    l_ndiffusion: 130*nm,
    l_pdiffusion: 130*nm,
    l_poly: 130*nm,
    l_metal1: 130*nm,
    l_metal2: 130*nm,
    l_metal3: 130*nm, # met2
    l_metal4: 130*nm, # met3
    l_nwell: 5*130*nm,
    l_pwell: 5*130*nm,
}

# Minimum area rules.
min_area = {
    l_metal1: 0.0561 * um * um ,#  !!! TEMPORARILY DISABLED, PLEASE ENABLE AGAIN
    l_metal2: 0.083 * um * um ,# !!! TEMPORARILY DISABLED, PLEASE ENABLE AGAIN
}
# RECIPE_SKIP_MIN_AREA (0/1): min area fixing is a DRC step (grow small shapes via
# an SMT re solve), NOT an LVS requirement. On some congested/multi-layer cells the
# re solve goes UNSAT and kills an otherwise LVS clean cell. Skipping it (empty
# min_area) leaves the cell LVS clean but possibly min area DRC dirty -- an
# acceptable first pass trade, and another escalation rung. Default 0 = unchanged.
if int(os.environ.get("RECIPE_SKIP_MIN_AREA", "0")):
    min_area = {}

# ROUTING #

# Cost for changing routing direction (horizontal/vertical).
# This will avoid creating zig zag routings.
orientation_change_penalty = 100000

# Routing edge weights per data base unit.
weights_horizontal = {
    l_ndiffusion: 120000, # (mohms/square) taken from spreadsheet "Layer resistances and capacitances"
    l_pdiffusion: 197000, # (mohms/square)
    l_poly: 48200*10, # (mohms/square) # 10 to avoid routing
    l_metal1: 1280, # SKY130_Li1 Local Interconnect! (mohms/square)
    l_metal2: 125, # SKY130_Metal1
    l_metal3: 125, # met2
    l_metal4: 125, # met3
}
weights_vertical = {
    l_ndiffusion: 120000, # (mohms/square) taken from spreadsheet "Layer resistances and capacitances"
    l_pdiffusion: 197000, # (mohms/square)
    l_poly: 48200*10, # (mohms/square) # 10 to avoid routing
    l_metal1: 1280, # SKY130_Li1 Local Interconnect! (mohms/square)
    l_metal2: 125, # SKY130_Metal1
    l_metal3: 125, # met2
    l_metal4: 125, # met3
}

viafactor = 1

# Via weights.
via_weights = {
    (l_metal1, l_ndiffusion): 15000*viafactor, # LICON
    (l_metal1, l_pdiffusion): 15000*viafactor, # LICON
    (l_metal1, l_poly): 15000*viafactor, # LICON
    (l_metal1, l_metal2): recipe_mcon_weight*viafactor, # MCON, per-cell recipe knob
    # (RECIPE_MCON_WEIGHT, default 300000). Higher makes li1->met1 hops costlier so short
    # intra cell nets stay on li1 instead of detouring up to met1. 300k cut inv met1 rects
    # 7->5 and improved test set completeness 12/14 -> 13/14; >=600k starts breaking cells
    # (xor2). Was originally 152000.
    (l_metal2, l_metal3): 150000*viafactor, # VIA (met1<->met2). Moderate cost so the
    # router prefers 2 layer routing and only spills onto met2 when congested.
    (l_metal3, l_metal4): 150000*viafactor, # VIA2 (met2<->met3)
#    (l_metal1, l_nplus): 1, # Contact to Well Taps, the value doesn't matter
#    (l_metal1, l_pplus): 1,

}

# Enable double vias between layers.
multi_via = {
    (l_metal1, l_poly): 1,
    (l_metal1, l_metal2): 1,
    (l_metal2, l_metal3): 1,
    (l_metal3, l_metal4): 1,
}

if( min_spacing[(l_pdiff_contact, l_pdiff_contact)] < min_spacing[(l_pdiffusion,l_pdiffusion)]+2*minimum_enclosure[(l_pdiffusion, l_pdiff_contact)]):
        newmin=min_spacing[(l_pdiffusion,l_pdiffusion)]+2*minimum_enclosure[(l_pdiffusion, l_pdiff_contact)]
        print("Minimum Spacing "+str(min_spacing[(l_pdiff_contact, l_pdiff_contact)])+" for pdiff_contact too small because of pdiffusion, minimum should be "+ str(newmin)+"(="+str(min_spacing[(l_pdiffusion,l_pdiffusion)])+"+2*"+str(minimum_enclosure[(l_pdiffusion, l_pdiff_contact)])+") Fixing minimum_spacing")
        min_spacing[(l_pdiff_contact, l_pdiff_contact)]=newmin

if( min_spacing[(l_ndiff_contact, l_ndiff_contact)] < min_spacing[(l_ndiffusion,l_ndiffusion)]+2*minimum_enclosure[(l_ndiffusion, l_ndiff_contact)]):
        newmin=min_spacing[(l_ndiffusion,l_ndiffusion)]+2*minimum_enclosure[(l_ndiffusion, l_ndiff_contact)]
        print("Minimum Spacing "+str(min_spacing[(l_ndiff_contact, l_ndiff_contact)])+" for ndiff_contact too small because of ndiffusion, minimum should be "+ str(newmin)+"(="+str(min_spacing[(l_ndiffusion,l_ndiffusion)])+"+2*"+str(minimum_enclosure[(l_ndiffusion, l_ndiff_contact)])+") Fixing minimum_spacing")
        min_spacing[(l_ndiff_contact, l_ndiff_contact)]=newmin

if( min_spacing[(l_pdiff_contact, l_ndiff_contact)] < min_spacing[(l_pdiffusion,l_ndiffusion)]+minimum_enclosure[(l_ndiffusion, l_ndiff_contact)]+minimum_enclosure[(l_pdiffusion, l_pdiff_contact)]):
        newmin=min_spacing[(l_pdiffusion,l_ndiffusion)]+minimum_enclosure[(l_ndiffusion, l_ndiff_contact)]+minimum_enclosure[(l_pdiffusion, l_pdiff_contact)]
        print("Minimum Spacing "+str(min_spacing[(l_ndiff_contact, l_ndiff_contact)])+" for pdiff_contact - ndiff_contact too small because of ndiffusion, minimum should be "+ str(newmin)+"(="+str(min_spacing[(l_pdiffusion,l_ndiffusion)])+"+"+str(minimum_enclosure[(l_ndiffusion, l_ndiff_contact)])+"+"+str(minimum_enclosure[(l_pdiffusion, l_pdiff_contact)])+") Fixing minimum_spacing")
        min_spacing[(l_pdiff_contact, l_ndiff_contact)]=newmin

if((l_poly_contact, l_poly_contact) in min_spacing and  min_spacing[(l_poly_contact, l_poly_contact)] < min_spacing[(l_poly,l_poly)]+2*minimum_enclosure[(l_poly, l_poly_contact)]):
        newmin=min_spacing[(l_poly,l_poly)]+2*minimum_enclosure[(l_poly, l_poly_contact)]
        print("Minimum Spacing "+str(min_spacing[(l_poly_contact, l_poly_contact)])+" for poly_contact too small because of polysilicon, minimum should be "+ str(newmin)+"(="+str(min_spacing[(l_poly,l_poly)])+"+"+str(minimum_enclosure[(l_poly, l_poly_contact)])+"+"+str(minimum_enclosure[(l_poly, l_poly_contact)])+") Fixing minimum_spacing")
        min_spacing[(l_poly_contact, l_poly_contact)]=newmin

if((l_poly_contact, l_poly_contact) in min_spacing and  min_spacing[(l_poly_contact, l_poly_contact)] < min_spacing[(l_metal1,l_metal1)]+2*minimum_enclosure[(l_metal1, l_poly_contact)]):
        newmin=min_spacing[(l_metal1,l_metal1)]+2*minimum_enclosure[(l_metal1, l_poly_contact)]
        print("Minimum Spacing "+str(min_spacing[(l_poly_contact, l_poly_contact)])+" for poly_contact too small because of local interconnect, minimum should be "+ str(newmin)+"(="+str(min_spacing[(l_metal1,l_metal1)])+"+"+str(minimum_enclosure[(l_metal1, l_poly_contact)])+"+"+str(minimum_enclosure[(l_metal1, l_poly_contact)])+") Fixing minimum_spacing")
        min_spacing[(l_poly_contact, l_poly_contact)]=newmin

if( min_spacing[(l_via1, l_via1)] < min_spacing[(l_metal1,l_metal1)]+2*minimum_enclosure[(l_metal1, l_via1)]):
        newmin=min_spacing[(l_metal1,l_metal1)]+2*minimum_enclosure[(l_metal1, l_via1)]
        print("Minimum Spacing "+str(min_spacing[(l_via1, l_via1)])+" for via1 too small because of local interconnect, minimum should be "+ str(newmin)+"(="+str(min_spacing[(l_metal1,l_metal1)])+"+2*"+str(minimum_enclosure[(l_metal1, l_via1)])+") Fixing minimum_spacing")
        min_spacing[(l_via1, l_via1)]=newmin

if( min_spacing[(l_via1, l_via1)] < min_spacing[(l_metal2,l_metal2)]+2*minimum_enclosure[(l_metal2, l_via1)]):
        newmin=min_spacing[(l_metal2,l_metal2)]+2*minimum_enclosure[(l_metal2, l_via1)]
        print("Minimum Spacing "+str(min_spacing[(l_via1, l_via1)])+" for via1 too small because of metal1, minimum should be "+ str(newmin)+"(="+str(min_spacing[(l_metal2,l_metal2)])+"+2*"+str(minimum_enclosure[(l_metal2, l_via1)])+") Fixing minimum_spacing")
        min_spacing[(l_via1, l_via1)]=newmin



    #(l_poly_contact, l_pdiff_contact): 170*nm, # (licon.2)
    #(l_poly_contact, l_ndiff_contact): 170*nm, # (licon.2)
#unit_cell_height=10
#routing_grid_pitch_y=4

#print("unit_cell_height: "+str(unit_cell_height))
#print("routing_grid_pitch_y: "+str(routing_grid_pitch_y))
middle=unit_cell_height//2
#print("Middle: "+str(middle))
gridpoints=1+unit_cell_height//routing_grid_pitch_y
#print("gridpoints: "+str(gridpoints))
odd=gridpoints &1
#print("odd: "+str(odd))

if odd==1:
    grid_offset_y=middle-((gridpoints-1)//2)*routing_grid_pitch_y
else:
    grid_offset_y=middle+routing_grid_pitch_y//2-(gridpoints//2)*routing_grid_pitch_y

#print("grid_offset_y: "+str(grid_offset_y))
grid_ys = list(range(grid_offset_y, grid_offset_y + unit_cell_height +1, routing_grid_pitch_y))
print("grid_before: "+str(grid_ys))
grid_ys[2] += 110*nm
grid_ys[-3] -= 110*nm
grid_ys[14] -= 10*nm
grid_ys[1] = 0
grid_ys[-2] = unit_cell_height
grid_ys.pop(-1)
grid_ys.pop(0)
print("grid_after: "+str(grid_ys))



def powervias(unit_cell_width): 
    return list(range(240*nm,unit_cell_width,480*nm))

power_vias=powervias
