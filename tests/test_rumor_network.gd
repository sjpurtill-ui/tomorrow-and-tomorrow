extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(424242)
	SettlementModel.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	MilitaryCampaign.reset_for_new_world(); ForeignDiplomacy.reset_for_new_world()
	GameState.initialize_population_model(); GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	FoodSystem.reset_for_new_world(); FoodSystem.initialize(); FoodSystem.receive_external_food(100000)
	GameState.civic_api_enabled=false
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool: return true)
func net(): return CivilizationSystem.rumor_network
func id(index:int)->String: return String(CivilizationSystem.civilizations[index].id)
func lead(observer:String="player",subject:String="",position:Vector2=Vector2(90,0),day:int=0)->Dictionary:
	return net().observation(observer,id(0) if subject=="" else subject,"Reported travelers",position,80,day,"test witnessed travelers")
func test_account_is_carried_until_return_and_not_live_sender_knowledge()->void:
	var source:=id(1); var other:=id(2)
	net().receive(source,lead(source),0)
	var party:Dictionary={}; net().prepare(party,"player",0)
	net().exchange(party,"player",source,Vector2(40,0),10)
	assert_dict(net().books.get("player",{})).is_empty()
	var carried:Array=party.rumor_inbox.duplicate(true)
	net().receive(source,lead(source,other,Vector2(900,0),11),11)
	assert_array(party.rumor_inbox).is_equal(carried)
	net().deliver(party,"player",30)
	var received:Dictionary=net().books.player[lead(source).id]
	assert_int(received.observed_day).is_equal(0)
	assert_int(received.reported_day).is_equal(30)
	assert_dict(received.heard_position).is_equal({"x":40.0,"z":0.0})
	assert_bool(net().books.player.has(lead(source,other,Vector2(900,0),11).id)).is_false()
func test_forwarding_requires_actual_visit_and_does_not_amplify_or_loop()->void:
	var a:=id(1); var b:=id(2); var c:=id(3)
	var original:=lead(a); net().receive(a,original,0)
	var courier:Dictionary={}; net().prepare(courier,a,0)
	assert_dict(net().books.get(b,{})).is_empty()
	net().exchange(courier,a,b,Vector2(200,0),12)
	var first:Dictionary=net().books[b][original.id].duplicate(true)
	assert_float(first.confidence).is_less(original.confidence)
	net().exchange(courier,a,b,Vector2(200,0),13)
	assert_dict(net().books[b][original.id]).is_equal(first)
	var next:Dictionary={}; net().prepare(next,b,14); net().exchange(next,b,c,Vector2(300,0),25)
	assert_bool(net().books[c].has(original.id)).is_true()
	var last:Dictionary={}; net().prepare(last,c,26); net().exchange(last,c,a,Vector2(100,0),40)
	assert_dict(net().books[a][original.id]).is_equal(original)
	assert_bool(net().books[a][original.id].confidence>net().books[c][original.id].confidence).is_true()
func test_visitor_exposure_reports_encounter_not_secret_home_or_hostility()->void:
	var host:=id(1); var party:Dictionary={}; net().prepare(party,"player",0)
	var relation:Dictionary=CivilizationSystem.civilizations[1].player_relation.duplicate(true)
	net().exchange(party,"player",host,Vector2(500,300),10)
	var exposure:Dictionary=net().list_leads(host,10)[0]
	assert_str(exposure.subject).is_equal("player")
	assert_dict(exposure.center).is_equal({"x":500.0,"z":300.0})
	assert_dict(CivilizationSystem.civilizations[1].player_relation).is_equal(relation)
	assert_array(CivilizationSystem.city_intelligence.known_cities(host,"player")).is_empty()
