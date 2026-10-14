extends "res://scripts/hud/content/dock_content_base.gd"
const Construction:=preload("res://scripts/settlement_construction.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Shelter:=preload("res://scripts/hud/shelter_status.gd")
const Upkeep:=preload("res://scripts/upkeep_warnings.gd")
const Tasks:=preload("res://scripts/manual_work.gd")
## What each building does, in the engine's numbers.
const Impact:=preload("res://scripts/building_impact.gd")
## The town's built fabric: homes by grade, roads, beauty, works, craft.
const Fabric:=preload("res://scripts/built_fabric.gd")
var selected_project:=""
var history_filter:=""
var history:RefCounted
## The defences card for this refresh (tab), read outside the town's stores.
var _defence:Dictionary={}
## What ten more builders would buy, for the "Set builders" tooltip.
var _ten_more:=""

## Individual buildings are drawn from each city's population and construction
## era; this dock shows what builders actually work on: the city's capacity and
## condition, its civic works, its infrastructure and its landmarks.
func meta()->Dictionary:
	return {"eyebrow":"CITIES & INFRASTRUCTURE","title":"Buildings","serif":true,"subtabs":["THE TOWN","CIVIC WORKS","INFRASTRUCTURE","LANDMARKS"]}
func tab(sub:int)->Dictionary:
	if sub==3:return preload("res://scripts/hud/content/dock_content_undertakings.gd").new(terrain,hud).tab(0)
	# The defences rise at the first town and are the whole people's: read
	# outside any one town's stores (home_defense.gd).
	var picked:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	_defence=_defence_card() if sub in [0,2] and GameState.settlement_site_committed and (picked.is_empty() or bool(picked.get("primary",false))) else {}
	if sub==2:return _infrastructure_tab()
	var page:Dictionary=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _city_tab() if sub==0 else _civic_tab()))
	return page

const ERAS:=["Founding","Foothold","Hamlet","Village","Local centre","Town","Mature town","Urban system","City","Historic city","Regional system","Industrial age","Metropolitan age"]

# --------------------------------------------------------------------------
# City: what goes up, what it gives, and what holds it up
# --------------------------------------------------------------------------

