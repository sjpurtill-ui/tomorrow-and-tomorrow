extends GdUnitTestSuite
## THE CHRONICLE AS A COUNT OF YEARS (hud/chronicle_feed.gd,
## hud/chronicle_year_model.gd, chronicle_annals.gd, crisis_system.gd).
## The user: "Chronicle is too wordy and not visual enough, particularly given
## things like 'year of the dry season' are so repetitive."
## - a trouble that took no one never names its year; only a trouble that
##   filled graves does, and only that kind is counted when it comes again;
## - years named before this rule for a harmless trouble ("the eighth Dry
##   Year") are shown unnamed, with the trouble's small mark kept;
## - a shallow dry spell is carried by the people's custom (no court matter,
##   no card) and told in one line of its year; a deep one still comes to court;
## - the page draws a mark for every year, opens the newest, opens any year
##   chosen, and keeps the chosen year across a live refresh.
## Offline; never calls a real API.

const Chronicle:=preload("res://scripts/chronicle.gd")
const Annals:=preload("res://scripts/chronicle_annals.gd")
const Model:=preload("res://scripts/hud/chronicle_year_model.gd")
const Feed:=preload("res://scripts/hud/chronicle_feed.gd")
const Crisis:=preload("res://scripts/crisis_system.gd")


func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(90210)
	ForeignDiplomacy.ensure();ForeignDiplomacy.audiences.erase("lives")
	Chronicle.pending_cards.clear()
	GameState.chronicle={}
	GameState.ensure_population_total(100)


func _acc(year:int)->Dictionary:
	var a:=Annals._new_acc(year)
	a.pop0=100
	return a


func test_a_trouble_that_took_no_one_never_names_its_year()->void:
	var annals:Array=[]
	# A dry year that took no one: no name, the drought's mark.
	var dry:=_acc(3)
	(dry.crises as Array).append({"id":"c1","type":"drought","short":"the Dry Year","deaths":0,"ended":true,"silent":true})
	annals.append({"y":2,"name":"","kinds":["the Dry Year"],"types":["drought"],"deaths":0,"pop":100})
	var named:=Annals._name_year(dry,annals)
	assert_str(String(named.name)).is_equal("")
	assert_str(Annals._quiet_glyph(dry)).is_equal("drought")
	# A hunger that filled graves names its year.
	var hungry:=_acc(4)
	(hungry.crises as Array).append({"id":"c2","type":"hunger","short":"the Hungry Winter","deaths":3,"ended":true,"silent":true})
	var h:=Annals._name_year(hungry,annals)
	assert_str(String(h.name)).is_equal("the Hungry Winter")
	assert_str(String(h.glyph)).is_equal("hunger")
	# When it comes again and kills again, it is counted.
	annals.append({"y":4,"name":"the Hungry Winter","kinds":["the Hungry Winter"],"types":["hunger"],"deaths":3,"pop":100})
	var again:=_acc(9)
	(again.crises as Array).append({"id":"c3","type":"hunger","short":"the Hungry Winter","deaths":4,"ended":true,"silent":true})
	assert_str(String(Annals._name_year(again,annals).name)).is_equal("the second Hungry Winter")
	# The first flood is remembered even when it drowned no one.
	var flood:=_acc(10)
	(flood.crises as Array).append({"id":"c4","type":"flood","short":"the High Water","deaths":0,"ended":true,"silent":true})
	assert_str(String(Annals._name_year(flood,annals).name)).is_equal("the High Water")
	# A second harmless dry year is still no name, and never "the second Dry Year".
	var dry2:=_acc(11)
	(dry2.crises as Array).append({"id":"c5","type":"drought","short":"the Dry Year","deaths":0,"ended":true,"silent":true})
	assert_str(String(Annals._name_year(dry2,annals).name)).is_equal("")


func test_older_years_named_for_a_harmless_trouble_are_shown_unnamed()->void:
	# As the user's own save kept them.
	var harmless:={"y":40,"name":"the eighth Dry Year","kinds":["the Dry Year"],"crises":1,"deaths":0,"pop":91,"learned":3}
	assert_str(Annals.display_name(harmless)).is_equal("")
	assert_str(Annals.glyph_of(harmless)).is_equal("drought")
	var deadly:={"y":8,"name":"the Hungry Winter","kinds":["the Hungry Winter","the Dry Year"],"crises":2,"deaths":2,"pop":103}
	assert_str(Annals.display_name(deadly)).is_equal("the Hungry Winter")
	var person:={"y":56,"name":"the year Tilla died","lost":["Tilla of the Lake Shore"],"crises":0,"deaths":0,"pop":89}
	assert_str(Annals.display_name(person)).is_equal("the year Tilla died")
	assert_str(Annals.glyph_of(person)).is_equal("death")
	# The model recounts a deadly trouble among the names still shown.
	var c:={"entries":[],"annals":[
		{"y":0,"name":"the Dry Year","kinds":["the Dry Year"],"deaths":0,"pop":100},
		{"y":1,"name":"the second Dry Year","kinds":["the Dry Year"],"deaths":3,"pop":100},
		{"y":2,"name":"the third Dry Year","kinds":["the Dry Year"],"deaths":0,"pop":99}]}
	var years:=Model.build(c,3*365+10,99)
	assert_int(years.size()).is_equal(4)
	assert_str(String(years[0].name)).is_equal("")
	assert_str(String(years[1].name)).is_equal("the Dry Year")
	assert_str(String(years[2].name)).is_equal("")
	assert_str(Model.unnamed_words(years[2])).contains("no one died")
	assert_bool(bool(years[3].closed)).is_false()


