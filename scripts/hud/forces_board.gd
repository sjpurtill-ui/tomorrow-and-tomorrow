extends VBoxContainer
## FORCES, as HOI4's army overview: numbers, bars and glyphs; sentences live
## in the tooltips.
##
##   strip    men under arms · gear issued · the hungry · in training, and
##            the training level (a click opens that page)
##   filters  All · In the field · Garrisons · Short of gear, with counts
##   rows     one per army card (hud/forces_model.gd): the state glyph, the
##            general's face, the name and the template it was raised from,
##            men against full strength, the army bar's three bars (gear,
##            will to fight, supply) in its colours and with its tooltips,
##            drill and experience, what it is doing and where it stands.
##            The bands an army's general leads sit beneath it.
## A click selects the army on the map and centres it (the army bar's own
## select_card, as command_rail_hud.select_army uses); a double-click or
## Orders opens it in the army command panel (the army bar's open_card); the
## sighting ring shows it on the map and closes this screen; Talk calls its
## general (else the war leader) to court, as the old card's "Talk to its
## captain" did. A short gear bar opens Production. Generals still choose
## the road, the camp and the fight.

signal page_wanted(page:String)
signal command_opened(kind:String)
signal close_wanted

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Model:=preload("res://scripts/hud/forces_model.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Story:=preload("res://scripts/hud/military_force_story.gd")
const Board:=preload("res://scripts/hud/recruit_deploy_board.gd")
## Below this width a row wraps its bars onto a second line.
const WIDE_FROM:=1080.0
## The name cell of a wide row (an army's; its bands' are narrower).
const WHO_WIDTH:=140.0
## Each of the three bars (its mark, the bar and its number).
const METER_WIDTH:=94.0
const REFRESH_SECONDS:=0.5

## The HUD shell (hud/command_rail_hud.gd); found from the running map when
## not given. Tests may hand in a stand-in with an army_bar.
var hud:Node
var filter:="all"
var strip_only:=false
var wide:=true
var selected_id:=""
var chips:Dictionary={}
var filter_buttons:Dictionary={}
var list:VBoxContainer
var feedback:Label
var policy_button:Button
## Live controls, one per row shown: {id, depth, panel, face, title, ...}.
var live:Array[Dictionary]=[]
var rows:Array[Dictionary]=[]
var signature:=""
var clock:=0.0


func setup(block:Dictionary={})->void:
	name="ForcesBoard"
	strip_only=bool(block.get("strip_only",false))
	filter=String(block.get("filter",filter))
	if block.has("hud"):hud=block.hud
	if block.has("width"):wide=float(block.width)>=WIDE_FROM
	add_theme_constant_override("separation",10)
	theme=_theme()
	_build_strip()
	if strip_only:
		refresh(true)
		return
	var bar:=HBoxContainer.new();bar.name="Filters";bar.add_theme_constant_override("separation",6);add_child(bar)
	for entry:Array in Model.FILTERS:
		var id:=String(entry[0])
		var button:=_button(bar,String(entry[1]),func():set_filter(id))
		button.name="Filter_"+id;button.toggle_mode=true;filter_buttons[id]=button
	feedback=T.make_label("",13,T.GOLD_TEXT);feedback.name="Feedback";feedback.hide();add_child(feedback)
	list=VBoxContainer.new();list.name="Rows";list.add_theme_constant_override("separation",6);add_child(list)
	refresh(true)


func _theme()->Theme:
	var skin:=Theme.new()
	skin.default_font=T.FONT_UI;skin.default_font_size=14
	for kind in ["Button"]:
		skin.set_stylebox("normal",kind,T.action_button_style(false));skin.set_stylebox("hover",kind,T.action_button_style(false,true))
		skin.set_stylebox("pressed",kind,T.button_pressed_style());skin.set_stylebox("hover_pressed",kind,T.button_pressed_style())
		skin.set_stylebox("disabled",kind,T.button_disabled_style());skin.set_stylebox("focus",kind,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:skin.set_color(state,kind,T.INK)
		skin.set_color("font_disabled_color",kind,T.DISABLED);skin.set_font_size("font_size",kind,14)
	skin.set_color("font_color","Label",T.INK)
	T.add_tooltip_style(skin)
	return skin


# --- Small builders -----------------------------------------------------------------

func _button(parent:Node,text:String,action:Callable,icon:Texture2D=null,tip:String="")->Button:
	var button:=Button.new();button.text=text;button.tooltip_text=tip;button.focus_mode=Control.FOCUS_NONE
	button.custom_minimum_size=Vector2(0,30)
	if icon!=null:
		button.icon=icon;button.expand_icon=false
		button.add_theme_constant_override("icon_max_width",16);button.add_theme_constant_override("h_separation",5)
	button.pressed.connect(action);parent.add_child(button);return button


func _glyph(parent:Node,texture:Texture2D,side:float=16.0)->TextureRect:
	var mark:=TextureRect.new();mark.texture=texture;mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size=Vector2(side,side);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(mark);return mark


## A button kept narrow (an icon or a few characters): the paper and rule
## of the others, with less room at its sides.
func _compact(button:Button,side:float=7.0)->void:
	for pair:Array in [["normal",T.action_button_style(false)],["hover",T.action_button_style(false,true)],["pressed",T.button_pressed_style()],["hover_pressed",T.button_pressed_style()],["disabled",T.button_disabled_style()]]:
		var style:StyleBoxFlat=pair[1];style.content_margin_left=side;style.content_margin_right=side
		button.add_theme_stylebox_override(String(pair[0]),style)


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


## A cell that carries a tooltip and lets clicks through to its row.
func _cell(parent:Node,min_width:float=0.0,vertical:bool=false)->BoxContainer:
	var box:BoxContainer
	if vertical:box=VBoxContainer.new()
	else:box=HBoxContainer.new()
	box.add_theme_constant_override("separation",0 if vertical else 4);box.mouse_filter=Control.MOUSE_FILTER_PASS
	box.custom_minimum_size.x=min_width;box.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	parent.add_child(box);return box


# --- The strip --------------------------------------------------------------------

func _build_strip()->void:
	var panel:=PanelContainer.new();panel.name="Strip";panel.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CARD,10));add_child(panel)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);panel.add_child(row)
	# The chips wrap on a narrow screen; the training level keeps the right edge.
	var flow:=HFlowContainer.new();flow.add_theme_constant_override("h_separation",26);flow.add_theme_constant_override("v_separation",6)
	flow.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(flow)
	for spec:Array in [["men","men","warriors"],["gear","gear","armed"],["fed","supply","all fed"],["training","drilling","in training"]]:
		var chip:=HBoxContainer.new();chip.name="Chip_"+String(spec[0]);chip.add_theme_constant_override("separation",7);chip.mouse_filter=Control.MOUSE_FILTER_STOP;flow.add_child(chip)
		_glyph(chip,Icons.command_texture(String(spec[1]),T.INK,48),22.0)
		var value:=_text(chip,"",19,T.INK,true);_whole(value)
		var word:=_text(chip,String(spec[2]),13,T.INK_MUTED);_whole(word);word.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		chips[String(spec[0])]={"chip":chip,"value":value,"word":word}
	(chips.gear.chip as Control).gui_input.connect(func(event:InputEvent):
		if _clicked(event) and bool(chips.gear.get("short",false)):_open_production())
	(chips.training.chip as Control).gui_input.connect(func(event:InputEvent):
		if _clicked(event):page_wanted.emit("recruitment"))
	(chips.training.chip as Control).mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	# Hot feuds, as HOI4 keeps the wars in sight: a click opens the Feuds page.
	var feuds:=HBoxContainer.new();feuds.name="Chip_feuds";feuds.add_theme_constant_override("separation",7);feuds.mouse_filter=Control.MOUSE_FILTER_STOP;flow.add_child(feuds)
	_glyph(feuds,Icons.war_texture("feud",T.RED,48),22.0)
	var feud_value:=_text(feuds,"",19,T.RED_TEXT,true);_whole(feud_value)
	var feud_word:=_text(feuds,"hot feuds",13,T.RED_TEXT);_whole(feud_word);feud_word.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	chips["feuds"]={"chip":feuds,"value":feud_value,"word":feud_word}
	feuds.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	feuds.gui_input.connect(func(event:InputEvent):
		if _clicked(event):page_wanted.emit("wars"))
	if not strip_only:
		policy_button=_button(row,"",func():page_wanted.emit("training"),Icons.command_texture("drill",T.INK,40),"How hard the forces drill, and what it costs.")
		policy_button.name="TrainingLevel";policy_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER


