extends RefCounted
## Field survival of the civilization's own scouts.
##
## A village of a few hundred gains roughly one person a year at historical
## growth rates, so scouting cannot be a steady drain on the people. Most
## trouble on the road is a delay, an injury, or a party that turns back with
## what it has seen. A death is uncommon and depends on the country crossed,
## the distance from home, the season, hostile contact and the scouts' own
## experience. The Chief Scout reads the settlement's natural increase and
## keeps the standing expected toll to a small share of it; the player can
## still order parties out regardless, at an honestly higher risk.

## Chance that a novice party in ordinary country suffers a death during one
## month on the road, close to home, outside winter.
const BASE_MONTHLY_DEATH:=0.0024
const MAX_DEATH_CHANCE:=0.30
const DEFAULT_TERRAIN:=0.35
const MAX_VETERANCY:=0.85
## Reckless parties press on through danger instead of turning back.
const RECKLESS_FACTOR:=2.6
const RECKLESS_HOSTILE_FACTOR:=1.5
## Share of the settlement's natural increase the Chief Scout will risk on
## standing (staff-managed) scouting, with a floor that always allows one short
## party so exploration never stops outright.
const BUDGET_SHARE:=0.12
const FLOOR_BUDGET:=0.05
## Prior growth used before a year of vital statistics exists.
const PRIOR_GROWTH_RATE:=0.0015
const STANCES:={
	"guarded":{"max_duration":30,"max_parties":1,"watch_rest_days":90,"label":"Guarded — the people are shrinking; only short, close parties go out."},
	"cautious":{"max_duration":90,"max_parties":2,"watch_rest_days":30,"label":"Cautious — growth is slow; parties stay within a season's walk."},
	"steady":{"max_duration":180,"max_parties":4,"watch_rest_days":1,"label":"Steady — parties range for up to half a year."},
	"bold":{"max_duration":365,"max_parties":6,"watch_rest_days":1,"label":"Bold — the people are growing; long expeditions are acceptable."},
}


static func terrain_danger(samples:Array)->float:
	## Danger of the country a route crosses, 0 (easy lowland) to 1 (bare
	## summits, frozen or sodden ground). Samples are ground-survey records.
	if samples.is_empty(): return DEFAULT_TERRAIN
	var total:=0.0
	var counted:=0
	for sample_variant in samples:
		if not sample_variant is Dictionary: continue
		var sample:Dictionary=sample_variant
		if sample.is_empty(): continue
		var danger:=0.22
		var height:=float(sample.get("height",0.0))
		if height>6.0: danger+=0.45
		elif height>3.2: danger+=0.20
		danger+=clampf(float(sample.get("slope",0.0))*0.25,0.0,0.18)
		match String(sample.get("biome","")):
			"tundra": danger+=0.25
			"wetland": danger+=0.15
			"steppe": danger+=0.06
			"woodland": danger+=0.05
		danger+=absf(float(sample.get("temperature",0.5))-0.5)*0.30
		if float(sample.get("river_distance_km",INF))<1.5: danger+=0.05
		total+=clampf(danger,0.0,1.0)
		counted+=1
	return clampf(total/float(counted),0.0,1.0) if counted>0 else DEFAULT_TERRAIN


static func season_factor(start_day:int,duration_days:int)->float:
	## Winter on the road is harder. Averaged over the days actually spent away.
	var steps:=maxi(1,ceili(float(maxi(1,duration_days))/15.0))
	var total:=0.0
	for step in steps:
		var day_of_year:=posmod(start_day+step*15,365)
		total+=1.0+0.5*maxf(0.0,cos(TAU*float(day_of_year-15)/365.0))
	return total/float(steps)


static func distance_factor(one_way_km:float)->float:
	## Farther from home means longer to limp back and no one to send for help.
	return 1.0+clampf(maxf(0.0,one_way_km)/1500.0,0.0,1.0)


static func skill_factor(veterancy:float)->float:
	return 1.0-0.6*clampf(veterancy,0.0,MAX_VETERANCY)


static func assess(context:Dictionary)->Dictionary:
	## Honest odds for one party. `context` keys: duration_days, one_way_km,
	## personnel, terrain_danger, start_day, veterancy, reckless.
	var duration:=maxi(1,int(context.get("duration_days",30)))
	var months:=float(duration)/30.0
	var personnel:=maxi(1,int(context.get("personnel",4)))
	var terrain:=clampf(float(context.get("terrain_danger",DEFAULT_TERRAIN)),0.0,1.0)
	var veterancy:=clampf(float(context.get("veterancy",0.0)),0.0,MAX_VETERANCY)
	var reckless:=bool(context.get("reckless",false))
	var season:=season_factor(int(context.get("start_day",0)),duration)
	var distance:=distance_factor(float(context.get("one_way_km",0.0)))
	var terrain_mult:=0.5+1.5*terrain
	var size_mult:=1.15 if personnel<=2 else 1.0
	var monthly:=BASE_MONTHLY_DEATH*terrain_mult*season*distance*skill_factor(veterancy)*size_mult*(RECKLESS_FACTOR if reckless else 1.0)
	var death_chance:=clampf(1.0-pow(1.0-clampf(monthly,0.0,0.5),months),0.0,MAX_DEATH_CHANCE)
	var mishap_chance:=clampf((0.08+0.22*terrain+0.02*months)*(1.0-0.4*veterancy)*(1.3 if reckless else 1.0),0.0,0.6)
	var toll:=1.0+(0.25 if (reckless or terrain>0.7) and personnel>=4 else 0.0)
	var expected:=death_chance*toll
	var label:="LOW" if death_chance<0.01 else ("GUARDED" if death_chance<0.04 else ("HIGH" if death_chance<0.12 else "GRAVE"))
	return {"death_chance":death_chance,"mishap_chance":mishap_chance,"expected_deaths":expected,"annual_expected_deaths":expected*365.0/float(duration),"hostile_multiplier":(1.0-0.35*veterancy)*(RECKLESS_HOSTILE_FACTOR if reckless else 1.0),"label":label,"reckless":reckless,"terrain_danger":terrain,"season":season,"veterancy":veterancy}


