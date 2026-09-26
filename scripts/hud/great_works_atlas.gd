extends Control
## "Our Great Works": every work this people has raised or tried to raise —
## building, standing, flawed, ruins and follies — with lore, layered history,
## effects in plain words, enshrined objects and decrees; "Works of Other
## Peoples" as they are actually known (dated, uncertain); and our legacy in
## stone: our record of works, told as history. Reads the GreatWorks facade; acts only through it,
## through validated civilization orders (restore/loot/return) and through the
## Audience Hall (conceiving a new work). Pauses while open.

signal conceive_requested

const Bridge:=preload("res://scripts/great_works_audience.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Plate:=preload("res://scripts/hud/great_work_plate.gd")
const Kit:=preload("res://scripts/hud/artifact_gallery.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const CULTURE_PATH:="res://scripts/artifact_culture.gd"
const RIVALRY_PATH:="res://scripts/great_works_rivalry.gd"
const CATALOG_PATH:="res://scripts/undertaking_catalog.gd"
const STATUS_WORDS:={"building":"Rising","stalled":"Idle","functioning":"Standing","ruined":"Ruin","abandoned":"Abandoned","rival":"Unfinished","quarried":"Quarried"}

var hud:Node
var terrain:Node
var director:Node
var tab:="ours"
var selected_key:=""
var message:=""
var pause=preload("res://scripts/hud/simulation_pause.gd").new()
var works_list:Array=[]
var foreign_list:Array=[]
var panel:PanelContainer
var list_box:VBoxContainer
var detail_scroll:ScrollContainer
var detail:VBoxContainer
var tab_buttons:Dictionary={}
var legacy_box:HBoxContainer
var toast:Label
var picker:Control

static func open(hud_node:Node,terrain_node:Node=null,director_node:Node=null,focus:String="")->Control:
	var host:Node=hud_node if is_instance_valid(hud_node) else (Engine.get_main_loop() as SceneTree).current_scene
	var previous:Variant=host.get_meta("great_works_atlas") if host.has_meta("great_works_atlas") else null
	if previous is Node and is_instance_valid(previous):(previous as Node).queue_free()
	var canvas:=CanvasLayer.new();canvas.layer=86;canvas.name="GreatWorksLayer";host.add_child(canvas);host.set_meta("great_works_atlas",canvas)
	var view:Control=load("res://scripts/hud/great_works_atlas.gd").new()
	view.hud=hud_node;view.terrain=terrain_node;view.director=director_node;view.selected_key=focus
	canvas.add_child(view)
	return view

func _ready()->void:
	name="GreatWorksAtlas"
	theme=T.control_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause.acquire(terrain if is_instance_valid(terrain) else get_tree().current_scene)
	var dim:=ColorRect.new();dim.color=T.SCRIM;dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(dim)
	dim.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:close())
	panel=PanelContainer.new();panel.name="WorksPanel";panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var style:=T.flat(T.DOCK_BG,T.BORDER_2,1,6);style.content_margin_left=26;style.content_margin_right=26;style.content_margin_top=18;style.content_margin_bottom=16
	style.shadow_color=Color(0,0,0,.4);style.shadow_size=20
	panel.add_theme_stylebox_override("panel",style);add_child(panel)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",10);panel.add_child(root)
	_build_header(root)
	root.add_child(Kit.Flourish.new())
	var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",8);root.add_child(tabs)
	for spec in [["ours","Our Great Works"],["foreign","Works of Other Peoples"]]:
		var id:=String(spec[0])
		var button:=Button.new();button.name="Tab_"+id;button.text=String(spec[1]);button.focus_mode=Control.FOCUS_NONE;button.custom_minimum_size.y=34
		button.add_theme_font_size_override("font_size",14);button.pressed.connect(func()->void:tab=id;selected_key="";refresh())
		tabs.add_child(button);tab_buttons[id]=button
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tabs.add_child(spacer)
	toast=Kit.label(tabs,"",13,T.TEXT_SOFT,false);toast.name="Toast"
	var main:=HBoxContainer.new();main.size_flags_vertical=Control.SIZE_EXPAND_FILL;main.add_theme_constant_override("separation",22);root.add_child(main)
	var list_scroll:=ScrollContainer.new();list_scroll.custom_minimum_size.x=430;list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;main.add_child(list_scroll)
	list_box=VBoxContainer.new();list_box.name="WorkList";list_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list_box.add_theme_constant_override("separation",8);list_scroll.add_child(list_box)
	detail_scroll=ScrollContainer.new();detail_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;main.add_child(detail_scroll)
	detail=VBoxContainer.new();detail.name="WorkDetail";detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_theme_constant_override("separation",10);detail_scroll.add_child(detail)
	get_viewport().size_changed.connect(_fit)
	_fit()
	refresh()

func _exit_tree()->void:
	pause.release()

func _fit()->void:
	var view:=get_viewport().get_visible_rect().size
	# Autowrapped labels report inflated heights before their first sort and a
	# container never shrinks by itself; re-assert the panel size every frame.
	var target:=Vector2(minf(1560,view.x-40),minf(960,view.y-40))
	if panel.size!=target:panel.size=target
	var place:=((view-panel.size)*.5).round()
	if panel.position!=place:panel.position=place

func _process(_delta:float)->void:
	_fit()

func close()->void:
	var layer_node:=get_parent()
	if layer_node is CanvasLayer:layer_node.queue_free()
	else:queue_free()

func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if is_instance_valid(picker):picker.queue_free()
		else:close()

# ---------------------------------------------------------------- header

func _build_header(root:VBoxContainer)->void:
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",24);root.add_child(header)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",3);header.add_child(words)
	Kit.label(words,"WONDERS OF OUR MAKING · CULTURE",11,T.GOLD,false,.12)
	Kit.display(words,"Our Great Works",34)
	var allure:=Bridge.api_dict("allure_contribution",["player"])
	var summary:=Kit.serif(words,"Every work is our own idea, raised or failed by our own hands. Together they lend us %.1f allure." % float(allure.get("value",0)),16,T.BODY,true)
	summary.name="AllureSummary"
	legacy_box=HBoxContainer.new();legacy_box.name="Legacy";legacy_box.add_theme_constant_override("separation",16);header.add_child(legacy_box)
	_build_legacy()
	var actions:=VBoxContainer.new();actions.add_theme_constant_override("separation",8);header.add_child(actions)
	var conceive:=Kit.action_button(actions,"Conceive a great work",conceive_work,true,"Call the court: pitch a wonder worthy of our people")
	conceive.name="ConceiveButton";conceive.custom_minimum_size=Vector2(230,42)
	# Master builders holding matters of their own (pitches, news, forecasts) can be called in.
	var builders:=0
	for entry:Dictionary in Hall.summonable():
		if String(entry.get("role",""))!="architect" or builders>=2:continue
		builders+=1
		var target:Dictionary=(entry.get("target",{}) as Dictionary).duplicate()
		var held:=int(entry.get("matters",0))
		var call:=Kit.action_button(actions,"Summon %s%s" % [String(entry.get("name","the master builder")),(" · %d" % held) if held>0 else ""],func()->void:_summon(target),false,"Call them before you in the court now")
		call.name="SummonBuilder%d" % builders;call.custom_minimum_size=Vector2(230,36)
	var close_button:=Kit.action_button(actions,"Close",close,false,"Close · Escape")
	close_button.name="CloseWorks"