func test_search_uses_report_not_hidden_truth_and_failure_only_weakens_corridor()->void:
	var account:=lead(); net().receive("player",account,0)
	var before:Dictionary=net().plan("player",account.id,1,500,0)
	assert_bool(before.ok).is_true()
	CivilizationSystem.civilizations[0].position=Vector2(.8,.8)
	var after:Dictionary=net().plan("player",account.id,1,500,0)
	assert_dict(after).is_equal(before)
	var party:Dictionary={"rumor_lead_id":account.id,"target_position":before.search_position}
	var result:String=net().finish_search(party,"player",30,false)
	assert_str(result).contains("remain unsearched")
	assert_float(net().books.player[account.id].confidence).is_less(account.confidence)
	assert_int(net().books.player[account.id].searched.size()).is_equal(1)
	assert_array(CivilizationSystem.city_intelligence.known_cities()).is_empty()
	assert_bool(net().search_point("player",account,1,500)!=net().search_point("player",account,2,500)).is_true()
func test_player_dispatch_spends_real_food_and_lost_party_delivers_nothing()->void:
	var account:=lead(); net().receive("player",account,0)
	var food:=FoodSystem.total_stored()
	var quote:Dictionary=CivilizationSystem.scout_mission_quote(30,"lead:"+account.id)
	assert_bool(quote.can_dispatch).is_true()
	var dispatch:Dictionary=CivilizationSystem.dispatch_scouts(30,"lead:"+account.id)
	assert_bool(dispatch.get("ok",false)).is_true()
	assert_float(FoodSystem.total_stored()).is_equal_approx(food-float(quote.provisions),.001)
	var party:Dictionary=CivilizationSystem.scout_missions[0]
	assert_str(party.target_kind).is_equal("investigate_lead")
	assert_bool(CivilizationSystem._scout_route_is_land(party.route)).is_true()
	var unseen:=lead(id(2),id(3)); party.rumor_inbox.append(unseen)
	CivilizationSystem._erase_scout_mission(party)
	assert_bool(net().books.player.has(unseen.id)).is_false()
func test_ai_uses_same_land_plan_and_pays_provisions_without_creating_people()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[1]
	civ.population=1000; civ.military_population=100; civ.food_days=100
	var account:=lead(String(civ.id),id(0),net().home(String(civ.id))+Vector2(80,0))
	net().receive(String(civ.id),account,0)
	var party:Dictionary={"point_a":net().home(String(civ.id)),"point_b":Vector2.ZERO,"search_sequence":0,"leg_days":30.0,"strength_share":.1}
	var old_food:=float(civ.food_days)
	assert_bool(net().ai_plan(party,civ,0)).is_true()
	assert_bool(party.has("rumor_lead_id")).is_true()
	assert_bool(CivilizationSystem._scout_route_is_land(party.route)).is_true()
	assert_float(civ.food_days).is_equal_approx(old_food-float(party.rumor_provisions)/1000,.0001)
	assert_int(party.rumor_personnel).is_equal(12)
	assert_float(float(civ.population)).is_equal(1000.0)
	CivilizationSystem.set_scout_geography_authority(Callable())
	var blocked:Dictionary={"point_a":party.point_a,"point_b":Vector2.ZERO,"search_sequence":1,"leg_days":30.0}
	var food_before:=float(civ.food_days)
	net().ai_plan(blocked,civ,0)
	assert_bool(blocked.rumor_waiting).is_true()
	assert_float(civ.food_days).is_equal(food_before)
func test_stale_conflicting_accounts_preserve_evidence_and_unknown_source()->void:
	var a:=lead(); a.heard_position={}; net().receive("player",a,0)
	var b:=lead(id(1),id(0),Vector2(2000,1000)); net().receive("player",b,0)
	var old:Dictionary=net().known("player",a.id,500)
	assert_str(old.state).is_equal("stale")
	assert_bool(old.conflicting).is_true()
	assert_float(old.radius).is_greater(a.radius)
	assert_float(old.confidence).is_less(a.confidence)
	assert_dict(old.heard_position).is_empty()
	assert_dict(net().books.player[a.id]).is_equal(a)
