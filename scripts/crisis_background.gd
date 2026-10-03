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
	[0.0,{"children":0.296,"youth":0.307,"early_adults":0.223,"established_adults":0.193,"mature_adults":0.212,"elders":0.095}],
	[20.0,{"children":0.267,"youth":0.269,"early_adults":0.198,"established_adults":0.174,"mature_adults":0.194,"elders":0.089}],
	[45.0,{"children":0.233,"youth":0.217,"early_adults":0.158,"established_adults":0.138,"mature_adults":0.156,"elders":0.072}],
	[80.0,{"children":0.203,"youth":0.182,"early_adults":0.133,"established_adults":0.118,"mature_adults":0.134,"elders":0.063}],
	[150.0,{"children":0.195,"youth":0.175,"early_adults":0.127,"established_adults":0.112,"mature_adults":0.128,"elders":0.060}],
	[275.0,{"children":0.267,"youth":0.240,"early_adults":0.168,"established_adults":0.143,"mature_adults":0.159,"elders":0.072}],
	[425.0,{"children":0.320,"youth":0.290,"early_adults":0.200,"established_adults":0.167,"mature_adults":0.181,"elders":0.080}],
	[600.0,{"children":0.375,"youth":0.342,"early_adults":0.236,"established_adults":0.196,"mature_adults":0.211,"elders":0.092}],
	[825.0,{"children":0.458,"youth":0.418,"early_adults":0.285,"established_adults":0.235,"mature_adults":0.247,"elders":0.106}],
	[1075.0,{"children":0.477,"youth":0.435,"early_adults":0.297,"established_adults":0.244,"mature_adults":0.257,"elders":0.110}]
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
