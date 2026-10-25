# sky130_fd_sc_hd, Cell Taxonomy

The library has **437 cells** across **16 functional categories**. Work dir logs are organized
one folder per category: `.work/ceiling/max/<category>/<cell>/`.

**Naming convention.** A cell name is `<function>_<drive>`, e.g. `nand2_4` is function `nand2` (a NAND with two inputs) at drive `_4`:
- `<function>` is the logic function. Its trailing digit is the **input count** for basic gates (`nand2`, `nor3`, `and4`) but **topology** for compound gates (`a21oi` is (2 input AND) OR (1 input), inverted). `inv`, `buf`, and the flip flops carry no input count digit.
- The trailing `_N` is **drive strength**, relative output current. Higher N = wider transistors,
  faster into big loads, more area & power. `_1` is the unit drive.
- A `b` / `bb` inside a gate name **inverts one / two inputs** (e.g. `nand2b`, `or4bb`).
- On flip flops: leading `s`=scan, `e`=enable; suffix letters encode reset/set & clock/output polarity.
- `lp` / `kapwr` / `iso` mark low power, always on power, or isolation variants.

## Category summary

| Category | Cells | What it is |
|---|--:|---|
| **Inverters** (`inverter`) | 16 | The fundamental gate: one PMOS pull up + one NMOS pull down inverting the input |
| **Buffers** (`buffer`) | 14 | Two cascaded inverters (net non inverting) that restore edge rate and drive large loads |
| **AND / OR gates** (`and_or`) | 44 | Primitive AND / OR gates, 2 to 4 inputs, plus input inverted variants (trailing `b`/`bb` invert one/two inputs, e.g |
| **NAND / NOR gates** (`nand_nor`) | 44 | The natural single stage CMOS primitives: NAND (series NMOS / parallel PMOS) and NOR (its dual) |
| **AND OR Invert (AOI)** (`aoi`) | 69 | AND OR Invert compound gates, the **largest family** |
| **OR AND Invert (OAI)** (`oai`) | 68 | OR AND Invert, the exact dual of AOI: OR groups feed an AND then an invert (`o21ai`, `o221a`, …) |
| **XOR / XNOR** (`xor_xnor`) | 12 | Exclusive OR / XNOR, 2 to 3 inputs |
| **Multiplexers** (`mux`) | 10 | 2:1 and 4:1 multiplexers (`mux2`, `mux4`) plus inverting `mux2i` |
| **Adders / majority** (`adder`) | 12 | Full adders (`fa`, `fah`, and carry in and carry out flavors `fahcin`/`fahcon`), the half adder (`ha`), and 3 input majority (`maj3`) |
| **Tristate / enabled drivers** (`tristate`) | 13 | Tristate / enabled drivers whose output can go high impedance: `einvn`/`einvp` (enabled inverters, active low / active high enable) and `ebufn` (enabled buffer) |
| **Flip flops** (`flipflop`) | 45 | Edge triggered D flip flops, the sequential backbone |
| **Latches** (`latch`) | 23 | Level sensitive latches (`dlxtp`, `dlrtp`, …) and clock gating latches (`dlclkp`, `sdlclkp`) |
| **Clock & delay** (`clock_delay`) | 14 | Clock and delay elements: tuned delay buffers (`clkdlybuf4s15/18/25/50`) and metal/diffusion delay lines (`dlygate4sd*`, `dlymetal6s*`) |
| **Tie & probe** (`tie_probe`) | 3 | Tie and probe cells: `conb` (constant tie high / tie low source) and `probe_p`/`probec_p` (DFT probe points) |
| **Fill / physical** (`fill_phys`) | 16 | Non logic physical cells: `fill` (filler), `decap` (decoupling capacitance), `tap`/`tapvgnd`/`tapvpwrvgnd` (well & substrate taps), `diode` (antenna diode), and `macro_sparecell` |
| **Low power / level shift / isolation** (`lpflow_pwr`) | 34 | Low power flow cells: level shifters (`lpflow_lsbuf_lh`, low→high voltage domain), input isolation (`lpflow_inputiso`, `inputisolatch`), power gating / retention, and `*isowell*` isolated well variants |

---

## Inverters, `inverter` (16 cells)

The fundamental gate: one PMOS pull up + one NMOS pull down inverting the input. Includes clock inverters (`clkinv`, sized for clock nets), a low power, low leakage variant (`clkinvlp`), and `bufinv` (buffered inverter). Drive strengths run `_1`…`_16`. Simplest cells in the library; they place and route trivially.

**Cells** (base function → drive strengths):

- `bufinv`, _8, _16
- `clkinv`, _1, _2, _4, _8, _16
- `clkinvlp`, _2, _4
- `inv`, _1, _2, _4, _6, _8, _12, _16

## Buffers, `buffer` (14 cells)

Two cascaded inverters (net non inverting) that restore edge rate and drive large loads. `clkbuf` distributes clocks; `bufbuf` is an extra strong buffer. Also easy to build.

**Cells** (base function → drive strengths):

- `buf`, _1, _2, _4, _6, _8, _12, _16
- `bufbuf`, _8, _16
- `clkbuf`, _1, _2, _4, _8, _16

## AND / OR gates, `and_or` (44 cells)

Primitive AND / OR gates, 2 to 4 inputs, plus input inverted variants (trailing `b`/`bb` invert one/two inputs, e.g. `and2b`, `or4bb`). Because static CMOS is naturally inverting, these are physically a NAND/NOR core followed by an inverter, i.e. two stage cells.

**Cells** (base function → drive strengths):

- `and2`, _0, _1, _2, _4
- `and2b`, _1, _2, _4
- `and3`, _1, _2, _4
- `and3b`, _1, _2, _4
- `and4`, _1, _2, _4
- `and4b`, _1, _2, _4
- `and4bb`, _1, _2, _4
- `or2`, _0, _1, _2, _4
- `or2b`, _1, _2, _4
- `or3`, _1, _2, _4
- `or3b`, _1, _2, _4
- `or4`, _1, _2, _4
- `or4b`, _1, _2, _4
- `or4bb`, _1, _2, _4

## NAND / NOR gates, `nand_nor` (44 cells)

The natural single stage CMOS primitives: NAND (series NMOS / parallel PMOS) and NOR (its dual). 2 to 4 inputs plus `b`/`bb` inverted input variants. Workhorse logic; almost always route easily.

**Cells** (base function → drive strengths):

- `nand2`, _1, _2, _4, _8
- `nand2b`, _1, _2, _4
- `nand3`, _1, _2, _4
- `nand3b`, _1, _2, _4
- `nand4`, _1, _2, _4
- `nand4b`, _1, _2, _4
- `nand4bb`, _1, _2, _4
- `nor2`, _1, _2, _4, _8
- `nor2b`, _1, _2, _4
- `nor3`, _1, _2, _4
- `nor3b`, _1, _2, _4
- `nor4`, _1, _2, _4
- `nor4b`, _1, _2, _4
- `nor4bb`, _1, _2, _4

## AND OR Invert (AOI), `aoi` (69 cells)

AND OR Invert compound gates, the **largest family**. The name `aXYZ…o[i]` encodes the sizes of the AND groups feeding an OR then an (optional) invert: e.g. `a21oi` = (2 input AND) OR (1 input), inverted. Single stage static CMOS. The high drive members are the routability stressers.

**Cells** (base function → drive strengths):

- **`a2111o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR B1 OR C1 OR D1.
- **`a2111oi`** (drives _0, _1, _2, _4)<br>
  Y = (A1 AND A2) OR B1 OR C1 OR D1, then inverted.
- **`a211o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR B1 OR C1.
- **`a211oi`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR B1 OR C1, then inverted.
- **`a21bo`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR B1 (with 1 input(s) inverted first).
- **`a21boi`** (drives _0, _1, _2, _4)<br>
  Y = (A1 AND A2) OR B1, then inverted (with 1 input(s) inverted first).
- **`a21o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR B1.
- **`a21oi`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR B1, then inverted.
- **`a221o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR (B1 AND B2) OR C1.
- **`a221oi`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR (B1 AND B2) OR C1, then inverted.
- **`a222oi`** (drives _1)<br>
  Y = (A1 AND A2) OR (B1 AND B2) OR (C1 AND C2), then inverted.
- **`a22o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR (B1 AND B2).
- **`a22oi`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR (B1 AND B2), then inverted.
- **`a2bb2o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR (B1 AND B2) (with 2 input(s) inverted first).
- **`a2bb2oi`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2) OR (B1 AND B2), then inverted (with 2 input(s) inverted first).
- **`a311o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2 AND A3) OR B1 OR C1.
- **`a311oi`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2 AND A3) OR B1 OR C1, then inverted.
- **`a31o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2 AND A3) OR B1.
- **`a31oi`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2 AND A3) OR B1, then inverted.
- **`a32o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2 AND A3) OR (B1 AND B2).
- **`a32oi`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2 AND A3) OR (B1 AND B2), then inverted.
- **`a41o`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2 AND A3 AND A4) OR B1.
- **`a41oi`** (drives _1, _2, _4)<br>
  Y = (A1 AND A2 AND A3 AND A4) OR B1, then inverted.

## OR AND Invert (OAI), `oai` (68 cells)

OR AND Invert, the exact dual of AOI: OR groups feed an AND then an invert (`o21ai`, `o221a`, …). Same structure and same placement/routing challenges as the AOI family.

**Cells** (base function → drive strengths):

- **`o2111a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND B1 AND C1 AND D1.
- **`o2111ai`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND B1 AND C1 AND D1, then inverted.
- **`o211a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND B1 AND C1.
- **`o211ai`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND B1 AND C1, then inverted.
- **`o21a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND B1.
- **`o21ai`** (drives _0, _1, _2, _4)<br>
  Y = (A1 OR A2) AND B1, then inverted.
