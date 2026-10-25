# Cell Status

Place and route status for all **437** `sky130_fd_sc_hd` cells, grouped by category.
**Status** is whether the cell builds DRC and LVS clean on the current flow (its committed recipe).
Each row links to the verbose run **log**, a **layout** render you can view in the browser, and the raw **output files** (GDS and LEF).

**301 closed, 136 open, of 437.** Last run recorded in `status/results.tsv`.

## Inverters (16)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `bufinv_16` | ✅ closed | 104 | [log](logs/bufinv_16.log) | [view](renders/bufinv_16.png) | [gds+lef](outputs/bufinv_16/) |
| `bufinv_8` | ✅ closed | 39 | [log](logs/bufinv_8.log) | [view](renders/bufinv_8.png) | [gds+lef](outputs/bufinv_8/) |
| `clkinv_1` | ✅ closed | 2 | [log](logs/clkinv_1.log) | [view](renders/clkinv_1.png) | [gds+lef](outputs/clkinv_1/) |
| `clkinv_16` | ✅ closed | 206 | [log](logs/clkinv_16.log) | [view](renders/clkinv_16.png) | [gds+lef](outputs/clkinv_16/) |
| `clkinv_2` | ✅ closed | 3 | [log](logs/clkinv_2.log) | [view](renders/clkinv_2.png) | [gds+lef](outputs/clkinv_2/) |
| `clkinv_4` | ✅ closed | 8 | [log](logs/clkinv_4.log) | [view](renders/clkinv_4.png) | [gds+lef](outputs/clkinv_4/) |
| `clkinv_8` | ✅ closed | 22 | [log](logs/clkinv_8.log) | [view](renders/clkinv_8.png) | [gds+lef](outputs/clkinv_8/) |
| `clkinvlp_2` | ✅ closed | 3 | [log](logs/clkinvlp_2.log) | [view](renders/clkinvlp_2.png) | [gds+lef](outputs/clkinvlp_2/) |
| `clkinvlp_4` | ❌ open | 4 | [log](logs/clkinvlp_4.log) | [view](renders/clkinvlp_4.png) | [gds+lef](outputs/clkinvlp_4/) |
| `inv_1` | ✅ closed | 1 | [log](logs/inv_1.log) | [view](renders/inv_1.png) | [gds+lef](outputs/inv_1/) |
| `inv_12` | ✅ closed | 19 | [log](logs/inv_12.log) | [view](renders/inv_12.png) | [gds+lef](outputs/inv_12/) |
| `inv_16` | ✅ closed | 31 | [log](logs/inv_16.log) | [view](renders/inv_16.png) | [gds+lef](outputs/inv_16/) |
| `inv_2` | ✅ closed | 2 | [log](logs/inv_2.log) | [view](renders/inv_2.png) | [gds+lef](outputs/inv_2/) |
| `inv_4` | ✅ closed | 4 | [log](logs/inv_4.log) | [view](renders/inv_4.png) | [gds+lef](outputs/inv_4/) |
| `inv_6` | ✅ closed | 7 | [log](logs/inv_6.log) | [view](renders/inv_6.png) | [gds+lef](outputs/inv_6/) |
| `inv_8` | ✅ closed | 10 | [log](logs/inv_8.log) | [view](renders/inv_8.png) | [gds+lef](outputs/inv_8/) |

## Buffers (14)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `buf_1` | ✅ closed | 3 | [log](logs/buf_1.log) | [view](renders/buf_1.png) | [gds+lef](outputs/buf_1/) |
| `buf_12` | ✅ closed | 53 | [log](logs/buf_12.log) | [view](renders/buf_12.png) | [gds+lef](outputs/buf_12/) |
| `buf_16` | ✅ closed | 93 | [log](logs/buf_16.log) | [view](renders/buf_16.png) | [gds+lef](outputs/buf_16/) |
| `buf_2` | ✅ closed | 5 | [log](logs/buf_2.log) | [view](renders/buf_2.png) | [gds+lef](outputs/buf_2/) |
| `buf_4` | ✅ closed | 7 | [log](logs/buf_4.log) | [view](renders/buf_4.png) | [gds+lef](outputs/buf_4/) |
| `buf_6` | ✅ closed | 15 | [log](logs/buf_6.log) | [view](renders/buf_6.png) | [gds+lef](outputs/buf_6/) |
| `buf_8` | ✅ closed | 30 | [log](logs/buf_8.log) | [view](renders/buf_8.png) | [gds+lef](outputs/buf_8/) |
| `bufbuf_16` | ✅ closed | 127 | [log](logs/bufbuf_16.log) | [view](renders/bufbuf_16.png) | [gds+lef](outputs/bufbuf_16/) |
| `bufbuf_8` | ✅ closed | 49 | [log](logs/bufbuf_8.log) | [view](renders/bufbuf_8.png) | [gds+lef](outputs/bufbuf_8/) |
| `clkbuf_1` | ✅ closed | 3 | [log](logs/clkbuf_1.log) | [view](renders/clkbuf_1.png) | [gds+lef](outputs/clkbuf_1/) |
| `clkbuf_16` | ✅ closed | 184 | [log](logs/clkbuf_16.log) | [view](renders/clkbuf_16.png) | [gds+lef](outputs/clkbuf_16/) |
| `clkbuf_2` | ✅ closed | 5 | [log](logs/clkbuf_2.log) | [view](renders/clkbuf_2.png) | [gds+lef](outputs/clkbuf_2/) |
| `clkbuf_4` | ✅ closed | 8 | [log](logs/clkbuf_4.log) | [view](renders/clkbuf_4.png) | [gds+lef](outputs/clkbuf_4/) |
| `clkbuf_8` | ✅ closed | 38 | [log](logs/clkbuf_8.log) | [view](renders/clkbuf_8.png) | [gds+lef](outputs/clkbuf_8/) |

## AND / OR gates (44)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `and2_0` | ✅ closed | 6 | [log](logs/and2_0.log) | [view](renders/and2_0.png) | [gds+lef](outputs/and2_0/) |
| `and2_1` | ✅ closed | 5 | [log](logs/and2_1.log) | [view](renders/and2_1.png) | [gds+lef](outputs/and2_1/) |
| `and2_2` | ✅ closed | 7 | [log](logs/and2_2.log) | [view](renders/and2_2.png) | [gds+lef](outputs/and2_2/) |
| `and2_4` | ✅ closed | 9 | [log](logs/and2_4.log) | [view](renders/and2_4.png) | [gds+lef](outputs/and2_4/) |
| `and2b_1` | ✅ closed | 10 | [log](logs/and2b_1.log) | [view](renders/and2b_1.png) | [gds+lef](outputs/and2b_1/) |
| `and2b_2` | ✅ closed | 9 | [log](logs/and2b_2.log) | [view](renders/and2b_2.png) | [gds+lef](outputs/and2b_2/) |
| `and2b_4` | ✅ closed | 16 | [log](logs/and2b_4.log) | [view](renders/and2b_4.png) | [gds+lef](outputs/and2b_4/) |
| `and3_1` | ✅ closed | 7 | [log](logs/and3_1.log) | [view](renders/and3_1.png) | [gds+lef](outputs/and3_1/) |
| `and3_2` | ✅ closed | 9 | [log](logs/and3_2.log) | [view](renders/and3_2.png) | [gds+lef](outputs/and3_2/) |
| `and3_4` | ✅ closed | 12 | [log](logs/and3_4.log) | [view](renders/and3_4.png) | [gds+lef](outputs/and3_4/) |
| `and3b_1` | ✅ closed | 11 | [log](logs/and3b_1.log) | [view](renders/and3b_1.png) | [gds+lef](outputs/and3b_1/) |
| `and3b_2` | ✅ closed | 13 | [log](logs/and3b_2.log) | [view](renders/and3b_2.png) | [gds+lef](outputs/and3b_2/) |
| `and3b_4` | ✅ closed | 17 | [log](logs/and3b_4.log) | [view](renders/and3b_4.png) | [gds+lef](outputs/and3b_4/) |
| `and4_1` | ✅ closed | 9 | [log](logs/and4_1.log) | [view](renders/and4_1.png) | [gds+lef](outputs/and4_1/) |
| `and4_2` | ✅ closed | 12 | [log](logs/and4_2.log) | [view](renders/and4_2.png) | [gds+lef](outputs/and4_2/) |
| `and4_4` | ✅ closed | 15 | [log](logs/and4_4.log) | [view](renders/and4_4.png) | [gds+lef](outputs/and4_4/) |
| `and4b_1` | ✅ closed | 15 | [log](logs/and4b_1.log) | [view](renders/and4b_1.png) | [gds+lef](outputs/and4b_1/) |
| `and4b_2` | ✅ closed | 18 | [log](logs/and4b_2.log) | [view](renders/and4b_2.png) | [gds+lef](outputs/and4b_2/) |
| `and4b_4` | ✅ closed | 19 | [log](logs/and4b_4.log) | [view](renders/and4b_4.png) | [gds+lef](outputs/and4b_4/) |
| `and4bb_1` | ✅ closed | 30 | [log](logs/and4bb_1.log) | [view](renders/and4bb_1.png) | [gds+lef](outputs/and4bb_1/) |
| `and4bb_2` | ❌ open | 25 | [log](logs/and4bb_2.log) | [view](renders/and4bb_2.png) | [gds+lef](outputs/and4bb_2/) |
| `and4bb_4` | ✅ closed | 50 | [log](logs/and4bb_4.log) | [view](renders/and4bb_4.png) | [gds+lef](outputs/and4bb_4/) |
| `or2_0` | ✅ closed | 5 | [log](logs/or2_0.log) | [view](renders/or2_0.png) | [gds+lef](outputs/or2_0/) |
| `or2_1` | ✅ closed | 5 | [log](logs/or2_1.log) | [view](renders/or2_1.png) | [gds+lef](outputs/or2_1/) |
| `or2_2` | ✅ closed | 6 | [log](logs/or2_2.log) | [view](renders/or2_2.png) | [gds+lef](outputs/or2_2/) |
| `or2_4` | ✅ closed | 9 | [log](logs/or2_4.log) | [view](renders/or2_4.png) | [gds+lef](outputs/or2_4/) |
| `or2b_1` | ❌ open | 9 | [log](logs/or2b_1.log) | [view](renders/or2b_1.png) | [gds+lef](outputs/or2b_1/) |
| `or2b_2` | ✅ closed | 9 | [log](logs/or2b_2.log) | [view](renders/or2b_2.png) | [gds+lef](outputs/or2b_2/) |
| `or2b_4` | ✅ closed | 16 | [log](logs/or2b_4.log) | [view](renders/or2b_4.png) | [gds+lef](outputs/or2b_4/) |
| `or3_1` | ✅ closed | 6 | [log](logs/or3_1.log) | [view](renders/or3_1.png) | [gds+lef](outputs/or3_1/) |
| `or3_2` | ✅ closed | 8 | [log](logs/or3_2.log) | [view](renders/or3_2.png) | [gds+lef](outputs/or3_2/) |
| `or3_4` | ✅ closed | 14 | [log](logs/or3_4.log) | [view](renders/or3_4.png) | [gds+lef](outputs/or3_4/) |
| `or3b_1` | ✅ closed | 12 | [log](logs/or3b_1.log) | [view](renders/or3b_1.png) | [gds+lef](outputs/or3b_1/) |
| `or3b_2` | ✅ closed | 22 | [log](logs/or3b_2.log) | [view](renders/or3b_2.png) | [gds+lef](outputs/or3b_2/) |
| `or3b_4` | ✅ closed | 20 | [log](logs/or3b_4.log) | [view](renders/or3b_4.png) | [gds+lef](outputs/or3b_4/) |
| `or4_1` | ✅ closed | 9 | [log](logs/or4_1.log) | [view](renders/or4_1.png) | [gds+lef](outputs/or4_1/) |
| `or4_2` | ✅ closed | 11 | [log](logs/or4_2.log) | [view](renders/or4_2.png) | [gds+lef](outputs/or4_2/) |
| `or4_4` | ✅ closed | 18 | [log](logs/or4_4.log) | [view](renders/or4_4.png) | [gds+lef](outputs/or4_4/) |
| `or4b_1` | ✅ closed | 18 | [log](logs/or4b_1.log) | [view](renders/or4b_1.png) | [gds+lef](outputs/or4b_1/) |
| `or4b_2` | ✅ closed | 20 | [log](logs/or4b_2.log) | [view](renders/or4b_2.png) | [gds+lef](outputs/or4b_2/) |
| `or4b_4` | ✅ closed | 28 | [log](logs/or4b_4.log) | [view](renders/or4b_4.png) | [gds+lef](outputs/or4b_4/) |
| `or4bb_1` | ✅ closed | 24 | [log](logs/or4bb_1.log) | [view](renders/or4bb_1.png) | [gds+lef](outputs/or4bb_1/) |
| `or4bb_2` | ✅ closed | 35 | [log](logs/or4bb_2.log) | [view](renders/or4bb_2.png) | [gds+lef](outputs/or4bb_2/) |
| `or4bb_4` | ✅ closed | 31 | [log](logs/or4bb_4.log) | [view](renders/or4bb_4.png) | [gds+lef](outputs/or4bb_4/) |

