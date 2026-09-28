extends Control
## THE BATTLE PANEL: one battle, read at a glance, at any size.
##
## Who is winning and by how much (a bar in the two sides' inks and a plain
## sentence); each side's general, how he is fighting this phase and whether
## the enemy has undone it; what each side took into the fight and what it has
## lost; the line where the two sides meet, block by block, and the reserve
## waiting behind it; why one side has the better of it; what changed; and
## the battle phase by phase. A battle being fought updates as the days pass;
## a finished one opens on its result and can be stepped back through, phase
## by phase. Nothing here fights a battle (battle_record.gd reads the record).
## A skirmish (one block a side, or a fight over at the first blow) is a
## small card instead.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Record:=preload("res://scripts/battle_record.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Account:=preload("res://scripts/battle_account.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")
const SimulationPause:=preload("res://scripts/hud/simulation_pause.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const VIEW_PATH:="res://scripts/hud/battle_view.gd"

## The widest the sheet grows, and the plate sizes it chooses between.
const SHEET_MAX:=1360.0
const PLATE_MAX:=112.0
const PLATE_MIN:=66.0
const PLATE_HEIGHT:=62.0
## Waiting blocks shown before the rest are summed up in words.
const RESERVE_SHOWN:=10

var host:Node
var record:Dictionary={}
var live:=false
var view:Dictionary={}
## 0 is the two sides drawn up; k is the end of phase k.
var step:=-1
var following:=true
var pause:=SimulationPause.new()
var paused_here:=false
var signature:=""
var poll:=0.0
## The battle shown, kept apart from the record: a battle that ends is
## cleared where it was fought and read again from its report.
var battle_id:=""
var battle_seed:=-1
var sheet:PanelContainer
var buttons:Dictionary={}
var left_colour:=Color()
var right_colour:=Color()
var left_text:=Color()
var right_text:=Color()


func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_STOP
	theme=T.control_theme()
	var scrim:=ColorRect.new(); scrim.name="Scrim"; scrim.color=T.SCRIM; scrim.set_anchors_and_offsets_preset(PRESET_FULL_RECT); scrim.mouse_filter=MOUSE_FILTER_STOP; add_child(scrim)
	if not live and is_instance_valid(host):
		pause.acquire(host); paused_here=true
	_refresh()
	modulate.a=0.0
	var tween:=create_tween(); tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"modulate:a",1.0,float(T.MOTION.slow))


func _exit_tree()->void:
	if paused_here: pause.release()
	var ui:Node=get_tree().root.get_node_or_null("MilitaryCommandUI") if is_inside_tree() else null
	if ui!=null and ui.get("battle_graphics")==self: ui.set("battle_graphics",null)


func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_ESCAPE: get_viewport().set_input_as_handled(); close()
			KEY_LEFT: get_viewport().set_input_as_handled(); _step_by(-1)
			KEY_RIGHT: get_viewport().set_input_as_handled(); _step_by(1)


## A live battle is read again as the days pass; when it ends, the panel
## shows how it ended.
func _process(delta:float)->void:
	if not live: return
	poll+=delta
	if poll<0.4: return
	poll=0.0
	var View:=load(VIEW_PATH)
	var found:Dictionary=View.find(battle_id) if battle_id!="" else {}
	if found.is_empty() and battle_seed>=0: found=View.find(battle_seed)
	if found.is_empty(): return
	if not bool(found.get("live",false)):
		record=found.record; live=false; following=true
		_refresh()
		return
	var now:Dictionary=found.record
	var mark:=_signature(now)
	if mark!=signature:
		record=now
		_refresh()


func _signature(source:Dictionary)->String:
	var battle:Dictionary=source.get("battle",{})
	return "%s|%d|%d|%d|%s" % [String(source.get("id","")),int(source.get("round",(source.get("rounds",[]) as Array).size())),int(battle.get("exchange",0)),(battle.get("phases",[]) as Array).size(),str(host.get("game_speed")) if is_instance_valid(host) else ""]


# --- Building ---------------------------------------------------------------------------

func _refresh()->void:
	if String(record.get("id",""))!="": battle_id=String(record.id)
	if record.has("seed"): battle_seed=int(record.seed)
	var View:=load(VIEW_PATH)
	view=Record.view(record,View.words(record,live))
	signature=_signature(record)
	var player:=bool(view.player)
	left_colour=T.TEAL if player else T.AMBER
	right_colour=T.RED if player else T.BLUE
	left_text=T.TEAL_TEXT if player else T.AMBER_TEXT
	right_text=T.RED_TEXT if player else T.BLUE_TEXT
	var count:=(view.phases as Array).size()
	if following or step<0 or step>count: step=count
	if is_instance_valid(sheet): sheet.get_parent().queue_free()
	buttons.clear()
	if bool(view.skirmish): _build_card()
	else: _build_panel()