- **`o21ba`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND B1 (with 1 input(s) inverted first).
- **`o21bai`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND B1, then inverted (with 1 input(s) inverted first).
- **`o221a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND (B1 OR B2) AND C1.
- **`o221ai`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND (B1 OR B2) AND C1, then inverted.
- **`o22a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND (B1 OR B2).
- **`o22ai`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND (B1 OR B2), then inverted.
- **`o2bb2a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND (B1 OR B2) (with 2 input(s) inverted first).
- **`o2bb2ai`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2) AND (B1 OR B2), then inverted (with 2 input(s) inverted first).
- **`o311a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2 OR A3) AND B1 AND C1.
- **`o311ai`** (drives _0, _1, _2, _4)<br>
  Y = (A1 OR A2 OR A3) AND B1 AND C1, then inverted.
- **`o31a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2 OR A3) AND B1.
- **`o31ai`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2 OR A3) AND B1, then inverted.
- **`o32a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2 OR A3) AND (B1 OR B2).
- **`o32ai`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2 OR A3) AND (B1 OR B2), then inverted.
- **`o41a`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2 OR A3 OR A4) AND B1.
- **`o41ai`** (drives _1, _2, _4)<br>
  Y = (A1 OR A2 OR A3 OR A4) AND B1, then inverted.