func _record()->Dictionary:
	var path:="res://scripts/undertaking_rewards.gd"
	if not ResourceLoader.exists(path):return {}
	var rewards:=load(path) as GDScript
	if not Bridge._has(rewards,"history"):return {}
	var value:Variant=rewards.call("history",GameState)
	return value if value is Dictionary else {}

func _build_legacy()->void:
	## Our record of great works: history, not a race.
	for child in legacy_box.get_children():child.queue_free()
	var h:=_record()
	var col:=VBoxContainer.new();col.name="Record";col.add_theme_constant_override("separation",2);legacy_box.add_child(col)
	Kit.label(col,"OUR RECORD OF GREAT WORKS",11,T.GOLD,false,.12)
	Kit.label(col,"%d attempted · %d stood · %d fell as follies" % [int(h.get("attempted",0)),int(h.get("succeeded",0)),int(h.get("follies",0))],13,T.BODY,false)
	Kit.label(col,"%d standing now · %d endured twenty years" % [int(h.get("standing",0)),int(h.get("enduring",0))],13,T.BODY,false)
	Kit.label(col,"%d purposes served · known to %d foreign people%s" % [int(h.get("kinds",0)),int(h.get("known_by",0)),"" if int(h.get("known_by",0))==1 else "s"],13,T.TEXT_SOFT,false)
	if int(h.get("costly",0))>0:Kit.label(col,"%d built through hardship, and remembered for it" % int(h.costly),13,T.AMBER,false)