func _build_card()->void:
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(center)
	sheet=PanelContainer.new(); sheet.name="Card"
	sheet.add_theme_stylebox_override("panel",T.paper_panel_style(true,T.RADIUS_CARD,32.0))
	sheet.custom_minimum_size=Vector2(minf(620.0,get_viewport_rect().size.x-32.0),0)
	center.add_child(sheet)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",14); sheet.add_child(column)
	_label(column,"A SKIRMISH%s" % _where_suffix().to_upper(),"kicker",T.INK_MUTED).name="Kicker"
	var headline:=_label(column,String(view.one_line) if String(view.one_line)!="" else String(view.phrase)+".","title",T.INK)
	headline.name="Headline"; headline.add_theme_font_override("font",T.voice_font()); headline.add_theme_font_size_override("font_size",26)
	var line:=HBoxContainer.new(); line.add_theme_constant_override("separation",24); column.add_child(line)
	for key in ["left","right"]:
		var side:Dictionary=view.sides[key]
		var box:=VBoxContainer.new(); box.size_flags_horizontal=SIZE_EXPAND_FILL; line.add_child(box)
		_label(box,_side_kicker(key),"kicker",left_text if key=="left" else right_text)
		var totals:Dictionary=side.totals
		var exact:=bool(side.exact)
		_label(box,"%s went in; %s still standing." % [_n(int(totals.went_in),exact),_n(int(totals.standing),exact)],"body",T.BODY)
		var lost:=_lost_words(totals,exact)
		if lost!="": _label(box,lost,"small",T.INK_MUTED)
	var events:Array=[]
	for phase in view.phases: events.append_array(phase.events)
	if not events.is_empty(): _label(column,String(events[-1])+".","body",T.BODY).name="Event"
	column.add_child(_rule())
	var row:=HBoxContainer.new(); row.alignment=BoxContainer.ALIGNMENT_END; row.add_theme_constant_override("separation",12); column.add_child(row)
	_time_button(row)
	_button(row,"Close","close",true)


func _build_panel()->void:
	var shell:=MarginContainer.new(); shell.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: shell.add_theme_constant_override("margin_"+edge,20)
	add_child(shell)
	# One tall sheet, centred: the header and footer stay put, the body scrolls.
	var row:=HBoxContainer.new(); row.alignment=BoxContainer.ALIGNMENT_CENTER; shell.add_child(row)
	sheet=PanelContainer.new(); sheet.name="Sheet"
	sheet.add_theme_stylebox_override("panel",T.paper_panel_style(true,T.RADIUS_CARD,24.0))
	var viewport_size:=get_viewport_rect().size
	var width:=minf(SHEET_MAX,viewport_size.x-40.0)
	sheet.custom_minimum_size=Vector2(width,0)
	sheet.size_flags_vertical=SIZE_EXPAND_FILL
	row.add_child(sheet)
	var outer:=VBoxContainer.new(); outer.add_theme_constant_override("separation",10); sheet.add_child(outer)
	_build_header(outer)
	_build_timeline(outer)
	var scroll:=ScrollContainer.new(); scroll.name="Body"; scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var inset:=MarginContainer.new(); inset.add_theme_constant_override("margin_right",16); inset.size_flags_horizontal=SIZE_EXPAND_FILL; scroll.add_child(inset)
	var body:=VBoxContainer.new(); body.size_flags_horizontal=SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",18); inset.add_child(body)
	var inner:=width-48.0-16.0
	body.custom_minimum_size.x=inner
	_build_sides(body,inner)
	_build_line(body,inner)
	_build_reasons(body,inner)
	_build_phase_summary(body)
	outer.add_child(_rule())
	_build_footer(outer)


