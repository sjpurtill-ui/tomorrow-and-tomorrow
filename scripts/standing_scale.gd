extends RefCounted
## THE AGE'S YARDSTICK for the nine strengths (standing.gd).
##
## The player, 2026-10-03: "It's very hard to tell how you stand in relation
## to others when everyone just starts out at 100% on the things they're
## focused on. What is the 100% relative to?"
##
## Every strength is now read against what peoples of the same age managed:
##   0.2 (20%) the low end: a poor or neglectful people of the age;
##   0.5 (50%) the typical people of the age;
##   0.8 (80%) what the best-documented peoples of the age did;
##   1.0 (100%) the most the age has plausibly seen at all.
## Between the anchors the reading runs on a log scale (doubling a store
## gains as much as the doubling before it), so each step up is harder than
## the last and no hoard of one thing fills a strength by itself. Shares that
## cannot pass 1 (trust in the chiefs, holding together) are read on the
## shortfall instead (from 90% to 97% is as far as from 70% to 90%).
##
## Where the anchors come from (docs/STANDING_DESIGN.md section 10 has the
## table):
##   - the benchmark bands the project already uses (docs/research
##     benchmarks_*.json): Might from defense_labor_share, Genius from
##     discoveries_known (600-3000) and its spread;
##   - the fast sim's balanced people (tools/sim, path_balanced) where the
##     benchmarks have nothing or run behind the engine (discoveries before
##     year 600; the engine's peoples know about ENGINE_PACE times the
##     provisional benchmark from 600 on, measured at 600 and 1200);
##   - the computer peoples of a played world at year 75 (their stores,
##     materials, goods, scouts, officials and works) where neither has it.
## Every people reads the same yardstick, the god's and the computer's alike.
##
## Static; preload. Pure: reads nothing but its arguments.

const LOW_SCORE:=0.2
const TYPICAL_SCORE:=0.5
const HIGH_SCORE:=0.8
const MAX_SCORE:=1.0

## A table row: [game year, low, typical, high, max]. Between rows the
## anchors are read by straight lines; past the last row, the last row.
##
## Might: the share of ALL the people ready to fight (warriors x readiness,
## walls counted, standing.gd), from the benchmark's defense_labor_share (% of
## the able workforce under arms or on watch) x ABLE_SHARE x READY (a watch
## drilled as the engine's peoples drill theirs: 0.91-0.97 at year 75).
const ABLE_SHARE:=0.6
const READY:=0.9
## defense_labor_share (%), benchmarks_600..3000.json, low/typical/high/max.
const DEFENSE_SHARE:=[[0,2,4,8,15],[100,2,4,8,15],[300,2,5,10,18],[600,2,5,10,20],[700,3,6,12,22],[800,2,5,10,20],
	[2300,2,5,10,20],[2400,2,5,11,22],[2500,1.5,4,9,20],[2600,1.5,4,9,20],[2700,2,4.5,10,25],[2800,2,5,12,30],[2900,1.5,3,7,18],[3000,1,2.5,5,15]]
## Genius: practices known. Before 600, the fast sim's balanced people's
## typical count (path_balanced, 2 seeds) with the benchmark's spread; from 600,
## benchmarks discoveries_known x ENGINE_PACE.
const ENGINE_PACE:=1.43
const KNOWN_SPREAD:=[0.5,1.0,1.28,1.47]
const KNOWN_TYPICAL_EARLY:=[[0,10],[10,30],[25,92],[50,269],[75,388],[100,445],[150,528],[200,612],[300,758],[400,892],[500,1030]]
const KNOWN_BENCHMARK:=[[600,390,790,1010,1180],[700,450,900,1160,1355],[800,515,1030,1325,1535],[900,575,1155,1485,1715],[1000,640,1275,1640,1875],
	[1100,690,1380,1775,2015],[1200,730,1460,1880,2087],[1300,770,1545,1985,2206],[1400,815,1630,2100,2331],[1500,870,1745,2240,2490],[1600,915,1835,2355,2618],
	[1700,980,1960,2525,2803],[1800,1060,2115,2720,3024],[1900,1128,2255,2900,3222],[2000,1207,2414,3104,3449],[2100,1257,2514,3233,3592],[2200,1318,2636,3389,3766],
	[2300,1376,2752,3538,3931],[2400,1457,2915,3748,4164],[2500,1524,3047,3918,4353],[2600,1624,3248,4176,4640],[2700,1733,3466,4456,4951],[2800,1836,3671,4720,5245],
	[2900,1942,3884,4993,5548],[3000,2008,4016,5163,5737]]