func _clicked(event:InputEvent)->bool:
	return event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT


func _update_strip(sum:Dictionary)->void:
	var fighters:=Story.fighters(int(sum.men),"army",EraWords.stage())
	chips.men.value.text=EraWords.grouped(int(sum.men));chips.men.word.text=fighters
	var men_tip:="%s %s: %s at home, %s in the field, %s holding towns." % [EraWords.grouped(int(sum.men)),fighters,EraWords.grouped(int(sum.home)),EraWords.grouped(int(sum.field)),EraWords.grouped(int(sum.garrison))]
	if int(sum.full)>int(sum.men):men_tip+="\n%s places are empty." % EraWords.grouped(int(sum.full)-int(sum.men))
	if int(sum.unknown)>0:men_tip+="\nNot counted: %d away with no report yet." % int(sum.unknown)
	chips.men.chip.tooltip_text=men_tip
	var required:=int(sum.required);var issued:=int(sum.issued)
	var share:=float(issued)/maxf(1.0,float(required)) if required>0 else 1.0
	var short:=not (sum.missing as Dictionary).is_empty()
	chips.gear.value.text="%d%%" % floori(share*100.0+0.0001)
	chips.gear.value.add_theme_color_override("font_color",T.AMBER_TEXT if short else T.INK)
	chips.gear["short"]=short
	chips.gear.chip.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if short else Control.CURSOR_ARROW
	chips.gear.chip.tooltip_text=BarModel.gear_words({"issued":issued,"required":required,"missing":sum.missing}).replace("the gear bar","here")
	var hungry:Array=sum.hungry
	chips.fed.value.text=str(hungry.size()) if not hungry.is_empty() else ""
	chips.fed.value.visible=not hungry.is_empty()
	chips.fed.word.text="hungry" if not hungry.is_empty() else "all fed"
	chips.fed.word.add_theme_color_override("font_color",T.RED_TEXT if not hungry.is_empty() else T.GREEN_TEXT)
	chips.fed.value.add_theme_color_override("font_color",T.RED_TEXT)
	chips.fed.chip.tooltip_text=("Short of food: "+", ".join(hungry)+".\nThe Readiness & supply tab says why.") if not hungry.is_empty() else "Every band is fed."
	chips.training.value.text=EraWords.grouped(int(sum.training))
	chips.training.chip.tooltip_text="%s drilling or called up and waiting.\nClick for Recruit & deploy." % EraWords.grouped(int(sum.training))
	if is_instance_valid(policy_button):policy_button.text="Training: %s" % String(MilitaryCampaign.training_staff.policy("army").label).to_lower()
	var hot:=preload("res://scripts/hud/war_ledger_model.gd").entries().filter(func(e:Dictionary)->bool: return String(e.kind)!="ended" and bool(e.get("hot",false)))
	chips.feuds.chip.visible=not hot.is_empty()
	chips.feuds.value.text=str(hot.size())
	chips.feuds.word.text="hot feud" if hot.size()==1 else "hot feuds"
	chips.feuds.chip.tooltip_text="Blood spilled within the year: %s.\nClick for the Feuds page." % ", ".join(hot.map(func(e:Dictionary)->String: return String(e.name)))