# ---------------------------------------------------------------- data

func refresh()->void:
	works_list=Bridge.api_list("works",["player"])
	foreign_list=Bridge.api_list("known_foreign_works",["player"])
	for id in tab_buttons:
		var button:Button=tab_buttons[id]
		var on:=String(id)==tab
		button.add_theme_stylebox_override("normal",T.flat(T.GOLD_WASH if on else T.BUTTON_BG,T.GOLD if on else T.BORDER_SOFT,1,3,6))
		button.add_theme_color_override("font_color",T.GOLD_BRIGHT if on else T.BODY)
	for child in list_box.get_children():child.queue_free()
	var items:Array=works_list if tab=="ours" else foreign_list
	if items.is_empty():
		var empty:=Kit.serif(list_box,"No great work has been attempted yet. Call the court and hear what they dream of." if tab=="ours" else "No word has reached us of other peoples' great works. Scouts, envoys and travelers bring such news home.",15,T.TEXT_SOFT,true)
		empty.name="EmptyNote"
	for item in items:
		if not item is Dictionary:continue
		var key:=_key(item)
		if selected_key.is_empty():selected_key=key
		list_box.add_child(_card(item,key==selected_key))
	for child in detail.get_children():child.queue_free()
	for item in items:
		if item is Dictionary and _key(item)==selected_key:
			if tab=="ours":_detail_ours(item)
			else:_detail_foreign(item)
	if tab=="foreign":_held_by_occupation()
	toast.text=message

func _key(item:Dictionary)->String:
	return "%s/%s/%s" % [String(item.get("owner","player")),String(item.get("city_id",item.get("local_city_id",""))),String(item.get("work_id",item.get("id",item.get("title",""))))]

func select(key:String)->void:
	selected_key=key;refresh()

func _status_words(item:Dictionary)->String:
	var status:=String(item.get("status",""))
	var outcome:=String(item.get("outcome",""))
	if status=="ruined" and outcome=="collapse":return "Folly · fallen"
	if status in ["building","stalled"]:
		return "%s · %s · %d%%" % [String(STATUS_WORDS.get(status,"Rising")),String(Bridge.STAGE_WORDS.get(String(item.get("stage","")),"")),roundi(float(item.get("progress",0))*100)]
	if status=="functioning" and outcome=="triumph":return "Standing · a triumph"
	if status=="functioning" and outcome=="flawed":return "Standing · flawed"
	return String(STATUS_WORDS.get(status,status.capitalize()))

func _status_color(item:Dictionary)->Color:
	var status:=String(item.get("status",""))
	if status=="ruined" or status=="abandoned":return T.RED
	if status in ["building","stalled"]:return T.AMBER
	if String(item.get("outcome",""))=="flawed":return T.AMBER
	return T.GREEN

