"""Developer-voice scan over a fun_playtest JSONL log (or several).

Fails (exit 1) when any line the player is told -- a Chronicle entry, a ledger
event, a court or envoy line, the ticker -- carries clerk or programmer
phrasing: "not global tracking", "a expedition", "polity",
"value-conserved exchange" and the like. The unit test
tests/test_one_chronicle.gd scans the scripts' string literals for the same.

  python dev_text_scan.py log.jsonl [more.jsonl ...]
"""
import json, re, sys

PATTERNS = [
    r"global tracking", r"omniscient tracking", r"local observations?\b(?! range)", r"value-conserved",
    r"\bpolit(y|ies)\b", r"unidentified aggregate", r"aggregate (foreign )?formation",
    r"simulated decisions", r"\ba (?=[aeiou]\w)(?!one\b|use|uni|eu)",
]
FIELDS = {"feed": ["title", "text"], "event": ["title", "desc"], "chronicle": ["text"], "ticker": ["text"],
          "audience": ["title", "facts", "lines", "options"], "audience_result": ["outcome"], "beat": ["title", "text"],
          "matter": ["summary"], "council": ["title", "body"], "aim": ["text"], "aim_decision": ["lines", "outcome"]}


def texts(row):
    for field in FIELDS.get(row.get("t", ""), []):
        value = row.get(field)
        if isinstance(value, list):
            for item in value:
                yield str(item)
        elif value:
            yield str(value)


def scan(paths):
    hits = []
    for path in paths:
        for line in open(path, encoding="utf-8"):
            try:
                row = json.loads(line)
            except ValueError:
                continue
            for text in texts(row):
                for pattern in PATTERNS:
                    m = re.search(pattern, text, re.I)
                    if m:
                        hits.append((path, row.get("day", 0), row.get("t"), m.group(0), text[:140]))
    return hits


if __name__ == "__main__":
    found = scan(sys.argv[1:])
    for path, day, kind, match, text in found:
        print("%s day %s %s [%s] %s" % (path.split("/")[-1], day, kind, match, text))
    print("DEV TEXT HITS: %d" % len(found))
    sys.exit(1 if found else 0)
