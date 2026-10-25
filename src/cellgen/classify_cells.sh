#!/usr/bin/env bash
# Classify every sky130_fd_sc_hd cell into a functional category.
# Emits: <cell>\t<category>   (one per line, sorted).  First matching rule wins.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cells=$(grep -E '^\.SUBCKT ' "$ROOT/cells/sky130_hd_all_cells.sp" | sed -E 's/^\.SUBCKT sky130_fd_sc_hd__//; s/ .*//' | sort)

classify(){
  case "$1" in
    inv_*|clkinv_*|clkinvlp_*|bufinv_*)                cat=inverter ;;
    buf_*|bufbuf_*|clkbuf_*)                            cat=buffer ;;
    clkdlybuf*|dlygate*|dlymetal*)                      cat=clock_delay ;;
    and[0-9]*|or[0-9]*)                                 cat=and_or ;;
    nand*|nor*)                                         cat=nand_nor ;;
    xor*|xnor*)                                         cat=xor_xnor ;;
    mux*)                                               cat=mux ;;
    fa|fa_*|fah*|ha|ha_*|maj*)                          cat=adder ;;
    a[0-9]*)                                            cat=aoi ;;
    o[0-9]*)                                            cat=oai ;;
    einv*|ebuf*)                                        cat=tristate ;;
    sdlclkp*|dlclkp*|dl[xr]*)                           cat=latch ;;
    sedf*|sdf*|edf*|df*)                                cat=flipflop ;;
    conb*|probe*|probec*)                              cat=tie_probe ;;
    fill*|decap*|tap*|diode*|macro*)                    cat=fill_phys ;;
    lpflow*|*isowell*)                                  cat=lpflow_pwr ;;
    *)                                                  cat=OTHER ;;
  esac
  echo "$cat"
}

for c in $cells; do printf '%s\t%s\n' "$c" "$(classify "$c")"; done
