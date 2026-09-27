extends VBoxContainer
## The Production screen: who runs the workshops, each line in plain words
## (what, how fast, when, what holds it back), household goods, repairs and the
## recipes that can start a new line. Reads the production snapshot only;
## every control calls the provider's existing production actions.
##
## Other dock panels extend this script for _button, _bar and _rule; keep those
## three helpers and their look unchanged. Screen helpers are prefixed _pq_.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Art:=preload("res://scripts/hud/production_art.gd")
const P:=preload("res://scripts/persistent_production.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
var data:Dictionary

func setup(block:Dictionary)->void:
	theme=T.control_theme();data=block;name="IllustratedProductionQueue"
	add_theme_constant_override("separation",24)
	var mode:=String(data.get("mode","military"))
	var lines:Array=data.get("lines",[])
	if mode!="civilian":
		_pq_header(lines)
		_pq_lines(lines)
		_pq_repairs()
	if mode!="military":_pq_households()
	if mode!="civilian":
		_pq_recipes()
		_pq_footer()

# --- Who runs it --------------------------------------------------------------
func _pq_header(lines:Array)->void:
	var box:=VBoxContainer.new();box.name="WhoRunsIt";box.add_theme_constant_override("separation",8);add_child(box)
	var owner:=String(data.get("owner",""))
	var head:=Plain.header(owner,bool(data.get("managed",true)),_pq_named(lines))
	var words:=_pq_label(String(head.text),"voice_small",T.INK);words.name="OwnerLine";box.add_child(words)
	var row:=HBoxContainer.new();box.add_child(row)
	var callback:Variant=data.get("on_header")
	var kind:=String(head.get("kind",""))
	var take:=_pq_button(row,String(head.action),func():if callback is Callable:callback.call(kind),String(head.action_tip),true)
	take.name="OwnerAction";take.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	if not callback is Callable:take.disabled=true
	var status:=String(data.get("status",""))
	if not status.is_empty():
		var note:=_pq_label("Latest note: "+status,"small",T.INK_MUTED);note.name="StaffNote";box.add_child(note)
	var capacity:=int(data.get("capacity",lines.size()))
	var free:=capacity-lines.size()
	var space:=("All workshop space is in use (%d line%s). Finish or close a line to start another." % [lines.size(),"" if lines.size()==1 else "s"]) if free<=0 else ("Room for %d more line%s." % [free,"" if free==1 else "s"])
	if lines.is_empty():space="No lines running. Room for %d." % capacity
	var room:=_pq_label(space,"small",T.INK_MUTED);room.name="WorkshopSpace";box.add_child(room)
	var stores:Array=data.get("stores",[])
	if not stores.is_empty():
		var strip:=HFlowContainer.new();strip.name="Stores";strip.add_theme_constant_override("h_separation",16);strip.add_theme_constant_override("v_separation",6);box.add_child(strip)
		var caption:=_pq_label("In store","small",T.INK_MUTED);caption.size_flags_horizontal=Control.SIZE_FILL;caption.autowrap_mode=TextServer.AUTOWRAP_OFF;strip.add_child(caption)
		for store:Dictionary in stores:
			var chip:=HBoxContainer.new();chip.add_theme_constant_override("separation",4);chip.tooltip_text="%s in store: %s" % [String(store.name),Plain.number(float(store.amount))];strip.add_child(chip)
			chip.add_child(Art.picture(Art.resource(String(store.get("resource",store.name))),22,22))
			var amount:=_pq_label("%s %s" % [String(store.name),Plain.number(float(store.amount))],"small",T.BODY);amount.autowrap_mode=TextServer.AUTOWRAP_OFF;amount.size_flags_horizontal=Control.SIZE_FILL;chip.add_child(amount)

func _pq_named(lines:Array)->Array:
	var result:Array=[]
	for line:Dictionary in lines:
		var copy:=line.duplicate();copy["name"]=P.product_name(String(line.get("item","")));result.append(copy)
	return result

# --- Lines ----------------------------------------------------------------------
func _pq_lines(lines:Array)->void:
	var box:=_pq_section("Workshop lines","WorkshopLines")
	if lines.is_empty():
		box.add_child(_pq_label("Nothing is being made in the workshops. Start a line below, or let your staff start one when a need comes up.","body",T.BODY))
		return
	for line:Dictionary in lines:_pq_line(box,line,lines.size())
	var note:="Priority splits workshop hands between lines. High takes twice Normal's share from the others, Urgent four times; Low takes half." if lines.size()>1 else "Priority only matters when lines compete for workshop hands; this is the only line running."
	var hint:=_pq_label(note,"small",T.INK_MUTED);hint.name="PriorityHint";box.add_child(hint)

func _pq_tone(tone:String)->Color:
	match tone:
		"good":return T.GREEN
		"warn":return T.AMBER
		"bad":return T.RED
	return T.INK_MUTED

func _pq_line(parent:Node,line:Dictionary,count:int)->void:
	var id:=int(line.id)
	var story:=Plain.line_story(line,data.get("context",{}))
	var tone:=_pq_tone(String(story.tone))
	# A paper card under a thin rule in the line's condition colour.
	var card:=VBoxContainer.new();card.name="Line%d" % id;card.add_theme_constant_override("separation",0);parent.add_child(card)
	var rule:=ColorRect.new();rule.color=tone;rule.custom_minimum_size.y=3;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(rule)
	var paper:=PanelContainer.new();var style:=T.paper_panel_style(true,0,16);style.border_width_top=0;style.corner_radius_bottom_left=T.RADIUS_CARD;style.corner_radius_bottom_right=T.RADIUS_CARD
	paper.add_theme_stylebox_override("panel",style);card.add_child(paper)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);paper.add_child(column)
	# Title row: picture, name, condition and who runs it.
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",12);column.add_child(top)
	var picture:=Art.picture(Art.product(String(line.item)),64,52);picture.tooltip_text=P.product_description(String(line.item));picture.mouse_filter=Control.MOUSE_FILTER_PASS;top.add_child(picture)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.size_flags_vertical=Control.SIZE_SHRINK_CENTER;identity.add_theme_constant_override("separation",2);top.add_child(identity)
	var title:=_pq_label(P.product_name(String(line.item)),"voice",T.INK);title.name="Title";identity.add_child(title)
	var tag:=HFlowContainer.new();tag.add_theme_constant_override("h_separation",8);identity.add_child(tag)
	var status:=_pq_label(String(story.short),"small",tone);status.name="Status";status.add_theme_font_override("font",T.font("ui_strong"));status.autowrap_mode=TextServer.AUTOWRAP_OFF;status.size_flags_horizontal=Control.SIZE_FILL;tag.add_child(status)
	var persistent:=bool(line.get("persistent",false))
	var boss:=Plain.first_name(String(data.get("owner","")))
	var runner:=(("%s runs this line" % boss) if boss!="Staff" else "Staff run this line") if bool(line.get("planner_managed",false)) else "You run this line"
	if not persistent:runner="One-off order"
	var who:=_pq_label("· "+runner,"small",T.INK_MUTED);who.autowrap_mode=TextServer.AUTOWRAP_OFF;who.size_flags_horizontal=Control.SIZE_FILL;who.name="Runner";tag.add_child(who)
	# One progress readout.
	var progress:=VBoxContainer.new();progress.add_theme_constant_override("separation",4);column.add_child(progress)
	var caption:=_pq_label(String(story.progress_text),"small",T.BODY);caption.name="Progress";progress.add_child(caption)
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=8;bar.value=float(story.progress)*100.0;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CONTROL));bar.add_theme_stylebox_override("fill",T.flat(tone if String(story.tone)!="muted" else T.RULE_STRONG,Color(0,0,0,0),0,T.RADIUS_CONTROL))
	progress.add_child(bar)
	# The four questions.
	var facts:=GridContainer.new();facts.name="Facts";facts.columns=2;facts.add_theme_constant_override("h_separation",16);facts.add_theme_constant_override("v_separation",6);column.add_child(facts)
	_pq_fact(facts,"Pace",String(story.pace),T.BODY,"PaceValue")
	_pq_fact(facts,"Target",String(story.eta),T.BODY,"EtaValue")
	var held:=String(story.held)+(("\n"+String(story.also)) if story.has("also") else "")
	_pq_fact(facts,"Held back",held,tone if String(story.tone) in ["bad","warn"] else T.BODY,"HeldValue")
	var materials:Array=story.materials
	if not materials.is_empty():
		var parts:Array[String]=[]
		for entry:Dictionary in materials:parts.append(String(entry.text))
		_pq_fact(facts,"Materials","\n".join(parts),T.BODY,"MaterialsValue")
	# Controls, all in words.
	if persistent:
		var controls:=HFlowContainer.new();controls.name="Controls";controls.add_theme_constant_override("h_separation",8);controls.add_theme_constant_override("v_separation",8);column.add_child(controls)
		var paused:=bool(line.get("paused",false))
		var pause:=_pq_button(controls,"Resume" if paused else "Pause",func():_pq_act(id,"pause",0),"Start making again. You take over this line." if paused else "Stop this line for now. Work in progress is kept. You take over this line.")
		pause.name="PauseButton"
		_pq_target(controls,id,int(line.get("target_stock",0)))
		var more:=MenuButton.new();more.name="MoreMenu";more.text="More ▾";more.flat=false;more.tooltip_text="Line details, retooling, workforce, closing the line, or handing it back to staff."
		T.text(more,"small",T.BODY)
		for state:String in ["normal","hover","pressed"]:
			var box:=T.flat(T.HOVER_BG if state!="normal" else T.PAPER_RAISED,T.GOLD if state!="normal" else T.RULE,1,T.RADIUS_CONTROL);box.content_margin_left=12;box.content_margin_right=12
			more.add_theme_stylebox_override(state,box)
		more.custom_minimum_size.y=32;controls.add_child(more)
		var popup:=more.get_popup();popup.theme=T.control_theme()
		popup.add_item("Details, retool or close line",0)
		popup.set_item_tooltip(0,"Full inputs, workforce, retooling to another product, and closing the line.")
		if not bool(line.get("planner_managed",false)):
			popup.add_item("Hand back to %s" % (boss if boss!="Staff" else "staff"),1)
			popup.set_item_tooltip(1,"Staff schedule this line again. Work in progress is kept.")
		popup.id_pressed.connect(func(choice:int):
			if choice==0:
				var detail:Variant=data.get("on_detail")
				if detail is Callable:detail.call(id)
			else:_pq_act(id,"delegate",0))
		var priority:=HBoxContainer.new();priority.name="Priority";priority.add_theme_constant_override("separation",6);column.add_child(priority)
		var priority_label:=_pq_label("Priority","small",T.INK_MUTED);priority_label.autowrap_mode=TextServer.AUTOWRAP_OFF;priority_label.size_flags_horizontal=Control.SIZE_FILL;priority_label.custom_minimum_size.x=80;priority.add_child(priority_label)
		var current:=Plain.priority_name(float(line.get("allocation",1.0)))
		for entry:Array in Plain.PRIORITIES:
			var weight:=float(entry[1])
			var tip:=String({"Low":"Half a Normal line's share of workshop hands; the rest go to other lines.","Normal":"An even share of workshop hands.","High":"Twice a Normal line's share, taken from the other lines.","Urgent":"Four times a Normal line's share, taken from the other lines."}[String(entry[0])])
			if count<=1:tip+=" With one line running, this changes nothing yet."
			var choice:=_pq_button(priority,String(entry[0]),func():_pq_act(id,"priority",weight),tip+" You take over this line.",String(entry[0])==current)
			choice.name="Priority"+String(entry[0]);choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	else:
		var batch:=HFlowContainer.new();batch.name="Controls";column.add_child(batch)
		_pq_button(batch,"Details or cancel",func():
			var detail:Variant=data.get("on_detail")
			if detail is Callable:detail.call(id),"Batch progress; cancelling returns unused materials.")

