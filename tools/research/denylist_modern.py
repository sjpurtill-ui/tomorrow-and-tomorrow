#!/usr/bin/env python3
"""Real-name denylist for the modern research windows (game 1800-3000, AD 1360-2030).

Extends the 1800-2400 denylist (tools/research/validate_registry_2400.py,
which extends 1200-1800, 600-1200 and 0-600) with modern countries, peoples,
cities, rivers, persons, eponyms, firms, brands, agencies, treaties and
events. It is stricter than the 1800-2400 list in two places: "galvan" is a
prefix again (galvanometer is an eponym) and "caesarean" is not allowed. Matching is on whole words after lower-casing and splitting on
anything that is not a letter, so snake_case ids and names are checked the
same way:

  - a plain entry ("paris") matches only that exact word;
  - a starred entry ("napoleon*") matches words that begin with the stem;
  - a stem listed in EXACT_ONLY is matched as an exact word only, which keeps
    ordinary vocabulary that happens to begin with a denylisted prefix
    (germanium, industry, marshalling, franking, voltage, polish ...) out of
    the hits;
  - PHRASES are regular expressions over the whole lower-cased text.

ALLOWED_TERMS lists words that would hit a stem but are accepted as standard
technical vocabulary (chemical elements, minerals, SI units), each with the
reason. They are reported, not failed.

  python tools/research/denylist_modern.py "some name to test"
"""
import importlib.util
import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("validate_registry_2400", os.path.join(_HERE, "validate_registry_2400.py"))
_v2400 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_v2400)

MODERN = """
america american* americas usa britain british england scotland scots wales france germany germanic prussia*
austria* hungar* russia* soviet* ussr poland italy spain portug* dutch holland netherland* belgi* swiss
switzerland swede* sweden norw* finland finnish denmark iceland balkan* serbia* croat* bosnia* ukrain* iran*
iraq* syria* palestin* saudi* kuwait* afghan* pakistan* bangladesh* ceylon burma* burmese siam* thailand
malay* indonesia* philippin* manchu* mexic* cuba* haiti* jamaica* brazil* argentin* chile chilean peru* bolivia*
colombia* venezuela* canad* alaska* hawaii* australia* zealand* maori zulu* boer boers congo* ethiopia*
abyssinia* kenya* nigeria* sudan* algeria* morocc* tunisia* liberia* rwanda* somali* europe* asia asian asiatic
africa* antarctic* siberia* yankee* dixie cherokee* sioux apache* navajo* inuit eskimo* aborigin*
washington berlin* moscow* petersburg* leningrad vienna* viennese geneva* hague versailles waterloo verdun somme
gallipoli stalingrad normandy dunkirk hiroshima nagasaki chernobyl fukushima bhopal minamata montreal rio
bretton marshall manhattan alamos chicago detroit pittsburgh manchester birmingham liverpool glasgow edinburgh
lyon lyons milan milanese naples munich hamburg* frankfurt* bombay mumbai calcutta kolkata delhi shanghai*
singapore sydney suez panama* kiel erie thames seine volga mississippi amazon* yellowstone galapagos krakatoa
tambora bikini hollywood bollywood broadway harvard yale eton sandhurst annapolis portland bordeaux champagne
cognac burgundy sherry chianti roquefort cheddar parmesan camembert gouda wiener frankfurter hamburger
napoleon* bonapart* bismarck* lincoln* jefferson* marx* engels lenin* stalin* trotsk* mao maoist hitler* nazi*
fascis* mussolini churchill roosevelt kennedy gandhi* darwin* pasteur* lister* listerine koch jenner curie
einstein* newtonian faraday maxwell* edison* marconi* morse braille fordism fordist taylorism taylorist keynes*
beveridge bessemer siemens krupp nobel diesel* jacquard arkwright stephenson brunel eiffel dunant freud*
pavlov* turing babbage lovelace neumann mendel mendelian mendeleev rutherford bohr heisenberg schrodinger planck
fermi oppenheimer malthus* ricardo* smith galvan* volta voltaic vulcan* doppler roentgen rontgen geiger bunsen
petri celsius fahrenheit kelvin joule hertz becquerel sievert gauss tesla farad ampere ohm watt volt pascal
victoria* victorian* edwardian elizabethan tsar* czar* kaiser* mikado shah pasha maharaj* raj
google microsoft ibm facebook twitter youtube tiktok netflix uber airbnb spacex nasa boeing airbus ford toyota
sony walkman xerox kodak polaroid thermos velcro nylon teflon kevlar bakelite aspirin heroin prozac viagra
hoover frigidaire pepsi mcdonald* walmart ikea intel nvidia openai chatgpt gpt bitcoin linux unix
wikipedia wiki bluetooth wifi gps sputnik vostok hubble arpanet fortran cobol zeppelin* dreadnought* maxim
gatling mauser enfield minie colt winchester kalashnikov jeep spitfire blitzkrieg blitz luftwaffe panzer uboat
kamikaze gestapo kgb cia fbi nato unesco unicef imf opec interpol ymca fifa oscar grammy cannes disney* mickey
sherlock dracula frankenstein covid* sars ebola zika hiv brexit jihadi* taliban qaeda bolshevik* menshevik*
jacobin* girondin* chartist* luddite* fenian* sepoy* boxer
"""
DENYLIST = _v2400.DENYLIST + MODERN.split()