func test_save_load_round_trip_legacy_and_malformed_rejection_are_atomic()->void:
	var account:=lead(); net().receive("player",account,0)
	var original:Dictionary=CivilizationSystem.export_state()
	var serialized:Dictionary=JSON.parse_string(JSON.stringify(original))
	assert_bool(CivilizationSystem.import_state(serialized).has("error")).is_false()
	assert_str(net().books.player[account.id].source).is_equal(account.source)
	var invalid:=CivilizationSystem.export_state(); invalid.rumor_leads.player[account.id].radius=-1
	assert_bool(CivilizationSystem.import_state(invalid).has("error")).is_true()
	assert_float(float(net().books.player[account.id].radius)).is_equal(80.0)
	original.erase("rumor_leads")
	assert_bool(CivilizationSystem.import_state(original).has("error")).is_false()
	assert_dict(net().books).is_empty()
func test_many_observers_and_repeated_delivery_stay_bounded()->void:
	for observer in 64:
		for subject in 45:
			var owner:="observer%d" % observer
			net().receive(owner,lead(owner,"subject%d" % subject,Vector2(subject*10,0)),0)
	assert_int(net().books.size()).is_equal(64)
	for book:Dictionary in net().books.values(): assert_int(book.size()).is_equal(32)
	assert_bool(net().validate(net().books)).is_true()
	var original:Dictionary=net().books.duplicate(true)
	var started:=Time.get_ticks_msec()
	for iteration in 1000: net().receive("observer0",net().books.observer0.values()[0],10)
	assert_dict(net().books).is_equal(original)
	assert_int(Time.get_ticks_msec()-started).is_less(1000)

func test_daily_physical_visit_and_actual_return_exchange_without_remote_delivery()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[1]
	var origin:Vector2=net().home("player")
	civ.position=Vector2((origin.x+100)/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,origin.y/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_Z_KM)
	var story:=lead(String(civ.id),id(3),origin+Vector2(150,100)); net().receive(String(civ.id),story,0)
	var party:Dictionary={"mission_id":55,"start_day":0,"return_day":20,"actual_return_day":20,"route":[net().point(origin),net().point(origin+Vector2(100,0))],"target_kind":"investigate_lead","rumor_lead_id":"missing"}
	net().prepare(party,"player",0); CivilizationSystem.scout_missions.append(party)
	net().sample(10)
	assert_bool(party.rumor_visits.has(String(civ.id))).is_true()
	assert_dict(net().books.get("player",{})).is_empty()
	net().deliver(party,"player",20)
	assert_bool(net().books.player.has(story.id)).is_true()
func test_ai_foreign_city_evidence_obeys_same_physical_return_boundary()->void:
	var city:Dictionary=CivilizationSystem.city_intelligence.sites(false)[0]
	var observer:=id(1); var mission:Dictionary={}
	CivilizationSystem.city_intelligence.stage(mission,observer,net().vector(city.position),.8,10,"real visit")
	assert_dict(CivilizationSystem.city_intelligence.known(observer,city.city_id)).is_empty()
	CivilizationSystem.city_intelligence.deliver(mission,observer,20)
	assert_int(CivilizationSystem.city_intelligence.known(observer,city.city_id,20).observed_day).is_equal(10)
func test_real_save_system_preserves_carried_and_received_accounts()->void:
	var account:=lead(); net().receive("player",account,0)
	assert_bool(CivilizationSystem.dispatch_scouts(30,"lead:"+account.id).get("ok",false)).is_true()
	var expected:Dictionary=net().books.duplicate(true)
	var carried:Array=CivilizationSystem.scout_missions[0].rumor_outbox.duplicate(true)
	var slot:="rumor_qa_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	net().books.clear()
	var restored:Dictionary=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).is_true()
	assert_dict(net().books).is_equal(expected)
	assert_array(CivilizationSystem.scout_missions[0].rumor_outbox).is_equal(carried)

func test_expired_accounts_are_pruned_and_packets_do_not_store_view_fields()->void:
	var old:=lead("witness","subject",Vector2(100,0))
	net().receive("player",old,0)
	var carried:Dictionary=net().packet(net().known("player",old.id,5),"player")
	assert_bool(carried.has("age") or carried.has("state") or carried.has("conflicting")).is_false()
	net().sample(4000)
	assert_dict(net().books.player).is_empty()
