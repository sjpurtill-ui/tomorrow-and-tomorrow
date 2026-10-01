extends GdUnitTestSuite
## Research pacing: teams carry questions. A people's researchers work in equal
## teams, each on one question until it is proven; a field's share of attention
## sets how often its questions get a team; questions of their age come first;
## steps to proof start trial use; cards keep time; a freed team offers the
## player a choice for a season.
const R:=preload("res://scripts/research_600_catalog.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Explainer:=preload("res://scripts/effect_explainer.gd")
const Board:=preload("res://scripts/hud/inquiry_board.gd")
const YEAR:=12

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(424242)
	GameState.initialize_population_model();GameState.ensure_population_total(240)
	GameState.synchronize_population_allocations()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.elapsed_days=float(YEAR*365)
	# Everything dated eight years or more back is known: the questions of the
	# last few years are open, with their foundations in place.
	var known:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		if DiscoverySystem.research_600_earliest_year(entry)<YEAR-4.0:known.append(String(entry.id))
	GameState.known_discoveries.assign(known)
	GameState.active_investigations.clear();GameState.research_targets.clear();GameState.discovery_progress.clear()
	# Nobody leaves learning for sickroom duty mid-test (civilian_care.gd).
	preload("res://scripts/civilian_care.gd").data().staff_share=0.0
	DiscoverySystem.take_research_steps()
	DiscoverySystem.refresh_investigations()

func after_test()->void:
	WorldSimulation.clear()

## A team at work on a question whose age has come (and that changes something).
func _team_of_its_age(with_effects:bool=false)->String:
	for channel:Variant in GameState.active_investigations:
		var question:=DiscoverySystem.discovery_definition(String(GameState.active_investigations[channel]))
		if DiscoverySystem.age_bucket(question)!=0:continue
		if with_effects and (question.get("effects",{}) as Dictionary).is_empty():continue
		return String(channel)
	return ""

func _prove(channel:String)->String:
	var id:=String(GameState.active_investigations[channel])
	GameState.discovery_progress[id]=1.0-0.000000001
	DiscoverySystem.process_day({})
	return id

# --- How many teams ---------------------------------------------------------------

func test_team_count_grows_four_teams_for_every_tenfold_researchers()->void:
	assert_int(R.team_count(0.0)).is_equal(1)
	assert_int(R.team_count(1.0)).is_equal(2)
	assert_int(R.team_count(2.5)).is_equal(4)
	assert_int(R.team_count(25.0)).is_equal(8)
	assert_int(R.team_count(250.0)).is_equal(12)
	assert_int(R.team_count(2500.0)).is_equal(16)
	assert_int(R.team_count(1.0e12)).is_equal(R.TEAMS_MAX)
	# The people field that many teams, each doing an equal part of the whole work.
	var teams:=DiscoverySystem.research_teams()
	assert_int(int(teams.count)).is_equal(R.team_count(float(teams.on_lines)))
	assert_int(GameState.active_investigations.size()).is_between(1,int(teams.count))
	var total:=0.0
	for channel:String in GameState.active_investigations:
		var home:=channel.split("::")
		total+=float(DiscoverySystem.research_capacity_for(home[0],home[1]).team_scale)
	assert_float(total).is_equal_approx(R.team_capacity(float(teams.on_lines)),0.0001)

# --- A team keeps its question ------------------------------------------------------

func test_a_team_keeps_its_question_until_proof_then_takes_one_of_its_age()->void:
	var before:=GameState.active_investigations.duplicate()
	var channel:=_team_of_its_age()
	assert_str(channel).is_not_empty()
	# Days go by: every team on a question of its age keeps it.
	for _day in 3:
		GameState.elapsed_days+=1.0
		DiscoverySystem.refresh_investigations()
	for kept:String in before:
		if DiscoverySystem.age_bucket(DiscoverySystem.discovery_definition(String(before[kept])))==0:assert_str(String(GameState.active_investigations.get(kept,""))).is_equal(String(before[kept]))
	var held:=GameState.active_investigations.duplicate()
	var proven:=_prove(channel)
	assert_bool(proven in GameState.known_discoveries).is_true()
	# The freed team took up another question; it is of its age whenever one is open.
	var taken:Array=[]
	for desk:String in GameState.active_investigations:
		if String(held.get(desk,""))!=String(GameState.active_investigations[desk]):taken.append(String(GameState.active_investigations[desk]))
	assert_int(taken.size()).is_greater_equal(1)
	assert_int(DiscoverySystem.age_bucket(DiscoverySystem.discovery_definition(String(taken[0])))).is_equal(0)
	# The teams it did not free kept their questions.
	for desk:String in held:
		if desk==channel or not GameState.active_investigations.has(desk):continue
		assert_str(String(GameState.active_investigations[desk])).is_equal(String(held[desk]))
	# The proof names its team's line, so the line's turns count from the log.
	assert_str(String(GameState.discovery_log[0].get("team_line",""))).is_equal(channel.split("::")[0])

# --- Age first, and lines take turns ---------------------------------------------------

func test_a_question_of_its_age_outranks_any_ahead_of_it()->void:
	var year:=float(GameState.elapsed_days)/365.0
	var now:={"id":"age_test_now","name":"Now","dynamic":"culture","subcategory":"Social cohesion","earliest_year":0.0,"signals":[]}
	var soon:={"id":"age_test_soon","name":"Soon","dynamic":"culture","subcategory":"Social cohesion","earliest_year":year+3.0,"signals":[]}
	var later:={"id":"age_test_later","name":"Later","dynamic":"culture","subcategory":"Social cohesion","earliest_year":year+30.0,"signals":[]}
	assert_int(DiscoverySystem.age_bucket(now)).is_equal(0)
	assert_int(DiscoverySystem.age_bucket(soon)).is_equal(1)
	assert_int(DiscoverySystem.age_bucket(later)).is_equal(2)
	assert_float(DiscoverySystem._candidate_score(now)).is_greater(DiscoverySystem._candidate_score(soon)+DiscoverySystem.AGE_BUCKET_SCORE*0.8)
	assert_float(DiscoverySystem._candidate_score(soon)).is_greater(DiscoverySystem._candidate_score(later)+DiscoverySystem.AGE_BUCKET_SCORE*0.8)
	# Across lines too: a free team helps another line's question of its age
	# before a line with a far larger share works ahead of its age.
	var lines:={"nutrition":8,"culture":1}
	var held:={}
	var turns:=DiscoverySystem._team_turns(lines,held,int(GameState.elapsed_days))
	var rows:=[{"line":"nutrition","channel":"nutrition::Daily supply","id":"ahead","tier":2,"score":500.0},{"line":"culture","channel":"culture::Social cohesion","id":"of_age","tier":0,"score":-500.0}]
	assert_str(String(DiscoverySystem._pick_team_placement(rows,lines,turns,held,int(GameState.elapsed_days)).id)).is_equal("of_age")

func test_a_team_working_ahead_moves_to_a_question_of_its_age_within_a_month()->void:
	WorldSimulation.create_actor("teams_ahead",515)
	WorldSimulation.scoped("teams_ahead",func()->void:
		var state:=WorldSimulation.state
		var research:=WorldSimulation.discovery
		state.elapsed_days=float(10*365)
		# No one at learning: one team, so it has to choose.
		state.population_allocations.Knowledge=0
		state.active_investigations.clear();state.research_targets.clear()
		state.research_subcategory_allocations={"culture":{"Social cohesion":6},"nutrition":{"Daily supply":1}}
		state.research_allocations={"culture":6,"nutrition":1}
		var ahead:={"id":"teams_far_ahead","name":"Far Ahead","dynamic":"culture","subcategory":"Social cohesion","earliest_year":40.0,"day":0,"requires":[],"signals":[],"observation":""}
		var of_age:={"id":"teams_of_age","name":"Of Its Age","dynamic":"nutrition","subcategory":"Daily supply","earliest_year":0.0,"day":0,"requires":["teams_gate"],"signals":[],"observation":""}
		state.known_discoveries.erase("teams_gate")
		research.catalog_by_channel={"culture::Social cohesion":[ahead],"nutrition::Daily supply":[of_age]}
		research.catalog_by_id[String(ahead.id)]=ahead;research.catalog_by_id[String(of_age.id)]=of_age
		# Only these two questions exist here: no foundation work elsewhere.
		research.technology_catalog.clear()
		research.refresh_investigations()
		assert_int(int(research.research_teams().count)).is_equal(1)
		assert_str(String(state.active_investigations.get("culture::Social cohesion",""))).is_equal("teams_far_ahead")
		state.discovery_progress["teams_far_ahead"]=0.2
		# The question of its age opens: within a month the team takes it up, and
		# the work done ahead of the age stays with the question it leaves.
		state.known_discoveries.append("teams_gate")
		var moved:=-1
		for day in 31:
			state.elapsed_days+=1.0
			research.refresh_investigations()
			if String(state.active_investigations.get("nutrition::Daily supply",""))=="teams_of_age":moved=day;break
		assert_int(moved).is_between(0,30)
		assert_bool(state.active_investigations.has("culture::Social cohesion")).is_false()
		assert_float(float(state.discovery_progress.get("teams_far_ahead",0.0))).is_equal(0.2)
	)

func test_a_line_share_sets_how_often_it_gets_a_team_and_none_waits_past_five_years()->void:
	var lines:={"knowledge":4,"culture":1}
	var rows:=[{"line":"knowledge","channel":"knowledge::Observers","id":"k","tier":0,"score":0.0},{"line":"culture","channel":"culture::Social cohesion","id":"c","tier":0,"score":0.0}]
	GameState.discovery_log.clear()
	var today:=int(GameState.elapsed_days)
	var picks:={"knowledge":0,"culture":0}
	for turn in 50:
		var held:={}
		var turns:=DiscoverySystem._team_turns(lines,held,today)
		var line:=String(DiscoverySystem._pick_team_placement(rows,lines,turns,held,today).line)
		picks[line]=int(picks[line])+1
		# The team proves its question a month later and frees again.
		today+=30
		GameState.discovery_log.push_front({"day":today,"id":"q%d" % turn,"dynamic":line,"team_line":line})
	assert_int(int(picks.knowledge)).is_between(38,42)
	assert_int(int(picks.culture)).is_between(8,12)
	# A followed line that has gone five years without a team takes the next one,
	# whatever the shares say.
	GameState.discovery_log.clear()
	for index in 6:GameState.discovery_log.push_front({"day":today-index*60,"id":"k%d" % index,"dynamic":"knowledge","team_line":"knowledge"})
	GameState.discovery_log.push_back({"day":today-int(6.0*365.0),"id":"c_old","dynamic":"culture","team_line":"culture"})
	var waiting:=DiscoverySystem._team_turns(lines,{},today)
	assert_float(DiscoverySystem._line_wait_years(waiting,"culture",today)).is_greater(R.TEAM_MAX_WAIT_YEARS)
	assert_str(String(DiscoverySystem._pick_team_placement(rows,lines,waiting,{},today).line)).is_equal("culture")
	GameState.discovery_log.clear()

func test_the_quick_pick_matches_a_pick_from_every_row()->void:
	for year:float in [12.0,60.0,150.0,186.0]:
		var day:=int(year*365.0)
		GameState.elapsed_days=float(day)
		var known:Array[String]=[]
		for entry:Dictionary in DiscoverySystem.technology_catalog:
			if DiscoverySystem.research_600_earliest_year(entry)<year-8.0:known.append(String(entry.id))
		GameState.known_discoveries.assign(known)
		GameState.active_investigations.clear()
		for line:String in GameState.research_subcategory_allocations:DiscoverySystem.set_domain_research_priority(line,1+line.length()%3)
		GameState.active_investigations.clear()
		DiscoverySystem.begin_research_scan()
		var lines:=DiscoverySystem._team_lines()
		var held:={}
		var turns:=DiscoverySystem._team_turns(lines,held,day)
		var busy:={}
		for pick in 8:
			var every:Array=[]
			var lending:=DiscoverySystem._lending_lines()
			for line:String in lines:
				for tier in DiscoverySystem.TEAM_TIER_LAST+1:every.append_array(DiscoverySystem._line_placements(line,day,busy,tier,lending))
			var reference:=DiscoverySystem._pick_team_placement(every,lines,turns,held,day)
			var quick:=DiscoverySystem._next_team_placement(lines,turns,held,day,busy)
			assert_str(String(quick.get("id",""))).is_equal(String(reference.get("id","")))
			assert_str(String(quick.get("channel",""))).is_equal(String(reference.get("channel","")))
			if quick.is_empty():break
			GameState.active_investigations[String(quick.channel)]=String(quick.id)
			busy[String(quick.id)]=true
			DiscoverySystem._count_turn(held,turns,String(quick.line),1)
		DiscoverySystem.end_research_scan()

# --- Far work comes band by band --------------------------------------------------------

func test_far_work_is_taken_band_by_band_before_a_line_s_long_leap()->void:
	var year:=float(GameState.elapsed_days)/365.0
	# Bands of years ahead: within 5, 10, 20, 35, 60, then beyond.
	var tiers:={0.0:0,3.0:1,8.0:2,10.0:2,15.0:3,30.0:4,50.0:5,61.0:6,79.5:6}
	DiscoverySystem.research_open_year({"id":"band_test_sync","earliest_year":0.0})
	for ahead:float in tiers:
		var question:={"id":"band_test_%d" % roundi(ahead*10.0),"dynamic":"culture","subcategory":"Social cohesion","earliest_year":0.0}
		DiscoverySystem._open_year_cache[String(question.id)]=year+ahead
		assert_int(DiscoverySystem.team_tier(question)).is_equal(int(tiers[ahead]))
		DiscoverySystem._open_year_cache.erase(String(question.id))
	assert_int(DiscoverySystem.TEAM_TIER_LAST).is_equal(2+DiscoverySystem.FAR_BANDS.size())
	# Nutrition has the turn by a wide margin (eight times culture's share, no
	# turns yet), but its only open work is a 60-year leap; culture offers work 8
	# years ahead. The free team takes the cheaper lead in culture.
	var lines:={"nutrition":8,"culture":1}
	var today:=int(GameState.elapsed_days)
	GameState.discovery_log.clear()
	for index in 3:GameState.discovery_log.push_front({"day":today-index*90,"id":"n%d" % index,"dynamic":"nutrition","team_line":"nutrition"})
	GameState.discovery_log.push_front({"day":today-60,"id":"c0","dynamic":"culture","team_line":"culture"})
	var held:={}
	var turns:=DiscoverySystem._team_turns(lines,held,today)
	var leap:={"line":"nutrition","channel":"nutrition::Daily supply","id":"leap","tier":5,"score":400.0}
	var near:={"line":"culture","channel":"culture::Social cohesion","id":"near","tier":2,"score":-400.0}
	assert_str(String(DiscoverySystem._pick_team_placement([leap,near],lines,turns,held,today).id)).is_equal("near")
	# In the same band the line's turn decides.
	var level:={"line":"nutrition","channel":"nutrition::Daily supply","id":"level","tier":2,"score":-900.0}
	assert_str(String(DiscoverySystem._pick_team_placement([level,near],lines,turns,held,today).id)).is_equal("level")
	GameState.discovery_log.clear()

func test_a_line_waiting_five_years_still_gets_its_turn_unless_it_would_leap_bands_ahead()->void:
	var lines:={"nutrition":8,"culture":1}
	var today:=int(GameState.elapsed_days)
	GameState.discovery_log.clear()
	for index in 3:GameState.discovery_log.push_front({"day":today-index*90,"id":"n%d" % index,"dynamic":"nutrition","team_line":"nutrition"})
	# Culture has held no team and proved nothing for six years: it is waiting.
	GameState.discovery_log.push_back({"day":today-int(6.0*365.0),"id":"c_old","dynamic":"culture","team_line":"culture"})
	var turns:=DiscoverySystem._team_turns(lines,{},today)
	assert_float(DiscoverySystem._line_wait_years(turns,"culture",today)).is_greater(R.TEAM_MAX_WAIT_YEARS)
	var nutrition:={"line":"nutrition","channel":"nutrition::Daily supply","id":"nutrition_near","tier":2,"score":300.0}
	# Its next question one or two bands further than nutrition's: culture takes its turn.
	var one_band:={"line":"culture","channel":"culture::Social cohesion","id":"culture_one_band","tier":3,"score":-300.0}
	assert_str(String(DiscoverySystem._pick_team_placement([nutrition,one_band],lines,turns,{},today).id)).is_equal("culture_one_band")
	var two_bands:={"line":"culture","channel":"culture::Social cohesion","id":"culture_two_bands","tier":4,"score":-300.0}
	assert_str(String(DiscoverySystem._pick_team_placement([nutrition,two_bands],lines,turns,{},today).id)).is_equal("culture_two_bands")
	# A 40-year leap stands three bands further: the cheaper work goes first, and
	# culture's turn comes as its questions draw nearer their age.
	var leap:={"line":"culture","channel":"culture::Social cohesion","id":"culture_leap","tier":5,"score":300.0}
	assert_str(String(DiscoverySystem._pick_team_placement([nutrition,leap],lines,turns,{},today).id)).is_equal("nutrition_near")
	# Against work 10 to 20 years ahead, the leap is only two bands further: its turn.
	var farther:={"line":"nutrition","channel":"nutrition::Daily supply","id":"nutrition_farther","tier":3,"score":300.0}
	assert_str(String(DiscoverySystem._pick_team_placement([farther,leap],lines,turns,{},today).id)).is_equal("culture_leap")
	# Questions of their age always come first, waiting or not.
	var of_age:={"line":"nutrition","channel":"nutrition::Daily supply","id":"nutrition_of_age","tier":0,"score":-900.0}
	assert_str(String(DiscoverySystem._pick_team_placement([of_age,one_band],lines,turns,{},today).id)).is_equal("nutrition_of_age")
	GameState.discovery_log.clear()

func test_a_team_on_a_long_leap_moves_two_bands_nearer_within_a_month()->void:
	WorldSimulation.create_actor("teams_leap",516)
	WorldSimulation.scoped("teams_leap",func()->void:
		var state:=WorldSimulation.state
		var research:=WorldSimulation.discovery
		state.elapsed_days=float(10*365)
		# No one at learning: one team, so it has to choose.
		state.population_allocations.Knowledge=0
		state.active_investigations.clear();state.research_targets.clear();state.discovery_log.clear()
		state.research_subcategory_allocations={"culture":{"Social cohesion":6},"nutrition":{"Daily supply":1}}
		state.research_allocations={"culture":6,"nutrition":1}
		# A 60-to-70-year leap in culture, and work 5 to 9 years ahead in nutrition
		# that opens once its foundation is known.
		var leap:={"id":"teams_long_leap","name":"Long Leap","dynamic":"culture","subcategory":"Social cohesion","earliest_year":80.0,"day":0,"requires":[],"signals":[],"observation":""}
		var near:={"id":"teams_near_lead","name":"Near Lead","dynamic":"nutrition","subcategory":"Daily supply","earliest_year":17.0,"day":0,"requires":["teams_leap_gate"],"signals":[],"observation":""}
		state.known_discoveries.erase("teams_leap_gate")
		research.catalog_by_channel={"culture::Social cohesion":[leap],"nutrition::Daily supply":[near]}
		research.catalog_by_id[String(leap.id)]=leap;research.catalog_by_id[String(near.id)]=near
		research.technology_catalog.clear()
		research.refresh_investigations()
		assert_int(int(research.research_teams().count)).is_equal(1)
		assert_str(String(state.active_investigations.get("culture::Social cohesion",""))).is_equal("teams_long_leap")
		assert_int(research.team_tier(leap)).is_equal(research.TEAM_TIER_LAST)
		assert_int(research.team_tier(near)).is_equal(2)
		state.discovery_progress["teams_long_leap"]=0.2
		# The nearer work opens: within a month the team takes it up, and the
		# work done on the long leap stays with it.
		state.known_discoveries.append("teams_leap_gate")
		var moved:=-1
		for day in 31:
			state.elapsed_days+=1.0
			research.refresh_investigations()
			if String(state.active_investigations.get("nutrition::Daily supply",""))=="teams_near_lead":moved=day;break
		assert_int(moved).is_between(0,30)
		assert_bool(state.active_investigations.has("culture::Social cohesion")).is_false()
		assert_float(float(state.discovery_progress.get("teams_long_leap",0.0))).is_equal(0.2)
		# A lead one band nearer is not worth a move: the team stays.
		state.active_investigations.clear()
		state.active_investigations["culture::Social cohesion"]="teams_long_leap"
		state.research_subcategory_allocations={"culture":{"Social cohesion":6},"nutrition":{"Daily supply":1}}
		var far:={"id":"teams_far_lead","name":"Far Lead","dynamic":"nutrition","subcategory":"Daily supply","earliest_year":64.0,"day":0,"requires":[],"signals":[],"observation":""}
		research.catalog_by_channel["nutrition::Daily supply"]=[far]
		research.catalog_by_id[String(far.id)]=far
		assert_int(research.team_tier(far)).is_equal(5)
		for day in 31:
			state.elapsed_days+=1.0
			research.refresh_investigations()
		assert_str(String(state.active_investigations.get("culture::Social cohesion",""))).is_equal("teams_long_leap")
	)

func test_a_long_leap_moves_to_cheap_work_though_another_line_waits_with_far_work()->void:
	# The player's year-186 save: knowledge had waited five years, so a free team
	# would take its 26-year question; that question was more work than the far
	# teams' own, and they kept 30-to-60-year leaps beside open work 9 years ahead.
	WorldSimulation.create_actor("teams_waiting_far",517)
	WorldSimulation.scoped("teams_waiting_far",func()->void:
		var state:=WorldSimulation.state
		var research:=WorldSimulation.discovery
		state.elapsed_days=float(10*365)
		state.population_allocations.Knowledge=0
		state.active_investigations.clear();state.research_targets.clear()
		state.research_subcategory_allocations={"culture":{"Social cohesion":6},"nutrition":{"Daily supply":1},"knowledge":{"Observers":1}}
		state.research_allocations={"culture":6,"nutrition":1,"knowledge":1}
		# Nutrition proved a question last year; knowledge has proved nothing.
		state.discovery_log=[{"day":int(state.elapsed_days)-365,"id":"teams_nutrition_last","dynamic":"nutrition","team_line":"nutrition"}]
		var leap:={"id":"teams_waiting_leap","name":"Long Leap","dynamic":"culture","subcategory":"Social cohesion","earliest_year":80.0,"day":0,"requires":[],"signals":[],"observation":""}
		var near:={"id":"teams_waiting_near","name":"Near Lead","dynamic":"nutrition","subcategory":"Daily supply","earliest_year":17.0,"day":0,"requires":[],"signals":[],"observation":""}
		var heavy:={"id":"teams_waiting_heavy","name":"Heavy Far Work","dynamic":"knowledge","subcategory":"Observers","earliest_year":40.0,"day":0,"requires":[],"signals":[],"observation":"","chance":0.00005}
		research.catalog_by_channel={"culture::Social cohesion":[leap],"nutrition::Daily supply":[near],"knowledge::Observers":[heavy]}
		for question:Dictionary in [leap,near,heavy]:research.catalog_by_id[String(question.id)]=question
		research.technology_catalog.clear()
		assert_int(research.team_tier(leap)).is_equal(research.TEAM_TIER_LAST)
		assert_int(research.team_tier(near)).is_equal(2)
		assert_int(research.team_tier(heavy)).is_equal(4)
		state.active_investigations["culture::Social cohesion"]="teams_waiting_leap"
		state.discovery_progress["teams_waiting_leap"]=0.2
		assert_int(int(research.research_teams().count)).is_equal(1)
		# A free team would take knowledge's far work (its turn has come)...
		var free:=research._next_team_placement(research._team_lines(),research._team_turns(research._team_lines(),{},int(state.elapsed_days)),{},int(state.elapsed_days),{},"culture::Social cohesion")
		assert_str(String(free.get("id",""))).is_equal("teams_waiting_heavy")
		# ...but the team on the long leap moves to the cheap work instead.
		var moved:=-1
		for day in 31:
			state.elapsed_days+=1.0
			research.refresh_investigations()
			if String(state.active_investigations.get("nutrition::Daily supply",""))=="teams_waiting_near":moved=day;break
		assert_int(moved).is_between(0,30)
		assert_bool(state.active_investigations.has("culture::Social cohesion")).is_false()
		assert_float(float(state.discovery_progress.get("teams_waiting_leap",0.0))).is_equal(0.2)
	)

# --- Foundation work keeps near its age ------------------------------------------------

func test_foundation_work_goes_no_more_than_five_years_ahead()->void:
	for year:float in [40.0,150.0,320.0]:
		var day:=int(year*365.0)
		GameState.elapsed_days=float(day)
		var known:Array[String]=[]
		for entry:Dictionary in DiscoverySystem.technology_catalog:
			if DiscoverySystem.research_600_earliest_year(entry)<year-30.0:known.append(String(entry.id))
		GameState.known_discoveries.assign(known)
		DiscoverySystem._research_600_foundation_cache.clear()
		for line:String in DiscoverySystem.society_model.DYNAMICS:
			for id:String in DiscoverySystem._research_600_foundation_ids(line,day):
				assert_float(DiscoverySystem.research_years_ahead(DiscoverySystem.discovery_definition(id),year)).is_less(DiscoverySystem.NEAR_AGE_YEARS)

# --- Steps to proof and trial use -----------------------------------------------------------

func test_steps_start_trial_use_and_a_proof_starts_in_fifteen_households_of_a_hundred()->void:
	assert_int(R.stage(0.2)).is_equal(0)
	assert_float(R.trial_share(0.2)).is_equal(0.0)
	assert_int(R.stage(0.34)).is_equal(1)
	assert_float(R.trial_share(0.34)).is_equal_approx(0.05,0.0001)
	assert_int(R.stage(0.7)).is_equal(2)
	assert_float(R.trial_share(0.7)).is_equal_approx(0.15,0.0001)
	var channel:=_team_of_its_age(true)
	assert_str(channel).is_not_empty()
	var id:=String(GameState.active_investigations[channel])
	var effects:Dictionary=DiscoverySystem.discovery_definition(id).get("effects",{})
	# A day's work carries it past a third of the evidence: its first cases.
	GameState.discovery_progress[id]=float(R.STAGES[0])-0.001
	DiscoverySystem.process_day({})
	var steps:=DiscoverySystem.take_research_steps()
	var reached:={}
	for step:Dictionary in steps:
		if String(step.id)==id:reached=step
	assert_dict(reached).is_not_empty()
	assert_int(int(reached.stage)).is_equal(1)
	assert_float(float(reached.share)).is_equal_approx(0.05,0.0001)
	# Tried in 5 households of 100 before proof: its effects count at that share,
	# in the engine's totals and in what the research pages say.
	Explainer.invalidate()
	var raw:=Explainer.raw_totals()
	var key:=String(effects.keys()[0])
	var scale:=Explainer.focus_scale(String(DiscoverySystem.discovery_definition(id).get("dynamic","")))
	var counted:=float(((raw.get(key,{}) as Dictionary).get("by",{}) as Dictionary).get(id,0.0))
	assert_float(counted).is_equal_approx(DiscoverySystem.society_model.scaled_effect(key,float(effects[key]),scale)*0.05,0.000001)
	assert_float(Explainer.practice_level(id)).is_equal_approx(0.05,0.0001)
	# Recipes, works and gates still wait for proof.
	assert_bool(id in GameState.known_discoveries).is_false()
	# Proven, the practice starts in 15 households of 100.
	_prove(channel)
	assert_bool(id in GameState.known_discoveries).is_true()
	assert_float(float(GameState.discovery_adoption.get(id,0.0))).is_greater_equal(R.PROOF_ADOPTION)

func test_steps_are_lines_in_the_season_tally_never_pop_ups()->void:
	var Chronicle:=preload("res://scripts/chronicle.gd")
	GameState.chronicle={}
	Chronicle.pending_cards.clear()
	var day:=int(GameState.elapsed_days)
	Chronicle._research_step({"day":day,"id":"tally_test_clay","name":"Clay Tempering","stage":1,"share":0.05,"dynamic":"production"})
	Chronicle._research_step({"day":day,"id":"tally_test_yoke","name":"Ox Yokes","stage":1,"share":0.05,"dynamic":"logistics"})
	# The same question's next step this season replaces its first.
	Chronicle._research_step({"day":day+3,"id":"tally_test_yoke","name":"Ox Yokes","stage":2,"share":0.15,"dynamic":"logistics"})
	var told:=Chronicle._flush_learned(Chronicle.data(),day+92)
	assert_dict(told).is_not_empty()
	assert_str(String(told.text)).contains("First cases held for clay tempering: 5 in 100 households try it.")
	assert_str(String(told.text)).contains("Ox yokes held up when repeated: 15 in 100 households use it.")
	assert_str(String(told.text)).not_contains("First cases held for ox yokes")
	assert_str(String(told.tier)).is_equal("whisper")
	assert_array(Chronicle.pending_cards).is_empty()
	GameState.chronicle={}

# --- Cards that keep time -------------------------------------------------------------------

func test_cards_keep_time_and_a_thin_team_is_named_only_below_a_third_of_normal()->void:
	var records:=DiscoverySystem.active_investigation_records()
	assert_int(records.size()).is_greater(0)
	for record:Dictionary in records:
		assert_int(int(record.estimated_days)).is_greater(0)
		assert_str(Words.clock(float(record.estimated_days))).starts_with("about ")
		assert_str(Words.clock(float(record.estimated_days))).ends_with(" to proof")
		assert_int(int(record.stage)).is_between(0,2)
		assert_float(float(record.research_workforce)).is_greater(0.0)
	var question:=DiscoverySystem.discovery_definition(String(GameState.active_investigations[_team_of_its_age()]))
	var normal:=R.normal_team(float(GameState.population_exact))
	assert_float(normal).is_greater(0.0)
	var thin:=DiscoverySystem._investigation_bottleneck(question,1,1.0,1.0,0.5,{"team_people":normal*0.3,"support_multiplier":1.0})
	assert_str(thin).starts_with("RESEARCH WORKFORCE")
	assert_str(Visuals.phase({"assignment":{"bottleneck":thin,"active":true,"capacity":{"researchers":normal*0.3}}})).is_equal("Thin team")
	var enough:=DiscoverySystem._investigation_bottleneck(question,1,1.0,1.0,0.5,{"team_people":normal*0.4,"support_multiplier":1.0})
	assert_str(enough).starts_with("REPLICATION")
	assert_str(enough).contains("5 in 100 households")
	# Ahead of its age is told first, with its price, so a thin team never hides it.
	var ahead:={"id":"card_test_ahead","name":"Far ahead","dynamic":"culture","subcategory":"Social cohesion","earliest_year":float(GameState.elapsed_days)/365.0+10.0,"signals":[]}
	var told:=DiscoverySystem._investigation_bottleneck(ahead,1,1.0,1.0,0.1,{"team_people":0.0,"support_multiplier":1.0})
	assert_str(told).starts_with("AHEAD OF ITS AGE")
	assert_str(told).contains("three times the usual work")
	assert_str(Visuals.plain_bottleneck(told)).contains("three times the usual work")
	assert_str(Words.lead_price(25.0,6.0)).is_equal("25 years ahead: six times the work")
	# A board whose teams work far ahead states the price of that lead.
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1120,1600);add_child(viewport)
	var board=Board.new();viewport.add_child(board)
	board.setup({"fields":[],"investigations":[{"id":"lead_test","name":"Far Ahead","dynamic":"culture","progress":0.2,"research_workforce":3.0,"years_ahead":25.0,"work_factor":6.0,"estimated_days":3000,"bottleneck":"AHEAD OF ITS AGE — 25 years early: about six times the usual work"}],
		"on_tree":func()->void:pass,"on_work":func()->void:pass,"on_domain":func(_d:String)->void:pass})
	var price:Label=board.find_child("LeadPrice",true,false)
	assert_object(price).is_not_null()
	assert_str(price.text).is_equal("Our learning runs ahead of its age. 25 years ahead: six times the work.")
	var holdup:Label=board.find_child("Holdup",true,false)
	assert_str(holdup.text).is_equal("Ahead of its age")