func _card(item:Dictionary,active:bool)->Control:
	var key:=_key(item)
	var card:=PanelContainer.new();card.name="Card_"+String(item.get("work_id",item.get("title",""))).replace(":","_").replace("/","_");card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	var style:=T.flat(T.ACTIVE_BG if active else T.TILE_BG,T.GOLD if active else Color(0,0,0,0),2 if active else 0,6,0)
	style.border_width_left=5;style.border_color=T.GOLD if active else _status_color(item)
	style.content_margin_left=8;style.content_margin_right=10;style.content_margin_top=6;style.content_margin_bottom=6
	card.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row)
	var art:=Plate.make(item,76);art.custom_minimum_size=Vector2(112,76);row.add_child(art)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",1);words.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(words)
	var title:=String(item.get("name",item.get("title","A great work")))
	var who:=""
	if tab=="foreign":
		who=String(item.get("civ_name","an unknown people"))
		var flag:=TextureRect.new();flag.texture=Identity.foreign(String(item.get("owner",""))).texture;flag.custom_minimum_size=Vector2(26,30);flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(flag);row.move_child(flag,0)
	var name_label:=Kit.serif(words,title,17,T.INK);name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var line:=_status_words(item) if tab=="ours" else "%s · as of day %d" % [who,int(item.get("day",0))]
	var status:=Kit.label(words,line,12,_status_color(item) if tab=="ours" else T.TEXT_SOFT,false);status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var place:=Kit.label(words,String(item.get("city_name","")),12,T.TEXT_DIM,false);place.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:select(key))
	return card

# ---------------------------------------------------------------- our works

func _definition(work_id:String)->Dictionary:
	if not ResourceLoader.exists(CATALOG_PATH):return {}
	var value:Variant=(load(CATALOG_PATH) as GDScript).call("get_definition",work_id)
	return value if value is Dictionary else {}

func _section(text:String)->void:
	var head:=Kit.label(detail,text,11,T.GOLD,false,.12)
	head.custom_minimum_size.y=18