## NAND / NOR gates (44)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `nand2_1` | ✅ closed | 2 | [log](logs/nand2_1.log) | [view](renders/nand2_1.png) | [gds+lef](outputs/nand2_1/) |
| `nand2_2` | ✅ closed | 6 | [log](logs/nand2_2.log) | [view](renders/nand2_2.png) | [gds+lef](outputs/nand2_2/) |
| `nand2_4` | ❌ open | 16 | [log](logs/nand2_4.log) | [view](renders/nand2_4.png) | [gds+lef](outputs/nand2_4/) |
| `nand2_8` | ✅ closed | 117 | [log](logs/nand2_8.log) | [view](renders/nand2_8.png) | [gds+lef](outputs/nand2_8/) |
| `nand2b_1` | ✅ closed | 5 | [log](logs/nand2b_1.log) | [view](renders/nand2b_1.png) | [gds+lef](outputs/nand2b_1/) |
| `nand2b_2` | ✅ closed | 8 | [log](logs/nand2b_2.log) | [view](renders/nand2b_2.png) | [gds+lef](outputs/nand2b_2/) |
| `nand2b_4` | ✅ closed | 24 | [log](logs/nand2b_4.log) | [view](renders/nand2b_4.png) | [gds+lef](outputs/nand2b_4/) |
| `nand3_1` | ✅ closed | 3 | [log](logs/nand3_1.log) | [view](renders/nand3_1.png) | [gds+lef](outputs/nand3_1/) |
| `nand3_2` | ✅ closed | 239 | [log](logs/nand3_2.log) | [view](renders/nand3_2.png) | [gds+lef](outputs/nand3_2/) |
| `nand3_4` | ✅ closed | 41 | [log](logs/nand3_4.log) | [view](renders/nand3_4.png) | [gds+lef](outputs/nand3_4/) |
| `nand3b_1` | ✅ closed | 7 | [log](logs/nand3b_1.log) | [view](renders/nand3b_1.png) | [gds+lef](outputs/nand3b_1/) |
| `nand3b_2` | ✅ closed | 17 | [log](logs/nand3b_2.log) | [view](renders/nand3b_2.png) | [gds+lef](outputs/nand3b_2/) |
| `nand3b_4` | ❌ open | 61 | [log](logs/nand3b_4.log) | [view](renders/nand3b_4.png) | [gds+lef](outputs/nand3b_4/) |
| `nand4_1` | ✅ closed | 4 | [log](logs/nand4_1.log) | [view](renders/nand4_1.png) | [gds+lef](outputs/nand4_1/) |
| `nand4_2` | ✅ closed | 40 | [log](logs/nand4_2.log) | [view](renders/nand4_2.png) | [gds+lef](outputs/nand4_2/) |
| `nand4_4` | ✅ closed | 169 | [log](logs/nand4_4.log) | [view](renders/nand4_4.png) | [gds+lef](outputs/nand4_4/) |
| `nand4b_1` | ✅ closed | 8 | [log](logs/nand4b_1.log) | [view](renders/nand4b_1.png) | [gds+lef](outputs/nand4b_1/) |
| `nand4b_2` | ✅ closed | 76 | [log](logs/nand4b_2.log) | [view](renders/nand4b_2.png) | [gds+lef](outputs/nand4b_2/) |
| `nand4b_4` | ❌ open | 300 | [log](logs/nand4b_4.log) | [view](renders/nand4b_4.png) | [gds+lef](outputs/nand4b_4/) |
| `nand4bb_1` | ✅ closed | 45 | [log](logs/nand4bb_1.log) | [view](renders/nand4bb_1.png) | [gds+lef](outputs/nand4bb_1/) |
| `nand4bb_2` | ✅ closed | 92 | [log](logs/nand4bb_2.log) | [view](renders/nand4bb_2.png) | [gds+lef](outputs/nand4bb_2/) |
| `nand4bb_4` | ❌ open | 300 | [log](logs/nand4bb_4.log) | [view](renders/nand4bb_4.png) | [gds+lef](outputs/nand4bb_4/) |
| `nor2_1` | ✅ closed | 7 | [log](logs/nor2_1.log) | [view](renders/nor2_1.png) | [gds+lef](outputs/nor2_1/) |
| `nor2_2` | ✅ closed | 22 | [log](logs/nor2_2.log) | [view](renders/nor2_2.png) | [gds+lef](outputs/nor2_2/) |
| `nor2_4` | ✅ closed | 20 | [log](logs/nor2_4.log) | [view](renders/nor2_4.png) | [gds+lef](outputs/nor2_4/) |
| `nor2_8` | ✅ closed | 53 | [log](logs/nor2_8.log) | [view](renders/nor2_8.png) | [gds+lef](outputs/nor2_8/) |
| `nor2b_1` | ✅ closed | 6 | [log](logs/nor2b_1.log) | [view](renders/nor2b_1.png) | [gds+lef](outputs/nor2b_1/) |
| `nor2b_2` | ✅ closed | 12 | [log](logs/nor2b_2.log) | [view](renders/nor2b_2.png) | [gds+lef](outputs/nor2b_2/) |
| `nor2b_4` | ✅ closed | 22 | [log](logs/nor2b_4.log) | [view](renders/nor2b_4.png) | [gds+lef](outputs/nor2b_4/) |
| `nor3_1` | ✅ closed | 3 | [log](logs/nor3_1.log) | [view](renders/nor3_1.png) | [gds+lef](outputs/nor3_1/) |
| `nor3_2` | ✅ closed | 8 | [log](logs/nor3_2.log) | [view](renders/nor3_2.png) | [gds+lef](outputs/nor3_2/) |
| `nor3_4` | ✅ closed | 59 | [log](logs/nor3_4.log) | [view](renders/nor3_4.png) | [gds+lef](outputs/nor3_4/) |
| `nor3b_1` | ✅ closed | 8 | [log](logs/nor3b_1.log) | [view](renders/nor3b_1.png) | [gds+lef](outputs/nor3b_1/) |
| `nor3b_2` | ✅ closed | 13 | [log](logs/nor3b_2.log) | [view](renders/nor3b_2.png) | [gds+lef](outputs/nor3b_2/) |
| `nor3b_4` | ✅ closed | 34 | [log](logs/nor3b_4.log) | [view](renders/nor3b_4.png) | [gds+lef](outputs/nor3b_4/) |
| `nor4_1` | ✅ closed | 4 | [log](logs/nor4_1.log) | [view](renders/nor4_1.png) | [gds+lef](outputs/nor4_1/) |
| `nor4_2` | ✅ closed | 17 | [log](logs/nor4_2.log) | [view](renders/nor4_2.png) | [gds+lef](outputs/nor4_2/) |
| `nor4_4` | ✅ closed | 62 | [log](logs/nor4_4.log) | [view](renders/nor4_4.png) | [gds+lef](outputs/nor4_4/) |
| `nor4b_1` | ✅ closed | 9 | [log](logs/nor4b_1.log) | [view](renders/nor4b_1.png) | [gds+lef](outputs/nor4b_1/) |
| `nor4b_2` | ✅ closed | 56 | [log](logs/nor4b_2.log) | [view](renders/nor4b_2.png) | [gds+lef](outputs/nor4b_2/) |
| `nor4b_4` | ✅ closed | 199 | [log](logs/nor4b_4.log) | [view](renders/nor4b_4.png) | [gds+lef](outputs/nor4b_4/) |
| `nor4bb_1` | ✅ closed | 14 | [log](logs/nor4bb_1.log) | [view](renders/nor4bb_1.png) | [gds+lef](outputs/nor4bb_1/) |
| `nor4bb_2` | ✅ closed | 22 | [log](logs/nor4bb_2.log) | [view](renders/nor4bb_2.png) | [gds+lef](outputs/nor4bb_2/) |
| `nor4bb_4` | ❌ open | 300 | [log](logs/nor4bb_4.log) | [view](renders/nor4bb_4.png) | [gds+lef](outputs/nor4bb_4/) |

