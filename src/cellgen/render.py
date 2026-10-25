#!/usr/bin/env python3
"""Render a generated cell's GDSII layout to a labeled PNG.

Each GDS (Graphic Design System) layer is drawn in its own color with pin/label
text overlaid, so you can eyeball the transistors, routing, and I/O pins.

Usage:
    src/cellgen/render.py <cell> [--gds PATH] [--out PATH] [--work DIR]

By default it reads   <repo>/.work/out/sky130_fd_sc_hd__<cell>.gds
and writes            <repo>/results/renders/<cell>.png
so the typical flow is:
    src/cellgen/run_cell.sh inv_1        # build it
    src/cellgen/render.py    inv_1        # view it
"""
import sys, os, argparse
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MplPoly
import klayout.db as db

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def main():
    ap = argparse.ArgumentParser(description="Render a cell's GDS to a labeled PNG.")
    ap.add_argument("cell", help="short cell name, e.g. inv_1")
    ap.add_argument("--gds", help="explicit GDS path (overrides the default lookup)")
    ap.add_argument("--work", default=os.path.join(REPO, ".work"), help="work dir holding out/")
    ap.add_argument("--out", help="output PNG path")
    a = ap.parse_args()

    full = f"sky130_fd_sc_hd__{a.cell}"
    gds = a.gds or os.path.join(a.work, "out", f"{full}.gds")
    if not os.path.exists(gds):
        sys.exit(f"GDS not found: {gds}\n"
                 f"Build the cell first:  src/cellgen/run_cell.sh {a.cell}")
    out = a.out or os.path.join(REPO, "results", "renders", f"{a.cell}.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)

    ly = db.Layout(); ly.read(gds); dbu = ly.dbu
    top = ly.top_cell(); bb = top.bbox()
    w_um, h_um = bb.width() * dbu, bb.height() * dbu
    print(f"cell: {top.name}")
    print(f"bbox: {w_um:.3f} x {h_um:.3f} um  (W x H)")

    fig, ax = plt.subplots(figsize=(9, 6))
    cmap = plt.get_cmap("tab20")
    print(f"{'layer/dt':<10}{'shapes':>7}")
    for i, li in enumerate(ly.layer_indices()):
        info = ly.get_info(li); name = f"{info.layer}/{info.datatype}"
        reg = db.Region(); reg.insert(top.begin_shapes_rec(li))
        polys = list(reg.each()); ntxt = 0; col = cmap(i % 20)
        for poly in polys:
            pts = [(p.x * dbu, p.y * dbu) for p in poly.each_point_hull()]
            ax.add_patch(MplPoly(pts, closed=True, facecolor=col, edgecolor='k', lw=0.3, alpha=0.55))
        for sh in top.shapes(li).each():
            if sh.is_text():
                t = sh.text
                ax.text(t.x * dbu, t.y * dbu, t.string, fontsize=7, ha='center',
                        va='center', color='red', weight='bold'); ntxt += 1
        if polys or ntxt:
            print(f"{name:<10}{len(polys):>7}{'  +'+str(ntxt)+' labels' if ntxt else ''}")
            if polys:
                ax.add_patch(MplPoly([(0, 0)] * 3, label=name, facecolor=col, alpha=.55))

    ax.set_xlim(bb.left * dbu - 0.2, bb.right * dbu + 0.2)
    ax.set_ylim(bb.bottom * dbu - 0.2, bb.top * dbu + 0.2)
    ax.set_aspect('equal'); ax.set_xlabel("um"); ax.set_ylabel("um")
    ax.set_title(f"{top.name}, {w_um:.2f} x {h_um:.2f} um  (sky130-cellgen)")
    ax.legend(loc='center left', bbox_to_anchor=(1.0, 0.5), fontsize=7, title="GDS layer/dt")
    plt.tight_layout(); plt.savefig(out, dpi=140, bbox_inches='tight')
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
