extends "res://tests/test_society_exchange.gd"
const A=preload("res://scripts/artifact_collection.gd")

func held(point:Vector2=Vector2(100,100))->Dictionary:
	var record:=A.find_at(777,point,1)
	E.data().collections[record.id]=record
	return record

func test_catalogue_is_diverse_and_deterministic()->void:
	var names:Dictionary={};var tiers:Dictionary={}
	for index:int in range(30000):
		var record:=A.find_at(777,Vector2(index*24,100),1)
		names[record.name]=true;tiers[record.rarity]=true
		assert_bool(E.valid_item(record)).is_true()
	assert_int(names.size()).is_greater(3500)
	assert_int(tiers.size()).is_equal(5)
	assert_str(A.find_at(777,Vector2(25,1),1).id).is_equal(A.find_at(777,Vector2(47,5),10).id)

func test_collections_appreciate_and_strengthen_research()->void:
	# Early record-keeping opens after year 0 (research_600 era gate), so the
	# opening redistribution can leave this channel unstaffed; staff it here.
	GameState.research_subcategory_allocations.knowledge["Preserved knowledge"]=maxi(2,int(GameState.research_subcategory_allocations.knowledge.get("Preserved knowledge",0)))
	var baseline:=DiscoverySystem.research_capacity_for("knowledge","Preserved knowledge")
	var culture_before:float=DiscoverySystem.society_model.evaluate_capacities({}).culture
	var record:=held();var initial:=A.price(record)
	A.advance(360);var first:=A.summary()
	assert_float(A.price(record)).is_greater(initial)
	assert_float(float(DiscoverySystem.research_capacity_for("knowledge","Preserved knowledge").progress_multiplier)).is_greater(float(baseline.progress_multiplier))
	assert_float(float(DiscoverySystem.society_model.evaluate_capacities({}).culture)).is_greater(culture_before)
	held(Vector2(900,100));A.advance(1)
	assert_float(float(A.summary().science)).is_greater(float(first.science))
	assert_bool(E.valid(E.data())).is_true()

func test_sale_conserves_money_and_moves_unique_ownership()->void:
	var record:=held();record.study=1;E.data().evidence[record.discovery_id]=record.id
	E.connection("neighbor")
	var target:=E.owner_state("neighbor")
	GameState.economy_stage="currency";target.economy_stage="currency"
	# Each realm pays and is paid from its one purse (realm_purse.gd).
	GameState.realm_purse={"balance":100.0,"coin":100.0,"backing":{"Gold":40.0},"migrated":true}
	target.realm_purse={"balance":10000.0,"coin":10000.0,"backing":{"Gold":4000.0},"migrated":true}
	var backing_before:=40.0+4000.0
	assert_bool(A.transfer(record.id,"neighbor","sell").has("ok")).is_true()
	assert_bool(E.data().collections.has(record.id)).is_false()
	assert_bool(target.society_exchange.collections.has(record.id)).is_true()
	assert_float(float(GameState.realm_purse.balance)+float(target.realm_purse.balance)).is_equal_approx(10100.0,.00001)
	assert_float(float(GameState.realm_purse.coin)+float(target.realm_purse.coin)).is_equal_approx(10100.0,.00001)
	assert_float(float(GameState.realm_purse.backing.Gold)+float(target.realm_purse.backing.Gold)).is_equal_approx(backing_before,.00001)
	assert_float(float(GameState.realm_purse.coin)).is_greater(100.0)
	assert_bool(E.valid(E.data())).is_true();assert_bool(E.valid(target.society_exchange)).is_true()
	assert_bool(A.transfer(record.id,"neighbor","sell").has("error")).is_true()

func test_museum_requires_knowledge_staff_and_real_spending()->void:
	var record:=held();record.study=1
	assert_bool(A.exhibit(record.id).has("error")).is_true()
	GameState.known_discoveries.append_array(["public_libraries","comparative_chronicles"])
	assert_bool(A.exhibit(record.id).has("ok")).is_true()
	GameState.economy_stage="currency";GameState.private_currency=100;GameState.public_treasury=0
	A.advance(1)
	assert_float(GameState.public_treasury).is_greater(0)
	assert_float(GameState.private_currency+GameState.public_treasury).is_equal_approx(100.0,.00001)

func test_trade_and_failed_sale_leave_no_duplicate()->void:
	var record:=held();var target:=E.owner_state("neighbor");E.connection("neighbor")
	var other:=A.find_at(777,Vector2(200,900),1);other.rarity=0;record.rarity=4
	target.society_exchange.collections[other.id]=other
	assert_bool(A.transfer(record.id,"neighbor","sell").has("error")).is_true()
	assert_bool(E.data().collections.has(record.id)).is_true()
	assert_bool(A.transfer(record.id,"neighbor","trade",other.id).has("ok")).is_true()
	assert_bool(E.data().collections.has(other.id)).is_true()
	assert_bool(target.society_exchange.collections.has(record.id)).is_true()