# --- Filters and rows -------------------------------------------------------------

func set_filter(id:String)->void:
	filter=id
	refresh(true)


func visible_rows()->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for row:Dictionary in rows:
		if Model.passes(row,filter):out.append(row)
	return out


func refresh(force:bool=false)->void:
	rows=Model.rows()
	_update_strip(Model.summary(rows))
	if strip_only:return
	var counts:=Model.counts(rows)
	for entry:Array in Model.FILTERS:
		var id:=String(entry[0]);var button:Button=filter_buttons[id]
		button.text="%s %d" % [String(entry[1]),int(counts.get(id,0))]
		button.set_pressed_no_signal(id==filter)
	var shown:=visible_rows()
	var shape:=_shape(shown)
	if force or shape!=signature:
		signature=shape
		_rebuild(shown)
	else:
		_update_values(shown)


func _shape(shown:Array)->String:
	var parts:Array=[wide,filter]
	for row:Dictionary in shown:
		parts.append([row.id,row.kind,row.get("unknown",false)])
		for band:Dictionary in _bands_shown(row):parts.append(band.id)
	return str(parts)


## A command's bands under its row: all of them, or under a filter only the
## bands it picks (the command's row stands over them).
func _bands_shown(row:Dictionary)->Array:
	var bands:Array=row.get("bands",[])
	if filter=="all":return bands
	return bands.filter(func(band:Dictionary)->bool:return Model.passes(band,filter))