## AND OR Invert (AOI) (69)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `a2111o_1` | ✅ closed | 11 | [log](logs/a2111o_1.log) | [view](renders/a2111o_1.png) | [gds+lef](outputs/a2111o_1/) |
| `a2111o_2` | ✅ closed | 13 | [log](logs/a2111o_2.log) | [view](renders/a2111o_2.png) | [gds+lef](outputs/a2111o_2/) |
| `a2111o_4` | ✅ closed | 201 | [log](logs/a2111o_4.log) | [view](renders/a2111o_4.png) | [gds+lef](outputs/a2111o_4/) |
| `a2111oi_0` | ✅ closed | 9 | [log](logs/a2111oi_0.log) | [view](renders/a2111oi_0.png) | [gds+lef](outputs/a2111oi_0/) |
| `a2111oi_1` | ✅ closed | 5 | [log](logs/a2111oi_1.log) | [view](renders/a2111oi_1.png) | [gds+lef](outputs/a2111oi_1/) |
| `a2111oi_2` | ✅ closed | 39 | [log](logs/a2111oi_2.log) | [view](renders/a2111oi_2.png) | [gds+lef](outputs/a2111oi_2/) |
| `a2111oi_4` | ✅ closed | 172 | [log](logs/a2111oi_4.log) | [view](renders/a2111oi_4.png) | [gds+lef](outputs/a2111oi_4/) |
| `a211o_1` | ✅ closed | 9 | [log](logs/a211o_1.log) | [view](renders/a211o_1.png) | [gds+lef](outputs/a211o_1/) |
| `a211o_2` | ✅ closed | 12 | [log](logs/a211o_2.log) | [view](renders/a211o_2.png) | [gds+lef](outputs/a211o_2/) |
| `a211o_4` | ✅ closed | 71 | [log](logs/a211o_4.log) | [view](renders/a211o_4.png) | [gds+lef](outputs/a211o_4/) |
| `a211oi_1` | ✅ closed | 4 | [log](logs/a211oi_1.log) | [view](renders/a211oi_1.png) | [gds+lef](outputs/a211oi_1/) |
| `a211oi_2` | ✅ closed | 26 | [log](logs/a211oi_2.log) | [view](renders/a211oi_2.png) | [gds+lef](outputs/a211oi_2/) |
| `a211oi_4` | ✅ closed | 125 | [log](logs/a211oi_4.log) | [view](renders/a211oi_4.png) | [gds+lef](outputs/a211oi_4/) |
| `a21bo_1` | ✅ closed | 12 | [log](logs/a21bo_1.log) | [view](renders/a21bo_1.png) | [gds+lef](outputs/a21bo_1/) |
| `a21bo_2` | ✅ closed | 13 | [log](logs/a21bo_2.log) | [view](renders/a21bo_2.png) | [gds+lef](outputs/a21bo_2/) |
| `a21bo_4` | ✅ closed | 26 | [log](logs/a21bo_4.log) | [view](renders/a21bo_4.png) | [gds+lef](outputs/a21bo_4/) |
| `a21boi_0` | ✅ closed | 8 | [log](logs/a21boi_0.log) | [view](renders/a21boi_0.png) | [gds+lef](outputs/a21boi_0/) |
| `a21boi_1` | ✅ closed | 10 | [log](logs/a21boi_1.log) | [view](renders/a21boi_1.png) | [gds+lef](outputs/a21boi_1/) |
| `a21boi_2` | ❌ open | 32 | [log](logs/a21boi_2.log) | [view](renders/a21boi_2.png) | [gds+lef](outputs/a21boi_2/) |
| `a21boi_4` | ✅ closed | 64 | [log](logs/a21boi_4.log) | [view](renders/a21boi_4.png) | [gds+lef](outputs/a21boi_4/) |
| `a21o_1` | ✅ closed | 6 | [log](logs/a21o_1.log) | [view](renders/a21o_1.png) | [gds+lef](outputs/a21o_1/) |
| `a21o_2` | ✅ closed | 7 | [log](logs/a21o_2.log) | [view](renders/a21o_2.png) | [gds+lef](outputs/a21o_2/) |
| `a21o_4` | ✅ closed | 19 | [log](logs/a21o_4.log) | [view](renders/a21o_4.png) | [gds+lef](outputs/a21o_4/) |
| `a21oi_1` | ✅ closed | 3 | [log](logs/a21oi_1.log) | [view](renders/a21oi_1.png) | [gds+lef](outputs/a21oi_1/) |
| `a21oi_2` | ✅ closed | 11 | [log](logs/a21oi_2.log) | [view](renders/a21oi_2.png) | [gds+lef](outputs/a21oi_2/) |
| `a21oi_4` | ✅ closed | 51 | [log](logs/a21oi_4.log) | [view](renders/a21oi_4.png) | [gds+lef](outputs/a21oi_4/) |
| `a221o_1` | ✅ closed | 24 | [log](logs/a221o_1.log) | [view](renders/a221o_1.png) | [gds+lef](outputs/a221o_1/) |
| `a221o_2` | ✅ closed | 40 | [log](logs/a221o_2.log) | [view](renders/a221o_2.png) | [gds+lef](outputs/a221o_2/) |
| `a221o_4` | ❌ open | 285 | [log](logs/a221o_4.log) | [view](renders/a221o_4.png) | [gds+lef](outputs/a221o_4/) |
| `a221oi_1` | ✅ closed | 8 | [log](logs/a221oi_1.log) | [view](renders/a221oi_1.png) | [gds+lef](outputs/a221oi_1/) |
| `a221oi_2` | ✅ closed | 56 | [log](logs/a221oi_2.log) | [view](renders/a221oi_2.png) | [gds+lef](outputs/a221oi_2/) |
| `a221oi_4` | ❌ open | 300 | [log](logs/a221oi_4.log) | [view](renders/a221oi_4.png) | [gds+lef](outputs/a221oi_4/) |
| `a222oi_1` | ✅ closed | 18 | [log](logs/a222oi_1.log) | [view](renders/a222oi_1.png) | [gds+lef](outputs/a222oi_1/) |
| `a22o_1` | ✅ closed | 8 | [log](logs/a22o_1.log) | [view](renders/a22o_1.png) | [gds+lef](outputs/a22o_1/) |
| `a22o_2` | ✅ closed | 10 | [log](logs/a22o_2.log) | [view](renders/a22o_2.png) | [gds+lef](outputs/a22o_2/) |
| `a22o_4` | ✅ closed | 49 | [log](logs/a22o_4.log) | [view](renders/a22o_4.png) | [gds+lef](outputs/a22o_4/) |
| `a22oi_1` | ✅ closed | 6 | [log](logs/a22oi_1.log) | [view](renders/a22oi_1.png) | [gds+lef](outputs/a22oi_1/) |
| `a22oi_2` | ✅ closed | 21 | [log](logs/a22oi_2.log) | [view](renders/a22oi_2.png) | [gds+lef](outputs/a22oi_2/) |
| `a22oi_4` | ✅ closed | 124 | [log](logs/a22oi_4.log) | [view](renders/a22oi_4.png) | [gds+lef](outputs/a22oi_4/) |
| `a2bb2o_1` | ❌ open | 19 | [log](logs/a2bb2o_1.log) | [view](renders/a2bb2o_1.png) | [gds+lef](outputs/a2bb2o_1/) |
| `a2bb2o_2` | ✅ closed | 20 | [log](logs/a2bb2o_2.log) | [view](renders/a2bb2o_2.png) | [gds+lef](outputs/a2bb2o_2/) |
| `a2bb2o_4` | ✅ closed | 41 | [log](logs/a2bb2o_4.log) | [view](renders/a2bb2o_4.png) | [gds+lef](outputs/a2bb2o_4/) |
| `a2bb2oi_1` | ✅ closed | 8 | [log](logs/a2bb2oi_1.log) | [view](renders/a2bb2oi_1.png) | [gds+lef](outputs/a2bb2oi_1/) |
| `a2bb2oi_2` | ✅ closed | 50 | [log](logs/a2bb2oi_2.log) | [view](renders/a2bb2oi_2.png) | [gds+lef](outputs/a2bb2oi_2/) |
| `a2bb2oi_4` | ✅ closed | 223 | [log](logs/a2bb2oi_4.log) | [view](renders/a2bb2oi_4.png) | [gds+lef](outputs/a2bb2oi_4/) |
| `a311o_1` | ✅ closed | 14 | [log](logs/a311o_1.log) | [view](renders/a311o_1.png) | [gds+lef](outputs/a311o_1/) |
| `a311o_2` | ✅ closed | 17 | [log](logs/a311o_2.log) | [view](renders/a311o_2.png) | [gds+lef](outputs/a311o_2/) |
| `a311o_4` | ✅ closed | 152 | [log](logs/a311o_4.log) | [view](renders/a311o_4.png) | [gds+lef](outputs/a311o_4/) |
| `a311oi_1` | ✅ closed | 7 | [log](logs/a311oi_1.log) | [view](renders/a311oi_1.png) | [gds+lef](outputs/a311oi_1/) |
| `a311oi_2` | ✅ closed | 36 | [log](logs/a311oi_2.log) | [view](renders/a311oi_2.png) | [gds+lef](outputs/a311oi_2/) |
| `a311oi_4` | ✅ closed | 311 | [log](logs/a311oi_4.log) | [view](renders/a311oi_4.png) | [gds+lef](outputs/a311oi_4/) |
| `a31o_1` | ✅ closed | 9 | [log](logs/a31o_1.log) | [view](renders/a31o_1.png) | [gds+lef](outputs/a31o_1/) |
| `a31o_2` | ✅ closed | 11 | [log](logs/a31o_2.log) | [view](renders/a31o_2.png) | [gds+lef](outputs/a31o_2/) |
| `a31o_4` | ✅ closed | 62 | [log](logs/a31o_4.log) | [view](renders/a31o_4.png) | [gds+lef](outputs/a31o_4/) |
| `a31oi_1` | ✅ closed | 5 | [log](logs/a31oi_1.log) | [view](renders/a31oi_1.png) | [gds+lef](outputs/a31oi_1/) |
| `a31oi_2` | ❌ open | 136 | [log](logs/a31oi_2.log) | [view](renders/a31oi_2.png) | [gds+lef](outputs/a31oi_2/) |
| `a31oi_4` | ✅ closed | 175 | [log](logs/a31oi_4.log) | [view](renders/a31oi_4.png) | [gds+lef](outputs/a31oi_4/) |
| `a32o_1` | ✅ closed | 11 | [log](logs/a32o_1.log) | [view](renders/a32o_1.png) | [gds+lef](outputs/a32o_1/) |
| `a32o_2` | ✅ closed | 12 | [log](logs/a32o_2.log) | [view](renders/a32o_2.png) | [gds+lef](outputs/a32o_2/) |
| `a32o_4` | ✅ closed | 117 | [log](logs/a32o_4.log) | [view](renders/a32o_4.png) | [gds+lef](outputs/a32o_4/) |
| `a32oi_1` | ✅ closed | 9 | [log](logs/a32oi_1.log) | [view](renders/a32oi_1.png) | [gds+lef](outputs/a32oi_1/) |
| `a32oi_2` | ✅ closed | 49 | [log](logs/a32oi_2.log) | [view](renders/a32oi_2.png) | [gds+lef](outputs/a32oi_2/) |
| `a32oi_4` | ❌ open | 300 | [log](logs/a32oi_4.log) | [view](renders/a32oi_4.png) | [gds+lef](outputs/a32oi_4/) |
| `a41o_1` | ✅ closed | 10 | [log](logs/a41o_1.log) | [view](renders/a41o_1.png) | [gds+lef](outputs/a41o_1/) |
| `a41o_2` | ✅ closed | 12 | [log](logs/a41o_2.log) | [view](renders/a41o_2.png) | [gds+lef](outputs/a41o_2/) |
| `a41o_4` | ❌ open | 300 | [log](logs/a41o_4.log) | [view](renders/a41o_4.png) | [gds+lef](outputs/a41o_4/) |
| `a41oi_1` | ✅ closed | 6 | [log](logs/a41oi_1.log) | [view](renders/a41oi_1.png) | [gds+lef](outputs/a41oi_1/) |
| `a41oi_2` | ✅ closed | 47 | [log](logs/a41oi_2.log) | [view](renders/a41oi_2.png) | [gds+lef](outputs/a41oi_2/) |
| `a41oi_4` | ❌ open | 300 | [log](logs/a41oi_4.log) | [view](renders/a41oi_4.png) | [gds+lef](outputs/a41oi_4/) |