## Share of the people at research (scholars): balanced peoples keep about
## 3.5% (work_paths LEARNING_CAP), computer peoples 2-3%; a people given to
## learning 11-12%, the most anyone sustains about 15%.
const SCHOLARS:=[[0,0.01,0.03,0.08,0.15]]
## Days of food in store: computer peoples and the fast sim hold about 30
## (the Headman plans 60 while short, food_care.gd); the deepest a ruler plans
## is 120; a year's grain is the most the granary states of history kept.
const STORES:=[[0,7,25,90,240],[300,10,30,120,365]]
## Building materials (timber, stone, clay, fibre) a head, and made goods a
## head: every people founds with about 0.2 and 0.1; by year 10 the yards and
## the makers have filled to what computer peoples of a played world held at
## year 75 (median 1.5 and 2).
const MATERIALS:=[[0,0.05,0.2,1.0,3.0],[10,0.3,1.5,6.0,15.0]]
const GOODS:=[[0,0.03,0.1,0.5,1.5],[10,0.5,2.0,6.0,12.0]]
## Days of water drawn and kept against a siege: none at the founding;
## computer peoples kept about 5 at year 75.
const WATER:=[[0,0.0,0.0,1.0,3.0],[10,0.5,3.0,8.0,20.0]]
## The defences' bonus (built_fabric.gd defense_bonus_now; a bastion 0.62):
## a ditch and fence early, walls by the bronze age.
const WALLS:=[[0,0.01,0.04,0.2,0.45],[100,0.03,0.12,0.35,0.62],[600,0.05,0.15,0.4,0.62],[1500,0.08,0.25,0.5,0.62]]
## Shares that cannot pass 1 (read on the shortfall): health, holding
## together, trust in the chiefs, carrying and hauling, the culture's allure.
## Played worlds and the fast sim settle near these within a few decades.
const HEALTH:=[[0,0.6,0.85,0.95,0.99],[25,0.75,0.94,0.98,0.995]]
const COHESION:=[[0,0.4,0.6,0.85,0.95],[25,0.75,0.93,0.98,0.995]]
const LEGITIMACY:=[[0,0.4,0.62,0.85,0.95],[25,0.75,0.93,0.98,0.995]]
const LOGISTICS:=[[0,0.08,0.16,0.4,0.6],[25,0.35,0.6,0.82,0.95]]
const CULTURE:=[[0,0.05,0.15,0.4,0.6],[50,0.35,0.62,0.8,0.92]]
## Administrators a share of the people (computer peoples 2-8%).
const ADMINISTRATION:=[[0,0.01,0.035,0.08,0.15]]
## Peoples met, counted from one (1 = none): contact comes years in
## (sparse-contact rule), then grows with reach.
const MET:=[[0,1,1,2,3],[50,1,1.5,3,4],[100,1,2,4,6],[300,1.5,3,6,9],[600,2,4,8,12],[1200,3,6,12,20]]
## Great works' renown points (great_works.gd renown), counted from one: most
## computer peoples of a played world had raised none by year 75 (two of
## twelve had, 4 and 24); the fast sim's standard policy, one every 15 years,
## is the high road. The benchmark's largest structures grow tenfold from
## 5000 BC to 3000 BC and tenfold again by 1500 BC.
const WORKS:=[[0,0.8,1,2,4],[100,0.8,1,10,30],[200,0.8,4,30,90],[300,0.8,10,60,180],[600,1.5,30,150,400],[1200,3,80,350,900],[3000,8,200,800,2000]]
## The realm's beauty (built_fabric.gd realm_beauty, 0..1), the fast sim's
## balanced people (0.1 by year 10, 0.2 at 75, 0.36 by 300) and builders'
## (0.4, 0.6). Read as 1 + 10 x beauty (beauty_anchors), so a village with no
## fine works yet is not nothing.
const BEAUTY:=[[0,0.0,0.0,0.1,0.25],[10,0.03,0.1,0.25,0.45],[100,0.05,0.22,0.45,0.7],[300,0.08,0.33,0.6,0.85]]
static func beauty_anchors(year:float)->Array:
	var out:Array=[]
	var a:=anchors(BEAUTY,year)
	return [0.8+10.0*float(a[0]),1.0+10.0*float(a[1]),1.0+10.0*float(a[2]),1.0+10.0*float(a[3])]

