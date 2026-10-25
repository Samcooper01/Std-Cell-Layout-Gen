#!/usr/bin/env python3
# Live dashboard for the automated cell sweep (src/cellgen/run_status.sh).
#
# Serves a browser GUI (Graphical User Interface) at http://127.0.0.1:8787 that shows,
# for all 437 sky130_fd_sc_hd cells: which are closed, open, pending, and which are
# running right now and what stage of the PnR (Place and Route) flow each running cell
# is in (Setup, Placement, Routing iteration N, DRC (Design Rule Check) repair, Writing
# output, LVS (Layout Versus Schematic)). Standard library only. Read only: it never
# writes into the run, so it cannot disturb the sweep.
#
#   src/cellgen/status_server.py                 # serve on 127.0.0.1:8787
#   PORT=9000 src/cellgen/status_server.py       # pick a port
#
import os
import re
import json
import html
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MAP = os.path.join(ROOT, "recipes", "cell_categories.tsv")
RESPART = os.path.join(ROOT, "status", "results.tsv.part")
WORK = os.path.join(ROOT, ".work", "status")
RENDERS = os.path.join(ROOT, "status", "renders")
LOGS = os.path.join(ROOT, "status", "logs")
CAP_SECONDS = int(os.environ.get("TIMEOUT", "300"))  # per cell 5 minute cap

# Category order and human titles, mirrored from src/cellgen/gen_status.sh so the grid
# reads the same as the published STATUS.md table.
ORDER = ["inverter", "buffer", "and_or", "nand_nor", "aoi", "oai", "xor_xnor", "mux",
         "adder", "tristate", "flipflop", "latch", "clock_delay", "tie_probe",
         "fill_phys", "lpflow_pwr"]
TITLE = {
    "inverter": "Inverters", "buffer": "Buffers", "and_or": "AND / OR gates",
    "nand_nor": "NAND / NOR gates", "aoi": "AND OR Invert (AOI)",
    "oai": "OR AND Invert (OAI)", "xor_xnor": "XOR / XNOR", "mux": "Multiplexers",
    "adder": "Adders / majority", "tristate": "Tristate / enabled drivers",
    "flipflop": "Flip flops", "latch": "Latches", "clock_delay": "Clock & delay",
    "tie_probe": "Tie & probe", "fill_phys": "Fill / physical",
    "lpflow_pwr": "Low power / level shift / isolation",
}

TS_RE = re.compile(r"^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)")
INFO_RE = re.compile(r"^\d[\d\- :]+\s+([A-Za-z_.]+)\s+(?:INFO|WARNING|ERROR):\s*(.*)$")
ITER_RE = re.compile(r"[Rr]outing iteration\s+(\d+)")
SAFE_CELL = re.compile(r"^[A-Za-z0-9_]+$")


def load_categories():
    """Return (ordered list of cells per category, cell -> category)."""
    by_cat, cell_cat = {c: [] for c in ORDER}, {}
    try:
        with open(MAP) as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if len(parts) < 2:
                    continue
                cell, cat = parts[0], parts[1]
                if cat in by_cat:
                    by_cat[cat].append(cell)
                    cell_cat[cell] = cat
    except OSError:
        pass
    for c in by_cat:
        by_cat[c].sort()
    return by_cat, cell_cat


def load_results():
    """Parse results.tsv.part, last write per cell wins -> cell -> (status, secs)."""
    out = {}
    try:
        with open(RESPART) as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if len(parts) >= 2 and parts[0]:
                    out[parts[0]] = (parts[1], parts[2] if len(parts) > 2 else "")
    except OSError:
        pass
    return out


def active_cells():
    """Scan /proc for run_cell.sh <cell> workers -> set of currently running cells."""
    live = set()
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            with open("/proc/%s/cmdline" % pid, "rb") as f:
                toks = [t.decode("utf-8", "replace") for t in f.read().split(b"\x00") if t]
        except OSError:
            continue
        for i, tok in enumerate(toks):
            if tok.endswith("run_cell.sh") and i + 1 < len(toks):
                live.add(toks[i + 1])
    return live