func _rebuild(shown:Array)->void:
	for child in list.get_children():list.remove_child(child);child.queue_free()
	live.clear()
	if rows.is_empty():
		_empty("No one is under arms yet.",true)
		return
	if shown.is_empty():
		_empty("No force matches this filter.",false)
		return
	for row:Dictionary in shown:
		_row(row,0)
		for band:Dictionary in _bands_shown(row):_row(band,1)
	_update_values(shown)


func _empty(words:String,recruit:bool)->void:
	var panel:=PanelContainer.new();panel.name="Empty";panel.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CARD,14));list.add_child(panel)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);panel.add_child(row)
	_glyph(row,Icons.command_texture("men",T.INK_MUTED,48),22.0)
	var text:=_text(row,words,14,T.INK_MUTED);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_whole(text)
	if recruit:_button(row,"Recruit & deploy",func():page_wanted.emit("recruitment"),Icons.command_texture("drill",T.INK,40),"Raise and drill a band.")


func _update_values(shown:Array)->void:
	var by_id:={}
	for row:Dictionary in shown:
		by_id[String(row.id)]=row
		for band:Dictionary in row.get("bands",[]):by_id[String(band.id)]=band
	for control:Dictionary in live:
		var row:Dictionary=by_id.get(String(control.id),{})
		if not row.is_empty():_update_row(control,row)


