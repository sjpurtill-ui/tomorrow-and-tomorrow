"""Summarise a tools/model_ab_probe.gd run (JSON) into per-model metrics.

    python tools/model_ab_report.py <run.json> [--transcripts]

Style heuristics (documented in docs/MODEL_AB_TEST.md):
- maxim_game: the game's own filler detector (AudienceVoice.without_filler)
  flagged the line (whole line, or a leading stock saying).
- maxim_regex: a sentence anywhere in the line reads as a gnomic saying: a
  generic subject ("a/an/every/no/the <noun> that/who/he who/those who/
  whoever") in the present tense, with no I/you/we, no digits and no names.
- aside: the model marked the line as an aside, or an official spoke beyond
  the principal answer (counted per exchange as extra official speakers).
- interjection: a leading vocative/exclamation ("Ah,", "Oh,", "Hah!", "Well,").
"""
import json, re, sys, statistics
from collections import defaultdict

GNOMIC = re.compile(r"^(?:a|an|every|no|each|the \w+ (?:that|who|which)|he who|she who|they who|those who|whoever|one who|a man who|a woman who|what \w+|when the|where the|never|always)\b", re.I)
PERSONAL = re.compile(r"\b(i|i'm|i'll|i've|i'd|me|my|mine|we|us|our|ours|you|your|yours|let)\b", re.I)
PRESENT = re.compile(r"\b(is|are|has|have|does|do|makes|keeps|feeds|burns|sinks|cuts|breaks|knows|needs|wants|never|always|finds|brings|eats|learns|forgets|remembers|loves|fears|grows|dies|lives|speaks|stands|falls|waits|pays|counts|carries)\b", re.I)
INTERJ = re.compile(r"^(ah|oh|hah|ha|hm+|well|alas|o|lo|behold|aye|hark|ahem|pah|bah)\b[,!.]?", re.I)


def sentences(text):
    return [s.strip() for s in re.split(r"(?<=[.!?;])\s+", text) if s.strip()]


def maxim_regex(text):
    for s in sentences(text):
        if GNOMIC.search(s) and PRESENT.search(s) and not PERSONAL.search(s) and not re.search(r"\d", s):
            return True
    return False


def pct(values, p):
    if not values:
        return 0
    v = sorted(values)
    k = max(0, min(len(v) - 1, int(round(p / 100.0 * len(v) + 0.5)) - 1))
    return v[k]


def main():
    path = sys.argv[1]
    data = json.load(open(path, encoding="utf-8"))
    rows = [e for e in data["exchanges"] if e.get("sent")]
    by = defaultdict(list)
    for e in rows:
        by[e["model"]].append(e)
    out = {}
    for model, es in by.items():
        lat = [e.get("latency_ms", 0) for e in es if e.get("http") == 200]
        costs = [e.get("cost_usd", 0.0) for e in es]
        lines = [l for e in es for l in e.get("line_checks", []) if l.get("key") != "narrator"]
        words = [len(l["text"].split()) for l in lines]
        m = {
            "calls": len(es),
            "http_ok": sum(1 for e in es if e.get("http") == 200),
            "cost_total": sum(costs),
            "cost_mean": statistics.mean(costs) if costs else 0,
            "prompt_tokens_mean": statistics.mean([e.get("prompt_tokens", 0) for e in es]) if es else 0,
            "completion_tokens_mean": statistics.mean([e.get("completion_tokens", 0) for e in es]) if es else 0,
            "reasoning_tokens_mean": statistics.mean([e.get("reasoning_tokens", 0) for e in es]) if es else 0,
            "latency_mean_ms": statistics.mean(lat) if lat else 0,
            "latency_p90_ms": pct(lat, 90),
            "over_game_timeout": sum(1 for e in es if e.get("over_game_timeout")),
            "json_ok": sum(1 for e in es if e.get("json_ok")),
            "schema_ok": sum(1 for e in es if e.get("schema_ok")),
            "finish_length": sum(1 for e in es if e.get("finish_reason") == "length"),
            "accepted": sum(1 for e in es if e.get("accepted")),
            "rejected_calls": [(e["scenario"], e["stage"], e.get("reject_reason", "")) for e in es if not e.get("accepted")],
            "persons_spoke_live": sum(1 for e in es if e.get("persons", {}).get("spoke_live")),
            "persons_calls": sum(1 for e in es if e.get("persons")),
            "lines_proposed": len(lines),
            "lines_delivered_est": sum(1 for e in es for l in e.get("line_checks", []) if l.get("key") != "narrator" and any(l["text"].strip()[:40] in d["text"] for d in e.get("delivered", []))),
            "maxim_game": sum(1 for l in lines if l.get("maxim_game")),
            "maxim_regex": sum(1 for l in lines if maxim_regex(l["text"])),
            "maxim_lines": [l["text"] for l in lines if l.get("maxim_game") or maxim_regex(l["text"])],
            "asides": sum(1 for l in lines if l.get("aside")),
            "interjections": sum(1 for l in lines if INTERJ.search(l["text"].strip())),
            "anachronism": sum(1 for l in lines if l.get("era_ok") is False),
            "anachronism_lines": [l["text"] for l in lines if l.get("era_ok") is False],
            "imitation_fail": sum(1 for l in lines if l.get("imitation_ok") is False),
            "meta": sum(1 for l in lines if l.get("meta")),
            "refuses_decided_order": sum(1 for l in lines if l.get("refuses_decided_order")),
            "invented_number": sum(1 for l in lines if l.get("invented_number")),
            "unknown_speaker": sum(1 for l in lines if l.get("unknown_speaker")),
            "words_per_line_mean": statistics.mean(words) if words else 0,
            "words_per_line_p90": pct(words, 90),
        }
        out[model] = m
    blocked = [e for e in data["exchanges"] if e.get("blocked")]
    print(json.dumps({"total_usd": data["total_usd"], "stopped": data["stopped"], "stop_reason": data["stop_reason"], "blocked": len(blocked), "models": out}, indent=2))
    if "--transcripts" in sys.argv:
        for sc in data["scenarios"]:
            print("\n=== %s / %s  (%s)" % (sc["scenario"], sc["model"], sc["note"][:300]))
            for aid, lines in sc["transcripts"].items():
                print("-- audience", aid)
                for l in lines:
                    print("  [%s%s] %s: %s" % (l["role"], " aside" if l["aside"] else "", l["speaker"], l["text"]))


if __name__ == "__main__":
    main()
