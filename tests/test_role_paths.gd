extends GdUnitTestSuite
## PEOPLE FIRST, F (docs/PEOPLE_FIRST.md): the words for the work, what each
## work does shown on the People view, and the different paths peoples take.
##   - "making" (was "making tools") and "keeping and caring" (was "keeping
##     the stores") wherever the player reads them; the court still reads the
##     old words.
##   - every role's row says what it does now and what ten more would do
##     (role_effects.gd), with the engine's numbers.
##   - each ruler takes a path by temper and situation (work_paths.gd): growth,
##     making and trade, war, learning (the scholarly only) or building, else a
##     balanced split; the leaders' split leans toward it; no path holds more
##     than about 40 in 100 of a world's rulers, and learning is not the
##     default; our own leaders start balanced.

const Manual:=preload("res://scripts/manual_work.gd")
const HomeOrders:=preload("res://scripts/home_orders.gd")
const Answers:=preload("res://scripts/court_answers.gd")
const Effects:=preload("res://scripts/role_effects.gd")
const Paths:=preload("res://scripts/work_paths.gd")
const Research600:=preload("res://scripts/research_600_catalog.gd")
const Personality:=preload("res://scripts/leader_personality.gd")
const People:=preload("res://scripts/hud/people_model.gd")
const Overview:=preload("res://scripts/hud/content/dock_content_overview.gd")
const Screen:=preload("res://scripts/hud/people_screen.gd")
const Save:=preload("res://scripts/save_system.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const DEV_WORDS:=["%","allocation","effective_workers","multiplier","coefficient","null","NAN","inf"]
const ROLES:=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]

class FakeHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Node=null
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_provider:Object,_sub:int=0)->void:pass

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()

func after()->void:
	T.set_color_mode("light")
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing:node.set_process(bool(_processing[node]))

## A settled people of `people` at their first home, the day's count made.
func _world(people:int=120)->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(716203);GameState.civic_api_enabled=false
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world();PeopleDirection.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(people)
	GameState.settlement_name="Keansburg"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(14.0,0.0,-9.0)
	GameState.elapsed_days=6*365+40
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":1800.0,"Preserved food":200.0}
	GameState.resource_stockpiles={"Food":2000.0,"Timber":500.0,"Fiber Plants":500.0}
	CivilizationSystem.register_player_origin(Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z))
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	GovernmentPeopleSystem.last_processed_month=(int(GameState.elapsed_days)+60)/30
	PeopleDirection.ensure()
	ResourceSystem.initialize()
	GameState.simulation_metrics.merge({"labor_efficiency":0.72,"security":0.4,"food_days":40.0,"food_intake_ratio":1.0,"food_production":100.0,"food_consumption":100.0,"food_eaten":100.0,
		"food_spoilage":0.0,"food_net":0.0,"food_total_stock":2000.0,"food_projected_days":9999.0,"food_labor_share":0.5,"food_forecast_90":{"first_shortage_day":-1},"housing_ratio":1.0,
		"food_harvest":{"Fresh plants":60.0,"Fresh meat":30.0,"Fish":10.0,"Dry staples":0.0}},true)
	GameState.water_metrics={"required_today":100.0,"total_required_today":100.0,"collected_today":100.0,"household_collected_today":40.0,"organized_collection_capacity":60.0,
		"conveyed_today":0.0,"rain_collected_today":0.0,"cistern_capacity":0.0,"intake_ratio":1.0,"stored":50.0,"days":3.0,"source_accessible":true,"source_distance_km":0.8}
	_delegate()

func _delegate()->void:
	GovernmentPeopleSystem.initializing=true
	GovernmentPeopleSystem._delegate_settlements(int(GameState.elapsed_days))
	GovernmentPeopleSystem.initializing=false

func _assert_plain(text:String,where:String)->void:
	for word:String in DEV_WORDS:
		assert_bool(text.contains(word)).override_failure_message("'%s' in %s: %s" % [word,where,text]).is_false()