## One row: glyph, face, name and template, men, three bars, drill, what it
## is doing and where, and its two actions. A band of an army sits indented.
func _row(row:Dictionary,depth:int)->void:
	var panel:=RowPanel.new();panel.board=self;panel.row_id=String(row.id);panel.depth=depth;panel.name="Row_"+String(row.id).replace(":","_").replace("/","_")
	list.add_child(panel)
	var lines:=VBoxContainer.new();lines.add_theme_constant_override("separation",4);lines.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(lines)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;lines.add_child(top)
	if depth>0:
		var indent:=Control.new();indent.custom_minimum_size.x=18.0*depth;indent.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(indent)
	var state:=StateMark.new();state.name="State";top.add_child(state)
	var frame:=Panel.new();frame.clip_contents=true;frame.custom_minimum_size=Vector2(30,36) if depth>0 else Vector2(36,44);frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame.size_flags_vertical=Control.SIZE_SHRINK_CENTER;frame.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK));top.add_child(frame)
	var face:=TextureRect.new();face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);face.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.add_child(face)
	# The kit most of them carry, on the face's corner (HOI4's division icon).
	var plate:=Panel.new();plate.name="KitPlate";plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;plate.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.INK,1,2))
	plate.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);plate.offset_left=-21.0;plate.offset_top=-21.0;plate.offset_right=0.0;plate.offset_bottom=0.0;frame.add_child(plate)
	var badge:=TextureRect.new();badge.name="Kit";badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);badge.offset_left=1.0;badge.offset_top=1.0;badge.offset_right=-1.0;badge.offset_bottom=-1.0;plate.add_child(badge)
	# Wide, the columns line up down the list: the name cell gives back what
	# a band's indent and smaller face take.
	var who:=_cell(top,(WHO_WIDTH-20.0*depth) if wide else 110.0,true)
	who.size_flags_horizontal=Control.SIZE_FILL if wide else Control.SIZE_EXPAND_FILL
	var title:=_text(who,"",15 if depth==0 else 14,T.INK,true)
	var template:=_text(who,"",12,T.INK_MUTED)
	var men_cell:=_cell(top,100.0)
	_glyph(men_cell,Icons.command_texture("men",T.INK_MUTED,32))
	var men:=_text(men_cell,"",14,T.INK,true);_whole(men)
	var call_up:Button=null
	if String(row.kind)=="home":
		call_up=_button(men_cell,"",func():call_up_home())
		call_up.name="CallUp";call_up.custom_minimum_size=Vector2(0,24);call_up.size_flags_vertical=Control.SIZE_SHRINK_CENTER;_compact(call_up,6.0)
	var bars_parent:HBoxContainer=top
	if not wide:
		bars_parent=HBoxContainer.new();bars_parent.add_theme_constant_override("separation",6);bars_parent.mouse_filter=Control.MOUSE_FILTER_IGNORE;lines.add_child(bars_parent)
		var indent:=Control.new();indent.custom_minimum_size.x=18.0*depth+56.0;indent.mouse_filter=Control.MOUSE_FILTER_IGNORE;bars_parent.add_child(indent)
	var meters:Array=[]
	for kind:String in ["gear","will","supply"]:
		var meter:=Board.Meter.new();meter.kind=kind;meter.name=kind.capitalize();meter.size_flags_horizontal=Control.SIZE_EXPAND_FILL if not wide else Control.SIZE_FILL
		meter.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bars_parent.add_child(meter);meter.mouse_filter=Control.MOUSE_FILTER_PASS;meters.append(meter)
		meter.custom_minimum_size.x=METER_WIDTH
	meters[0].clicked.connect(_open_production)
	var drill_cell:=_cell(bars_parent,84.0)
	_glyph(drill_cell,Icons.command_texture("drill",T.INK_MUTED,32))
	var drill:=_text(drill_cell,"",13,T.INK,true);_whole(drill)
	var seen_mark:=_glyph(drill_cell,Icons.logistics_texture("seen",T.INK_MUTED,32),14.0)
	var seen:=_text(drill_cell,"",13,T.INK,true);_whole(seen)
	var place:=_cell(top,130.0 if wide else 120.0,true);place.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var doing:=_text(place,"",13,T.INK)
	var where:=_text(place,"",12,T.INK_MUTED)
	var find:=_button(top,"",func():find_row(String(row.id),true),Icons.logistics_texture("find",T.INK,40),"Show them on the map.")
	find.name="Find";find.custom_minimum_size=Vector2(30,30);find.size_flags_vertical=Control.SIZE_SHRINK_CENTER;_compact(find)
	var talk:=_button(top,"",func():talk_to(String(row.id)),Icons.logistics_texture("talk",T.INK,40))
	talk.name="Talk";talk.custom_minimum_size=Vector2(30,30);talk.size_flags_vertical=Control.SIZE_SHRINK_CENTER;_compact(talk)
	var orders:=_button(top,"Orders",func():open_orders(String(row.id)),Icons.command_texture("arrow",T.INK,40))
	orders.name="Orders";orders.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	live.append({"id":String(row.id),"depth":depth,"panel":panel,"state":state,"face":face,"face_key":"","who":who,"title":title,"template":template,"men_cell":men_cell,"men":men,
		"call_up":call_up,"badge":badge,"badge_key":"","meters":meters,"drill_cell":drill_cell,"drill":drill,"seen_mark":seen_mark,"seen":seen,"place":place,"doing":doing,"where":where,"find":find,"talk":talk,"orders":orders})


