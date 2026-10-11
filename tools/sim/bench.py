#!/usr/bin/env python3
"""The simulator bench: set the numbers in a browser, run the fast sim, read it.

    python tools/sim/bench.py            # opens http://127.0.0.1:8765
    python tools/sim/bench.py --port 8770 --no-open

A local page over the surrogate (model.py). Each world of a run is its own
low-priority process, so a changed game number lives only in that run: the
game's files and saves are never written. Finished runs are kept under
tools/sim/bench_runs/ (ignored by git) so they can be compared later.
"""
from __future__ import annotations

import argparse
import json
import multiprocessing as mp
import os
import queue as queue_mod
import subprocess
import sys
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

SIM = Path(__file__).resolve().parent
sys.path.insert(0, str(SIM))
import bench_worker as worker  # noqa: E402

RUNS = SIM / "bench_runs"
KEEP_RUNS = 40
MAX_YEARS = 3000
MAX_WORLDS = 8
PARALLEL = max(1, min(8, (os.cpu_count() or 4) - 2))
LOCK = threading.RLock()
JOBS: dict[str, "Job"] = {}
PENDING: list[tuple["Job", int]] = []
RUNNING: list[tuple["Job", int, mp.Process]] = []


def record_every(years: int) -> float:
    """A row a year; a longer run thins them so the page stays quick."""
    return 1.0 if years <= 1500 else 2.0


class Job:
    def __init__(self, name: str, spec: dict):
        self.id = time.strftime("%Y%m%d-%H%M%S") + f"-{int(time.time() * 1000) % 1000:03d}"
        self.name = name
        self.spec = spec
        self.seeds = [int(spec.get("seed0", 1)) + i for i in range(int(spec["worlds"]))]
        self.rows: dict[int, list] = {s: [] for s in self.seeds}
        self.extra: dict[int, dict] = {}
        self.errors: dict[int, str] = {}
        self.queue = mp.Queue()
        self.status = "waiting"
        self.created = time.time()
        self.finished = 0.0
        self.expect = int(int(spec["years"]) / float(spec["record_every"])) + 1

    def meta(self) -> dict:
        return {"id": self.id, "name": self.name, "spec": self.spec, "seeds": self.seeds, "status": self.status, "created": self.created,
                "seconds": round((self.finished or time.time()) - self.created, 1), "expect": self.expect,
                "errors": self.errors, "got": {str(s): len(r) for s, r in self.rows.items()}}

    def drain(self) -> None:
        while True:
            try:
                kind, seed, payload = self.queue.get_nowait()
            except (queue_mod.Empty, EOFError, OSError):
                return
            if kind == "row":
                self.rows[seed].append(payload)
            elif kind == "done":
                self.extra[seed] = payload
            elif kind == "error":
                self.errors[seed] = payload

    def settled(self, seed: int) -> bool:
        return seed in self.extra or seed in self.errors

    def save(self) -> None:
        RUNS.mkdir(exist_ok=True)
        doc = {"meta": self.meta(), "rows": {str(s): r for s, r in self.rows.items()}, "extra": {str(s): e for s, e in self.extra.items()}}
        (RUNS / f"{self.id}.json").write_text(json.dumps(doc, separators=(",", ":")), encoding="utf-8")
        for old in sorted(RUNS.glob("*.json"))[:-KEEP_RUNS]:
            old.unlink(missing_ok=True)


def scheduler() -> None:
    """Start waiting worlds as processes come free; collect what they send."""
    ctx = mp.get_context("spawn")
    while True:
        time.sleep(0.15)
        with LOCK:
            for job in list(JOBS.values()):
                job.drain()
            for entry in list(RUNNING):
                job, seed, proc = entry
                if proc.is_alive():
                    continue
                job.drain()
                if not job.settled(seed):
                    time.sleep(0.2)
                    job.drain()
                if not job.settled(seed) and job.status != "stopped":
                    job.errors[seed] = f"the world's process ended without finishing (exit code {proc.exitcode})"
                RUNNING.remove(entry)
            while PENDING and len(RUNNING) < PARALLEL:
                job, seed = PENDING.pop(0)
                if job.status == "stopped":
                    continue
                proc = ctx.Process(target=worker.run_seed, args=(job.spec, seed, job.queue), daemon=True)
                proc.start()
                job.status = "running"
                RUNNING.append((job, seed, proc))
            for job in JOBS.values():
                if job.status == "running" and all(job.settled(s) for s in job.seeds):
                    job.status = "error" if job.errors and not job.extra else "done"
                    job.finished = time.time()
                    try:
                        job.save()
                    except OSError as e:
                        job.errors[-1] = f"could not save the run: {e}"