## OR AND Invert (OAI) (68)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `o2111a_1` | ✅ closed | 9 | [log](logs/o2111a_1.log) | [view](renders/o2111a_1.png) | [gds+lef](outputs/o2111a_1/) |
| `o2111a_2` | ✅ closed | 11 | [log](logs/o2111a_2.log) | [view](renders/o2111a_2.png) | [gds+lef](outputs/o2111a_2/) |
| `o2111a_4` | ✅ closed | 81 | [log](logs/o2111a_4.log) | [view](renders/o2111a_4.png) | [gds+lef](outputs/o2111a_4/) |
| `o2111ai_1` | ✅ closed | 6 | [log](logs/o2111ai_1.log) | [view](renders/o2111ai_1.png) | [gds+lef](outputs/o2111ai_1/) |
| `o2111ai_2` | ✅ closed | 63 | [log](logs/o2111ai_2.log) | [view](renders/o2111ai_2.png) | [gds+lef](outputs/o2111ai_2/) |
| `o2111ai_4` | ✅ closed | 261 | [log](logs/o2111ai_4.log) | [view](renders/o2111ai_4.png) | [gds+lef](outputs/o2111ai_4/) |
| `o211a_1` | ✅ closed | 9 | [log](logs/o211a_1.log) | [view](renders/o211a_1.png) | [gds+lef](outputs/o211a_1/) |
| `o211a_2` | ✅ closed | 28 | [log](logs/o211a_2.log) | [view](renders/o211a_2.png) | [gds+lef](outputs/o211a_2/) |
| `o211a_4` | ✅ closed | 85 | [log](logs/o211a_4.log) | [view](renders/o211a_4.png) | [gds+lef](outputs/o211a_4/) |
| `o211ai_1` | ✅ closed | 13 | [log](logs/o211ai_1.log) | [view](renders/o211ai_1.png) | [gds+lef](outputs/o211ai_1/) |
| `o211ai_2` | ✅ closed | 176 | [log](logs/o211ai_2.log) | [view](renders/o211ai_2.png) | [gds+lef](outputs/o211ai_2/) |
| `o211ai_4` | ✅ closed | 104 | [log](logs/o211ai_4.log) | [view](renders/o211ai_4.png) | [gds+lef](outputs/o211ai_4/) |
| `o21a_1` | ✅ closed | 30 | [log](logs/o21a_1.log) | [view](renders/o21a_1.png) | [gds+lef](outputs/o21a_1/) |
| `o21a_2` | ✅ closed | 34 | [log](logs/o21a_2.log) | [view](renders/o21a_2.png) | [gds+lef](outputs/o21a_2/) |
| `o21a_4` | ✅ closed | 98 | [log](logs/o21a_4.log) | [view](renders/o21a_4.png) | [gds+lef](outputs/o21a_4/) |
| `o21ai_0` | ✅ closed | 20 | [log](logs/o21ai_0.log) | [view](renders/o21ai_0.png) | [gds+lef](outputs/o21ai_0/) |
| `o21ai_1` | ✅ closed | 18 | [log](logs/o21ai_1.log) | [view](renders/o21ai_1.png) | [gds+lef](outputs/o21ai_1/) |
| `o21ai_2` | ✅ closed | 44 | [log](logs/o21ai_2.log) | [view](renders/o21ai_2.png) | [gds+lef](outputs/o21ai_2/) |
| `o21ai_4` | ❌ open | 34 | [log](logs/o21ai_4.log) | [view](renders/o21ai_4.png) | [gds+lef](outputs/o21ai_4/) |
| `o21ba_1` | ✅ closed | 53 | [log](logs/o21ba_1.log) | [view](renders/o21ba_1.png) | [gds+lef](outputs/o21ba_1/) |
| `o21ba_2` | ✅ closed | 68 | [log](logs/o21ba_2.log) | [view](renders/o21ba_2.png) | [gds+lef](outputs/o21ba_2/) |
| `o21ba_4` | ✅ closed | 40 | [log](logs/o21ba_4.log) | [view](renders/o21ba_4.png) | [gds+lef](outputs/o21ba_4/) |
| `o21bai_1` | ✅ closed | 33 | [log](logs/o21bai_1.log) | [view](renders/o21bai_1.png) | [gds+lef](outputs/o21bai_1/) |
| `o21bai_2` | ✅ closed | 27 | [log](logs/o21bai_2.log) | [view](renders/o21bai_2.png) | [gds+lef](outputs/o21bai_2/) |
| `o21bai_4` | ✅ closed | 175 | [log](logs/o21bai_4.log) | [view](renders/o21bai_4.png) | [gds+lef](outputs/o21bai_4/) |
| `o221a_1` | ✅ closed | 19 | [log](logs/o221a_1.log) | [view](renders/o221a_1.png) | [gds+lef](outputs/o221a_1/) |
| `o221a_2` | ❌ open | 34 | [log](logs/o221a_2.log) | [view](renders/o221a_2.png) | [gds+lef](outputs/o221a_2/) |
| `o221a_4` | ✅ closed | 171 | [log](logs/o221a_4.log) | [view](renders/o221a_4.png) | [gds+lef](outputs/o221a_4/) |
| `o221ai_1` | ❌ open | 12 | [log](logs/o221ai_1.log) | [view](renders/o221ai_1.png) | [gds+lef](outputs/o221ai_1/) |
| `o221ai_2` | ✅ closed | 54 | [log](logs/o221ai_2.log) | [view](renders/o221ai_2.png) | [gds+lef](outputs/o221ai_2/) |
| `o221ai_4` | ❌ open | 300 | [log](logs/o221ai_4.log) | [view](renders/o221ai_4.png) | [gds+lef](outputs/o221ai_4/) |
| `o22a_1` | ✅ closed | 7 | [log](logs/o22a_1.log) | [view](renders/o22a_1.png) | [gds+lef](outputs/o22a_1/) |
| `o22a_2` | ✅ closed | 14 | [log](logs/o22a_2.log) | [view](renders/o22a_2.png) | [gds+lef](outputs/o22a_2/) |
| `o22a_4` | ✅ closed | 109 | [log](logs/o22a_4.log) | [view](renders/o22a_4.png) | [gds+lef](outputs/o22a_4/) |
| `o22ai_1` | ✅ closed | 9 | [log](logs/o22ai_1.log) | [view](renders/o22ai_1.png) | [gds+lef](outputs/o22ai_1/) |
| `o22ai_2` | ❌ open | 20 | [log](logs/o22ai_2.log) | [view](renders/o22ai_2.png) | [gds+lef](outputs/o22ai_2/) |
| `o22ai_4` | ✅ closed | 72 | [log](logs/o22ai_4.log) | [view](renders/o22ai_4.png) | [gds+lef](outputs/o22ai_4/) |
| `o2bb2a_1` | ✅ closed | 21 | [log](logs/o2bb2a_1.log) | [view](renders/o2bb2a_1.png) | [gds+lef](outputs/o2bb2a_1/) |
| `o2bb2a_2` | ✅ closed | 19 | [log](logs/o2bb2a_2.log) | [view](renders/o2bb2a_2.png) | [gds+lef](outputs/o2bb2a_2/) |
| `o2bb2a_4` | ❌ open | 31 | [log](logs/o2bb2a_4.log) | [view](renders/o2bb2a_4.png) | [gds+lef](outputs/o2bb2a_4/) |
| `o2bb2ai_1` | ✅ closed | 8 | [log](logs/o2bb2ai_1.log) | [view](renders/o2bb2ai_1.png) | [gds+lef](outputs/o2bb2ai_1/) |
| `o2bb2ai_2` | ✅ closed | 23 | [log](logs/o2bb2ai_2.log) | [view](renders/o2bb2ai_2.png) | [gds+lef](outputs/o2bb2ai_2/) |
| `o2bb2ai_4` | ✅ closed | 24354 | [log](logs/o2bb2ai_4.log) | [view](renders/o2bb2ai_4.png) | [gds+lef](outputs/o2bb2ai_4/) |
| `o311a_1` | ✅ closed | 8 | [log](logs/o311a_1.log) | [view](renders/o311a_1.png) | [gds+lef](outputs/o311a_1/) |
| `o311a_2` | ✅ closed | 10 | [log](logs/o311a_2.log) | [view](renders/o311a_2.png) | [gds+lef](outputs/o311a_2/) |
| `o311a_4` | ✅ closed | 70 | [log](logs/o311a_4.log) | [view](renders/o311a_4.png) | [gds+lef](outputs/o311a_4/) |
| `o311ai_0` | ✅ closed | 6 | [log](logs/o311ai_0.log) | [view](renders/o311ai_0.png) | [gds+lef](outputs/o311ai_0/) |
| `o311ai_1` | ✅ closed | 5 | [log](logs/o311ai_1.log) | [view](renders/o311ai_1.png) | [gds+lef](outputs/o311ai_1/) |
| `o311ai_2` | ✅ closed | 34 | [log](logs/o311ai_2.log) | [view](renders/o311ai_2.png) | [gds+lef](outputs/o311ai_2/) |
| `o311ai_4` | ✅ closed | 24362 | [log](logs/o311ai_4.log) | [view](renders/o311ai_4.png) | [gds+lef](outputs/o311ai_4/) |
| `o31a_1` | ✅ closed | 6 | [log](logs/o31a_1.log) | [view](renders/o31a_1.png) | [gds+lef](outputs/o31a_1/) |
| `o31a_2` | ✅ closed | 8 | [log](logs/o31a_2.log) | [view](renders/o31a_2.png) | [gds+lef](outputs/o31a_2/) |
| `o31a_4` | ❌ open | 24262 | [log](logs/o31a_4.log) | [view](renders/o31a_4.png) | [gds+lef](outputs/o31a_4/) |
| `o31ai_1` | ✅ closed | 4 | [log](logs/o31ai_1.log) | [view](renders/o31ai_1.png) | [gds+lef](outputs/o31ai_1/) |
| `o31ai_2` | ✅ closed | 25 | [log](logs/o31ai_2.log) | [view](renders/o31ai_2.png) | [gds+lef](outputs/o31ai_2/) |
| `o31ai_4` | ✅ closed | 24221 | [log](logs/o31ai_4.log) | [view](renders/o31ai_4.png) | [gds+lef](outputs/o31ai_4/) |
| `o32a_1` | ✅ closed | 17 | [log](logs/o32a_1.log) | [view](renders/o32a_1.png) | [gds+lef](outputs/o32a_1/) |
| `o32a_2` | ✅ closed | 19 | [log](logs/o32a_2.log) | [view](renders/o32a_2.png) | [gds+lef](outputs/o32a_2/) |
| `o32a_4` | ❌ open | 24358 | [log](logs/o32a_4.log) | [view](renders/o32a_4.png) | [gds+lef](outputs/o32a_4/) |
| `o32ai_1` | ✅ closed | 9 | [log](logs/o32ai_1.log) | [view](renders/o32ai_1.png) | [gds+lef](outputs/o32ai_1/) |
| `o32ai_2` | ✅ closed | 24162 | [log](logs/o32ai_2.log) | [view](renders/o32ai_2.png) | [gds+lef](outputs/o32ai_2/) |
| `o32ai_4` | ❌ open | 300 | [log](logs/o32ai_4.log) | [view](renders/o32ai_4.png) | [gds+lef](outputs/o32ai_4/) |
| `o41a_1` | ✅ closed | 9 | [log](logs/o41a_1.log) | [view](renders/o41a_1.png) | [gds+lef](outputs/o41a_1/) |
| `o41a_2` | ✅ closed | 10 | [log](logs/o41a_2.log) | [view](renders/o41a_2.png) | [gds+lef](outputs/o41a_2/) |
| `o41a_4` | ❌ open | 206 | [log](logs/o41a_4.log) | [view](renders/o41a_4.png) | [gds+lef](outputs/o41a_4/) |
| `o41ai_1` | ✅ closed | 5 | [log](logs/o41ai_1.log) | [view](renders/o41ai_1.png) | [gds+lef](outputs/o41ai_1/) |
| `o41ai_2` | ✅ closed | 51 | [log](logs/o41ai_2.log) | [view](renders/o41ai_2.png) | [gds+lef](outputs/o41ai_2/) |
| `o41ai_4` | ✅ closed | 227 | [log](logs/o41ai_4.log) | [view](renders/o41ai_4.png) | [gds+lef](outputs/o41ai_4/) |

