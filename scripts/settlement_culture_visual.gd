extends RefCounted
## A small recorded finish, not another culture or production system. The
## model stamps this from its owner's lived values and known crafts when a
## building is made. Renderers never update old finishes from today's values.
## All data is JSON-safe; the four codes fit existing MultiMesh custom data.
const VERSION:=1
const ROOF_COLORS:=[Color("b99556"),Color("a96349"),Color("686a66"),Color("baac8c")]
const PLASTER_COLORS:=[Color("c6a77c"),Color("e0d6bb"),Color("c9af76"),Color("c59278")]
const ROOF_MIX:=0.35
const PLASTER_MIX:=0.55
const LIMITS:={"roof":4,"plaster":4,"door":3,"decor":2}

static func neutral()->Dictionary:
	return {"version":VERSION,"roof":0,"plaster":0,"door":0,"decor":0}

## identity may contain the actual emblem's `field` colour and `pattern`.
## There is no random or population-sized work, no date, and no stock access.
static func capture(values:Dictionary,knowledge:Array,identity:Dictionary={})->Dictionary:
	var result:=neutral()
	var raw:Variant=values.get("lived",{})
	if not raw is Dictionary or raw.is_empty():return result
	var lived:Dictionary=raw
	# Ten-percent bins prevent tiny daily value drift from changing a finish.
	var order:=_bin((_axis(lived,"centralization")+_axis(lived,"hierarchy"))*.5)
	var openness:=_bin((_axis(lived,"openness")+_axis(lived,"experimentation")+_axis(lived,"pluralism"))/3.0)
	var continuity:=_bin((_axis(lived,"collective_obligation")+1.0-_axis(lived,"experimentation")+1.0-_axis(lived,"achieved_status"))/3.0)
	var stewardship:=_bin((_axis(lived,"ecological_restraint")+_axis(lived,"common_stewardship"))*.5)
	var pigment:bool="mineral_pigment_preparation" in knowledge
	var earth:bool="clay_shaping" in knowledge
	var lime:bool="lime_mortar" in knowledge
	var marks:bool="pictographic_records" in knowledge
	# Roof tints are restrained choices within the existing roof material,
	# never an assertion that straw became tile or that new pigment was paid.
	# Actual emblem colours anchor established identities. Without one, lived
	# preferences choose natural warm earth, smoke or pale straw registers.
	var roof:=_identity_roof(identity)
	if roof==0:
		if stewardship>=.6:roof=4
		elif order>=.6:roof=3
		elif openness>=.6:roof=2 if pigment else 1
		elif continuity>=.6:roof=1
		else:roof=4
	result.roof=roof
	if earth or lime:
		result.plaster=2 if lime and (order>=.6 or stewardship>=.6) else 1
		if pigment and openness>=.6:result.plaster=3 if roof in [1,4] else 4
	# Simple doorway rhythms are dark/light earth-and-timber marks from the
	# founding, not advanced painted ornament. Learned pigments and recording
	# practices enable the richer decoration code; they add no material bonus.
	if order>=.6:result.door=1
	elif openness>=.6:result.door=2
	elif continuity>=.6:result.door=3
	elif identity.has("pattern"):result.door=1+posmod(int(identity.pattern),3)
	else:result.door=1
	if pigment:
		result.decor=2 if marks and (order>=.7 or openness>=.7 or continuity>=.7) else 1
	return result

## A supplied fallback is for an explicitly captured representative only.
## Missing legacy stamps are neutral by default; malformed/future stamps
## cannot silently acquire today's appearance. Inputs are never mutated.
static func for_plot(plot:Dictionary,fallback:Dictionary={})->Dictionary:
	var raw:Variant=plot.get("cultural_appearance",fallback)
	var result:=_normalized(raw)
	var family:=String(plot.get("material_family",""))
	if family not in ["earth","stone","brick","masonry","concrete"]:result.plaster=0
	# Temporary hides and light poles carry their material, not plaster or
	# permanent architectural trim. Roof tone is still the existing material.
	if String(plot.get("form","")).contains("shelter") or String(plot.get("land_use",""))=="temporary_encampment":
		result.plaster=0;result.decor=0
	return result

static func signature(profile:Dictionary)->String:
	var value:=_normalized(profile)
	return "%d:%d:%d:%d:%d" % [VERSION,value.roof,value.plaster,value.door,value.decor]

static func custom_data(plot:Dictionary,fallback:Dictionary={})->Color:
	var value:=for_plot(plot,fallback)
	return Color(float(value.roof),float(value.plaster),float(value.door),float(value.decor))

static func _normalized(raw:Variant)->Dictionary:
	var result:=neutral()
	if not raw is Dictionary:return result
	var version:Variant=raw.get("version",0)
	if not (version is int or version is float) or not is_finite(float(version)) or float(version)!=float(VERSION):return result
	for key:String in LIMITS:
		var value:Variant=raw.get(key,0)
		if not (value is int or value is float) or not is_finite(float(value)):return neutral()
		var number:=float(value)
		if number!=floor(number) or number<0.0 or number>float(LIMITS[key]):return neutral()
		result[key]=int(number)
	return result

static func _axis(lived:Dictionary,key:String)->float:
	var raw:Variant=lived.get(key,.5)
	if not (raw is int or raw is float) or not is_finite(float(raw)):return .5
	return clampf(float(raw),0.0,1.0)

static func _bin(value:float)->float:return float(roundi(value*10.0))/10.0

static func _identity_roof(identity:Dictionary)->int:
	var raw:Variant=identity.get("field","")
	var color:=Color.TRANSPARENT
	if raw is Color:color=raw
	elif raw is String:
		var code:=String(raw).trim_prefix("#")
		if code.length() in [6,8] and code.is_valid_hex_number(false):color=Color.from_string(code,Color.TRANSPARENT)
	if color.a<=0.0:return 0
	var selected:=0;var nearest:=INF
	for index in ROOF_COLORS.size():
		var candidate:Color=ROOF_COLORS[index]
		# Emblems are deliberately ink-dark. RGB distance made nine of the ten
		# founding colours choose smoke merely because it is the darkest roof.
		# Match hue/chroma independently of brightness; a near-neutral smoke
		# has no reliable hue and supplies the restrained cool-colour fallback.
		var hue_delta:=absf(color.h-candidate.h)
		hue_delta=minf(hue_delta,1.0-hue_delta)
		var hue_distance:=0.045 if candidate.s<0.1 else 4.0*hue_delta*hue_delta
		var distance:=hue_distance+0.25*pow(color.s-candidate.s,2.0)
		if distance<nearest:nearest=distance;selected=index+1
	return selected