static func _temper(open:float,discipline:float,empathy:float,assertive:float,risk:float)->Dictionary:
	return {"openness":open,"discipline":discipline,"empathy":empathy,"assertiveness":assertive,"risk_tolerance":risk}

const CALM:={"threat":0.0,"at_war":false,"met":0,"roofless":false,"sick":false}

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

func test_making_and_keeping_and_caring_are_the_words()->void:
	assert_str(Manual.task_words("Crafting")).is_equal("making")
	assert_str(Manual.task_words("Administration")).is_equal("keeping and caring")
	for role:String in Manual.TASKS:
		for words:String in Manual.TASKS[role]:
			assert_str(words).not_contains("making tools").not_contains("keeping the stores")
	assert_str(Manual.split_words({"Crafting":3,"Administration":2})).is_equal("3 making, 2 keeping and caring")
	assert_str(Manual._doing("Crafting",1)).is_equal("make things")
	assert_str(Manual._doing("Administration",1)).is_equal("keep and care")
	# The court names them as the People view does.
	assert_str(String(Answers.WORK_WORDS.crafting)).is_equal("making goods")
	assert_str(String(Answers.WORK_WORDS.administration)).is_equal("keeping and caring")
	for pair:Array in People.TASKS:
		assert_str(String(pair[1])).not_contains("making tools").not_contains("keeping the stores")
	# Learning is the learners' work, never "keepers" (the court reads bare
	# "keepers" as keeping and caring).
	for words:String in Manual.TASKS.Knowledge:assert_str(words).not_contains("keep")
	assert_str(Manual._doing("Knowledge",1)).is_equal("learn")

func test_the_court_reads_the_new_words_and_the_old()->void:
	var cases:={
		"Put 5 more on keeping and caring":"Administration",
		"put 5 more on keeping the stores":"Administration",
		"Put 4 more on the carers":"Administration",
		"put 3 more on making":"Crafting",
		"put 3 more on making tools":"Crafting",
		"Put 3 more on making things":"Crafting",
		"put 3 more on keeping watch":"Defense",
		"Put 2 more on the watch":"Defense",
		"put 2 more on the lore keepers":"Knowledge",
		"put 2 more on the learners":"Knowledge",
		"put 2 more on the keepers":"Administration",
	}
	for said:String in cases:
		var reading:=HomeOrders.work_reading(said)
		assert_str(String(reading.get("role",""))).override_failure_message("'%s' read as %s" % [said,str(reading)]).is_equal(String(cases[said]))
	var moved:=HomeOrders.work_reading("Move 2 from keeping and caring to building")
	assert_str(String(moved.get("other",""))).is_equal("Administration")
	assert_str(String(moved.get("role",""))).is_equal("Construction")
	# The headman's buttons offer it.
	var found:=false
	for task:Array in preload("res://scripts/court_office_orders.gd").TASKS:found=found or String(task[0])=="keeping and caring"
	assert_bool(found).is_true()

# --------------------------------------------------------------------------
# What each work does
# --------------------------------------------------------------------------

func test_every_role_says_what_it_does_now_and_what_ten_more_would_do()->void:
	_world()
	for role:String in ROLES:
		var effect:=Effects.of(role)
		for field:String in ["now","plus_ten"]:
			assert_str(String(effect.get(field,""))).override_failure_message("%s has no %s" % [role,field]).is_not_empty()
			_assert_plain(String(effect.get(field,"")),"%s %s" % [role,field])
		assert_str(String(effect.plus_ten)).starts_with("Ten more")
		print("[role_paths] %s: %s %s" % [Manual.task_words(role),String(effect.now),String(effect.plus_ten)])
	# Learning is told in learners, never keepers, on the row and in its panel.
	var learning:=Effects.knowledge()
	assert_str(String(learning.now)+String(learning.plus_ten)).contains("learners").not_contains("keepers")
	var panel:=preload("res://scripts/task_impact.gd").knowledge()
	var told:=String(panel.lead)
	for line:Dictionary in panel.lines:told+=" "+String(line.label)+" "+String(line.value)+" "+String(line.words)
	assert_str(told.to_lower()).not_contains("keepers").contains("learners")
	# The People view's rows carry them.
	var tasks:=People.labor()
	assert_int(tasks.size()).is_equal(ROLES.size())
	for task:Dictionary in tasks:
		assert_str(String((task.get("effect",{}) as Dictionary).get("now",""))).override_failure_message("%s row has no effect" % String(task.id)).is_not_empty()

