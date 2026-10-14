extends VBoxContainer
## WORLD › PEOPLES, under the ledger of peoples: what we strive for (the live
## generational aim, legacy_aims.gd) and the peoples told of but not yet met,
## one line each with Follow. No chart of its own: the map beside the page
## shows the same ground with the scouts' routes inked on it
## (expedition_routes_overlay.gd). Built from the plain model in
## dock_content_world.gd; every action is a Callable from that model.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Kit:=preload("res://scripts/hud/artifact_gallery.gd")

var model:Dictionary={}
var tier:=0
## The aims sheet sits in its own slot (hidden while there is no aim).
var aims_slot:VBoxContainer

func setup(block:Dictionary)->void:
	name="KnownWorldBoard"
	model=block.get("model",{})
	tier=int(model.get("tier",0))
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	_build_compact()

## The live refresh: the side is drawn again only when its aims or leads moved.
func update_block(block:Dictionary)->bool:
	var next:Dictionary=block.get("model",{})
	var old_model:=model
	model=next
	if old_model.get("aims",{})!=next.get("aims",{}) or old_model.get("leads",[])!=next.get("leads",[]):
		for child in get_children():remove_child(child);child.queue_free()
		_build_compact()
	return true

## "What we strive for": the live generational aim (legacy_aims.gd), its
## progress in the people's words, what rivals have sworn, and legacies won.
func _build_aims()->void:
	var aims:Dictionary=model.get("aims",{})
	var live:Dictionary=aims.get("active",{})
	var waiting:=String(aims.get("waiting",""))
	var rivals:Array=aims.get("rivals",[])
	var legacies:Array=aims.get("legacies",[])
	aims_slot.visible=not (live.is_empty() and waiting=="" and rivals.is_empty() and legacies.is_empty())
	if not aims_slot.visible: return
	var frame:=PanelContainer.new();frame.name="AimsSheet";frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel",sheet_style());aims_slot.add_child(frame)
	var stack:=VBoxContainer.new();stack.name="Aims";stack.add_theme_constant_override("separation",8);frame.add_child(stack)
	preload("res://scripts/hud/world_ui.gd").heading(stack,"What we strive for",String(live.get("by","")) if not live.is_empty() else "")
	if not live.is_empty():
		var title:=Kit.serif(stack,String(live.get("title","")),24,T.INK,true);title.name="AimTitle"
		var bar:=AimBar.new();bar.name="AimProgress";bar.progress=float(live.get("progress",0.0));bar.marks=live.get("milestones",[]);bar.custom_minimum_size=Vector2(0,18);stack.add_child(bar)
		bar.tooltip_text=preload("res://scripts/hud/era_words.gd").way_along(float(live.get("progress",0.0)))
		var said:=String(live.get("words",""))
		var line:=Kit.label(stack,"%s · %s left" % [said.substr(0,1).to_upper()+said.substr(1),String(live.get("left",""))],13,T.BODY,false);line.name="AimWords"
		if String(live.get("clash",""))!="":
			Kit.label(stack,"%s have sworn against it." % String(live.clash),12,T.GOLD_TEXT,false)
	elif waiting!="":
		Kit.serif(stack,"The people want an aim. Summon %s to hear it." % waiting,16,T.INK,true).name="AimWaiting"
	for rival:Dictionary in rivals:
		var row:=Kit.label(stack,"%s of %s has sworn to %s%s%s" % [String(rival.get("leader","")),String(rival.get("people","")),String(rival.get("phrase","")),(", as the ruler before swore" if int(rival.get("heirs",0))>0 else ""),(" (against our aim)" if bool(rival.get("clash",false)) else "")],12,T.TEXT_SOFT,false)
		row.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;row.name="Vow_"+String(rival.get("civ_id","")).validate_node_name()
		if String(rival.get("why",""))!="":
			var why:=Kit.serif(stack,String(rival.why),12,T.MUTED,true);why.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			why.name="VowWhy_"+String(rival.get("civ_id","")).validate_node_name()
	for legacy:Dictionary in legacies:
		var remembered:=Kit.serif(stack,"Remembered: %s, %s" % [String(legacy.get("name","")),preload("res://scripts/hud/era_words.gd").when(int(legacy.get("day",0)))],13,T.BODY,true)
		remembered.name="Legacy_%d" % int(legacy.get("day",0))

## No chart of its own: the map beside the page shows the same ground, with
## the scouts' routes inked on it (expedition_routes_overlay.gd).
## No chart of its own: the map beside the page shows the same ground, with
## the scouts' routes inked on it (expedition_routes_overlay.gd).
func _build_compact()->void:
	var side:=VBoxContainer.new();side.name="Side";side.size_flags_horizontal=Control.SIZE_EXPAND_FILL;side.add_theme_constant_override("separation",12);add_child(side)
	aims_slot=VBoxContainer.new();aims_slot.name="AimsSlot";aims_slot.add_theme_constant_override("separation",0)
	side.add_child(aims_slot)
	_fill_compact_side(side)

