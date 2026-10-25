#!/usr/bin/env bash
# Generate CELL_TAXONOMY.md from recipes/cell_categories.tsv.
# Descriptions are embedded here; the cell lists are pulled live from the map so
# they never drift. Re run after any classifier change.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MAP="$ROOT/recipes/cell_categories.tsv"
OUT="$ROOT/docs/CELL_TAXONOMY.md"

# category  ->  human title
declare -A TITLE=(
  [inverter]="Inverters" [buffer]="Buffers" [and_or]="AND / OR gates"
  [nand_nor]="NAND / NOR gates" [aoi]="AND OR Invert (AOI)" [oai]="OR AND Invert (OAI)"
  [xor_xnor]="XOR / XNOR" [mux]="Multiplexers" [adder]="Adders / majority"
  [tristate]="Tristate / enabled drivers" [flipflop]="Flip flops" [latch]="Latches"
  [clock_delay]="Clock & delay" [tie_probe]="Tie & probe" [fill_phys]="Fill / physical"
  [lpflow_pwr]="Low power / level shift / isolation")

desc(){ case "$1" in
 inverter)  echo "The fundamental gate: one PMOS pull up + one NMOS pull down inverting the input. Includes clock inverters (\`clkinv\`, sized for clock nets), a low power, low leakage variant (\`clkinvlp\`), and \`bufinv\` (buffered inverter). Drive strengths run \`_1\`…\`_16\`. Simplest cells in the library; they place and route trivially." ;;
 buffer)    echo "Two cascaded inverters (net non inverting) that restore edge rate and drive large loads. \`clkbuf\` distributes clocks; \`bufbuf\` is an extra strong buffer. Also easy to build." ;;
 and_or)    echo "Primitive AND / OR gates, 2 to 4 inputs, plus input inverted variants (trailing \`b\`/\`bb\` invert one/two inputs, e.g. \`and2b\`, \`or4bb\`). Because static CMOS is naturally inverting, these are physically a NAND/NOR core followed by an inverter, i.e. two stage cells." ;;
 nand_nor)  echo "The natural single stage CMOS primitives: NAND (series NMOS / parallel PMOS) and NOR (its dual). 2 to 4 inputs plus \`b\`/\`bb\` inverted input variants. Workhorse logic; almost always route easily." ;;
 aoi)       echo "AND OR Invert compound gates, the **largest family**. The name \`aXYZ…o[i]\` encodes the sizes of the AND groups feeding an OR then an (optional) invert: e.g. \`a21oi\` = (2 input AND) OR (1 input), inverted. Single stage static CMOS. The high drive members are the routability stressers." ;;
 oai)       echo "OR AND Invert, the exact dual of AOI: OR groups feed an AND then an invert (\`o21ai\`, \`o221a\`, …). Same structure and same placement/routing challenges as the AOI family." ;;
 xor_xnor)  echo "Exclusive OR / XNOR, 2 to 3 inputs. Notable because XOR needs both true and complemented versions of its inputs internally, so it packs more transistors and denser internal routing than the input count suggests." ;;
 mux)       echo "2:1 and 4:1 multiplexers (\`mux2\`, \`mux4\`) plus inverting \`mux2i\`. Select logic driving a pass/tristate structure; internal routing is moderately dense." ;;
 adder)     echo "Full adders (\`fa\`, \`fah\`, and carry in and carry out flavors \`fahcin\`/\`fahcon\`), the half adder (\`ha\`), and 3 input majority (\`maj3\`). Multi output (sum + carry) compound cells, among the harder combinational cells to place and route." ;;
 tristate)  echo "Tristate / enabled drivers whose output can go high impedance: \`einvn\`/\`einvp\` (enabled inverters, active low / active high enable) and \`ebufn\` (enabled buffer). Used to drive shared buses." ;;
 flipflop)  echo "Edge triggered D flip flops, the sequential backbone. Prefixes: \`df\` base; leading \`s\` = **scan** for test (adds \`SCD\` and \`SCE\`: when scan enable \`SCE\` is high the flop captures the scan input \`SCD\` instead of \`D\`, so flops chain into a shift register that shifts test patterns in and results out), \`e\` = **enable** (adds \`DE\`: the flop loads \`D\` on the clock edge only when \`DE\` is high, otherwise it holds), \`se\` = both. Suffix letters encode reset/set and clock/output polarity (\`r\`=reset, \`s\`=set, \`bb\`=both, \`t/p/n/b\` = clock & output flavors). Each is ~20 to 30 transistors (master + slave latch + clock + set/reset), which is why **this family dominates the un converged set**, it is placement bound, not area bound." ;;
 latch)     echo "Level sensitive latches (\`dlxtp\`, \`dlrtp\`, …) and clock gating latches (\`dlclkp\`, \`sdlclkp\`). Effectively half a flip flop (a single latch), but still multi transistor; the clock gating latches are central to power management." ;;
 clock_delay) echo "Clock and delay elements: tuned delay buffers (\`clkdlybuf4s15/18/25/50\`) and metal/diffusion delay lines (\`dlygate4sd*\`, \`dlymetal6s*\`). Used to tune clock skew and fix hold. Structurally simple but geometry specific." ;;
 tie_probe) echo "Tie and probe cells: \`conb\` (constant tie high / tie low source) and \`probe_p\`/\`probec_p\` (DFT probe points). \`conb\` is the cell whose netlist contains an R/C device that lclayout's SPICE reader currently can't parse." ;;
 fill_phys) echo "Non logic physical cells: \`fill\` (filler), \`decap\` (decoupling capacitance), \`tap\`/\`tapvgnd\`/\`tapvpwrvgnd\` (well & substrate taps), \`diode\` (antenna diode), and \`macro_sparecell\`. No signal function, they satisfy DRC, well tie, and antenna rules. Several need dedicated templates rather than routing." ;;
 lpflow_pwr) echo "Low power flow cells: level shifters (\`lpflow_lsbuf_lh\`, low→high voltage domain), input isolation (\`lpflow_inputiso\`, \`inputisolatch\`), power gating / retention, and \`*isowell*\` isolated well variants. These span multiple voltage domains and need a second well / isolated well that the base cell template doesn't emit, a structural gap, not a routing problem." ;;
