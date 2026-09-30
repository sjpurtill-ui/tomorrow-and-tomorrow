extends VBoxContainer
## RECRUIT & DEPLOY, as HOI4 does it: numbers, bars and one click.
##
##   manpower strip   can be called up · serving · in training (· jobs left
##                    undone at home), icons and numbers
##   band templates   small cards: the band's picture, its men and arms, one
##                    "Train" click, or "×5" for five at once
##   deployment queue each line a row of −/+ (how many bands), ∞ (keep
##                    raising), priority, auto-deploy, where they go, pause and
##                    stop; each band in training one compact row of three bars
##                    (men gathered, gear issued, training), the day it is ready
##                    and "Deploy early"
## A short gear bar is amber; its tooltip says what is missing and why, and a
## click opens production. Every number is hud/deployment_model.gd's reading
## of the one military ledger; the sentences live in tooltips.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Model:=preload("res://scripts/hud/deployment_model.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Art:=preload("res://scripts/hud/military_roster_visuals.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const LINES_PER_PAGE:=4
const BANDS_PER_PAGE:=4
const PRIORITY_WORDS:=["low","normal","high"]

var edit:Callable
var rows:VBoxContainer
var templates_box:VBoxContainer
var columns:GridContainer
var queue_column:VBoxContainer
var templates_column:VBoxContainer
var feedback:Label
var chips:Dictionary={}
var queue_counts:Label
var refresh_clock:=0.0
var signature:=""
var page:=0
var slot_pages:Dictionary={}
## Live controls updated in place: {id, slot?, meters?, date?, deploy?, head?}.
var live:Array[Dictionary]=[]


func setup(block:Dictionary)->void:
	name="RecruitDeployBoard";edit=block.get("edit_template",func(_id:int):pass)
	add_theme_constant_override("separation",12)
	theme=_theme()
	_build_strip()
	feedback=T.make_label("",13,T.RED_TEXT);feedback.hide();add_child(feedback)
	columns=GridContainer.new();columns.columns=2;columns.add_theme_constant_override("h_separation",20);columns.add_theme_constant_override("v_separation",16);add_child(columns)
	queue_column=VBoxContainer.new();queue_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;queue_column.size_flags_stretch_ratio=1.7;queue_column.add_theme_constant_override("separation",8);columns.add_child(queue_column)
	var queue_head:=HBoxContainer.new();queue_head.add_theme_constant_override("separation",10);queue_column.add_child(queue_head)
	var kicker:=_kicker(queue_head,"In training");kicker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	queue_counts=T.make_label("",13,T.MUTED);queue_head.add_child(queue_counts)
	rows=VBoxContainer.new();rows.add_theme_constant_override("separation",8);queue_column.add_child(rows)
	templates_column=VBoxContainer.new();templates_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;templates_column.add_theme_constant_override("separation",8);columns.add_child(templates_column)
	var head:=HBoxContainer.new();templates_column.add_child(head)
	var caption:=_kicker(head,"Bands we can raise");caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var add:=_icon_button(head,"plus","New",func():
		var result:=MilitaryCampaign.create_army_template()
		if result.has("template"):edit.call(int(result.template.template_id))
		else:report(result),"Draw up a new kind of band")
	add.name="NewTemplate"
	templates_box=VBoxContainer.new();templates_box.add_theme_constant_override("separation",8);templates_column.add_child(templates_box)
	build_templates()
	resized.connect(layout_columns);layout_columns()
	rebuild()


