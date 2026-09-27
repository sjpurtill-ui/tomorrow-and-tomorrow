extends GdUnitTestSuite
## Round three of war on the map: forces are inked marks that evolve with
## their size and age (a spear tally, a leader's standard, a framed standard,
## a staff-map box), sized in screen space per zoom band, giving way to the
## front and to corps and army-group marks when crowded, with a plain paper
## card: the right noun, the strength rounded, the general, what the force is
## doing, and the report's age only when it matters. Enemy marks come only
## from what was seen, and fade as the sighting ages.
const Marks:=preload("res://scripts/hud/army_marks.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Presentation:=preload("res://scripts/warfare_map_presentation.gd")
const Icons:=preload("res://scripts/resource_icons.gd")

## Staff-room and ledger words that must never reach a card.
const JARGON:=["LAST REPORT","DAYS OLD","SOLDIERS","READY","SUPPLY","OBSERVED DAY","CLICK","FIELD ARMY","FOREIGN FORMATION","YOU ","%","~","•"]


static func _jargon_in(text:String)->String:
	for word in JARGON:
		if word in text: return word
	# A compact count ("6.0K", "1.2M", "12.00B").
	var compact:=RegEx.create_from_string("\\d(\\.\\d+)?[KMB]\\b")
	if compact.search(text)!=null: return "compact count"
	# Shouted words (all capitals, four letters or more).
	var shout:=RegEx.create_from_string("\\b[A-Z]{4,}\\b")
	var found:=shout.search(text)
	if found!=null: return found.get_string()
	return ""


# --- Words by size and era -----------------------------------------------------------

func test_the_noun_follows_the_size_of_the_force_and_its_age()->void:
	assert_str(Marks.noun(12,"hearth")).is_equal("band")
	assert_str(Marks.noun(120,"hearth")).is_equal("war party")
	assert_str(Marks.noun(3000,"hearth")).is_equal("host")
	assert_str(Marks.noun(30000,"hearth")).is_equal("great host")
	assert_str(Marks.noun(3000,"lettered")).is_equal("host")
	assert_str(Marks.noun(30000,"lettered")).is_equal("army")
	# The printed ages: regiments with powder, corps once they can be formed.
	assert_str(Marks.noun(3000,"reckoned",0)).is_equal("host")
	assert_str(Marks.noun(3000,"reckoned",1)).is_equal("regiment")
	assert_str(Marks.noun(30000,"reckoned",1,false)).is_equal("army")
	assert_str(Marks.noun(30000,"reckoned",1,true)).is_equal("corps")
	# Rifles and motors: the staff's own echelons.
	assert_str(Marks.noun(800,"reckoned",2)).is_equal("battalion")
	assert_str(Marks.noun(3000,"reckoned",2)).is_equal("brigade")
	assert_str(Marks.noun(12000,"reckoned",2)).is_equal("division")
	assert_str(Marks.noun(40000,"reckoned",3)).is_equal("corps")
	assert_str(Marks.noun(150000,"reckoned",3)).is_equal("army")
	# No age calls thirty thousand a band.
	for stage in ["hearth","lettered","reckoned"]:
		for era in 4: assert_str(Marks.noun(30000,stage,era,true)).is_not_equal("band")


func test_the_mark_evolves_from_spear_tally_to_staff_box()->void:
	assert_str(Marks.kind(12,"hearth")).is_equal("band")
	assert_str(Marks.kind(3000,"hearth")).is_equal("host")
	assert_str(Marks.kind(30000,"hearth")).is_equal("host")
	assert_str(Marks.kind(3000,"lettered")).is_equal("host")
	assert_str(Marks.kind(30000,"lettered")).is_equal("army")
	assert_str(Marks.kind(3000,"reckoned",2)).is_equal("formation")
	assert_str(Marks.kind(20000,"reckoned",0,true)).is_equal("formation")
	assert_int(Marks.tally(12)).is_less(Marks.tally(200))
	assert_int(Marks.echelon_marks(3000)).is_less(Marks.echelon_marks(90000))
	# Every mark is drawn by the icon engine, with ink and a halo, no assets.
	for kind in ["band:2","band:5","host","army","formation"]:
		for branch in ["foot","horse","missile","guns","engineers","motor","armour"]:
			var texture:=Icons.army_texture(kind,branch,Color("#2b2118"),Color("#4f9bb8"))
			assert_int(texture.get_width()).is_equal(64)
			var image:=texture.get_image()
			var inked:=0
			for y in range(0,64,2):
				for x in range(0,64,2):
					if image.get_pixel(x,y).a>0.5: inked+=1
			assert_int(inked).is_greater(40)
	# Owner colour is an accent, not the mark: most of a standard is ink or paper.
	var host:=Icons.army_glyph("host","foot",Color.BLACK,Color.RED)
	var accented:=host.filter(func(p:Dictionary)->bool: return (p.col as Color)==Color.RED)
	assert_int(accented.size()).is_equal(1)


func test_strength_is_rounded_the_way_a_clerk_would_say_it()->void:
	assert_str(Marks.about(12)).is_equal("12")
	assert_str(Marks.about(37)).is_equal("about 35")
	assert_str(Marks.about(243)).is_equal("about 240")
	assert_str(Marks.about(6240)).is_equal("about 6,200")
	assert_str(Marks.about(30000)).is_equal("about 30,000")
	assert_str(Marks.about(29_600)).is_equal("about 30,000")
	assert_str(Marks.about(243_000)).is_equal("about 240,000")
	assert_str(Marks.about(1_240_000)).is_equal("about 1.2 million")
	assert_str(Marks.about(3_000_000_000)).is_equal("about 3 billion")
	assert_str(Marks.about_range(900,1500)).is_equal("900 to 1,500")
	assert_str(Marks.about_range(1000,1200)).is_equal("about 1,100")
	assert_str(Marks.about_range(0,0)).is_equal("numbers unknown")


func test_a_report_says_its_age_only_when_it_matters()->void:
	assert_str(Marks.age_words(0)).is_equal("")
	assert_str(Marks.age_words(1)).is_equal("")
	assert_str(Marks.age_words(3)).is_equal("reported three days ago")
	assert_str(Marks.age_words(20)).is_equal("reported 20 days ago")
	assert_str(Marks.age_words(90,"seen")).is_equal("seen about three months ago")


func test_what_a_force_is_doing_is_said_plainly()->void:
	assert_str(Marks.doing({"status":"moving","destination_name":"TSAREN"})).is_equal("marching on Tsaren")
	assert_str(Marks.doing({"status":"moving","destination_name":"MARKED GROUND","delta":Vector2(1,0)})).is_equal("marching east")
	assert_str(Marks.doing({"status":"moving","destination_name":"Commanded ground","delta":Vector2(0,-1)})).is_equal("marching north")
	assert_str(Marks.doing({"status":"moving","destination_name":"INTERCEPT · Cedar League"})).is_equal("going after Cedar League")
	assert_str(Marks.doing({"status":"moving","destination_id":"player_home","destination_name":"Home"})).is_equal("marching home")
	assert_str(Marks.doing({"status":"stationed","command_status":"Engaging · escape routes cut"})).is_equal("fighting, their way out cut")
	assert_str(Marks.doing({"status":"stationed","command_status":"Holding contact and seeking support"})).is_equal("holding the line, asking for help")
	assert_str(Marks.doing({"status":"stationed","location_name":"Alder Ford"})).is_equal("holding at Alder Ford")
	assert_str(Marks.doing({"status":"stationed","at_home":true})).is_equal("at home")
	assert_str(Marks.doing({"withdrawing":true,"status":"moving","destination_name":"Tsaren"})).is_equal("falling back home")
	assert_str(Marks.doing({"besieging":"TSAREN"})).is_equal("besieging Tsaren")
	assert_str(Marks.doing({"fighting":true,"status":"moving"})).is_equal("in battle")


func test_cards_name_the_force_its_strength_general_and_work_without_jargon()->void:
	var card:=Marks.card_ours({"troops":30000,"noun":"army","general":"Arno Kell","doing":"marching on Tsaren","report_age":0})
	assert_str(card[0]).is_equal("Arno's army, about 30,000")
	assert_str(card[1]).is_equal("Marching on Tsaren")
	card=Marks.card_ours({"troops":30000,"noun":"army","name":"Second Host","general":"Field staff","doing":"holding the line","report_age":3})
	assert_str(card[0]).is_equal("Second Host: an army of about 30,000")
	assert_str(card[1]).is_equal("Holding the line · reported three days ago")
	card=Marks.card_ours({"troops":12,"noun":"band","doing":"at home"})
	assert_str(card[0]).is_equal("Our band, 12")
	card=Marks.card_ours({"members":3,"members_troops":61000,"noun":"host"})
	assert_str(card[0]).is_equal("Three hosts of ours, about 61,000 in all")
	var theirs:=Marks.card_theirs({"low":5000,"high":7000,"noun":"army","owner":"Cedar League","moving":true,"age_days":4})
	assert_str(theirs[0]).is_equal("Cedar League army, 5,000 to 7,000")
	assert_str(theirs[1]).is_equal("On the move · seen four days ago")
	assert_str(Marks.card_theirs({"low":6000,"high":6000,"noun":"host","age_days":0})[1]).is_equal("")
	# Across ages, sizes, states and report ages, no card carries jargon.
	for stage in ["hearth","lettered","reckoned"]:
		for troops in [8,40,180,900,6000,30000,240000,3_000_000]:
			for age in [0,1,3,25,120]:
				for era in [0,2]:
					var word:=Marks.noun(troops,stage,era,true)
					for text in Array(Marks.card_ours({"troops":troops,"noun":word,"name":"Second Host","general":"Hena Vall","doing":Marks.doing({"status":"moving","destination_name":"TSAREN"}),"condition":"damaged","report_age":age}))+Array(Marks.card_theirs({"low":troops,"high":troops*2,"noun":word,"owner":"Cedar League","moving":true,"condition":"worn","age_days":age})):
						assert_str(_jargon_in(String(text))).override_failure_message("jargon in '%s'" % text).is_equal("")


func test_presentation_labels_are_plain_at_every_band_and_stage()->void:
	var army:={"army_id":7,"name":"First Field Army","troops":30000,"readiness":0.4,"supply_level":0.3,"status":"moving","destination_name":"TSAREN","destination_id":"tsaren","location_name":"HOME",
		"position":{"x":0.0,"z":0.0},"destination_position":{"x":5.0,"z":0.0},"report_age_days":6,"commander":{"name":"Arno Kell"},"formations":[{"unit":"levy","count":30000,"equipment_condition":0.4}]}
	var sighting:={"id":"f1","civilization":"Cedar League","identified":true,"hostile":true,"strength_estimate_low":900,"strength_estimate_high":1500,"damage_estimate":0.4,"position":{"x":3.0,"z":1.0}}
	var scout:={"id":"f2","identified":false,"carries_report":true,"strength_estimate_low":4,"strength_estimate_high":8,"position":{"x":2.0,"z":2.0}}
	for stage in ["hearth","lettered","reckoned"]:
		for camera in [2.0,48.0,320.0,3200.0]:
			var snapshot:=Presentation.build_snapshot(camera,[army,army.duplicate()],[sighting,scout],[],[],{},7,stage)
			for view in snapshot.player+snapshot.foreign:
				assert_str(_jargon_in(String(view.label))).override_failure_message("jargon in '%s'" % view.label).is_equal("")
	var single:=Presentation.player_marker(army,48.0,true)
	assert_str(String(single.label)).contains("Arno's")
	assert_str(String(single.label)).contains("reported six days ago")


# --- Screen-space size and crowding ---------------------------------------------------

func test_marks_are_sized_in_screen_space_by_zoom_band()->void:
	for kind in ["band","host","army","formation"]:
		assert_float(Marks.size_px("local",kind)).is_greater(Marks.size_px("regional",kind))
		assert_float(Marks.size_px("regional",kind)).is_greater(Marks.size_px("continental",kind))
		assert_float(Marks.size_px("continental",kind)).is_greater_equal(12.0)
		assert_float(Marks.size_px("world",kind)).is_equal(0.0)
		assert_float(Marks.size_px("local",kind)).is_less_equal(30.0)
	# The same force, drawn at two very different map scales in one band,
	# keeps the same size on screen.
	var sizes:Array=[]
	for scale in [60.0,4.0]:
		var overlay:Control=auto_free(Overlay.new())
		overlay.size=Vector2(1200,800)
		overlay.project=func(p:Vector2)->Vector2: return Vector2(600,400)+p*scale
		overlay.band_override="local"
		add_child(overlay)
		overlay.set_scene(Overlay.compose(_inputs()),true)
		overlay.queue_redraw()
		await await_idle_frame()
		await await_idle_frame()
		assert_bool((overlay.drawn_marks as Array).is_empty()).is_false()
		sizes.append(float(overlay.drawn_marks[0].size))
	assert_float(float(sizes[0])).is_equal(float(sizes[1]))


func _mark(id:String,side:String,at:Vector2,troops:int=2000,extra:Dictionary={})->Dictionary:
	var mark:={"id":id,"side":side,"at":at,"priority":troops,"kind":"host","size":24.0,"troops":troops,"army_id":int(id.get_slice(":",1)) if side=="ours" else -1}
	mark.merge(extra,true)
	return mark


func test_stacked_marks_become_one_and_cards_stay_within_budget()->void:
	var marks:Array=[]
	for k in 5: marks.append(_mark("ours:%d" % k,"ours",Vector2(300,300)+Vector2(k,0)))
	var laid:=Marks.layout(marks,{"band":"local","bounds":Rect2(0,0,1200,800)})
	assert_int((laid.drawn as Array).size()).is_equal(1)
	assert_int((laid.drawn[0].members as Array).size()).is_equal(5)
	assert_int(int(laid.drawn[0].members_troops)).is_equal(10000)
	# Ten separate forces: at most six cards close up, four regionally, none
	# wider; the selected force always has one.
	marks.clear()
	for k in 10: marks.append(_mark("ours:%d" % k,"ours",Vector2(100+k*90,300),1000+k,{"selected":k==0}))
	for band in ["local","regional","continental"]:
		var spread:=Marks.layout(marks,{"band":band,"bounds":Rect2(0,0,1200,800)})
		var cards:=(spread.drawn as Array).filter(func(e:Dictionary)->bool: return bool(e.card))
		assert_int(cards.size()).is_equal(int(Marks.CARDS.get(band,0)))
		if band!="continental": assert_bool(cards.any(func(e:Dictionary)->bool: return bool(e.get("selected",false)))).is_true()
	# Nothing is drawn at world scale; the fronts and army groups speak there.
	assert_int((Marks.layout(marks,{"band":"world"}).drawn as Array).size()).is_equal(0)


func test_marks_give_way_to_the_front_and_to_army_group_marks()->void:
	var front:=PackedVector2Array([Vector2(0,300),Vector2(1200,300)])
	var on_line:=_mark("ours:1","ours",Vector2(500,301))
	var theirs:=_mark("theirs:a","theirs",Vector2(800,299))
	var laid:=Marks.layout([on_line,theirs],{"band":"regional","bounds":Rect2(0,0,1200,800),"fronts":[front],"home":Vector2(500,700)})
	for entry in laid.drawn:
		var gap:=absf((entry.at as Vector2).y-300.0)
		assert_float(gap).is_greater_equal(float(entry.size)*0.5+3.9)
		assert_bool(bool(entry.moved)).is_true()
	# Ours step back toward home, theirs toward their side.
	var ours_entry:Dictionary=(laid.drawn as Array).filter(func(e:Dictionary)->bool: return e.side=="ours")[0]
	assert_float((ours_entry.at as Vector2).y).is_greater(300.0)
	# A corps mark stands for its armies: they give way to it (unless selected).
	var under:=_mark("ours:7","ours",Vector2(200,200))
	var chosen:=_mark("ours:8","ours",Vector2(600,200),2000,{"selected":true})
	var grouped:=Marks.layout([under,chosen],{"band":"continental","bounds":Rect2(0,0,1200,800),"echelons":[{"at":Vector2(400,200),"armies":[7,8]}]})
	assert_str(String(grouped.hidden.get("ours:7",""))).is_equal("echelon")
	assert_int((grouped.drawn as Array).size()).is_equal(1)
	# Opposing marks at one spot are pushed apart, never stacked together.
	var clash:=Marks.layout([_mark("ours:1","ours",Vector2(400,400)),_mark("theirs:a","theirs",Vector2(401,400))],{"band":"local","bounds":Rect2(0,0,1200,800)})
	assert_int((clash.drawn as Array).size()).is_equal(2)
	assert_float((clash.drawn[0].at as Vector2).distance_to(clash.drawn[1].at)).is_greater_equal(24.0)


func test_marks_are_bounded_however_many_forces()->void:
	var marks:Array=[]
	for k in 300: marks.append(_mark("ours:%d" % k,"ours",Vector2(20+(k%30)*38,20+(k/30)*38)))
	for k in 300: marks.append(_mark("theirs:%d" % k,"theirs",Vector2(30+(k%30)*38,30+(k/30)*38)))
	var laid:=Marks.layout(marks,{"band":"local","bounds":Rect2(0,0,1200,800)})
	var ours:=(laid.drawn as Array).filter(func(e:Dictionary)->bool: return e.side=="ours").size()
	var theirs:=(laid.drawn as Array).size()-ours
	assert_int(ours).is_less_equal(Marks.MAX_OURS)
	assert_int(theirs).is_less_equal(Marks.MAX_THEIRS)


# --- Observation honesty -------------------------------------------------------------------

func _inputs()->Dictionary:
	return {"mode":"front","stage":"reckoned","home":Vector2(-10,0),"today":100,
		"friendly":[{"id":"1","army_id":1,"pos":Vector2(0,-2),"strength":30000.0,"general":"Arno Kell","doing_context":{"status":"moving","destination_name":"Tsaren"}},{"id":"2","army_id":2,"pos":Vector2(0,2),"strength":4000.0}],
		"enemy":[{"id":"a","pos":Vector2(6,-2),"strength":6000.0,"low":5000,"high":7000,"age_days":0,"observed":true},{"id":"b","pos":Vector2(6,2),"strength":4000.0,"age_days":40}]}


func test_their_marks_come_only_from_what_was_seen_and_fade_with_age()->void:
	var built:=Overlay.compose(_inputs())
	var theirs:Array=(built.marks as Array).filter(func(m:Dictionary)->bool: return m.side=="theirs")
	assert_int(theirs.size()).is_equal(2)
	# Exactly where they were seen, never where they might be now.
	for mark in theirs:
		var seen:Dictionary=(_inputs().enemy as Array).filter(func(e:Dictionary)->bool: return e.id==mark.enemy_id)[0]
		assert_that(mark.pos).is_equal(seen.pos)
	# No sighting, no mark: an unseen host does not exist on the chart.
	var blind:=_inputs(); blind.enemy=[]
	assert_int((Overlay.compose(blind).marks as Array).filter(func(m:Dictionary)->bool: return m.side=="theirs").size()).is_equal(0)
	# Before writing, strangers are told as feuds, not as counters.
	var early:=_inputs(); early.stage="hearth"
	assert_int((Overlay.compose(early).marks as Array).filter(func(m:Dictionary)->bool: return m.side=="theirs").size()).is_equal(0)
	# Old sightings fade and are ringed with dashes, as the front's stale stretches.
	assert_float(Marks.fade(0)).is_equal(1.0)
	assert_float(Marks.fade(40)).is_less(Marks.fade(3))
	assert_float(Marks.fade(400)).is_greater_equal(0.35)
	var stale:Dictionary=theirs.filter(func(m:Dictionary)->bool: return m.enemy_id=="b")[0]
	assert_int(int(stale.age_days)).is_greater_equal(Marks.STALE_DAYS)
	assert_str(Marks.card_theirs(stale)[1]).is_equal("Seen 40 days ago")


# --- Selection and notes ------------------------------------------------------------------

func test_a_click_on_a_mark_selects_it_and_opens_the_generals_note()->void:
	var overlay:Control=auto_free(Overlay.new())
	overlay.size=Vector2(1200,800)
	overlay.project=func(p:Vector2)->Vector2: return Vector2(600,400)+p*60.0
	overlay.band_override="local"
	add_child(overlay)
	overlay.set_scene(Overlay.compose(_inputs()),true)
	overlay.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	var at:=overlay.mark_screen_position("ours","1") as Vector2
	assert_bool(at.is_finite()).is_true()
	var mark:Dictionary=overlay.mark_at(at)
	assert_str(String(mark.kind)).is_equal("army")
	assert_int(int(mark.army_id)).is_equal(1)
	assert_int(overlay._army_counter_at(at)).is_equal(1)
	# Their seen host opens a note about what was seen (the contact card
	# handles hosts still in sight).
	var there:=overlay.mark_screen_position("theirs","b") as Vector2
	var hit:Dictionary=overlay.mark_at(there)
	assert_str(String(hit.kind)).is_equal("sighting")
	var note:Dictionary=overlay.note_content(hit)
	assert_str(String(note.kicker)).starts_with("THEIR")
	assert_str(" ".join(note.lines)).contains("40 days ago")
	# Cards are lettered like the city cards: two lines, plain words, no jargon.
	var cards:=(overlay.placed_captions as Array).filter(func(c:Dictionary)->bool: return String(c.id).begins_with("mark:"))
	assert_int(cards.size()).is_greater(0)
	for card in cards: assert_str(_jargon_in(String(card.text))).is_equal("")
	assert_bool(cards.any(func(c:Dictionary)->bool: return "Arno's corps, about 30,000" in String(c.text) or "Arno's army, about 30,000" in String(c.text))).is_true()