static func odds_phrase(assessment:Dictionary)->String:
	var chance:=float(assessment.get("death_chance",0.0))
	if chance<=0.0: return "no one is expected to be lost"
	var one_in:=maxi(2,roundi(1.0/chance))
	return "about one party in %d like this loses someone" % one_in


static func resolve(assessment:Dictionary,personnel:int,rng:RandomNumberGenerator)->Dictionary:
	## One roll decides the road. Deaths are rare; most trouble is survivable.
	var party:=maxi(1,personnel)
	var roll:=rng.randf()
	var death_chance:=float(assessment.get("death_chance",0.0))
	var mishap_chance:=float(assessment.get("mishap_chance",0.0))
	if party>1 and roll<death_chance:
		var lost:=1
		var grave:=bool(assessment.get("reckless",false)) or float(assessment.get("terrain_danger",0.0))>0.7
		if grave and party>=4 and rng.randf()<0.25: lost=2
		return {"kind":"loss","lost":mini(lost,party-1),"mishap":""}
	if roll<death_chance+mishap_chance:
		var reckless:=bool(assessment.get("reckless",false))
		var pick:=rng.randf()
		var mishap:="turned_back" if pick<(0.15 if reckless else 0.35) else ("injury" if pick<0.70 else "delay")
		return {"kind":"mishap","lost":0,"mishap":mishap}
	return {"kind":"safe","lost":0,"mishap":""}


static func mishap_line(mishap:String,personnel:int,rng:RandomNumberGenerator)->String:
	match mishap:
		"injury":
			var hurt:=mini(maxi(1,personnel-1),1+(1 if personnel>=5 and rng.randf()<0.3 else 0))
			return "%s hurt on the road and carried home by the others; all came back alive." % ("One scout was" if hurt==1 else "Two scouts were")
		"delay":
			return "Flooded fords and bad weather held the party up for days, but everyone came home."
		"turned_back":
			return "Sickness and hard going turned the party back before it reached the end of its route; it brings home what it saw on the way."
	return ""


static func updated_veterancy(veterancy:float,returned:int,personnel:int,lost:int)->float:
	## Each homecoming teaches the corps; each death takes experience with it.
	var value:=clampf(veterancy,0.0,MAX_VETERANCY)
	if returned>0: value+=(MAX_VETERANCY-value)*0.05*clampf(float(returned)/3.0,0.5,1.5)
	if lost>0 and personnel>0: value-=value*0.35*clampf(float(lost)/float(personnel),0.0,1.0)
	return clampf(value,0.0,MAX_VETERANCY)


static func destroyed_share(aggression:float,at_war:bool,reckless:bool)->float:
	## Of hostile contacts that are not captures, how many end with the whole
	## party dead rather than chased off. Rare outside open war.
	return clampf(0.04+clampf(aggression,0.0,1.0)*0.14+(0.22 if at_war else 0.0)+(0.08 if reckless else 0.0),0.04,0.5)


static func natural_increase(population:float,vital:Dictionary,tracked_days:int)->float:
	## Births minus deaths over the past year, blended with a slow prior until a
	## full year has been recorded.
	var observed:=float(vital.get("net",0))
	var weight:=clampf(float(maxi(0,tracked_days))/365.0,0.0,1.0)
	return observed*weight+maxf(0.0,population)*PRIOR_GROWTH_RATE*(1.0-weight)


static func prudence(population:float,annual_increase:float)->Dictionary:
	## The Chief Scout's own judgment of how much to risk.
	var people:=maxf(1.0,population)
	var rate:=annual_increase/people
	var stance:="bold"
	if annual_increase<0.0 or people<40.0: stance="guarded"
	elif rate<0.0015: stance="cautious"
	elif rate<0.005: stance="steady"
	var rules:Dictionary=STANCES[stance]
	return {"stance":stance,"growth_rate":rate,"annual_increase":annual_increase,"budget":maxf(FLOOR_BUDGET,BUDGET_SHARE*maxf(0.0,annual_increase)),"max_duration":int(rules.max_duration),"max_parties":int(rules.max_parties),"watch_rest_days":int(rules.watch_rest_days),"label":String(rules.label)}