## XOR / XNOR (12)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `xnor2_1` | ✅ closed | 12 | [log](logs/xnor2_1.log) | [view](renders/xnor2_1.png) | [gds+lef](outputs/xnor2_1/) |
| `xnor2_2` | ✅ closed | 30 | [log](logs/xnor2_2.log) | [view](renders/xnor2_2.png) | [gds+lef](outputs/xnor2_2/) |
| `xnor2_4` | ✅ closed | 229 | [log](logs/xnor2_4.log) | [view](renders/xnor2_4.png) | [gds+lef](outputs/xnor2_4/) |
| `xnor3_1` | ❌ open | 300 | [log](logs/xnor3_1.log) | [view](renders/xnor3_1.png) | [gds+lef](outputs/xnor3_1/) |
| `xnor3_2` | ❌ open | 300 | [log](logs/xnor3_2.log) | [view](renders/xnor3_2.png) | [gds+lef](outputs/xnor3_2/) |
| `xnor3_4` | ❌ open | 300 | [log](logs/xnor3_4.log) | [view](renders/xnor3_4.png) | [gds+lef](outputs/xnor3_4/) |
| `xor2_1` | ✅ closed | 20 | [log](logs/xor2_1.log) | [view](renders/xor2_1.png) | [gds+lef](outputs/xor2_1/) |
| `xor2_2` | ✅ closed | 50 | [log](logs/xor2_2.log) | [view](renders/xor2_2.png) | [gds+lef](outputs/xor2_2/) |
| `xor2_4` | ✅ closed | 240 | [log](logs/xor2_4.log) | [view](renders/xor2_4.png) | [gds+lef](outputs/xor2_4/) |
| `xor3_1` | ❌ open | 300 | [log](logs/xor3_1.log) | [view](renders/xor3_1.png) | [gds+lef](outputs/xor3_1/) |
| `xor3_2` | ❌ open | 300 | [log](logs/xor3_2.log) | [view](renders/xor3_2.png) | [gds+lef](outputs/xor3_2/) |
| `xor3_4` | ❌ open | 300 | [log](logs/xor3_4.log) | [view](renders/xor3_4.png) | [gds+lef](outputs/xor3_4/) |

## Multiplexers (10)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `mux2_1` | ✅ closed | 17 | [log](logs/mux2_1.log) | [view](renders/mux2_1.png) | [gds+lef](outputs/mux2_1/) |
| `mux2_2` | ✅ closed | 18 | [log](logs/mux2_2.log) | [view](renders/mux2_2.png) | [gds+lef](outputs/mux2_2/) |
| `mux2_4` | ✅ closed | 72 | [log](logs/mux2_4.log) | [view](renders/mux2_4.png) | [gds+lef](outputs/mux2_4/) |
| `mux2_8` | ❌ open | 300 | [log](logs/mux2_8.log) | [view](renders/mux2_8.png) | [gds+lef](outputs/mux2_8/) |
| `mux2i_1` | ✅ closed | 21 | [log](logs/mux2i_1.log) | [view](renders/mux2i_1.png) | [gds+lef](outputs/mux2i_1/) |
| `mux2i_2` | ✅ closed | 60 | [log](logs/mux2i_2.log) | [view](renders/mux2i_2.png) | [gds+lef](outputs/mux2i_2/) |
| `mux2i_4` | ❌ open | 300 | [log](logs/mux2i_4.log) | [view](renders/mux2i_4.png) | [gds+lef](outputs/mux2i_4/) |
| `mux4_1` | ✅ closed | 110 | [log](logs/mux4_1.log) | [view](renders/mux4_1.png) | [gds+lef](outputs/mux4_1/) |
| `mux4_2` | ❌ open | 300 | [log](logs/mux4_2.log) | [view](renders/mux4_2.png) | [gds+lef](outputs/mux4_2/) |
| `mux4_4` | ❌ open | 300 | [log](logs/mux4_4.log) | [view](renders/mux4_4.png) | [gds+lef](outputs/mux4_4/) |

## Adders / majority (12)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `fa_1` | ✅ closed | 161 | [log](logs/fa_1.log) | [view](renders/fa_1.png) | [gds+lef](outputs/fa_1/) |
| `fa_2` | ❌ open | 300 | [log](logs/fa_2.log) | [view](renders/fa_2.png) | [gds+lef](outputs/fa_2/) |
| `fa_4` | ❌ open | 187 | [log](logs/fa_4.log) | [view](renders/fa_4.png) | [gds+lef](outputs/fa_4/) |
| `fah_1` | ❌ open | 300 | [log](logs/fah_1.log) | [view](renders/fah_1.png) | [gds+lef](outputs/fah_1/) |
| `fahcin_1` | ❌ open | 300 | [log](logs/fahcin_1.log) | [view](renders/fahcin_1.png) | [gds+lef](outputs/fahcin_1/) |
| `fahcon_1` | ❌ open | 300 | [log](logs/fahcon_1.log) | [view](renders/fahcon_1.png) | [gds+lef](outputs/fahcon_1/) |
| `ha_1` | ✅ closed | 18 | [log](logs/ha_1.log) | [view](renders/ha_1.png) | [gds+lef](outputs/ha_1/) |
| `ha_2` | ✅ closed | 92 | [log](logs/ha_2.log) | [view](renders/ha_2.png) | [gds+lef](outputs/ha_2/) |
| `ha_4` | ✅ closed | 107 | [log](logs/ha_4.log) | [view](renders/ha_4.png) | [gds+lef](outputs/ha_4/) |
| `maj3_1` | ✅ closed | 13 | [log](logs/maj3_1.log) | [view](renders/maj3_1.png) | [gds+lef](outputs/maj3_1/) |
| `maj3_2` | ✅ closed | 17 | [log](logs/maj3_2.log) | [view](renders/maj3_2.png) | [gds+lef](outputs/maj3_2/) |
| `maj3_4` | ✅ closed | 26 | [log](logs/maj3_4.log) | [view](renders/maj3_4.png) | [gds+lef](outputs/maj3_4/) |