func test_the_people_view_draws_each_effect_under_its_row()->void:
	_world()
	var hud:=FakeHud.new();add_child(hud);auto_free(hud)
	var provider=Overview.new(null,hud)
	var block:Dictionary=(provider.tab(0).blocks as Array)[0]
	var screen:VBoxContainer=auto_free(Screen.new())
	screen.theme=T.control_theme();screen.size=Vector2(940,1400)
	add_child(screen)
	screen.setup(block)
	var labor:=screen.find_child("Labor",true,false)
	for role:String in ROLES:
		var box:=labor.find_child("TaskBox_"+role,true,false)
		assert_object(box).override_failure_message("no row for "+role).is_not_null()
		var line:=box.find_child("Effect",true,false) as Label
		assert_object(line).override_failure_message("no effect under "+role).is_not_null()
		var more:=box.find_child("TenMore",true,false) as Label
		assert_object(more).override_failure_message("no ten more under "+role).is_not_null()
		assert_str(more.text).starts_with("Ten more")
		# Short, as every label on the People view.
		for label:Label in [line,more]:
			assert_int(label.text.split(" ",false).size()).override_failure_message("'%s'" % label.text).is_less_equal(12)
	assert_str((labor.find_child("TaskBox_Crafting",true,false).find_child("Task",true,false) as Button).text.to_lower()).contains("making")
	assert_str((labor.find_child("TaskBox_Administration",true,false).find_child("Task",true,false) as Button).text.to_lower()).contains("keeping and caring")
	# Our leaders' path is said with their lines.
	var said:=PackedStringArray()
	for line_variant in (block.labor.who as Array):said.append(String((line_variant as Dictionary).get("text","")))
	assert_str(" ".join(said)).contains("Our leaders keep the work balanced")

## "Ten more" is always the gain over now, never a new total.
func test_ten_more_is_always_the_gain()->void:
	_world()
	var pop:=float(GameState.population_exact)
	# Keeping and caring: coverage = keepers ÷ 3.5 in 100 of the people, up to 1.25.
	var keepers:=float(GameState.effective_workers("Administration"))
	var raw:=float(GameState.population_allocations.get("Administration",0))
	var ten:=10.0*(keepers/raw if raw>0.0 else 1.0)
	var now:=clampf(keepers/(pop*0.035),0.0,1.25)
	var more:=clampf((keepers+ten)/(pop*0.035),0.0,1.25)
	assert_str(String(Effects.administration().plus_ten)).is_equal("Ten more: cohesion +%d, trust +%d." % [roundi((more-now)*20.0),roundi((more-now)*10.0)])
	# Learning: the knowing they add and how much faster the research goes, from
	# the engine's own reading (discovery_system.gd role_effect).
	var learners:=float(GameState.effective_workers("Knowledge"))
	var raw_learners:=float(GameState.population_allocations.get("Knowledge",0))
	var research:=DiscoverySystem.role_effect("Knowledge",10.0*(learners/raw_learners if raw_learners>0.0 else 1.0))
	assert_float(float(research.pace_gain)).is_greater(0.0)
	assert_str(String(Effects.knowledge().plus_ten)).contains("research %s" % Effects.faster(float(research.pace_gain)))
	# Building: how much sooner, not when.
	assert_str(String(Effects.construction().plus_ten)).contains("sooner")
	# The watch: the guard ten more add at home, by the home's share of the
	# people in towns that keep a guard (here, one town: all of it).
	assert_str(String(Effects.defense().plus_ten)).contains("guard at home +10")