# --- A freed team's choice --------------------------------------------------------------------

func test_a_freed_team_offers_a_choice_for_a_season_then_keeps_its_question()->void:
	var proven:=_prove(_team_of_its_age())
	var choices:=DiscoverySystem.team_choices()
	assert_int(choices.size()).is_greater(0)
	var choice:Dictionary=choices[0]
	assert_str(String(choice.proved_id)).is_equal(proven)
	var options:Array=choice.options
	assert_int(options.size()).is_between(2,3)
	assert_str(String((options[0] as Dictionary).id)).is_equal(String(choice.taken))
	assert_str(String(GameState.active_investigations[String(choice.channel)])).is_equal(String(choice.taken))
	for option:Dictionary in options:
		assert_int(int(option.days)).is_greater(0)
		assert_int(int(option.opens)).is_greater_equal(0)
		assert_bool(option.has("effects")).is_true()
	# Drawn inline on the research board, never as a pop-up.
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1120,2000);add_child(viewport)
	var board=Board.new();viewport.add_child(board)
	board.setup({"fields":[],"investigations":DiscoverySystem.active_investigation_records(),"choices":choices,"on_choose":func(_k:String,_i:String)->void:pass,"on_tree":func()->void:pass,"on_work":func()->void:pass,"on_domain":func(_d:String)->void:pass})
	var card:Node=board.find_child("Choice_"+String(choice.key).validate_node_name(),true,false)
	assert_object(card).is_not_null()
	assert_int(card.find_children("Option_*","",true,false).size()).is_equal(options.size())
	assert_int(card.find_children("Choose","Button",true,false).size()).is_equal(options.size())
	# Choosing another question sends the team there until it is proven.
	var other:Dictionary=options[1]
	var progress_before:=float(GameState.discovery_progress.get(String(choice.taken),0.0))
	assert_bool(bool(DiscoverySystem.choose_team_question(String(choice.key),String(other.id)).ok)).is_true()
	assert_str(String(GameState.active_investigations.get(String(other.channel),""))).is_equal(String(other.id))
	assert_str(String(GameState.research_targets.get(String(other.channel),""))).is_equal(String(other.id))
	assert_float(float(GameState.discovery_progress.get(String(choice.taken),0.0))).is_equal(progress_before)
	for left:Dictionary in DiscoverySystem.team_choices():assert_str(String(left.key)).is_not_equal(String(choice.key))
	# Left alone for a season, a choice lapses and the team keeps what it took.
	var second:=_prove(_team_of_its_age())
	var pending:Dictionary={}
	for open:Dictionary in DiscoverySystem.team_choices():
		if String(open.proved_id)==second:pending=open
	assert_dict(pending).is_not_empty()
	GameState.elapsed_days+=float(DiscoverySystem.CHOICE_DAYS+1)
	for open:Dictionary in DiscoverySystem.team_choices():assert_str(String(open.key)).is_not_equal(String(pending.key))
	assert_str(String(GameState.active_investigations.get(String(pending.channel),""))).is_equal(String(pending.taken))