func _build_header(parent:Node)->void:
	var head:=VBoxContainer.new(); head.name="Header"; head.add_theme_constant_override("separation",6); parent.add_child(head)
	var top:=HBoxContainer.new(); head.add_child(top)
	var kicker:=_label(top,"THE FIGHT %s · %s" % [_where_words().to_upper(),_when_words().to_upper()] if _when_words()!="" else "THE FIGHT %s" % _where_words().to_upper(),"kicker",T.INK_MUTED)
	kicker.name="Kicker"; kicker.size_flags_horizontal=SIZE_EXPAND_FILL
	var shown:Dictionary=_shown_phase()
	var phrase:=String(view.phrase)
	if step<(view.phases as Array).size() or (live and step==0):
		phrase=Record.phrase(float(shown.get("progress",0.0)),0.0,bool(view.player),String(view.names.left),String(view.names.right))
	var headline:=_label(head,phrase,"title",T.INK); headline.name="Headline"
	headline.add_theme_font_override("font",T.voice_font()); headline.add_theme_font_size_override("font_size",30)
	var sub:=[_cap(String(view.ground.words))]
	sub.append(String(view.status))
	if String(record.get("id",""))!="" and live: sub.append(_battle_day_words())
	var subline:=_label(head,"  ·  ".join(PackedStringArray(sub)),"small",T.INK_MUTED); subline.name="Where"
	if not live and String(view.one_line)!="" and String(view.one_line)!=String(view.phrase)+".":
		_label(head,String(view.one_line),"body",T.BODY).name="Account"
	var bar:=ProgressStrip.new(); bar.name="Progress"
	bar.value=float(shown.get("progress",view.progress)) if not shown.is_empty() else float(view.progress)
	var previous:Dictionary=_phase_at(step-1)
	bar.ghost=float(previous.get("progress",bar.value)) if not previous.is_empty() else bar.value
	bar.left_colour=left_colour; bar.right_colour=right_colour
	bar.custom_minimum_size=Vector2(0,22)
	bar.tooltip_text="Who has the better of the fight: the further the bar reaches toward a side's end, the more that side is winning."
	head.add_child(bar)
	var ends:=HBoxContainer.new(); head.add_child(ends)
	var left_name:=_label(ends,_cap(String(view.names.left)),"small",left_text); left_name.size_flags_horizontal=SIZE_EXPAND_FILL
	left_name.add_theme_font_override("font",T.font("ui_strong"))
	var right_name:=_label(ends,_cap(String(view.names.right)),"small",right_text); right_name.size_flags_horizontal=SIZE_EXPAND_FILL
	right_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; right_name.add_theme_font_override("font",T.font("ui_strong"))


func _build_sides(parent:Node,width:float)->void:
	var row:=HBoxContainer.new(); row.name="Sides"; row.add_theme_constant_override("separation",32); parent.add_child(row)
	var shown:Dictionary=_shown_phase()
	for key in ["left","right"]:
		var side:Dictionary=view.sides[key]
		var box:=VBoxContainer.new(); box.name="Side"+key.capitalize(); box.size_flags_horizontal=SIZE_EXPAND_FILL; box.add_theme_constant_override("separation",4)
		box.custom_minimum_size.x=(width-32.0)*0.5
		row.add_child(box)
		_label(box,_side_kicker(key),"kicker",left_text if key=="left" else right_text)
		_label(box,_cap(String(view.names[key])),"value",T.INK)
		var general:Dictionary=side.general
		var who:=String(general.name)
		var about:=String(general.line)
		if who!="" or about!="": _label(box,(who+("  ·  " if who!="" and about!="" else "")+about).strip_edges(),"small",T.BODY)
		var tactic:Dictionary=(shown.get("tactics",{}) as Dictionary).get(key,{}) if not shown.is_empty() else {}
		if String(tactic.get("words",""))!="":
			var how:=_label(box,"This phase: %s%s" % [String(tactic.words).substr(0,1).to_lower()+String(tactic.words).substr(1),"  (a new way of fighting)" if bool(tactic.get("changed",false)) else ""],"body",T.BODY)
			how.name="Tactic"
			if bool(tactic.get("countered",false)):
				var by:=String(tactic.get("by","")).to_lower()
				_label(box,"Undone by %s %s" % ["their" if key=="left" and bool(view.player) else ("our" if bool(view.player) else "the other side's"),by.trim_prefix("a ").trim_prefix("an ")],"small",T.RED_TEXT).name="Countered"
		box.add_child(_totals(side,key))


func _totals(side:Dictionary,key:String)->Control:
	var totals:=_totals_at(side,key)
	var exact:=bool(side.exact)
	var grid:=GridContainer.new(); grid.name="Totals"; grid.columns=6
	grid.add_theme_constant_override("h_separation",10); grid.add_theme_constant_override("v_separation",2)
	for pair in [["Went in",int(totals.went_in)],["Still standing",int(totals.standing)],["Killed",int(totals.killed)],["Wounded",int(totals.wounded)],["Fled",int(totals.fled)],["Taken",int(totals.captured)]]:
		var name:=_label(grid,String(pair[0]),"small",T.INK_MUTED); name.autowrap_mode=TextServer.AUTOWRAP_OFF
		var value:=_label(grid,"none" if int(pair[1])<=0 and String(pair[0]) not in ["Went in","Still standing"] else _n(int(pair[1]),exact),"body",T.INK)
		value.autowrap_mode=TextServer.AUTOWRAP_OFF
		value.add_theme_font_override("font",T.font("ui_strong"))
	return grid