func _detail_ours(item:Dictionary)->void:
	var work_id:=String(item.get("work_id",""))
	var city_id:=String(item.get("city_id",""))
	var site:=Bridge.api_dict("site",[city_id,work_id])
	var d:=_definition(work_id)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",20);detail.add_child(top)
	var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",T.flat(Color("f3e7cc"),T.GOLD,1,4,4));top.add_child(frame)
	var view:=item.duplicate(true);view.merge(site,false)
	var art:=Plate.make(view,210);art.name="DetailPlate";art.custom_minimum_size=Vector2(320,210);frame.add_child(art)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",4);top.add_child(words)
	Kit.display(words,String(item.get("name","A great work")),26)
	var concept:Dictionary=site.get("concept",{}) if site.get("concept") is Dictionary else {}
	var shape:=String(item.get("form",""))
	if shape.is_empty() and not concept.is_empty():shape=Bridge.concept_form(concept)
	var purpose:=Bridge.purpose_label(String(item.get("purpose","")))
	Kit.serif(words,"A %s%s · %s ambition · %s" % [shape.replace("_"," "),(" raised to %s" % purpose) if not purpose.is_empty() else "",String(item.get("ambition","grand")).capitalize(),String(item.get("city_name",""))],15,T.BODY,true)
	var status:=Kit.label(words,_status_words(item),14,_status_color(item),false,.04);status.name="StatusLine"
	var lore:=String(item.get("ruin_lore","")) if String(item.get("status",""))=="ruined" else ""
	if lore.is_empty():lore=String(item.get("lore",""))
	if not lore.is_empty():Kit.serif(words,lore,15,T.TEXT_SOFT,true)
	var motive:=String(concept.get("motive",""))
	if not motive.is_empty():Kit.label(words,motive.substr(0,1).to_upper()+motive.substr(1),13,T.TEXT_DIM)
	var architect:=String(item.get("architect",""))
	var arch:Dictionary=site.get("architect",{}) if site.get("architect") is Dictionary else {}
	if not architect.is_empty():Kit.label(words,"Master builder: %s%s" % [architect,(" — %s in style" % String(arch.get("style",""))) if not String(arch.get("style","")).is_empty() else ""],13,T.BODY)
	var figure_id:=String(arch.get("id",""))
	if not figure_id.is_empty() and not architect.is_empty():
		var held:=int(Hall.matter_counts().get("figure:"+figure_id,0))
		var summon_button:=Kit.action_button(words,"Summon %s to the court%s" % [architect,(" · %d matter%s" % [held,"" if held==1 else "s"]) if held>0 else ""],func()->void:_summon({"figure_id":figure_id,"name":architect}),false,"Call the master builder in now")
		summon_button.name="SummonArchitect"
	var status_key:=String(item.get("status",""))
	if status_key in ["building","stalled"]:
		_section("THE WORKS")
		var bar:=ProgressBar.new();bar.name="Progress";bar.min_value=0;bar.max_value=1;bar.value=float(item.get("progress",0));bar.show_percentage=false;bar.custom_minimum_size.y=12;detail.add_child(bar)
		Kit.label(detail,String(site.get("reason","")),13,T.TEXT_SOFT)
		var assessment:Dictionary=site.get("assessment",{}) if site.get("assessment") is Dictionary else {}
		if not assessment.is_empty():
			var odds:=Kit.serif(detail,"The court reckons it %s. %s" % [Bridge.odds_words(float(assessment.get("score",.5))),String(assessment.get("spoken",""))],15,T.INK,true)
			odds.name="OddsWords"
		var decision:Dictionary=site.get("decision",{}) if site.get("decision") is Dictionary else {}
		if not decision.is_empty():
			var hear:=Kit.action_button(detail,"Hear the master builder: %s" % String(decision.get("prompt","a decision awaits")).substr(0,90),func()->void:_hear_decision(work_id,city_id),true)
			hear.name="HearBuilder"
	if status_key=="functioning":
		_section("WHAT IT DOES FOR US")
		var effect_text:=String(site.get("effect_text",""))
		var reward:=String(site.get("reward_text",""))
		if not reward.is_empty():Kit.label(detail,"◆  "+reward,14,T.BODY)
		if not effect_text.is_empty() and not reward.contains(effect_text):Kit.label(detail,"◆  "+effect_text,14,T.BODY)
		Kit.label(detail,"Condition %s · maintained %.1f years · known to %d other peoples" % [_condition_words(float(item.get("condition",1))),float(site.get("operating_days",0))/365.0,(site.get("heard_by",{}) as Dictionary).size() if site.get("heard_by") is Dictionary else 0],13,T.TEXT_SOFT)
		var decree:Dictionary=d.get("decree",{}) if d.get("decree") is Dictionary else {}
		if not decree.is_empty():
			_section("ITS DECREE")
			var decree_row:=HBoxContainer.new();decree_row.add_theme_constant_override("separation",12);detail.add_child(decree_row)
			var decree_words:=VBoxContainer.new();decree_words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;decree_row.add_child(decree_words)
			Kit.serif(decree_words,String(decree.get("label","")),16,T.INK)
			Kit.label(decree_words,String(decree.get("text","")),13,T.TEXT_SOFT)
			var proclaim:=Kit.action_button(decree_row,"Proclaim",func()->void:_proclaim(String(decree.get("label","")),String(decree.get("text",""))),false,"Issue it to the civic council as a decree")
			proclaim.name="ProclaimDecree"
			proclaim.disabled=not (is_instance_valid(terrain) and terrain.has_method("issue_civic_directive_text"))
		_shrine(site,d,work_id,city_id)
		_war_actions(item,site,work_id,city_id)
	_history(site)

func _condition_words(value:float)->String:
	if value>=.9:return "excellent"
	if value>=.7:return "good"
	if value>=.5:return "worn"
	if value>=.3:return "failing"
	return "near ruin"

func _history(site:Dictionary)->void:
	var events:Array=site.get("events",[])
	var layers:Array=site.get("layers",[])
	if events.is_empty() and layers.is_empty():return
	_section("ITS HISTORY")
	for layer in layers:
		if layer is Dictionary:
			Kit.label(detail,"Beneath it: %s, Years %d–%d%s" % [String(layer.get("name",layer.get("title",""))),int(float(layer.get("from",0))/365.0)+1,int(float(layer.get("to",0))/365.0)+1,(" · "+String(layer.get("outcome",""))) if not String(layer.get("outcome","")).is_empty() else ""],13,T.TEXT_SOFT)
	for event in events:
		if not event is Dictionary:continue
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);detail.add_child(row)
		var when:=Kit.label(row,"Year %d · Day %d" % [int(float(event.get("day",0))/365.0)+1,int(event.get("day",0))%365+1],12,T.TEXT_DIM,false);when.custom_minimum_size.x=120
		Kit.label(row,String(event.get("text","")),13,T.BODY)