# --- Older saves -------------------------------------------------------------------------------

func test_an_older_save_with_a_question_on_every_line_settles_into_teams()->void:
	# Before teams every staffed sub-line held a question; such a save loads with
	# more questions under way than teams. The furthest ahead pause first and keep
	# their evidence; a proof logged before teams counts for its field's turns.
	for line:String in GameState.research_subcategory_allocations:DiscoverySystem.set_domain_research_priority(line,4)
	var day:=int(GameState.elapsed_days)
	var placed:=0
	for channel_variant in DiscoverySystem.catalog_by_channel:
		var channel:=String(channel_variant)
		if not GameState.research_subcategory_allocations.has(channel.split("::")[0]):continue
		for entry:Dictionary in DiscoverySystem.catalog_by_channel[channel]:
			if String(entry.id) in GameState.known_discoveries or String(entry.id) in GameState.active_investigations.values():continue
			if not DiscoverySystem._discovery_is_eligible(entry,day):continue
			GameState.active_investigations[channel]=String(entry.id)
			GameState.discovery_progress[String(entry.id)]=0.3
			placed+=1
			break
	var count:=int(DiscoverySystem.research_teams().count)
	assert_int(placed).is_greater(count)
	var before:=GameState.discovery_progress.duplicate()
	GameState.discovery_log.push_front({"day":day-30,"id":"older_save_proof","dynamic":"culture"})
	DiscoverySystem.refresh_investigations()
	assert_int(GameState.active_investigations.size()).is_less_equal(count)
	for id:String in before:assert_float(float(GameState.discovery_progress.get(id,0.0))).is_equal(float(before[id]))
	var turns:=DiscoverySystem._team_turns(DiscoverySystem._team_lines(),{},day)
	assert_float(float(turns.turns.culture)).is_greater_equal(1.0)
	GameState.discovery_log.clear()