## XOR / XNOR, `xor_xnor` (12 cells)

Exclusive OR / XNOR, 2 to 3 inputs. Notable because XOR needs both true and complemented versions of its inputs internally, so it packs more transistors and denser internal routing than the input count suggests.

**Cells** (base function → drive strengths):

- **`xnor2`** (drives _1, _2, _4)<br>
  2 input XNOR: high when the two inputs match.
- **`xnor3`** (drives _1, _2, _4)<br>
  3 input XNOR: even parity of three inputs.
- **`xor2`** (drives _1, _2, _4)<br>
  2 input exclusive OR: high when the two inputs differ.
- **`xor3`** (drives _1, _2, _4)<br>
  3 input XOR: high on odd parity of the three inputs.

## Multiplexers, `mux` (10 cells)

2:1 and 4:1 multiplexers (`mux2`, `mux4`) plus inverting `mux2i`. Select logic driving a pass/tristate structure; internal routing is moderately dense.

**Cells** (base function → drive strengths):

- **`mux2`** (drives _1, _2, _4, _8)<br>
  2 to 1 multiplexer: passes A0 or A1 depending on the select.
- **`mux2i`** (drives _1, _2, _4)<br>
  2 to 1 multiplexer with an inverted output.
- **`mux4`** (drives _1, _2, _4)<br>
  4 to 1 multiplexer: picks one of four inputs with two select bits.