## Scouts and the watch: the share of the people out scouting and surveying,
## and half the share on the watch (every people founds with about 6 in 100;
## computer peoples of a played world at year 75: 6.4-11.8, median about 8.5).
const SCOUTS:=[[0,0.02,0.06,0.12,0.2],[25,0.03,0.08,0.15,0.22]]
## Mean familiarity with the peoples we know (society_exchange.gd ties).
const FAMILIARITY:=[[0,0.01,0.08,0.3,0.6]]
## Counts that start at nothing are read as 1 + the count (or a multiple of
## it), with the low end below 1, so having nothing reads typical while
## nothing is typical and falls away smoothly as the age moves on.
## Treaties and kept exchanges, 1 + count: computer peoples of a played world
## at year 75 held one or two.
const TREATIES:=[[0,0.8,1,2,4],[50,0.8,2,3.5,6],[300,0.9,2.5,5,8],[1200,1,3.5,7,12]]
## Gifts given, 1 + 20 x their worth a head of our people a year: three of
## twelve computer peoples gave at year 75 (0.01, 0.05 and 0.09 a head).
const GIFTS:=[[0,0.8,1,2,4],[100,0.8,1.2,3,7],[300,0.85,1.6,4,10]]
## Envoy-days abroad in the last five years, 1 + a tenth of them a hundred of
## our people: one of twelve computer peoples had a mission out at year 75.
const ENVOY_DAYS:=[[0,0.8,1,3,8],[100,0.8,1.5,6,15],[300,0.9,2.5,10,25]]
## How well we know the peoples we know (their contact_intelligence, 0..0.95;
## computer peoples at year 75: 0.19-0.48, median 0.22).
const INTEL:=[[0,0.1,0.22,0.55,0.8]]

## The anchors [low, typical, high, max] of a table at a game year.
static func anchors(table:Array,year:float)->Array:
	if table.is_empty(): return [0.0,1.0,2.0,3.0]
	var first:Array=table[0]
	if table.size()==1 or year<=float(first[0]): return _row(first)
	for i in range(1,table.size()):
		var row:Array=table[i]
		if year<=float(row[0]):
			var before:Array=table[i-1]
			var t:=(year-float(before[0]))/maxf(0.001,float(row[0])-float(before[0]))
			var out:Array=[]
			for k in 4: out.append(lerpf(float(before[k+1]),float(row[k+1]),t))
			return out
	return _row(table[-1])

static func _row(row:Array)->Array:
	return [float(row[1]),float(row[2]),float(row[3]),float(row[4])]

## Might's anchors: the share of the whole people ready to fight.
static func might_anchors(year:float)->Array:
	var a:=anchors(DEFENSE_SHARE,year)
	var out:Array=[]
	for v in a: out.append(float(v)/100.0*ABLE_SHARE*READY)
	return out

## Genius's anchors: practices known.
static func known_anchors(year:float)->Array:
	if year>=600.0:
		var a:=anchors(KNOWN_BENCHMARK,year)
		var out:Array=[]
		for v in a: out.append(float(v)*ENGINE_PACE)
		return out
	var typical:=_line(KNOWN_TYPICAL_EARLY,year)
	if year>500.0:
		# Meet the benchmark's own line at 600.
		typical=lerpf(_line(KNOWN_TYPICAL_EARLY,500.0),float(KNOWN_BENCHMARK[0][2])*ENGINE_PACE,(year-500.0)/100.0)
	var spread:Array=[]
	for k in KNOWN_SPREAD: spread.append(typical*float(k))
	return spread

static func _line(table:Array,year:float)->float:
	if year<=float(table[0][0]): return float(table[0][1])
	for i in range(1,table.size()):
		if year<=float(table[i][0]):
			var t:=(year-float(table[i-1][0]))/maxf(0.001,float(table[i][0])-float(table[i-1][0]))
			return lerpf(float(table[i-1][1]),float(table[i][1]),t)
	return float(table[-1][1])

