extends VBoxContainer
## READINESS & SUPPLY, as HOI4's logistics view: numbers, bars and glyphs;
## the reasons live in the tooltips.
##
##   strip   who carries our food (porters, carts or lorries) and how many,
##           the share of the fighters' need they can move, our hubs and
##           depots, the rations eaten a day and the gear being mended, and
##           one click to the supply map (hud/supply_map.gd)
##   rows    one per force (hud/readiness_model.gd, supply_state.forces()):
##           its supply bar in the state's colour, the hub it draws on with
##           days and km along the line, a hungry-days badge, and its gear
##           shortfalls (equipment_logistics.gd); a shortfall opens
##           Production, as the recruit board's amber gear bar does.
## The staff hand out the gear and the quartermasters run the carts; nothing
## here is a form to fill in.

signal close_wanted

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Model:=preload("res://scripts/hud/readiness_model.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Board:=preload("res://scripts/hud/recruit_deploy_board.gd")
const Forces:=preload("res://scripts/hud/forces_board.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const SupplyMap:=preload("res://scripts/hud/supply_map.gd")
## Below this width a row puts its line and gear on a second line.
const WIDE_FROM:=940.0
const REFRESH_SECONDS:=0.5
const CARRIER_GLYPH:={"foot":"porter","wheeled":"cart","motor":"lorry"}

## The HUD shell and the map; found from the running scene when not given.
var hud:Node
var terrain:Node
var wide:=true
var chips:Dictionary={}
var header:HBoxContainer
var list:VBoxContainer
var map_button:Button
var live:Array[Dictionary]=[]
var rows:Array[Dictionary]=[]
var signature:=""
var clock:=0.0


func setup(block:Dictionary={})->void:
	name="ReadinessBoard"
	if block.has("hud"):hud=block.hud
	if block.has("terrain"):terrain=block.terrain
	if block.has("width"):wide=float(block.width)>=WIDE_FROM
	add_theme_constant_override("separation",10)
	theme=_theme()
	_build_strip()
	# The column heads sit over the rows' own columns (a row's paper has an 8 px margin).
	var head:=MarginContainer.new();head.name="Head";head.add_theme_constant_override("margin_left",8);head.add_theme_constant_override("margin_right",8);add_child(head)
	header=HBoxContainer.new();header.name="Header";header.add_theme_constant_override("separation",10);head.add_child(header)
	list=VBoxContainer.new();list.name="Rows";list.add_theme_constant_override("separation",6);add_child(list)
	refresh(true)


func _theme()->Theme:
	var skin:=Theme.new()
	skin.default_font=T.FONT_UI;skin.default_font_size=14
	skin.set_stylebox("normal","Button",T.action_button_style(false));skin.set_stylebox("hover","Button",T.action_button_style(false,true))
	skin.set_stylebox("pressed","Button",T.button_pressed_style());skin.set_stylebox("hover_pressed","Button",T.button_pressed_style())
	skin.set_stylebox("disabled","Button",T.button_disabled_style());skin.set_stylebox("focus","Button",StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:skin.set_color(state,"Button",T.INK)
	skin.set_color("font_disabled_color","Button",T.DISABLED);skin.set_font_size("font_size","Button",14)
	skin.set_color("font_color","Label",T.INK)
	T.add_tooltip_style(skin)
	return skin


func _glyph(parent:Node,texture:Texture2D,side:float=16.0)->TextureRect:
	var mark:=TextureRect.new();mark.texture=texture;mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size=Vector2(side,side);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(mark);return mark


## A label shown whole: its words never trimmed, its width their width.
func _whole(label:Label)->Label:
	label.clip_text=false;label.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
	return label


func _text(parent:Node,text:String,size:int,color:Color,strong:bool=false,min_width:float=0.0)->Label:
	var label:=T.make_label(text,size,color)
	if strong:label.add_theme_font_override("font",T.font("ui_strong"))
	label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size.x=min_width;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label);return label


func _box(parent:Node,vertical:bool,min_width:float=0.0,gap:int=4)->BoxContainer:
	var box:BoxContainer
	if vertical:box=VBoxContainer.new()
	else:box=HBoxContainer.new()
	box.add_theme_constant_override("separation",gap);box.mouse_filter=Control.MOUSE_FILTER_PASS
	box.custom_minimum_size.x=min_width;box.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	parent.add_child(box);return box


# --- The strip --------------------------------------------------------------------

func _build_strip()->void:
	var panel:=PanelContainer.new();panel.name="Strip";panel.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CARD,10));add_child(panel)
	var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",24);row.add_theme_constant_override("v_separation",6);panel.add_child(row)
	for spec:Array in [["carriers","porters"],["carried","of the need carried"],["hubs","hubs"],["depots","depots"],["rations","rations a day"],["repair","being mended"]]:
		var chip:=HBoxContainer.new();chip.name="Chip_"+String(spec[0]);chip.add_theme_constant_override("separation",7);chip.mouse_filter=Control.MOUSE_FILTER_STOP;row.add_child(chip)
		var icon:=_glyph(chip,null,22.0)
		var value:=_text(chip,"0",19,T.INK,true);_whole(value)
		var word:=_text(chip,String(spec[1]),13,T.INK_MUTED);_whole(word);word.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		chips[String(spec[0])]={"chip":chip,"icon":icon,"value":value,"word":word}
	chips.carried.icon.texture=Icons.command_texture("supply",T.INK,48)
	chips.hubs.icon.texture=Icons.logistics_texture("hub",T.INK,48)
	chips.depots.icon.texture=Icons.logistics_texture("depot",T.INK,48)
	chips.rations.icon.texture=Icons.people_texture("fed",T.INK,48,false)
	chips.repair.icon.texture=Icons.workshop_texture("mend",T.INK,24)
	map_button=Button.new();map_button.name="ShowSupplyMap";map_button.text="Show supply on map";map_button.focus_mode=Control.FOCUS_NONE
	map_button.icon=Icons.logistics_texture("find",T.INK,40);map_button.add_theme_constant_override("icon_max_width",16);map_button.add_theme_constant_override("h_separation",5)
	map_button.custom_minimum_size=Vector2(0,30);map_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	map_button.tooltip_text="Show where our fighters can be fed, and our supply lines, on the map."
	map_button.pressed.connect(show_supply_on_map);row.add_child(map_button)