func _theme()->Theme:
	var skin:=Theme.new()
	skin.default_font=T.FONT_UI;skin.default_font_size=14
	for kind in ["Button","OptionButton","CheckButton"]:
		skin.set_stylebox("normal",kind,T.action_button_style(false));skin.set_stylebox("hover",kind,T.action_button_style(false,true))
		skin.set_stylebox("pressed",kind,T.button_pressed_style());skin.set_stylebox("hover_pressed",kind,T.button_pressed_style())
		skin.set_stylebox("disabled",kind,T.button_disabled_style());skin.set_stylebox("focus",kind,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:skin.set_color(state,kind,T.INK)
		skin.set_color("font_disabled_color",kind,T.DISABLED);skin.set_font_size("font_size",kind,14)
	skin.set_color("font_color","Label",T.INK)
	skin.set_stylebox("panel","PopupMenu",T.flat(T.PAPER,T.RULE,1,4,6));skin.set_stylebox("hover","PopupMenu",T.flat(T.HOVER_BG))
	for state in ["font_color","font_hover_color"]:skin.set_color(state,"PopupMenu",T.INK)
	T.add_tooltip_style(skin)
	return skin


func _kicker(parent:Node,text:String)->Label:
	var label:=T.make_label(text,13,T.INK_MUTED);label.add_theme_font_override("font",T.font("ui_strong"));parent.add_child(label);return label


func _skin(bg:Color,border:Color,pad:int=10)->StyleBoxFlat:
	var style:=T.flat(bg,border,1,T.RADIUS_CARD,pad);return style


func _icon_button(parent:Node,icon:String,text:String,action:Callable,tip:String="")->Button:
	var button:=Button.new();button.text=text;button.tooltip_text=tip;button.focus_mode=Control.FOCUS_NONE
	button.icon=Icons.command_texture(icon,T.INK,40);button.expand_icon=false
	button.add_theme_constant_override("icon_max_width",16);button.add_theme_constant_override("h_separation",5)
	button.custom_minimum_size=Vector2(30 if text=="" else 0,30)
	button.pressed.connect(action);parent.add_child(button);return button


func layout_columns()->void:
	if not columns:return
	columns.columns=2 if size.x>=860 else 1
	templates_column.custom_minimum_size.x=300 if columns.columns==2 else 0


func report(result:Dictionary)->void:
	var error:=String(result.get("error",""))
	feedback.text=error;feedback.visible=error!="";feedback.tooltip_text=error
	rebuild()


# --- Manpower -----------------------------------------------------------------------

func _build_strip()->void:
	var strip:=PanelContainer.new();strip.name="Manpower";strip.add_theme_stylebox_override("panel",_skin(T.PAPER_SUNK,T.RULE,10));add_child(strip)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",28);strip.add_child(row)
	for spec:Array in [["free","free","can be called up"],["serving","serving","serving"],["training","drilling","in training"],["undone","work","jobs left undone"]]:
		var chip:=HBoxContainer.new();chip.add_theme_constant_override("separation",8);chip.mouse_filter=Control.MOUSE_FILTER_PASS;row.add_child(chip)
		var icon:=TextureRect.new();icon.texture=Icons.command_texture(String(spec[1]),T.INK,48);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size=Vector2(24,24);icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(icon)
		var value:=T.make_label("0",20,T.INK);value.add_theme_font_override("font",T.font("ui_strong"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(value)
		var word:=T.make_label(String(spec[2]),13,T.INK_MUTED);word.size_flags_vertical=Control.SIZE_SHRINK_CENTER;word.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(word)
		chips[String(spec[0])]={"chip":chip,"value":value,"word":word}


func _update_strip()->void:
	var m:=Model.manpower()
	var ledger:Dictionary=m.ledger
	chips.free.value.text=EraWords.grouped(int(m.free))
	chips.free.chip.tooltip_text="%s working-age people could still be called up.\nScouts, envoys and scholars away are not counted." % EraWords.grouped(int(m.free))
	chips.serving.value.text=EraWords.grouped(int(m.serving))
	chips.serving.chip.tooltip_text="%s serve now: %d at home, %d in the field, %d holding towns, %d recovering, %d missing, %d crews." % [EraWords.grouped(int(m.serving)),int(ledger.home),int(ledger.field),int(ledger.occupation),int(ledger.recovering),int(ledger.missing),int(ledger.naval_air)]
	chips.training.value.text=EraWords.grouped(int(m.training))
	chips.training.chip.tooltip_text="%d in drill, %d called up and waiting for a place." % [int(ledger.training),int(ledger.recruits)]
	chips.undone.value.text=EraWords.grouped(int(m.undone))
	chips.undone.value.add_theme_color_override("font_color",T.AMBER_TEXT if int(m.undone)>0 else T.INK)
	chips.undone.chip.tooltip_text="Everyone called up beyond the watch leaves a job at home undone: %d today.\nStand bands down to send them back to work." % int(m.undone)
	chips.undone.chip.visible=int(m.undone)>0 or int(m.serving)>0


# --- Templates ----------------------------------------------------------------------

func build_templates()->void:
	for child in templates_box.get_children():templates_box.remove_child(child);child.queue_free()
	for item:Dictionary in Model.templates():
		var id:=int(item.id)
		var card:=PanelContainer.new();card.name="Template%d" % id;card.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,8));templates_box.add_child(card)
		var body:=HBoxContainer.new();body.add_theme_constant_override("separation",10);card.add_child(body)
		var frame:=PanelContainer.new();frame.clip_contents=true;frame.custom_minimum_size=Vector2(46,58);frame.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK));body.add_child(frame)
		var art:=TextureRect.new();art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var path:=String(item.art)
		if path!="" and ResourceLoader.exists(path):art.texture=load(path)
		else:art.texture=Icons.command_texture("will",T.INK,64);art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(art)
		var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",3);body.add_child(words)
		var title:=T.make_label(String(item.name),15,T.INK);title.add_theme_font_override("font",T.font("ui_strong"));title.clip_text=true;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;words.add_child(title)
		var facts:=HBoxContainer.new();facts.add_theme_constant_override("separation",6);words.add_child(facts)
		_fact(facts,"men",EraWords.grouped(int(item.men)),T.INK,"%d men in each band." % int(item.men))
		var arms:PackedStringArray=[]
		for entry:Dictionary in item.entries:arms.append("%d %s" % [int(entry.count),String(entry.unit_name).to_lower()])
		for weapon:String in item.gear:
			var gear:Dictionary=item.gear[weapon]
			var short:=int(gear.stock)<int(gear.need)
			_fact(facts,"gear",EraWords.grouped(int(gear.need)),T.AMBER_TEXT if short else T.INK,"%s: %d a band · %d in store." % [MilitaryCampaign.PersistentProduction.product_name(weapon),int(gear.need),int(gear.stock)])
		var kinds:=T.make_label(" · ".join(arms),12,T.INK_MUTED);kinds.clip_text=true;kinds.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;kinds.tooltip_text=kinds.text;kinds.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(kinds)
		# What the design does, by the engine's own rules (deployment_model.template_stats).
		var said:Array=Model.stats_words(item.get("stats",{}))
		if String(said[0])!="":
			var stats:=T.make_label(String(said[0]),12,T.INK);stats.name="Stats%d" % id;stats.clip_text=true;stats.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			stats.tooltip_text=String(said[1]);stats.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(stats)
		var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",6);words.add_child(actions)
		var train:=_icon_button(actions,"drill","Train",func():report(MilitaryCampaign.recruit_deploy.add(id,1,1,false)),"Raise and drill one band of %d." % int(item.men))
		train.name="TrainTemplate%d" % id;train.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		train.add_theme_stylebox_override("normal",T.gold_outline_style());train.add_theme_color_override("font_color",T.GOLD_TEXT)
		var five:=_icon_button(actions,"plus","×5",func():report(MilitaryCampaign.recruit_deploy.add(id,5,1,false)),"Raise five bands at once, drilled side by side.")
		five.name="TrainFive%d" % id
		var change:=_icon_button(actions,"edit","",func():edit.call(id),"Change who is in this band.")
		change.name="EditTemplate%d" % id
		for button:Button in [train,five]:
			button.disabled=not bool(item.trainable)
			if not bool(item.trainable):button.tooltip_text=String(item.reason)