def stage_label(module, msg):
    m = module.lower()
    if "lvs" in msg.lower():
        return "LVS (Layout Versus Schematic)"
    if "placer" in m:
        return "Placement"
    if "pathfinder" in m or "router" in m:
        return "Routing"
    if "drc" in m:
        return "DRC (Design Rule Check) repair"
    if "writer" in m:
        return "Writing output"
    if "tech" in m:
        return "Setup"
    return "Working"


def live_stage(cell):
    """Read a running cell's build.log -> (stage, detail, elapsed_seconds)."""
    path = os.path.join(WORK, cell, "build.log")
    try:
        with open(path, "r", errors="replace") as f:
            lines = f.readlines()
    except OSError:
        return ("Starting", "", 0)
    first_ts = last_ts = None
    for line in lines:
        m = TS_RE.match(line)
        if m:
            if first_ts is None:
                first_ts = m.group(1)
            last_ts = m.group(1)
    elapsed = 0
    if first_ts and last_ts:
        elapsed = _ts_delta(first_ts, last_ts)
    stage, detail, last_iter = "Starting", "", None
    for line in reversed(lines):
        it = ITER_RE.search(line)
        if it and last_iter is None:
            last_iter = it.group(1)
        m = INFO_RE.match(line)
        if m:
            stage = stage_label(m.group(1), m.group(2))
            break
    if stage == "Routing" and last_iter is not None:
        detail = "iteration %s" % last_iter
    return (stage, detail, elapsed)


def _ts_delta(a, b):
    # Difference in seconds between two "YYYY-MM-DD HH:MM:SS" stamps, no timezone math.
    def secs(t):
        d, tm = t.split(" ")
        y, mo, dy = (int(x) for x in d.split("-"))
        h, mi, s = (int(x) for x in tm.split(":"))
        return ((((y * 12 + mo) * 31 + dy) * 24 + h) * 60 + mi) * 60 + s
    return max(0, secs(b) - secs(a))


# Ordered stages of the flow, used to draw the per cell timeline. Labels carry their
# acronym expansions so the GUI (Graphical User Interface) shows them expanded.
STAGES = ["Setup", "Placement", "Routing", "DRC (Design Rule Check) repair",
          "Writing output", "LVS (Layout Versus Schematic)"]


def cell_detail(cell):
    """Full live detail for one cell: current stage, stage timeline (when each stage was
    first reached), the routing iteration-vs-time series for the convergence chart, and
    the tail of its verbose log."""
    live = cell in active_cells()
    live_path = os.path.join(WORK, cell, "build.log")
    saved = os.path.join(LOGS, cell + ".log")
    src = live_path if os.path.exists(live_path) else (saved if os.path.exists(saved) else None)
    lines = []
    if src:
        try:
            with open(src, "r", errors="replace") as f:
                lines = f.readlines()
        except OSError:
            lines = []

    first_ts = last_ts = None
    reached = {}   # stage -> seconds after start when first seen
    iters = []     # [seconds_after_start, routing_iteration]
    cur_stage = "Starting"
    for line in lines:
        m = TS_RE.match(line)
        if m:
            if first_ts is None:
                first_ts = m.group(1)
            last_ts = m.group(1)
        mm = INFO_RE.match(line)
        if mm:
            st = stage_label(mm.group(1), mm.group(2))
            cur_stage = st
            if st in STAGES and st not in reached and first_ts and last_ts:
                reached[st] = _ts_delta(first_ts, last_ts)
        it = ITER_RE.search(line)
        if it and first_ts and last_ts:
            iters.append([_ts_delta(first_ts, last_ts), int(it.group(1))])

    results = load_results()
    st, secs = results.get(cell, ("pending", ""))
    status = "running" if live else (st if st in ("closed", "open") else "pending")

    elapsed = _ts_delta(first_ts, last_ts) if (first_ts and last_ts) else 0
    if not live and secs:
        try:
            elapsed = int(float(secs))
        except ValueError:
            pass

    # routing iterations per second over roughly the last 15 seconds of samples
    rate = 0.0
    if len(iters) >= 2:
        t_end, i_end = iters[-1]
        ref = iters[0]
        for t, i in reversed(iters):
            if t_end - t >= 15:
                ref = [t, i]
                break
        if t_end - ref[0] > 0:
            rate = (i_end - ref[1]) / (t_end - ref[0])

    timeline = [{"stage": s, "reached": s in reached, "t": reached.get(s)} for s in STAGES]
    return {
        "cell": cell, "status": status,
        "stage": cur_stage if live else status,
        "elapsed": elapsed, "cap": CAP_SECONDS, "secs": secs,
        "timeline": timeline, "iters": iters,
        "iter_now": iters[-1][1] if iters else None, "rate": round(rate, 2),
        "render": os.path.exists(os.path.join(RENDERS, cell + ".png")),
        "log": ("".join(lines)[-20000:]) if lines else "(no log yet)",
    }