func test_gift_earns_recipient_respect_and_sites_cannot_be_reissued()->void:
	var point:=Vector2(100,100);var record:=held(point);E.connection("neighbor")
	E.data()["artifact_sites"]={record.id:true}
	assert_bool(A.transfer(record.id,"neighbor","gift").has("ok")).is_true()
	assert_bool(A.site_claimed(record.id)).is_true()
	WorldSimulation.scoped("neighbor",func()->void:
		assert_float(float(E.connection("player").respect)).is_greater(0)
		assert_bool(A.site_claimed(record.id)).is_true())

func test_held_artifact_unlocks_early_question_without_free_completion()->void:
	var record:=held();record.discovery_id="oral_epics";record.work=1
	# Artifacts are studied only by researchers assigned to the artifact-study role.
	preload("res://scripts/artifact_culture.gd").set_study_weight(1)
	GameState.elapsed_days=1;E.advance(1)
	assert_bool(P.ready(DiscoverySystem.discovery_definition("oral_epics"),1)).is_true()
	assert_bool("oral_epics" in GameState.known_discoveries).is_false()

func test_populated_collection_pages_searches_and_fits()->void:
	for index:int in range(85):held(Vector2(index*24,100))
	for size:Vector2i in [Vector2i(340,640),Vector2i(960,720)]:
		var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=size;add_child(viewport)
		var view:=CollectionPanel.new();viewport.add_child(view)
		for frame:int in range(4):await get_tree().process_frame
		assert_float(view.panel.size.x).is_less_equal(size.x)
		assert_int(view.cards.get_child_count()).is_equal(1)
		view.select_piece.pressed.emit()
		assert_int(view.choices.get_child_count()).is_equal(6)
		view.page=14;view.refresh(true)
		assert_int(view.choices.get_child_count()).is_equal(1)
		view.page=0;view.search.text="no such artifact";view.refresh(true)
		assert_int(view.choices.get_child_count()).is_equal(1)
		assert_bool(view.choices.get_child(0) is Label).is_true()
		assert_bool(view.cards.visible).is_false()

func test_returned_artifact_card_uses_its_artifact_painting_not_subject_art()->void:
	var record:=held();record.discovery_id="stone_sorting";record.name="Selected cutting stone";record.catalogue_id=0
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(960,720);add_child(viewport)
	var view:=CollectionPanel.new();viewport.add_child(view)
	for frame:int in range(4):await get_tree().process_frame
	var card:PanelContainer=view.cards.get_child(0)
	var row:BoxContainer=card.get_child(0)
	var painting:TextureRect=row.get_child(0)
	assert_vector(painting.custom_minimum_size).is_equal(Vector2(160,160))
	assert_str(painting.texture.resource_path).contains("artifacts/prehistoric-v1/artifact-0000")

func test_artifact_state_roundtrip_and_legacy_defaults()->void:
	var record:=held();A.advance(360)
	E.data()["artifact_sites"]={record.id:true}
	var saved:Dictionary=bytes_to_var(var_to_bytes(SaveSystem._capture_reflected(GameState,[])))
	GameState.society_exchange=E.empty_state()
	assert_bool(E.valid(saved.society_exchange)).is_true()
	GameState.society_exchange=saved.society_exchange
	assert_float(float(E.data().collections[record.id].held_days)).is_equal(360.0)
	assert_bool(A.site_claimed(record.id)).is_true()
	assert_bool(E.valid(E.empty_state())).is_true()

func test_daily_accrual_is_idempotent_and_large_collection_is_bounded()->void:
	for index:int in range(4096):held(Vector2(index*24,100))
	var started:=Time.get_ticks_usec()
	E.advance(1);var first:=A.summary();E.advance(1)
	assert_float(float(A.summary().prestige)).is_equal(float(first.prestige))
	assert_bool(E.valid(E.data())).is_true()
	print("ARTIFACT_4096_ACCRUAL_VALIDATION_US ",Time.get_ticks_usec()-started)
	assert_float(float(first.science)).is_less(1.0)

func test_gift_return_cannot_farm_the_same_recipient_respect()->void:
	var record:=held();E.connection("neighbor")
	assert_bool(A.transfer(record.id,"neighbor","gift").has("ok")).is_true()
	var respect:float=E.owner_state("neighbor").society_exchange.connections.player.respect
	WorldSimulation.scoped("neighbor",func()->void:
		WorldSimulation.world.civilizations.append({"id":"human","name":"Home","player_relation":{"at_war":false}})
		assert_bool(A.transfer(record.id,"player","gift").has("ok")).is_true())
	assert_bool(A.transfer(record.id,"neighbor","gift").has("ok")).is_true()
	assert_float(float(E.owner_state("neighbor").society_exchange.connections.player.respect)).is_equal(respect)