func _build_line(parent:Node,width:float)->void:
	var box:=VBoxContainer.new(); box.name="Line"; box.add_theme_constant_override("separation",6); parent.add_child(box)
	var top:=HBoxContainer.new(); top.add_theme_constant_override("separation",16); box.add_child(top)
	var kicker:=_label(top,"THE LINE","kicker",T.INK_MUTED); kicker.autowrap_mode=TextServer.AUTOWRAP_OFF
	var plates:Dictionary=_plates_shown()
	var note:=_frontage_note(plates)
	var legend:=_label(top,note,"small",T.INK_MUTED); legend.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; legend.size_flags_horizontal=SIZE_EXPAND_FILL
	var label_width:=132.0
	var most:=maxi(1,maxi((plates.left.front as Array).size(),(plates.right.front as Array).size()))
	var room:=width-label_width-8.0
	var plate_width:=clampf(floorf(room/float(most))-6.0,PLATE_MIN,PLATE_MAX)
	var player:=bool(view.player)
	var fit:=maxi(3,floori((room-200.0)/(plate_width+6.0)))
	_plate_row(box,"Their reserve" if player else "%s waiting" % _cap(_strip(String(view.names.right))),plates.right.rear,"right",plate_width,label_width,true,fit)
	_plate_row(box,"Their line" if player else "%s line" % _cap(_possessive(String(view.names.right))),plates.right.front,"right",plate_width,label_width,false)
	var contact:=HBoxContainer.new(); contact.add_theme_constant_override("separation",8); box.add_child(contact)
	var spacer:=Control.new(); spacer.custom_minimum_size.x=label_width; contact.add_child(spacer)
	var rule:=ContactRule.new(); rule.size_flags_horizontal=SIZE_EXPAND_FILL; rule.custom_minimum_size.y=14; rule.colour=T.RULE_STRONG; contact.add_child(rule)
	_plate_row(box,"Our line" if player else "%s line" % _cap(_possessive(String(view.names.left))),plates.left.front,"left",plate_width,label_width,false)
	_plate_row(box,"Our reserve" if player else "%s waiting" % _cap(_strip(String(view.names.left))),plates.left.rear,"left",plate_width,label_width,true,fit)
	_label(box,"On each block: its arm and how many are still with it; the upper bar is the men left of those it started with, the lower bar is their heart.","small",T.INK_MUTED)


func _plate_row(parent:Node,title:String,plates:Array,key:String,plate_width:float,label_width:float,rear:bool,fit:int=RESERVE_SHOWN)->void:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",8); parent.add_child(row)
	var name:=_label(row,title,"small",left_text if key=="left" else right_text)
	name.custom_minimum_size.x=label_width; name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	name.add_theme_font_override("font",T.font("ui_strong"))
	var flow:=HFlowContainer.new(); flow.size_flags_horizontal=SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation",6); flow.add_theme_constant_override("v_separation",6)
	row.add_child(flow)
	var shown:=plates
	var waiting:Array=[]; var broken:=0; var fled:=0
	for plate in plates:
		match String(plate.state):
			"reserve": waiting.append(plate)
			"broken": broken+=1
			"fled": fled+=1
	var room:=mini(fit,RESERVE_SHOWN)
	if rear:
		shown=waiting.slice(0,room)
		if broken+fled>0 and waiting.size()<room:
			for plate in plates:
				if String(plate.state)!="reserve" and shown.size()<room: shown.append(plate)
	for plate in shown:
		var card:=Plate.new()
		card.data=plate; card.accent=left_colour if key=="left" else right_colour
		card.custom_minimum_size=Vector2(plate_width,PLATE_HEIGHT)
		card.tooltip_text=_plate_words(plate)
		flow.add_child(card)
	var gone_shown:=0
	for plate in shown:
		if String(plate.state)!="reserve": gone_shown+=1
	var summary:=_rear_summary(waiting.size()-mini(waiting.size(),room),broken,fled,broken+fled>gone_shown,key) if rear else ""
	if rear and plates.is_empty(): summary="Nobody waiting."
	if not rear and plates.is_empty(): summary="Nobody in the line."
	if summary!="":
		var words:=_label(flow,summary,"small",T.INK_MUTED); words.custom_minimum_size=Vector2(0,PLATE_HEIGHT); words.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		words.autowrap_mode=TextServer.AUTOWRAP_OFF


func _rear_summary(more:int,broken:int,fled:int,summed:bool,key:String)->String:
	var word:=String(view.sides[key].word)
	var parts:Array[String]=[]
	if more>0: parts.append("and %s more %s waiting" % [_count(more),word if more==1 else _plural(word)])
	if broken>0 and summed: parts.append("%s broke and ran" % _count(broken))
	if fled>0 and summed: parts.append("%s fled" % _count(fled))
	return ", ".join(parts)


func _frontage_note(plates:Dictionary)->String:
	var shown:Dictionary=_shown_phase()
	var capacity:=int(shown.get("capacity",0))
	var fighting:=(plates.left.front as Array).size()
	var total:=fighting+(plates.left.rear as Array).size()
	var word:=String(view.sides.left.word)
	if capacity<=0 or total<=fighting: return "Every %s is in the line." % word if total>1 else ""
	return "The ground lets about %s a side fight at once: %s of %s %s here." % [Marks.about(capacity).trim_prefix("about "),_count(fighting),_count(total),_plural(word)]