## The selected town as a strategy-game panel (hud/buildings_board.gd): a
## strip of four or five figures with bars, then one-line rows: what goes up
## now and next (the civic work, the defences' next stage with its bill as
## pips and a Build button, new homes, the landmark), where every builder
## works (built_fabric.gd crews()), the built fabric with what each part
## does, and what the people are close to learning to build. Sentences wait
## in the tooltips. Every figure is the engine's own: the work and housing
## rules (settlement_construction.gd), the repair facts (upkeep_warnings.gd),
## the town's form, era checks and capacities (SettlementModel), what each
## work does (building_impact.gd), the defence ledger with the rule every
## people follows (home_defense.gd) and the fabric (built_fabric.gd).
func _city_tab()->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var housing:=Construction.housing()
	var crews:=_crews()
	if not GameState.settlement_site_committed or GameState.convoy_traveling:
		var home:=_home_row(housing);home["section"]="next"
		return {"brief":_now_brief(city,{},housing,crews),"blocks":[{"type":"town_works","board":true,"sections":[{"id":"next","heading":String(city.get("name","Founding camp")),"span":true}],"cards":[home]}]}
	var project:=_now_project(city)
	var cards:Array=[]
	# The figures in the strip travel with the page as hidden rows (their
	# words and tooltips), read by the strip and the tests.
	for card:Dictionary in [_home_row(housing),_builders_row(crews),_condition_row()]:
		card["section"]="kpi";cards.append(card)
	for card:Dictionary in _work_rows(city,project,crews):cards.append(_as_row(card,"next"))
	var just:=_just_built(city)
	if not just.is_empty():cards.append(_as_row(just,"next"))
	if not _defence.is_empty():cards.append(_defence_row(_defence))
	var homes_row:=_as_row(_new_homes_row(housing,crews),"next")
	for gain:Dictionary in homes_row.get("gains",[]):homes_row.detail="%s %s: %s → %s." % [String(homes_row.get("detail","")),String(gain.label),String(gain.before),String(gain.after)]
	homes_row.erase("gains")
	cards.append(homes_row)
	cards.append_array(_landmark_rows())
	cards.append_array(_crew_rows(crews))
	cards.append_array(_fabric_rows())
	# Its counts are in its pips: the row says no number twice.
	var workshops:=_as_row(_workshops_row(),"fabric");workshops.sub="";workshops.name="Workshops, stores";cards.append(workshops)
	var era:=_era_row(crews)
	if era.has("meter"):
		var level:=float(SettlementModel.city_form().get("tier",0.0))
		var next_era:=String(ERAS[mini(clampi(floori(level),0,ERAS.size()-1)+1,ERAS.size()-1)])
		# What it still needs rides as chips on the row's second line.
		var wants:PackedStringArray=[]
		for note:Dictionary in era.get("notes",[]):wants.append(String(note.text).get_slice(" (",0).to_lower())
		era.erase("notes")
		era.merge({"section":"soon","name":"Next: %s" % next_era,"sub":String(era.sub) if wants.is_empty() else ", ".join(wants.slice(0,2))+("…" if wants.size()>2 else ""),"value":"","bar":{"ratio":clampf(level-floorf(level),0.0,1.0),"color":Tokens.GOLD,"width":80}},true)
		era.erase("meter")
		cards.append(era)
	cards.append_array(_unlock_rows())
	var done:=GameState.settlement_completed.size()
	var total:=Construction._settlement_definitions().size()
	var sections:=[
		{"id":"next","heading":("%s: now and next" % String(city.get("name","The town"))) if GameState.player_settlements.size()>1 else "Building now and next","span":true,"note":("All %d civic works stand" % total) if project.is_empty() else "%d of %d civic works stand" % [done,total],"note_tip":"New civic works come as the people learn new ways to build: see Coming next."},
		{"id":"crews","heading":"Builders by job","actions":[{"label":"Set builders","tip":"How many of the people build, make and carry: The People."+(("
Ten more builders would give: %s." % _ten_more) if _ten_more!="" else ""),"on_press":jump("overview",0)}]},
		{"id":"fabric","heading":"The town's fabric"},
		{"id":"soon","heading":"Coming next"}]
	var page:={"kpis":_glance(housing,crews),"blocks":[{"type":"town_works","board":true,"sections":sections,"cards":cards}]}
	# A lead line only when something is wrong; a quiet town needs none.
	var brief:=_now_brief(city,project,housing,crews)
	page["brief"]=brief if String(brief.get("tone",""))!="info" else {}
	return page

## A town_works card as a board row in `section`, its progress as the row's
## bar and its state as a tag.
static func _as_row(card:Dictionary,section:String)->Dictionary:
	card["section"]=section
	var state:=String(card.get("state",""))
	if not card.has("tag"):
		match state:
			"building":card["tag"]={"text":"Building","tone":"good"}
			"waiting":card["tag"]={"text":"Waiting","tone":"warn"}
			"done":card["tag"]={"text":"Built","tone":"good"}
	return card

## The page's strip: homes, builders by job (one split bar), repair, the
## building era and a landmark under way, each the engine's own
## (housing(), crews, upkeep_warnings.gd facts, SettlementModel.city_form,
## great_works.gd works).
func _glance(h:Dictionary,crews:Dictionary)->Array:
	var tiles:Array=[]
	var home:=_home_row(h)
	var places:=int(h.places);var people:=int(h.people);var short:=int(h.short)
	tiles.append({"label":"HOMES","value":"%s places" % _n(places),"glance":true,"meter":clampf(float(people)/float(maxi(1,places)),0.0,1.0),"meter_color":Tokens.RED if short>0 else Tokens.GREEN,
		"delta":"%s sleep out" % _n(short) if short>0 else "%d%% filled · %s free" % [roundi(float(people)/float(maxi(1,places))*100.0),_n(maxi(0,places-people))],"delta_color":Tokens.RED if short>0 else Tokens.MUTED,"tip":"%s. %s" % [String(home.sub),String(home.detail)]})
	var split:=_crew_split(crews)
	var segments:Array=[]
	var words:PackedStringArray=[]
	for part:Dictionary in split:
		segments.append({"share":float(part.heads),"color":part.color,"label":String(part.label),"value":_n(roundi(float(part.heads)))})
		words.append("%s %s" % [_n(roundi(float(part.heads))),String(part.short)])
	var heads:=int(crews.heads)
	tiles.append({"label":"BUILDERS","value":_n(heads),"glance":true,"segments":segments,"delta":"%d per 1,000 people" % roundi(float(heads)*1000.0/maxf(1.0,float(GameState.population_total))) if heads>0 else "no one is building","delta_color":Tokens.MUTED if heads>0 else Tokens.RED,
		"tip":"\n".join(words) if heads>0 else "No one is building: works, repairs and new homes all stop.","on_press":jump("overview",0)})
	var repair:=_condition_row()
	tiles.append({"label":"CONDITION","value":String(repair.value),"glance":true,"meter":float((repair.meter as Dictionary).ratio),"meter_color":repair.accent,
		"delta":String(repair.sub).get_slice(":",0),"tip":"%s. %s" % [String(repair.sub),String(repair.detail)]})
	var form:Dictionary=SettlementModel.city_form()
	var tier:=clampi(floori(float(form.get("tier",0.0))),0,ERAS.size()-1)
	tiles.append({"label":"BUILDING ERA","value":ERAS[tier],"glance":true,"meter":float(tier+1)/float(ERAS.size()),"meter_color":Tokens.GOLD,
		"delta":"%d of %d eras" % [tier+1,ERAS.size()],"tip":"Later eras give the buildings more store room and better workshops, and cost more to keep up."})
	for work:Dictionary in preload("res://scripts/great_works.gd").works():
		if String(work.get("status","")) not in ["building","stalled"]:continue
		var left:=float(work.get("days_left",-1.0))
		tiles.append({"label":"LANDMARK","value":"%d%%" % roundi(float(work.get("progress",0.0))*100.0),"glance":true,"meter":float(work.get("progress",0.0)),"meter_color":Tokens.GOLD if String(work.status)=="building" else Tokens.RED,
			"delta":_left_words(left) if String(work.status)=="building" and left>=0.0 else "stalled","delta_color":Tokens.MUTED if String(work.status)=="building" else Tokens.RED,
			"tip":"%s: %s." % [String(work.get("name","A landmark")),String(work.get("stage",""))],"on_press":jump("construction",3)})
		break
	return tiles

## Every builder by what they do today, in heads: the town's own crews as the
## engine splits them (built_fabric.gd crews(): new homes, the civic work,
## repair, water and rail works, the walls, then fine work and upkeep), the
## share a landmark and military works take, and those away or hurt.
func _crew_split(crews:Dictionary)->Array:
	var heads:=float(crews.heads)
	if heads<=0.0:return []
	var town:=float(crews.town)
	var f:=Fabric.crews()
	var scale:=town/maxf(0.0001,float(f.builders))
	var parts:Array=[]
	var spec:=[["homes","Building homes","homes","homes",Tokens.GREEN,"Putting up new places while the town fills."],
		["civic","On the civic work","civic work","hall",Tokens.TEAL,"On the civic work in hand."],
		["repair","Repair","repair","repair",Tokens.MUTED,"Mending the town's works as they wear: %s builders' worth wanted." % _n(roundi(float(f.repair_want)*scale))],
		["infra","Water and rail works","water and rail","yard",Tokens.BLUE,"Building and keeping the water works, channels and rail."],
		["walls","On the walls","walls","palisade",Tokens.RED,"Raising and keeping the town's walls."],
		["fabric","Upkeep, fine work","fine work","builders",Tokens.GOLD,"Keeping homes, roads, work buildings and fine works, then raising them."]]
	for item in spec:
		var n:=float(f.get(String(item[0]),0.0))*scale
		if n<0.5:continue
		parts.append({"key":String(item[0]),"label":String(item[1]),"short":String(item[2]),"icon":String(item[3]),"color":item[4],"tip":String(item[5]),"heads":n})
	var landmark:=float(crews.landmark);var military:=float(crews.military)
	if landmark>=0.5:parts.append({"key":"landmark","label":"Landmark","short":"landmark","icon":"shrine","color":Tokens.VIOLET,"tip":"Raising the great work.","heads":landmark})
	if military>=0.5:parts.append({"key":"military","label":"Military works","short":"military","icon":"wall","color":Tokens.AMBER,"tip":"Building for the army.","heads":military})
	var away:=heads-town-landmark-military
	if away>=0.5:parts.append({"key":"away","label":"Away or hurt","short":"away or hurt","icon":"watchers","color":Tokens.TRACK,"tip":"Set to building but away from the town, hurt, or doing their share of other work.","heads":away})
	parts.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.heads)>float(b.heads))
	return parts

## The builders by job as rows: count, share bar and what the job is; the
## fine-work row says where its days went (built_fabric.gd report spent), and
## the last row what ten more builders would buy (plus_lines).
func _crew_rows(crews:Dictionary)->Array:
	var rows:Array=[]
	var heads:=float(crews.heads)
	if heads<=0.0:
		rows.append({"section":"crews","key":"crew_none","icon":"builders","name":"No one is building","sub":"Works, repairs and new homes all stop","value":"0","value_color":Tokens.RED,"tag":{"text":"Stopped","tone":"bad"}})
		return rows
	var spent:Dictionary=Fabric.report().spent
	for part:Dictionary in _crew_split(crews):
		var row:={"section":"crews","key":"crew_"+String(part.key),"icon":String(part.icon),"name":String(part.label),"value":_n(roundi(float(part.heads))),"value_width":56,
			"bar":{"ratio":float(part.heads)/heads,"color":part.color,"width":90},"sub":"%d%%" % roundi(float(part.heads)/heads*100.0),"detail":String(part.tip)}
		if String(part.key)=="fabric":
			var total:=0.0
			for key in ["upkeep","homes","roads","works","beauty"]:total+=float(spent.get(key,0.0))
			if total>0.0:
				var said:PackedStringArray=[]
				var chips:Array=[]
				for pair in [["upkeep","upkeep"],["homes","better homes"],["roads","roads"],["works","work buildings"],["beauty","fine works"]]:
					var part_share:=float(spent.get(String(pair[0]),0.0))/total
					if part_share<0.03:continue
					said.append("%s %d%%" % [String(pair[1]),roundi(part_share*100.0)])
					chips.append({"label":_upper_first(String(pair[1])),"value":"%d%%" % roundi(part_share*100.0),"tone":"plain","tip":"Their builder-days lately on %s." % String(pair[1])})
				row["effects"]=chips
				row.detail="%s Their days lately: %s." % [String(part.tip),", ".join(said)]
		rows.append(row)
	var more:Array=[]
	var nothing:=RegEx.create_from_string("^\\+?0(\\.0)?\\b|^(\\S+) to \\2$")
	for line:Dictionary in Fabric.plus_lines(10.0).slice(1):
		if nothing.search(String(line.value))!=null or more.size()>=3:continue
		more.append({"label":String(line.label),"value":String(line.value),"tone":String(line.get("tone","plain")),"tip":String(line.get("words",""))})
	_ten_more=", ".join(PackedStringArray(more.map(func(m:Dictionary)->String:return "%s %s" % [String(m.label).to_lower(),String(m.value)])))
	return rows

## The built fabric as rows with bars: homes by kind (one split bar), roads,
## beauty, work buildings, walls and stone, the builders' craft and the
## upkeep kept, each with what it does now (built_fabric.gd effect_lines).
const FABRIC_EFFECTS:={"homes":["Health","Illness deaths","Fire","Sickness breaking out","Holding together"],"roads":["Hauling","Between towns","Hauls from deposits"],
	"beauty":["Splendor","Love of the god","Allure abroad"],"works":["Makers' goods","Stored food rots","Cutting and digging","Water carried","Kilns"],
	"walls":["Defences","Might"],"craft":["Building knowledge","Great works"]}
func _fabric_rows()->Array:
	if not GameState.settlement_site_committed:return []
	var r:Dictionary=Fabric.report()
	var by_label:Dictionary={}
	for line:Dictionary in Fabric.effect_lines(r):by_label[String(line.label)]=line
	var homes:Array=r.homes
	var segments:Array=[]
	var kinds:PackedStringArray=[]
	for g in Fabric.GRADES.size():
		var share:=float(homes[g])
		if share<0.005:continue
		segments.append({"share":share,"color":Color(String(GRADE_INKS[g])),"label":String(Fabric.GRADE_SHORT[g]),"value":"%d%%" % roundi(share*100.0)})
		kinds.append("%s %d%%" % [String(Fabric.GRADE_SHORT[g]),roundi(share*100.0)])
	var best:=int(r.best)
	var caps:Array=r.caps
	var legend:="The best they can build now: %s, at most %d in 100 of the places at the builders' craft %s." % [String(Fabric.GRADE_WORDS[best]),roundi(float(caps[best])*100.0),Fabric._one(float(r.craft))]
	if best<Fabric.GRADES.size()-1:
		legend+=" %s need %s known and craft %s." % [String(Fabric.GRADE_WORDS[best+1]).capitalize(),_any_words(Fabric.GRADE_KNOW[best+1]),Fabric._one(float(Fabric.GRADE_CRAFT[best+1]))]
	legend+=" New places go up plain; builders raise them as they have hands, and unkept homes fall a grade."
	var declining:=Fabric.decline_words(r)
	var d:Dictionary=r.defense
	var rows:Array=[
		{"key":"fabric_homes","fx":"homes","icon":"homes","name":"Homes","sub":", ".join(kinds),"segments":segments,"value":"%d/100" % roundi(float(r.quality)*100.0),"detail":"Mean quality %d of 100 (windbreaks 0, huts 30, timber 55, mudbrick 75, stone 100). %s" % [roundi(float(r.quality)*100.0),legend]},
		{"key":"fabric_roads","fx":"roads","icon":"open","name":"Roads","sub":String(Fabric.ROAD_WORDS[int(r.road_kind)]),"bar":{"ratio":float(r.roads),"tick":float(r.road_cap),"color":Tokens.TEAL},"value":"%d/100" % roundi(float(r.roads)*100.0),
			"detail":"The road index; %s are the best the people know (up to %d, the tick). Roads wear %d in 100 a year unkept." % [String(Fabric.ROAD_WORDS[int(r.road_kind)]),roundi(float(r.road_cap)*100.0),roundi(Fabric.ROAD_WEAR*100.0)]},
		{"key":"fabric_beauty","fx":"beauty","icon":"shrine","name":"Beauty","sub":"","bar":{"ratio":float(r.beauty),"color":Tokens.GOLD},"value":"%d/100" % roundi(float(r.beauty)*100.0),
			"detail":"Fine works a person. Each builder-day of fine work is worth %s with what the people know of the arts. Unkept, they weather %d in 100 a year." % [Fabric._one(float(r.artistry)),roundi(Fabric.BEAUTY_WEAR*100.0)]},
		{"key":"fabric_works","fx":"works","icon":"workshop","name":"Work buildings","sub":"","bar":{"ratio":float(r.cover),"color":Tokens.BLUE},"value":"%d/100" % roundi(float(r.cover)*100.0),
			"detail":"How fully workshops, granaries, kilns, storehouses and water works serve the town."}]
	if bool(r.home):
		var bonus:=float(d.get("defense_bonus",0.0))
		rows.append({"key":"fabric_walls","fx":"walls","icon":"wall","name":"Walls and stone","sub":"%s · %d%% stone houses" % [String(d.get("short","Open ground")),roundi(float(r.stone)*100.0)],"bar":{"ratio":clampf(bonus/Fabric.BASTION_BONUS,0.0,1.0),"color":Tokens.RED},"value":"+%d%%" % roundi(bonus*100.0),
			"detail":"%s at %d%% repair, and %d in 100 of the places stone. The bar runs to a bastion network's +%d%%." % [String(d.get("short","Open ground")),roundi(float(d.get("integrity",1.0))*100.0),roundi(float(r.stone)*100.0),roundi(Fabric.BASTION_BONUS*100.0)]})
	rows.append({"key":"fabric_craft","fx":"craft","icon":"builders","name":"Builders' craft","sub":"settles at %s" % Fabric._one(float(r.craft_settles)),"bar":{"ratio":float(r.craft)/Fabric.CRAFT_MAX,"color":Tokens.VIOLET},"value":"%s/%d" % [Fabric._one(float(r.craft)),roundi(Fabric.CRAFT_MAX)],
		"detail":"The builders' living experience. At today's builders it settles at %s over a working life; it fades as the old builders die." % Fabric._one(float(r.craft_settles))})
	var kept:=float(r.paid)
	# All kept is the town's condition, already in the strip: the row shows
	# only when the builders fall behind.
	if not declining.is_empty():rows.append({"key":"fabric_upkeep","icon":"repair","name":"Upkeep kept","sub":"everything kept" if declining.is_empty() else ", ".join(declining),"bar":{"ratio":kept,"color":Tokens.GREEN if kept>=0.99 else Tokens.RED},"value":"%d%%" % roundi(kept*100.0),"value_color":Tokens.INK if kept>=0.99 else Tokens.RED,
		"tag":{} if declining.is_empty() else {"text":"Too few builders","tone":"bad"},
		"detail":"Every home, road, work building and fine work is kept." if declining.is_empty() else "The builders keep homes first, then the walls, work buildings, roads and fine works. Now %s. More builders, or fewer works to keep." % ", ".join(declining)})
	for row:Dictionary in rows:
		row["section"]="fabric"
		if (row.get("tag",{}) as Dictionary).is_empty():row.erase("tag")
		var effects:Array=[]
		var more:PackedStringArray=[]
		for label:String in FABRIC_EFFECTS.get(String(row.get("fx","")),[]):
			if not by_label.has(label):continue
			var line:Dictionary=by_label[label]
			if effects.size()<2:effects.append({"label":label,"value":String(line.value),"tone":String(line.get("tone","plain")),"tip":String(line.get("words",""))})
			else:more.append("%s %s: %s" % [label,String(line.value),String(line.get("words",""))])
		if not effects.is_empty():row["effects"]=effects
		if not more.is_empty():row.detail=String(row.detail)+"\n"+"\n".join(more)
	return rows

## The landmarks under way, each a row with its bar and the time left
## (great_works.gd works); a finished one lives on the Landmarks tab.
func _landmark_rows()->Array:
	var rows:Array=[]
	for work:Dictionary in preload("res://scripts/great_works.gd").works():
		var status:=String(work.get("status",""))
		if status not in ["building","stalled"]:continue
		var progress:=float(work.get("progress",0.0))
		var left:=float(work.get("days_left",-1.0))
		var building:=status=="building"
		rows.append({"section":"next","key":"landmark_"+String(work.get("work_id","")),"icon":"shrine","name":String(work.get("name","A great work")),
			"sub":"%s%s" % [String(preload("res://scripts/great_works_audience.gd").STAGE_WORDS.get(String(work.get("stage","")),"Landmark")),(" · "+_left_words(left)) if building and left>=0.0 else (" · "+String(work.get("idle",""))) if not building else ""],
			"bar":{"ratio":progress,"color":Tokens.GOLD if building else Tokens.RED},"value":"%d%%" % roundi(progress*100.0),
			"tag":{"text":"Rising" if building else "Idle","tone":"good" if building else "bad"},
			"actions":[{"label":"Open","tip":"The landmark's page: its odds, its builders and your choices.","on_press":jump("construction",3)}]})
	return rows

## What the people are close to learning that the builders would use: new
## civic works, better homes, roads, work buildings, the arts that make
## fine work worth more and new building eras, each with how far the
## question has come (discovery_progress) and whether a team is on it.
func _unlock_rows()->Array:
	var groups:Array=[]
	var known:Array=GameState.known_discoveries
	for definition:Dictionary in Construction._settlement_definitions():
		var id:=String(definition.get("discovery",""))
		if id.is_empty() or String(definition.name) in GameState.settlement_completed:continue
		if id in known:
			if DiscoverySystem.adoption(id)<0.10:groups.append({"ids":[id],"opens":String(definition.name),"icon":work_icon(String(definition.name)),"adopting":true})
			continue
		groups.append({"ids":[id],"opens":String(definition.name),"icon":work_icon(String(definition.name))})
	for g in range(1,Fabric.GRADES.size()):
		if Fabric._knows(Fabric.GRADE_KNOW[g]):continue
		groups.append({"ids":Fabric.GRADE_KNOW[g],"opens":String(Fabric.GRADE_WORDS[g]),"icon":"homes"})
		break
	var road:=Fabric.road_kind()+1
	if road<Fabric.ROAD_KINDS.size():groups.append({"ids":Fabric.ROAD_KINDS[road][0],"opens":String(Fabric.ROAD_WORDS[road]),"icon":"open"})
	for work:String in Fabric.WORKS_KNOW:
		var id:=String(Fabric.WORKS_KNOW[work])
		if not id.is_empty() and id not in known:groups.append({"ids":[id],"opens":String(Fabric.WORKS_WORDS[work]),"icon":"workshop"})
	var arts:Array=Array(Fabric.ARTISTRY).filter(func(id:Variant)->bool:return String(id) not in known)
	if not arts.is_empty():groups.append({"ids":arts,"opens":"Richer fine work","icon":"shrine","tip":"Each of these the people learn makes a builder-day of fine work worth +%s more." % Impact._two(Fabric.ARTISTRY_EACH)})
	var later:Array=[]
	for entry:Dictionary in preload("res://scripts/settlement_architecture_knowledge.gd").entries():
		if String(entry.id) not in known:later.append(String(entry.id))
	if not later.is_empty():groups.append({"ids":later,"opens":"Later building era","icon":"era"})
	var studying:Dictionary={}
	for channel in GameState.active_investigations:studying[String(GameState.active_investigations[channel])]=true
	var rows:Array=[]
	for group:Dictionary in groups:
		var best:="";var best_progress:=-1.0;var best_on:=false
		for id in group.ids:
			var entry:Dictionary=WorldSimulation.discovery.discovery_definition(String(id)) if WorldSimulation.discovery!=null else {}
			if entry.is_empty():continue
			var progress:=float(DiscoverySystem.adoption(String(id))) if bool(group.get("adopting",false)) else float(GameState.discovery_progress.get(String(id),0.0))
			var on:=studying.has(String(id))
			if (on and not best_on) or (on==best_on and progress>best_progress):best=String(id);best_progress=progress;best_on=on
		if best.is_empty():continue
		var begun:=best_progress>0.0005 or best_on
		# A question no one has begun is not "coming next".
		if not begun and not bool(group.get("adopting",false)):continue
		rows.append({"section":"soon","key":"soon_"+best,"icon":String(group.icon),"name":_upper_first(String(group.opens)),"sub":_discovery_name(best),
			"bar":{"ratio":clampf(best_progress,0.0,1.0),"color":Tokens.TEAL if best_on else Tokens.RULE_STRONG,"width":70},"value":"%d%%" % roundi(clampf(best_progress,0.0,1.0)*100.0) if begun else "",
			"tag":{"text":"Taking up","tone":"info"} if bool(group.get("adopting",false)) else ({"text":"Studying","tone":"info"} if best_on else ({} if begun else {"text":"Not begun","tone":"note"})),
			"detail":("The people know it; %d in 100 have taken it up (10 needed)." % roundi(best_progress*100.0)) if bool(group.get("adopting",false)) else ("%s: %d%% of the way to proof%s. It opens %s." % [_upper_first(_discovery_name(best)),roundi(best_progress*100.0)," and a team is on it" if best_on else ", no team on it yet",String(group.opens)])+(" "+String(group.tip) if group.has("tip") else ""),
			"_rank":(2.0 if best_on or bool(group.get("adopting",false)) else 0.0)+best_progress})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a._rank)>float(b._rank))
	rows=rows.slice(0,3)
	for row:Dictionary in rows:
		row.erase("_rank")
		if (row.tag as Dictionary).is_empty():row.erase("tag")
	return rows

## The defences' next stage as a row: what it gives (before -> after), its
## bill as pips against the store, what stops it, and the choice of who
## decides, Build first (home_defense.gd reading, via _defence_card).
func _defence_row(card:Dictionary)->Dictionary:
	var row:=card.duplicate(true)
	row["section"]="next"
	var r:=HomeDefense.reading()
	var next:Dictionary=r.next
	var building:Dictionary=r.building
	var status:=String(r.status)
	if not building.is_empty():row.name=String(building.get("short","Defences"))
	elif not next.is_empty():row.name=String(next.get("short","Defences"))
	else:row.name=String(r.short)
	# Rising: its own words; else what stands now, the state on the tag.
	if building.is_empty():
		row["sub"]="Defences, now %s" % String(r.short).to_lower()
		row.erase("value")
	var tags:={"building":["Building","good"],"stalled":["Stopped","bad"],"ready":["Ready","good"],"waiting":["Waiting","warn"],"held":["Held","warn"],"hungry":["Food short","bad"],"complete":["Built","good"]}
	if tags.has(status):row["tag"]={"text":String(tags[status][0]),"tone":String(tags[status][1]),"tip":_upper_first(String(card.get("sub","")))+"."}
	# The bar: the stage rising, else the danger the people read against
	# what the next stage needs (the tick).
	if card.get("progress") is Dictionary:row["bar"]=card.progress
	# The verb on the row: Build (the god's word "build now"); who else may
	# decide rides small on the second line, with any fix.
	var word:=String(r.word)
	if row.get("choice") is Dictionary:
		var others:Array=[]
		var short_labels:={"people":"People decide","hold":"Hold off"}
		for option:Dictionary in row.choice.options:
			if String(option.id)=="build":continue
			option.label=String(short_labels.get(String(option.id),option.label));others.append(option)
		row.choice={"selected":word,"options":others}
		row["actions"]=[{"label":"Build ordered" if word=="build" else "Build","primary":word!="build","pressed":word=="build","tip":String(HomeDefense.WORD_TIPS.build),"on_press":_set_defence_word.bind("build")}]
	if card.has("actions"):row["actions2"]=card.actions
	# A material short is already red in its pips: no second chip for it.
	var short:Dictionary={}
	for blocker:Dictionary in r.blockers:
		if String(blocker.get("kind",""))=="material":short[String(blocker.text)]=true
	row["blockers"]=(row.get("blockers",[]) as Array).filter(func(b:Dictionary)->bool:return not short.has(String(b.text)))
	return row

## Who builds: the builders set to it, those on the town's own works, and the
## share a landmark or military works take, in heads (GameState.workers_at:
## a great work's favour or a gifted builder makes each count for more, not
## more of them).
func _crews()->Dictionary:
	var heads:=maxi(0,int(GameState.population_allocations.get("Construction",0)))
	var town:=maxf(0.0,GameState.workers_at("Construction"))
	var with_military:=maxf(town,GameState.effective_workers("Construction",true,false,false,false,false))
	var landmark_share:=clampf(preload("res://scripts/undertaking_system.gd").share(GameState),0.0,0.95)
	return {"heads":heads,"town":town,"military":with_military-town,"landmark":with_military*landmark_share/(1.0-landmark_share)}

## The work the builders are on now; else the one they wait to start (your
## priority first, then the next known work whose earlier works stand), read
## as the Civic works list reads it. Empty when every known work is built.
func _now_project(city:Dictionary)->Dictionary:
	var current:=Construction._current_settlement_project()
	if not current.is_empty():return _project(current,current,false)
	var priority:=String(city.get("construction_priority",""))
	var waiting:Dictionary={}
	for definition:Dictionary in Construction._settlement_definitions():
		var title:=String(definition.name)
		if title in GameState.settlement_completed:continue
		var discovery:=String(definition.get("discovery",""))
		if not discovery.is_empty() and discovery not in GameState.known_discoveries:continue
		if title==priority:return _project(definition,current,false)
		var ready:=true
		for required in definition.requires:
			if String(required) not in GameState.settlement_completed:ready=false
		if ready and waiting.is_empty():waiting=definition
	return {} if waiting.is_empty() else _project(waiting,current,false)

## The dock's lead, in a line: what the builders are doing and how far, or
## what holds them up. The cards below carry the rest.
func _now_brief(city:Dictionary,project:Dictionary,_housing:Dictionary,crews:Dictionary)->Dictionary:
	if not GameState.settlement_site_committed:return {"tone":"info","title":"No town yet","why":"Building starts once the people choose where to settle."}
	if GameState.convoy_traveling:return {"tone":"info","title":"The people are on the move","why":"Building starts again when they settle."}
	if not String(city.get("occupied_by","")).is_empty():return {"tone":"danger","title":"Held by an enemy","why":"No one builds here until the town is free again."}
	if int(crews.heads)<=0:return {"tone":"danger","title":"No one is building","why":"Works, repairs and new homes stop. Set builders on The People."}
	if project.is_empty():return {"tone":"info","title":"Every work the people know is built","why":"New works come as the people learn new ways to build."}
	var title:=String(project.name)
	if bool(project.active):
		var pace:=_time_left(float(project.days_left)) if float(project.days_left)>=0.0 else "but "+_time_left(-1.0)
		return {"tone":"info","title":"Building the %s" % title,"why":"%d%% done, %s." % [roundi(float(project.progress)*100.0),pace]}
	return {"tone":"warn","title":"The builders are waiting","why":"Next is the %s, which %s." % [title,_lower_first(_first_blocker(project))]}

## What goes up now: the work in hand (or the one the builders wait on), and
## your priority if it waits.
func _work_rows(city:Dictionary,project:Dictionary,_crews_now:Dictionary)->Array:
	var rows:Array=[]
	var priority:=String(city.get("construction_priority",""))
	# Every known work built is one small note on the page, not a card.
	if project.is_empty():return rows
	rows.append(_work_card(project,priority))
	if not priority.is_empty() and not project.is_empty() and priority!=String(project.name) and priority not in GameState.settlement_completed:
		for definition:Dictionary in Construction._settlement_definitions():
			if String(definition.name)!=priority:continue
			var wanted:=_project(definition,{},false)
			var card:=_work_card(wanted,priority)
			card.merge({"key":"priority","name":"Your priority: %s" % priority,"sub":_first_blocker(wanted),"detail":"The builders work on what they can until it is ready."},true)
			rows.append(card)
	return rows

## One civic work: its bar and days left while it rises, what it gives (the
## engine's lines, building_impact.gd), its bill against the stores and what
## stops it.
func _work_card(project:Dictionary,priority:String)->Dictionary:
	var title:=String(project.name)
	var mine:=title==priority and not priority.is_empty()
	var card:={"key":"work","icon":work_icon(title),"name":title,"needs":_bill(project.inputs),"effects":_effects(project.get("impact",{})),"gains":_work_gains(title)}
	var progress:=float(project.progress)
	if bool(project.active):
		var inputs:PackedStringArray=[]
		for input:Dictionary in project.inputs:inputs.append("%s %s" % [Plain.number(float(input.required)),ResourceSystem.display_name(String(input.resource)).to_lower()])
		var stores:=(" The %s it takes %s in the stores." % [_and_list(Array(inputs)),"is" if inputs.size()==1 else "are"]) if not inputs.is_empty() else ""
		card.merge({"value":"%d%%" % roundi(progress*100.0),"value_color":Tokens.GREEN,"accent":Tokens.GREEN,"state":"building",
			"sub":("Your priority · " if mine else "")+_upper_first(_time_left(float(project.days_left))),
			"progress":{"ratio":progress,"text":_left_words(float(project.days_left)),"color":Tokens.GREEN},
			"detail":"When done it %s.%s" % [_gain(project),stores]},true)
		return card
	var more:PackedStringArray=[]
	for index in range(1,(project.blockers as Array).size()):more.append(_lower_first(String(project.blockers[index])))
	var also:=(" It also %s." % _and_list(Array(more))) if not more.is_empty() else ""
	var blockers:Array=[]
	for blocker:String in project.blockers:blockers.append({"text":blocker,"tone":"bad"})
	card.merge({"value":"Waiting","value_color":Tokens.AMBER,"accent":Tokens.AMBER,"state":"waiting","blockers":blockers,
		"sub":("Your priority · " if mine else "")+_first_blocker(project),
		"progress":{"ratio":progress,"text":"%d%% · waiting" % roundi(progress*100.0),"color":Tokens.AMBER},
		"detail":"When built it %s.%s" % [_gain(project),also]},true)
	return card

## A civic work's mark on the town board (resource_icons.gd town_glyph).
static func work_icon(title:String)->String:
	return String({"Hearth Circle":"hall","Lean-to Shelters":"homes","Storage Pits":"stores","Public Stores":"stores","Open Work Area":"workshop",
		"Gathering Yard":"yard","Framed Hall":"hall","Hearth Shrine":"shrine","Shrine House":"shrine"}.get(title,"hall"))

## A work's bill against the stores: [{resource, have, need}].
static func _bill(inputs:Array)->Array:
	var out:Array=[]
	for input:Dictionary in inputs:out.append({"resource":String(input.resource),"have":float(input.stored),"need":float(input.required)})
	return out

## What a work gives, in its first three lines (building_impact.gd): the
## figure on the card, the engine's sentence in its tooltip.
static func _effects(impact:Variant)->Array:
	var out:Array=[]
	if not impact is Dictionary:return out
	for line in ((impact as Dictionary).get("lines",[]) as Array).slice(0,3):
		out.append({"label":String(line.get("label","")),"value":String(line.get("value","")),"tone":String(line.get("tone","plain")),"tip":String(line.get("words",""))})
	return out

## The places a work adds, as the housing ledger will read once it stands.
static func _work_gains(title:String)->Array:
	if title!="Lean-to Shelters":return []
	var places:=int(GameState.housing_capacity)
	return [{"label":"Places","icon":"homes","before":_n(places),"after":_n(places+Construction.lean_to_places()),"tone":"good","tip":"The Lean-to Shelters add room for %s people." % _n(Construction.lean_to_places())}]

## The civic work finished here most lately, while it is fresh (within
## JUST_BUILT_DAYS): its builders' stamp and what it now does. {} if none.
const JUST_BUILT_DAYS:=30
func _just_built(city:Dictionary)->Dictionary:
	var id:=String(city.get("id",""))
	var titles:Array=[]
	for definition:Dictionary in Construction._settlement_definitions():titles.append(String(definition.name))
	var today:=int(GameState.elapsed_days)
	for index in range(GameState.building_ledger.size()-1,-1,-1):
		var row:Dictionary=GameState.building_ledger[index]
		if String(row.get("event",""))!="completed" or String(row.get("kind","")) not in titles:continue
		if not id.is_empty() and String(row.get("settlement_id",""))!="" and String(row.settlement_id)!=id:continue
		var ago:=today-int(row.get("day",-100000))
		if ago>JUST_BUILT_DAYS or ago<0:return {}
		var title:=String(row.kind)
		if title not in GameState.settlement_completed:return {}
		return {"key":"just_built","icon":work_icon(title),"name":title,"accent":Tokens.GREEN,"state":"done",
			"sub":"Finished %s" % ("today" if ago<1 else Plain.span_text(float(ago))+" ago"),"effects":_effects(Impact.work(title)),
			"stamp":{"text":"Built","tip":"The builders finished the %s %s." % [title,"today" if ago<1 else Plain.span_text(float(ago))+" ago"]},
			"detail":"It now %s." % _gain({"name":title,"effect":_definition_effect(title)})}
	return {}

static func _definition_effect(title:String)->String:
	for definition:Dictionary in Construction._settlement_definitions():
		if String(definition.name)==title:return String(definition.get("effect",""))
	return ""

func _builders_row(crews:Dictionary)->Dictionary:
	var heads:=int(crews.heads)
	if heads<=0 or float(crews.town)<0.5:
		return {"key":"builders","icon":"builders","name":"Builders","value":"None" if heads<=0 else str(heads),"value_color":Tokens.RED,"sub":"No one is building: works, repairs and new homes all stop" if heads<=0 else "None are free for the town's own works",
			"detail":"Set people to building on The People.","accent":Tokens.RED,"blockers":[{"text":"No builders" if heads<=0 else "None free for the town","tone":"bad"}]}
	var town:=roundi(float(crews.town));var landmark:=roundi(float(crews.landmark));var military:=roundi(float(crews.military))
	var away:=heads-town-landmark-military
	var parts:PackedStringArray=["%d on the town's works" % town]
	if landmark>0:parts.append("%d raising a landmark" % landmark)
	if military>0:parts.append("%d on military works" % military)
	if away>0:parts.append("%d away or hurt" % away)
	# The water and rail works the same builders serve each month (SettlementModel.process_month).
	var sites:=preload("res://scripts/water_waste_works.gd").construction_sites()+preload("res://scripts/rail_freight.gd").construction_sites()
	for line:Dictionary in GameState.water_conveyance.get("lines",[]):
		if String(line.get("status",""))=="under_construction":sites+=1
	var infrastructure:=(" Each month they also work on %s: see Infrastructure." % _count(sites,"water or rail work","water or rail works")) if sites>0 else ""
	var card:={"key":"builders","icon":"builders","name":"Builders","value":str(heads),"sub":"All on the town's works" if parts.size()==1 and town>=heads else _upper_first(", ".join(parts)),
		"detail":"More builders finish works sooner, keep the town in better repair and put up homes faster."+infrastructure,"accent":Tokens.RULE_STRONG,"state":"plain"}
	if heads>0:card["meter"]={"ratio":clampf(float(town)/float(heads),0.0,1.0),"text":"%d of %d on the town" % [mini(town,heads),heads],"color":Tokens.GREEN,"tip":"Builders on the town's own works against all set to building."}
	return card

## Where the town's places are and what they mean: the carried tents and the
## shelters and homes built here (settlement_construction.gd housing()). On
## the road the tents are pitched for only part of the band each night: the
## share the simulation shelters (simulation_metrics.housing_ratio).
func _home_row(h:Dictionary)->Dictionary:
	var places:=int(h.places);var people:=int(h.people);var carried:=int(h.carried);var built:=int(h.built)
	var short:=int(h.short);var spare:=int(h.spare)
	if GameState.convoy_traveling:
		var covered:=clampf(float(GameState.simulation_metrics.get("housing_ratio",0.0)),0.0,1.0)
		return {"key":"housing","icon":"homes","name":"Housing","value":"%s places" % _n(carried),"sub":"On the road about %d in 10 sleep under cover each night" % roundi(covered*10.0),
			"detail":"The tents carried on the journey hold %s once pitched. More carriers and builders pitch more of them each night." % _n(carried),"accent":Tokens.AMBER,
			"meter":{"ratio":covered,"text":"%d in 10 under cover" % roundi(covered*10.0),"color":Tokens.AMBER}}
	var status:="Everyone has a roof, with room for %s more" % _n(spare) if spare>0 else "Everyone has a roof, with no room to spare"
	if short>0:status="%s of the %s sleep in the open" % [_n(short),_count(people,"person","people")]
	var where:="All %s were built here." % _n(places)
	if carried>0 and built>0:where="%s are in the tents carried on the journey and %s in shelters built here." % [_n(carried),_n(built)]
	elif carried>0:where="No homes built yet: all %s are in the tents carried on the journey." % _n(places)
	elif places<=0:where="No shelter at all."
	var meaning:=" Spare places let newcomers and people brought home move in." if spare>0 else (" Sleeping in the open makes people sicker and slower at work." if short>0 else "")
	var card:={"key":"housing","icon":"homes","name":"Housing","value":"%s places" % _n(places),"value_color":Tokens.RED if short>0 else Tokens.GREEN,"sub":status,"detail":where+meaning,"accent":Tokens.RED if short>0 else Tokens.GREEN,"state":"plain",
		"meter":{"ratio":clampf(float(people)/float(maxi(1,places)),0.0,1.0),"text":"%s people in %s places" % [_n(people),_n(places)],"color":Tokens.RED if short>0 else Tokens.GREEN,"tip":where}}
	if short>0:card["blockers"]=[{"text":"%s sleep in the open" % _n(short),"tone":"bad","tip":"Sleeping in the open makes people sicker and slower at work."}]
	return card

## When the builders put up more homes, from the rule they follow.
func _new_homes_row(h:Dictionary,crews:Dictionary)->Dictionary:
	var trigger:=int(h.trigger);var batch:=int(h.batch);var places:=int(h.places)
	var rule:="Builders put up homes whenever more than %s people live here, %d%% of the places." % [_n(trigger),roundi(Construction.HOUSING_TRIGGER*100.0)]
	var gains:=[{"label":"Places","icon":"homes","before":_n(places),"after":_n(places+batch),"tone":"good","tip":"Each batch of homes adds %s places." % _n(batch)}]
	if not bool(h.shelters_built):
		return {"key":"new_homes","icon":"homes","name":"New homes","value":"Lean-tos first","value_color":Tokens.AMBER,"sub":"The Lean-to Shelters come first: room for %s more" % _n(int(h.lean_to_places)),
			"detail":"After them, builders put up homes whenever the town fills.","accent":Tokens.RULE_STRONG,"state":"waiting"}
	if bool(h.building):
		var left:="stopped: no one is building" if float(h.days_left)<0.0 else ("finished within a day" if float(h.days_left)<1.0 else "about %s left" % Plain.span_text(float(h.days_left)))
		return {"key":"new_homes","icon":"homes","name":"New homes","value":"%d%%" % roundi(float(h.progress)*100.0),"value_color":Tokens.GREEN,"sub":"%s more places going up, %s" % [_n(batch),left],"detail":rule,"accent":Tokens.GREEN,"state":"building",
			"progress":{"ratio":float(h.progress),"text":_left_words(float(h.days_left)),"color":Tokens.GREEN if float(h.days_left)>=0.0 else Tokens.RED},"gains":gains}
	var pace:="Then %s add about %s places every %s." % [_count(roundi(float(crews.town)),"builder"),_n(batch),Plain.span_text(float(h.days_per_batch))] if float(h.days_per_batch)>0.0 else "No one is building now, so none would go up."
	return {"key":"new_homes","icon":"homes","name":"New homes","value":"%s to go" % _n(maxi(0,trigger-int(h.people))),"value_width":70,"sub":"next homes at %s people" % _n(trigger),"detail":pace,"accent":Tokens.RULE_STRONG,"state":"plain",
		"meter":{"ratio":clampf(float(h.people)/float(maxi(1,trigger)),0.0,1.0),"text":"%s of %s people" % [_n(int(h.people)),_n(trigger)],"color":Tokens.GOLD,"tip":rule},"gains":gains}

## The town's repair, from the same facts its official reads (upkeep_warnings).
func _condition_row()->Dictionary:
	var f:=Upkeep.facts()
	var condition:=float(f.condition);var change:=float(f.monthly_change);var hold:=int(f.builders_to_hold)
	var sub:="Wearing out: down %s%% a month" % Plain.number(-change*100.0)
	if change>0.0005:sub="Sound: the builders mend faster than it wears" if condition>=0.995 else "Mending: up %s%% a month" % Plain.number(change*100.0)
	elif change>=-0.0005:sub="Holding: the builders just keep up with the wear"
	var detail:="Makers work only as fast as their workshops are kept, and worn buildings hold less in store."
	if change<-0.0005:detail=("%s would hold it. " % _count(hold,"builder") if hold>0 else "Too few materials to hold it, however many build. ")+detail
	elif hold>0 and int(f.builders)>hold:detail="%s would be enough to hold it. " % _count(hold,"builder")+detail
	var blockers:Array=[]
	if not String(f.short_material).is_empty():
		detail+=" Short of %s: only %d%% of the mending is paid for." % [Upkeep._material_words(String(f.short_material)),roundi(float(f.materials_paid)*100.0)]
		blockers.append({"text":"Short of %s" % Upkeep._material_words(String(f.short_material)),"tone":"bad","tip":"Only %d%% of the mending is paid for." % roundi(float(f.materials_paid)*100.0)})
	var mending:=float(f.get("mending",1.0))
	if absf(mending-1.0)>=0.005:detail+=" Our repair skill makes each month's mending go %d%% %s." % [roundi(absf(mending-1.0)*100.0),"further" if mending>1.0 else "less far"]
	if change<-0.0005 and float(f.months_until_failing)>0.0:detail+=" At this rate it is badly worn in %s." % Plain.span_text(float(f.months_until_failing)*30.4)
	var color:=Tokens.GREEN if condition>=0.75 else (Tokens.AMBER if condition>=Upkeep.FAILING_BELOW else Tokens.RED)
	return {"key":"condition","icon":"repair","name":"Condition","value":"%d%%" % roundi(condition*100.0),"value_color":color,"sub":sub,"detail":detail,"accent":color,"state":"plain","blockers":blockers,
		"meter":{"ratio":condition,"tick":float(Upkeep.FAILING_BELOW),"color":color,"text":"failing below %d%%" % roundi(float(Upkeep.FAILING_BELOW)*100.0)}}

## The era the town builds in, whether it is rising, and what the next era
## still needs (SettlementModel.fabric_era_checks and the age thresholds).
func _era_row(crews:Dictionary)->Dictionary:
	var form:Dictionary=SettlementModel.city_form()
	var level:=float(form.get("tier",0.0))
	var tier:=clampi(floori(level),0,ERAS.size()-1)
	var day:=int(GameState.elapsed_days)
	var supported:=int(SettlementModel._supported_fabric_tier(day))
	var meaning:="Later eras give the buildings more store room and better workshops, and cost more to keep up."
	if tier>=ERAS.size()-1:return {"key":"era","icon":"era","name":"Building era","value":ERAS[tier],"sub":"The last era there is","detail":meaning,"accent":Tokens.GOLD,"state":"plain"}
	var sub:="Stays %s for now" % ERAS[tier]
	var wanted:=_era_needs(tier+1,day)
	var needs:="%s needs %s. " % [ERAS[tier+1],_and_list(wanted)] if not wanted.is_empty() else ""
	var notes:Array=[]
	if float(supported)>level:
		if float(form.get("materials_paid",1.0))>=0.5 and float(crews.town)>0.0:
			sub="Rising toward %s" % ERAS[mini(supported,ERAS.size()-1)];needs=""
		else:sub="Held back: too few builders or materials to rise"
	else:
		for want:String in wanted:notes.append({"text":_upper_first(want),"tip":"%s needs this." % ERAS[tier+1]})
	return {"key":"era","icon":"era","name":"Building era","value":ERAS[tier],"sub":sub,"detail":needs+meaning,"accent":Tokens.GOLD,"state":"plain","notes":notes,
		"meter":{"ratio":clampf(level/float(ERAS.size()-1),0.0,1.0),"text":"%s next" % ERAS[tier+1],"color":Tokens.GOLD,"tip":"%d of %d eras" % [tier+1,ERAS.size()]}}

## What an era still needs, in plain words: the town's age, its crews and
## works, and building knowledge.
func _era_needs(next:int,day:int)->Array:
	var needs:Array=[]
	var age:=float(SettlementModel._settlement_age_years(day))
	var need_age:=float(SettlementModel.FABRIC_ERA_AGE_YEARS[next])
	if age<need_age:needs.append("the town to be %s old (%s to go)" % [_years_words(need_age),Plain.span_text((need_age-age)*365.0)])
	for check:Dictionary in SettlementModel.fabric_era_checks(next):
		if bool(check.met):continue
		var have:=int(check.have);var need:=int(check.need)
		match String(check.what):
			"lean_to_shelters":needs.append("the Lean-to Shelters built")
			"builders":needs.append("%d builders (%d now)" % [need,have])
			"works":needs.append("%d finished works (%d now)" % [need,have])
			"makers":needs.append("%d makers (%d now)" % [need,have])
			"carriers":needs.append("%d carriers (%d now)" % [need,have])
			"stewards":needs.append("%d store keepers (%d now)" % [need,have])
			"districts":needs.append("a second district")
			"labor":needs.append("work going at %d%% (%d%% now)" % [roundi(float(check.need)*100.0),roundi(float(check.have)*100.0)])
			_:needs.append("more knowledge of building, roads and crafts")
	if next>preload("res://scripts/settlement_architecture_knowledge.gd").ceiling():needs.append("new building knowledge")
	return needs

## The workshops and stores the town's buildings hold, how fully staffed they
## are (SettlementModel._built_capacities) and the store room they add.
func _workshops_row()->Dictionary:
	var capacities:Dictionary=SettlementModel.city_capacities()
	var people:=maxf(1.0,float(GameState.population_total))
	var need:=ceili(people*0.1)
	var makers:=GameState.effective_workers("Crafting");var carriers:=GameState.effective_workers("Logistics")
	var staffed:=minf(makers,carriers)/maxf(1.0,people*0.1)
	var storage:Dictionary=capacities.get("storage_bulk",{})
	var room:=0.0
	for kind in storage:room+=float(storage[kind])
	var total:=float(GameState.material_metrics.get("storage_capacity",0.0))
	var added:="less than a unit" if room<1.0 else Plain.number(roundf(room))
	var holds:=("The buildings add %s to the town's %s units of store room." % [added,Plain.number(roundf(total))]) if total>=room and total>0.0 else ("The buildings add %s of store room." % (added if room<1.0 else added+" units"))
	return {"key":"workshops","icon":"workshop","name":"Workshops and stores","value":"Fully staffed" if staffed>=1.0 else "Short-handed","value_color":Tokens.GREEN if staffed>=1.0 else Tokens.AMBER,
		"sub":"%d of %d makers, %d of %d carriers" % [mini(need,floori(makers)),need,mini(need,floori(carriers)),need],
		"detail":"Staffed and kept up, workshops help the makers, and stores speed hauling and trade. "+holds,"accent":Tokens.RULE_STRONG,"state":"plain",
		"needs":[{"label":"Makers","have":float(floori(makers)),"need":float(need),"tip":"Makers at work against the %d the workshops need (one in ten people)." % need},
			{"label":"Carriers","have":float(floori(carriers)),"need":float(need),"tip":"Carriers at work against the %d the stores need (one in ten people)." % need}]}

# --------------------------------------------------------------------------
# The defences: a first-class work of the town
# --------------------------------------------------------------------------

const HomeDefense:=preload("res://scripts/home_defense.gd")
## The town board's mark for each defence stage (resource_icons town_glyph).
const DEFENCE_ICONS:=["open","watch","earthwork","palisade","wall","bastion"]

## The defences as the town board shows them, read from the defence ledger
## and the shared rule (home_defense.gd reading): what stands, what the next
## stage gives (before -> after), its bill against the stores, who decides
## and, when nothing is being raised, exactly why, in numbers, with the fix
## one click away where there is one.
func _defence_card()->Dictionary:
	var r:=HomeDefense.reading()
	var status:=String(r.status)
	var word:=String(r.word)
	var next:Dictionary=r.next
	var building:Dictionary=r.building
	var stage:=int(r.stage)
	var next_name:=String(next.get("short","")).to_lower()
	var card:={"key":"defences","name":"Defences","icon":DEFENCE_ICONS[clampi(int(building.get("index",stage)),0,DEFENCE_ICONS.size()-1)],"state":"plain","value":String(r.short),"value_color":Tokens.INK,"accent":Tokens.RULE_STRONG}
	var workers:=int(r.workers)
	match status:
		"unsettled":card.sub="Works start once the people settle"
		"complete":card.merge({"sub":"The strongest works there are stand here","value_color":Tokens.GREEN,"accent":Tokens.GREEN},true)
		"building":card.merge({"sub":"Raising the %s · %d on the watch" % [String(building.short).to_lower(),workers],"value":"%d%%" % roundi(float(building.progress)*100.0),"value_color":Tokens.GREEN,"accent":Tokens.GREEN,"state":"building"},true)
		"stalled":card.merge({"sub":"The %s have stopped: nobody keeps the watch" % String(building.short).to_lower(),"value":"%d%%" % roundi(float(building.progress)*100.0),"value_color":Tokens.RED,"accent":Tokens.RED,"state":"waiting"},true)
		"ready":card.merge({"sub":("Build now: the %s start tomorrow" if word=="build" else "The people start the %s at their council") % next_name,"value_color":Tokens.GREEN,"accent":Tokens.GREEN,"state":"waiting"},true)
		"waiting":card.merge({"sub":("Build now: the %s wait for what is missing" if word=="build" else "The people want the %s, but the means are short") % next_name,"value_color":Tokens.AMBER,"accent":Tokens.AMBER,"state":"waiting"},true)
		"held":card.merge({"sub":"You said hold off: no new works start","value_color":Tokens.AMBER,"accent":Tokens.AMBER},true)
		"hungry":card.merge({"sub":"No new works while food is short","value_color":Tokens.AMBER,"accent":Tokens.RED,"state":"waiting"},true)
		_:card.sub="Our people see no need for the %s yet" % next_name
	if not building.is_empty():
		var left:=float(building.days_left)
		card["progress"]={"ratio":float(building.progress),"text":_left_words(left),"color":Tokens.GREEN if left>=0.0 else Tokens.RED,
			"tip":"%s of watch work a day by %d on the watch." % [Plain.number(float(building.daily)),workers]}
	# What the next stage gives: the town's figures now against the stage's
	# own at full repair (MilitaryCampaign.SETTLEMENT_DEFENSE_STAGES).
	if not next.is_empty():
		var now:Dictionary=r.now;var after:Dictionary=next.after
		card["gains"]=[
			{"label":"Defenders","icon":"shield","before":"+%d%%" % roundi(float(now.defense_bonus)*100.0),"after":"+%d%%" % roundi(float(after.defense_bonus)*100.0),"tone":"good","tip":"Our side fights at home as if the ground were this much more defensible; attackers need more men to ring the town."},
			{"label":"Lookout","icon":"lookout","before":"%d km" % roundi(float(now.lookout_km)),"after":"%d km" % roundi(float(after.lookout_km)),"tone":"good","tip":"How far off an approaching band is seen."},
			{"label":"Stores safe","icon":"stores","before":"%d%%" % roundi(float(now.stores_safe)*100.0),"after":"%d%%" % roundi(float(after.stores_safe)*100.0),"tone":"good","tip":"The share of the stores raiders cannot carry away."}]
	var controller:=load("res://scripts/civilization_controller.gd")
	var spare:=float(controller.DEFENSE_SPARE) if word=="people" else 1.0
	var blockers:Array=[]
	var notes:Array=[]
	var actions:Array=[]
	if building.is_empty() and not next.is_empty() and status!="complete":
		var needs:Array=[]
		for material:String in (next.materials as Dictionary):
			var bill:=float(next.materials[material])
			needs.append({"resource":material,"have":float(GameState.resource_stockpiles.get(material,0.0)),"need":bill*spare,
				"tip":("%s in store against %s: twice the %s the works take, so the people can spare it." % [_n(roundi(float(GameState.resource_stockpiles.get(material,0.0)))),_n(roundi(bill*spare)),_n(roundi(bill))]) if word=="people" else ("%s in store against the %s the works take." % [_n(roundi(float(GameState.resource_stockpiles.get(material,0.0)))),_n(roundi(bill))])})
		card["needs"]=needs
		var danger:Dictionary=r.danger
		if not danger.is_empty():
			card["meter"]={"ratio":clampf(float(danger.weighed),0.0,1.0),"tick":float(danger.need),"color":Tokens.AMBER,"text":"Danger %d · needs %d" % [HomeDefense.danger_points(float(danger.weighed)),roundi(float(danger.need)*100.0)],"tip":_danger_words(danger,next_name)}
		# Who would raise them, and how long they would take at today's watch.
		var decision:Dictionary=r.decision
		if workers>0 and float(decision.get("daily",0.0))>0.0:
			notes.append({"text":"%d on the watch · %s" % [workers,Plain.duration_text(float(decision.days))],"tip":"%s of watch work a day: the %s would take %s." % [Plain.number(float(decision.daily)),next_name,Plain.duration_text(float(decision.days))]})
	# What stops it, each a chip; amber for a reason, red for what is missing.
	for blocker:Dictionary in r.blockers:
		var kind:=String(blocker.kind)
		if kind=="unsettled":continue
		var item:={"text":String(blocker.text),"tone":"warn" if kind in ["danger","held"] else "bad"}
		match kind:
			"danger":item.tip="The danger they read, weighed by their temper, is below what the %s need. Build now raises them anyway." % next_name
			"material":
				# Carriers bring it while the works are wanted (home_defense material_targets).
				item.tip="Our carriers bring it from our other towns while any spare it." if not HomeDefense.material_targets().is_empty() else "Build now sets our carriers bringing it from our other towns."
				var coming:=float((r.incoming as Dictionary).get(String(blocker.resource),0.0))
				if coming>0.0:notes.append({"text":"%s %s on the road" % [_n(floori(coming)),ResourceSystem.display_name(String(blocker.resource)).to_lower()],"tip":"Deliveries from our other towns, on their way here."})
				elif word=="build" and not _has(actions,"See materials"):actions.append({"label":"See materials","tip":"Where our materials come from and what holds them up.","on_press":jump("economy",1)})
			"watch","slow":
				var add:=HomeDefense.watch_fix(int(next.get("index",stage+1)))
				item.tip="The works rise only by the day's watch work."
				if add>0 and not _has(actions,"Put"):actions.append({"label":"Put %d on the watch" % add,"primary":true,"on_press":_watch.bind(add),
					"tip":"Moves %d from the busiest work to the watch.%s" % [add," You then set the daily work yourself, on The People." if not Tasks.manual() else ""]})
			"food":
				item.tip="Our people raise no works while food is short."
				actions.append({"label":"See food","tip":"The stores, what comes in and what is eaten.","on_press":jump("economy",0)})
		blockers.append(item)
	card["blockers"]=blockers
	card["notes"]=notes
	if not actions.is_empty():card["actions"]=actions
	if status!="unsettled" and status!="complete":
		var options:Array=[]
		for id:String in HomeDefense.WORDS:options.append({"id":id,"label":String(HomeDefense.WORD_LABELS[id]),"tip":String(HomeDefense.WORD_TIPS[id]),"on_press":_set_defence_word.bind(id)})
		card["choice"]={"selected":word,"options":options}
	var finished:=int(GameState.elapsed_days)-int(MilitaryCampaign.settlement_defense.get("completed_day",-100000))
	if stage>0 and building.is_empty() and finished>=0 and finished<=JUST_BUILT_DAYS:
		card["stamp"]={"text":"Built","tip":"The %s stood %s." % [String(r.short).to_lower(),"today" if finished<1 else Plain.span_text(float(finished))+" ago"]}
	card["detail"]=_defence_detail(r,next_name)
	return card

static func _has(actions:Array,label:String)->bool:
	for action:Dictionary in actions:
		if String(action.label).begins_with(label):return true
	return false

## The danger the people read, as a tooltip: each part, their temper, the
## need of the next stage.
static func _danger_words(danger:Dictionary,next_name:String)->String:
	var parts:PackedStringArray=[]
	for part:Dictionary in danger.parts:parts.append("%s %d" % [_upper_first(String(part.words)),roundi(float(part.value)*100.0)])
	var temper:=float(danger.temper)
	var mood:="wary" if temper>1.05 else ("bold" if temper<0.95 else "even-tempered")
	return "%s. Our people are %s: they weigh the danger ×%s, so %d. The %s need %d." % ["; ".join(parts) if not parts.is_empty() else "No danger they can see",mood,Impact._two(temper),HomeDefense.danger_points(float(danger.weighed)),next_name,roundi(float(danger.need)*100.0)]

## The defences' tooltip: what the next stage takes, who decides and by what
## rule, and when the people next look.
static func _defence_detail(r:Dictionary,next_name:String)->String:
	var lines:PackedStringArray=[]
	var next:Dictionary=r.next
	if not next.is_empty():
		var bill:PackedStringArray=[]
		for material:String in (next.materials as Dictionary):bill.append("%s %s" % [_n(roundi(float(next.materials[material]))),ResourceSystem.display_name(material).to_lower()])
		lines.append("The %s take %s days of watch work and %s." % [next_name,_n(roundi(float(next.work))),_and_list(Array(bill))])
	match String(r.word):
		"build":lines.append("Build now: each next stage starts as soon as its materials are in store and someone keeps the watch, whatever the danger.")
		"hold":lines.append("Hold off: no new works start. Any already going up are finished.")
		_:
			lines.append("Our people decide by the rule every people follows: they raise the next works when the danger they read, weighed by their temper, reaches what the works need, with food for 30 days, twice the materials in store and a watch that finishes them within three years.")
			var days:=int(r.next_council)-int(GameState.elapsed_days)
			lines.append("They next look at their council in %s." % ("a day" if days<=1 else Plain.span_text(float(days))))
	return "\n".join(lines)

func _set_defence_word(id:String)->void:
	var result:=HomeDefense.set_word(id)
	preload("res://scripts/order_tracker.gd").defence_order(id,result)
	if result.has("ok"):
		var begun:=bool(result.get("started",false))
		terrain._report_military_action({"ok":true,"message":("Work begins on the %s." % String(MilitaryCampaign.SETTLEMENT_DEFENSE_STAGES[int(MilitaryCampaign.settlement_defense.project_stage)].short).to_lower()) if begun else "Defences: %s." % String(HomeDefense.WORD_LABELS[id]).to_lower()})
	if is_instance_valid(hud):hud.request_immediate_dock_refresh()

func _watch(add:int)->void:
	var moved:=Tasks.move("Defense",add)
	terrain._report_military_action({"ok":bool(moved.get("ok",false)),"message":"%d more keep the watch." % int(moved.get("moved",0)) if bool(moved.get("ok",false)) else String(moved.get("reason","No one could be moved."))})
	if is_instance_valid(hud):hud.request_immediate_dock_refresh()

## "about 25 days left", or why no time can be given.
static func _left_words(days:float)->String:
	if days<0.0:return "stopped"
	if days<1.0:return "within a day"
	return "about %s left" % Plain.span_text(days)

# --- Words ------------------------------------------------------------------

## What a work gets the town, in its own words (the Lean-to Shelters with the
## places they add).
static func _gain(project:Dictionary)->String:
	if String(project.get("name",""))=="Lean-to Shelters":return "protects health and adds room for %s people" % _n(Construction.lean_to_places())
	return String(project.get("effect","serves the town"))

static func _first_blocker(project:Dictionary)->String:
	return String(project.blockers[0]) if not (project.get("blockers",[]) as Array).is_empty() else "Waits its turn"

static func _time_left(days:float)->String:
	if days<0.0:return "no one is at work on it"
	if days<1.0:return "finished within a day at today's pace"
	return "about %s left at today's pace" % Plain.span_text(days)

static func _lower_first(text:String)->String:
	return text.left(1).to_lower()+text.substr(1) if not text.is_empty() else text

static func _upper_first(text:String)->String:
	return text.left(1).to_upper()+text.substr(1) if not text.is_empty() else text

static func _and_list(items:Array)->String:
	if items.size()<=1:return "" if items.is_empty() else String(items[0])
	return ", ".join(PackedStringArray(items.slice(0,items.size()-1)))+" and "+String(items.back())

static func _n(value:int)->String:
	return preload("res://scripts/hud/era_words.gd").grouped(value)

static func _count(value:int,one:String,many:String="")->String:
	return "%s %s" % [_n(value),one if value==1 else (many if not many.is_empty() else one+"s")]

static func _years_words(years:float)->String:
	if years<1.0:return "%d months" % roundi(years*12.0)
	if is_equal_approx(years,1.0):return "a year"
	return "%s years" % Plain.number(years)

## Civic works as one table (hud/buildings_board.gd): every work the people
## know, built or not, a row each with its state, what it does in the
## engine's figures, its bill as pips while it waits, what stops it and the
## priority verb; then what the homes and works do now, and the town's
## building record folded in (no screen behind the page).
func _civic_tab()->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var priority:=String(city.get("construction_priority",""))
	var current:=Construction._current_settlement_project()
	var can_prioritize:=not city.is_empty() and String(city.get("occupied_by","")).is_empty() and GameState.settlement_site_committed
	var projects:Array=[]
	var cards:Array=[]
	var built:=0
	var folded:PackedStringArray=[]
	for definition:Dictionary in Construction._settlement_definitions():
		var title:=String(definition.name)
		var done:=title in GameState.settlement_completed
		var discovery:=String(definition.get("discovery",""))
		var unknown:=not done and not discovery.is_empty() and discovery not in GameState.known_discoveries
		var project:=_project(definition,current,done)
		if not unknown:projects.append(project)
		if done:built+=1
		# The name and its figures say what it is; the sentence waits in the tooltip.
		var row:={"section":"works","key":"work_"+title,"icon":work_icon(title),"name":title,"sub":"","detail":"It %s." % _gain(definition),"effects":_effects(project.impact)}
		if done:
			# A work built long ago folds into one line; a fresh one keeps its stamp.
			var ago:=int(project.finished_ago)
			if ago<0 or ago>JUST_BUILT_DAYS:
				var said:PackedStringArray=[]
				for effect:Dictionary in row.effects:said.append("%s %s" % [String(effect.label),String(effect.value)])
				folded.append("%s: %s" % [title,", ".join(said)])
				continue
			row["stamp"]={"text":"Built","tip":"Finished %s." % String(project.finished_words)}
		elif unknown:
			var progress:=float(GameState.discovery_progress.get(discovery,0.0))
			row.merge({"tag":{"text":"Unknown","tone":"note","tip":"The people must first learn %s." % _discovery_name(discovery)},"bar":{"ratio":progress,"color":Tokens.TEAL,"width":80,"tip":"%s: %d%% of the way to proof." % [_upper_first(_discovery_name(discovery)),roundi(progress*100.0)]},
				"value":"%d%%" % roundi(progress*100.0),"sub":"needs %s" % _discovery_name(discovery)},true)
		else:
			var active:=bool(project.active)
			row.merge({"bar":{"ratio":float(project.progress),"color":Tokens.GREEN if active else Tokens.AMBER},"value":"%d%%" % roundi(float(project.progress)*100.0),"needs":_bill(project.inputs),
				"tag":{"text":"Building","tone":"good"} if active else {"text":"Waiting","tone":"warn","tip":"\n".join(project.blockers)},
				"sub":_upper_first(_time_left(float(project.days_left))) if active else _first_blocker(project)},true)
			var blockers:Array=[]
			for blocker:String in project.blockers:blockers.append({"text":blocker,"tone":"bad"})
			if not active and not blockers.is_empty():row["blockers"]=blockers
			if can_prioritize:
				row["actions"]=[{"label":"Back to leader","tip":"The leader chooses what to build again.","on_press":_priority.bind("")}] if title==priority else [{"label":"Build first","tip":"The builders take this up as soon as it can start, and work on what they can until then.","on_press":_priority.bind(title)}]
			if title==priority:row["highlight"]=true
		cards.append(row)
	if not folded.is_empty():
		var total:=Construction._settlement_definitions().size()
		cards.push_front({"section":"works","key":"works_built","icon":"hall","name":"Built works","sub":"",
			"bar":{"ratio":float(built)/float(maxi(1,total)),"color":Tokens.GREEN},"value":"%d of %d" % [built,total],"value_width":60,
			"detail":"What each does now, in the engine's figures:
"+"
".join(folded)})
	# What the homes and the works do now, in the engine's figures.
	var titles:Array=Construction._settlement_definitions().map(func(d:Dictionary)->String:return String(d.name))
	for line:Dictionary in Impact.summary():
		# A civic work's own line is its row above.
		if String(line.label) in titles:continue
		var label:=String(line.label);var value:=String(line.value)
		# Room in store, not food in hand: said so, beside the top bar's days of food.
		if label=="Food kept":label="Store room for food";value=value+"' worth"
		if label=="Homes":value=value.replace(" places a person"," a person")
		cards.append({"section":"does","key":"does_"+String(line.label),"icon":"hall","name":label,"value":value,"value_color":Tokens.GREEN if String(line.get("tone",""))=="good" else (Tokens.RED if String(line.get("tone",""))=="bad" else Tokens.INK),"value_width":44,"detail":String(line.get("words",""))})
	var homes:=Impact.homes()
	for line:Dictionary in homes.lines:
		cards.append({"section":"homes","key":"homes_"+String(line.label),"icon":"homes","name":String(SHORT_LINES.get(String(line.label),line.label)),"value":preload("res://scripts/hud/content/dock_content_undertakings.gd")._grouped_numbers(String(line.value)),"value_color":Tokens.GREEN if String(line.get("tone",""))=="good" else (Tokens.RED if String(line.get("tone",""))=="bad" else Tokens.INK),"value_width":44,"detail":String(line.get("words",""))})
	var record:=_record_rows()
	cards.append_array(record.rows)
	var sections:=[
		{"id":"does","heading":"What the buildings do"},
		{"id":"homes","heading":"What the homes do"},
		{"id":"works","heading":"Civic works","span":true,"note":("Your priority: %s" % priority) if not priority.is_empty() else "the leader chooses"},
		{"id":"record","heading":"Building record","note":String(record.note),"actions":record.actions}]
	return {"blocks":[{"type":"town_works","board":true,"sections":sections,"cards":cards,"projects":projects,"completed":GameState.settlement_completed.size(),"priority":priority}]}

## The homes' lines in a word or two, so a row never cuts its name.
const SHORT_LINES:={"Deaths from age and weakness":"Deaths of age","Sickness breaking out":"Sickness","Room for newcomers":"Room to spare","Deaths of exposure":"Deaths of cold"}

## The town's building record, newest first, eight to a page, folded into
## the Civic works tab (GameState.building_ledger, as the old record
## screen read it).
const RECORD_PAGE:=8
var record_page:=0
func _record_rows()->Dictionary:
	var id:=String(GameState.selected_player_settlement_id)
	var records:Array=[]
	for row:Dictionary in GameState.building_ledger:
		if id.is_empty() or String(row.get("settlement_id",""))==id:records.append(row)
	records.reverse()
	var pages:=maxi(1,ceili(float(records.size())/RECORD_PAGE))
	record_page=clampi(record_page,0,pages-1)
	var losses:=0
	for row:Dictionary in records:
		if String(row.get("event","")) in ["damaged","destroyed"]:losses+=1
	var rows:Array=[]
	for index in range(record_page*RECORD_PAGE,mini(records.size(),(record_page+1)*RECORD_PAGE)):
		var row:Dictionary=records[index]
		var event:=String(row.get("event","recorded"))
		var used:PackedStringArray=[]
		for material in row.get("materials",{}):used.append("%s %s" % [_n(roundi(float(row.materials[material]))),ResourceSystem.display_name(String(material)).to_lower()])
		var bad:=event in ["destroyed","damaged","abandoned","vacated"]
		var kind:=String(row.get("kind","Building"))
		rows.append({"section":"record","key":"record_%d" % int(row.get("id",index)),"icon":work_icon(kind),"name":kind if kind!=kind.to_lower() else kind.replace("_"," ").capitalize(),
			"sub":preload("res://scripts/calendar_date.gd").words(int(row.get("day",0)),true),"tag":{"text":event.replace("_"," ").capitalize(),"tone":"bad" if bad else ("good" if event in ["completed","founded","infilled","rebuilt","reoccupied"] else "info")},
			"detail":("Used %s." % ", ".join(used)) if not used.is_empty() else "Record #%d." % int(row.get("id",0))})
	var actions:Array=[]
	if pages>1:
		actions.append({"label":"Newer","tip":"Newer records","on_press":_record_turn.bind(-1) if record_page>0 else Callable()})
		actions.append({"label":"Older","tip":"Older records","on_press":_record_turn.bind(1) if record_page<pages-1 else Callable()})
	return {"rows":rows,"actions":actions,"note":"%s records · %s losses" % [_n(records.size()),_n(losses)] if not records.is_empty() else "nothing built yet"}

func _record_turn(step:int)->void:
	record_page=maxi(0,record_page+step)
	if is_instance_valid(hud):hud.request_immediate_dock_refresh()

## Infrastructure as rows (hud/buildings_board.gd): the defence ladder, stage
## by stage, with the next stage's bill, Build and who decides on its row (the
## same row and figures as The Town: _defence_row); the roads and each kind
## of work building with its cover and what it does (built_fabric.gd); the
## water works, channels, rail and plants that are working; and the water
## works the people are learning (water_waste_works.gd), with progress.
func _infrastructure_tab()->Dictionary:
	var cards:Array=[]
	var many:=GameState.player_settlements.size()>1
	for city:Dictionary in GameState.player_settlements:
		var id:=String(city.get("id",""))
		var rows:Array=SettlementModel.with_city_resources(id,func()->Array:return _infrastructure_rows(id))
		for row:Dictionary in rows:
			# A plant waiting idle is not news on this page.
			if String(row.get("key","")).begins_with("plant_") and String((row.get("tag",{}) as Dictionary).get("text",""))=="Idle":continue
			row["section"]="works"
			if many:row.sub=("%s · %s" % [String(city.get("name","")),String(row.get("sub",""))]).trim_suffix(" · ")
			cards.append(row)
	cards.append_array(_ladder_rows())
	cards.append_array(_network_rows())
	cards.append_array(_water_unlock_rows())
	var sections:=[
		{"id":"defences","heading":"The defences, stage by stage","span":true},
		{"id":"network","heading":"Roads and work buildings"},
		{"id":"works","heading":"Water, rail and plants"},
		{"id":"water_soon","heading":"Water works not yet built"}]
	return {"blocks":[{"type":"town_works","board":true,"sections":sections,"cards":cards}]}

## The defence ladder: each stage what it gives; the next stage is The
## Town's own defences row (one bill, one Build, one figure everywhere).
func _ladder_rows()->Array:
	var rows:Array=[]
	var r:=HomeDefense.reading()
	var here:=int(r.stage)
	var building:Dictionary=r.building
	var next_index:=int(building.get("index",here+1)) if not building.is_empty() else here+1
	for stage:Dictionary in Impact.defences():
		var index:=int(stage.stage)
		var lines:Array=stage.lines
		var spec:Dictionary=MilitaryCampaign.SETTLEMENT_DEFENSE_STAGES[index]
		if index==next_index and not _defence.is_empty() and not bool(stage.built):
			var next_row:=_defence_row(_defence)
			next_row.merge({"key":"stage_%d" % index,"section":"defences","sub":"%s days' work" % _n(roundi(float(spec.work))),"highlight":true},true)
			rows.append(next_row)
			continue
		var bill:PackedStringArray=[]
		for material:String in (spec.materials as Dictionary):bill.append("%s %s" % [_n(roundi(float(spec.materials[material]))),ResourceSystem.display_name(material).to_lower()])
		var effects:=[{"label":"Lookout","value":String(lines[1].value),"tone":"good" if bool(stage.built) else "plain","tip":String(lines[1].words)},{"label":"Stores safe","value":String(lines[2].value),"tone":"good" if bool(stage.built) else "plain","tip":String(lines[2].words)}]
		var row:={"section":"defences","key":"stage_%d" % index,"icon":DEFENCE_ICONS[clampi(index,0,DEFENCE_ICONS.size()-1)],"name":String(stage.name),
			"value":String(lines[0].value),"value_color":Tokens.GREEN if bool(stage.built) else Tokens.TEXT_SOFT,"sub":("%s days' work, %s" % [_n(roundi(float(spec.work))),", ".join(bill)]) if not bool(stage.built) else "",
			"effects":effects,"detail":"Defenders %s: %s" % [String(lines[0].value),String(lines[0].words)]}
		if bool(stage.built):row["tag"]={"text":"Built","tone":"good"}
		rows.append(row)
	return rows

## The roads and each kind of work building: cover against the most there
## can be, and what it does now (built_fabric.gd works_cover, effect_lines).
const WORK_KINDS:={"workshops":["Workshops","workshop","Makers' goods"],"granaries":["Granaries","stores","Stored food rots"],"kilns":["Kilns","workshop","Kilns"],"storehouses":["Storehouses","stores","Cutting and digging"],"water":["Wells","stores","Water carried"]}
func _network_rows()->Array:
	if not GameState.settlement_site_committed:return []
	var r:Dictionary=Fabric.report()
	var by_label:Dictionary={}
	for line:Dictionary in Fabric.effect_lines(r):by_label[String(line.label)]=line
	var rows:Array=[]
	var road_fx:Array=[]
	for label in ["Hauling","Between towns","Hauls from deposits"]:
		if by_label.has(label):road_fx.append({"label":label,"value":String(by_label[label].value),"tone":String(by_label[label].get("tone","plain")),"tip":String(by_label[label].words)})
	rows.append({"section":"network","key":"net_roads","icon":"open","name":"Roads","sub":String(Fabric.ROAD_WORDS[int(r.road_kind)]),"bar":{"ratio":float(r.roads),"tick":float(r.road_cap),"color":Tokens.TEAL},"value":"%d/100" % roundi(float(r.roads)*100.0),
		"effects":road_fx,"detail":"The road index; %s are the best the people know (up to %d, the tick)." % [String(Fabric.ROAD_WORDS[int(r.road_kind)]),roundi(float(r.road_cap)*100.0)]})
	for kind:String in WORK_KINDS:
		var spec:Array=WORK_KINDS[kind]
		var know:=String(Fabric.WORKS_KNOW.get(kind,""))
		var cover:=float(Fabric.works_cover(kind))
		var line:Dictionary=by_label.get(String(spec[2]),{})
		var row:={"section":"network","key":"net_"+kind,"icon":String(spec[1]),"name":String(spec[0]),"bar":{"ratio":cover,"color":Tokens.BLUE},"value":"%d/100" % roundi(cover*100.0),
			"sub":("%s %s" % [String(spec[2]).to_lower(),String(line.get("value",""))]) if not line.is_empty() else "","detail":String(line.get("words","How fully %s serve the town." % String(Fabric.WORKS_WORDS[kind])))}
		if not know.is_empty() and know not in GameState.known_discoveries:
			row.merge({"tag":{"text":"Unknown","tone":"note","tip":"The people must first learn %s." % _discovery_name(know)},"sub":"needs %s" % _discovery_name(know),"value":""},true)
		rows.append(row)
	return rows

## Water works the people know of but have not built, or are learning, with
## how far the practice has come (water_waste_works.gd SPECS).
func _water_unlock_rows()->Array:
	var works=preload("res://scripts/water_waste_works.gd")
	var rows:Array=[]
	for kind:String in works.SPECS:
		if not works.work_for(kind).is_empty():continue
		var spec:Dictionary=works.SPECS[kind]
		var id:=String(spec.discovery)
		var known:=id in GameState.known_discoveries
		var progress:=float(DiscoverySystem.adoption(id)) if known else float(GameState.discovery_progress.get(id,0.0))
		if progress<=0.0005 and not known:continue
		var ready:=known and progress>=0.25
		rows.append({"section":"water_soon","key":"water_soon_"+kind,"icon":"stores","name":String(spec.name),"sub":"","bar":{} if ready else {"ratio":clampf(progress/0.25 if known else progress,0.0,1.0),"color":Tokens.TEAL},
			"value":("Ready" if progress>=0.25 else "%d%%" % roundi(progress*100.0)) if known else "%d%%" % roundi(progress*100.0),"value_color":Tokens.GREEN if known and progress>=0.25 else Tokens.INK,
			"detail":("The people know %s; builders raise it once its stone, timber or clay arrive." % _discovery_name(id)) if ready else ("The people know it; %d in 100 have taken it up (25 needed to build it)." % roundi(progress*100.0)) if known else ("%s: %d%% of the way to proof." % [_upper_first(_discovery_name(id)),roundi(progress*100.0)])})
	return rows

static func _infrastructure_rows(city_id:String)->Array:
	var rows:Array=[]
	var works=preload("res://scripts/water_waste_works.gd")
	for work:Dictionary in works.data().get("works",[]):
		# What it does, from its practice and its coverage (building_impact.gd).
		var effects:Array=[]
		var told:PackedStringArray=[]
		for line:Dictionary in Impact.water_work(String(work.kind)).lines:
			told.append("%s %s: %s" % [String(line.label),String(line.value),String(line.words)])
			if effects.size()<2:effects.append({"label":String(line.label),"value":String(line.value),"tone":String(line.get("tone","plain")),"tip":String(line.words)})
		var condition:=float(work.get("condition",1.0))
		rows.append({"key":"water_"+String(work.kind),"icon":"stores","name":String(works.SPECS.get(String(work.kind),{}).get("name",String(work.kind).capitalize())),"tag":_status_tag(String(work.get("status",""))),
			"bar":{"ratio":condition,"color":Tokens.TEAL,"width":80,"tip":"Repair"},"value":"%d%%" % roundi(condition*100.0),"sub":"repair","effects":effects,"detail":String.chr(10).join(told)})
	for line:Dictionary in preload("res://scripts/water_conveyance.gd").data().get("lines",[]):
		var condition:=float(line.get("condition",1.0))
		rows.append({"key":"conduit_%d" % rows.size(),"icon":"stores","name":"Water channel","tag":_status_tag(String(line.get("status",""))),"bar":{"ratio":condition,"color":Tokens.TEAL,"width":80},"value":"%d%%" % roundi(condition*100.0),"sub":"repair","detail":"A channel bringing water to the town."})
	for line:Dictionary in preload("res://scripts/rail_freight.gd").data().get("lines",[]):
		rows.append({"key":"rail_%d" % rows.size(),"icon":"yard","name":"Rail line","tag":_status_tag(String(line.get("status",""))),"value":"%d wagons" % int(line.get("wagons",0)),"value_width":80,"sub":"","detail":"A rail line and its wagons."})
	for base:Dictionary in MilitaryCampaign.joint_operations.state.get("bases",[]):
		if String(base.get("city_id",""))!=city_id:continue
		var condition:=float(base.get("condition",1.0))
		rows.append({"key":"dock_%d" % rows.size(),"icon":"yard","name":"Naval dock","bar":{"ratio":condition,"color":Tokens.BLUE,"width":80},"value":"%d%%" % roundi(condition*100.0),"sub":"repair","detail":"A dock for the fleet."})
	var ops=preload("res://scripts/technology_operations.gd")
	if GameState.resource_settlement_id.is_empty():
		for plant:String in ops.data().get("plants",{}):
			var record:Dictionary=ops.data().plants[plant]
			if int(record.get("installed",0))+int(record.get("building",0))<=0:continue
			var status:=String(ops.status(plant))
			var stopped:=status.to_lower().begins_with("waiting") or status.to_lower().contains("short")
			rows.append({"key":"plant_"+plant,"icon":"workshop","name":String(ops.PLANTS.get(plant,{}).get("name",plant.capitalize())),"value":"%d installed" % int(record.get("installed",0)),"value_width":90,
				"sub":status,"tag":{"text":"Idle" if stopped else "Working","tone":"warn" if stopped else "good","tip":status},"detail":"%s: %s." % [String(ops.PLANTS.get(plant,{}).get("name",plant.capitalize())),status]})
	return rows

static func _status_tag(status:String)->Dictionary:
	var words:=status.replace("_"," ").capitalize()
	if words.is_empty():return {}
	var tone:="good" if status in ["operational","complete","active","built","running"] else ("warn" if status in ["under_construction","planned","building"] else ("bad" if status in ["damaged","failed","abandoned","ruined"] else "info"))
	return {"text":words,"tone":tone}

func _local_tab(sub:int)->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var priority:=String(city.get("construction_priority",""))
	var current:=Construction._current_settlement_project()
	var projects:Array=[]
	for project:Dictionary in Construction._settlement_definitions():
		var done:=String(project.name) in GameState.settlement_completed
		if done!=(sub==1):continue
		var discovery:=String(project.get("discovery",""))
		if not done and not discovery.is_empty() and discovery not in GameState.known_discoveries:continue
		projects.append(_project(project,current,done))
	var stocks:Dictionary={}
	for resource in ["Timber","Stone","Clay","Fiber Plants"]:stocks[resource]=float(GameState.resource_stockpiles.get(resource,0))
	return {"blocks":[{"type":"construction_queue","shelter":Shelter.describe(GameState.settlement_completed,GameState.housing_capacity,GameState.population_total,Construction.carried_places()),"projects":projects,"selected":selected_project,"priority":priority,"stocks":stocks,"city":String(city.get("name","Founding camp")),"builders":int(GameState.population_allocations.get("Construction",0)),"carriers":int(GameState.population_allocations.get("Logistics",0)),"can_prioritize":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),"committed":GameState.settlement_site_committed,"completed":GameState.settlement_completed.size(),"fresh_days":JUST_BUILT_DAYS,"on_select":_select,"on_priority":_priority,"on_site":terrain._on_settlement_action_pressed,"on_record":func():hud.open_detail(preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud,GameState.selected_player_settlement_id))}]}
## One civic work as both tabs read it: progress, the material bill (the mix
## the builders will use, or the closest known one), what holds it up in plain
## words, and the days left at today's pace (Construction.daily_work) while it
## is the work in hand.
func _project(project:Dictionary,current:Dictionary,done:bool)->Dictionary:
	var title:=String(project.name)
	var materials:Dictionary=Construction._settlement_project_material_plan(project)
	var feasible:=not materials.is_empty()
	if not feasible:
		var least_missing:=INF
		for option:Dictionary in Construction.material_options(project):
			if not String(option.get("requires","")).is_empty() and String(option.requires) not in GameState.known_discoveries:continue
			var missing:=0.0
			for resource:String in option.cost:missing+=maxf(0,float(option.cost[resource])-float(GameState.resource_stockpiles.get(resource,0)))/maxf(1,float(option.cost[resource]))
			if missing<least_missing:least_missing=missing;materials=option.cost
	var inputs:Array=[]
	var blockers:Array[String]=[]
	for resource:String in materials:
		var stored:=float(GameState.resource_stockpiles.get(resource,0));var required:=float(materials[resource])
		inputs.append({"resource":resource,"stored":stored,"required":required})
		if stored+.0001<required:blockers.append("Needs %s more %s" % [Plain.number(required-stored),ResourceSystem.display_name(resource).to_lower()])
	for required in project.requires:
		if String(required) not in GameState.settlement_completed:blockers.push_front("Needs the %s first" % String(required))
	for role:String in project.minimum:
		var available:=int(GameState.population_allocations.get(role,0))
		if available<=0:blockers.append("Needs people %s" % String((Tasks.TASKS.get(role,[role.to_lower(),"",role.to_lower()]) as Array)[2]))
	var discovery:=String(project.get("discovery",""))
	if not discovery.is_empty() and DiscoverySystem.adoption(discovery)<.10:blockers.push_front("Needs the people to take up the practice")
	if bool(project.get("requires_water",false)) and not bool(GameState.water_metrics.get("source_accessible",false)):blockers.push_front("Needs water within reach")
	if bool(project.get("known_resource",false)) and ResourceSystem.visible_deposits().is_empty():blockers.push_front("Needs a known place to dig or cut: send scouts")
	if GameState.convoy_traveling:blockers.push_front("Needs the people to settle")
	if not GameState.settlement_site_committed:blockers.push_front("Needs a place to settle")
	var active:=title==String(current.get("name","")) and blockers.is_empty()
	var worked:=float(GameState.settlement_projects.get(title,0))
	var rate:=Construction.daily_work() if active else 0.0
	var ago:=_finished_ago(title) if done else -1
	return {"name":title,"done":done,"active":active,"impact":Impact.work(title),"progress":1.0 if done else clampf(worked/float(project.days),0,1),"state":"Complete" if done else ("Building" if active else (blockers[0] if not blockers.is_empty() else "Waits its turn")),"blockers":blockers,"inputs":inputs,"bill_note":"Selected material mix" if feasible else "Closest known mix · alternatives considered","effect":String(project.get("effect","")),
		"days_left":maxf(0.0,float(project.days)-worked)/rate if rate>0.0 else -1.0,
		"finished_ago":ago,"finished_words":("today" if ago<1 else Plain.span_text(float(ago))+" ago") if ago>=0 else ""}

## Days since this town finished `title` (its building ledger), or -1.
static func _finished_ago(title:String)->int:
	var id:=String(GameState.selected_player_settlement_id)
	for index in range(GameState.building_ledger.size()-1,-1,-1):
		var row:Dictionary=GameState.building_ledger[index]
		if String(row.get("event",""))!="completed" or String(row.get("kind",""))!=title:continue
		if not id.is_empty() and String(row.get("settlement_id",""))!="" and String(row.settlement_id)!=id:continue
		return maxi(0,int(GameState.elapsed_days)-int(row.get("day",0)))
	return -1
func _select(title:String)->void:
	selected_project="" if selected_project==title else title;hud.request_immediate_dock_refresh()
func _priority(title:String)->void:
	var result:Dictionary=Construction.set_priority(GameState.selected_player_settlement_id,title)
	preload("res://scripts/order_tracker.gd").building_order(title,result,String(GameState.selected_player_settlement_id))
	terrain._report_military_action(result);hud.request_immediate_dock_refresh()
func signature()->Array:
	return [MilitaryCampaign.settlement_defense.duplicate(true),GameState.selected_player_settlement_id,GameState.settlement_site_committed,GameState.settlement_projects.duplicate(true),GameState.settlement_completed.duplicate(),GameState.resource_stockpiles.duplicate(),GameState.population_allocations.duplicate(),GameState.elapsed_days,GameState.settlement_network_revision,selected_project,record_page,GameState.building_ledger.size(),GameState.next_building_record_id,history_filter,history.signature() if history!=null else []]

func _settlements_tab()->Dictionary:
	var blocks:Array=[{"type":"text","heading":"CONSTRUCTION BY SETTLEMENT","text":"Completed works count finished projects. A shelter project can provide several structures. History records later building changes, repairs and losses."}]
	for city:Dictionary in GameState.player_settlements:
		var id:=String(city.get("id",""))
		var report:Dictionary=SettlementModel.with_city_resources(id,func()->Dictionary:
			return _settlement_report(GameState.settlement_completed,GameState.settlement_projects))
		blocks.append({"type":"text","heading":String(city.get("name","Settlement")),"text":"%d completed works · %d underway" % [report.completed,report.underway]})
		if not report.items.is_empty():blocks.append({"type":"rows","items":report.items})
		blocks.append({"type":"actions","items":[{"label":"CONSTRUCTION HISTORY","sub":String(city.get("name","Settlement")),"on_press":_open_city_record.bind(id)}]})
	if GameState.player_settlements.is_empty():blocks.append({"type":"text","heading":"SETTLEMENTS","text":"Choose a settlement site to begin construction."})
	return {"blocks":blocks}

static func _settlement_report(completed:Array,progress:Dictionary)->Dictionary:
	var items:Array=[]
	var underway:=0
	for title in completed:
		items.append({"name":String(title),"value":"1 completed work","accent":Tokens.GREEN})
	for project:Dictionary in Construction._settlement_definitions():
		var title:=String(project.name)
		if title in completed or float(progress.get(title,0))<=0:continue
		underway+=1
		items.append({"name":title,"value":"%.1f%%" % (100.0*clampf(float(progress[title])/float(project.days),0,1)),"sub":"Work in progress","accent":Tokens.AMBER})
	return {"completed":completed.size(),"underway":underway,"items":items}

func _open_city_record(id:String)->void:
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud,id))

