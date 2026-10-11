"""The simulator bench's real-game side: one headless Godot per world, running
the game's own rules (tools/sim/bench_probe.gd) and sending a row a year.

Nothing here re-types a rule. The people is the truth probe's disposable one
(never the player's game or saves); with ``span`` above 1 it steps as a calm
people the player has not met does (scripts/day_span.gd): several days at a
time on the same rules, daily whenever its food, water or wars ask for it.

A changed game number is a changed ``const`` line: the run then uses a copy of
the game's scripts with those lines rewritten (``patched_project``), under
tools/sim/bench_runs/projects/. The game's own files are never written.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path

SIM = Path(__file__).resolve().parent
ROOT = SIM.parent.parent
RUNS = SIM / "bench_runs"
DEFAULT_GODOT = r"C:\Users\sjpur\leviathan\tools\godot\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe"
SITE_SCENARIO = {"good": "sensible", "average": "average", "poor": "poorland"}
# Worlds of the real game at once: each is a whole engine.
PARALLEL = max(1, min(4, (os.cpu_count() or 4) // 4))
HARVEST = {"fresh plants": "plants", "plants": "plants", "meat": "meat", "fish": "fish", "dry staples": "staples", "staples": "staples"}
RAW = ("Timber", "Stone", "Clay", "Fiber Plants", "Flint")
# The files whose numbers the bench offers: the rules of people, food, work,
# learning, making, the watch, land, building and crises.
CONST_FILES = [
    "scripts/food_system.gd", "scripts/food_care.gd", "scripts/early_life_conditions.gd", "scripts/game_state.gd",
    "scripts/government_people_system.gd", "scripts/work_paths.gd", "scripts/society_model.gd", "scripts/consequence_engine.gd",
    "scripts/research_600_catalog.gd", "scripts/discovery_system.gd", "scripts/technology_eras.gd",
    "scripts/civilian_goods.gd", "scripts/resource_system.gd", "scripts/weapons_stock.gd", "scripts/watch_military.gd", "scripts/standing.gd",
    "scripts/built_fabric.gd", "scripts/settlement_construction.gd", "scripts/crisis_system.gd", "scripts/crisis_unattended.gd",
    "scripts/dry_water.gd", "scripts/day_span.gd", "scripts/economy_system.gd", "scripts/civilization_strategy.gd",
]
CONST_LINE = re.compile(r"^const\s+([A-Z][A-Z0-9_]*)\s*(?::\s*(?:float|int)\s*)?:?=\s*(-?\d+(?:\.\d*)?|-?\.\d+)\s*(?:#.*)?$")


def godot() -> str:
    return os.environ.get("GODOT", DEFAULT_GODOT)


def available() -> str:
    """'' when the real game can run here, else why not."""
    if not Path(godot()).exists():
        return f"Godot was not found at {godot()} (set the GODOT environment variable)."
    if not (ROOT / "project.godot").exists():
        return "This checkout has no project.godot."
    if not (ROOT / ".godot" / "global_script_class_cache.cfg").exists():
        return "This checkout has never been opened by Godot (no .godot class cache)."
    return ""


# ---------------------------------------------------------------- the numbers
def const_catalog() -> list[dict]:
    """Every plain number the game's rule files declare as a const, with the
    game's own comment above it."""
    out = []
    for rel in CONST_FILES:
        path = ROOT / rel
        if not path.exists():
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        seen = set()
        for i, line in enumerate(lines):
            m = CONST_LINE.match(line.rstrip())
            if not m or m.group(1) in seen:
                continue
            seen.add(m.group(1))
            note = []
            j = i - 1
            while j >= 0 and lines[j].startswith("#"):
                note.insert(0, lines[j].lstrip("# ").strip())
                j -= 1
            text = m.group(2)
            out.append({"id": f"{rel}::{m.group(1)}", "name": m.group(1), "value": float(text), "file": rel, "note": " ".join(note),
                        "whole": not ("." in text), "line": i + 1})
    return out