## Adders / majority, `adder` (12 cells)

Full adders (`fa`, `fah`, and carry in and carry out flavors `fahcin`/`fahcon`), the half adder (`ha`), and 3 input majority (`maj3`). Multi output (sum + carry) compound cells, among the harder combinational cells to place and route.

**Cells** (base function → drive strengths):

- **`fa`** (drives _1, _2, _4)<br>
  Full adder: sum and carry out of A, B, and a carry in.
- **`fah`** (drives _1)<br>
  Full adder tuned for a fast carry chain.
- **`fahcin`** (drives _1)<br>
  Full adder with a dedicated carry in path.
- **`fahcon`** (drives _1)<br>
  Full adder with a dedicated carry out path.
- **`ha`** (drives _1, _2, _4)<br>
  Half adder: sum (A xor B) and carry (A and B) of two bits.
- **`maj3`** (drives _1, _2, _4)<br>
  Majority: the output is whatever value at least two of the three inputs hold.

## Tristate / enabled drivers, `tristate` (13 cells)

Tristate / enabled drivers whose output can go high impedance: `einvn`/`einvp` (enabled inverters, active low / active high enable) and `ebufn` (enabled buffer). Used to drive shared buses.

**Cells** (base function → drive strengths):

- **`ebufn`** (drives _1, _2, _4, _8)<br>
  Tristate buffer (non inverting), active low enable, for shared buses.
- **`einvn`** (drives _0, _1, _2, _4, _8)<br>
  Tristate inverter, active low enable: inverts A, or floats (high impedance) when off.
- **`einvp`** (drives _1, _2, _4, _8)<br>
  Tristate inverter, active high enable.

## Flip flops, `flipflop` (45 cells)

Edge triggered D flip flops, the sequential backbone. Prefixes: `df` base; leading `s` = **scan** for test (adds `SCD` and `SCE`: when scan enable `SCE` is high the flop captures the scan input `SCD` instead of `D`, so flops chain into a shift register that shifts test patterns in and results out), `e` = **enable** (adds `DE`: the flop loads `D` on the clock edge only when `DE` is high, otherwise it holds), `se` = both. Suffix letters encode reset/set and clock/output polarity (`r`=reset, `s`=set, `bb`=both, `t/p/n/b` = clock & output flavors). Each is ~20 to 30 transistors (master + slave latch + clock + set/reset), which is why **this family dominates the un converged set**, it is placement bound, not area bound.

**Cells** (base function → drive strengths):

- **`dfbbn`** (drives _1, _2)<br>
  D flip flop, negative edge clock with async set and reset.
- **`dfbbp`** (drives _1)<br>
  D flip flop, positive edge clock with async set and reset.
- **`dfrbp`** (drives _1, _2)<br>
  D flip flop, positive edge clock, true and inverted outputs with async reset (Q to 0).
- **`dfrtn`** (drives _1)<br>
  D flip flop, negative edge clock, true output with async reset (Q to 0).
- **`dfrtp`** (drives _1, _2, _4)<br>
  D flip flop, positive edge clock, true output with async reset (Q to 0).
- **`dfsbp`** (drives _1, _2)<br>
  D flip flop, positive edge clock, true and inverted outputs with async set (Q to 1).
- **`dfstp`** (drives _1, _2, _4)<br>
  D flip flop, positive edge clock, true output with async set (Q to 1).
- **`dfxbp`** (drives _1, _2)<br>
  D flip flop, positive edge clock, true and inverted outputs.
- **`dfxtp`** (drives _1, _2, _4)<br>
  D flip flop, positive edge clock, true output.
- **`edfxbp`** (drives _1)<br>
  enable D flip flop, positive edge clock, true and inverted outputs.
- **`edfxtp`** (drives _1)<br>
  enable D flip flop, positive edge clock, true output.
- **`sdfbbn`** (drives _1, _2)<br>
  scan D flip flop, negative edge clock with async set and reset.
- **`sdfbbp`** (drives _1)<br>
  scan D flip flop, positive edge clock with async set and reset.
- **`sdfrbp`** (drives _1, _2)<br>
  scan D flip flop, positive edge clock, true and inverted outputs with async reset (Q to 0).