func test_owner_explicit_exchange_moves_between_owners_with_provenance()->void:
	var record:=held();E.connection("neighbor")
	# check() never moves anything; exchange() runs the giver's own transfer rules.
	assert_bool(A.exchange_check("player",record.id,"neighbor","gift").has("ok")).is_true()
	assert_bool(E.data().collections.has(record.id)).is_true()
	assert_bool(A.exchange("player",record.id,"neighbor","gift").has("ok")).is_true()
	assert_bool(A.holdings("neighbor").has(record.id)).is_true()
	assert_bool(A.holdings("player").has(record.id)).is_false()
	WorldSimulation.scoped("neighbor",func()->void:
		E.connection("player")
		WorldSimulation.world.civilizations.append({"id":"human","name":"Home","player_relation":{"at_war":false}}))
	assert_bool(A.exchange("neighbor",record.id,"player","gift").has("ok")).is_true()
	var moved:Dictionary=E.data().collections[record.id]
	assert_int((moved.provenance as Array).size()).is_equal(2)
	assert_str(String(moved.provenance[0].from)).is_equal("player")
	assert_str(String(moved.provenance[1].from)).is_equal("neighbor")
	assert_bool(E.valid(E.data())).is_true()
	assert_bool(A.exchange("nobody",record.id,"player","gift").has("error")).is_true()

func test_collection_offer_search_reaches_piece_beyond_first_forty_and_swaps()->void:
	var record:=held();record.rarity=4;E.connection("neighbor")
	var target:=E.owner_state("neighbor")
	var last:Dictionary={}
	for index in 50:
		last=A.find_at(777,Vector2(index*24,900),1);last.rarity=0
		last.name="Neighbor piece %02d" % index
		target.society_exchange.collections[last.id]=last
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(960,720);add_child(viewport)
	var view:=CollectionPanel.new();viewport.add_child(view)
	for frame in 4:await get_tree().process_frame
	view.offer_id=record.id;view.offer_to="neighbor";view.offer_mode="trade";view._build_offer()
	var wanted:OptionButton=view.offer_box.find_child("Wanted",true,false)
	assert_int(wanted.item_count).is_equal(51)
	var search_field:LineEdit=view.offer_box.find_child("FindTheirPiece",true,false)
	search_field.text="Neighbor piece 49";search_field.text_changed.emit(search_field.text)
	await get_tree().process_frame
	wanted=view.offer_box.find_child("Wanted",true,false)
	assert_int(wanted.item_count).is_equal(2)
	assert_str(String(wanted.get_item_metadata(1))).is_equal(String(last.id))
	wanted.select(1);wanted.item_selected.emit(1)
	await get_tree().process_frame
	var confirm:Button=view.offer_box.find_child("ConfirmOffer",true,false)
	assert_bool(confirm.disabled).is_false()
	confirm.pressed.emit()
	assert_bool(E.data().collections.has(last.id)).is_true()
	assert_bool(target.society_exchange.collections.has(record.id)).is_true()
	assert_bool(view.offer_box.visible).is_false()
	assert_bool(view.cards.visible).is_true()

func test_collection_policies_replace_reader_and_live_resize_keeps_selection()->void:
	var record:=held();record.study=1.0
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(960,720);add_child(viewport)
	var view:=CollectionPanel.new();viewport.add_child(view)
	for frame in 6:await get_tree().process_frame
	var selected:=view.selected_id
	var bar:ProgressBar=view.cards.find_child("*",true,false) as ProgressBar
	for control:Node in view.cards.find_children("*","ProgressBar",true,false):bar=control
	assert_bool(bar.visible).is_false()
	view.home_toggle.pressed.emit()
	assert_bool(view.cards.visible).is_false()
	assert_bool(view.home_box.visible).is_true()
	assert_bool(view.reader_back.visible).is_true()
	for button:Node in view.home_box.find_children("*","Button",true,false):
		if button.text=="Welcome them faster":button.pressed.emit();break
	assert_str(String(E.data().migration_policy)).is_equal("welcome")
	view.reader_back.pressed.emit()
	assert_bool(view.cards.visible).is_true()
	assert_str(view.selected_id).is_equal(selected)
	record.study=0.25;GameState.elapsed_days+=1;view.refresh(false)
	for control:Node in view.cards.find_children("*","ProgressBar",true,false):bar=control
	assert_bool(bar.visible).is_true()
	assert_float(bar.value).is_equal(25.0)
	for shape:Vector2i in [Vector2i(340,640),Vector2i(960,720)]:
		viewport.size=shape
		for frame in 8:await get_tree().process_frame
		assert_bool(Rect2(Vector2.ZERO,shape).encloses(view.panel.get_global_rect())).is_true()
		assert_str(view.selected_id).is_equal(selected)