## Tristate / enabled drivers (13)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `ebufn_1` | ✅ closed | 8 | [log](logs/ebufn_1.log) | [view](renders/ebufn_1.png) | [gds+lef](outputs/ebufn_1/) |
| `ebufn_2` | ✅ closed | 16 | [log](logs/ebufn_2.log) | [view](renders/ebufn_2.png) | [gds+lef](outputs/ebufn_2/) |
| `ebufn_4` | ✅ closed | 88 | [log](logs/ebufn_4.log) | [view](renders/ebufn_4.png) | [gds+lef](outputs/ebufn_4/) |
| `ebufn_8` | ✅ closed | 201 | [log](logs/ebufn_8.log) | [view](renders/ebufn_8.png) | [gds+lef](outputs/ebufn_8/) |
| `einvn_0` | ✅ closed | 5 | [log](logs/einvn_0.log) | [view](renders/einvn_0.png) | [gds+lef](outputs/einvn_0/) |
| `einvn_1` | ✅ closed | 5 | [log](logs/einvn_1.log) | [view](renders/einvn_1.png) | [gds+lef](outputs/einvn_1/) |
| `einvn_2` | ✅ closed | 13 | [log](logs/einvn_2.log) | [view](renders/einvn_2.png) | [gds+lef](outputs/einvn_2/) |
| `einvn_4` | ✅ closed | 27 | [log](logs/einvn_4.log) | [view](renders/einvn_4.png) | [gds+lef](outputs/einvn_4/) |
| `einvn_8` | ✅ closed | 76 | [log](logs/einvn_8.log) | [view](renders/einvn_8.png) | [gds+lef](outputs/einvn_8/) |
| `einvp_1` | ✅ closed | 5 | [log](logs/einvp_1.log) | [view](renders/einvp_1.png) | [gds+lef](outputs/einvp_1/) |
| `einvp_2` | ✅ closed | 12 | [log](logs/einvp_2.log) | [view](renders/einvp_2.png) | [gds+lef](outputs/einvp_2/) |
| `einvp_4` | ✅ closed | 26 | [log](logs/einvp_4.log) | [view](renders/einvp_4.png) | [gds+lef](outputs/einvp_4/) |
| `einvp_8` | ✅ closed | 81 | [log](logs/einvp_8.log) | [view](renders/einvp_8.png) | [gds+lef](outputs/einvp_8/) |

## Flip flops (45)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `dfbbn_1` | ❌ open | 300 | [log](logs/dfbbn_1.log) | [view](renders/dfbbn_1.png) | [gds+lef](outputs/dfbbn_1/) |
| `dfbbn_2` | ❌ open | 300 | [log](logs/dfbbn_2.log) | [view](renders/dfbbn_2.png) | [gds+lef](outputs/dfbbn_2/) |
| `dfbbp_1` | ❌ open | 300 | [log](logs/dfbbp_1.log) | [view](renders/dfbbp_1.png) | [gds+lef](outputs/dfbbp_1/) |
| `dfrbp_1` | ❌ open | 300 | [log](logs/dfrbp_1.log) | [view](renders/dfrbp_1.png) | [gds+lef](outputs/dfrbp_1/) |
| `dfrbp_2` | ❌ open | 300 | [log](logs/dfrbp_2.log) | [view](renders/dfrbp_2.png) | [gds+lef](outputs/dfrbp_2/) |
| `dfrtn_1` | ❌ open | 300 | [log](logs/dfrtn_1.log) | [view](renders/dfrtn_1.png) | [gds+lef](outputs/dfrtn_1/) |
| `dfrtp_1` | ❌ open | 300 | [log](logs/dfrtp_1.log) | [view](renders/dfrtp_1.png) | [gds+lef](outputs/dfrtp_1/) |
| `dfrtp_2` | ❌ open | 300 | [log](logs/dfrtp_2.log) | [view](renders/dfrtp_2.png) | [gds+lef](outputs/dfrtp_2/) |
| `dfrtp_4` | ❌ open | 300 | [log](logs/dfrtp_4.log) | [view](renders/dfrtp_4.png) | [gds+lef](outputs/dfrtp_4/) |
| `dfsbp_1` | ❌ open | 300 | [log](logs/dfsbp_1.log) | [view](renders/dfsbp_1.png) | [gds+lef](outputs/dfsbp_1/) |
| `dfsbp_2` | ❌ open | 300 | [log](logs/dfsbp_2.log) | [view](renders/dfsbp_2.png) | [gds+lef](outputs/dfsbp_2/) |
| `dfstp_1` | ❌ open | 300 | [log](logs/dfstp_1.log) | [view](renders/dfstp_1.png) | [gds+lef](outputs/dfstp_1/) |
| `dfstp_2` | ❌ open | 300 | [log](logs/dfstp_2.log) | [view](renders/dfstp_2.png) | [gds+lef](outputs/dfstp_2/) |
| `dfstp_4` | ❌ open | 300 | [log](logs/dfstp_4.log) | [view](renders/dfstp_4.png) | [gds+lef](outputs/dfstp_4/) |
| `dfxbp_1` | ❌ open | 300 | [log](logs/dfxbp_1.log) | [view](renders/dfxbp_1.png) | [gds+lef](outputs/dfxbp_1/) |
| `dfxbp_2` | ❌ open | 300 | [log](logs/dfxbp_2.log) | [view](renders/dfxbp_2.png) | [gds+lef](outputs/dfxbp_2/) |
| `dfxtp_1` | ❌ open | 300 | [log](logs/dfxtp_1.log) | [view](renders/dfxtp_1.png) | [gds+lef](outputs/dfxtp_1/) |
| `dfxtp_2` | ❌ open | 300 | [log](logs/dfxtp_2.log) | [view](renders/dfxtp_2.png) | [gds+lef](outputs/dfxtp_2/) |
| `dfxtp_4` | ❌ open | 300 | [log](logs/dfxtp_4.log) | [view](renders/dfxtp_4.png) | [gds+lef](outputs/dfxtp_4/) |
| `edfxbp_1` | ❌ open | 300 | [log](logs/edfxbp_1.log) | [view](renders/edfxbp_1.png) | [gds+lef](outputs/edfxbp_1/) |
| `edfxtp_1` | ❌ open | 300 | [log](logs/edfxtp_1.log) | [view](renders/edfxtp_1.png) | [gds+lef](outputs/edfxtp_1/) |
| `sdfbbn_1` | ❌ open | 300 | [log](logs/sdfbbn_1.log) | [view](renders/sdfbbn_1.png) | [gds+lef](outputs/sdfbbn_1/) |
| `sdfbbn_2` | ❌ open | 300 | [log](logs/sdfbbn_2.log) | [view](renders/sdfbbn_2.png) | [gds+lef](outputs/sdfbbn_2/) |
| `sdfbbp_1` | ❌ open | 300 | [log](logs/sdfbbp_1.log) | [view](renders/sdfbbp_1.png) | [gds+lef](outputs/sdfbbp_1/) |
| `sdfrbp_1` | ❌ open | 13 | [log](logs/sdfrbp_1.log) | [view](renders/sdfrbp_1.png) | [gds+lef](outputs/sdfrbp_1/) |
| `sdfrbp_2` | ❌ open | 12 | [log](logs/sdfrbp_2.log) | [view](renders/sdfrbp_2.png) | [gds+lef](outputs/sdfrbp_2/) |
| `sdfrtn_1` | ❌ open | 10 | [log](logs/sdfrtn_1.log) | [view](renders/sdfrtn_1.png) | [gds+lef](outputs/sdfrtn_1/) |
| `sdfrtp_1` | ❌ open | 10 | [log](logs/sdfrtp_1.log) | [view](renders/sdfrtp_1.png) | [gds+lef](outputs/sdfrtp_1/) |
| `sdfrtp_2` | ❌ open | 10 | [log](logs/sdfrtp_2.log) | [view](renders/sdfrtp_2.png) | [gds+lef](outputs/sdfrtp_2/) |
| `sdfrtp_4` | ❌ open | 300 | [log](logs/sdfrtp_4.log) | [view](renders/sdfrtp_4.png) | [gds+lef](outputs/sdfrtp_4/) |
| `sdfsbp_1` | ❌ open | 300 | [log](logs/sdfsbp_1.log) | [view](renders/sdfsbp_1.png) | [gds+lef](outputs/sdfsbp_1/) |
| `sdfsbp_2` | ❌ open | 300 | [log](logs/sdfsbp_2.log) | [view](renders/sdfsbp_2.png) | [gds+lef](outputs/sdfsbp_2/) |
| `sdfstp_1` | ❌ open | 300 | [log](logs/sdfstp_1.log) | [view](renders/sdfstp_1.png) | [gds+lef](outputs/sdfstp_1/) |
| `sdfstp_2` | ❌ open | 300 | [log](logs/sdfstp_2.log) | [view](renders/sdfstp_2.png) | [gds+lef](outputs/sdfstp_2/) |
| `sdfstp_4` | ❌ open | 300 | [log](logs/sdfstp_4.log) | [view](renders/sdfstp_4.png) | [gds+lef](outputs/sdfstp_4/) |
| `sdfxbp_1` | ❌ open | 300 | [log](logs/sdfxbp_1.log) | [view](renders/sdfxbp_1.png) | [gds+lef](outputs/sdfxbp_1/) |
| `sdfxbp_2` | ❌ open | 300 | [log](logs/sdfxbp_2.log) | [view](renders/sdfxbp_2.png) | [gds+lef](outputs/sdfxbp_2/) |
| `sdfxtp_1` | ❌ open | 300 | [log](logs/sdfxtp_1.log) | [view](renders/sdfxtp_1.png) | [gds+lef](outputs/sdfxtp_1/) |
| `sdfxtp_2` | ❌ open | 300 | [log](logs/sdfxtp_2.log) | [view](renders/sdfxtp_2.png) | [gds+lef](outputs/sdfxtp_2/) |
| `sdfxtp_4` | ❌ open | 300 | [log](logs/sdfxtp_4.log) | [view](renders/sdfxtp_4.png) | [gds+lef](outputs/sdfxtp_4/) |
| `sedfxbp_1` | ❌ open | 300 | [log](logs/sedfxbp_1.log) | [view](renders/sedfxbp_1.png) | [gds+lef](outputs/sedfxbp_1/) |
| `sedfxbp_2` | ❌ open | 300 | [log](logs/sedfxbp_2.log) | [view](renders/sedfxbp_2.png) | [gds+lef](outputs/sedfxbp_2/) |
| `sedfxtp_1` | ❌ open | 300 | [log](logs/sedfxtp_1.log) | [view](renders/sedfxtp_1.png) | [gds+lef](outputs/sedfxtp_1/) |
| `sedfxtp_2` | ❌ open | 300 | [log](logs/sedfxtp_2.log) | [view](renders/sedfxtp_2.png) | [gds+lef](outputs/sedfxtp_2/) |
| `sedfxtp_4` | ❌ open | 300 | [log](logs/sedfxtp_4.log) | [view](renders/sedfxtp_4.png) | [gds+lef](outputs/sedfxtp_4/) |