# ---------------------------------------------------------------- enshrining

func _culture()->GDScript:
	return load(CULTURE_PATH) as GDScript if ResourceLoader.exists(CULTURE_PATH) else null

func _shrine(site:Dictionary,d:Dictionary,work_id:String,city_id:String)->void:
	var slots:=int(d.get("shrine_slots",0))
	if slots<=0:return
	_section("ENSHRINED HERE · %d PLACE%s" % [slots,"" if slots==1 else "S"])
	var shelf:=HBoxContainer.new();shelf.name="Shrine";shelf.add_theme_constant_override("separation",10);detail.add_child(shelf)
	var enshrined:Array=site.get("enshrined",[])
	var culture:=_culture()
	for index in mini(slots,8):
		if index<enshrined.size():
			var item:Dictionary={}
			if culture!=null:
				var found:Variant=culture.call("artifact",String(enshrined[index]))
				if found is Dictionary:item=found
			if item.is_empty():item={"id":String(enshrined[index]),"name":"An enshrined object","rarity_index":0}
			var plate_art:=Kit.mini_plate(item,96,Callable());plate_art.name="Enshrined_%d" % index;shelf.add_child(plate_art)
		else:
			var empty:=Button.new();empty.name="Enshrine_%d" % index;empty.text="+\nEnshrine";empty.custom_minimum_size=Vector2(96,96);empty.focus_mode=Control.FOCUS_NONE
			empty.add_theme_stylebox_override("normal",T.flat(Color(0,0,0,0),T.BORDER_SOFT,1,4,0));empty.add_theme_stylebox_override("hover",T.flat(T.GOLD_WASH,T.GOLD,1,4,0))
			empty.tooltip_text="Place a studied artifact here; pilgrims will come to see it"
			empty.pressed.connect(func()->void:open_enshrine_picker(work_id,city_id))
			shelf.add_child(empty)

func enshrine_candidates()->Array:
	var culture:=_culture()
	if culture==null:return []
	var page:Variant=culture.call("artifacts",{"status":"all","sort":"prestige","page":0,"page_size":200})
	var items:Array=(page as Dictionary).get("items",[]) if page is Dictionary else []
	var taken:={}
	for work in works_list:
		if not work is Dictionary:continue
		var site:=Bridge.api_dict("site",[String(work.get("city_id","")),String(work.get("work_id",""))])
		for id in site.get("enshrined",[]):taken[String(id)]=true
	var result:Array=[]
	for item in items:
		if item is Dictionary and not taken.has(String((item as Dictionary).get("id",""))):result.append(item)
	return result

func open_enshrine_picker(work_id:String,city_id:String)->Control:
	if is_instance_valid(picker):picker.queue_free()
	var box:=PanelContainer.new();box.name="EnshrinePicker";picker=box
	box.add_theme_stylebox_override("panel",T.flat(T.DOCK_BG,T.GOLD,2,6,14))
	add_child(box)
	var col:=VBoxContainer.new();col.add_theme_constant_override("separation",8);box.add_child(col)
	Kit.display(col,"Choose an object to enshrine",22)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(760,420);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
	var grid:=GridContainer.new();grid.columns=6;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);scroll.add_child(grid)
	var candidates:=enshrine_candidates()
	if candidates.is_empty():Kit.label(col,"Our people hold no artifacts that could be enshrined.",14,T.TEXT_SOFT)
	for item in candidates:
		var cell:=VBoxContainer.new();cell.custom_minimum_size.x=112;grid.add_child(cell)
		var id:=String((item as Dictionary).get("id",""))
		cell.add_child(Kit.mini_plate(item,104,func(_id:String)->void:enshrine(work_id,city_id,id)))
		var caption:=Kit.label(cell,String((item as Dictionary).get("name","")),11,T.BODY);caption.max_lines_visible=2
	Kit.action_button(col,"Cancel",func()->void:box.queue_free())
	box.reset_size()
	box.position=((get_viewport().get_visible_rect().size-box.get_combined_minimum_size())*.5).round()
	return box