func _pq_target(parent:Node,id:int,target:int)->void:
	var box:=HBoxContainer.new();box.name="TargetStepper";box.add_theme_constant_override("separation",0);box.tooltip_text="Stock target: the line pauses when this many are in store and starts again when some are used.";parent.add_child(box)
	var down:=_pq_button(box,"−",func():_pq_act(id,"target",Plain.step_target(target,-1)),"Keep fewer in store (applies now). You take over this line.")
	down.name="TargetDown";down.custom_minimum_size.x=34;down.disabled=target<=0
	var field:=PanelContainer.new();field.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.RULE,1,0));box.add_child(field)
	var value:=_pq_label("No target" if target<=0 else "Keep %d" % target,"small",T.INK);value.name="TargetValue"
	value.autowrap_mode=TextServer.AUTOWRAP_OFF;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;value.custom_minimum_size=Vector2(96,30)
	value.tooltip_text="Stock target: the line pauses when this many are in store and starts again when some are used. No target means it keeps making."
	value.mouse_filter=Control.MOUSE_FILTER_PASS;field.add_child(value)
	var up:=_pq_button(box,"+",func():_pq_act(id,"target",Plain.step_target(target,1)),"Keep more in store (applies now). You take over this line.")
	up.name="TargetUp";up.custom_minimum_size.x=34