## The reading of `x` against anchors [low, typical, high, max]: 0 at 0,
## LOW_SCORE at low (straight up to it), then on a log scale through the
## typical, high and max anchors; 1 at max and past it.
static func score(x:float,a:Array)->float:
	if a.size()<4: return 0.0
	var low:=maxf(0.0,float(a[0]))
	var typical:=maxf(low,float(a[1]))
	var high:=maxf(typical*1.0001+0.000001,float(a[2]))
	var most:=maxf(high*1.0001,float(a[3]))
	# Nothing is typical when the age typically has nothing yet (no great
	# work, no fine works at the founding): having nothing reads typical.
	if x<=typical and typical<=0.000001: return TYPICAL_SCORE
	if x>=typical:
		if x>=most: return MAX_SCORE
		var from:=maxf(typical,0.000001)
		if x<=high: return lerpf(TYPICAL_SCORE,HIGH_SCORE,_t(x,from,high))
		return lerpf(HIGH_SCORE,MAX_SCORE,_t(x,high,most))
	if x<=0.0: return 0.0
	if low<=0.000001 or x<=low:
		# Below the low end (or with none named): straight up from nothing.
		var floor_at:=low if low>0.000001 else typical
		var floor_score:=LOW_SCORE if low>0.000001 else TYPICAL_SCORE
		return floor_score*clampf(x/floor_at,0.0,1.0)
	return lerpf(LOW_SCORE,TYPICAL_SCORE,_t(x,low,typical))

## Where x lies between a and b on a log scale, 0..1.
static func _t(x:float,a:float,b:float)->float:
	if b<=a or a<=0.0: return 1.0
	return clampf(log(x/a)/log(b/a),0.0,1.0)

## The same for a share that cannot pass 1, read on its shortfall: 0.9 is to
## 0.97 as 0.7 is to 0.9.
static func score_share(x:float,a:Array)->float:
	var t:=func(v:float)->float: return 1.0/maxf(0.0005,1.0-clampf(v,0.0,0.9995))
	if x<=0.0: return 0.0
	var low:=clampf(float(a[0]),0.0,0.999)
	if x<=low: return LOW_SCORE*x/maxf(0.0001,low)
	return score(t.call(x),[t.call(low),t.call(float(a[1])),t.call(float(a[2])),t.call(float(a[3]))])

## An official's skill (0..1, an ordinary holder 0.47) as a reading: the
## ordinary holder is typical, the best of the age (1.0) the most, nobody
## at all (0.2, standing.gd _office_skill) a quarter.
const ORDINARY_SKILL:=0.47
static func skill_score(skill:float)->float:
	if skill>=ORDINARY_SKILL: return lerpf(TYPICAL_SCORE,MAX_SCORE,clampf((skill-ORDINARY_SKILL)/(1.0-ORDINARY_SKILL),0.0,1.0))
	return lerpf(0.0,TYPICAL_SCORE,clampf(skill/ORDINARY_SKILL,0.0,1.0))

## A count beyond the ordinary (agents abroad, spies caught): nothing is
## typical (0.5); each more lifts it, each less of a lift than the one before.
static func bonus_score(count:float,half:float)->float:
	return TYPICAL_SCORE+(MAX_SCORE-TYPICAL_SCORE)*(1.0-exp(-maxf(0.0,count)/maxf(0.01,half)*0.6931))

## How `x` stands to the typical `typical`, in plain words: "about twice",
## "about a third more", "about the same as", "about half"...
static func against_words(x:float,typical:float)->String:
	if typical<=0.0: return ""
	var r:=x/typical
	if r>=2.75: return "about %d times" % roundi(r)
	if r>=1.75: return "about twice"
	if r>=1.4: return "about half again"
	if r>=1.2: return "about a quarter more than"
	if r>=1.08: return "a little more than"
	if r>0.92: return "about the same as"
	if r>0.8: return "a little less than"
	if r>0.6: return "about two thirds of"
	if r>0.4: return "about half"
	if r>0.25: return "about a third of"
	return "a small part of"

## "about twice a typical people of our age" for a measure and its anchors.
static func compare_words(x:float,a:Array)->String:
	var words:=against_words(x,float(a[1]))
	return ("%s a typical people of our age" % words) if words!="" else ""
