extends GdUnitTestSuite
## The Research dock's "Where we look" tab lists each question under way once,
## however many lines of attention work it, and every card is as tall as its
## own words and names the field it belongs to.
const Board:=preload("res://scripts/hud/inquiry_board.gd")
const DAY:=365*11

func before_test()->void:
	GameState.reset_for_new_world(991704)
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	# Labor as the day's settlement work shares it out (people at learning > 0);
	# reading the research lines re-synchronizes it, so start synchronized.
	GameState.synchronize_population_allocations()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.elapsed_days=float(DAY)
	for id in ["stone_sorting","clay_testing","counting_words","tallies","basketry","ember_tending","hearth_heat_retention"]:
		if not id in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.resource_deposits.append({"resource":"Clay","stage":"accessible"})
	GameState.resource_deposits.append({"resource":"Fiber Plants","stage":"accessible"})
	for domain in GameState.research_subcategory_allocations:
		for sub in (GameState.research_subcategory_allocations[domain] as Dictionary):GameState.research_subcategory_allocations[domain][sub]=0
	DiscoverySystem._rebuild_research_domain_totals()
	GameState.active_investigations.clear();GameState.research_targets.clear()

## A question a field may take up as foundation work on a line that is not the
## question's own: how two lines came to hold one question.
func _borrowed()->Dictionary:
	for domain:String in GameState.research_subcategory_allocations:
		for id:String in DiscoverySystem._research_600_foundation_ids(domain,DAY):
			if DiscoverySystem.Research600.deferred(id,DiscoverySystem.society_model.ceiling_era):continue
			var question:=DiscoverySystem.discovery_definition(id)
			if not (GameState.research_subcategory_allocations.get(String(question.dynamic),{}) as Dictionary).has(String(question.subcategory)):continue
			var own:=DiscoverySystem._channel_key(String(question.dynamic),String(question.subcategory))
			for sub:String in GameState.research_subcategory_allocations[domain]:
				var line:=DiscoverySystem._channel_key(domain,sub)
				if line!=own:return {"id":id,"line":line,"own":own}
	return {}

func _staff(channel:String)->void:
	var parts:=channel.split("::")
	GameState.research_subcategory_allocations[parts[0]][parts[1]]=1
	DiscoverySystem._rebuild_research_domain_totals()

func _ids(records:Array)->Array:
	var ids:Array=[]
	for record:Dictionary in records:ids.append(String(record.id))
	return ids

func test_two_lines_on_one_question_are_one_record_with_both_teams()->void:
	var borrowed:=_borrowed()
	assert_dict(borrowed).is_not_empty()
	_staff(borrowed.line);_staff(borrowed.own)
	GameState.active_investigations[borrowed.line]=borrowed.id
	# The question's own line frees up and takes the question the other line
	# borrowed: for a day both lines hold it.
	GameState.research_targets[borrowed.own]=borrowed.id
	var records:=DiscoverySystem.active_investigation_records()
	assert_str(String(GameState.active_investigations.get(borrowed.line,""))).is_equal(borrowed.id)
	assert_str(String(GameState.active_investigations.get(borrowed.own,""))).is_equal(borrowed.id)
	var ids:=_ids(records)
	assert_int(ids.count(borrowed.id)).is_equal(1)
	for id in ids:assert_int(ids.count(id)).is_equal(1)
	var record:Dictionary=records[ids.find(borrowed.id)]
	assert_array(record.channels).contains_exactly_in_any_order([borrowed.line,borrowed.own])
	assert_int(int(record.observer_allocation)).is_equal(2)
	var own_parts:=String(borrowed.own).split("::");var line_parts:=String(borrowed.line).split("::")
	# Two teams on it for the day: both teams' people.
	var team:=float(DiscoverySystem.research_capacity_for(own_parts[0],own_parts[1]).team_people)+float(DiscoverySystem.research_capacity_for(line_parts[0],line_parts[1]).team_people)
	assert_float(team).is_greater(0.0)
	assert_float(float(record.research_workforce)).is_equal_approx(team,0.0001)

func test_a_borrowed_question_goes_back_to_its_own_line()->void:
	var borrowed:=_borrowed()
	assert_dict(borrowed).is_not_empty()
	_staff(borrowed.line);_staff(borrowed.own)
	GameState.active_investigations[borrowed.line]=borrowed.id
	DiscoverySystem.refresh_investigations()
	assert_str(String(GameState.active_investigations.get(borrowed.line,""))).is_equal(borrowed.id)
	# The player chooses the question for its own line.
	assert_bool(bool(DiscoverySystem.select_research_target(borrowed.id).ok)).is_true()
	DiscoverySystem.refresh_investigations()
	assert_str(String(GameState.active_investigations.get(borrowed.own,""))).is_equal(borrowed.id)
	assert_str(String(GameState.active_investigations.get(borrowed.line,""))).is_not_equal(borrowed.id)
	var held:=0
	for id:Variant in GameState.active_investigations.values():
		if String(id)==borrowed.id:held+=1
	assert_int(held).is_equal(1)
	assert_int(_ids(DiscoverySystem.active_investigation_records()).count(borrowed.id)).is_equal(1)