## Latches (23)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `dlclkp_1` | ❌ open | 300 | [log](logs/dlclkp_1.log) | [view](renders/dlclkp_1.png) | [gds+lef](outputs/dlclkp_1/) |
| `dlclkp_2` | ❌ open | 300 | [log](logs/dlclkp_2.log) | [view](renders/dlclkp_2.png) | [gds+lef](outputs/dlclkp_2/) |
| `dlclkp_4` | ❌ open | 300 | [log](logs/dlclkp_4.log) | [view](renders/dlclkp_4.png) | [gds+lef](outputs/dlclkp_4/) |
| `dlrbn_1` | ❌ open | 300 | [log](logs/dlrbn_1.log) | [view](renders/dlrbn_1.png) | [gds+lef](outputs/dlrbn_1/) |
| `dlrbn_2` | ❌ open | 300 | [log](logs/dlrbn_2.log) | [view](renders/dlrbn_2.png) | [gds+lef](outputs/dlrbn_2/) |
| `dlrbp_1` | ❌ open | 300 | [log](logs/dlrbp_1.log) | [view](renders/dlrbp_1.png) | [gds+lef](outputs/dlrbp_1/) |
| `dlrbp_2` | ❌ open | 300 | [log](logs/dlrbp_2.log) | [view](renders/dlrbp_2.png) | [gds+lef](outputs/dlrbp_2/) |
| `dlrtn_1` | ❌ open | 300 | [log](logs/dlrtn_1.log) | [view](renders/dlrtn_1.png) | [gds+lef](outputs/dlrtn_1/) |
| `dlrtn_2` | ❌ open | 300 | [log](logs/dlrtn_2.log) | [view](renders/dlrtn_2.png) | [gds+lef](outputs/dlrtn_2/) |
| `dlrtn_4` | ❌ open | 300 | [log](logs/dlrtn_4.log) | [view](renders/dlrtn_4.png) | [gds+lef](outputs/dlrtn_4/) |
| `dlrtp_1` | ❌ open | 300 | [log](logs/dlrtp_1.log) | [view](renders/dlrtp_1.png) | [gds+lef](outputs/dlrtp_1/) |
| `dlrtp_2` | ❌ open | 300 | [log](logs/dlrtp_2.log) | [view](renders/dlrtp_2.png) | [gds+lef](outputs/dlrtp_2/) |
| `dlrtp_4` | ❌ open | 300 | [log](logs/dlrtp_4.log) | [view](renders/dlrtp_4.png) | [gds+lef](outputs/dlrtp_4/) |
| `dlxbn_1` | ❌ open | 300 | [log](logs/dlxbn_1.log) | [view](renders/dlxbn_1.png) | [gds+lef](outputs/dlxbn_1/) |
| `dlxbn_2` | ❌ open | 300 | [log](logs/dlxbn_2.log) | [view](renders/dlxbn_2.png) | [gds+lef](outputs/dlxbn_2/) |
| `dlxbp_1` | ❌ open | 300 | [log](logs/dlxbp_1.log) | [view](renders/dlxbp_1.png) | [gds+lef](outputs/dlxbp_1/) |
| `dlxtn_1` | ❌ open | 300 | [log](logs/dlxtn_1.log) | [view](renders/dlxtn_1.png) | [gds+lef](outputs/dlxtn_1/) |
| `dlxtn_2` | ❌ open | 300 | [log](logs/dlxtn_2.log) | [view](renders/dlxtn_2.png) | [gds+lef](outputs/dlxtn_2/) |
| `dlxtn_4` | ❌ open | 300 | [log](logs/dlxtn_4.log) | [view](renders/dlxtn_4.png) | [gds+lef](outputs/dlxtn_4/) |
| `dlxtp_1` | ❌ open | 300 | [log](logs/dlxtp_1.log) | [view](renders/dlxtp_1.png) | [gds+lef](outputs/dlxtp_1/) |
| `sdlclkp_1` | ❌ open | 300 | [log](logs/sdlclkp_1.log) | [view](renders/sdlclkp_1.png) | [gds+lef](outputs/sdlclkp_1/) |
| `sdlclkp_2` | ❌ open | 300 | [log](logs/sdlclkp_2.log) | [view](renders/sdlclkp_2.png) | [gds+lef](outputs/sdlclkp_2/) |
| `sdlclkp_4` | ❌ open | 300 | [log](logs/sdlclkp_4.log) | [view](renders/sdlclkp_4.png) | [gds+lef](outputs/sdlclkp_4/) |

## Clock & delay (14)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `clkdlybuf4s15_1` | ✅ closed | 11 | [log](logs/clkdlybuf4s15_1.log) | [view](renders/clkdlybuf4s15_1.png) | [gds+lef](outputs/clkdlybuf4s15_1/) |
| `clkdlybuf4s15_2` | ✅ closed | 14 | [log](logs/clkdlybuf4s15_2.log) | [view](renders/clkdlybuf4s15_2.png) | [gds+lef](outputs/clkdlybuf4s15_2/) |
| `clkdlybuf4s18_1` | ✅ closed | 10 | [log](logs/clkdlybuf4s18_1.log) | [view](renders/clkdlybuf4s18_1.png) | [gds+lef](outputs/clkdlybuf4s18_1/) |
| `clkdlybuf4s18_2` | ✅ closed | 13 | [log](logs/clkdlybuf4s18_2.log) | [view](renders/clkdlybuf4s18_2.png) | [gds+lef](outputs/clkdlybuf4s18_2/) |
| `clkdlybuf4s25_1` | ✅ closed | 11 | [log](logs/clkdlybuf4s25_1.log) | [view](renders/clkdlybuf4s25_1.png) | [gds+lef](outputs/clkdlybuf4s25_1/) |
| `clkdlybuf4s25_2` | ✅ closed | 14 | [log](logs/clkdlybuf4s25_2.log) | [view](renders/clkdlybuf4s25_2.png) | [gds+lef](outputs/clkdlybuf4s25_2/) |
| `clkdlybuf4s50_1` | ❌ open | 300 | [log](logs/clkdlybuf4s50_1.log) | [view](renders/clkdlybuf4s50_1.png) | [gds+lef](outputs/clkdlybuf4s50_1/) |
| `clkdlybuf4s50_2` | ❌ open | 300 | [log](logs/clkdlybuf4s50_2.log) | [view](renders/clkdlybuf4s50_2.png) | [gds+lef](outputs/clkdlybuf4s50_2/) |
| `dlygate4sd1_1` | ✅ closed | 11 | [log](logs/dlygate4sd1_1.log) | [view](renders/dlygate4sd1_1.png) | [gds+lef](outputs/dlygate4sd1_1/) |
| `dlygate4sd2_1` | ✅ closed | 10 | [log](logs/dlygate4sd2_1.log) | [view](renders/dlygate4sd2_1.png) | [gds+lef](outputs/dlygate4sd2_1/) |
| `dlygate4sd3_1` | ❌ open | 300 | [log](logs/dlygate4sd3_1.log) | [view](renders/dlygate4sd3_1.png) | [gds+lef](outputs/dlygate4sd3_1/) |
| `dlymetal6s2s_1` | ✅ closed | 18 | [log](logs/dlymetal6s2s_1.log) | [view](renders/dlymetal6s2s_1.png) | [gds+lef](outputs/dlymetal6s2s_1/) |
| `dlymetal6s4s_1` | ✅ closed | 29 | [log](logs/dlymetal6s4s_1.log) | [view](renders/dlymetal6s4s_1.png) | [gds+lef](outputs/dlymetal6s4s_1/) |
| `dlymetal6s6s_1` | ✅ closed | 29 | [log](logs/dlymetal6s6s_1.log) | [view](renders/dlymetal6s6s_1.png) | [gds+lef](outputs/dlymetal6s6s_1/) |

## Tie & probe (3)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `conb_1` | ❌ open | 1 | [log](logs/conb_1.log) | [view](renders/conb_1.png) | [gds+lef](outputs/conb_1/) |
| `probec_p_8` | ❌ open | 1 | [log](logs/probec_p_8.log) | [view](renders/probec_p_8.png) | [gds+lef](outputs/probec_p_8/) |
| `probe_p_8` | ❌ open | 1 | [log](logs/probe_p_8.log) | [view](renders/probe_p_8.png) | [gds+lef](outputs/probe_p_8/) |

## Fill / physical (16)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `decap_12` | ❌ open | 1 | [log](logs/decap_12.log) | [view](renders/decap_12.png) | [gds+lef](outputs/decap_12/) |
| `decap_3` | ❌ open | 1 | [log](logs/decap_3.log) | [view](renders/decap_3.png) | [gds+lef](outputs/decap_3/) |
| `decap_4` | ❌ open | 2 | [log](logs/decap_4.log) | [view](renders/decap_4.png) | [gds+lef](outputs/decap_4/) |
| `decap_6` | ❌ open | 2 | [log](logs/decap_6.log) | [view](renders/decap_6.png) | [gds+lef](outputs/decap_6/) |
| `decap_8` | ❌ open | 2 | [log](logs/decap_8.log) | [view](renders/decap_8.png) | [gds+lef](outputs/decap_8/) |
| `diode_2` | ✅ closed | 1 | [log](logs/diode_2.log) | [view](renders/diode_2.png) | [gds+lef](outputs/diode_2/) |
| `fill_1` | ✅ closed | 1 | [log](logs/fill_1.log) | [view](renders/fill_1.png) | [gds+lef](outputs/fill_1/) |
| `fill_2` | ✅ closed | 1 | [log](logs/fill_2.log) | [view](renders/fill_2.png) | [gds+lef](outputs/fill_2/) |
| `fill_4` | ✅ closed | 1 | [log](logs/fill_4.log) | [view](renders/fill_4.png) | [gds+lef](outputs/fill_4/) |
| `fill_8` | ✅ closed | 1 | [log](logs/fill_8.log) | [view](renders/fill_8.png) | [gds+lef](outputs/fill_8/) |
| `macro_sparecell` | ✅ closed | 1 | [log](logs/macro_sparecell.log) | [view](renders/macro_sparecell.png) | [gds+lef](outputs/macro_sparecell/) |
| `tap_1` | ✅ closed | 1 | [log](logs/tap_1.log) | [view](renders/tap_1.png) | [gds+lef](outputs/tap_1/) |
| `tap_2` | ✅ closed | 1 | [log](logs/tap_2.log) | [view](renders/tap_2.png) | [gds+lef](outputs/tap_2/) |
| `tapvgnd_1` | ✅ closed | 1 | [log](logs/tapvgnd_1.log) | [view](renders/tapvgnd_1.png) | [gds+lef](outputs/tapvgnd_1/) |
| `tapvgnd2_1` | ✅ closed | 1 | [log](logs/tapvgnd2_1.log) | [view](renders/tapvgnd2_1.png) | [gds+lef](outputs/tapvgnd2_1/) |
| `tapvpwrvgnd_1` | ✅ closed | 1 | [log](logs/tapvpwrvgnd_1.log) | [view](renders/tapvpwrvgnd_1.png) | [gds+lef](outputs/tapvpwrvgnd_1/) |