esac; }

# categories that get a one line functional description per cell (AOI onward)
EXPLAIN="aoi oai xor_xnor mux adder tristate flipflop latch clock_delay tie_probe fill_phys lpflow_pwr"

# AOI / OAI: structure read straight from the digits in the name
aoi_desc(){
  # Spell out the boolean: digits = AND-group sizes (a size-1 group is a single
  # input straight into the OR). AOI = groups AND'd inside, OR'd together, inverted.
  local n="$1" inner outer sizes i s letter term expr="" j nb extra tail
  case "$n" in a*) inner="AND"; outer="OR";; *) inner="OR"; outer="AND";; esac
  sizes=$(printf '%s' "$n" | grep -oE '[0-9]')
  i=0
  for s in $sizes; do
    letter=$(printf "\\$(printf '%03o' $((65+i)))")   # A, B, C, ...
    if [ "$s" -ge 2 ]; then
      term=""; j=1
      while [ "$j" -le "$s" ]; do term="$term${term:+ $inner }$letter$j"; j=$((j+1)); done
      term="($term)"
    else
      term="${letter}1"
    fi
    expr="$expr${expr:+ $outer }$term"
    i=$((i+1))
  done
  case "$n" in *i) tail=", then inverted";; *) tail="";; esac
  nb=$(printf '%s' "$n" | tr -cd b | wc -c); extra=""
  [ "$nb" -gt 0 ] && extra=" (with $nb input(s) inverted first)"
  echo "Y = $expr$tail$extra."
}

# flip flops: prefix s/e/se + reset/set/both + output + edge, all from the name
flop_desc(){
  local n="$1" pre="" fn="" out="" edge=""
  case "$n" in sedf*) pre="scan plus enable "; n=${n#sedf};; sdf*) pre="scan "; n=${n#sdf};; edf*) pre="enable "; n=${n#edf};; df*) n=${n#df};; esac
  case "$n" in r*) fn=" with async reset (Q to 0)"; n=${n#r};; s*) fn=" with async set (Q to 1)"; n=${n#s};; bb*) fn=" with async set and reset"; n=${n#bb};; x*) n=${n#x};; esac
  case "$n" in b*) out=", true and inverted outputs"; n=${n#b};; t*) out=", true output"; n=${n#t};; esac
  case "$n" in *n) edge="negative edge clock";; *) edge="positive edge clock";; esac
  echo "${pre}D flip flop, ${edge}${out}${fn}."
}