def _unlink_junction(path: Path) -> None:
    # os.rmdir removes a junction itself and never what it points at.
    if path.exists() or path.is_symlink():
        os.rmdir(path)


def _junction(link: Path, target: Path) -> None:
    subprocess.run(["cmd", "/c", "mklink", "/J", str(link), str(target)], capture_output=True, check=True)


def patched_project(knobs: dict) -> Path:
    """The game with these const lines rewritten: a copy of scripts/ and
    tools/sim, everything else joined to the real checkout. Kept by content."""
    if not knobs:
        return ROOT
    key = hashlib.sha1(json.dumps(sorted(knobs.items())).encode()).hexdigest()[:12]
    home = RUNS / "projects"
    proj = home / key
    if (proj / "ready").exists():
        return proj
    home.mkdir(parents=True, exist_ok=True)
    forget_project(proj)
    proj.mkdir()
    for entry in ROOT.iterdir():
        name = entry.name
        if name in (".git", ".godot", "scripts", "tools", "reports", "artifacts") or name.endswith(".log"):
            continue
        if entry.is_dir():
            _junction(proj / name, entry)
        else:
            shutil.copy2(entry, proj / name)
    shutil.copytree(ROOT / "scripts", proj / "scripts")
    (proj / "tools").mkdir()
    shutil.copytree(SIM, proj / "tools" / "sim", ignore=shutil.ignore_patterns("bench_runs", "__pycache__", "ground_truth", "cache", "*.py", "*.json", "*.html"))
    (proj / ".godot").mkdir()
    for name in ("global_script_class_cache.cfg", "uid_cache.bin"):
        if (ROOT / ".godot" / name).exists():
            shutil.copy2(ROOT / ".godot" / name, proj / ".godot" / name)
    imported = (ROOT / ".godot" / "imported").resolve()
    if imported.exists():
        _junction(proj / ".godot" / "imported", imported)
    by_file: dict[str, dict] = {}
    for kid, value in knobs.items():
        rel, name = kid.split("::")
        by_file.setdefault(rel, {})[name] = value
    for rel, changes in by_file.items():
        path = proj / rel
        raw = path.read_bytes().decode("utf-8")
        newline = "\r\n" if "\r\n" in raw else "\n"
        lines = raw.split(newline)
        left = dict(changes)
        for i, line in enumerate(lines):
            m = CONST_LINE.match(line)
            if m and m.group(1) in left:
                value = left.pop(m.group(1))
                text = str(int(round(value))) if "." not in m.group(2) and float(value).is_integer() else repr(float(value))
                lines[i] = line[:m.start(2)] + text + line[m.end(2):]
        if left:
            forget_project(proj)
            raise ValueError(f"{rel}: no such number {', '.join(left)}")
        path.write_bytes(newline.join(lines).encode("utf-8"))
    (proj / "ready").write_text(json.dumps(knobs), encoding="utf-8")
    # Keep the six most recent sets.
    kept = sorted((p for p in home.iterdir() if p.is_dir()), key=lambda p: p.stat().st_mtime)
    for old in kept[:-6]:
        forget_project(old)
    return proj


def forget_project(proj: Path) -> None:
    """Remove a patched copy: every junction is unlinked first, so nothing
    of the real checkout is ever deleted through one."""
    if not proj.exists() or RUNS not in proj.resolve().parents:
        return
    for link in [proj / ".godot" / "imported", *proj.iterdir()]:
        if link.is_dir() and (link.is_symlink() or getattr(os.path, "isjunction", lambda p: False)(link) or _is_reparse(link)):
            _unlink_junction(link)
    shutil.rmtree(proj)


def _is_reparse(path: Path) -> bool:
    try:
        return bool(os.lstat(path).st_file_attributes & 0x400)
    except (OSError, AttributeError):
        return False


# ---------------------------------------------------------------- the rows
def _r(v):
    try:
        v = float(v)
    except (TypeError, ValueError):
        return None
    if v != v or v in (float("inf"), float("-inf")):
        return None
    return 0 if v == 0.0 else float(f"{v:.5g}")


