extends Node
## Plain-speech gate. Scans every offline dialogue table and template source
## for invented maxims, aphorisms and kennings (scripts/plain_speech.gd) and
## checks the detector itself against known good and bad lines. Also checks
## the forms of address a god is given, and that no line table still uses the
## {proverb} token. Exits 1 on any failure.
##   <godot> --headless --path <worktree> res://tests/plain_speech_probe.tscn [-- --list]

const Plain:=preload("res://scripts/plain_speech.gd")
const CV:=preload("res://scripts/character_voice.gd")

## Every source of spoken lines: offline banks, templates, voice models,
## envoy/rival lines, court replies, advisors, directives, notables.
const SOURCES:=[
	"res://scripts/audience_voice.gd","res://scripts/character_voice.gd","res://scripts/divine_voice.gd",
	"res://scripts/court_lives.gd","res://scripts/court_lives_lines.gd","res://scripts/court_persons.gd","res://scripts/court_persons_lines.gd",
	"res://scripts/legacy_aims.gd","res://scripts/legacy_aims_lines.gd","res://scripts/fire_circle_voice.gd",
	"res://scripts/chief_scout.gd","res://scripts/opening_arc.gd","res://scripts/rival_rulers.gd","res://scripts/joint_rivals.gd",
	"res://scripts/court_commands.gd","res://scripts/advisor_system.gd","res://scripts/custom_directive.gd",
	"res://scripts/village_notables.gd","res://scripts/great_works_audience.gd","res://scripts/great_works_rivalry.gd",
	"res://scripts/interaction_types.gd","res://scripts/audience_hall.gd",
]
## Lines of source that hold instructions, patterns or UI, not speech.
const SKIP_LINE:="(?i)(RegEx|compile\\(|push_error|push_warning|print\\(|\"style\":|\"guide\"|\"guide_early\"|\"era\":|\"label\"|\"label_early\"|tooltip|PROMPT|_RULES|const [A-Z_]*PATTERN|FAMOUS_LINES|const [A-Z_]*WORDS:=\"|\"words\":)"

const BAD:=[
	"Feast-Giver, a free bundle is best counted twice: it asks no carrying, no return, and feeds many hearths!",
	"Gift-food fills bellies, but a fox leaves tracks.",
	"A gift-bearer made trail-leader is a costly knot.",
	"A full store is a quiet camp.",
	"My roast goose, yielding plants today plants a hungry hand tomorrow; our stores can spare, yet our standing cannot!",
	"Their word-hoard will call it theft, god; twenty meals buy a long border-song.",
	"Cheap rope, short trip.",
	"The wind does not argue. It blows.",
	"Honey on the lip, nettle in the sleeve.",
	"A hungry neighbour is a worse fence than a fed one.",
	"Every edge is honest once it's struck.",
]
const GOOD:=[
	"Great One, it's forty hides and they want nothing back. I'd take it.",
	"The meat is welcome, but Elarin will expect our hunters at their fire next spring.",
	"Elarin will call this theft. Twenty meals isn't worth a feud on the border.",
	"We have eleven days of food in the pits, and the hunters came back empty twice.",
	"{leader} sends you {amt} {res}, {address}, and asks nothing for it.",
	"Their escort is half-starved. They could not march three days on that.",
	"A gift from {civ}: {amt} {res}.",
	"Send Oyun with the scouts; she has walked that valley before.",
]
## God-address terms that are comic, food puns or over-familiar.
const ABSURD_ADDRESS:="(?i)(roast|goose|gravy|butter|big fish|big-hearted|friend-chief|my gull|ma chief|feast-giver|my bright one|hearth-holder|forge-master|ring-giver|dearie|pet\\b)"

## Descriptions and UI phrases the scan cannot tell from a saying.
const NOT_SPEECH:=["a narrower, reversible measure that does not compel bodily harm"]

var failures:PackedStringArray=PackedStringArray()