func enshrine(work_id:String,city_id:String,artifact_id:String)->Dictionary:
	var answer:=Bridge.api_dict("enshrine",[city_id,work_id,artifact_id])
	message=String(answer.get("message",answer.get("error","")))
	if is_instance_valid(picker):picker.queue_free()
	refresh()
	return answer

# ---------------------------------------------------------------- war and decrees

func _rivalry()->GDScript:
	return load(RIVALRY_PATH) as GDScript if ResourceLoader.exists(RIVALRY_PATH) else null

func order(kind:String,fields:Dictionary)->Dictionary:
	## Every war action goes through the validated civilization orders.
	var command:=fields.duplicate();command["kind"]=kind
	var answer:Dictionary=WorldSimulation.submit("player",command)
	message=String(answer.get("message",answer.get("error","")))
	refresh()
	return answer

func _war_actions(item:Dictionary,site:Dictionary,work_id:String,city_id:String)->void:
	var buttons:Array=[]
	if float(item.get("condition",1))<.98 and String(item.get("occupied_by","")).is_empty():
		buttons.append(["RestoreButton","Restore it","Repair up to a third of the wear from local stores",func()->void:order("great_work_restore",{"city":city_id,"id":work_id})])
	var rivalry:Dictionary=site.get("rivalry",{}) if site.get("rivalry") is Dictionary else {}
	var looted:=0
	for entry in rivalry.get("looted",[]):
		if entry is Dictionary and not bool(entry.get("returned",false)):looted+=1
	if looted>0:
		var line:=Kit.label(detail,"%d enshrined treasure%s carried off by occupiers and not returned." % [looted,"" if looted==1 else "s"],13,T.RED)
		line.name="LootedNote"
	if buttons.is_empty():return
	_section("CARE AND CONFLICT")
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);detail.add_child(row)
	for spec:Array in buttons:
		var button:=Kit.action_button(row,String(spec[1]),spec[3],false,String(spec[2]));button.name=String(spec[0])

func _held_by_occupation()->void:
	var rivalry:=_rivalry()
	if rivalry==null or not Bridge._has(rivalry,"held_works"):return
	var held:Variant=rivalry.call("held_works","player")
	if not held is Array:return
	var shown:=false
	for entry in held:
		if not entry is Dictionary or not bool((entry as Dictionary).get("captured",false)):continue
		if not shown:
			_section("WORKS IN CITIES OUR ARMIES HOLD")
			shown=true
		var r:Dictionary=entry.get("record",{})
		var civ_owner:=String(entry.get("owner",""))
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);detail.add_child(row)
		Kit.label(row,"%s at %s" % [Bridge.work_title(r),String(entry.get("city_name",""))],14,T.BODY)
		var enshrined:Array=r.get("enshrined",[])
		var loot:=Kit.action_button(row,"Carry off its treasures (%d)" % enshrined.size(),func()->void:order("great_work_loot",{"owner":civ_owner,"city":String(entry.get("city_id","")),"id":String(r.get("id",""))}),false,"Every people that hears of it will judge us")
		loot.name="LootButton"
		loot.disabled=enshrined.is_empty()
	for work in foreign_list:
		if not work is Dictionary:continue
		var owner2:=String(work.get("owner",""))
		if _holds_loot_from(owner2,String(work.get("work_id",""))):
			var row2:=HBoxContainer.new();row2.add_theme_constant_override("separation",10);detail.add_child(row2)
			Kit.label(row2,"We hold treasures taken from %s." % String(work.get("title",work.get("name","their work"))),14,T.BODY)
			var give:=Kit.action_button(row2,"Return them",func()->void:order("great_work_return_loot",{"owner":owner2,"id":String(work.get("work_id",""))}),false,"Their people will remember the gesture")
			give.name="ReturnLootButton"