func _pq_act(id:int,action:String,value:float)->void:
	var callback:Variant=data.get("on_action")
	if callback is Callable:callback.call(id,action,value)

# --- Repairs ----------------------------------------------------------------------
func _pq_repairs()->void:
	var repairs:Array=data.get("repairs",[])
	if repairs.is_empty():return
	var box:=_pq_section("Damaged equipment","Repairs")
	for repair:Dictionary in repairs:
		var count:=int(repair.count)
		box.add_child(_pq_label("%s: %d damaged set%s, %s." % [String(repair.name),count,"" if count==1 else "s",Plain.repair_text(String(repair.status))],"body",T.BODY))
	box.add_child(_pq_label("Staff repair these on the matching line when it has spare work. You don't need to order anything.","small",T.INK_MUTED))

# --- Household goods ---------------------------------------------------------------
func _pq_households()->void:
	var box:=_pq_section("Household goods","Households")
	var cities:Array=data.get("households",[])
	if cities.is_empty():
		box.add_child(_pq_label("No settlement makes household goods yet.","body",T.BODY));return
	box.add_child(_pq_label("Tools, baskets, pots and fittings. Households make these themselves and wear them out; they are not workshop lines.","small",T.INK_MUTED))
	for city:Dictionary in cities:
		var story:=household_story(city)
		var tone:=_pq_tone(String(story.tone))
		var card:=VBoxContainer.new();card.name="Household_"+String(city.get("id",""));card.add_theme_constant_override("separation",0);box.add_child(card)
		var rule:=ColorRect.new();rule.color=tone;rule.custom_minimum_size.y=3;card.add_child(rule)
		var paper:=PanelContainer.new();var style:=T.paper_panel_style(true,0,16);style.border_width_top=0;style.corner_radius_bottom_left=T.RADIUS_CARD;style.corner_radius_bottom_right=T.RADIUS_CARD
		paper.add_theme_stylebox_override("panel",style);card.add_child(paper)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);paper.add_child(column)
		column.add_child(_pq_label("Everyday goods · "+String(city.city),"voice",T.INK))
		column.add_child(_pq_label(String(story.progress_text),"small",T.BODY))
		var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=8;bar.value=float(city.get("coverage",0.0))*100.0
		bar.add_theme_stylebox_override("background",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CONTROL));bar.add_theme_stylebox_override("fill",T.flat(tone,Color(0,0,0,0),0,T.RADIUS_CONTROL));column.add_child(bar)
		var facts:=GridContainer.new();facts.columns=2;facts.add_theme_constant_override("h_separation",16);facts.add_theme_constant_override("v_separation",6);column.add_child(facts)
		_pq_fact(facts,"Pace",String(story.pace),T.BODY,"HouseholdPace")
		_pq_fact(facts,"Full",String(story.eta),T.BODY,"HouseholdEta")
		_pq_fact(facts,"Held back",String(story.held),tone if String(story.tone) in ["bad","warn"] else T.BODY,"HouseholdHeld")
		_pq_fact(facts,"Materials",String(story.materials),T.BODY,"HouseholdMaterials")
	var techniques:Array=data.get("techniques",[])
	if techniques.is_empty():return
	var coverage:=float((cities[0] as Dictionary).get("coverage",0.0))
	var tech:=_pq_section("Household techniques","Techniques")
	tech.add_child(_pq_label("A technique only helps as far as households have goods. With stores %d%% full, each works at about %d%% of its full benefit." % [roundi(coverage*100.0),roundi(coverage*100.0)],"small",T.INK_MUTED))
	var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",6);tech.add_child(grid)
	for technique:Dictionary in techniques:
		var label:=_pq_label(String(technique.name),"body",T.INK);grid.add_child(label)
		var adoption:=roundi(float(technique.adoption)*100.0)
		var value:=_pq_label(("In use everywhere" if adoption>=100 else "In use by %d%%" % adoption)+" · working at %d%%" % roundi(float(technique.working)*100.0),"small",T.BODY)
		value.autowrap_mode=TextServer.AUTOWRAP_OFF;value.size_flags_horizontal=Control.SIZE_FILL;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;grid.add_child(value)

