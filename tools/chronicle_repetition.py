"""Repetition in a replayed Chronicle (tools/chronicle_replay.gd output).

A sentence counts as repeated when the same sentence, with numbers and
number words masked, was already told earlier in the same feed. Year entries
(kind "annal") are measured on their own and together with every other
non-whisper line.

    python tools/chronicle_repetition.py replay.json [--years A-B] [--show N]
"""
import collections
import json
import re
import sys

NUMBER_WORDS = ("no one two three four five six seven eight nine ten eleven twelve thirteen "
                "fourteen fifteen sixteen seventeen eighteen nineteen twenty").split()
ORDINALS = ("first second third fourth fifth sixth seventh eighth ninth tenth eleventh "
            "twelfth thirteenth fourteenth fifteenth sixteenth seventeenth eighteenth "
            "nineteenth twentieth").split()
MASK = re.compile(r"\b(\d[\d,]*|%s)\b" % "|".join(NUMBER_WORDS + ORDINALS))
SPLIT = re.compile(r"[^.!?;]+[.!?;]+['\")]*|[^.!?;]+$")


def norm(sentence):
    s = sentence.lower().strip().rstrip(".;")
    return MASK.sub("#", s).strip()


def sentences(text):
    return [s.strip() for s in SPLIT.findall(text) if len(s.strip()) > 3]


def measure(entries):
    seen = collections.Counter()
    total = repeated = 0
    for e in entries:
        for s in sentences(e.get("text", "")):
            n = norm(s)
            total += 1
            if seen[n]:
                repeated += 1
            seen[n] += 1
    return total, repeated, seen


def main():
    path = sys.argv[1]
    show = 0
    years = None
    args = sys.argv[2:]
    for i, a in enumerate(args):
        if a == "--show":
            show = int(args[i + 1])
        if a == "--years":
            lo, hi = args[i + 1].split("-")
            years = (int(lo), int(hi))
    data = json.load(open(path, encoding="utf-8"))
    entries = sorted(data["entries"], key=lambda e: (int(e.get("day", 0))))
    told = [e for e in entries if e.get("tier") != "whisper"]
    annals = [e for e in told if e.get("kind") in ("annal", "age")]
    t, r, seen = measure(told)
    print("all told lines: %d entries, %d sentences, %d repeated (%.0f%%)" % (len(told), t, r, 100.0 * r / max(1, t)))
    t2, r2, seen2 = measure(annals)
    print("year entries:   %d entries, %d sentences, %d repeated (%.0f%%)" % (len(annals), t2, r2, 100.0 * r2 / max(1, t2)))
    words = sum(len(e.get("text", "").split()) for e in annals)
    print("year entry words: %d (%.0f per entry)" % (words, words / max(1, len(annals))))
    print("most repeated year-entry sentences:")
    for s, n in seen2.most_common(12):
        if n > 1:
            print("  x%d  %s" % (n, s))
    if show:
        print()
        for e in annals:
            y = int(e.get("day", 0)) // 365 + 1
            if years and not (years[0] <= y <= years[1]):
                continue
            print("Year %d [%s] %s\n  %s\n" % (y, e.get("kind"), e.get("title"), e.get("text")))


if __name__ == "__main__":
    main()