## A day whose dry spell goes this deep at its worst (the world's own
## weather), or -1 when none is found.
func _day_with_depth(low:float,high:float)->int:
	for day in range(400,20000,17):
		var depth:=Crisis.drought_depth(day)
		if depth>=low and depth<high: return day
	return -1


func test_a_shallow_dry_spell_is_carried_by_custom_and_told_in_one_line()->void:
	GameState.settlement_founded_day=0
	Crisis.onsets_enabled=false
	var day:=_day_with_depth(0.0,0.17)
	assert_int(day).is_greater(0)
	GameState.elapsed_days=float(day)
	var x:=Crisis.inputs(day)
	x["weather_season"]=0.87; x["pop"]=100.0
	var matters:=(preload("res://scripts/audience_hall.gd").state().get("queue",[]) as Array).size()
	Crisis._open_drought(day,x)
	var c:=Crisis._active_of("drought")
	assert_bool(c.is_empty()).is_false()
	assert_bool(bool(c.get("quiet",false))).is_true()
	assert_str(String(c.choice)).is_equal("carry")
	# No court matter and no card.
	assert_int((preload("res://scripts/audience_hall.gd").state().get("queue",[]) as Array).size()).is_equal(matters)
	assert_int((GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool: return String(e.get("key","")).begins_with("crisis:")).size()).is_equal(0)
	for d in range(day+1,int(c.end_day)+2):
		GameState.elapsed_days=float(d)
		if (Crisis.state().active as Dictionary).has(String(c.id)): Crisis._advance(c,d,Crisis.inputs(d))
	var dry:Array=(Annals.acc(Chronicle.data(),int(GameState.elapsed_days)) as Dictionary).get("dry",[])
	assert_int(dry.size()).is_equal(1)
	var line:=preload("res://scripts/chronicle_years.gd").dry_line(dry,{"seed":1,"recent":{},"used":[]},false)
	assert_str(line).contains("parts in ten")
	Crisis.onsets_enabled=true


func test_a_deep_dry_season_still_comes_to_court()->void:
	GameState.settlement_founded_day=0
	Crisis.onsets_enabled=false
	var day:=_day_with_depth(0.21,0.6)
	if day<0: return # this world's weather never runs that dry
	GameState.elapsed_days=float(day)
	var x:=Crisis.inputs(day)
	x["weather_season"]=0.86; x["pop"]=100.0
	Crisis._open_drought(day,x)
	var c:=Crisis._active_of("drought")
	assert_bool(bool(c.get("quiet",false))).is_false()
	assert_bool(bool(c.get("severe",false))).is_true()
	Crisis.onsets_enabled=true


func _world_with_years()->void:
	var c:=Chronicle.data()
	c["annals"]=[
		{"y":0,"name":"","crises":0,"deaths":0,"learned":4,"pop":110,"km":0},
		{"y":1,"name":"the year Tilla died","lost":["Tilla of the Lake Shore"],"crises":0,"deaths":0,"learned":2,"pop":108,"km":0,"born":3,"buried":5,"glyph":"death"},
		{"y":2,"name":"","kinds":["the Dry Year"],"types":["drought"],"crises":1,"deaths":0,"learned":1,"pop":109,"km":800}]
	c["annal_year"]=2
	(c.entries as Array).push_front({"key":"annal:1","day":1*365+364,"tier":"notice","kind":"annal","title":"The year Tilla died","text":"Tilla of the Lake Shore died at 70."})
	(c.entries as Array).push_front({"key":"t:death","day":1*365+100,"tier":"moment","kind":"death","title":"Tilla of the Lake Shore Is Dead","text":"Tilla died aged 70."})
	(c.entries as Array).push_front({"key":"t:now","day":3*365+20,"tier":"notice","kind":"discovery","title":"Twisted Cordage","text":"Fibres twisted hold more."})
	GameState.elapsed_days=float(3*365+30)


func test_the_page_draws_every_year_and_opens_the_one_chosen()->void:
	_world_with_years()
	var dock:=preload("res://scripts/hud/content/dock_content_chronicle.gd").new(null,null)
	var block:Dictionary=(dock.tab(0).blocks as Array)[0]
	var feed:VBoxContainer=Feed.new()
	feed.size=Vector2(900,900)
	add_child(feed)
	feed.setup(block)
	await await_idle_frame()
	var count:Control=feed.find_child("YearCount",true,false)
	assert_object(count).is_not_null()
	assert_int((count.get("years") as Array).size()).is_equal(4)
	# The newest year opens first: the one in progress, which holds a tale.
	var kicker:Label=feed.find_child("Kicker",true,false)
	assert_str(kicker.text).contains("YEAR 4")
	assert_object(feed.find_child("Moment",true,false)).is_not_null()
	# The years are listed, newest first.
	assert_object(feed.find_child("Year2",true,false)).is_not_null()
	# Choosing a year opens it: its name, its facts as tokens, its moment.
	feed._choose(2)
	kicker=feed.find_child("Kicker",true,false)
	assert_str(kicker.text).is_equal("YEAR 2")
	assert_str((feed.find_child("YearName",true,false) as Label).text).is_equal("The year Tilla died")
	assert_object(feed.find_child("Fact",true,false)).is_not_null()
	# A live refresh keeps the chosen year.
	var state:Dictionary=feed.view_state()
	var again:VBoxContainer=Feed.new()
	again.size=Vector2(900,900)
	add_child(again)
	again.setup(block)
	again.restore_view_state(state)
	assert_str((again.find_child("Kicker",true,false) as Label).text).is_equal("YEAR 2")
	remove_child(feed); remove_child(again)
	feed.free(); again.free()
	await await_idle_frame()