func _build_reasons(parent:Node,width:float)->void:
	var row:=HBoxContainer.new(); row.name="Reasons"; row.add_theme_constant_override("separation",32); parent.add_child(row)
	var shown:Dictionary=_shown_phase()
	var why:=VBoxContainer.new(); why.name="Why"; why.size_flags_horizontal=SIZE_EXPAND_FILL; why.add_theme_constant_override("separation",4)
	why.custom_minimum_size.x=(width-32.0)*0.56
	row.add_child(why)
	var player:=bool(view.player)
	_label(why,"WHY","kicker",T.INK_MUTED)
	var items:Array=shown.get("why",[]) if not shown.is_empty() else []
	if items.is_empty(): _label(why,"Nothing has been fought yet." if step==0 else "Too little is known to say.","small",T.INK_MUTED)
	else: _label(why,("How much each thing adds to our strength (+) or to theirs (−)." if player else "How much each thing adds to %s strength (+) or to %s (−)." % [_possessive(String(view.names.left)),_possessive(String(view.names.right))]),"small",T.INK_MUTED).name="WhyLegend"
	var grid:=GridContainer.new(); grid.columns=3; grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",4)
	why.add_child(grid)
	for item in items.slice(0,7):
		var pct:=int(item.pct)
		var ours:=String(item.favours)=="left"
		var tag:=_label(grid,"%s%d%%" % ["+" if pct>=0 else "−",absi(pct)],"body",left_text if ours else right_text)
		tag.add_theme_font_override("font",T.font("ui_strong")); tag.autowrap_mode=TextServer.AUTOWRAP_OFF
		tag.tooltip_text="How much this adds to %s strength against the other side." % ("our" if ours and player else ("their" if player else _possessive(String(view.names.left if ours else view.names.right))))
		var name:=_label(grid,String(item.label),"body",T.INK); name.autowrap_mode=TextServer.AUTOWRAP_OFF
		var text:=_label(grid,String(item.text)+".","small",T.BODY)
		text.size_flags_horizontal=SIZE_EXPAND_FILL
	var changes:=VBoxContainer.new(); changes.name="Changes"; changes.size_flags_horizontal=SIZE_EXPAND_FILL; changes.add_theme_constant_override("separation",4)
	row.add_child(changes)
	_label(changes,"WHAT CHANGED","kicker",T.INK_MUTED)
	var events:Array=shown.get("events",[]) if not shown.is_empty() else []
	if events.is_empty(): _label(changes,"The two sides are drawn up, facing each other." if step==0 else "Nothing changed but the slow wearing down of both lines.","small",T.INK_MUTED)
	for line in events.slice(0,6):
		_label(changes,"•  %s." % String(line),"body",T.BODY)


## The battle's phases as a row of steps, with the men each side lost in
## each phase beside them; picking a step shows the field as it was then.
func _build_timeline(parent:Node)->void:
	var phases:Array=view.phases
	var row:=HBoxContainer.new(); row.name="Timeline"; row.add_theme_constant_override("separation",16); parent.add_child(row)
	var steps:=HFlowContainer.new(); steps.name="Steps"; steps.size_flags_horizontal=SIZE_EXPAND_FILL
	steps.add_theme_constant_override("h_separation",6); steps.add_theme_constant_override("v_separation",6); row.add_child(steps)
	var labels:Array=["Drawn up"]
	for phase in phases: labels.append(String(phase.when)+(" (now)" if bool(phase.get("current",false)) else ""))
	for index in labels.size():
		var tab:=Button.new(); tab.text=String(labels[index]); tab.toggle_mode=true; tab.button_pressed=index==step
		tab.focus_mode=Control.FOCUS_NONE
		T.text(tab,"small",T.INK)
		tab.custom_minimum_size=Vector2(0,30)
		tab.add_theme_stylebox_override("normal",T.action_button_style(false))
		tab.add_theme_stylebox_override("pressed",T.gold_outline_style() if index==step else T.button_pressed_style())
		tab.add_theme_stylebox_override("hover_pressed",T.gold_outline_style())
		tab.tooltip_text="The two sides as they stood before the first blow." if index==0 else "The field at the end of these hours of fighting."
		tab.pressed.connect(_select.bind(index))
		steps.add_child(tab)
	if phases.is_empty(): return
	var losses:=VBoxContainer.new(); losses.add_theme_constant_override("separation",0); row.add_child(losses)
	var strip:=LossStrip.new(); strip.name="Losses"
	strip.values=view.losses_by_phase; strip.selected=step-1
	strip.left_colour=left_colour; strip.right_colour=right_colour
	strip.custom_minimum_size=Vector2(clampf(float(phases.size())*44.0,120.0,300.0),40)
	strip.tooltip_text="Men lost in each phase: %s on the left of each pair, %s on the right." % [String(view.names.left),String(view.names.right)]
	losses.add_child(strip)
	var legend:=_label(losses,"Men lost in each phase","small",T.INK_MUTED); legend.name="LossLegend"; legend.autowrap_mode=TextServer.AUTOWRAP_OFF