# Stems whose base is matched only as a whole word, so that ordinary words
# beginning with them are not hits. Each entry names the ordinary word it
# protects; every other stem stays a prefix match (so galvanometer,
# vulcanised, caesarean, pasteurised and diesel-engined are all hits).
EXACT_ONLY = (set(_v2400.EXACT_ONLY) - {"galvan"}) | {
    "german",      # germanium (semiconductor element), germane, germinate
    "frank",       # franking (postage), frankly
    "galen",       # galena (lead ore)
    "rhod",        # rhodium, rhodopsin
    "delph",       # delphinium
    "japan",       # japanning (black lacquer varnish), a trade term
    "celt",        # celt (polished stone axe), a tool word
    "vandal",      # vandalism, ordinary English
}

PHRASES = list(_v2400.PHRASES) + [
    r"new york", r"new deal", r"wall street", r"silicon valley", r"dust bowl", r"ellis island", r"west point",
    r"pearl harbou?r", r"three mile island", r"iron curtain", r"berlin wall", r"cold war", r"great depression",
    r"great war", r"(first|second) world war", r"world wars? (i|ii|one|two|1|2)(?![a-z])", r"coca[- ]cola",
    r"red cross", r"red crescent", r"salvation army", r"marshall plan",
    r"united nations", r"league of nations", r"european union", r"world health organi[sz]ation", r"spanish flu",
    r"bird flu", r"rock and roll", r"hip hop", r"christmas", r"easter", r"thanksgiving", r"halloween",
    r"bone china", r"plaster of paris", r"prussian blue", r"paris green", r"venetian blind", r"turkey red",
    r"indian ink", r"morocco leather", r"peruvian bark", r"jesuit'?s? bark", r"chile saltpet(re|er)",
    r"java man", r"panama canal", r"suez canal", r"kiel canal", r"geneva convention", r"hague convention",
    r"big bang", r"moore'?s law", r"murphy'?s law", r"petri dish",
]

# Standard technical words that contain a denylisted stem. Accepted, with the
# reason recorded; the validator reports them instead of failing.
ALLOWED_TERMS = {
    "voltage": "SI-derived technical noun; the unit word volt is still denylisted",
    "kaolin": "standard mineral name (kept since the 1200-1800 pass)",
    "bauxite": "standard ore name",
}


def words(text):
    return re.findall(r"[a-z]+", text.lower().replace("_", " "))


def hits(text):
    found = []
    for w in words(text):
        if w in ALLOWED_TERMS:
            continue
        for stem in DENYLIST:
            if stem.endswith("*"):
                base = stem[:-1]
                if base in EXACT_ONLY:
                    if w == base:
                        found.append(w)
                elif w.startswith(base):
                    found.append(w)
            elif w == stem:
                found.append(w)
    low = text.lower().replace("_", " ")
    for phrase in PHRASES:
        for m in re.finditer(phrase, low):
            found.append(m.group(0))
    return sorted(set(found))


def self_test():
    for p in PHRASES:
        if any(ord(ch) < 32 for ch in p):
            raise SystemExit("denylist phrase %r contains a control character" % p)
    for ok in ("germanium transistors", "industrial research", "hump marshalling yards", "franking machines",
               "galena smelting", "voltage transformers", "fire by platoons", "turkeys fattened", "after a world war",
               "coca leaf", "japanning", "vandalism"):
        assert not hits(ok), "false positive on %r: %s" % (ok, hits(ok))
    for bad in ("needle galvanometers", "diesel_motor_ships", "gentle_heat_pasteurising", "sutured_caesarean",
                "rubber_vulcanization", "the second world war", "world war ii", "portland cement", "napoleonic code",
                "christian", "trojans", "silicon valley", "geneva convention"):
        assert hits(bad), "missed real name in %r" % bad


def allowed_terms_used(text):
    return sorted(set(w for w in words(text) if w in ALLOWED_TERMS))


if __name__ == "__main__":
    self_test()
    for arg in sys.argv[1:]:
        print(arg, "->", hits(arg))