celldesc(){ case "$1" in
  xor2) echo "2 input exclusive OR: high when the two inputs differ.";;
  xor3) echo "3 input XOR: high on odd parity of the three inputs.";;
  xnor2) echo "2 input XNOR: high when the two inputs match.";;
  xnor3) echo "3 input XNOR: even parity of three inputs.";;
  mux2) echo "2 to 1 multiplexer: passes A0 or A1 depending on the select.";;
  mux2i) echo "2 to 1 multiplexer with an inverted output.";;
  mux4) echo "4 to 1 multiplexer: picks one of four inputs with two select bits.";;
  fa) echo "Full adder: sum and carry out of A, B, and a carry in.";;
  fah) echo "Full adder tuned for a fast carry chain.";;
  fahcin) echo "Full adder with a dedicated carry in path.";;
  fahcon) echo "Full adder with a dedicated carry out path.";;
  ha) echo "Half adder: sum (A xor B) and carry (A and B) of two bits.";;
  maj3) echo "Majority: the output is whatever value at least two of the three inputs hold.";;
  einvn) echo "Tristate inverter, active low enable: inverts A, or floats (high impedance) when off.";;
  einvp) echo "Tristate inverter, active high enable.";;
  ebufn) echo "Tristate buffer (non inverting), active low enable, for shared buses.";;
  dlxtp) echo "D latch, transparent while the clock is high, true output.";;
  dlxtn) echo "D latch, transparent while the clock is low (negative level).";;
  dlxbp) echo "D latch with true and inverted outputs.";;
  dlxbn) echo "D latch, negative level, true and inverted outputs.";;
  dlrtp) echo "D latch with async reset (Q to 0).";;
  dlrtn) echo "D latch with reset, negative level.";;
  dlrbp) echo "D latch with reset, true and inverted outputs.";;
  dlrbn) echo "D latch with reset, negative level, true and inverted outputs.";;
  dlclkp) echo "Clock gating latch: makes a glitch free gated clock enable.";;
  sdlclkp) echo "Clock gating latch with scan support.";;
  clkdlybuf4s15) echo "Clock delay buffer, 4 stages, shortest fixed delay.";;
  clkdlybuf4s18) echo "Clock delay buffer, 4 stages, short fixed delay.";;
  clkdlybuf4s25) echo "Clock delay buffer, 4 stages, medium fixed delay.";;
  clkdlybuf4s50) echo "Clock delay buffer, 4 stages, longest fixed delay.";;
  dlygate4sd1) echo "Delay gate, roughly 1 unit of fixed delay.";;
  dlygate4sd2) echo "Delay gate, roughly 2 units of fixed delay.";;
  dlygate4sd3) echo "Delay gate, roughly 3 units of fixed delay.";;
  dlymetal6s2s) echo "Metal delay line, 6 stages, short routing delay.";;
  dlymetal6s4s) echo "Metal delay line, 6 stages, medium routing delay.";;
  dlymetal6s6s) echo "Metal delay line, 6 stages, long routing delay.";;
  conb) echo "Tie cell: buffered constant 1 (HI) and 0 (LO) outputs for unused inputs.";;
  probe_p) echo "Probe point for design for test and debug access.";;
  probec_p) echo "Clock probe point for test access.";;
  decap) echo "Decoupling capacitor across the rails that steadies the supply.";;
  diode) echo "Antenna diode that protects thin gates from charge during fabrication.";;
  fill) echo "Filler cell that occupies empty space to keep layout density legal.";;
  macro_sparecell) echo "Spare gate left in the layout for late metal fixes.";;
  tap) echo "Well and substrate tap that pins the body voltage.";;
  tapvgnd) echo "Substrate tap tied to ground.";;
  tapvgnd2) echo "Substrate tap (wider) tied to ground.";;
  tapvpwrvgnd) echo "Tap tied to both power and ground.";;
  lpflow_bleeder) echo "Bleeder that slowly drains a floating node.";;
  lpflow_clkbufkapwr) echo "Clock buffer on always on power, for power gated regions.";;
  lpflow_clkinvkapwr) echo "Clock inverter on always on power.";;
  lpflow_decapkapwr) echo "Decap on the always on power rail.";;
  lpflow_inputiso0n) echo "Input isolation gate that clamps to 0 when the domain is off (active low enable).";;
  lpflow_inputiso0p) echo "Input isolation gate that clamps to 0 when the domain is off (active high enable).";;
  lpflow_inputiso1n) echo "Input isolation gate that clamps to 1 when the domain is off (active low enable).";;
  lpflow_inputiso1p) echo "Input isolation gate that clamps to 1 when the domain is off (active high enable).";;
  lpflow_inputisolatch) echo "Input isolation latch that holds the last value when the domain powers down.";;
  lpflow_isobufsrc) echo "Isolation buffer for a source biased domain.";;
  lpflow_isobufsrckapwr) echo "Isolation buffer on always on power.";;
  lpflow_lsbuf_lh_isowell) echo "Level shifter, low to high supply, in an isolated well.";;
  lpflow_lsbuf_lh_isowell_tap) echo "Level shifter (low to high) with an isolated well and body tap.";;
  lpflow_lsbuf_lh_hl_isowell_tap) echo "Level shifter usable low to high and high to low, isolated well plus tap.";;
  *) echo "";;