## The side of the chart: what we strive for, then the peoples told of.
func _fill_compact_side(side:VBoxContainer)->void:
	_build_aims()
	var leads:Array=model.get("leads",[])
	var UI:=preload("res://scripts/hud/world_ui.gd")
	var actions:Dictionary=model.get("actions",{})
	if leads.is_empty():
		var empty:=HFlowContainer.new();empty.name="Leads";empty.add_theme_constant_override("h_separation",12);empty.add_theme_constant_override("v_separation",4);side.add_child(empty)
		UI.label(empty,"No other peoples have been told of.",14,T.INK_MUTED)
		UI.verb(empty,"Map of hearsay",actions.get("rumor_map",Callable()),"Where travellers' accounts place peoples we have not seen").name="RumorMap"
		return
	var stack:=UI.sheet(side,"Leads")
	var names:={}
	for lead:Dictionary in leads:names[String(lead.get("name",""))]=true
	var shared:=String(names.keys()[0]) if names.size()==1 else ""
	var head:=UI.heading(stack,"Told of, not yet met"+((": "+the_name(shared)) if shared!="" else ""))
	UI.verb(head,"Map of hearsay",actions.get("rumor_map",Callable()),"Where travellers' accounts place peoples we have not seen").name="RumorMap"
	for index in leads.size():
		var lead:Dictionary=leads[index]
		var row:=UI.line(stack,6);row.name="Lead_%d" % index
		var tip:="%s%s%s" % [String(lead.get("text","")),"
"+String(lead.get("word","")),("
Searched for %d times, not found." % int(lead.get("searched",0))) if int(lead.get("searched",0))>0 else ("
An old telling." if bool(lead.get("stale",false)) else "")]
		row.tooltip_text=tip
		var dots:=Dots.new();dots.amount=clampf(float(lead.get("confidence",0.0))/.5,0,1);row.add_child(dots)
		dots.tooltip_text=tip;dots.mouse_filter=Control.MOUSE_FILTER_PASS
		# Where they are said to be leads the row; many tellings share a name.
		UI.cell(row,String(lead.get("where","")),132,13,T.INK if not bool(lead.get("stale",false)) else T.INK_MUTED,true).tooltip_text=tip
		var who:=the_name(String(lead.get("name","")))
		if shared=="":UI.label(row,who.substr(0,1).to_upper()+who.substr(1),12,T.INK_MUTED,false,true).tooltip_text=tip
		else:UI.spacer(row)
		var follow:=UI.verb(row,"Follow",actions.get("plan",Callable()),"Push an expedition toward them, planned on the map");follow.name="FollowLead"

class AimBar extends Control:
	var progress:=0.0
	var marks:Array=[]
	func _ready()->void:resized.connect(queue_redraw)
	func _draw()->void:
		var h:=size.y*0.5
		var y:=(size.y-h)*0.5
		draw_rect(Rect2(0,y,size.x,h),Color(T.BORDER_SOFT,.5))
		draw_rect(Rect2(0,y,size.x*clampf(progress,0.0,1.0),h),T.GOLD)
		for mark in [25,50,75]:
			var x:=size.x*float(mark)/100.0
			draw_line(Vector2(x,y-3),Vector2(x,y+h+3),T.INK if int(mark) in marks else Color(T.INK,.35),1.5)

## "the Keshan", but "The Nine Fires" when the name already carries its article.
static func the_name(people:String)->String:
	var name_text:=people.strip_edges()
	var lower:=name_text.to_lower()
	if lower.begins_with("the ") or lower.begins_with("a ") or lower.begins_with("an "):return name_text
	return "the "+name_text


## The shared ruled panel (dense_blocks.gd render_frame).
static func sheet_style()->StyleBoxFlat:
	var style:=T.flat(Color(T.PAPER_RAISED,0.5),T.RULE,1,4)
	style.set_content_margin_all(10)
	return style

class Dots extends Control:
	var amount:=0.0
	func _init()->void:custom_minimum_size=Vector2(44,12);size_flags_vertical=Control.SIZE_SHRINK_CENTER;mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		for i:int in 5:
			var c:=Vector2(4+i*9,size.y*.5)
			if float(i)<amount*5.0-.01:draw_circle(c,3,T.GOLD)
			else:draw_arc(c,3,0,TAU,12,Color(T.GOLD,.45),1.0,true)