func _holds_loot_from(civ_owner:String,work_id:String)->bool:
	var rivalry:=_rivalry()
	if rivalry==null or not Bridge._has(rivalry,"cities") or civ_owner.is_empty():return false
	var owned:Variant=rivalry.call("cities",civ_owner)
	if not owned is Array:return false
	for city in owned:
		if not city is Dictionary:continue
		for r in (city as Dictionary).get("undertakings",[]):
			if not r is Dictionary or String((r as Dictionary).get("id",""))!=work_id:continue
			for entry in ((r as Dictionary).get("rivalry",{}) as Dictionary).get("looted",[]):
				if entry is Dictionary and String(entry.get("by",""))=="player" and not bool(entry.get("returned",false)):return true
	return false

func _proclaim(label_text:String,text:String)->void:
	if is_instance_valid(terrain) and terrain.has_method("issue_civic_directive_text"):
		terrain.issue_civic_directive_text("%s: %s" % [label_text,text])
		message="Proclaimed: %s." % label_text
		refresh()

func _summon(target:Dictionary)->void:
	if not is_instance_valid(director) or not director.has_method("summon"):return
	close()
	director.summon(target)

func _hear_decision(work_id:String,city_id:String)->void:
	var made:=Bridge.decision_audience(work_id,city_id,true)
	var id:=String(made.get("id",""))
	if id.is_empty():
		for audience:Dictionary in Bridge._waiting_of("great_work"):
			if String((audience.get("great_work",{}) as Dictionary).get("work_id",""))==work_id:id=String(audience.id)
	if not id.is_empty() and is_instance_valid(director) and director.has_method("open_audience"):
		close()
		director.open_audience(id)

## Calls the court for a new work: a wonder pitch in the Audience Hall.
func conceive_work()->Dictionary:
	var made:=Bridge.ruler_proposal()
	conceive_requested.emit()
	if not made.is_empty() and is_instance_valid(director) and director.has_method("open_audience"):
		close()
		director.open_audience(String(made.id))
	elif made.is_empty():
		message="Nobody at court can carry a proposal just now."
		refresh()
	return made

# ---------------------------------------------------------------- other peoples

func _detail_foreign(item:Dictionary)->void:
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",20);detail.add_child(top)
	var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",T.flat(Color("f3e7cc"),T.BORDER_2,1,4,4));top.add_child(frame)
	var art:=Plate.make(item,200);art.name="ForeignPlate";art.custom_minimum_size=Vector2(300,200);frame.add_child(art)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",5);top.add_child(words)
	Kit.display(words,String(item.get("title",item.get("name","A great work"))),24)
	var who:=HBoxContainer.new();who.add_theme_constant_override("separation",8);words.add_child(who)
	var flag:=TextureRect.new();flag.texture=Identity.foreign(String(item.get("owner",""))).texture;flag.custom_minimum_size=Vector2(28,32);flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;who.add_child(flag)
	Kit.serif(who,"%s · %s" % [String(item.get("civ_name","an unknown people")),String(item.get("city_name","a place we have not seen"))],16,T.BODY)
	var age:=int(item.get("age_days",0))
	var dated:=Kit.label(words,"As of day %d (%s) · %s · confidence %s" % [int(item.get("day",0)),"today" if age<=0 else "%d days old" % age,String(item.get("source","hearsay")),_confidence(float(item.get("confidence",.5)))],13,T.TEXT_SOFT)
	dated.name="DatedLine"
	if bool(item.get("stale",false)):Kit.label(words,"This word is old; the truth may have moved on.",13,T.AMBER)
	var status:=String(item.get("status",""))
	if status in ["building","stalled"]:
		Kit.label(words,"Perhaps %d–%d%% raised when last seen." % [roundi(float(item.get("progress_low",0))*100),roundi(float(item.get("progress_high",1))*100)],14,T.BODY)
	Kit.serif(detail,String(item.get("text","")),15,T.INK,true)

func _confidence(value:float)->String:
	if value>=.75:return "high"
	if value>=.55:return "fair"
	return "low"

# ---------------------------------------------------------------- drawn pieces