static func household_story(city:Dictionary)->Dictionary:
	var stock:=float(city.get("stock",0.0));var target:=maxf(.01,float(city.get("target",1.0)))
	var made:=float(city.get("made",0.0));var worn:=float(city.get("worn",0.0))
	var coverage:=float(city.get("coverage",clampf(stock/target,0,1)))
	var net:=made-worn
	var story:={"tone":"good"}
	story.progress_text="%s in store of %s wanted (%d%%)" % [Plain.number(stock),Plain.number(target),roundi(coverage*100.0)]
	var wear:=("about %s a day wear out" % Plain.number(worn)) if worn>=0.01 else "hardly any wear out yet"
	story.pace=("Making about %s a day; %s" % [Plain.number(made),wear]) if made>0.0 else ("Nothing made today; "+wear)
	if coverage>=.98:story.eta="Full"
	elif net>0.0:
		var when:=Plain.duration_text((target-stock)/net);story.eta=when.left(1).to_upper()+when.substr(1)+" at this pace"
	else:story.eta="Not filling: wear outpaces making"
	var reason:=String(city.get("reason",""))
	match reason:
		"No craftspeople assigned":story.held="No craftspeople are at work.";story.tone="bad"
		"Needs timber, fiber, clay, stone or flint":story.held="Out of raw materials: timber, fiber, clay, stone or flint.";story.tone="bad"
		"Needs a settled workplace":story.held="Needs a settled place to work.";story.tone="bad"
		_:
			if coverage>=.98 or reason=="Stock target met":story.held="Nothing. Stores are full."
			elif net<=0.0:story.held="Too few craftspeople to keep up with wear.";story.tone="warn"
			else:story.held="Nothing. Filling as fast as the craftspeople can."
	var parts:Array[String]=[]
	for material:Dictionary in city.get("basket",[]):parts.append("%s %s" % [String(material.name).to_lower(),Plain.number(float(material.amount))])
	story.materials=("Any mix of these, in store: "+", ".join(parts)+".") if not parts.is_empty() else "No timber, fiber, clay, stone or flint in store."
	return story