func _build_phase_summary(parent:Node)->void:
	var shown:Dictionary=_shown_phase()
	if shown.is_empty() or step<=0: return
	var losses:Dictionary=shown.losses
	var summary:="%s: %s lost %s; %s lost %s." % [String(shown.when),_cap(String(view.names.left)),_n(int(losses.left.total),true),String(view.names.right),_n(int(losses.right.total),bool(view.sides.right.exact))]
	var box:=VBoxContainer.new(); box.name="Phase"; box.add_theme_constant_override("separation",4); parent.add_child(box)
	_label(box,"THIS PHASE","kicker",T.INK_MUTED)
	_label(box,summary,"body",T.BODY).name="PhaseSummary"


func _build_footer(parent:Node)->void:
	var row:=HBoxContainer.new(); row.name="Footer"; row.add_theme_constant_override("separation",12); parent.add_child(row)
	var back:=_button(row,"Earlier","earlier",false); back.disabled=step<=0
	var forward:=_button(row,"Later","later",false); forward.disabled=step>=(view.phases as Array).size()
	var gap:=Control.new(); gap.size_flags_horizontal=SIZE_EXPAND_FILL; row.add_child(gap)
	_time_button(row)
	_button(row,"Close","close",true)


func _time_button(row:Node)->void:
	if not live or not is_instance_valid(host) or not ("game_speed" in host) or not host.has_method("_set_game_speed"): return
	var held:=float(host.get("game_speed"))<=0.0
	_button(row,"Let the fight go on" if held else "Hold time","time",held)


# --- Acting -------------------------------------------------------------------------------

func _act(id:String)->void:
	match id:
		"close": close()
		"earlier": _step_by(-1)
		"later": _step_by(1)
		"time":
			if is_instance_valid(host) and host.has_method("_set_game_speed"):
				host.call("_set_game_speed",1.0 if float(host.get("game_speed"))<=0.0 else 0.0)
			_refresh()


func _select(index:int)->void:
	step=clampi(index,0,(view.phases as Array).size())
	following=step>=(view.phases as Array).size()
	_rebuild_only()


func _step_by(delta:int)->void:
	_select(step+delta)


func _rebuild_only()->void:
	if is_instance_valid(sheet): sheet.get_parent().queue_free()
	buttons.clear()
	if bool(view.skirmish): _build_card()
	else: _build_panel()


func close()->void:
	var layer:=get_parent()
	if is_instance_valid(host) and host.has_meta(load(VIEW_PATH).META) and host.get_meta(load(VIEW_PATH).META)==layer: host.remove_meta(load(VIEW_PATH).META)
	if layer is CanvasLayer: layer.queue_free()
	else: queue_free()


# --- What is shown ---------------------------------------------------------------------------

func _phase_at(index:int)->Dictionary:
	if index<=0 or index>(view.phases as Array).size(): return {}
	return view.phases[index-1]


func _shown_phase()->Dictionary:
	if step<=0:
		var first:Dictionary=_phase_at(1)
		return {"tactics":first.get("tactics",{}),"progress":0.0,"why":[],"events":[],"capacity":int(first.get("capacity",0)),"losses":{"left":{"total":0},"right":{"total":0}},"when":"Drawn up"} if not first.is_empty() else {}
	return _phase_at(step)


func _plates_shown()->Dictionary:
	if step<=0: return view.start
	return _phase_at(step).plates


## Losses so far at the step shown; the finished battle's own totals at its end.
func _totals_at(side:Dictionary,key:String)->Dictionary:
	var totals:Dictionary=side.totals
	var count:=(view.phases as Array).size()
	if step>=count: return totals
	var out:={"went_in":int(totals.went_in),"killed":0,"wounded":0,"fled":0,"captured":0}
	for index in range(1,step+1):
		var losses:Dictionary=(_phase_at(index).losses as Dictionary)[key]
		for kind in ["killed","wounded","fled","captured"]: out[kind]=int(out[kind])+int(losses[kind])
	out["standing"]=maxi(0,int(out.went_in)-int(out.killed)-int(out.wounded)-int(out.fled)-int(out.captured))
	return out


# --- Words -----------------------------------------------------------------------------------

func _where_words()->String:
	var where:=String(view.where)
	if where=="" and String(view.place)!="": return "at "+String(view.place)
	if where=="" or where=="in the open country":
		# No town to name it by: the ground itself.
		where=Record.ground_place(String(view.ground.kind))
	return where


