extends GdUnitTestSuite
## ONE TITLE AND ONE PLACE PER PERSON (scripts/person_posts.gd): Home's
## leader row, the Council and the War screen give the same words.
const Posts:=preload("res://scripts/person_posts.gd")
const Commands:=preload("res://scripts/leader_commands.gd")

func _world()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(716203);GameState.civic_api_enabled=false
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world();PeopleDirection.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_founded_day=0
	GameState.ensure_population_total(93)
	GameState.elapsed_days=31*365+120
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits"];GameState.settlement_site_committed=true;GameState.settlement_name="Seanstone"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()

func test_a_general_reads_as_the_war_screen_shows_them()->void:
	var figure:={"id":"fig_7","name":"Sahika Rilanu","role":"General","status":"living"}
	var idle:=[{"id":"fig_7","leader":{"figure_id":"fig_7"},"men":0,"places":{}}]
	assert_dict(Posts.of({"figure":figure},idle)).is_equal({"title":"General","place":"At home","group":"war"})
	var leading:=[{"id":"fig_7","leader":{"figure_id":"fig_7"},"men":340,"places":{"Tsaren":2,"the field":1}}]
	assert_str(String(Posts.of({"figure":figure},leading).place)).is_equal("In the field at Tsaren")
	# The war leader at home is called so, as on the War screen.
	var marshal:=[{"id":Commands.WAR_LEADER,"leader":{"figure_id":"fig_7"},"men":0,"places":{}}]
	assert_str(String(Posts.of({"figure":figure},marshal).title)).is_equal("War leader")
	assert_str(String(Posts.of({"figure":{"id":"a","role":"Architect"}}).title)).is_equal("Master builder")

func test_a_town_leader_has_one_title_on_home_and_in_council()->void:
	_world()
	var id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(id)
	assert_dict(leader).is_not_empty()
	var post:=Posts.of({"person_id":int(leader.person_id)})
	assert_str(String(post.title)).contains(GovernmentPeopleSystem.settlement_leader_title())
	assert_str(String(post.place)).is_equal(String(GameState.player_settlements[0].get("name","")))
	# Home's leader row says the same title.
	var words:=preload("res://scripts/hud/settlement_overview.gd")._office_words(leader)
	assert_str(words).starts_with(String(post.title)+", age ")
	# Every office they hold is in it, in the court's own words.
	for office:Dictionary in GovernmentPeopleSystem.active_offices():
		var holder:Variant=WorldSimulation.state.leadership_positions.get(String(office.key),{})
		if holder is Dictionary and int((holder as Dictionary).get("person_id",0))==int(leader.person_id):
			assert_str(String(post.title)).contains(String(office.title))