func _update_strip(s:Dictionary)->void:
	var who:=String(s.carrier)
	chips.carriers.icon.texture=Icons.logistics_texture(String(CARRIER_GLYPH.get(who,"porter")),T.INK,48)
	var count:=int(s.carts) if who!="foot" else int(s.haulers)
	chips.carriers.value.text=EraWords.grouped(count)
	chips.carriers.word.text=String(s.carrier_words)
	var loss:=roundi(float((Supply.CARRIERS.get(who,Supply.CARRIERS.foot) as Dictionary).loss)*100.0)
	chips.carriers.chip.tooltip_text="Our %s carry the fighters' food from the stores: %s haulers and %s carts.\nThey eat about %d%% of a load for each day of hauling." % [String(s.carrier_words),EraWords.grouped(int(s.haulers)),EraWords.grouped(int(s.carts)),loss]
	var transport:=float(s.transport)
	chips.carried.value.text="%d%%" % roundi(transport*100.0)
	chips.carried.value.add_theme_color_override("font_color",Supply.state_text_color(Supply.state_of(transport)))
	var carried_tip:="Our carriers can move %d%% of what the fighters need.\nMore haulers, carts and a careful commander carry more." % roundi(transport*100.0)
	if float(s.stores)<0.97:carried_tip+="\nThe stores are short: %d%% of the people's food came in." % roundi(float(s.stores)*100.0)
	if float(s.siege)<1.0:carried_tip+="\nHome is besieged: %d%% of the carts get out." % roundi(float(s.siege)*100.0)
	chips.carried.chip.tooltip_text=carried_tip
	var hubs:Array=s.hubs;var depots:Array=s.depots
	chips.hubs.value.text=str(hubs.size());chips.hubs.word.text="hub" if hubs.size()==1 else "hubs"
	chips.hubs.chip.tooltip_text="Our stores the carts load from: %s." % ", ".join(hubs) if not hubs.is_empty() else "No stores to load from."
	chips.depots.value.text=str(depots.size());chips.depots.word.text="depot" if depots.size()==1 else "depots"
	chips.depots.chip.visible=not depots.is_empty()
	chips.depots.chip.tooltip_text="Towns we hold, where the carts rest and stores gather: %s.\nA line from a depot starts at half the haul of reaching it." % ", ".join(depots)
	chips.rations.value.text=_amount(float(s.rations))
	chips.rations.chip.tooltip_text="The fighters eat about %s rations a day, at home and in the field." % _amount(float(s.rations))
	var mending:Dictionary=s.mending
	chips.repair.value.text=str(int(mending.count))
	chips.repair.chip.tooltip_text=("Gear being mended:\n"+"\n".join(mending.lines)) if not (mending.lines as Array).is_empty() else "Nothing broken is waiting."
	map_button.visible=_map_terrain()!=null
	if map_button.visible:map_button.disabled=SupplyMap.is_shown(_map_terrain())