func test_the_people_view_works_the_effects_out_weekly_or_when_the_work_changes()->void:
	_world()
	var day:=int(GameState.elapsed_days)
	GameState.elapsed_days=day-posmod(day,Effects.CACHE_DAYS)
	var week:=Effects.all_cached()
	assert_bool(is_same(Effects.all_cached(),week)).is_true()
	# A day later in the same week: the same reading.
	GameState.elapsed_days+=1
	assert_bool(is_same(Effects.all_cached(),week)).is_true()
	# A week on: read again.
	GameState.elapsed_days+=Effects.CACHE_DAYS
	var later:=Effects.all_cached()
	assert_bool(is_same(later,week)).is_false()
	# The work changed: read again at once.
	GameState.population_allocations.Defense=int(GameState.population_allocations.Defense)+3
	assert_bool(is_same(Effects.all_cached(),later)).is_false()
	assert_int(Effects.all_cached().size()).is_equal(9)

func test_ten_more_reads_the_engine_rule()->void:
	_world()
	# The watch: +42 points of safety for every 5 in 100 of the people on it.
	var pop:=float(GameState.population_exact)
	var watch:=float(GameState.population_allocations.get("Defense",0))
	var more:=roundi((watch+10.0)/(pop*0.05)*42.0)-roundi(watch/(pop*0.05)*42.0)
	var said:=String(Effects.defense().plus_ten)
	var expected:=roundi(10.0/(pop*0.05)*42.0)
	assert_bool(said.contains("+%d points" % expected) or said.contains("+%d points" % more)).override_failure_message(said).is_true()
	# Food: ten more bring in their share at today's yield a getter.
	var getters:=float(GameState.effective_workers("Food"))
	var raw:=float(GameState.population_allocations.get("Food",0))
	var each:=100.0/getters
	assert_str(String(Effects.food().plus_ten)).contains("about %s more" % preload("res://scripts/task_impact.gd")._whole(each*10.0*getters/raw))

# --------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------

func test_each_temper_takes_its_path()->void:
	assert_str(String(Paths.choose(_temper(.9,.7,.5,.3,.2),CALM).id)).is_equal("learning")
	assert_str(String(Paths.choose(_temper(.4,.4,.9,.2,.2),CALM).id)).is_equal("growth")
	assert_str(String(Paths.choose(_temper(.4,.5,.15,.9,.7),CALM).id)).is_equal("war")
	assert_str(String(Paths.choose(_temper(.66,.8,.5,.4,.7),CALM).id)).is_equal("making")
	assert_str(String(Paths.choose(_temper(.2,.9,.5,.7,.4),CALM).id)).is_equal("building")
	assert_str(String(Paths.choose(_temper(.5,.5,.5,.5,.5),CALM).id)).is_equal("balanced")
	# The situation pulls: an even temper at war, its neighbours pressing, leans to the watch.
	assert_str(String(Paths.choose(_temper(.5,.5,.5,.5,.5),{"threat":.8,"at_war":true}).id)).is_equal("war")
	# A path held is kept while it is near the best: no flipping month by month.
	var trader:=_temper(.62,.78,.5,.55,.62)
	var fresh:=Paths.choose(trader,CALM)
	var other:="building" if String(fresh.id)=="making" else "making"
	var scores:Dictionary=fresh.scores
	if absf(float(scores.get(other,0.0))-float(fresh.score))<=Paths.STICK:
		assert_str(String(Paths.choose(trader,CALM,other).id)).is_equal(other)
	# A scholar on learning keeps it until openness falls below the leaving
	# line, so a ruler near the line does not flip month by month.
	var near:=_temper(Paths.SCHOLARLY-.02,.75,.4,.25,.15)
	assert_str(String(Paths.choose(near,CALM).id)).is_not_equal("learning")
	assert_str(String(Paths.choose(near,CALM,"learning").id)).is_equal("learning")
	assert_str(String(Paths.choose(_temper(Paths.SCHOLARLY_LEAVE-.02,.75,.4,.25,.15),CALM,"learning").id)).is_not_equal("learning")
	# Every path says why in plain words.
	for path:String in Paths.NAMES:
		assert_str(Paths.why(path,CALM)).is_not_empty()

