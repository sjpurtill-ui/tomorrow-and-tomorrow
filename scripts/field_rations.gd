extends RefCounted
## Food for soldiers away from home, kept apart from the home fires.
##
## Home stores feed the people at home first-hand. A band in the field eats
## what the carriers bring out plus what it can forage; a garrison holding a
## captured town eats mostly from that town. When soldiers go short, the
## shortfall stays with them (supply, condition, speed) and is told as their
## trouble, never as hunger at home.

## Share of a day's ration a band away from home finds for itself by hunting,
## gathering and taking from the country it stands in. Camped bands forage
## better than bands on the march; neither lives well off the land alone.
const FORAGE_STATIONED:=0.35
const FORAGE_MOVING:=0.18
## A ration below this share counts as a hungry day for the soldiers.
const HUNGRY_BELOW:=0.75


static func forage_share(force:Dictionary)->float:
	var base:=FORAGE_MOVING if String(force.get("status","stationed"))=="moving" else FORAGE_STATIONED
	# The country, the season and the band's size (supply_state.gd): rich green
	# land in summer feeds a small band better than a host in winter.
	var supply=load("res://scripts/supply_state.gd")
	return minf(float(supply.FORAGE_SHARE_MAX),base*float(supply.forage_factor(force)))


## Share of a garrison's ration the held town supplies from its own fields and
## stores. A quiet town feeds nearly all of it; a resentful one hides food.
static func occupation_local_share(region:Dictionary)->float:
	if region.is_empty() or String(region.get("controller",""))!="player": return 0.0
	var resistance:=clampf(float(region.get("resistance",0.5)),0.0,1.0)
	return clampf(0.95-resistance*0.45,0.5,0.95)


static func occupation_key(force:Dictionary)->String:
	return "%s/%s" % [String(force.get("civ_id","")),String(force.get("region_id",""))]


## Count hungry days on a force; a fed day wears the count down again.
## Preserved travel food and supply know-how (research: supply endurance) let a
## short band hold out longer: its hungry days count slower (research_mechanics.gd).
static func mark_day(force:Dictionary,ratio:float,span:float)->void:
	var days:=float(force.get("hungry_days",0.0))
	var pace:float=preload("res://scripts/research_mechanics.gd").hunger_pace()
	force["hungry_days"]=days+span*pace if ratio<HUNGRY_BELOW else maxf(0.0,days-2.0*span)


static func is_hungry(force:Dictionary)->bool:
	return float(force.get("hungry_days",0.0))>=3.0 and int(force.get("troops",0))>0


## Plain words for a band short of food, or "" when it is fed.
## "Rovik's band is short of food, about 25 km out."
static func short_words(force:Dictionary,home:Vector2)->String:
	if not is_hungry(force): return ""
	var who:=String((force.get("commander",{}) as Dictionary).get("name","")).strip_edges() if force.get("commander") is Dictionary else ""
	who=who.get_slice(" ",0)
	var subject:=("%s's band" % who) if who!="" else ("The garrison in %s" % String(force.get("region_name","the held town")) if force.has("region_id") else "Our band in the field")
	if force.has("region_id") and who!="": subject="%s's garrison in %s" % [who,String(force.get("region_name","the held town"))]
	var marks=load("res://scripts/hud/army_marks.gd")
	var km:float=marks.home_km(force,home)
	var where:String=", %s out" % marks.km_words(km) if km>=1.0 and not force.has("region_id") else ""
	var how:="going hungry" if float(force.get("provision_ratio",1.0))<0.45 else "short of food"
	return "%s is %s%s." % [subject,how,where]


## One plain line per band or garrison now short of food.
static func hungry_lines(military:Object,home:Vector2)->PackedStringArray:
	var out:PackedStringArray=[]
	if military==null: return out
	for force:Dictionary in military.field_armies:
		var words:=short_words(force,home)
		if words!="": out.append(words)
	for force:Dictionary in military.occupation_forces:
		var words:=short_words(force,home)
		if words!="": out.append(words)
	return out