func _update_row(control:Dictionary,row:Dictionary)->void:
	control["row"]=row
	var unknown:=bool(row.get("unknown",false))
	var panel:RowPanel=control.panel
	panel.chosen=String(row.id)==selected_id;panel.restyle()
	(control.state as StateMark).state=String(row.get("state","holding"));(control.state as StateMark).fade=0.55 if unknown else 1.0
	var state_words:=BattleMarks.state_words(String(row.get("state","holding")))
	(control.state as StateMark).tooltip_text=state_words.substr(0,1).to_upper()+state_words.substr(1)
	(control.state as StateMark).queue_redraw()
	_face(control,row)
	var group:=String(row.kind)=="group"
	control.title.text=String(row.get("title",""))+(" ×%d" % (row.get("members",[]) as Array).size() if group else "")
	control.template.text=String(row.get("template",""))
	var tip:=BarModel.tooltip(row)
	if not (row.get("kinds",[]) as Array).is_empty():
		var parts:PackedStringArray=[]
		for kind:Dictionary in row.kinds:parts.append("%s %s" % [EraWords.grouped(int(kind.count)),String(kind.label).to_lower()])
		tip="%s\nMade up of %s." % [tip,", ".join(parts)]
	control.who.tooltip_text=tip
	var men:=int(row.get("men",0));var full:=int(row.get("full",men))
	control.men.text="—" if unknown else "%s/%s" % [EraWords.grouped(men),EraWords.grouped(full)]
	control.men_cell.tooltip_text="Not known until a runner reports." if unknown else ("%s of %s men; %s places empty." % [EraWords.grouped(men),EraWords.grouped(full),EraWords.grouped(full-men)] if full>men else "%s men, every place filled." % EraWords.grouped(men))
	var gap:=maxi(0,full-men)
	if control.call_up!=null:
		var button:Button=control.call_up
		button.visible=gap>0 and not unknown
		button.text="+%d" % gap
		button.tooltip_text="Call up %d from the people to fill the empty places." % gap
	var meters:Array=control.meters
	var gear:=float(row.get("gear",1.0));var will:=float(row.get("will",0.6));var supply:=float(row.get("supply",1.0))
	var detail:Dictionary=row.get("gear_detail",{})
	meters[0].clickable=not unknown and not (detail.get("missing",{}) as Dictionary).is_empty()
	meters[0].set_reading(gear,"%d/%d" % [int(detail.get("issued",0)),int(detail.get("required",0))],BarModel.gear_color(gear),BarModel.gear_words(detail))
	meters[1].set_reading(will,"%d%%" % roundi(will*100.0),BarModel.will_color(will),BarModel.will_words(will)+"\nBelow a quarter they break.")
	meters[2].set_reading(supply,"%d%%" % roundi(supply*100.0),BarModel.supply_color(String(row.get("supply_state","well"))),BarModel.supply_line(row))
	for meter in meters:(meter as Control).visible=not unknown
	var drill:=float(row.get("drill",0.0));var seen:=float(row.get("seen",0.0))
	control.drill.text="%d%%" % roundi(drill*100.0)
	control.seen.text="%d%%" % roundi(seen*100.0)
	# The star only once they have seen some fighting.
	(control.seen as Control).visible=seen>=0.005;(control.seen_mark as Control).visible=seen>=0.005
	control.drill_cell.visible=not unknown
	var seen_words:=Story.experience_words(seen)
	control.drill_cell.tooltip_text="%s (%d%%); %s." % [Story.drill_word(drill),roundi(drill*100.0),seen_words]
	var doing:=String(row.get("doing",""))
	control.doing.text=doing.substr(0,1).to_upper()+doing.substr(1)
	var age:=int(row.get("report_age",0))
	# A band known by its runner says how old his word is, as Readiness does.
	control.where.text=String(row.get("where",""))+(" · "+BarModel.dated_words(age) if not bool(row.get("live",true)) and not unknown else "")
	var age_words:=ArmyMarks.age_words(age)
	control.place.tooltip_text=(control.doing.text+"."+("\n"+age_words.substr(0,1).to_upper()+age_words.substr(1)+" by runner." if age_words!="" else ""))
	var orders:Button=control.orders
	orders.tooltip_text="Open the town we hold: its people and the garrison's orders." if String(row.kind)=="garrison" else "Open their orders in the army command panel."
	var find:Button=control.find
	find.disabled=not (row.get("position",Vector2.INF) as Vector2).is_finite()
	var who:=String((row.get("general",{}) as Dictionary).get("name",""))
	(control.talk as Button).tooltip_text="Call %s to court." % (who if who!="" else "the war leader")