func _amount(value:float)->String:
	return "0" if value<0.05 else ("%.1f" % value if value<10.0 else EraWords.grouped(roundi(value)))


# --- The supply map ---------------------------------------------------------------

func _map_terrain()->Node:
	if is_instance_valid(terrain):return terrain
	var scene:=get_tree().current_scene if is_inside_tree() else null
	return scene if scene!=null and "hud" in scene else null


## One click to HOI4's supply map mode: the supply map's own switch
## (hud/supply_map.gd set_shown); this screen closes so the map is in view.
func show_supply_on_map()->void:
	var map:=_map_terrain()
	if map==null:return
	SupplyMap.set_shown(map,true)
	close_wanted.emit()


# --- Rows ---------------------------------------------------------------------------

func refresh(force:bool=false)->void:
	rows=Model.rows()
	_update_strip(Model.strip())
	var shape:=str([wide,rows.map(func(r:Dictionary)->Array:return [r.key,(r.short as Array).map(func(e:Dictionary)->String:return String(e.item))])])
	if force or shape!=signature:
		signature=shape
		_rebuild()
	else:
		_update_values()


func _rebuild()->void:
	for child in header.get_children():header.remove_child(child);child.queue_free()
	for child in list.get_children():list.remove_child(child);child.queue_free()
	live.clear()
	(header.get_parent() as Control).visible=wide and not rows.is_empty()
	if wide:
		for spec:Array in [["Force",256.0],["Fed",170.0],["Line to stores",214.0],["Hungry",96.0],["Gear short",0.0]]:
			var kicker:=_text(header,String(spec[0]).to_upper(),12,T.INK_MUTED,true,float(spec[1]))
			_whole(kicker)
	if rows.is_empty():
		var panel:=PanelContainer.new();panel.name="Empty";panel.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CARD,14));list.add_child(panel)
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);panel.add_child(line)
		_glyph(line,Icons.command_texture("supply",T.INK_MUTED,48),22.0)
		var words:=_text(line,"No one is under arms, so no one to feed.",14,T.INK_MUTED);_whole(words)
		return
	for row:Dictionary in rows:_row(row)
	_update_values()