# --- The board -----------------------------------------------------------------

const WORKFORCE:="RESEARCH WORKFORCE — a thin team: less than one person at it, where a people of our size would put about 3 on one question"
func _records()->Array:
	return [
		{"id":"clay_shaping","name":"Clay Vessels","dynamic":"production","progress":0.46,"research_workforce":0.5,"bottleneck":WORKFORCE},
		{"id":"mouths_against_store","name":"Mouths Counted Against the Store","dynamic":"demography","progress":0.63,"research_workforce":0.5,"bottleneck":WORKFORCE},
		{"id":"fruit_pulp_screening","name":"Fruit Pulp Screening","dynamic":"nutrition","progress":0.2,"research_workforce":0.5,"bottleneck":WORKFORCE},
		{"id":"turbidity_judging","name":"Turbidity Judging","dynamic":"health","progress":0.3,"research_workforce":1.2,"bottleneck":"EARLY EVIDENCE — more repeated cases are required"},
		{"id":"loose_question","name":"A question with only a line","dynamic":"","subcategory":"Stored reserve","progress":0.1,"research_workforce":0.5,"bottleneck":WORKFORCE},
	]
func _board(records:Array,width:int)->Node:
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(width,2000);add_child(viewport)
	var board=Board.new();viewport.add_child(board)
	board.setup({"fields":[],"investigations":records,"on_tree":func()->void:pass,"on_work":func()->void:pass,"on_domain":func(_d:String)->void:pass})
	board.position=Vector2.ZERO;board.size=Vector2(width,0)
	return board

func test_the_lead_question_has_a_painting_and_the_rest_keep_field_order()->void:
	var records:=_records()
	var order:=Board.question_order(records)
	var lead:Dictionary=order.lead
	assert_bool(Board.has_painting(lead)).is_true()
	for record:Dictionary in records:
		if Board.has_painting(record):assert_float(float(record.progress)).is_less_equal(float(lead.progress))
	var fields:Array=preload("res://scripts/hud/research_visuals.gd").NAMES.keys()
	var last:=-1
	for record:Dictionary in order.rest:
		var index:=fields.find(String(record.dynamic))
		if index<0:index=fields.size()
		assert_int(index).is_greater_equal(last);last=index
	assert_int(order.rest.size()).is_equal(records.size()-1)

func test_every_card_names_its_field_in_full()->void:
	assert_str(Board.field_name({"dynamic":"production"})).is_equal("Craft & industry")
	assert_str(Board.field_name({"dynamic":"","subcategory":"Stored reserve"})).is_equal("Stored reserve")
	assert_str(Board.field_name({"name":"No field at all"})).is_empty()
	var records:=_records();records.append({"id":"bare","name":"No field at all","progress":0.05,"research_workforce":0.5,"bottleneck":WORKFORCE})
	for width:int in [1120,600]:
		var board:=_board(records,width)
		for i in 5:await get_tree().process_frame
		var cards:Array=board.find_children("Question_*","",true,false)
		assert_int(cards.size()).is_equal(records.size())
		for card:Control in cards:
			var label:Label=card.find_child("FieldLabel",true,false)
			if card.name=="Question_bare":
				assert_object(label).is_null()
				continue
			assert_object(label).is_not_null()
			assert_str(label.text.strip_edges()).is_not_empty()
			var needed:=label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
			assert_float(label.size.x+1.0).is_greater_equal(needed)
			assert_int(label.get_theme_font_size("font_size")).is_greater_equal(12)

func test_cards_are_as_tall_as_their_words_and_fit_the_board()->void:
	for width:int in [1120,600]:
		var board:=_board(_records(),width)
		for i in 5:await get_tree().process_frame
		var cards:Array=board.find_children("Question_*","",true,false)
		assert_int(cards.size()).is_equal(5)
		for card:Control in cards:
			assert_float(card.size.y).is_less_equal(card.get_combined_minimum_size().y+1.0)
			assert_float(card.get_global_rect().end.x).is_less_equal(float(width)+1.0)
		var lead:Control=board.find_child("BeingLearned",true,false).find_child("Question_mouths_against_store",false,false)
		assert_object(lead).is_not_null()
		assert_float(lead.size.x).is_greater(float(width)*0.9)
		assert_int(board.projects_grid.columns).is_equal(2 if width>=Board.WIDE else 1)
		assert_bool(board.lead_row.vertical).is_equal(width<Board.WIDE)

func test_a_shared_holdup_is_written_out_once()->void:
	var board:=_board(_records(),1120)
	for i in 3:await get_tree().process_frame
	var sentence:=preload("res://scripts/hud/research_visuals.gd").plain_bottleneck(WORKFORCE)
	var written:=0;var named:=0
	for label:Node in board.find_children("*","Label",true,false):
		if (label as Label).text==sentence:written+=1
		if (label as Label).text=="Thin team":named+=1
	assert_int(written).is_equal(1)
	assert_int(named).is_equal(4)
	for card:Control in board.find_children("Question_*","",true,false):
		assert_str(card.tooltip_text).contains("Click to review")
