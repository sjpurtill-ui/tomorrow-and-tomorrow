extends RefCounted
## THE FORCES TAB AS NUMBERS: HOI4's army overview; hud/forces_board.gd
## draws it.
##
## One row per card of the army bar (hud/army_bar_model.gd): the levy at
## home, each band, each town we hold; the bands one headquarters or one
## general leads stand as one army with its bands beneath. Men, gear, will
## to fight, supply, drill, the state glyph and what they are doing are the
## army bar's own readings of the one ledger (docs/ADJUDICATION.md), so a
## band reads the same on the bar, in this list and on the map. This adds
## only what a list needs: the template the band was raised from, where it
## stands, and which filters it answers to. Pure reads; nothing here
## changes the world.
##
##   rows()      the rows: each an army-bar card plus {template, where,
##               short, away, bands (a group's own rows)}
##   passes()    whether a row answers a filter (FILTERS)
##   counts()    how many rows answer each filter, for the chips
##   summary()   the strip on top: men, gear issued, the hungry, in training

const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const Deploy:=preload("res://scripts/hud/deployment_model.gd")
const Story:=preload("res://scripts/hud/military_force_story.gd")
## The filter chips, in order: [id, words].
const FILTERS:=[["all","All"],["field","In the field"],["garrison","Garrisons"],["short","Short of gear"]]


static func _host(mc:Node)->Node:
	return mc if mc!=null else MilitaryCampaign


# --- Rows -------------------------------------------------------------------------

static func rows(mc:Node=null)->Array[Dictionary]:
	mc=_host(mc)
	var out:Array[Dictionary]=[]
	var templates:Array=mc.army_templates
	for card:Dictionary in BarModel.cards(mc):
		var row:=decorate(card,templates)
		if String(card.kind)=="group":
			var bands:Array[Dictionary]=[]
			for member in card.get("member_cards",[]):bands.append(decorate(member,templates))
			row["bands"]=bands
			# The army is doing what its most pressing band is doing.
			for band:Dictionary in bands:
				if String(band.get("state",""))==String(card.get("state","")):
					row["doing"]=String(band.get("doing",""));break
		out.append(row)
	return out


## One army-bar card with the list's words added; the card's own numbers
## are left exactly as the bar reads them.
static func decorate(card:Dictionary,templates:Array=[])->Dictionary:
	var row:=card.duplicate()
	row.erase("member_cards")
	row["template"]=template_of(card,templates)
	row["where"]=where_of(card)
	row["short"]=is_short(card)
	row["away"]=String(card.get("kind","")) in ["army","group"] and not bool(card.get("home",false))
	return row


## A band short of gear: sets it should carry and does not (ammunition is
## told on the supply bar, as the army bar tells it).
static func is_short(card:Dictionary)->bool:
	if bool(card.get("unknown",false)):return false
	var detail:Dictionary=card.get("gear_detail",{})
	return not (detail.get("missing",{}) as Dictionary).is_empty() or float(card.get("gear",1.0))<0.999


## The template a band was raised from ("Levy band" for "Levy band 2"), else
## what it is made of ("Levy · archers"); an army of bands says how many.
static func template_of(card:Dictionary,templates:Array=[])->String:
	if String(card.get("kind",""))=="group":
		var count:=(card.get("members",[]) as Array).size()
		return "%d bands" % count
	var own:=String(card.get("name","")).strip_edges()
	var base:=own.rstrip("0123456789 ").strip_edges()
	if base!="":
		for t in templates:
			var template:Dictionary=t
			if String(template.get("name","")).strip_edges().to_lower()==base.to_lower():return Story.sentence_name(String(template.name))
	return kinds_words(card.get("kinds",[]))


## "Levy", "Levy · archers", "Spearmen · archers +1".
static func kinds_words(kinds:Array,limit:int=2)->String:
	var names:PackedStringArray=[]
	for kind in kinds.slice(0,limit):
		var label:=String((kind as Dictionary).get("label",""))
		names.append(label if names.is_empty() else label.to_lower())
	var text:=" · ".join(names)
	if kinds.size()>limit:text+=" +%d" % (kinds.size()-limit)
	return text


## Where it stands: our settlement at home, the town a garrison holds, else
## how far out and which way ("25 km north-east").
static func where_of(card:Dictionary)->String:
	if bool(card.get("unknown",false)):return "No report yet"
	if String(card.get("kind",""))=="garrison":return String(card.get("name",""))
	var home_name:=String(GameState.settlement_name).strip_edges()
	if home_name=="":home_name="Home"
	if bool(card.get("home",false)):return home_name
	var at:Vector2=card.get("position",Vector2.INF)
	var home:Vector2=WorldSimulation.world.player_world_origin if WorldSimulation.world!=null else Vector2.INF
	if not at.is_finite() or not home.is_finite():return ""
	var km:=at.distance_to(home)
	if km<ArmyMarks.HOME_RADIUS_KM:return home_name
	var way:=ArmyMarks.compass(at-home)
	return ("%s %s" % [ArmyMarks.km_words(km).trim_prefix("about "),way]).strip_edges()


# --- Filters ----------------------------------------------------------------------

static func passes(row:Dictionary,filter:String)->bool:
	match filter:
		"field":return bool(row.get("away",false))
		"garrison":return String(row.get("kind",""))=="garrison"
		"short":
			if bool(row.get("short",false)):return true
			for band:Dictionary in row.get("bands",[]):
				if bool(band.get("short",false)):return true
			return false
	return true


static func counts(list:Array)->Dictionary:
	var out:={}
	for entry:Array in FILTERS:
		var id:=String(entry[0]);var n:=0
		for row:Dictionary in list:
			if passes(row,id):n+=1
		out[id]=n
	return out


# --- The strip --------------------------------------------------------------------

## {men, full, home, field, garrison, issued, required, missing:{item:n},
## hungry:[titles], training}. Sums of the rows' own readings; a band away
## with no report yet is not guessed at.
static func summary(list:Array,mc:Node=null)->Dictionary:
	mc=_host(mc)
	var out:={"men":0,"full":0,"home":0,"field":0,"garrison":0,"issued":0,"required":0,"missing":{},"hungry":[],"unknown":0}
	for row:Dictionary in list:
		if bool(row.get("unknown",false)):
			out.unknown=int(out.unknown)+1
			continue
		var men:=int(row.get("men",0))
		out.men=int(out.men)+men;out.full=int(out.full)+int(row.get("full",men))
		var place:="garrison" if String(row.get("kind",""))=="garrison" else ("home" if bool(row.get("home",false)) else "field")
		out[place]=int(out[place])+men
		var detail:Dictionary=row.get("gear_detail",{})
		out.issued=int(out.issued)+int(detail.get("issued",0));out.required=int(out.required)+int(detail.get("required",0))
		for item:String in detail.get("missing",{}):(out.missing as Dictionary)[item]=int((out.missing as Dictionary).get(item,0))+int(detail.missing[item])
		var parts:Array=(row.bands as Array) if row.has("bands") else [row]
		for part in parts:
			var band:Dictionary=part
			if String(band.get("state",""))=="hungry" or String(band.get("supply_state",""))=="starving":(out.hungry as Array).append(String(band.get("title","")))
	out["training"]=int(Deploy.manpower(mc).training)
	return out