## Low power / level shift / isolation (34)

| Cell | Status | Time (s) | Log | Layout | Files |
|---|---|--:|---|---|---|
| `lpflow_bleeder_1` | ❌ open | 4 | [log](logs/lpflow_bleeder_1.log) | [view](renders/lpflow_bleeder_1.png) | [gds+lef](outputs/lpflow_bleeder_1/) |
| `lpflow_clkbufkapwr_1` | ✅ closed | 4 | [log](logs/lpflow_clkbufkapwr_1.log) | [view](renders/lpflow_clkbufkapwr_1.png) | [gds+lef](outputs/lpflow_clkbufkapwr_1/) |
| `lpflow_clkbufkapwr_16` | ✅ closed | 176 | [log](logs/lpflow_clkbufkapwr_16.log) | [view](renders/lpflow_clkbufkapwr_16.png) | [gds+lef](outputs/lpflow_clkbufkapwr_16/) |
| `lpflow_clkbufkapwr_2` | ✅ closed | 5 | [log](logs/lpflow_clkbufkapwr_2.log) | [view](renders/lpflow_clkbufkapwr_2.png) | [gds+lef](outputs/lpflow_clkbufkapwr_2/) |
| `lpflow_clkbufkapwr_4` | ✅ closed | 8 | [log](logs/lpflow_clkbufkapwr_4.log) | [view](renders/lpflow_clkbufkapwr_4.png) | [gds+lef](outputs/lpflow_clkbufkapwr_4/) |
| `lpflow_clkbufkapwr_8` | ✅ closed | 37 | [log](logs/lpflow_clkbufkapwr_8.log) | [view](renders/lpflow_clkbufkapwr_8.png) | [gds+lef](outputs/lpflow_clkbufkapwr_8/) |
| `lpflow_clkinvkapwr_1` | ✅ closed | 2 | [log](logs/lpflow_clkinvkapwr_1.log) | [view](renders/lpflow_clkinvkapwr_1.png) | [gds+lef](outputs/lpflow_clkinvkapwr_1/) |
| `lpflow_clkinvkapwr_16` | ❌ open | 107 | [log](logs/lpflow_clkinvkapwr_16.log) | [view](renders/lpflow_clkinvkapwr_16.png) | [gds+lef](outputs/lpflow_clkinvkapwr_16/) |
| `lpflow_clkinvkapwr_2` | ✅ closed | 3 | [log](logs/lpflow_clkinvkapwr_2.log) | [view](renders/lpflow_clkinvkapwr_2.png) | [gds+lef](outputs/lpflow_clkinvkapwr_2/) |
| `lpflow_clkinvkapwr_4` | ✅ closed | 10 | [log](logs/lpflow_clkinvkapwr_4.log) | [view](renders/lpflow_clkinvkapwr_4.png) | [gds+lef](outputs/lpflow_clkinvkapwr_4/) |
| `lpflow_clkinvkapwr_8` | ✅ closed | 35 | [log](logs/lpflow_clkinvkapwr_8.log) | [view](renders/lpflow_clkinvkapwr_8.png) | [gds+lef](outputs/lpflow_clkinvkapwr_8/) |
| `lpflow_decapkapwr_12` | ❌ open | 1 | [log](logs/lpflow_decapkapwr_12.log) | [view](renders/lpflow_decapkapwr_12.png) | [gds+lef](outputs/lpflow_decapkapwr_12/) |
| `lpflow_decapkapwr_3` | ❌ open | 1 | [log](logs/lpflow_decapkapwr_3.log) | [view](renders/lpflow_decapkapwr_3.png) | [gds+lef](outputs/lpflow_decapkapwr_3/) |
| `lpflow_decapkapwr_4` | ❌ open | 2 | [log](logs/lpflow_decapkapwr_4.log) | [view](renders/lpflow_decapkapwr_4.png) | [gds+lef](outputs/lpflow_decapkapwr_4/) |
| `lpflow_decapkapwr_6` | ❌ open | 1 | [log](logs/lpflow_decapkapwr_6.log) | [view](renders/lpflow_decapkapwr_6.png) | [gds+lef](outputs/lpflow_decapkapwr_6/) |
| `lpflow_decapkapwr_8` | ❌ open | 1 | [log](logs/lpflow_decapkapwr_8.log) | [view](renders/lpflow_decapkapwr_8.png) | [gds+lef](outputs/lpflow_decapkapwr_8/) |
| `lpflow_inputiso0n_1` | ✅ closed | 5 | [log](logs/lpflow_inputiso0n_1.log) | [view](renders/lpflow_inputiso0n_1.png) | [gds+lef](outputs/lpflow_inputiso0n_1/) |
| `lpflow_inputiso0p_1` | ✅ closed | 9 | [log](logs/lpflow_inputiso0p_1.log) | [view](renders/lpflow_inputiso0p_1.png) | [gds+lef](outputs/lpflow_inputiso0p_1/) |
| `lpflow_inputiso1n_1` | ✅ closed | 8 | [log](logs/lpflow_inputiso1n_1.log) | [view](renders/lpflow_inputiso1n_1.png) | [gds+lef](outputs/lpflow_inputiso1n_1/) |
| `lpflow_inputiso1p_1` | ✅ closed | 5 | [log](logs/lpflow_inputiso1p_1.log) | [view](renders/lpflow_inputiso1p_1.png) | [gds+lef](outputs/lpflow_inputiso1p_1/) |
| `lpflow_inputisolatch_1` | ❌ open | 300 | [log](logs/lpflow_inputisolatch_1.log) | [view](renders/lpflow_inputisolatch_1.png) | [gds+lef](outputs/lpflow_inputisolatch_1/) |
| `lpflow_isobufsrc_1` | ✅ closed | 5 | [log](logs/lpflow_isobufsrc_1.log) | [view](renders/lpflow_isobufsrc_1.png) | [gds+lef](outputs/lpflow_isobufsrc_1/) |
| `lpflow_isobufsrc_16` | ❌ open | 245 | [log](logs/lpflow_isobufsrc_16.log) | [view](renders/lpflow_isobufsrc_16.png) | [gds+lef](outputs/lpflow_isobufsrc_16/) |
| `lpflow_isobufsrc_2` | ✅ closed | 11 | [log](logs/lpflow_isobufsrc_2.log) | [view](renders/lpflow_isobufsrc_2.png) | [gds+lef](outputs/lpflow_isobufsrc_2/) |
| `lpflow_isobufsrc_4` | ✅ closed | 21 | [log](logs/lpflow_isobufsrc_4.log) | [view](renders/lpflow_isobufsrc_4.png) | [gds+lef](outputs/lpflow_isobufsrc_4/) |
| `lpflow_isobufsrc_8` | ✅ closed | 59 | [log](logs/lpflow_isobufsrc_8.log) | [view](renders/lpflow_isobufsrc_8.png) | [gds+lef](outputs/lpflow_isobufsrc_8/) |
| `lpflow_isobufsrckapwr_16` | ❌ open | 300 | [log](logs/lpflow_isobufsrckapwr_16.log) | [view](renders/lpflow_isobufsrckapwr_16.png) | [gds+lef](outputs/lpflow_isobufsrckapwr_16/) |
| `lpflow_lsbuf_lh_hl_isowell_tap_1` | ❌ open | 3 | [log](logs/lpflow_lsbuf_lh_hl_isowell_tap_1.log) | [view](renders/lpflow_lsbuf_lh_hl_isowell_tap_1.png) | [gds+lef](outputs/lpflow_lsbuf_lh_hl_isowell_tap_1/) |
| `lpflow_lsbuf_lh_hl_isowell_tap_2` | ❌ open | 3 | [log](logs/lpflow_lsbuf_lh_hl_isowell_tap_2.log) | [view](renders/lpflow_lsbuf_lh_hl_isowell_tap_2.png) | [gds+lef](outputs/lpflow_lsbuf_lh_hl_isowell_tap_2/) |
| `lpflow_lsbuf_lh_hl_isowell_tap_4` | ❌ open | 4 | [log](logs/lpflow_lsbuf_lh_hl_isowell_tap_4.log) | [view](renders/lpflow_lsbuf_lh_hl_isowell_tap_4.png) | [gds+lef](outputs/lpflow_lsbuf_lh_hl_isowell_tap_4/) |
| `lpflow_lsbuf_lh_isowell_4` | ✅ closed | 41 | [log](logs/lpflow_lsbuf_lh_isowell_4.log) | [view](renders/lpflow_lsbuf_lh_isowell_4.png) | [gds+lef](outputs/lpflow_lsbuf_lh_isowell_4/) |
| `lpflow_lsbuf_lh_isowell_tap_1` | ❌ open | 3 | [log](logs/lpflow_lsbuf_lh_isowell_tap_1.log) | [view](renders/lpflow_lsbuf_lh_isowell_tap_1.png) | [gds+lef](outputs/lpflow_lsbuf_lh_isowell_tap_1/) |
| `lpflow_lsbuf_lh_isowell_tap_2` | ❌ open | 3 | [log](logs/lpflow_lsbuf_lh_isowell_tap_2.log) | [view](renders/lpflow_lsbuf_lh_isowell_tap_2.png) | [gds+lef](outputs/lpflow_lsbuf_lh_isowell_tap_2/) |
| `lpflow_lsbuf_lh_isowell_tap_4` | ❌ open | 4 | [log](logs/lpflow_lsbuf_lh_isowell_tap_4.log) | [view](renders/lpflow_lsbuf_lh_isowell_tap_4.png) | [gds+lef](outputs/lpflow_lsbuf_lh_isowell_tap_4/) |

---
_Generated by `src/cellgen/gen_status.sh` from `recipes/cell_categories.tsv` and `status/results.tsv`._