func test_learning_only_for_a_scholarly_temper()->void:
	# Open, careful and steady, but short of scholarly: never learning.
	var open_not_scholar:=_temper(Paths.SCHOLARLY-.02,.9,.3,.2,.12)
	assert_str(String(Paths.choose(open_not_scholar,CALM).id)).is_not_equal("learning")
	assert_bool(Paths.scores(open_not_scholar,CALM).has("learning")).is_false()
	# Across rulers drawn as the world draws them, learning is not the default.
	var rng:=RandomNumberGenerator.new();rng.seed=4401
	var counts:={}
	var n:=6000
	for i in n:
		var pick:=String(Paths.choose(Personality.generate(rng),CALM).id)
		counts[pick]=int(counts.get(pick,0))+1
	var most:=""
	for path:String in counts:
		if most=="" or int(counts[path])>int(counts[most]):most=path
	print("[role_paths] tempers drawn at random (%d): %s" % [n,_shares(counts,n)])
	assert_str(most).is_not_equal("learning")
	assert_float(float(counts.get("learning",0))/n).is_less(0.2)
	for path:String in counts:
		assert_float(float(counts[path])/n).override_failure_message("%s holds %s" % [path,_shares(counts,n)]).is_less_equal(0.4)

func test_paths_spread_across_a_seeded_world_of_twelve()->void:
	var all:={}
	var total:=0
	for world_seed:int in [716203,74017,777,20261002,31337,90210,4242,123456,8675309,1001]:
		var counts:={}
		var rows:PackedStringArray=[]
		for index in range(1,13):
			var civ_id:="civ_%02d" % index
			var pick:=Paths.choose(Personality.foreign(world_seed,civ_id),CALM)
			counts[pick.id]=int(counts.get(pick.id,0))+1
			all[pick.id]=int(all.get(pick.id,0))+1
			rows.append("%s %s" % [civ_id,String(pick.id)])
			total+=1
		print("[role_paths] world %d: %s" % [world_seed,_shares(counts,12)])
		if world_seed==716203:print("[role_paths] world %d rulers: %s" % [world_seed,", ".join(rows)])
		# A world's peoples go different ways.
		assert_int(counts.size()).override_failure_message("world %d: %s" % [world_seed,str(counts)]).is_greater_equal(3)
		for path:String in counts:
			assert_int(int(counts[path])).override_failure_message("world %d: %s" % [world_seed,str(counts)]).is_less_equal(5)
	print("[role_paths] all %d rulers: %s" % [total,_shares(all,total)])
	for path:String in all:
		assert_float(float(all[path])/total).override_failure_message("%s" % _shares(all,total)).is_less_equal(0.4)
	var most:=""
	for path:String in all:
		if most=="" or int(all[path])>int(all[most]):most=path
	assert_str(most).is_not_equal("learning")

func _shares(counts:Dictionary,n:int)->String:
	var parts:PackedStringArray=[]
	for path:String in ["growth","making","war","learning","building","balanced"]:
		parts.append("%s %d (%d in 100)" % [path,int(counts.get(path,0)),roundi(float(counts.get(path,0))*100.0/maxf(1.0,n))])
	return ", ".join(parts)