func _row(row:Dictionary)->void:
	var panel:=PanelContainer.new();panel.name="Row_"+String(row.key).replace(":","_");panel.mouse_filter=Control.MOUSE_FILTER_PASS
	var style:=T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD,8);style.content_margin_top=5;style.content_margin_bottom=5
	panel.add_theme_stylebox_override("panel",style);list.add_child(panel)
	var lines:=VBoxContainer.new();lines.add_theme_constant_override("separation",4);lines.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(lines)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",10);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;lines.add_child(top)
	var sack:=_glyph(top,null,18.0)
	var frame:=Panel.new();frame.clip_contents=true;frame.custom_minimum_size=Vector2(28,34);frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK));top.add_child(frame)
	var face:=TextureRect.new();face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);face.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.add_child(face)
	var who:=_box(top,true,190.0 if wide else 130.0,0);who.size_flags_horizontal=Control.SIZE_EXPAND_FILL if not wide else Control.SIZE_FILL
	var title:=_text(who,"",14,T.INK,true)
	var men:=_text(who,"",12,T.INK_MUTED)
	var meter:=Board.Meter.new();meter.kind="supply";meter.name="Supply";meter.size_flags_vertical=Control.SIZE_SHRINK_CENTER;top.add_child(meter)
	meter.custom_minimum_size.x=170.0;meter.mouse_filter=Control.MOUSE_FILTER_PASS
	var second:HBoxContainer=top
	if not wide:
		second=HBoxContainer.new();second.add_theme_constant_override("separation",10);second.mouse_filter=Control.MOUSE_FILTER_IGNORE;lines.add_child(second)
		var indent:=Control.new();indent.custom_minimum_size.x=48.0;indent.mouse_filter=Control.MOUSE_FILTER_IGNORE;second.add_child(indent)
	var line:=_box(second,false,214.0,6)
	var hub_mark:=_glyph(line,null,18.0)
	var words:=_box(line,true,0.0,0);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var hub:=_text(words,"",13,T.INK,true)
	var span:=_text(words,"",12,T.INK_MUTED)
	var road:=_glyph(line,Icons.logistics_texture("road",T.INK_MUTED,40),18.0)
	var hungry:=PanelContainer.new();hungry.name="Hungry";hungry.mouse_filter=Control.MOUSE_FILTER_PASS;hungry.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var pill:=T.flat(T.DANGER_BG,T.DANGER_BORDER,1,8,0);pill.content_margin_left=6;pill.content_margin_right=8;pill.content_margin_top=1;pill.content_margin_bottom=1
	hungry.add_theme_stylebox_override("panel",pill)
	var hungry_slot:=_box(top,false,96.0,0)
	hungry_slot.add_child(hungry)
	var hungry_row:=HBoxContainer.new();hungry_row.add_theme_constant_override("separation",4);hungry_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;hungry.add_child(hungry_row)
	_glyph(hungry_row,Icons.logistics_texture("hungry",T.RED_TEXT,32),14.0)
	var hungry_days:=_text(hungry_row,"",12,T.RED_TEXT,true);_whole(hungry_days)
	if wide:top.move_child(hungry_slot,line.get_index()+1)
	var gear:=HFlowContainer.new();gear.name="Gear";gear.add_theme_constant_override("h_separation",6);gear.add_theme_constant_override("v_separation",4);gear.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	gear.mouse_filter=Control.MOUSE_FILTER_IGNORE;second.add_child(gear)
	live.append({"key":String(row.key),"panel":panel,"sack":sack,"face":face,"face_key":"","who":who,"title":title,"men":men,"meter":meter,"line":line,"hub_mark":hub_mark,"hub":hub,"span":span,"road":road,
		"hungry":hungry,"hungry_days":hungry_days,"gear":gear,"gear_key":""})


func _update_values()->void:
	var by_key:={}
	for row:Dictionary in rows:by_key[String(row.key)]=row
	for control:Dictionary in live:
		var row:Dictionary=by_key.get(String(control.key),{})
		if not row.is_empty():_update_row(control,row)


func _update_row(control:Dictionary,row:Dictionary)->void:
	control["row"]=row
	var state:=String(row.get("state","well"))
	var ratio:=float(row.get("ratio",1.0))
	(control.sack as TextureRect).texture=Icons.command_texture("supply",Supply.state_text_color(state),32)
	var general:Dictionary=row.get("general",{})
	var face_key:="%s|%s" % [String(row.card_kind),String(general.get("figure_id",general.get("name","")))]
	if face_key!=String(control.face_key):
		control.face_key=face_key
		var face:TextureRect=control.face
		face.texture=Forces.face_texture({"kind":String(row.card_kind),"general":general})
		face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if not general.is_empty() and String(row.card_kind)!="home" else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	control.title.text=String(row.get("title",""))
	# No runner yet: nothing is known of their supply, and nothing is guessed.
	var unknown:=bool(row.get("unknown",false))
	var age:=int(row.get("report_age",0))
	var reported:=not bool(row.get("live",true))
	control.men.text="—" if unknown else "%s men" % EraWords.grouped(int(row.get("men",0)))+(" · "+BarModel.dated_words(age) if reported else "")
	(control.meter as Control).visible=not unknown
	var reasons:=why_words(row)
	control.who.tooltip_text="No runner has come from them yet." if unknown else String(row.get("words",""))+("\n"+reasons if reasons!="" and not reported else "")
	var head:=("Supply %d%%, %s." % [roundi(ratio*100.0),BarModel.report_words(age)]) if reported else shares_words(row)
	control.meter.set_reading(ratio,"%d%%" % roundi(ratio*100.0),Supply.state_color(state),"%s\n%s" % [head,reasons] if reasons!="" else head)
	var at_home:=bool(row.get("at_home",false))
	var kind:=String(row.get("hub_kind",""))
	(control.hub_mark as TextureRect).texture=Icons.logistics_texture("depot" if kind=="held" else "hub",T.INK,32) if not at_home else Icons.command_texture("home",T.INK,32)
	control.hub.text=String(row.get("hub",""))
	var days:=float(row.get("days",0.0))
	if unknown:control.span.text="no report yet"
	elif at_home:control.span.text="at home"
	elif String(row.get("hub",""))=="" or not is_finite(days):control.span.text="no road back"
	else:control.span.text="%s · %d km" % [Supply.days_words(days),roundi(float(row.get("km",0.0)))]
	if unknown:control.line.tooltip_text="Where they are is not known until a runner comes."
	else:control.line.tooltip_text=(Supply.line_words(row).substr(0,1).to_upper()+Supply.line_words(row).substr(1)+("." if not reported else ", where the runner left them.")) if not at_home else "At home: fed from the stores."
	var road:=String(row.get("road",""))
	(control.road as TextureRect).visible=road!="" and not unknown
	(control.road as TextureRect).tooltip_text="By %s." % road
	var hungry:=bool(row.get("hungry",false))
	(control.hungry as Control).visible=hungry
	var hungry_days:=roundi(float(row.get("hungry_days",0.0)))
	control.hungry_days.text="%d day%s" % [hungry_days,"" if hungry_days==1 else "s"]
	(control.hungry as Control).tooltip_text="Hungry %d days: below a fed day's ration.\nHunger wears down their will and their health." % hungry_days
	_update_gear(control,row.get("short",[]))