# --- A founding band's first season -----------------------------------------------------------

func test_a_founding_band_sees_steps_within_a_year_and_proofs_soon_after()->void:
	GameState.reset_for_new_world(31337)
	GameState.initialize_population_model();GameState.ensure_population_total(120)
	GameState.synchronize_population_allocations()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	preload("res://scripts/civilian_care.gd").data().staff_share=0.0
	DiscoverySystem.take_research_steps()
	var first_step:=-1
	var first_proof:=-1
	var teams:=0
	var started:=Time.get_ticks_usec()
	var days:=0
	for day in 1100:
		GameState.elapsed_days=float(day)
		var proofs:=DiscoverySystem.process_day({})
		days=day+1
		teams=maxi(teams,GameState.active_investigations.size())
		if first_proof<0 and not proofs.is_empty():first_proof=day
		if first_step<0 and not DiscoverySystem.take_research_steps().is_empty():first_step=day
		if first_proof>=0 and first_step>=0:break
	print("RESEARCH_PACING_SMOKE first_step=%d first_proof=%d teams=%d us_per_day=%d" % [first_step,first_proof,teams,(Time.get_ticks_usec()-started)/maxi(1,days)])
	# A handful of questions at once, each moving: a step within the first year,
	# a proof within about two (the old thin spread took three to four).
	assert_int(teams).is_between(2,6)
	assert_int(first_step).is_between(0,365)
	assert_int(first_proof).is_between(0,800)