- **`sdfrtn`** (drives _1)<br>
  scan D flip flop, negative edge clock, true output with async reset (Q to 0).
- **`sdfrtp`** (drives _1, _2, _4)<br>
  scan D flip flop, positive edge clock, true output with async reset (Q to 0).
- **`sdfsbp`** (drives _1, _2)<br>
  scan D flip flop, positive edge clock, true and inverted outputs with async set (Q to 1).
- **`sdfstp`** (drives _1, _2, _4)<br>
  scan D flip flop, positive edge clock, true output with async set (Q to 1).
- **`sdfxbp`** (drives _1, _2)<br>
  scan D flip flop, positive edge clock, true and inverted outputs.
- **`sdfxtp`** (drives _1, _2, _4)<br>
  scan D flip flop, positive edge clock, true output.
- **`sedfxbp`** (drives _1, _2)<br>
  scan plus enable D flip flop, positive edge clock, true and inverted outputs.
- **`sedfxtp`** (drives _1, _2, _4)<br>
  scan plus enable D flip flop, positive edge clock, true output.

## Latches, `latch` (23 cells)

Level sensitive latches (`dlxtp`, `dlrtp`, …) and clock gating latches (`dlclkp`, `sdlclkp`). Effectively half a flip flop (a single latch), but still multi transistor; the clock gating latches are central to power management.

**Cells** (base function → drive strengths):

- **`dlclkp`** (drives _1, _2, _4)<br>
  Clock gating latch: makes a glitch free gated clock enable.
- **`dlrbn`** (drives _1, _2)<br>
  D latch with reset, negative level, true and inverted outputs.
- **`dlrbp`** (drives _1, _2)<br>
  D latch with reset, true and inverted outputs.
- **`dlrtn`** (drives _1, _2, _4)<br>
  D latch with reset, negative level.
- **`dlrtp`** (drives _1, _2, _4)<br>
  D latch with async reset (Q to 0).
- **`dlxbn`** (drives _1, _2)<br>
  D latch, negative level, true and inverted outputs.
- **`dlxbp`** (drives _1)<br>
  D latch with true and inverted outputs.
- **`dlxtn`** (drives _1, _2, _4)<br>
  D latch, transparent while the clock is low (negative level).
- **`dlxtp`** (drives _1)<br>
  D latch, transparent while the clock is high, true output.
- **`sdlclkp`** (drives _1, _2, _4)<br>
  Clock gating latch with scan support.

## Clock & delay, `clock_delay` (14 cells)

Clock and delay elements: tuned delay buffers (`clkdlybuf4s15/18/25/50`) and metal/diffusion delay lines (`dlygate4sd*`, `dlymetal6s*`). Used to tune clock skew and fix hold. Structurally simple but geometry specific.

**Cells** (base function → drive strengths):

- **`clkdlybuf4s15`** (drives _1, _2)<br>
  Clock delay buffer, 4 stages, shortest fixed delay.
- **`clkdlybuf4s18`** (drives _1, _2)<br>
  Clock delay buffer, 4 stages, short fixed delay.
- **`clkdlybuf4s25`** (drives _1, _2)<br>
  Clock delay buffer, 4 stages, medium fixed delay.
- **`clkdlybuf4s50`** (drives _1, _2)<br>
  Clock delay buffer, 4 stages, longest fixed delay.
- **`dlygate4sd1`** (drives _1)<br>
  Delay gate, roughly 1 unit of fixed delay.
- **`dlygate4sd2`** (drives _1)<br>
  Delay gate, roughly 2 units of fixed delay.
- **`dlygate4sd3`** (drives _1)<br>
  Delay gate, roughly 3 units of fixed delay.
- **`dlymetal6s2s`** (drives _1)<br>
  Metal delay line, 6 stages, short routing delay.
- **`dlymetal6s4s`** (drives _1)<br>
  Metal delay line, 6 stages, medium routing delay.
- **`dlymetal6s6s`** (drives _1)<br>
  Metal delay line, 6 stages, long routing delay.

## Tie & probe, `tie_probe` (3 cells)

Tie and probe cells: `conb` (constant tie high / tie low source) and `probe_p`/`probec_p` (DFT probe points). `conb` is the cell whose netlist contains an R/C device that lclayout's SPICE reader currently can't parse.

