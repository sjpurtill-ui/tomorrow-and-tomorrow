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
var view:Dictionary={}
var lead_picker:OptionButton
var lead_reader:VBoxContainer
var lead_count:Label
## The aims sheet sits in its own slot (hidden while there is no aim).
var aims_slot:VBoxContainer

func setup(block:Dictionary)->void:
	name="KnownWorldBoard"
	model=block.get("model",{})
	view=block.get("view",{})
	if not view.has("lead"):view.lead=""
	if not view.has("query"):view.query=""
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
		var focus:=get_viewport().gui_get_focus_owner()
		var focus_name:=String(focus.name) if focus!=null and is_ancestor_of(focus) else ""
		for child in get_children():remove_child(child);child.queue_free()
		_build_compact()
		if focus_name!="":
			var replacement:=find_child(focus_name,true,false) as Control
			if replacement!=null:replacement.grab_focus()
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
	var head:=UI.heading(stack,"Told of, not yet met")
	UI.verb(head,"Map of hearsay",actions.get("rumor_map",Callable()),"Where travellers' accounts place peoples we have not seen").name="RumorMap"
	lead_count=UI.label(stack,"",14,T.INK_MUTED);lead_count.name="LeadCount"
	var choose:=HBoxContainer.new();choose.add_theme_constant_override("separation",8);stack.add_child(choose)
	var search:=LineEdit.new();search.name="FindLead";search.placeholder_text="Find a telling";search.text=String(view.query);search.custom_minimum_size=Vector2(140,40);search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choose.add_child(search)
	search.add_theme_font_size_override("font_size",14)
	lead_picker=OptionButton.new();lead_picker.name="SelectLead";lead_picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;T.apply_button_style(lead_picker,false);choose.add_child(lead_picker);lead_picker.get_popup().max_size.y=320
	lead_picker.fit_to_longest_item=false;lead_picker.clip_text=true;lead_picker.custom_minimum_size.x=120
	lead_reader=VBoxContainer.new();lead_reader.name="SelectedLead";lead_reader.add_theme_constant_override("separation",6);stack.add_child(lead_reader)
	search.text_changed.connect(func(text:String):view.query=text;_refresh_lead_picker())
	lead_picker.item_selected.connect(func(index:int):view.lead=String(lead_picker.get_item_metadata(index));_show_lead())
	_refresh_lead_picker();_show_lead()

static func lead_key(lead:Dictionary)->String:
	return String(lead.get("id","")) if String(lead.get("id",""))!="" else String(lead.get("name",""))+"|"+String(lead.get("where",""))+"|"+String(lead.get("text",""))

func _refresh_lead_picker()->void:
	lead_picker.clear()
	var query:=String(view.query).strip_edges().to_lower()
	var selected_found:=false
	var leads:Array=model.get("leads",[])
	if String(view.lead)=="" and not leads.is_empty():view.lead=lead_key(leads[0])
	for lead:Dictionary in leads:
		if query!="" and not query in (String(lead.get("name",""))+" "+String(lead.get("where",""))+" "+String(lead.get("text",""))).to_lower():continue
		lead_picker.add_item(String(lead.get("name","A people"))+" · "+String(lead.get("where","")))
		var index:=lead_picker.item_count-1
		lead_picker.set_item_metadata(index,lead_key(lead))
		if lead_key(lead)==String(view.lead):lead_picker.select(index);selected_found=true
	var matching:=lead_picker.item_count
	if matching==0:lead_picker.add_item("No matching tellings");lead_picker.set_item_disabled(0,true)
	elif not selected_found:lead_picker.select(-1);lead_picker.text="Choose a matching telling"
	lead_picker.tooltip_text="%d matching of %d tellings" % [matching,leads.size()]
	lead_count.text="%d tellings" % leads.size() if query=="" else "%d matching of %d tellings" % [matching,leads.size()]
	lead_reader.visible=matching>0

func _show_lead()->void:
	for child in lead_reader.get_children():lead_reader.remove_child(child);child.queue_free()
	var selected:Dictionary={}
	var leads:Array=model.get("leads",[])
	for lead:Dictionary in leads:
		if lead_key(lead)==String(view.lead):selected=lead;break
	if selected.is_empty() and not leads.is_empty():selected=leads[0];view.lead=lead_key(selected);_refresh_lead_picker()
	if selected.is_empty():return
	var UI:=preload("res://scripts/hud/world_ui.gd")
	var title:=UI.label(lead_reader,String(selected.get("where","")),18,T.INK,true);title.name="LeadWhere"
	var text:=UI.label(lead_reader,String(selected.get("text","")),16,T.INK);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.name="LeadEvidence"
	var status:=HFlowContainer.new();status.add_theme_constant_override("h_separation",12);status.add_theme_constant_override("v_separation",4);lead_reader.add_child(status)
	var dots:=Dots.new();dots.amount=clampf(float(selected.get("confidence",0))/.5,0,1);status.add_child(dots);dots.tooltip_text=String(selected.get("word",""))
	UI.label(status,String(selected.get("word",""))+(" · an old telling" if bool(selected.get("stale",false)) else ""),14,T.INK_MUTED)
	var searches:=int(selected.get("searched",0))
	if searches>0:UI.label(lead_reader,"%d search%s; not found." % [searches,"" if searches==1 else "es"],14,T.INK_MUTED)
	var actions:Dictionary=model.get("actions",{})
	var follow:=UI.verb(status,"Follow lead",actions.get("plan",Callable()),"Plan an expedition on the map; choose the route there.");follow.name="FollowLead"


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