func _where_suffix()->String:
	return " "+_where_words()


func _when_words()->String:
	if live: return Chronicle.date_label(int(WorldSimulation.state.elapsed_days)) if WorldSimulation!=null else ""
	return Chronicle.date_label(int(view.day)) if int(view.day)>0 else ""


func _battle_day_words()->String:
	var started:=int(view.started)
	var today:=int(WorldSimulation.state.elapsed_days) if WorldSimulation!=null else started
	var day:=maxi(1,today-started+1)
	return "Day %s of the battle" % _count(day)


func _side_kicker(key:String)->String:
	if bool(view.player): return "OUR SIDE" if key=="left" else "THEIR SIDE"
	var role:=String(view.sides[key].role)
	return "ATTACKING" if role=="attacker" else "DEFENDING"


func _plate_words(plate:Dictionary)->String:
	var arm:=Record.arm_words(String(plate.arm),int(plate.men))
	var state:=String(plate.state)
	var heart:=Account.morale_words(float(plate.cohesion))
	var where:=String({"front":"in the line","reserve":"waiting in reserve","broken":"broke and ran","fled":"left the field"}.get(state,""))
	if state in ["broken","fled"] and int(plate.men)<=0: return "%s: %s. It started with %s." % [_cap(Record.arm_words(String(plate.arm),2)),where,_grouped(int(plate.men0))]
	return "%s: %s of %s still with it, %s, %s." % [_cap(Record.arm_words(String(plate.arm),2)),_grouped(int(plate.men)),_grouped(int(plate.men0)),heart,where]


func _lost_words(totals:Dictionary,exact:bool)->String:
	var parts:Array[String]=[]
	for pair in [["killed","killed"],["wounded","wounded"],["fled","ran"],["captured","taken"]]:
		if int(totals[pair[0]])>0: parts.append("%s %s" % [_n(int(totals[pair[0]]),exact),String(pair[1])])
	return _cap(", ".join(parts)+".") if not parts.is_empty() else "Nobody lost."


func _n(value:int,exact:bool)->String:
	return _grouped(value) if exact or value<=20 else Marks.about(value)


func _grouped(value:int)->String:
	return preload("res://scripts/hud/era_words.gd").grouped(value)


func _count(n:int)->String:
	var words:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
	return words[n] if n>=0 and n<words.size() else _grouped(n)


func _plural(word:String)->String:
	return preload("res://scripts/battle_blocks.gd").plural(word)


func _possessive(name:String)->String:
	var clean:=_strip(name)
	return clean+"'" if clean.ends_with("s") else clean+"'s"


func _strip(name:String)->String:
	return name.trim_prefix("the ").trim_prefix("The ")


func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)


# --- Small parts ------------------------------------------------------------------------------

func _label(parent:Node,text:String,role:String,color:Color)->Label:
	var label:=Label.new(); label.text=text; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	T.text(label,role,color); parent.add_child(label)
	return label


func _button(parent:Node,text:String,id:String,primary:bool)->Button:
	var button:=Button.new(); button.name=id.capitalize().replace(" ",""); button.text=text
	T.text(button,"body",T.INK)
	button.custom_minimum_size=Vector2(0,40)
	button.add_theme_stylebox_override("normal",T.action_button_style(primary))
	button.add_theme_stylebox_override("hover",T.action_button_style(primary,true))
	button.pressed.connect(_act.bind(id))
	parent.add_child(button); buttons[id]=button
	return button


func _rule()->Control:
	var rule:=ColorRect.new(); rule.color=T.RULE; rule.custom_minimum_size=Vector2(0,1)
	return rule