func _fact(parent:Node,icon:String,value:String,color:Color,tip:String)->void:
	var box:=HBoxContainer.new();box.add_theme_constant_override("separation",3);box.tooltip_text=tip;box.mouse_filter=Control.MOUSE_FILTER_PASS;parent.add_child(box)
	var mark:=TextureRect.new();mark.texture=Icons.command_texture(icon,T.INK_MUTED,32);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.custom_minimum_size=Vector2(16,16)
	mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(mark)
	var text:=T.make_label(value,14,color);text.add_theme_font_override("font",T.font("ui_strong"));text.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(text)


# --- The queue ----------------------------------------------------------------------

func rebuild()->void:
	for child in rows.get_children():rows.remove_child(child);child.queue_free()
	live.clear()
	var lines:=Model.lines()
	if lines.is_empty():_empty_queue()
	page=clampi(page,0,maxi(0,(lines.size()-1)/LINES_PER_PAGE))
	for item:Dictionary in lines.slice(page*LINES_PER_PAGE,page*LINES_PER_PAGE+LINES_PER_PAGE):_line_card(item)
	if lines.size()>LINES_PER_PAGE:_pager(rows,page,ceili(lines.size()/float(LINES_PER_PAGE)),func(step:int):page+=step;rebuild())
	signature=shape()
	update_values()