func _update_gear(control:Dictionary,short:Array)->void:
	var gear:HFlowContainer=control.gear
	var key:=str(short.map(func(e:Dictionary)->Array:return [e.item,e.missing]))
	if key==String(control.gear_key):return
	control.gear_key=key
	for child in gear.get_children():gear.remove_child(child);child.queue_free()
	if short.is_empty():
		var ok:=_text(gear,"—",13,T.INK_MUTED);ok.tooltip_text="Every set issued.";ok.mouse_filter=Control.MOUSE_FILTER_PASS
		return
	for entry:Dictionary in short:
		var button:=Button.new();button.name="Short_"+String(entry.item);button.focus_mode=Control.FOCUS_NONE
		button.text="−%s" % EraWords.grouped(int(entry.missing))
		button.icon=Icons.equipment_texture(String(entry.item),T.INK,T.AMBER,40);button.add_theme_constant_override("icon_max_width",18);button.add_theme_constant_override("h_separation",4)
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:button.add_theme_color_override(state,T.AMBER_TEXT)
		button.custom_minimum_size=Vector2(0,26);button.tooltip_text=Model.short_words(entry)
		button.pressed.connect(open_production);gear.add_child(button)


## "Carried 25% · foraged 35% · from the town 0%": where the day's food came
## from, in the model's own shares (they add up to the whole).
static func shares_words(row:Dictionary)->String:
	var parts:PackedStringArray=[]
	var names:=[["carried","carried"],["foraged","foraged"],["local","from the town"]]
	var values:Array=[]
	for pair:Array in names:values.append(float(row.get(String(pair[0]),0.0)))
	var pcts:Array=Supply.percents(float(row.get("ratio",0.0)),values)
	for i in names.size():
		if float(values[i])>0.004:parts.append("%s %d%%" % [String(names[i][1]),int(pcts[i])])
	var head:="Fed %d%% of a day's need" % roundi(float(row.get("ratio",0.0))*100.0)
	return head+(": "+", ".join(parts) if not parts.is_empty() else "")+"."


## The model's reasons (why[]), one to a line, each begun with a capital.
static func why_words(row:Dictionary)->String:
	var lines:PackedStringArray=[]
	for reason in row.get("why",[]):
		var text:=String(reason)
		if text!="":lines.append(text.substr(0,1).to_upper()+text.substr(1)+".")
	return "\n".join(lines)


func open_production()->void:
	var shell:=hud if is_instance_valid(hud) else null
	if shell==null:
		var scene:=get_tree().current_scene if is_inside_tree() else null
		if scene!=null and "hud" in scene:shell=scene.hud
	if shell!=null and shell.has_method("open_dock"):shell.open_dock("production",2)


## The width the rows have (the Military screen's panel less its margins,
## which the screen gives whenever the window changes): wide, a row is one
## line; narrow, its bars go on a second.
func set_available_width(width:float)->void:
	var now:=width>=WIDE_FROM
	if now!=wide:
		wide=now
		refresh(true)


func _process(delta:float)->void:
	clock+=delta
	# Hidden behind the army command panel, it waits.
	if clock<REFRESH_SECONDS or not is_visible_in_tree():return
	clock=0.0
	refresh()
