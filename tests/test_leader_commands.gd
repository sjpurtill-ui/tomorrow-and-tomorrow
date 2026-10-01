extends GdUnitTestSuite
## COMMANDS (scripts/leader_commands.gd): a leader and the bands under them.
## A band's leader is its commander record: moving a band to a general gives
## it that general's skills; moving it to the war leader gives it the war
## leader's. The commands are read from the bands themselves.

const Commands:=preload("res://scripts/leader_commands.gd")

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(5151)
	MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.settlement_site_committed=true
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	WorldSimulation.figures.ensure()

func after_test()->void:
	MilitaryCampaign.reset_for_new_world()
	WorldSimulation.clear()

func _band(id:int,men:int,commander:Dictionary)->Dictionary:
	var force:Dictionary=MilitaryCampaign.simulator.create_formation_force("Band %d" % id,[{"id":id,"unit":"spearman","weapon":"spear","count":men,"authorized_count":men,"equipment":men,"equipment_required":men,"training":0.6}],0.7,0.8)
	force.merge({"army_id":id,"name":"Band %d" % id,"status":"stationed","location_name":"Eldwick","position":{"x":0.0,"z":0.0},"supply_level":1.0,"commander":commander},true)
	return force

func _general()->Dictionary:
	for person:Dictionary in WorldSimulation.figures.people:
		if String(person.role)=="General" and String(person.status)=="living":return person
	return {}

func test_bands_are_grouped_under_their_leaders_and_can_be_moved()->void:
	# The war leader at home first (a general may hold that place), then a
	# field general of their own for band 1.
	MilitaryCampaign.home_army["commander"]=MilitaryCampaign._marshal_commander()
	var led:Dictionary=WorldSimulation.figures.commander(MilitaryCampaign._acting_field_commander(false),"army_1")
	var general:Dictionary=WorldSimulation.figures.by_id(String(led.figure_id))
	assert_dict(general).is_not_empty()
	assert_str(String(led.figure_id)).is_not_equal(Commands.war_leader_figure(MilitaryCampaign))
	MilitaryCampaign.field_armies.assign([_band(1,12,led),_band(2,8,MilitaryCampaign._marshal_commander())])
	var commands:=Commands.commands(MilitaryCampaign)
	var by:={}
	for c:Dictionary in commands:by[String(c.id)]=c
	assert_array(by[String(general.id)].bands).is_equal([1])
	assert_array(by[Commands.WAR_LEADER].bands).is_equal([2])
	assert_int(int(by[String(general.id)].men)).is_equal(12)
	# Band 2 under the general: both bands are theirs, with their skills.
	var moved:=Commands.assign(MilitaryCampaign,2,String(general.id))
	assert_bool(bool(moved.get("ok",false))).is_true()
	assert_str(String(moved.message)).contains(String(general.name))
	var band2:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(2)]
	assert_str(String(band2.commander.figure_id)).is_equal(String(general.id))
	assert_float(float(band2.commander.tactics)).is_equal_approx(float(led.tactics),0.01)
	by={}
	for c:Dictionary in Commands.commands(MilitaryCampaign):by[String(c.id)]=c
	assert_array(by[String(general.id)].bands).is_equal([1,2])
	assert_int(int(by[String(general.id)].men)).is_equal(20)
	assert_array(by[Commands.WAR_LEADER].bands).is_empty()
	# Band 1 back to the war leader: the general's slot is free again.
	assert_bool(bool(Commands.assign(MilitaryCampaign,1,Commands.WAR_LEADER).get("ok",false))).is_true()
	var band1:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(1)]
	assert_str(String(band1.commander.get("figure_id",""))).is_equal(Commands.war_leader_figure(MilitaryCampaign))
	assert_bool(WorldSimulation.figures.assignments.has("army_1")).is_false()
	assert_str(Commands.leader_of(band1)).is_equal(Commands.WAR_LEADER)

func test_nobody_leads_a_band_they_cannot()->void:
	MilitaryCampaign.home_army["commander"]=MilitaryCampaign._marshal_commander()
	MilitaryCampaign.field_armies.assign([_band(3,10,MilitaryCampaign._marshal_commander())])
	assert_str(String(Commands.assign(MilitaryCampaign,3,"nobody").get("error",""))).contains("no such general")
	assert_str(String(Commands.assign(MilitaryCampaign,9,Commands.WAR_LEADER).get("error",""))).contains("no such band")
	var general:=WorldSimulation.figures.by_id(String(WorldSimulation.figures.commander(MilitaryCampaign._acting_field_commander(false),"army_7").figure_id))
	general["status"]="wounded"
	assert_str(String(Commands.assign(MilitaryCampaign,3,String(general.id)).get("error",""))).contains("cannot lead")
	general["status"]="living"

