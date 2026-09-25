"""Read constants straight out of the game's GDScript so the surrogate never
keeps a hand copy that can drift.

Two tools:
* ``const(path, NAME)`` parses a top-level ``const NAME := <literal>`` whose value
  is a number, string, bool, array or dictionary literal (Vector2(a, b) becomes
  [a, b]; typed-array prefixes and trailing commas are handled).
* ``line_numbers(path, anchor)`` returns every numeric literal on the first
  source line containing ``anchor``: used for rates embedded in formulas
  (e.g. the conception line in GameState.process_reproduction_day). Callers
  check the count and fall back to params.json when a line has changed shape,
  so an edited formula surfaces as a warning instead of silently wrong numbers.
"""
from __future__ import annotations

import json
import re
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
WARNINGS: list[str] = []


def game_rev() -> str:
    """SIM_GAME_REV=<git rev> reads every game file from that commit instead of
    the working tree (calibrate/check use it to match a truth run's sources)."""
    import os
    return os.environ.get("SIM_GAME_REV", "")


@lru_cache(maxsize=None)
def read_game_file(path: str) -> str:
    rev = game_rev()
    if rev:
        import subprocess
        out = subprocess.run(["git", "-C", str(ROOT), "show", f"{rev}:{path}"], capture_output=True)
        if out.returncode == 0:
            return out.stdout.decode("utf-8")
    return (ROOT / path).read_text(encoding="utf-8")


@lru_cache(maxsize=None)
def game_file_exists(path: str) -> bool:
    """Whether ``path`` exists in the game revision being read (or the tree)."""
    rev = game_rev()
    if rev:
        import subprocess
        return subprocess.run(["git", "-C", str(ROOT), "cat-file", "-e", f"{rev}:{path}"], capture_output=True).returncode == 0
    return (ROOT / path).exists()


def source(path: str) -> str:
    return read_game_file(path)


def _extract_value(text: str, start: int) -> str:
    """Return the literal starting at ``start`` (balanced brackets, one line otherwise)."""
    i = start
    while text[i] in " \t":
        i += 1
    if text[i] in "[{(" or text.startswith("Vector2", i):
        depth = 0
        j = i
        in_str = False
        while j < len(text):
            c = text[j]
            if in_str:
                if c == "\\":
                    j += 2
                    continue
                if c == '"':
                    in_str = False
            elif c == '"':
                in_str = True
            elif c == "#":
                while j < len(text) and text[j] != "\n":
                    j += 1
                continue
            elif c in "[{(":
                depth += 1
            elif c in "]})":
                depth -= 1
                if depth == 0:
                    return text[i:j + 1]
            j += 1
        raise ValueError("unbalanced literal")
    end = text.find("\n", i)
    value = text[i:end if end >= 0 else None]
    return value.split("#")[0].strip()


def _to_json(literal: str) -> str:
    out = []
    i = 0
    in_str = False
    while i < len(literal):
        c = literal[i]
        if in_str:
            out.append(c)
            if c == "\\":
                out.append(literal[i + 1])
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == "#":
            while i < len(literal) and literal[i] != "\n":
                i += 1
            continue
        out.append(c)
        i += 1
    s = "".join(out)
    s = re.sub(r"Vector2i?\(\s*([^,()]+?)\s*,\s*([^,()]+?)\s*\)", r"[\1,\2]", s)
    s = re.sub(r"(?<![\w.])(-?)\.(\d)", r"\g<1>0.\2", s)          # .45 -> 0.45
    s = re.sub(r"(\d)\.(?!\d)", r"\1.0", s)                      # 1. -> 1.0
    s = re.sub(r",\s*([\]}])", r"\1", s)                         # trailing commas
    s = re.sub(r"\bINF\b", "1e308", s)
    s = re.sub(r"\btrue\b", "true", s)
    return s


def const(path: str, name: str, default=None, optional: bool = False):
    """``optional``: a feature constant the engine may not have (yet); absent
    means the feature is off and ``default`` is its neutral value, silently."""
    text = source(path)
    match = re.search(r"^(?:static\s+)?const\s+" + re.escape(name) + r"\s*(?::\s*[\w\[\], ]+)?\s*:?=", text, re.M)
    if not match:
        if default is None:
            raise KeyError(f"{name} not found in {path}")
        if not optional:
            WARNINGS.append(f"{path}: const {name} not found; using params.json fallback")
        return default
    literal = _extract_value(text, match.end())
    # Dictionary keys that name another const (e.g. {FRESH:0.04}) resolve to its value.
    literal = re.sub(r"(?<=[{,\s])([A-Z][A-Z0-9_]*)(?=\s*:(?!=))",
                     lambda m: json.dumps(const(path, m.group(1))), literal)
    try:
        return json.loads(_to_json(literal))
    except json.JSONDecodeError:
        try:
            return float(literal)
        except ValueError:
            if default is None:
                raise
            WARNINGS.append(f"{path}: const {name} unparseable; using fallback")
            return default


_NUM = re.compile(r"(?<![\w.])-?(?:\d+\.\d*|\.\d+|\d+)(?:e-?\d+)?")


def line_numbers(path: str, anchor: str, expect: int | None = None, default: list[float] | None = None,
                 occurrence: int = 0) -> list[float]:
    """Numeric literals on the ``occurrence``-th line containing ``anchor``."""
    lines = [line for line in source(path).splitlines() if anchor in line]
    if len(lines) <= occurrence:
        if default is None:
            raise KeyError(f"anchor {anchor!r} not in {path}")
        WARNINGS.append(f"{path}: anchor {anchor!r} missing; using params.json fallback")
        return list(default)
    line = lines[occurrence].split("#")[0]
    # Dictionary-read fallbacks (``.get("key",0.0)``) are defaults, not coefficients.
    line = re.sub(r"\.get\(\s*\"[^\"]*\"\s*,\s*-?[\d.]+\s*\)", ".get()", line)
    # Drop identifiers containing digits (e.g. Vector2, log10) before matching.
    line = re.sub(r"[A-Za-z_]\w*", lambda m: " " if any(ch.isdigit() for ch in m.group(0)) else m.group(0), line)
    numbers = [float(x) for x in _NUM.findall(line)]
    if expect is not None and len(numbers) != expect:
        if default is None:
            raise ValueError(f"{path}: {anchor!r} has {len(numbers)} numbers, expected {expect}: {numbers}")
        WARNINGS.append(f"{path}: {anchor!r} changed shape ({len(numbers)} numbers, expected {expect}); using fallback")
        return list(default)
    return numbers


def line_hash(path: str, anchor: str) -> str | None:
    """Short hash of the first source line containing ``anchor`` (formula drift check)."""
    import hashlib
    for line in source(path).splitlines():
        if anchor in line:
            return hashlib.sha1(line.strip().encode("utf-8")).hexdigest()[:10]
    return None


def literal_after(path: str, anchor: str, default=None):
    """Parse the dict/array literal that begins right after ``anchor`` (e.g. a
    local ``var changes:Dictionary=({`` table inside a function)."""
    text = source(path)
    at = text.find(anchor)
    if at < 0:
        if default is None:
            raise KeyError(f"anchor {anchor!r} not in {path}")
        WARNINGS.append(f"{path}: anchor {anchor!r} missing; using fallback")
        return default
    start = at + len(anchor)
    while text[start] not in "[{":
        start += 1
    literal = _extract_value(text, start)
    try:
        return json.loads(_to_json(literal))
    except json.JSONDecodeError:
        if default is None:
            raise
        WARNINGS.append(f"{path}: literal after {anchor!r} unparseable; using fallback")
        return default