func _face(control:Dictionary,row:Dictionary)->void:
	var kinds:Array=row.get("kinds",[])
	var glyph:=preload("res://scripts/battle_blocks.gd").glyph_of(String((kinds[0] as Dictionary).get("unit","levy")),String((kinds[0] as Dictionary).get("weapon",""))) if not kinds.is_empty() else ""
	if control.has("badge") and glyph!=String(control.get("badge_key","")):
		control.badge_key=glyph
		(control.badge as TextureRect).texture=Icons.arm_texture(glyph,T.INK,T.GOLD,48) if glyph!="" else null
		(control.badge as TextureRect).get_parent().visible=glyph!=""
		(control.badge as TextureRect).tooltip_text=String((kinds[0] as Dictionary).get("label","")) if not kinds.is_empty() else ""
	var general:Dictionary=row.get("general",{})
	var key:="%s|%s|%s" % [String(row.kind),String(general.get("figure_id","")),String(general.get("name",""))]
	if key==String(control.face_key):return
	control.face_key=key
	var face:TextureRect=control.face
	face.texture=face_texture(row)
	face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if not general.is_empty() and String(row.kind)!="home" else TextureRect.STRETCH_KEEP_ASPECT_CENTERED


## The same face the army bar gives a card: the general's portrait, else the
## home mark, a garrison's shield or a standard.
static func face_texture(card:Dictionary)->Texture2D:
	var general:Dictionary=card.get("general",{})
	match String(card.get("kind","")):
		"home":return Icons.command_texture("home",T.INK,64)
		"garrison":
			if general.is_empty():return Icons.command_texture("defend",T.INK,64)
	if general.is_empty():return Icons.command_texture("will",T.INK,64)
	return Portrait.texture({"name":String(general.get("full_name",general.get("name",""))),"person_id":absi(String(general.get("figure_id",general.get("name",""))).hash())%997+1})


func _row_by_id(id:String)->Dictionary:
	for row:Dictionary in rows:
		if String(row.id)==id:return row
		for band:Dictionary in row.get("bands",[]):
			if String(band.id)==id:return band
	return {}


# --- Acting on a row --------------------------------------------------------------

func _hud()->Node:
	if is_instance_valid(hud):return hud
	var scene:=get_tree().current_scene if is_inside_tree() else null
	if scene!=null and "hud" in scene and is_instance_valid(scene.hud):return scene.hud
	return null


func _army_bar()->Node:
	var shell:=_hud()
	if shell==null or not ("army_bar" in shell):return null
	var bar:Variant=shell.get("army_bar")
	return bar if bar is Node and is_instance_valid(bar) else null


## The army bar's own card for this row (the bar's list is the same reading).
func _bar_card(bar:Node,id:String)->Dictionary:
	bar.refresh()
	for card:Dictionary in bar.cards:
		if String(card.id)==id:return card
		for member:Dictionary in card.get("member_cards",[]):
			if String(member.id)==id:return member
	return {}


## Select the army on the map and centre it, as a click on its army-bar card
## does (hud/army_bar.gd select_card). show: also close this screen so the
## map is in view.
func find_row(id:String,show:bool=false)->void:
	var row:=_row_by_id(id)
	if row.is_empty():return
	selected_id=id
	var bar:=_army_bar()
	if bar!=null:
		var card:=_bar_card(bar,id)
		bar.select_card(card if not card.is_empty() else row)
	else:
		var shell:=_hud()
		if shell!=null and shell.has_method("select_army") and int(row.get("army_id",-1))>=0:shell.select_army(int(row.army_id))
	for control:Dictionary in live:
		(control.panel as RowPanel).chosen=String(control.id)==selected_id;(control.panel as RowPanel).restyle()
	if show:close_wanted.emit()