func _history_tab()->Dictionary:
	if history==null:history=preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud)
	history.settlement_id=history_filter
	var result:Dictionary=history.tab(0)
	var filters:Array=[{"label":"ALL SETTLEMENTS","on_press":_filter_history.bind("")}]
	for city:Dictionary in GameState.player_settlements:
		filters.append({"label":String(city.get("name","Settlement")),"on_press":_filter_history.bind(String(city.get("id","")))})
	result.blocks.push_front({"type":"actions","items":filters})
	return result

func _filter_history(id:String)->void:
	history_filter=id
	if history!=null:history.pages[0]=0
	hud.request_immediate_dock_refresh()


# --------------------------------------------------------------------------
# The built fabric (built_fabric.gd): what the builders have made of the town
# --------------------------------------------------------------------------

## Dwelling grades, plainest to best, as the homes bar paints them.
const GRADE_INKS:=["#a08a6c","#8f7a52","#8a6a3e","#9b6a4a","#6f7378"]

## The town's fabric at a glance: the homes by grade (one bar), its roads,
## beauty, work buildings, walls and stone, the builders' craft and upkeep
## (bars), what it does now and what ten more builders would buy, every
## number the engine's own (built_fabric.gd report, effect_lines,
## plus_lines). Says plainly when the builders are too few to keep it all.
func _fabric_blocks()->Array:
	if not GameState.settlement_site_committed:return []
	var r:Dictionary=Fabric.report()
	var homes:Array=r.homes
	var items:Array=[]
	for g in Fabric.GRADES.size():
		var share:=float(homes[g])
		if share<0.005:continue
		items.append({"share":share,"value":"%d%%" % roundi(share*100.0),"label":String(Fabric.GRADE_SHORT[g]),"color":Color(String(GRADE_INKS[g])),
			"tip":"%d of every 100 places are %s." % [roundi(share*100.0),String(Fabric.GRADE_WORDS[g])]})
	var best:=int(r.best)
	var caps:Array=r.caps
	var legend:="Homes %d of 100 good. The best they can build now: %s, at most %d in 100 of the places at the builders' craft %s." % [roundi(float(r.quality)*100.0),String(Fabric.GRADE_WORDS[best]),roundi(float(caps[best])*100.0),Fabric._one(float(r.craft))]
	if best<Fabric.GRADES.size()-1:
		var g:=best+1
		legend+=" %s need %s known and craft %s." % [String(Fabric.GRADE_WORDS[g]).capitalize(),_any_words(Fabric.GRADE_KNOW[g]),Fabric._one(float(Fabric.GRADE_CRAFT[g]))]
	legend+=" New places go up plain; builders raise them as they have hands, and unkept homes fall a grade."
	var declining:=Fabric.decline_words(r)
	var road_words:=String(Fabric.ROAD_WORDS[int(r.road_kind)])
	var d:Dictionary=r.defense
	var bars:Array=[
		{"name":"Homes","ratio":float(r.quality),"value":"%d/100" % roundi(float(r.quality)*100.0),"color":Tokens.GREEN,"tip":"The places' mean quality: windbreaks 0, huts 30, timber 55, mudbrick 75, stone 100."},
		{"name":"Roads","ratio":float(r.roads),"value":"%d/%d" % [roundi(float(r.roads)*100.0),roundi(float(r.road_cap)*100.0)],"color":Tokens.TEAL,"tip":"The road index: %s are the best the people know (up to %d). Roads wear %d in 100 a year unkept." % [road_words,roundi(float(r.road_cap)*100.0),roundi(Fabric.ROAD_WEAR*100.0)]},
		{"name":"Beauty","ratio":float(r.beauty),"value":"%d/100" % roundi(float(r.beauty)*100.0),"color":Tokens.GOLD,"tip":"Fine works a person: carved posts, plazas, painted halls, monuments. Each builder-day of fine work is worth %s with what the people know of the arts. Unkept, they weather %d in 100 a year." % [Fabric._one(float(r.artistry)),roundi(Fabric.BEAUTY_WEAR*100.0)]},
		{"name":"Work buildings","ratio":float(r.cover),"value":"%d/100" % roundi(float(r.cover)*100.0),"color":Tokens.BLUE,"tip":"How fully workshops, granaries, kilns, storehouses and water works serve the town."},
		{"name":"Craft","ratio":float(r.craft)/Fabric.CRAFT_MAX,"value":"%s of %d" % [Fabric._one(float(r.craft)),roundi(Fabric.CRAFT_MAX)],"color":Tokens.VIOLET,"tip":"The builders' living experience. At today's builders it settles at %s over a working life; it fades as the old builders die." % Fabric._one(float(r.craft_settles))},
		{"name":"Upkeep kept","ratio":float(r.paid),"value":"%d%%" % roundi(float(r.paid)*100.0),"color":Tokens.GREEN if float(r.paid)>=0.99 else Tokens.RED,"tip":("Every home, road, work building and fine work is kept." if declining.is_empty() else "Too few builders: "+", ".join(declining)+".")}]
	if bool(r.home):
		var bonus:=float(d.get("defense_bonus",0.0))
		bars.insert(4,{"name":"Walls and stone","ratio":clampf(bonus/Fabric.BASTION_BONUS,0.0,1.0),"value":"+%d%%" % roundi(bonus*100.0),"color":Tokens.RED,"tip":"%s at %d%% repair, and %d in 100 of the places stone." % [String(d.get("short","Open ground")),roundi(float(d.get("integrity",1.0))*100.0),roundi(float(r.stone)*100.0)]})
	var spent:Dictionary=r.spent
	var note:="%s free builders" % Fabric._one(float(r.free_builders))
	var blocks:Array=[
		{"type":"segments","heading":"Homes by kind","note":"%d places" % int(r.places),"items":items,"legend":legend},
		{"type":"bars","heading":"The built fabric","note":note,"items":bars}]
	if not declining.is_empty():
		blocks.append({"type":"impact_lines","heading":"Falling into disrepair","compact":false,"lines":[{"label":"Too few builders","value":"%d%% kept" % roundi(float(r.paid)*100.0),
			"words":"The builders keep homes first, then the walls, work buildings, roads and fine works. Now %s. More builders, or fewer works to keep." % ", ".join(declining),"tone":"bad"}]})
	if float(spent.get("upkeep",0.0))+float(spent.get("homes",0.0))+float(spent.get("roads",0.0))+float(spent.get("works",0.0))+float(spent.get("beauty",0.0))>0.0:
		blocks.append({"type":"segments","heading":"Where the builders' days go","note":"last %d days" % int(r.days),"items":_spent_items(spent,float(r.idle)),"legend":"Upkeep first (homes, then the walls, work buildings, roads and fine works), then new work on homes, roads, work buildings and fine works by their share; what one cannot use goes to fine works. Idle: no materials to work with."})
	blocks.append({"type":"impact_lines","heading":"What the built fabric does","compact":true,"columns":3,"lines":Fabric.effect_lines(r)})
	blocks.append({"type":"impact_lines","heading":"What ten more builders would buy now","compact":true,"columns":3,"lines":Fabric.plus_lines(10.0)})
	return blocks