## The leaders' split leans toward the path; food comes first all the same.
func test_the_path_leans_the_leaders_split()->void:
	_world()
	var city:Dictionary=GameState.player_settlements[0]
	var leader:=GovernmentPeopleSystem._person_record(int(city.get("leader_person_id",0)))
	var shares:={}
	for path:String in ["balanced","growth","making","war","learning","building"]:
		PeopleDirection.work_path={"id":path,"since":int(GameState.elapsed_days),"reviewed":int(GameState.elapsed_days),"why":"","score":0.7,"by":"leaders"}
		shares[path]=SettlementModel.with_city_resources(String(city.id),func()->Dictionary:return GovernmentPeopleSystem._allocations_for_focus("balanced",leader,true))
	var table:PackedStringArray=[]
	for path:String in shares:
		var parts:PackedStringArray=[]
		for role:String in ROLES:parts.append("%s %.1f" % [role,float(shares[path][role])])
		table.append("%s: %s" % [path,", ".join(parts)])
	print("[role_paths] the leaders' split by path (in 100):\n  "+"\n  ".join(table))
	var base:Dictionary=shares.balanced
	for pair:Array in [["growth","Administration"],["making","Crafting"],["war","Defense"],["learning","Knowledge"],["building","Construction"]]:
		# Its own work rises, and the work it leans toward together by more.
		assert_float(float(shares[pair[0]][pair[1]])).override_failure_message("%s does not lean to %s" % pair).is_greater(float(base[pair[1]])+2.5)
		var ours:=0.0;var before:=0.0
		for role:String in Paths.WORK[pair[0]]:ours+=float(shares[pair[0]][role]);before+=float(base[role])
		assert_float(ours).override_failure_message("%s's work together" % pair[0]).is_greater(before+3.0)
	# Only the learning path puts more on learning.
	for path:String in ["growth","making","war","building"]:
		assert_float(float(shares[path].Knowledge)).is_less_equal(float(base.Knowledge)+0.01)
	# Food first: no path takes hands off food (the planners' need and the
	# age's floor are laid on after the path).
	for path:String in shares:
		assert_float(float(shares[path].Food)).is_greater_equal(float(base.Food)-0.5)

## One temper asks twice, through its ambition and its path: each role takes
## the larger ask, never both; the deeper food reserve likewise.
func test_the_path_does_not_stack_on_the_ambitions()->void:
	_world()
	PeopleDirection.work_path={"id":"learning","since":0,"reviewed":int(GameState.elapsed_days),"why":"","score":.8,"by":"ruler"}
	var weights:={"Knowledge":20.0,"Survey":8.0}
	Paths.lean(weights,{"Knowledge":14.0,"Survey":4.0},0.0)
	assert_float(float(weights.Knowledge)).is_equal_approx(20.0,0.0001)
	assert_float(float(weights.Survey)).is_equal_approx(8.0,0.0001)
	weights={"Knowledge":6.0,"Survey":8.0}
	Paths.lean(weights,{},0.0)
	assert_float(float(weights.Knowledge)).is_equal_approx(6.0+float(Paths.WORK.learning.Knowledge),0.0001)
	weights={"Knowledge":10.0}
	Paths.lean(weights,{"Knowledge":4.0},0.0)
	assert_float(float(weights.Knowledge)).is_equal_approx(10.0+float(Paths.WORK.learning.Knowledge)-4.0,0.0001)
	PeopleDirection.work_path.id="growth"
	assert_float(Paths.lean({},{},0.2)).is_equal_approx(float(Paths.FOOD_LEAN.growth),0.0001)
	assert_float(Paths.lean({},{},0.9)).is_equal_approx(0.9,0.0001)

## The Food page says the reserve the planners aim for, the path's included.
func test_the_food_page_reserve_counts_the_path()->void:
	_world()
	var demand:=maxf(0.01,float(GameState.simulation_metrics.get("food_consumption",0.0)))
	var cap:=float(FoodSystem._food_storage_capacity())/demand*0.8
	PeopleDirection.work_path={"id":"balanced","since":0,"reviewed":int(GameState.elapsed_days),"why":"","score":.58,"by":"leaders"}
	var plain:=float(GovernmentPeopleSystem.reserve_plan().target_days)
	PeopleDirection.work_path.id="growth"
	var growth:=float(GovernmentPeopleSystem.reserve_plan().target_days)
	assert_float(plain).is_equal_approx(minf(GovernmentPeopleSystem.RESERVE_TARGET_DAYS,cap),0.01)
	assert_float(growth).is_equal_approx(minf(GovernmentPeopleSystem.RESERVE_TARGET_DAYS*(1.0+float(Paths.FOOD_LEAN.growth)),cap),0.01)
	assert_str(String(Paths.LEANS.growth)).not_contains("getting food").contains("deeper food reserve")