def start_run(body: dict) -> dict:
    spec = dict(body.get("spec") or {})
    spec["years"] = max(10, min(MAX_YEARS, int(spec.get("years", 600))))
    spec["worlds"] = max(1, min(MAX_WORLDS, int(spec.get("worlds", 1))))
    spec["record_every"] = record_every(spec["years"])
    job = Job(str(body.get("name") or "Run")[:80], spec)
    with LOCK:
        JOBS[job.id] = job
        PENDING.extend((job, s) for s in job.seeds)
    return job.meta()


def stop_run(job_id: str) -> dict:
    with LOCK:
        job = JOBS.get(job_id)
        if not job:
            return {"error": "no such run"}
        job.status = "stopped"
        job.finished = time.time()
        PENDING[:] = [(j, s) for j, s in PENDING if j is not job]
        for j, _s, proc in RUNNING:
            if j is job and proc.is_alive():
                proc.terminate()
        # What it reached is still worth reading: keep it like a finished run.
        job.drain()
        if any(job.rows.values()):
            try:
                job.save()
            except OSError:
                pass
        return job.meta()


def poll(job_id: str, cursors: dict) -> dict:
    with LOCK:
        job = JOBS.get(job_id)
        if not job:
            return {"error": "no such run"}
        out = job.meta()
        out["rows"] = {str(s): job.rows[s][int(cursors.get(str(s), 0)):] for s in job.seeds}
        out["extra"] = {str(s): e for s, e in job.extra.items()} if job.status in ("done", "error", "stopped") else {}
        return out


def saved_list() -> list:
    live = {j.id for j in JOBS.values() if j.status in ("waiting", "running")}
    out = []
    for path in sorted(RUNS.glob("*.json"), reverse=True):
        if path.stem in live:
            continue
        try:
            with path.open(encoding="utf-8") as f:
                head = f.read(200000)
            # The meta block leads the file; read it without loading every row.
            end = head.index(',"rows":')
            out.append(json.loads(head[:end] + "}")["meta"])
        except (ValueError, KeyError, OSError):
            continue
    return out