# --- Recipes ------------------------------------------------------------------------
func _pq_recipes()->void:
	var recipes:Array=data.get("recipes",[])
	var box:=_pq_section("Start a new line","Recipes")
	if recipes.is_empty():
		box.add_child(_pq_label("Your people know no workshop recipes yet.","body",T.BODY));return
	var start_target:=int(data.get("start_target",10))
	box.add_child(_pq_label("A new line keeps %d in store; change the target on its card." % start_target,"small",T.INK_MUTED))
	var group:=""
	for recipe:Dictionary in recipes:
		if String(recipe.group)!=group:
			group=String(recipe.group)
			var heading:=_pq_label(group,"small",T.INK);heading.add_theme_font_override("font",T.font("ui_strong"));box.add_child(heading)
		var row:=HBoxContainer.new();row.name="Recipe_"+String(recipe.item);row.add_theme_constant_override("separation",12);box.add_child(row)
		var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);row.add_child(words)
		words.add_child(_pq_label(String(recipe.name),"body",T.INK))
		var blocker:=String(recipe.get("blocker",""))
		var running:=bool(recipe.get("running",false))
		var detail:=String(recipe.needs)
		if running:detail="Already being made · "+detail
		elif not blocker.is_empty():detail=blocker+" · "+detail
		var sub:=_pq_label(detail,"small",T.RED if not blocker.is_empty() and not running else T.INK_MUTED);sub.name="Reason";words.add_child(sub)
		var start:Variant=data.get("on_start")
		var item:=String(recipe.item)
		var tip:="Start a line that keeps %d in store." % start_target
		if running:tip="A line already makes this."
		elif not blocker.is_empty():tip=String(recipe.get("blocker_full",blocker))
		var button:=_pq_button(row,"Start making",func():if start is Callable:start.call(item),tip,blocker.is_empty() and not running)
		button.name="StartButton";button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		button.disabled=not blocker.is_empty() or running or not start is Callable
		var rule:=HSeparator.new();rule.add_theme_color_override("color",T.RULE);box.add_child(rule)