## One block: its arm, how many are still with it, a bar for the men left of
## those it started with and one for its heart; worn, broken or gone at a glance.
class Plate extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	const Record:=preload("res://scripts/battle_record.gd")
	var data:Dictionary={}
	var accent:=Color.WHITE

	func _ready()->void:
		mouse_filter=MOUSE_FILTER_PASS

	func _draw()->void:
		var w:=size.x; var h:=size.y
		var state:=String(data.get("state","front"))
		var faded:=state=="fled"
		var ground:=T.PAPER_RAISED if state=="front" else T.PAPER_SUNK
		if faded: ground=T.PAPER
		draw_rect(Rect2(Vector2.ZERO,size),ground)
		if state=="broken":
			var hatch:=Color(T.RED,0.18)
			var x:=-h
			while x<w:
				draw_line(Vector2(x,h),Vector2(x+h,0),hatch,1.0)
				x+=7.0
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE,false,1.0)
		if state=="front": draw_rect(Rect2(0,0,w,3),accent)
		var ink:=T.INK if not faded else Color(T.INK_MUTED,0.8)
		var icon:=Icons.arm_texture(String(data.get("arm","spear")),T.INK if not faded else T.INK_MUTED,accent)
		draw_texture_rect(icon,Rect2(5,7,26,26),false,Color(1,1,1,0.55 if faded else 1.0))
		var strong:=T.font("ui_strong"); var plain:=T.font("ui")
		var men:=int(data.get("men",0))
		var number:=preload("res://scripts/hud/era_words.gd").grouped(men) if men>0 else ("broke" if state=="broken" else "gone")
		draw_string(strong,Vector2(33,22),number,HORIZONTAL_ALIGNMENT_RIGHT,w-38,15,ink if men>0 else (T.RED_TEXT if state=="broken" else T.INK_MUTED))
		if w>=86.0:
			var word:=Record.arm_words(String(data.get("arm","spear")),maxi(2,men))
			draw_string(plain,Vector2(33,37),word,HORIZONTAL_ALIGNMENT_RIGHT,w-38,12,T.INK_MUTED)
		elif state=="reserve" or faded:
			pass
		# Men left, then heart.
		var bar_w:=w-12.0
		var strength:=clampf(float(data.get("strength",1.0)),0.0,1.0)
		var heart:=clampf(float(data.get("cohesion",1.0)),0.0,1.0)
		draw_rect(Rect2(6,h-17,bar_w,4),T.TRACK)
		draw_rect(Rect2(6,h-17,bar_w*strength,4),Color(T.INK,0.72 if not faded else 0.35))
		draw_rect(Rect2(6,h-10,bar_w,4),T.TRACK)
		var heart_colour:=T.GREEN if heart>=0.5 else (T.AMBER if heart>=0.25 else T.RED)
		draw_rect(Rect2(6,h-10,bar_w*heart,4),Color(heart_colour,0.9 if not faded else 0.4))


## Who is winning: the bar reaches toward the side that has the better of it.
class ProgressStrip extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var value:=0.0
	var ghost:=0.0
	var left_colour:=Color.WHITE
	var right_colour:=Color.WHITE

	func _draw()->void:
		var w:=size.x; var h:=size.y
		var split:=clampf(0.5+value*0.5,0.0,1.0)*w
		draw_rect(Rect2(0,0,w,h),T.TRACK)
		draw_rect(Rect2(0,0,split,h),Color(left_colour,0.88))
		draw_rect(Rect2(split,0,w-split,h),Color(right_colour,0.88))
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE_STRONG,false,1.0)
		draw_line(Vector2(w*0.5,-3),Vector2(w*0.5,h+3),Color(T.PAPER,0.9),2.0)
		var before:=clampf(0.5+ghost*0.5,0.0,1.0)*w
		if absf(before-split)>2.0: draw_line(Vector2(before,1),Vector2(before,h-1),Color(T.PAPER,0.55),2.0)
		draw_line(Vector2(split,-4),Vector2(split,h+4),T.INK,3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(split-6,-8),Vector2(split+6,-8),Vector2(split,-2)]),T.INK)


## The line where the two sides meet.
class ContactRule extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var colour:=Color.BLACK

	func _draw()->void:
		var y:=size.y*0.5
		var x:=0.0
		while x<size.x:
			draw_line(Vector2(x,y),Vector2(minf(size.x,x+10.0),y),colour,2.0)
			x+=16.0
		var text:="where the lines meet"
		var font:=T.font("ui")
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		var at:=Vector2((size.x-width)*0.5,y+4)
		draw_rect(Rect2(at.x-8,0,width+16,size.y),T.PAPER_RAISED)
		draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)


## Men lost in each phase, the two sides side by side; the phase shown is marked.
class LossStrip extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var values:Array=[]
	var selected:=-1
	var left_colour:=Color.WHITE
	var right_colour:=Color.WHITE

	func _draw()->void:
		if values.is_empty(): return
		var most:=1
		for pair in values: most=maxi(most,maxi(int(pair.left),int(pair.right)))
		var n:=values.size()
		var slot:=minf(size.x/float(n),120.0)
		var bar:=minf(22.0,slot*0.3)
		var font:=T.font("ui")
		var base:=size.y-16.0
		draw_line(Vector2(0,base),Vector2(slot*float(n),base),T.RULE,1.0)
		for i in n:
			var pair:Dictionary=values[i]
			var x:=float(i)*slot+slot*0.5
			var lh:=(base-4.0)*float(pair.left)/float(most)
			var rh:=(base-4.0)*float(pair.right)/float(most)
			draw_rect(Rect2(x-bar-1,base-lh,bar,lh),Color(left_colour,0.85))
			draw_rect(Rect2(x+1,base-rh,bar,rh),Color(right_colour,0.85))
			if i==selected: draw_rect(Rect2(x-bar-5,base+2,bar*2+10,3),T.GOLD)
			draw_string(font,Vector2(x-bar-4,size.y-2),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,bar*2+8,12,T.INK_MUTED)