## The leaders read the realm's own count, before any town's work is laid; a
## town's scope never re-chooses the path.
func test_the_leaders_review_at_the_realm_level()->void:
	_world()
	assert_int(int(PeopleDirection.work_path.reviewed)).is_equal(int(GameState.elapsed_days))
	PeopleDirection.work_path={"id":"war","since":0,"reviewed":int(GameState.elapsed_days)-400,"why":"old","score":.7,"by":"leaders"}
	var city:Dictionary=GameState.player_settlements[0]
	var leader:=GovernmentPeopleSystem._person_record(int(city.get("leader_person_id",0)))
	SettlementModel.with_city_resources(String(city.id),func()->Dictionary:return GovernmentPeopleSystem._allocations_for_focus("balanced",leader,true))
	assert_str(String(PeopleDirection.work_path.why)).is_equal("old")
	_delegate()
	assert_int(int(PeopleDirection.work_path.reviewed)).is_equal(int(GameState.elapsed_days))
	assert_str(Paths.held()).is_equal("balanced")

func test_our_leaders_start_balanced_and_not_on_learning()->void:
	_world()
	assert_str(Paths.held()).is_equal("balanced")
	assert_str(String(PeopleDirection.work_path.get("by",""))).is_equal("leaders")
	var knowledge:=float(GameState.population_allocation_percentages.get("Knowledge",0.0))
	print("[role_paths] our leaders' default split (in 100): %s" % str(GameState.population_allocation_percentages))
	assert_float(knowledge).is_less_equal(8.0)
	# The leaders look again after a month, not every day.
	PeopleDirection.work_path.why="kept"
	GameState.elapsed_days+=5
	Paths.current()
	assert_str(String(PeopleDirection.work_path.why)).is_equal("kept")
	GameState.elapsed_days+=Paths.REVIEW_DAYS
	Paths.current()
	assert_str(String(PeopleDirection.work_path.why)).is_not_equal("kept")

func test_a_computer_ruler_orders_its_path_and_the_world_shows_it()->void:
	_world()
	WorldSimulation.enabled=true
	# A proud, hard ruler and a caring, careful one, by their own tempers.
	WorldSimulation.create_actor("civ_test_a",716203,Vector2(40,40))
	WorldSimulation.create_actor("civ_test_b",716203,Vector2(-40,40))
	var controller:=preload("res://scripts/civilization_controller.gd")
	for pair:Array in [["civ_test_a",_temper(.4,.5,.15,.9,.7),"war"],["civ_test_b",_temper(.4,.4,.9,.2,.2),"growth"]]:
		var id:=String(pair[0])
		WorldSimulation.scoped(id,func()->void:
			# Balanced until the ruler has chosen.
			assert_str(Paths.current()).is_equal("balanced")
			controller.work_path_orders(id,{"personality":pair[1]})
			assert_str(Paths.held()).is_equal(String(pair[2]))
			assert_str(String(Paths.record_of().by)).is_equal("ruler")
			assert_str(Paths.current()).is_equal(String(pair[2]))
			# The order is logged with the ruler's other orders.
			var last:Dictionary=(WorldSimulation.actors[id].orders as Array).back()
			assert_str(String(last.order.kind)).is_equal("work_path")
		)
	var spread:=Paths.world_spread()
	print("[role_paths] world spread: %s" % str(spread.counts))
	assert_int(int(spread.counts.get("war",0))).is_equal(1)
	assert_int(int(spread.counts.get("growth",0))).is_equal(1)
	assert_str(Paths.people_words("civ_test_a")).is_equal("their work is set on war")
	# A bad path is refused.
	assert_bool(Paths.order({"path":"plunder"}).has("error")).is_true()

func test_the_path_is_saved_with_the_people_and_old_saves_start_balanced()->void:
	_world()
	var saved:=Save._capture_reflected(PeopleDirection,[])
	assert_bool(saved.has("work_path")).is_true()
	assert_str(String((saved.work_path as Dictionary).get("id",""))).is_equal("balanced")
	# An older save has no path: nothing to lean on until the leaders look.
	saved.erase("work_path")
	PeopleDirection.work_path={}
	Save._apply_reflected(PeopleDirection,saved)
	assert_str(Paths.held()).is_equal("")
	assert_str(Paths.current()).is_equal("balanced")