def flatten(row: dict, prev: dict | None) -> dict:
    """The dashboard's row from the probe's: one level, numbers only, the
    yearly rates added."""
    out = {}
    for k, v in row.items():
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            out[k] = _r(v)
    out["towns"] = out.get("settlements")
    for src, prefix in (("alloc", "work_"), ("cohorts", "age_"), ("capacities", "cap_"), ("per_line", "line_"), ("effects", "eff_"),
                        ("source_health", "source_"), ("mortality_components", "mort_"), ("death_causes", "cause_")):
        for k, v in (row.get(src) or {}).items():
            out[prefix + str(k)] = _r(v)
    pop = max(1.0, float(row.get("population", 1)))
    for k, v in (row.get("cohorts") or {}).items():
        out["ageshare_" + k] = _r(100.0 * float(v) / pop)
    total_harvest = 0.0
    for k, v in (row.get("harvest") or {}).items():
        total_harvest += float(v)
        out["harvest_" + HARVEST.get(str(k).lower(), str(k).lower().replace(" ", "_"))] = _r(v)
    workers = row.get("workers") or {}
    out["knowledge_workers"] = _r(workers.get("Knowledge", 0))
    if float(workers.get("Food", 0)) > 0:
        out["food_per_worker"] = _r(total_harvest / float(workers["Food"]))
    water = row.get("water") or {}
    out["water_intake"], out["water_days"] = _r(water.get("intake", 1)), _r(water.get("days", 0))
    effects = row.get("effects") or {}
    for k in ("tool_quality", "craft_output", "trade_capacity", "state_capacity", "construction_rate", "warfare_readiness"):
        out[k] = _r(effects.get(k, 0))
    out["literacy"] = _r(100.0 * max(0.0, min(1.0, float(effects.get("literacy", 0)))))
    for k, v in (row.get("bench") or {}).items():
        out[k] = _r(v)
    out["raw"] = _r(sum(float(out.get("stock_" + r) or 0) for r in RAW))
    art = row.get("artifacts") or {}
    out["art_count"], out["art_studied"] = art.get("count", 0), art.get("studied", 0)
    if prev is not None:
        dt = max(1e-9, float(row["year"]) - float(prev["year"]))
        mid = max(1.0, 0.5 * (pop + float(prev["population"])))
        out["births_rate"] = _r((float(row["births"]) - float(prev["births"])) / dt / mid * 1000.0)
        out["deaths_rate"] = _r((float(row["deaths"]) - float(prev["deaths"])) / dt / mid * 1000.0)
        out["growth"] = _r(((pop / max(1.0, float(prev["population"]))) ** (1.0 / dt) - 1.0) * 100.0)
        out["learned_year"] = _r((float(row["known"]) - float(prev["known"])) / dt)
        out["steps_year"] = _r((float(row.get("steps", 0)) - float(prev.get("steps", 0))) / dt)
    else:
        for k in list(out):
            if k.startswith(("st_", "cap_", "eff_")) or k in ("labor_efficiency", "infant_mortality", "life_expectancy", "field_strength", "drill", "armed"):
                out[k] = None
    return out


