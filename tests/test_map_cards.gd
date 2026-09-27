extends GdUnitTestSuite
## The map's own cards read plainly: paper and ink, 12 px or more, sentence
## case, no symbol codes, no raw day counts, no controls that do not exist,
## and nothing that throws away play without asking first.

const Card:=preload("res://scripts/hud/resource_survey_card.gd")
const Lens:=preload("res://scripts/hud/ground_lens.gd")
const Kit:=preload("res://scripts/hud/paper_kit.gd")
const Ticker:=preload("res://scripts/hud/map_ticker_words.gd")
const Notes:=preload("res://scripts/hud/map_notes.gd")
const Menu:=preload("res://scripts/hud/game_menu.gd")
const Caravans:=preload("res://scripts/hud/caravan_panel.gd")
const Contact:=preload("res://scripts/hud/content/dock_detail_map_contact.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

const BANNED:=["✓","○","◇","›","⌄","×","ACTIONS","RIGHT-CLICK CHARTED","TO MARCH","FOCUS CONVOY","POPULATION in the top bar","OPEN COUNCIL","WORLD > SCOUTING","personnel","Day ","day %"]

func _texts(node:Node)->Array[String]:
	var found:Array[String]=[]
	if node is Label and (node as Label).is_visible_in_tree():found.append((node as Label).text)
	if node is Button and (node as Button).is_visible_in_tree():found.append((node as Button).text)
	for child in node.get_children():found.append_array(_texts(child))
	return found

func _smallest_font(node:Node)->int:
	var smallest:=99
	if node is Label or node is Button:
		smallest=(node as Control).get_theme_font_size("font_size")
	for child in node.get_children():smallest=mini(smallest,_smallest_font(child))
	return smallest

func _assert_plain(texts:Array[String])->void:
	for text in texts:
		for banned in BANNED:
			assert_str(text).override_failure_message("'%s' contains '%s'" % [text,banned]).not_contains(banned)

func test_survey_card_uses_words_not_symbols_on_paper()->void:
	var card:ScrollContainer=auto_free(Card.new());add_child(card)
	card.show_survey([
		{"id":"a","resource":"Clay","distance_km":2.0,"knowledge":"indicated","quality":"unknown","abundance":"unknown","retrievable":false,"blockers":["deposit has not been surveyed"]},
		{"id":"b","resource":"Stone","distance_km":4.0,"knowledge":"surveyed","quality":"good","abundance":"common","retrievable":true,"blockers":[]},
	],{"id":"grassland","label":"open grassland","tree_cover":.09,"stone":"abundant","soil":"high","fiber":"scattered"},
	{"title":"Fresh water nearby","source_text":"Stream · 0.4 km W","reason":"Households can fetch water.","neighbors":{"title":"NO KNOWN NEIGHBOR","text":"Returned reports only."},"color":Color("8ed9ae")})
	await await_idle_frame()
	var texts:=_texts(card)
	assert_array(texts).contains(["Not surveyed","Workable","More"])
	_assert_plain(texts)
	assert_int(_smallest_font(card)).is_greater_equal(12)
	for entry:Dictionary in card.resource_cards:
		var state:Label=entry.state
		assert_float(T.contrast(state.get_theme_color("font_color"),T.PAPER_SUNK)).is_greater_equal(4.5)

func test_ground_accounts_use_seasons_and_plain_words()->void:
	var account:=Lens.foreign_settlement("The Reed People","a scout's telling",400)
	assert_str(account).contains(Kit.season_of_year(400))
	assert_str(account).not_contains("Day ")
	assert_str(account).not_contains("aggregate")
	assert_str(Lens.uncharted(false)).not_contains("UNCHARTED")
	assert_str(Lens.encounter("The Reed People",30,"Hunters met them at the ford")).contains("not where they live")
	assert_str(Lens.where_words({"kind":"inside","name":"Ashford","km":1.5})).is_equal("Inside Ashford, 1.5 km from its hearth")

func test_ticker_sentences_have_no_system_titles_or_dead_controls()->void:
	var lines:Array[String]=[
		Ticker.day_news([{"name":"Settled Villages"}],[],[],[]),
		Ticker.day_news([],[{"name":"Cordage"}],[],[]),
		Ticker.day_news([],[],[{"title":"Resource Flow Constrained","description":"The clay pits are working below what the potters need."}],[]),
		Ticker.inspection("uncharted",{}),
		Ticker.inspection("open",{"ground":"open grassland","site_committed":false}),
		Ticker.inspection("open",{"ground":"open grassland","site_committed":true}),
		Ticker.inspection("encounter",{"name":"the Reed People","home_known":false}),
	]
	for line in lines:
		assert_str(line).is_not_empty()
		assert_str(line).is_equal(T.sentence_case(line))
		assert_bool(line!=line.to_upper()).is_true()
	_assert_plain(lines)
	assert_str(Ticker.inspection("open",{"ground":"open grassland","site_committed":true})).contains("Found")
	assert_str(Kit.sentence("SETTLEMENT NOT STARTED")).is_equal("Settlement not started")
	assert_str(Kit.sentence("Tilla leads the caravan")).is_equal("Tilla leads the caravan")

func test_map_help_and_notices_name_only_real_controls()->void:
	for state in [[false,false,false],[true,true,false],[true,false,true],[true,false,false]]:
		var words:=Notes.help_words(state[0],state[1],state[2])
		_assert_plain([String(words.title),String(words.body)])
		assert_bool(String(words.title)!=String(words.title).to_upper()).is_true()
	var road:=Notes.road_words("Tilla","The ford is high; we will camp a day.")
	assert_str(road).contains("court")
	assert_str(road).not_contains("OPEN COUNCIL")
	assert_str(Notes.alert_title(true,1,200)).contains(preload("res://scripts/hud/era_words.gd").when(200))
	assert_str(Notes.alert_title(true,1,200)).not_contains("DAY")

func test_first_contact_alert_is_paper_and_opens_the_court()->void:
	var layer:CanvasLayer=auto_free(CanvasLayer.new());add_child(layer)
	var alert:=Notes.build_alert(layer,Vector2(1600,900),func():pass,func():pass,func():pass)
	(alert.panel as Control).visible=true
	await await_idle_frame()
	var texts:=_texts(alert.panel)
	assert_array(texts).contains(["Show on map","Speak with them","Later"])
	assert_array(texts).not_contains(["OPEN WORLD","DISMISS","SHOW MAP"])
	assert_int(_smallest_font(alert.panel)).is_greater_equal(12)

func test_game_menu_words_are_plain_and_confirm_before_discarding_play()->void:
	assert_str(Menu.saved_words({})).is_equal("Nothing has been saved yet.")
	var saved:=Menu.saved_words({"settlement_name":"Ashford","elapsed_days":500,"population":140})
	assert_str(saved).contains(Kit.season_of_year(500))
	assert_str(saved).not_contains("day ")
	for combo in [[true,true],[true,false],[false,false]]:
		var words:=Menu.ai_words(combo[0],combo[1])
		assert_str(String(words.status)).not_contains("AI ·")
		assert_str(String(words.status)).not_contains("Terra")
	var host:Control=auto_free(Control.new());add_child(host)
	host.size=Vector2(1280,720)
	var ran:=[false]
	var dialog:=Menu.confirm(host,"Restart this world?","Everything since then is lost.","Restart",func():ran[0]=true)
	await await_idle_frame()
	assert_bool(ran[0]).is_false()
	(dialog.find_child("KeepPlaying",true,false) as Button).pressed.emit()
	assert_bool(ran[0]).is_false()
	var again:=Menu.confirm(host,"Restart this world?","Everything since then is lost.","Restart",func():ran[0]=true)
	(again.find_child("ConfirmYes",true,false) as Button).pressed.emit()
	assert_bool(ran[0]).is_true()

func test_settler_card_is_one_card_with_send_them()->void:
	var host:Control=auto_free(Control.new());add_child(host)
	host.size=Vector2(1280,720)
	var card:=Caravans.open_settler_card(host,{"name":"Waterford","origin_name":"Ashford","leader":"Tilla","leader_summary":"Seasoned on the road","people":40,"food_days":40.0,"journey":"6 days","distance_km":24.0,"supplies":"40.0 timber","water_title":"Fresh water nearby","water_text":"Stream · 0.4 km W.","ready":true,"advice":"Tilla: enough for the march."},func():pass,func():pass)
	await await_idle_frame()
	var texts:=_texts(card.overlay)
	assert_array(texts).contains(["Send them","Choose other land","Who goes","Journey","They carry"])
	assert_bool((card.send as Button).disabled).is_false()
	assert_int(card.overlay.find_children("*","SpinBox",true,false).size()).is_equal(0)
	assert_int(card.overlay.find_children("*","OptionButton",true,false).size()).is_equal(0)
	_assert_plain(texts)

func test_map_contact_card_asks_the_general_without_direct_orders()->void:
	var provider:=Contact.new(null,null,"nobody")
	var meta:=provider.meta()
	assert_str(String(meta.eyebrow)).is_equal("Strangers in sight")
	var source:=FileAccess.get_file_as_string("res://scripts/hud/content/dock_detail_map_contact.gd")
	for forbidden in ["MOVE TO INTERCEPT","ENGAGE NOW","CAPTURE SCOUTS","ATTACK SCOUTS","SELECT NEAREST","1. Select","WAR PLANNING opens"]:
		assert_str(source).not_contains(forbidden)
	var lost:=provider.tab(0)
	assert_str(String(lost.brief.title)).is_equal("Out of sight")

func test_chronicle_lines_on_the_ticker_are_calm_sentences()->void:
	# The line the player saw: an era label and a shouted title.
	var shouted:="HEARTH-TALE: ROVIK'S BAND TOOK TSAREN  •  Tsaren is ours. Rovik left 17 fighters to hold it. One more is still with Rovik."
	var calm:=Kit.calm_line(shouted)
	assert_str(calm).not_contains("HEARTH-TALE")
	assert_str(calm).not_contains("•")
	assert_str(calm).starts_with("Rovik's band took tsaren.")
	assert_str(calm).contains("Tsaren is ours.")
	# The ticker's own Chronicle line never carries the label in the first place.
	var saved:Dictionary=GameState.chronicle
	GameState.chronicle={"version":9999,"entries":[{"key":"t","day":10,"tier":"notice","kind":"story","title":"Rovik's band took Tsaren","text":"Tsaren is ours. Rovik left 17 fighters to hold it. One more is still with Rovik."}],"firsts":{},"keys":{},"moment_days":[],"moment_ids":{}}
	var line:=Ticker.latest_telling()
	GameState.chronicle=saved
	assert_str(line).is_equal("Rovik's band took Tsaren: Tsaren is ours.")
	# And the paper slip turns anything shouted into the calm line.
	var label:Label=auto_free(Label.new())
	preload("res://scripts/hud/map_ticker_style.gd").style(label)
	label.text=shouted
	preload("res://scripts/hud/map_ticker_style.gd").fit(label,1600.0)
	assert_str(label.text).is_equal(calm)
	assert_int(label.get_theme_font_size("font_size")).is_greater_equal(14)
	assert_float(T.contrast(label.get_theme_color("font_color"),T.PANEL_BG_SOLID)).is_greater_equal(4.5)