def git_rev() -> str:
    try:
        return subprocess.run(["git", "-C", str(SIM), "rev-parse", "--short", "HEAD"], capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return ""


def meta() -> dict:
    import gamedata as gd
    import model
    import simlib
    table, sites = simlib.scenarios()
    _constants, cat = simlib.data()

    def side(name: str) -> dict:
        path = SIM / name
        return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    return {
        "knobs": worker.knob_catalog(), "labels": side("bench_labels.json"), "effects": side("bench_effects.json"),
        "sites": {k: {a: b for a, b in v.items() if isinstance(b, (int, float))} for k, v in sites.items()},
        "paths": list(model.PATH_WORK.keys()) or ["balanced"], "ambitions": list(model.AMBITION_WORK.keys()) or ["makers"],
        "roles": list(model.ROLES), "lines": list(gd.LINES), "research": table["path_balanced"]["research"],
        "splits": {k[6:]: v["manual"] for k, v in table.items() if k.startswith("split_") and v.get("manual")},
        "landmarks": worker.landmarks(cat), "rev": git_rev(), "parallel": PARALLEL, "max_years": MAX_YEARS, "max_worlds": MAX_WORLDS,
        "questions": cat.n,
    }


class Handler(BaseHTTPRequestHandler):
    server_version = "SimBench/1"

    def log_message(self, *_args) -> None:
        pass

    def _send(self, code: int, body: bytes, kind: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, obj, code: int = 200) -> None:
        self._send(code, json.dumps(obj, separators=(",", ":")).encode("utf-8"), "application/json")

    def _body(self) -> dict:
        n = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(n) or b"{}") if n else {}

    def do_GET(self) -> None:  # noqa: N802
        url = urlparse(self.path)
        parts = [p for p in url.path.split("/") if p]
        try:
            if not parts:
                self._send(200, (SIM / "bench.html").read_bytes(), "text/html; charset=utf-8")
            elif parts == ["api", "meta"]:
                self._json(self.server.meta)
            elif parts == ["api", "runs"]:
                with LOCK:
                    live = [j.meta() for j in sorted(JOBS.values(), key=lambda j: -j.created) if j.status in ("waiting", "running")]
                self._json({"live": live, "saved": saved_list()})
            elif parts[:2] == ["api", "run"] and len(parts) == 3:
                self._json(poll(parts[2], json.loads(parse_qs(url.query).get("c", ["{}"])[0])))
            elif parts[:2] == ["api", "saved"] and len(parts) == 3:
                path = RUNS / f"{Path(parts[2]).name}.json"
                if path.exists():
                    self._send(200, path.read_bytes(), "application/json")
                else:
                    self._json({"error": "no such run"}, 404)
            else:
                self._json({"error": "not found"}, 404)
        except (BrokenPipeError, ConnectionError):
            pass
        except Exception as e:  # the page shows it
            self._json({"error": f"{type(e).__name__}: {e}"}, 500)

    def do_POST(self) -> None:  # noqa: N802
        parts = [p for p in urlparse(self.path).path.split("/") if p]
        try:
            if parts == ["api", "run"]:
                self._json(start_run(self._body()))
            elif parts[:2] == ["api", "stop"] and len(parts) == 3:
                self._json(stop_run(parts[2]))
            elif parts[:2] == ["api", "forget"] and len(parts) == 3:
                stop_run(parts[2])
                with LOCK:
                    JOBS.pop(parts[2], None)
                (RUNS / f"{Path(parts[2]).name}.json").unlink(missing_ok=True)
                self._json({"ok": True})
            else:
                self._json({"error": "not found"}, 404)
        except Exception as e:
            self._json({"error": f"{type(e).__name__}: {e}"}, 500)


def check() -> int:
    """The bench's own smoke test: the numbers load and a world runs with one changed."""
    m = meta()
    sent = queue_mod.Queue()
    spec = {"years": 5, "record_every": 1.0, "path": "balanced", "mode": "leaders", "towns": True, "knobs": {"model.CULTIVATION_YIELD": 6.0, "p.harvest_mult": 1.2}}
    worker.run_seed(spec, 1, sent)
    got = list(sent.queue)
    rows = [x for x in got if x[0] == "row"]
    if got[-1][0] != "done" or len(rows) != 6 or "births_rate" not in rows[-1][2]:
        print("BENCH CHECK FAIL", got[-1][0], got[-1][2] if got[-1][0] == "error" else len(rows))
        return 1
    print(f"BENCH CHECK PASS  {len(m['knobs'])} numbers, {len(rows[-1][2])} readings a year, {len(m['landmarks'])} landmarks")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--no-open", action="store_true", help="do not open the browser")
    ap.add_argument("--check", action="store_true", help="read the numbers, run one 5-year world, and exit (0 = the bench works)")
    args = ap.parse_args()
    if args.check:
        return check()
    print("Reading the game's numbers...", flush=True)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    server.meta = meta()
    threading.Thread(target=scheduler, daemon=True).start()
    url = f"http://127.0.0.1:{args.port}/"
    print(f"Simulator bench at {url}  (game {server.meta['rev']}, {len(server.meta['knobs'])} numbers, up to {PARALLEL} worlds at once). Ctrl+C stops it.", flush=True)
    if not args.no_open:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    with LOCK:
        for _j, _s, proc in RUNNING:
            if proc.is_alive():
                proc.terminate()
    return 0


if __name__ == "__main__":
    sys.exit(main())