esac; }

describe(){ case "$1" in
  [ao][0-9]*) aoi_desc "$1";;
  df*|sdf*|edf*|sedf*) flop_desc "$1";;
  *) celldesc "$1";;
esac; }

# category print order (combinational → sequential → clock → special)
ORDER="inverter buffer and_or nand_nor aoi oai xor_xnor mux adder tristate flipflop latch clock_delay tie_probe fill_phys lpflow_pwr"

total=$(wc -l < "$MAP")
{
echo "# sky130_fd_sc_hd, Cell Taxonomy"
echo
echo "The library has **$total cells** across **16 functional categories**. Work dir logs are organized"
echo "one folder per category: \`.work/ceiling/max/<category>/<cell>/\`."
echo
echo "**Naming convention.** A cell name is \`<function>_<drive>\`, e.g. \`nand2_4\` is function \`nand2\` (a NAND with two inputs) at drive \`_4\`:"
echo "- \`<function>\` is the logic function. Its trailing digit is the **input count** for basic gates (\`nand2\`, \`nor3\`, \`and4\`) but **topology** for compound gates (\`a21oi\` is (2 input AND) OR (1 input), inverted). \`inv\`, \`buf\`, and the flip flops carry no input count digit."
echo "- The trailing \`_N\` is **drive strength**, relative output current. Higher N = wider transistors,"
echo "  faster into big loads, more area & power. \`_1\` is the unit drive."
echo "- A \`b\` / \`bb\` inside a gate name **inverts one / two inputs** (e.g. \`nand2b\`, \`or4bb\`)."
echo "- On flip flops: leading \`s\`=scan, \`e\`=enable; suffix letters encode reset/set & clock/output polarity."
echo "- \`lp\` / \`kapwr\` / \`iso\` mark low power, always on power, or isolation variants."
echo
echo "## Category summary"
echo
echo "| Category | Cells | What it is |"
echo "|---|--:|---|"
for cat in $ORDER; do
  n=$(awk -F'\t' -v C="$cat" '$2==C{n++}END{print n+0}' "$MAP")
  short=$(desc "$cat" | sed -E 's/\. .*//')   # first sentence
  printf '| **%s** (`%s`) | %d | %s |\n' "${TITLE[$cat]}" "$cat" "$n" "$short"
done
echo
echo "---"
echo
for cat in $ORDER; do
  n=$(awk -F'\t' -v C="$cat" '$2==C{n++}END{print n+0}' "$MAP")
  echo "## ${TITLE[$cat]}, \`$cat\` ($n cells)"
  echo
  echo "$(desc "$cat")"
  echo
  echo "**Cells** (base function → drive strengths):"
  echo
  # group by base function (strip trailing _<digits>), drives sorted NUMERICALLY
  awk -F'\t' -v C="$cat" '$2==C{print $1}' "$MAP" | sort > /tmp/_catcells
  case " $EXPLAIN " in *" $cat "*) explain=1;; *) explain=0;; esac
  sed -E 's/_[0-9]+$//' /tmp/_catcells | sort -u | while read -r b; do
    drives=$(grep -E "^${b}_[0-9]+$" /tmp/_catcells | sed -E 's/.*_//' | sort -n | sed 's/^/_/' | paste -sd, - | sed 's/,/, /g')
    [ -z "$drives" ] && drives="(single variant)"
    if [ "$explain" = 1 ]; then
      printf -- '- **`%s`** (drives %s)<br>\n  %s\n' "$b" "$drives" "$(describe "$b")"
    else
      printf -- '- `%s`, %s\n' "$b" "$drives"
    fi
  done
  echo
done
echo "---"
echo "_Generated by \`src/cellgen/gen_cell_taxonomy.sh\` from \`recipes/cell_categories.tsv\`._"
} > "$OUT"
echo "wrote $OUT ($(wc -l < "$OUT") lines)"