func _pq_footer()->void:
	var row:=HFlowContainer.new();row.name="Footer";row.add_theme_constant_override("h_separation",8);row.add_theme_constant_override("v_separation",8);add_child(row)
	_pq_button(row,"All recipes and order types",data.get("on_add"),"Every product you can make, with one-off batches and continuous lines.")
	_pq_button(row,"Workshop staff and labor",data.get("on_manage"),"Who schedules the workshops, and how much crafting labor goes to lines.")
	_pq_button(row,"Output history",data.get("on_history"),"What the workshops and households have actually finished.")

# --- Shared pieces --------------------------------------------------------------------
func _pq_section(title:String,node_name:String)->VBoxContainer:
	var box:=VBoxContainer.new();box.name=node_name;box.add_theme_constant_override("separation",10);add_child(box)
	var heading:=_pq_label(title,"small",T.GOLD);heading.add_theme_font_override("font",T.font("ui_strong"));heading.name="Heading";box.add_child(heading)
	var rule:=HSeparator.new();rule.add_theme_color_override("color",T.RULE);box.add_child(rule)
	return box

func _pq_label(text:String,role:String,color:Color)->Label:
	var label:=Label.new();label.text=text;T.text(label,role,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label

func _pq_fact(grid:GridContainer,caption:String,value:String,color:Color,node_name:String)->Label:
	var key:=_pq_label(caption,"small",T.INK_MUTED);key.autowrap_mode=TextServer.AUTOWRAP_OFF;key.size_flags_horizontal=Control.SIZE_FILL;key.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;key.custom_minimum_size.x=80;grid.add_child(key)
	var label:=_pq_label(value,"body",color);label.name=node_name;grid.add_child(label)
	return label

func _pq_button(parent:Node,label:String,callback:Variant,tip:String,active:bool=false)->Button:
	var b:=Button.new();b.text=label;b.tooltip_text=tip;b.custom_minimum_size.y=32;T.text(b,"small",T.INK if active else T.BODY)
	var normal:=T.flat(T.ACTIVE_BG if active else T.PAPER_RAISED,T.GOLD if active else T.RULE,1,T.RADIUS_CONTROL);normal.content_margin_left=12;normal.content_margin_right=12
	var hover:=T.flat(T.HOVER_BG,T.GOLD,1,T.RADIUS_CONTROL);hover.content_margin_left=12;hover.content_margin_right=12
	b.add_theme_stylebox_override("normal",normal);b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("pressed",T.button_pressed_style())
	parent.add_child(b)
	if callback is Callable and callback.is_valid():b.pressed.connect(callback)
	else:b.disabled=true
	return b

# --- Helpers shared with panels that extend this script (keep as they are) --------------
func _button(parent:Node,label:String,callback:Variant,tip:String,active:bool=false)->void:
	var b:=Button.new();b.text=label;b.tooltip_text=tip;b.custom_minimum_size=Vector2(28,28);b.add_theme_font_size_override("font_size",12);b.add_theme_color_override("font_color",T.BODY);b.add_theme_color_override("font_hover_color",T.INK)
	b.add_theme_stylebox_override("normal",T.flat(T.ACTIVE_BG if active else Color.TRANSPARENT,T.GOLD if active else T.BORDER_SOFT,1,0,5));b.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.GOLD,1,0,5));parent.add_child(b)
	if callback is Callable and callback.is_valid():b.pressed.connect(callback)
	else:b.disabled=true
func _bar(parent:Node,ratio:float,color:Color)->void:
	var bar:=ProgressBar.new();bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.custom_minimum_size.y=7;bar.show_percentage=false;bar.value=ratio*100;bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(color));parent.add_child(bar)
func _rule(parent:Node)->void:
	var rule:=HSeparator.new();rule.add_theme_color_override("color",T.BORDER_SOFT);parent.add_child(rule)