def snapshot():
    by_cat, _ = load_categories()
    results = load_results()
    live = active_cells()
    totals = {"closed": 0, "open": 0, "running": 0, "pending": 0, "total": 0}
    cats = []
    for cat in ORDER:
        cells_out = []
        for cell in by_cat.get(cat, []):
            totals["total"] += 1
            has_render = os.path.exists(os.path.join(RENDERS, cell + ".png"))
            if cell in live:
                stage, detail, elapsed = live_stage(cell)
                totals["running"] += 1
                cells_out.append({
                    "cell": cell, "status": "running", "stage": stage, "detail": detail,
                    "elapsed": elapsed, "cap": CAP_SECONDS, "render": has_render,
                })
                continue
            st, secs = results.get(cell, ("pending", ""))
            if st not in ("closed", "open"):
                st = "pending"
            totals[st] += 1
            cells_out.append({
                "cell": cell, "status": st, "secs": secs, "render": has_render,
            })
        cats.append({"key": cat, "title": TITLE[cat], "cells": cells_out})
    return {"totals": totals, "cats": cats}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass  # quiet; do not spam the terminal running the sweep

    def _send(self, code, body, ctype):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except BrokenPipeError:
            pass

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/":
            return self._send(200, PAGE, "text/html; charset=utf-8")
        if path == "/api/status":
            return self._send(200, json.dumps(snapshot()), "application/json")
        if path.startswith("/api/cell/"):
            cell = path[len("/api/cell/"):]
            if not SAFE_CELL.match(cell):
                return self._send(400, "bad cell", "text/plain")
            return self._send(200, json.dumps(cell_detail(cell)), "application/json")
        if path.startswith("/log/"):
            cell = path[len("/log/"):]
            if not SAFE_CELL.match(cell):
                return self._send(400, "bad cell", "text/plain")
            live_path = os.path.join(WORK, cell, "build.log")
            saved = os.path.join(LOGS, cell + ".log")
            src = live_path if os.path.exists(live_path) else saved
            try:
                with open(src, "r", errors="replace") as f:
                    data = f.read()[-20000:]
            except OSError:
                data = "(no log yet)"
            return self._send(200, data, "text/plain; charset=utf-8")
        if path.startswith("/render/"):
            cell = path[len("/render/"):].rsplit(".", 1)[0]
            if not SAFE_CELL.match(cell):
                return self._send(400, "bad cell", "text/plain")
            png = os.path.join(RENDERS, cell + ".png")
            try:
                with open(png, "rb") as f:
                    return self._send(200, f.read(), "image/png")
            except OSError:
                return self._send(404, "no render", "text/plain")
        return self._send(404, "not found", "text/plain")


