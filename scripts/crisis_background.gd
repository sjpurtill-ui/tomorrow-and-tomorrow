extends RefCounted
## THE CRISES' SHARE OF THE AGE TABLE. The age table (game_state.gd
## BASELINE_HAZARD_BY_AGE with the early-care multipliers and the day's
## conditions) is the all-cause benchmark: about 25 years of life and 260 of
## 1,000 babies lost in the first year at the founding
## (docs/research/BENCHMARKS_600.md), crises included. The crises
## (crisis_system.gd for the god's people, crisis_unattended.gd for every
## other) then kill on their own odds and tolls: sickness, hunger, floods,
## fires and dry seasons. Counting both took the same deaths twice, about 8 in
## 1,000 a year at the founding, and a fed people shrank.
##
## So each day's deaths emit only the age table's background: each age
## cohort's all-cause hazard less CRISIS_SHARE of it, the share the crises take
## from that cohort on average for a typical people of the era (by the crises'
## own death weights: sickness and hunger hardest on children and the old,
## drowning and fire on the default row). The crises themselves are untouched:
## the same odds, tolls, timing, named dead and orders. A calm decade grows;
## a bad one is felt; a better order still saves lives.
##
## The screens read the all-cause table (life expectancy, infant mortality,
## the hearth count's expected deaths): the background plus the crises'
## expected share, so they show life as it is lived, crises included.
##
## Measured by tools/sim/crisis_share.py (the surrogate's balanced path on good
## and average land, the engine's crisis hazards and tolls, many seeds); re-run
## it after changing the crises, the age table or the founding.

const COHORTS:Array[String]=["children","youth","early_adults","established_adults","mature_adults","elders"]
## [game year, {cohort: share of its all-cause hazard the crises take}].
const CRISIS_SHARE:Array=[
	[0.0,{"children":0.293,"youth":0.305,"early_adults":0.221,"established_adults":0.191,"mature_adults":0.210,"elders":0.094}],
	[20.0,{"children":0.258,"youth":0.261,"early_adults":0.193,"established_adults":0.169,"mature_adults":0.189,"elders":0.087}],
	[45.0,{"children":0.229,"youth":0.213,"early_adults":0.156,"established_adults":0.137,"mature_adults":0.155,"elders":0.072}],
	[80.0,{"children":0.203,"youth":0.183,"early_adults":0.134,"established_adults":0.119,"mature_adults":0.135,"elders":0.063}],
	[150.0,{"children":0.190,"youth":0.171,"early_adults":0.124,"established_adults":0.109,"mature_adults":0.125,"elders":0.059}],
	[275.0,{"children":0.259,"youth":0.234,"early_adults":0.164,"established_adults":0.139,"mature_adults":0.154,"elders":0.070}],
	[425.0,{"children":0.322,"youth":0.292,"early_adults":0.202,"established_adults":0.169,"mature_adults":0.183,"elders":0.081}],
	[600.0,{"children":0.386,"youth":0.352,"early_adults":0.243,"established_adults":0.202,"mature_adults":0.218,"elders":0.096}],
	[825.0,{"children":0.467,"youth":0.427,"early_adults":0.290,"established_adults":0.238,"mature_adults":0.249,"elders":0.107}],
	[1075.0,{"children":0.489,"youth":0.446,"early_adults":0.304,"established_adults":0.249,"mature_adults":0.262,"elders":0.112}],
	[1350.0,{"children":0.483,"youth":0.441,"early_adults":0.300,"established_adults":0.246,"mature_adults":0.259,"elders":0.111}],
	[1650.0,{"children":0.503,"youth":0.459,"early_adults":0.312,"established_adults":0.256,"mature_adults":0.267,"elders":0.114}],
	[1950.0,{"children":0.487,"youth":0.445,"early_adults":0.302,"established_adults":0.247,"mature_adults":0.258,"elders":0.110}],
	[2250.0,{"children":0.470,"youth":0.428,"early_adults":0.290,"established_adults":0.236,"mature_adults":0.247,"elders":0.105}],
	[2550.0,{"children":0.420,"youth":0.380,"early_adults":0.258,"established_adults":0.211,"mature_adults":0.220,"elders":0.095}]
]

## Each cohort's crisis share at game year `year` ({cohort: share}).
static func shares(year:float)->Dictionary:
	var result:Dictionary={}
	var first:Array=CRISIS_SHARE[0]
	if year<=float(first[0]) or CRISIS_SHARE.size()==1:
		for key:String in COHORTS:result[key]=float((first[1] as Dictionary).get(key,0.0))
		return result
	for index in range(1,CRISIS_SHARE.size()):
		var high:Array=CRISIS_SHARE[index]
		if year<=float(high[0]):
			var low:Array=CRISIS_SHARE[index-1]
			var t:=(year-float(low[0]))/maxf(0.0001,float(high[0])-float(low[0]))
			for key:String in COHORTS:result[key]=lerpf(float((low[1] as Dictionary).get(key,0.0)),float((high[1] as Dictionary).get(key,0.0)),t)
			return result
	var last:Array=CRISIS_SHARE[CRISIS_SHARE.size()-1]
	for key:String in COHORTS:result[key]=float((last[1] as Dictionary).get(key,0.0))
	return result

## What of each cohort's all-cause hazard the day's background deaths take
## ({cohort: 1 - share}).
static func background(year:float)->Dictionary:
	var result:Dictionary={}
	var share:=shares(year)
	for key:String in COHORTS:result[key]=1.0-clampf(float(share[key]),0.0,0.9)
	return result