func test_a_generals_record_counts_their_battles()->void:
	MilitaryCampaign.home_army["commander"]=MilitaryCampaign._marshal_commander()
	var led:Dictionary=WorldSimulation.figures.commander(MilitaryCampaign._acting_field_commander(false),"army_1")
	var general:Dictionary=WorldSimulation.figures.by_id(String(led.figure_id))
	var ours:={"name":"Band 1","commander":led,"remaining_troops":10}
	var theirs:={"name":"Their host","commander":{},"remaining_troops":2}
	WorldSimulation.figures.record_battle({"seed":11,"round_count":3,"outcome":"attacker_victory","attacker":ours,"defender":theirs,"termination":{"defeated":"Their host"}})
	WorldSimulation.figures.record_battle({"seed":12,"round_count":4,"outcome":"defender_victory","attacker":ours,"defender":theirs,"termination":{"defeated":"Band 1","commander_fate":"escaped"}})
	var leader:={}
	for l:Dictionary in Commands.leaders(MilitaryCampaign):
		if String(l.id)==String(general.id):leader=l
	var record:=Commands.record(leader)
	assert_int(int(record.battles)).is_equal(2)
	assert_int(int(record.won)).is_equal(1)
	assert_int(int(record.lost)).is_equal(1)
	# The war leader at home is listed first.
	assert_str(String(Commands.leaders(MilitaryCampaign)[0].id)).is_equal(Commands.WAR_LEADER)

func test_the_leaders_screen_lists_commands_and_moves_bands()->void:
	MilitaryCampaign.home_army["commander"]=MilitaryCampaign._marshal_commander()
	var led:Dictionary=WorldSimulation.figures.commander(MilitaryCampaign._acting_field_commander(false),"army_1")
	MilitaryCampaign.field_armies.assign([_band(1,12,led),_band(2,8,MilitaryCampaign._marshal_commander())])
	var Board:=preload("res://scripts/hud/leaders_board.gd")
	var board:VBoxContainer=auto_free(Board.new())
	add_child(board)
	board.setup({})
	# A row per command, the war leader first, and the chosen one's file.
	assert_object(board.find_child("Leader_war_leader",true,false)).is_not_null()
	assert_object(board.find_child("Leader_%s" % String(led.figure_id),true,false)).is_not_null()
	for key in ["supply","gear","will","pace"]:assert_object(board.find_child("Tile_%s" % key,true,false)).is_not_null()
	# The general's file: their band; then band 2 put under them.
	board.chosen=String(led.figure_id);board.refresh(true)
	assert_object(board.find_child("Band_1",true,false)).is_not_null()
	board._move(2,String(led.figure_id))
	assert_str(board.feedback.text).contains("now serves under")
	assert_object(board.find_child("Band_2",true,false)).is_not_null()
	# Many bands read by kit and place.
	var groups:=Board.grouped([{"kinds":[{"unit":"spearman","weapon":"spear"}],"doing":"at Eldwick","men":10,"full":12},{"kinds":[{"unit":"spearman","weapon":"spear"}],"doing":"at Eldwick","men":8,"full":12}])
	assert_int(groups.size()).is_equal(1)
	assert_int(int(groups[0].count)).is_equal(2)
	assert_int(int(groups[0].men)).is_equal(18)
	# The tiles say the engine's numbers.
	var tiles:=Board.tile_specs({"bands":2,"men":20,"full":24,"issued":20,"required":24,"will":0.5,"supply":1.0,"hungry":0,"breaking":0,"marching":1,"missing":{"spear":4},"worst":"well"},[],0.5,false)
	assert_str(String(tiles[2].line)).contains("a day in camp")
	assert_str(String(tiles[1].line)).contains("short 4")


func test_each_command_wears_its_own_colour()->void:
	assert_bool(Commands.color(Commands.WAR_LEADER)==Commands.WAR_LEADER_COLOR).is_true()
	assert_bool(Commands.color("")==Commands.WAR_LEADER_COLOR).is_true()
	var a:=Commands.color("figure_5151_3");var b:=Commands.color("figure_5151_4")
	assert_bool(a==b).is_false()
	assert_bool(Commands.color("figure_5151_3")==a).is_true()
	# No command is red: red is theirs.
	for c:Color in Commands.PALETTE:assert_bool(c.r>c.g+0.15 and c.r>c.b+0.15).is_false()
	# An army bar card's command: its general, its group's key, or the war leader.
	assert_str(Commands.leader_of_card({"id":"general:figure_5151_3"})).is_equal("figure_5151_3")
	assert_str(Commands.leader_of_card({"id":"general:war_leader"})).is_equal(Commands.WAR_LEADER)
	assert_str(Commands.leader_of_card({"id":"army:2","general":{"figure_id":""}})).is_equal(Commands.WAR_LEADER)