func _ready()->void:
	for line in BAD:
		if not Plain.is_maxim(String(line)): failures.append("detector missed a maxim: "+String(line))
	for line in GOOD:
		if Plain.is_maxim(String(line)): failures.append("detector flagged plain speech: %s (%s)" % [String(line),JSON.stringify(Plain.flags(String(line)))])
	# Stripping keeps the plain part of a mixed line.
	var mixed:=Plain.strip("Great One, twenty meals is what they ask. A full store is a quiet camp.")
	if "quiet camp" in mixed or not "twenty meals" in mixed: failures.append("strip did not keep only the plain sentence: "+mixed)
	var listing:="--list" in OS.get_cmdline_user_args()
	var scanned:=0
	var flagged:=0
	var per_file:={}
	for path in SOURCES:
		if not FileAccess.file_exists(path): continue
		var lines:=FileAccess.get_file_as_string(path).split("\n")
		var skip:=RegEx.new(); skip.compile(SKIP_LINE)
		var in_triple:=false
		var caps:=RegEx.new(); caps.compile("\\b[A-Z]{4,}\\b|'envoy'|^Cost:")
		for n in lines.size():
			var src:=String(lines[n])
			if src.count("\"\"\"")%2==1: in_triple=not in_triple; continue
			if in_triple or src.strip_edges().begins_with("#") or src.strip_edges().begins_with("##"): continue
			if skip.search(src)!=null: continue
			if "{proverb}" in src: failures.append("%s:%d still uses the {proverb} token" % [path.get_file(),n+1])
			for literal in _literals(src):
				if literal.split(" ",false).size()<4: continue
				# Model instructions and fact sheets (CAPITALS, long prose) are not speech.
				if literal.length()>320 or caps.search(literal)!=null or literal in NOT_SPEECH: continue
				scanned+=1
				var f:=Plain.flags(literal)
				if f.is_empty(): continue
				flagged+=1
				per_file[path.get_file()]=int(per_file.get(path.get_file(),0))+1
				var row:="%s:%d [%s] %s" % [path.get_file(),n+1,String((f[0] as Dictionary).reason),literal]
				failures.append("maxim in offline line: "+row)
				if listing: print(row)
	# The offline interaction archetypes (civic replies) are lines too.
	var types:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/interactions/types.json"))
	var json_lines:Array=[]
	_json_strings(types,json_lines)
	for literal in json_lines:
		if String(literal).split(" ",false).size()<4 or String(literal).length()>320: continue
		scanned+=1
		var jf:=Plain.flags(String(literal))
		if jf.is_empty(): continue
		flagged+=1
		per_file["types.json"]=int(per_file.get("types.json",0))+1
		failures.append("maxim in offline line: types.json [%s] %s" % [String((jf[0] as Dictionary).reason),String(literal)])
		if listing: print("types.json [%s] %s" % [String((jf[0] as Dictionary).reason),String(literal)])
	# Every dialect's god-address is reverent: no food puns, nothing comic.
	var absurd:=RegEx.new(); absurd.compile(ABSURD_ADDRESS)
	for d:Dictionary in CV.DIALECTS:
		for a in d.get("address",[]):
			if absurd.search(String(a))!=null: failures.append("absurd address in %s: %s" % [String(d.id),String(a)])
		if not (d.get("proverb",[]) as Array).is_empty(): failures.append("dialect %s still carries proverbs" % String(d.id))
		for key in (d.get("subs",{}) as Dictionary):
			var v:Variant=(d.subs as Dictionary)[key]
			for word in (v if v is Array else [v]):
				if absurd.search(String(word))!=null or RegEx.create_from_string(Plain.KENNING).search(String(word))!=null: failures.append("comic or kenning word swap in %s: %s -> %s" % [String(d.id),String(key),String(word)])
	print("PLAIN_SPEECH scanned %d offline lines, %d flagged %s" % [scanned,flagged,JSON.stringify(per_file)])
	if failures.is_empty():
		print("PLAIN_SPEECH PASS")
		get_tree().quit(0)
		return
	for f in failures.slice(0,80): print("FAIL ",f)
	print("PLAIN_SPEECH FAIL (%d)" % failures.size())
	get_tree().quit(1)

## Spoken fields of types.json (effects, side and cues are outcome labels).
const JSON_SPEECH:=["core","ask","open","comply","caution","answer"]

static func _json_strings(v:Variant,out:Array,spoken:bool=false)->void:
	if v is String:
		if spoken: out.append(v)
	elif v is Array:
		for x in v: _json_strings(x,out,spoken)
	elif v is Dictionary:
		for k in v: _json_strings((v as Dictionary)[k],out,spoken or String(k) in JSON_SPEECH)

## Double-quoted string literals on one source line (escapes honoured).
static func _literals(src:String)->PackedStringArray:
	var out:PackedStringArray=PackedStringArray()
	var i:=0
	while i<src.length():
		if src[i]=="\"":
			var j:=i+1
			var buf:=""
			while j<src.length() and src[j]!="\"":
				if src[j]=="\\" and j+1<src.length(): buf+=src[j+1]; j+=2; continue
				buf+=src[j]; j+=1
			out.append(buf)
			i=j+1
			continue
		i+=1
	return out