# ---------------------------------------------------------------- one world
class World:
    """One headless engine and the thread reading what it writes. Shaped like
    a process for bench.py's scheduler (is_alive, terminate, exitcode)."""

    def __init__(self, job_id: str, spec: dict, seed: int, queue):
        self.job_id, self.spec, self.seed, self.queue = job_id, spec, seed, queue
        self.proc: subprocess.Popen | None = None
        self.exitcode = None
        self.stopped = False
        self.thread = threading.Thread(target=self._run, daemon=True)

    def start(self) -> None:
        self.thread.start()

    def is_alive(self) -> bool:
        return self.thread.is_alive()

    def terminate(self) -> None:
        self.stopped = True
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()

    def _args(self, work: Path) -> list[str]:
        spec = self.spec
        args = [f"--scenario={SITE_SCENARIO.get(spec.get('site', 'good'), 'sensible')}", f"--seed={self.seed}", f"--years={int(spec['years'])}",
                f"--span={max(1, int(spec.get('span', 30)))}", f"--spec={(work / 'spec.json').as_posix()}",
                f"--stream={(work / 'rows.jsonl').as_posix()}", f"--out={(work / 'out.json').as_posix()}"]
        if spec.get("mode") == "split":
            args.append("--split=" + ",".join(f"{k}:{float(v):g}" for k, v in spec.get("manual", {}).items() if float(v) > 0))
        elif spec.get("path") and spec["path"] != "balanced":
            args.append(f"--path={spec['path']}")
        return args

    def _run(self) -> None:
        started = time.time()
        work = RUNS / "work" / f"{self.job_id}-{self.seed}"
        try:
            project = patched_project(self.spec.get("consts") or {})
            shutil.rmtree(work, ignore_errors=True)
            work.mkdir(parents=True)
            spec = self.spec
            probe_spec = {"research": spec.get("research") or {}, "start_population": int(spec.get("start_population", 120)),
                          "site_profile": spec.get("site_profile") or {}, "ambition": spec.get("ambition") or "makers",
                          "phases": [{k: v for k, v in ph.items() if k in ("from", "path", "manual")} for ph in spec.get("phases") or []]}
            (work / "spec.json").write_text(json.dumps(probe_spec), encoding="utf-8")
            flags = 0x00004000 if sys.platform == "win32" else 0   # BELOW_NORMAL_PRIORITY_CLASS: the player's game comes first
            with open(work / "engine.log", "w", encoding="utf-8", errors="replace") as log:
                self.proc = subprocess.Popen([godot(), "--headless", "--path", str(project), "res://tools/sim/bench_probe.tscn", "--", *self._args(work)],
                                             stdout=log, stderr=subprocess.STDOUT, creationflags=flags)
                self._tail(work / "rows.jsonl")
            self.exitcode = self.proc.returncode
            if self.stopped:
                return
            out = work / "out.json"
            if self.exitcode != 0 or not out.exists():
                tail = (work / "engine.log").read_text(encoding="utf-8", errors="replace")[-1500:]
                self.queue.put(("error", self.seed, f"the game's rules stopped (exit code {self.exitcode})\n{tail}"))
                return
            self.queue.put(("done", self.seed, self._extra(json.loads(out.read_text(encoding="utf-8")), started)))
        except Exception as e:
            self.queue.put(("error", self.seed, f"{type(e).__name__}: {e}"))
        finally:
            if not self.stopped and self.exitcode == 0:
                shutil.rmtree(work, ignore_errors=True)

    def _tail(self, path: Path) -> None:
        prev = None
        pos = 0
        # The probe writes year 0 only to its final file: the founding row is the truth row at day 0.
        while True:
            done = self.proc.poll() is not None
            if path.exists():
                with open(path, encoding="utf-8") as f:
                    f.seek(pos)
                    chunk = f.read()
                keep = chunk.rfind("\n") + 1
                pos += len(chunk[:keep].encode("utf-8"))
                for line in chunk[:keep].splitlines():
                    if not line.strip():
                        continue
                    row = json.loads(line)
                    self.queue.put(("row", self.seed, flatten(row, prev)))
                    prev = row
            if done:
                return
            time.sleep(0.25)

    def _extra(self, out: dict, started: float) -> dict:
        import bench_worker
        import simlib
        _constants, cat = simlib.data()
        learned, reached = [], {}
        for day, rid, line in out.get("discoveries", []):
            row = cat.rows[cat.index[rid]] if rid in cat.index else {}
            learned.append([round(day / 365.0, 1), row.get("name", rid), line])
            reached[rid] = day / 365.0
        marks = {m["id"]: (round(reached[m["id"]], 1) if m["id"] in reached else None) for m in bench_worker.landmarks(cat)}
        return {"seconds": round(time.time() - started, 1), "learned": learned, "marks": marks, "crises": [], "engine_seconds": out.get("seconds")}