## Open its orders: the army command panel with this army chosen, or a held
## town's own view (hud/army_bar.gd open_card).
func open_orders(id:String)->void:
	var row:=_row_by_id(id)
	if row.is_empty():return
	selected_id=id
	var bar:=_army_bar()
	if bar!=null:
		var card:=_bar_card(bar,id)
		bar.open_card(card if not card.is_empty() else row)
	elif String(row.kind)=="garrison":
		preload("res://scripts/hud/occupation_view.gd").open(String(row.get("civ_id","")),String(row.get("region_id","")))
	else:
		MilitaryCampaign.joint_operations.open_hierarchy("army")
		var screen:Variant=MilitaryCampaign.joint_operations.screen
		if is_instance_valid(screen) and screen.has_method("choose_force"):screen.choose_force(int(row.get("army_id",0)))
	command_opened.emit(String(row.kind))


## Call its general to court (else the war leader), through the court's own
## summons (audience_director), as the old card's "Talk to its captain" did.
func talk_to(id:String)->void:
	var row:=_row_by_id(id)
	if row.is_empty():return
	var general:Dictionary=row.get("general",{})
	var captain:Dictionary=Story.captain_for({"commander":{"figure_id":String(general.get("figure_id","")),"name":String(general.get("full_name",general.get("name","")))}},MilitaryCampaign)
	var director:Node=preload("res://scripts/audience_director.gd").court_node()
	if director==null:
		if is_instance_valid(feedback):
			feedback.text="The court cannot sit just now";feedback.tooltip_text="";feedback.show()
		return
	if not captain.is_empty() and director.has_method("summon"):director.call("summon",captain.target)
	else:director.call("open_court",{})
	close_wanted.emit()


## The call-up for the levy at home: free adults into the recruit reserve,
## then into the empty places (MilitaryCampaign.reinforce_formation). They
## drill a few days before they stand in the line.
func call_up_home()->String:
	var sent:=0;var refusal:=""
	for f in (MilitaryCampaign.home_army.get("formations",[]) as Array).duplicate(true):
		var formation:Dictionary=f
		var gap:=maxi(0,int(formation.get("authorized_count",formation.get("count",0)))-int(formation.get("count",0)))
		if gap<=0 or not formation.has("id"):continue
		if MilitaryCampaign.aggregate_recruits<gap:MilitaryCampaign.raise_recruits(gap-MilitaryCampaign.aggregate_recruits)
		var result:Dictionary=MilitaryCampaign.reinforce_formation(int(formation.id),gap)
		if result.has("error"):refusal=String(result.error);continue
		sent+=int(result.get("accepted",0))
	var words:=("%s called up to fill the levy" % EraWords.grouped(sent)) if sent>0 else "No one could be called up"
	if is_instance_valid(feedback):
		feedback.text=words;feedback.show()
		feedback.tooltip_text="They drill for a few days, then take the empty places." if sent>0 else refusal
		feedback.mouse_filter=Control.MOUSE_FILTER_PASS
	refresh(true)
	return words


func _open_production()->void:
	var shell:=_hud()
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


class RowPanel extends PanelContainer:
	## One row's paper: a click selects the army on the map, a double-click
	## opens its orders; the chosen row carries the gold rule.
	var board:Node
	var row_id:=""
	var depth:=0
	var chosen:=false
	var hovered:=false

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func():hovered=true;restyle())
		mouse_exited.connect(func():hovered=false;restyle())
		restyle()

	func restyle()->void:
		var style:=T.flat(T.HOVER_BG if hovered else (T.PAPER_RAISED if depth==0 else T.PAPER),T.GOLD if chosen else T.RULE,1,T.RADIUS_CARD,8)
		style.content_margin_top=5;style.content_margin_bottom=5
		if chosen:style.border_width_left=3
		add_theme_stylebox_override("panel",style)

	func _gui_input(event:InputEvent)->void:
		if not (event is InputEventMouseButton) or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT:return
		accept_event()
		if event.double_click:board.open_orders(row_id)
		else:board.find_row(row_id)


class StateMark extends Control:
	## The counter's state glyph: marching, holding, besieging, fighting,
	## broken or hungry (hud/battle_marks.gd draws it, as on the map).
	var state:="holding"
	var fade:=1.0

	func _ready()->void:
		custom_minimum_size=Vector2(20,20);size_flags_vertical=Control.SIZE_SHRINK_CENTER;mouse_filter=Control.MOUSE_FILTER_PASS

	func _draw()->void:
		BattleMarks.draw_state(self,size*0.5,state,7.5,fade)