func _spent_items(spent:Dictionary,idle:float)->Array:
	var out:Array=[]
	var parts:=[["upkeep","upkeep",Tokens.MUTED],["homes","homes",Tokens.GREEN],["roads","roads",Tokens.TEAL],["works","work buildings",Tokens.BLUE],["beauty","fine works",Tokens.GOLD],["walls","walls",Tokens.RED]]
	var total:=idle
	for part in parts:total+=float(spent.get(String(part[0]),0.0))
	if total<=0.0:return out
	for part in parts:
		var days:=float(spent.get(String(part[0]),0.0))
		if days/total<0.02:continue
		out.append({"share":days/total,"value":"%d" % roundi(days),"label":String(part[1]),"color":part[2],"tip":"%d builder-days on %s." % [roundi(days),String(part[1])]})
	if idle/total>=0.02:out.append({"share":idle/total,"value":"%d" % roundi(idle),"label":"idle","color":Tokens.RED,"tip":"%d builder-days with no timber, clay or stone to work." % roundi(idle)})
	return out

## "framed construction or timber post-beam connections", from discovery ids.
func _any_words(ids:Array)->String:
	var names:PackedStringArray=[]
	for id in ids:names.append(String(_discovery_name(String(id))))
	return " or ".join(names) if not names.is_empty() else "nothing"

func _discovery_name(id:String)->String:
	var entry:Dictionary=WorldSimulation.discovery.discovery_definition(id) if WorldSimulation.discovery!=null else {}
	return String(entry.get("name",id.replace("_"," "))).to_lower()