**Cells** (base function → drive strengths):

- **`conb`** (drives _1)<br>
  Tie cell: buffered constant 1 (HI) and 0 (LO) outputs for unused inputs.
- **`probec_p`** (drives _8)<br>
  Clock probe point for test access.
- **`probe_p`** (drives _8)<br>
  Probe point for design for test and debug access.

## Fill / physical, `fill_phys` (16 cells)

Non logic physical cells: `fill` (filler), `decap` (decoupling capacitance), `tap`/`tapvgnd`/`tapvpwrvgnd` (well & substrate taps), `diode` (antenna diode), and `macro_sparecell`. No signal function, they satisfy DRC, well tie, and antenna rules. Several need dedicated templates rather than routing.

**Cells** (base function → drive strengths):

- **`decap`** (drives _3, _4, _6, _8, _12)<br>
  Decoupling capacitor across the rails that steadies the supply.
- **`diode`** (drives _2)<br>
  Antenna diode that protects thin gates from charge during fabrication.
- **`fill`** (drives _1, _2, _4, _8)<br>
  Filler cell that occupies empty space to keep layout density legal.
- **`macro_sparecell`** (drives (single variant))<br>
  Spare gate left in the layout for late metal fixes.
- **`tap`** (drives _1, _2)<br>
  Well and substrate tap that pins the body voltage.
- **`tapvgnd`** (drives _1)<br>
  Substrate tap tied to ground.
- **`tapvgnd2`** (drives _1)<br>
  Substrate tap (wider) tied to ground.
- **`tapvpwrvgnd`** (drives _1)<br>
  Tap tied to both power and ground.

## Low power / level shift / isolation, `lpflow_pwr` (34 cells)

Low power flow cells: level shifters (`lpflow_lsbuf_lh`, low→high voltage domain), input isolation (`lpflow_inputiso`, `inputisolatch`), power gating / retention, and `*isowell*` isolated well variants. These span multiple voltage domains and need a second well / isolated well that the base cell template doesn't emit, a structural gap, not a routing problem.

**Cells** (base function → drive strengths):

- **`lpflow_bleeder`** (drives _1)<br>
  Bleeder that slowly drains a floating node.
- **`lpflow_clkbufkapwr`** (drives _1, _2, _4, _8, _16)<br>
  Clock buffer on always on power, for power gated regions.
- **`lpflow_clkinvkapwr`** (drives _1, _2, _4, _8, _16)<br>
  Clock inverter on always on power.
- **`lpflow_decapkapwr`** (drives _3, _4, _6, _8, _12)<br>
  Decap on the always on power rail.
- **`lpflow_inputiso0n`** (drives _1)<br>
  Input isolation gate that clamps to 0 when the domain is off (active low enable).
- **`lpflow_inputiso0p`** (drives _1)<br>
  Input isolation gate that clamps to 0 when the domain is off (active high enable).
- **`lpflow_inputiso1n`** (drives _1)<br>
  Input isolation gate that clamps to 1 when the domain is off (active low enable).
- **`lpflow_inputiso1p`** (drives _1)<br>
  Input isolation gate that clamps to 1 when the domain is off (active high enable).
- **`lpflow_inputisolatch`** (drives _1)<br>
  Input isolation latch that holds the last value when the domain powers down.
- **`lpflow_isobufsrc`** (drives _1, _2, _4, _8, _16)<br>
  Isolation buffer for a source biased domain.
- **`lpflow_isobufsrckapwr`** (drives _16)<br>
  Isolation buffer on always on power.
- **`lpflow_lsbuf_lh_hl_isowell_tap`** (drives _1, _2, _4)<br>
  Level shifter usable low to high and high to low, isolated well plus tap.
- **`lpflow_lsbuf_lh_isowell`** (drives _4)<br>
  Level shifter, low to high supply, in an isolated well.
- **`lpflow_lsbuf_lh_isowell_tap`** (drives _1, _2, _4)<br>
  Level shifter (low to high) with an isolated well and body tap.

---
_Generated by `src/cellgen/gen_cell_taxonomy.sh` from `recipes/cell_categories.tsv`._