func _empty_queue()->void:
	var panel:=PanelContainer.new();panel.name="EmptyQueue";panel.add_theme_stylebox_override("panel",_skin(T.PAPER_SUNK,T.RULE,14));rows.add_child(panel)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);panel.add_child(row)
	var icon:=TextureRect.new();icon.texture=Icons.command_texture("drill",T.INK_MUTED,48);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.custom_minimum_size=Vector2(22,22);icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(icon)
	row.add_child(T.make_label("Nobody in training. Press Train on a band.",14,T.INK_MUTED))


func _pager(parent:Node,at:int,pages:int,step:Callable)->void:
	var paging:=HBoxContainer.new();paging.add_theme_constant_override("separation",8);parent.add_child(paging)
	var back:=_icon_button(paging,"","‹",func():step.call(-1),"Earlier");back.icon=null;back.disabled=at<=0
	paging.add_child(T.make_label("%d / %d" % [at+1,pages],13,T.INK_MUTED))
	var on:=_icon_button(paging,"","›",func():step.call(1),"Later");on.icon=null;on.disabled=at>=pages-1


func _line_card(item:Dictionary)->void:
	var id:=int(item.id)
	var panel:=PanelContainer.new();panel.name="Line%d" % id;panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,8));rows.add_child(panel)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",4);panel.add_child(box)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",6);box.add_child(head)
	var title:=T.make_label(String(item.name),15,T.INK);title.add_theme_font_override("font",T.font("ui_strong"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.clip_text=true;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.custom_minimum_size.x=80;head.add_child(title)
	var minus:=_icon_button(head,"minus","",func():report(MilitaryCampaign.recruit_deploy.change_count(id,-1)),"One band fewer: one not yet started, else the newest in drill goes home.");minus.name="Fewer"
	var count:=T.make_label("",15,T.INK);count.add_theme_font_override("font",T.font("ui_strong"));count.custom_minimum_size.x=34;count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;head.add_child(count)
	var plus:=_icon_button(head,"plus","",func():report(MilitaryCampaign.recruit_deploy.change_count(id,1)),"One band more, drilled alongside the others.");plus.name="More"
	var repeat:=_icon_button(head,"repeat","",func():report(MilitaryCampaign.recruit_deploy.configure(id,"repeat",not bool(MilitaryCampaign.recruit_deploy.line(id).get("repeat",false)))),"Keep raising bands until stopped.")
	repeat.toggle_mode=true;repeat.name="Repeat"
	var priority:=_icon_button(head,"prio1","",func():report(MilitaryCampaign.recruit_deploy.configure(id,"priority",(int(MilitaryCampaign.recruit_deploy.line(id).get("priority",1))+1)%3)),"");priority.name="Priority"
	var automatic:=CheckButton.new();automatic.name="AutoDeploy";automatic.text="Auto";automatic.focus_mode=Control.FOCUS_NONE
	automatic.icon=Icons.command_texture("deploy",T.INK,40);automatic.add_theme_constant_override("icon_max_width",16)
	automatic.tooltip_text="Send each band off as soon as it is trained and armed."
	automatic.toggled.connect(func(on:bool):report(MilitaryCampaign.recruit_deploy.configure(id,"auto_deploy",on)));head.add_child(automatic)
	var destination:=OptionButton.new();destination.name="Destination";destination.fit_to_longest_item=false;destination.custom_minimum_size.x=128;destination.clip_text=true;destination.focus_mode=Control.FOCUS_NONE
	destination.add_item("New band",0)
	# Only a band at home can take new men in (they cannot teleport); bands away
	# are listed greyed so the choice is plain.
	var waiting_on:=""
	for army:Dictionary in MilitaryCampaign.field_armies:
		if int(army.get("troops",0))<=0:continue
		var home:=String(army.get("location_id",""))=="player_home" and String(army.get("status",""))=="stationed"
		destination.add_item(("Join " if home else "Away: ")+Model.Logistics.force_name(army),int(army.army_id))
		if not home:
			destination.set_item_disabled(destination.get_item_count()-1,true)
			if int(army.army_id)==int(item.target_army):waiting_on=Model.Logistics.force_name(army)
	destination.select(maxi(0,destination.get_item_index(int(item.target_army))))
	destination.tooltip_text="Where the new men go. Only a band at home can take them in; bands away are greyed.\nNew band: bands this line raises within a month of each other go out together under one general."
	if waiting_on!="":destination.tooltip_text="Waiting: %s is away. Trained bands wait at home until it returns, or choose New band." % waiting_on
	destination.item_selected.connect(func(index:int):report(MilitaryCampaign.recruit_deploy.configure(id,"target_army",destination.get_item_id(index))));head.add_child(destination)
	var pause:=_icon_button(head,"pause","",func():report(MilitaryCampaign.recruit_deploy.configure(id,"paused",not bool(MilitaryCampaign.recruit_deploy.line(id).get("paused",false)))),"");pause.name="Pause"
	var stop:=_icon_button(head,"stop","",func():report(MilitaryCampaign.recruit_deploy.cancel(id)),"Stop this line: the recruits go home, their gear back to store.");stop.name="Stop"
	live.append({"id":id,"head":true,"count":count,"minus":minus,"repeat":repeat,"priority":priority,"automatic":automatic,"pause":pause,"title":title})
	var bands:Array=item.bands
	var slot_page:=clampi(int(slot_pages.get(id,0)),0,maxi(0,(bands.size()-1)/BANDS_PER_PAGE))
	for band:Dictionary in bands.slice(slot_page*BANDS_PER_PAGE,slot_page*BANDS_PER_PAGE+BANDS_PER_PAGE):_band_row(box,id,band)
	if bands.size()>BANDS_PER_PAGE:_pager(box,slot_page,ceili(bands.size()/float(BANDS_PER_PAGE)),func(step:int):slot_pages[id]=slot_page+step;rebuild())
	if bands.is_empty():
		var waiting:=T.make_label("Waiting for men to call up.",13,T.AMBER_TEXT);waiting.tooltip_text="Nobody is free to call up. Stand a band down, or wait for the young to come of age.";waiting.mouse_filter=Control.MOUSE_FILTER_PASS;box.add_child(waiting)


func _band_row(parent:Node,line_id:int,band:Dictionary)->void:
	var row:=HBoxContainer.new();row.name="Band%d" % int(band.slot);row.add_theme_constant_override("separation",10);parent.add_child(row)
	var number:=T.make_label("%d" % (int(band.index)+1),13,T.INK_MUTED);number.custom_minimum_size.x=14;number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(number)
	var meters:Array=[]
	for kind:String in ["men","gear","drill"]:
		var meter:=Meter.new();meter.kind=kind;meter.name=kind.capitalize();meter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(meter);meters.append(meter)
	meters[1].clicked.connect(_open_production)
	var date:=DateMark.new();date.name="Ready";row.add_child(date)
	var slot:=int(band.slot)
	var deploy:=_icon_button(row,"deploy","Deploy early",func():report(MilitaryCampaign.recruit_deploy.deploy(line_id,slot,true)),"");deploy.name="Deploy"
	deploy.custom_minimum_size.x=128
	live.append({"id":line_id,"slot":slot,"meters":meters,"date":date,"deploy":deploy})


func _open_production()->void:
	var scene:=get_tree().current_scene if is_inside_tree() else null
	if scene!=null and "hud" in scene and scene.hud:scene.hud.open_dock("production",2)


func shape()->String:
	var parts:Array=[page]
	for item:Dictionary in MilitaryCampaign.recruit_deploy.data.lines:parts.append([item.id,item.slots,item.deployed,item.get("target_army",0),slot_pages.get(int(item.id),0)])
	parts.append(MilitaryCampaign.field_armies.map(func(a:Dictionary)->int:return int(a.get("army_id",0))))
	return str(parts)


func update_values()->void:
	_update_strip()
	var lines:=Model.lines()
	var by_id:={}
	var bands:=0;var sent:=0
	for item:Dictionary in lines:
		by_id[int(item.id)]=item;bands+=int(item.in_training);sent+=int(item.deployed)
	queue_counts.text="%d training · %d sent" % [bands,sent] if not lines.is_empty() else ""
	var stock:=Model.stock_rows() if not lines.is_empty() else {}
	for control:Dictionary in live:
		var item:Dictionary=by_id.get(int(control.id),{})
		if item.is_empty():continue
		if control.has("head"):_update_head(control,item);continue
		var band:Dictionary={}
		for candidate:Dictionary in item.bands:
			if int(candidate.slot)==int(control.slot):band=candidate;break
		if band.is_empty():continue
		_update_band(control,band,stock)


func _update_head(control:Dictionary,item:Dictionary)->void:
	control.count.text="∞" if bool(item.repeat) else "×%d" % int(item.count)
	control.count.tooltip_text="Keeps raising bands until stopped." if bool(item.repeat) else "%d bands asked for: %d in training, %d still to start, %d sent." % [int(item.count),int(item.in_training),int(item.remaining),int(item.deployed)]
	control.count.mouse_filter=Control.MOUSE_FILTER_PASS
	(control.repeat as Button).set_pressed_no_signal(bool(item.repeat))
	var level:=clampi(int(item.priority),0,2)
	(control.priority as Button).icon=Icons.command_texture("prio%d" % level,T.INK,40)
	(control.priority as Button).tooltip_text="Priority: %s. Higher lines get men and gear first. Click to change." % PRIORITY_WORDS[level]
	(control.automatic as CheckButton).set_pressed_no_signal(bool(item.auto_deploy))
	var pause:Button=control.pause
	pause.icon=Icons.command_texture("resume" if bool(item.paused) else "pause",T.INK,40)
	pause.tooltip_text="Resume this line." if bool(item.paused) else "Pause this line: no drill, no rations spent."
	(control.title as Label).add_theme_color_override("font_color",T.INK_MUTED if bool(item.paused) else T.INK)
	(control.minus as Button).disabled=not bool(item.repeat) and int(item.remaining)<=0 and int(item.in_training)<=1


func _update_band(control:Dictionary,band:Dictionary,stock:Dictionary={})->void:
	var meters:Array=control.meters
	var men_tip:="%d of %d men gathered." % [int(band.men),int(band.men_target)]
	if bool(band.men_short):men_tip+="\nThe rest are called up as people come free."
	meters[0].set_reading(float(band.men)/maxf(1.0,float(band.men_target)),"%d/%d" % [int(band.men),int(band.men_target)],T.INK_MUTED if not bool(band.men_short) else T.AMBER,men_tip)
	var gear_tip:=Model.gear_words(band,null,stock)
	meters[1].set_reading(float(band.gear)/maxf(1.0,float(band.gear_target)),"%d/%d" % [int(band.gear),int(band.gear_target)],T.AMBER if bool(band.gear_short) else T.BLUE,gear_tip)
	meters[1].clickable=bool(band.gear_short)
	var drill_tip:="%d%% of first drill done." % roundi(float(band.training)*100.0)
	for reason:String in band.reasons:drill_tip+="\n"+reason
	meters[2].set_reading(float(band.training),"%d%%" % roundi(float(band.training)*100.0),T.TEAL,drill_tip)
	var date:DateMark=control.date
	if bool(band.ready):date.set_reading("Ready",T.GREEN_TEXT,"Trained and armed. They join the army at home with the next day.")
	elif bool(band.waits_for_gear):date.set_reading("Needs gear",T.AMBER_TEXT,"Drill is done; they wait for their gear.\n"+gear_tip.get_slice("\nClick",0))
	elif int(band.ready_day)>=0:date.set_reading(Model.day_words(int(band.ready_day)),T.INK,"Ready about %s (%s)." % [EraWords.when(int(band.ready_day)),"in %d days" % int(band.days_left) if int(band.days_left)>1 else "tomorrow"])
	else:date.set_reading("—",T.INK_MUTED,"No day yet: "+("waiting for men to call up." if bool(band.men_short) else "drill has stalled.")+("\n"+"\n".join(band.reasons) if not (band.reasons as Array).is_empty() else ""))
	var deploy:Button=control.deploy
	var early:=bool(band.early)
	deploy.disabled=not early
	deploy.text="Deploy" if bool(band.ready) else "Deploy early"
	deploy.tooltip_text=("Send them off now." if bool(band.ready) else "Send them off now, half-trained. They fight worse.") if early else "Possible once a fifth of their drill is done."


func _process(delta:float)->void:
	refresh_clock+=delta
	if refresh_clock<.5 or rows==null:return
	refresh_clock=0
	if signature!=shape():build_templates();rebuild()
	else:update_values()


class Meter extends Control:
	## One bar of a band's row: its mark, the bar, and the number.
	signal clicked
	const Icons:=preload("res://scripts/resource_icons.gd")
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var kind:="men"
	var share:=0.0
	var text:=""
	var fill:=Color.WHITE
	var clickable:=false

	func _ready()->void:
		custom_minimum_size=Vector2(118,22);mouse_filter=Control.MOUSE_FILTER_STOP

	func set_reading(value:float,words:String,colour:Color,tip:String)->void:
		share=clampf(value,0.0,1.0);text=words;fill=colour;tooltip_text=tip
		mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
		queue_redraw()

	func _gui_input(event:InputEvent)->void:
		if clickable and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			accept_event();clicked.emit()

	func _draw()->void:
		var font:=T.font("ui_strong")
		var number_w:=maxf(40.0,font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+4.0)
		draw_texture_rect(Icons.command_texture(kind,T.INK_MUTED,32),Rect2(Vector2(0,3),Vector2(16,16)),false)
		var bar:=Rect2(Vector2(20,8),Vector2(maxf(8.0,size.x-24-number_w),7))
		draw_rect(bar,T.TRACK)
		if share>0.0:draw_rect(Rect2(bar.position,Vector2(bar.size.x*share,bar.size.y)),fill)
		draw_rect(bar,Color(T.RULE_STRONG,0.7),false,1.0)
		draw_string(font,Vector2(size.x-number_w+4,16),text,HORIZONTAL_ALIGNMENT_LEFT,number_w,13,T.INK)


class DateMark extends Control:
	## The day a band is ready: an hourglass and the date.
	const Icons:=preload("res://scripts/resource_icons.gd")
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var text:=""
	var colour:=Color.BLACK

	func _ready()->void:
		custom_minimum_size=Vector2(128,22);mouse_filter=Control.MOUSE_FILTER_STOP

	func set_reading(words:String,ink:Color,tip:String)->void:
		text=words;colour=ink;tooltip_text=tip;queue_redraw()

	func _draw()->void:
		draw_texture_rect(Icons.command_texture("date",T.INK_MUTED,32),Rect2(Vector2(0,3),Vector2(16,16)),false)
		draw_string(T.font("ui_strong"),Vector2(20,16),text,HORIZONTAL_ALIGNMENT_LEFT,size.x-20,13,colour)