PAGE = r"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cell sweep - live status</title>
<style>
  :root{
    --bg:#0d1117;--panel:#161b22;--edge:#30363d;--fg:#e6edf3;--dim:#8b949e;
    --closed:#2ea043;--open:#f85149;--run:#3b82f6;--pend:#30363d;--acc:#58a6ff;
  }
  @media (prefers-color-scheme: light){
    :root{--bg:#f6f8fa;--panel:#fff;--edge:#d0d7de;--fg:#1f2328;--dim:#636c76;--pend:#d0d7de;}
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--fg);
    font:14px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif}
  header{position:sticky;top:0;z-index:5;background:var(--panel);border-bottom:1px solid var(--edge);
    padding:14px 20px}
  h1{margin:0 0 10px;font-size:16px;font-weight:600;letter-spacing:.2px}
  h1 .live{color:var(--dim);font-weight:400}
  .stats{display:flex;gap:10px;flex-wrap:wrap;align-items:center}
  .stat{padding:4px 10px;border:1px solid var(--edge);border-radius:20px;font-size:13px}
  .stat b{font-variant-numeric:tabular-nums}
  .dot{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:6px;vertical-align:middle}
  .d-closed{background:var(--closed)}.d-open{background:var(--open)}
  .d-run{background:var(--run)}.d-pend{background:var(--pend)}
  .bar{height:8px;border-radius:5px;background:var(--pend);overflow:hidden;margin-top:10px;display:flex}
  .bar > span{height:100%}
  main{padding:16px 20px;max-width:1200px;margin:0 auto}
  .running{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:10px;margin-bottom:8px}
  .rcard{background:var(--panel);border:1px solid var(--run);border-radius:10px;padding:10px 12px}
  .rcard .name{font-weight:600;font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
  .rcard .stage{color:var(--acc);font-size:13px;margin-top:2px}
  .rcard .meta{color:var(--dim);font-size:12px;margin-top:4px;font-variant-numeric:tabular-nums}
  .rcard .cbar{height:6px;border-radius:4px;background:var(--pend);overflow:hidden;margin-top:8px}
  .rcard .cbar > i{display:block;height:100%;background:var(--run)}
  .empty{color:var(--dim);padding:6px 0 12px}
  section{margin-top:18px}
  section h2{font-size:14px;font-weight:600;margin:0 0 8px;color:var(--fg);display:flex;gap:8px;align-items:baseline}
  section h2 small{color:var(--dim);font-weight:400}
  .grid{display:flex;flex-wrap:wrap;gap:5px}
  .chip{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11px;padding:3px 7px;
    border-radius:6px;border:1px solid var(--edge);cursor:pointer;user-select:none;white-space:nowrap}
  .chip.closed{background:color-mix(in srgb,var(--closed) 22%,transparent);border-color:var(--closed)}
  .chip.open{background:color-mix(in srgb,var(--open) 20%,transparent);border-color:var(--open)}
  .chip.running{background:color-mix(in srgb,var(--run) 26%,transparent);border-color:var(--run);
    animation:pulse 1.3s ease-in-out infinite}
  .chip.pending{opacity:.55}
  @keyframes pulse{0%,100%{box-shadow:0 0 0 0 color-mix(in srgb,var(--run) 60%,transparent)}
    50%{box-shadow:0 0 0 4px transparent}}
  /* detail drawer */
  #drawer{position:fixed;top:0;right:0;height:100%;width:min(560px,92vw);background:var(--panel);
    border-left:1px solid var(--edge);transform:translateX(100%);transition:transform .18s ease;
    z-index:20;display:flex;flex-direction:column}
  #drawer.open{transform:none}
  #drawer .dhead{padding:12px 16px;border-bottom:1px solid var(--edge);display:flex;
    justify-content:space-between;align-items:center;gap:10px}
  #drawer .dhead .t{font-family:ui-monospace,monospace;font-weight:600}
  #drawer .x{cursor:pointer;color:var(--dim);border:1px solid var(--edge);border-radius:6px;padding:2px 9px}
  #drawer .body{overflow:auto;padding:12px 16px}
  #drawer img{max-width:100%;border:1px solid var(--edge);border-radius:8px;background:#fff}
  #drawer pre{background:var(--bg);border:1px solid var(--edge);border-radius:8px;padding:10px;
    overflow:auto;font-size:11px;line-height:1.4;max-height:52vh}
  .muted{color:var(--dim);margin:12px 0 4px}
  /* status badge + key/value line */
  .badge{display:inline-block;padding:2px 10px;border-radius:20px;font-size:12px;border:1px solid var(--edge);text-transform:capitalize}
  .badge.running{color:var(--run);border-color:var(--run)}
  .badge.closed{color:var(--closed);border-color:var(--closed)}
  .badge.open{color:var(--open);border-color:var(--open)}
  .badge.pending{color:var(--dim)}
  .kv{color:var(--dim);font-size:12px;font-variant-numeric:tabular-nums;margin-left:8px}
  /* vertical stage timeline */
  .tl{margin:12px 0 6px;padding-left:3px}
  .step{display:flex;gap:10px;align-items:flex-start;padding:5px 0;position:relative}
  .step .sd{width:12px;height:12px;border-radius:50%;margin-top:2px;flex:0 0 auto;
    background:var(--pend);border:2px solid var(--edge);z-index:1}
  .step.done .sd{background:var(--closed);border-color:var(--closed)}
  .step.cur .sd{background:var(--run);border-color:var(--run);animation:pulse 1.3s infinite}
  .step b{font-weight:600}.step.todo b{color:var(--dim)}
  .step small{color:var(--dim);margin-left:8px;font-variant-numeric:tabular-nums}
  .step:not(:last-child)::before{content:"";position:absolute;left:6px;top:17px;bottom:-5px;width:2px;background:var(--edge)}
  .step.done:not(:last-child)::before{background:var(--closed)}
  /* convergence chart */
  svg.chart{width:100%;height:auto;background:var(--bg);border:1px solid var(--edge);border-radius:8px}
  svg.chart text{fill:var(--dim);font-size:9px}
  svg.chart polyline{fill:none;stroke:var(--run);stroke-width:2;vector-effect:non-scaling-stroke}
  svg.chart line.axis{stroke:var(--edge);stroke-width:1}
  /* log colorized by pipeline stage */
  .lg-route{color:var(--acc)}.lg-drc{color:#a371f7}.lg-place{color:#e3b341}
  .lg-write{color:#79c0ff}.lg-ok{color:var(--closed);font-weight:600}
  .lg-warn{color:#d29922}.lg-err{color:var(--open)}
</style></head>
<body>
<header>
  <h1>Cell sweep <span class="live">live status - refreshes every 2s</span></h1>
  <div class="stats" id="stats"></div>
  <div class="bar" id="obar"></div>
</header>
<main>
  <section>
    <h2>Running now <small id="rcount"></small></h2>
    <div class="running" id="running"></div>
    <div class="empty" id="rempty" style="display:none">No cells running right now.</div>
  </section>
  <div id="cats"></div>
</main>

<div id="drawer">
  <div class="dhead"><span class="t" id="dtitle"></span><span class="x" onclick="closeDrawer()">close</span></div>
  <div class="body" id="dbody"></div>
</div>

<script>
let openCell = null;
function fmt(s){s=+s||0;let m=Math.floor(s/60),r=s%60;return m+"m "+String(r).padStart(2,"0")+"s"}
function esc(t){return t.replace(/[&<>]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]))}

async function tick(){
  let d;
  try{ d = await (await fetch("/api/status")).json() }catch(e){ return }
  const t = d.totals;
  document.getElementById("stats").innerHTML =
    `<span class="stat"><span class="dot d-closed"></span>closed <b>${t.closed}</b></span>`+
    `<span class="stat"><span class="dot d-open"></span>open <b>${t.open}</b></span>`+
    `<span class="stat"><span class="dot d-run"></span>running <b>${t.running}</b></span>`+
    `<span class="stat"><span class="dot d-pend"></span>pending <b>${t.pending}</b></span>`+
    `<span class="stat">total <b>${t.total}</b></span>`;
  const tot=t.total||1;
  document.getElementById("obar").innerHTML =
    `<span style="width:${100*t.closed/tot}%;background:var(--closed)"></span>`+
    `<span style="width:${100*t.open/tot}%;background:var(--open)"></span>`+
    `<span style="width:${100*t.running/tot}%;background:var(--run)"></span>`;

  // running cards
  const run=[]; d.cats.forEach(c=>c.cells.forEach(x=>{if(x.status==="running")run.push(x)}));
  document.getElementById("rcount").textContent = run.length? `(${run.length})`:"";
  document.getElementById("rempty").style.display = run.length? "none":"block";
  document.getElementById("running").innerHTML = run.map(x=>{
    const pct=Math.min(100,100*(x.elapsed||0)/(x.cap||300));
    const det=x.detail?` &middot; ${esc(x.detail)}`:"";
    return `<div class="rcard"><div class="name">${x.cell}</div>`+
      `<div class="stage">${esc(x.stage)}${det}</div>`+
      `<div class="meta">${fmt(x.elapsed)} / ${fmt(x.cap)} cap</div>`+
      `<div class="cbar"><i style="width:${pct}%"></i></div></div>`;
  }).join("");

  // category grid
  document.getElementById("cats").innerHTML = d.cats.map(c=>{
    const chips = c.cells.map(x=>{
      const tip = x.status==="running" ? `${x.stage}${x.detail?" "+x.detail:""}`
        : (x.secs? `${x.status} - ${fmt(x.secs)}` : x.status);
      return `<span class="chip ${x.status}" title="${esc(tip)}" onclick="openDrawer('${x.cell}')">${x.cell}</span>`;
    }).join("");
    const n=c.cells.length;
    const cl=c.cells.filter(x=>x.status==="closed").length;
    return `<section><h2>${esc(c.title)} <small>${cl}/${n} closed</small></h2><div class="grid">${chips}</div></section>`;
  }).join("");

}

let drawerTimer=null, drawerBuiltFor=null;
function openDrawer(cell){
  openCell=cell; drawerBuiltFor=null;   // force a fresh skeleton for the new cell
  document.getElementById("drawer").classList.add("open");
  document.getElementById("dtitle").textContent=cell;
  loadDetail();
  clearInterval(drawerTimer); drawerTimer=setInterval(loadDetail,1000); // 1s live tail
}
function closeDrawer(){openCell=null;drawerBuiltFor=null;clearInterval(drawerTimer);document.getElementById("drawer").classList.remove("open")}

async function loadDetail(){
  const cell=openCell; if(!cell)return;
  let d; try{ d=await (await fetch("/api/cell/"+cell)).json() }catch(e){return}
  if(openCell!==cell)return;               // user switched cells mid-fetch
  renderDetail(d);
}

function colorLog(txt){
  return esc(txt).split("\n").map(l=>{
    let c="";
    if(/LVS result: SUCCESS/.test(l))c="lg-ok";
    else if(/ERROR|Traceback|Error|failed|FAIL/.test(l))c="lg-err";
    else if(/WARNING/.test(l))c="lg-warn";
    else if(/pathfinder|router/.test(l))c="lg-route";
    else if(/drc_cleaner/.test(l))c="lg-drc";
    else if(/placer/.test(l))c="lg-place";
    else if(/writer/.test(l))c="lg-write";
    return c?`<span class="${c}">${l}</span>`:l;
  }).join("\n");
}

function chartSvg(iters,cap){
  if(!iters||iters.length<2)return "";
  const W=520,H=150,pad=26;
  const tmax=Math.max(cap||300, iters[iters.length-1][0])||1;
  const imax=Math.max(2,...iters.map(p=>p[1]));
  const X=t=>pad+(W-pad-6)*t/tmax;
  const Y=i=>H-pad-(H-pad-8)*i/imax;
  const pts=iters.map(p=>X(p[0]).toFixed(1)+","+Y(p[1]).toFixed(1)).join(" ");
  return `<svg class="chart" viewBox="0 0 ${W} ${H}">`+
    `<line class="axis" x1="${pad}" y1="${H-pad}" x2="${W-3}" y2="${H-pad}"/>`+
    `<line class="axis" x1="${pad}" y1="6" x2="${pad}" y2="${H-pad}"/>`+
    `<text x="2" y="12">${imax} iter</text><text x="2" y="${H-pad}">0</text>`+
    `<text x="${W-26}" y="${H-6}">${Math.round(tmax)}s</text>`+
    `<text x="${pad+2}" y="${H-6}">0s</text>`+
    `<polyline points="${pts}"/></svg>`;
}

// Build the drawer once per cell; later polls patch fields in place so the image and
// log do not flash. Element ids are the stable patch targets.
function ensureSkeleton(cell){
  if(drawerBuiltFor===cell)return;
  drawerBuiltFor=cell;
  document.getElementById("dbody").innerHTML =
    `<div id="d_head"></div>`+
    `<div class="tl" id="d_tl"></div>`+
    `<div id="d_conv"></div>`+
    `<div id="d_img"></div>`+
    `<p class="muted">verbose log (live)</p><pre id="d_log"></pre>`;
}

function renderDetail(d){
  ensureSkeleton(d.cell);

  let head=`<span class="badge ${d.status}">${d.status}</span>`;
  if(d.status==="running"){
    const pct=Math.min(100,100*(d.elapsed||0)/(d.cap||300));
    head+=`<span class="kv">${esc(d.stage)} &middot; ${fmt(d.elapsed)} / ${fmt(d.cap)} cap</span>`+
      `<div style="height:6px;border-radius:4px;background:var(--pend);overflow:hidden;margin:8px 0 2px">`+
      `<i style="display:block;height:100%;width:${pct}%;background:var(--run)"></i></div>`;
  } else if(d.secs){
    head+=`<span class="kv">${fmt(d.secs)}</span>`;
  }
  document.getElementById("d_head").innerHTML=head;

  document.getElementById("d_tl").innerHTML = d.timeline.map(s=>{
    const cls = (d.status==="running"&&s.stage===d.stage)?"cur":(s.reached?"done":"todo");
    const t = s.t!=null?`${s.t}s`:"";
    return `<div class="step ${cls}"><span class="sd"></span><div><b>${esc(s.stage)}</b><small>${t}</small></div></div>`;
  }).join("");

  const conv=document.getElementById("d_conv");
  if(d.iters&&d.iters.length>1){
    const rate=d.rate?` &middot; ${d.rate} iter/s`:"";
    conv.innerHTML=`<p class="muted">routing convergence: iteration ${d.iter_now}${rate}</p>`+chartSvg(d.iters,d.cap);
  } else conv.innerHTML="";

  // load the layout render exactly once (it never changes), so it does not flash
  const imgWrap=document.getElementById("d_img");
  if(d.render && !imgWrap.dataset.loaded){
    imgWrap.dataset.loaded="1";
    imgWrap.innerHTML=`<p class="muted">layout render:</p><img src="/render/${d.cell}.png" onerror="this.style.display='none'">`;
  } else if(!d.render){
    imgWrap.innerHTML=""; imgWrap.dataset.loaded="";
  }

  // patch the log text only, preserving the reader's scroll position (live tail)
  const pre=document.getElementById("d_log");
  const wasBottom = pre.scrollTop+pre.clientHeight>=pre.scrollHeight-30;
  pre.innerHTML=colorLog(d.log||"");
  if(wasBottom) pre.scrollTop=pre.scrollHeight;
}

tick(); setInterval(tick, 2000);
</script>
</body></html>"""


def main():
    port = int(os.environ.get("PORT", "8787"))
    srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print("cell sweep dashboard: http://127.0.0.1:%d  (Ctrl-C to stop)" % port)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
