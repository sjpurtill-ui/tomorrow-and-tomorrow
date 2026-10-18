extends BoxContainer
## Named people, measured programs and distinct decisions. No labor commands.
const Families=preload("res://scripts/major_families.gd")
const Tokens=preload("res://scripts/hud/hud_tokens.gd")
const Purse=preload("res://scripts/realm_purse.gd")
const Business=preload("res://scripts/enterprise.gd")
const Tracker=preload("res://scripts/order_tracker.gd")
const Portrait=preload("res://scripts/hud/person_portrait.gd")
const Values=preload("res://scripts/societal_values_model.gd")
signal selected(id:String)
signal changed
signal summon(person_id:int)
var selected_id:=""
var _updates:Array[Callable]=[]
var _list_scroll:ScrollContainer
var _detail_scroll:ScrollContainer
var _details:VBoxContainer
var _program:GridContainer
var _pages:Array[Control]=[]
var _tabs:Array[Button]=[]
var _shape:Array=[]
var _portraits:Dictionary={}
var page:=0

func _label(parent:Node,text:String,size:int=15)->Label:
	var label:=Tokens.make_label(text,size,Tokens.TEXT_SOFT);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);return label
func _column(parent:Node)->VBoxContainer:
	var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",7);parent.add_child(box);return box
func _button(parent:Node,title:String,action:String,id:String,tip:String="",disabled:bool=false)->Button:
	var button:=Button.new();button.text=title;button.tooltip_text=tip;button.disabled=disabled
	button.name=action.capitalize()+id;button.custom_minimum_size.y=34;Tokens.apply_button_style(button);parent.add_child(button)
	button.pressed.connect(func()->void:
		var order:=Tracker.register(title,"court");var result:=Families.decide(action,id)
		if result.ok:Tracker.done(order,String(result.text))
		else:Tracker.refuse(order,String(result.text))
		changed.emit())
	return button
func _signature()->Array:
	var result:Array=[Tokens.color_mode,Families.data().get("mandate","")]
	for f:Dictionary in Families.data().get("families",[]):result.append([f.id,f.head,f.stage,f.party,f.character])
	return result
func refresh()->bool:
	if not Families.active() or _signature()!=_shape:return false
	for update:Callable in _updates:update.call()
	return true
func _layout()->void:
	vertical=size.x<780
	_list_scroll.custom_minimum_size=Vector2(0,180) if vertical else Vector2(250,0)
	_list_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL if vertical else Control.SIZE_FILL
	_list_scroll.size_flags_vertical=Control.SIZE_FILL if vertical else Control.SIZE_EXPAND_FILL
	_detail_scroll.custom_minimum_size.y=600 if vertical else 500
func _show_page(index:int)->void:
	page=index
	for i in _pages.size():_pages[i].visible=i==page;_tabs[i].set_pressed_no_signal(i==page)
func build(id:String)->void:
	selected_id=id;name="FamilyCourt";size_flags_vertical=Control.SIZE_EXPAND_FILL;size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",18);_shape=_signature().duplicate(true)
	_list_scroll=ScrollContainer.new();_list_scroll.name="FamilyListScroll";_list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(_list_scroll)
	var list:=_column(_list_scroll)
	var people:Array=[]
	for f:Dictionary in Families.data().get("families",[]):people.append(GovernmentPeopleSystem.person_snapshot(int(f.head)))
	var slots:=Portrait.distinct_slots(people);var picture_index:=0
	for f:Dictionary in Families.data().get("families",[]):
		var row:=HBoxContainer.new();list.add_child(row)
		var head:=GovernmentPeopleSystem.person_snapshot(int(f.head));_portraits[String(f.id)]=slots[picture_index];row.add_child(Portrait.picture_slot(head,slots[picture_index],40,48));picture_index+=1
		var button:=Button.new();button.name="Select"+String(f.id);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.clip_text=true;button.custom_minimum_size.x=190
		button.text="%s\n%s" % [String(f.name),String(Families.TRADES[f.id][0])];button.tooltip_text=String(head.get("name","Vacant"));Tokens.apply_button_style(button,String(f.id)==id);row.add_child(button)
		var picked:=String(f.id);button.pressed.connect(func():selected.emit(picked))
	var scroll:=ScrollContainer.new();scroll.name="FamilyDetailScroll";scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;add_child(scroll);_detail_scroll=scroll
	_details=_column(scroll)
	var f:=Families.family(id)
	if f.is_empty():return
	var head:=GovernmentPeopleSystem.person_snapshot(int(f.head))
	var identity:=HBoxContainer.new();_details.add_child(identity);identity.add_child(Portrait.picture_slot(head,_portraits[id],72,86))
	var names:=_column(identity);_label(names,String(f.name),24);_label(names,String(head.get("name","Vacant")),19)
	var position:=_label(names,"")
	_updates.append(func():
		var current:=Families.family(id);var d:=Families.data()
		position.text="%s · loyalty %.0f%% · standing %.1f%s%s" % [Families.STAGES[int(current.stage)],float(current.loyalty)*100,float(current.standing)," · favored" if d.favored==id else ""," · endorsed" if d.mandate==id else ""])
	var stages:=HFlowContainer.new();stages.name="FamilyEvolution";_details.add_child(stages)
	for stage in range(1,6):
		var step:=_column(stages);step.add_theme_constant_override("separation",2)
		for text:String in [Families.STAGES[stage],preload("res://scripts/hud/era_words.gd").grouped(Families.THRESHOLDS[stage-1])+" people"]:
			var label:=_label(step,text,12);label.autowrap_mode=TextServer.AUTOWRAP_OFF
			label.add_theme_color_override("font_color",Tokens.TEAL if int(f.stage)>=stage else Tokens.MUTED)
	var organization:=_label(_details,"",13)
	_updates.append(func():
		var current:=Families.family(id);var stage:=int(current.stage)
		organization.text="%d / %d months organizing for %s" % [int(current.months),Families.MATURITY[stage],Families.STAGES[stage+1]] if stage<5 else "Established political party"
		if stage<5 and Families.ceiling(int(SettlementModel.national_population()))<=stage:organization.text+=" · needs %s people" % preload("res://scripts/hud/era_words.gd").grouped(Families.THRESHOLDS[stage]))
	var call_button:=Button.new();call_button.text="Speak to "+String(head.get("name","the head"));Tokens.apply_button_style(call_button);_details.add_child(call_button);call_button.pressed.connect(func():summon.emit(int(Families.family(id).head)))
	var character:Dictionary=f.character
	_label(_details,"Wants to "+String(character.want)+". Fears "+String(character.fear)+".",14)
	_label(_details,"“"+Families.Character.speech(character,int(GameState.elapsed_days)/30,float(GameState.simulation_metrics.get("food_intake_ratio",1))<.8)+"”",16)
	var tabs:=HFlowContainer.new();_details.add_child(tabs)
	for title:String in ["Program & patronage","Values & culture","Funding & trade"]:
		var button:=Button.new();button.text=title;button.toggle_mode=true;Tokens.apply_button_style(button);tabs.add_child(button);_tabs.append(button)
		var index:=_pages.size();var content:=_column(_details);_pages.append(content);button.pressed.connect(_show_page.bind(index))
	_build_program(_pages[0],id)
	_build_values(_pages[1],id)
	_build_spending(_pages[2],id)
	_show_page(0);resized.connect(_layout);_layout();refresh()

func _build_program(parent:Node,id:String)->void:
	_label(parent,"Efficiency bonus · workers stay where you assigned them",13)
	_program=GridContainer.new();_program.name="ProgramComparison";_program.columns=4;_program.add_theme_constant_override("h_separation",12);parent.add_child(_program)
	for heading:String in ["Effect","Now","Endorse","Favor"]:_label(_program,heading,12)
	var now:=Families.bonuses();var proposed:=Families.program_bonuses(id)
	for role:String in Families.TRADES:
		if not now.has(role) and not proposed.has(role):continue
		_label(_program,String(Families.EFFECT_NAMES[role]).capitalize(),14)
		for kind in 3:
			var cell:=_column(_program)
			var reading:=_label(cell,"",18)
			var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size=Vector2(45,4);bar.max_value=12;cell.add_child(bar)
			bar.add_theme_stylebox_override("background",Tokens.flat(Tokens.TRACK))
			_updates.append(func():
				var values:Dictionary=Families.bonuses() if kind==0 else Families.program_bonuses(id,.15 if kind==2 and Families.data().favored!=id else 0.0)
				var value:=float(values.get(role,0))*100;reading.text="%+.1f%%" % value;reading.add_theme_color_override("font_color",Tokens.RED_TEXT if value<0 else Tokens.GREEN_TEXT)
				bar.value=absf(value);bar.add_theme_stylebox_override("fill",Tokens.flat(Tokens.RED if value<0 else Tokens.GREEN)))
	var rival:=_label(parent,"",13)
	_updates.append(func():
		var challenger:=Families.family(String(Families.data().challenger))
		rival.text="Opposition: "+String(challenger.get("name","none"))+ (" · %.0f points off this trade's bonus" % (6 if Families.stage()>=3 else 3) if Families.stage()>=2 and not challenger.is_empty() and challenger.id!=id else ""))
	var actions:=HFlowContainer.new();parent.add_child(actions)
	var favor:=_button(actions,"Favor this head","favor",id,"Endorses their program; +15 loyalty points here and −15 to the previous favored head, who becomes a rival.")
	var endorse:=_button(actions,"Endorse program","entrust",id,"Applies the Endorse column. Patronage, workers, spending and trade rules stay unchanged.")
	_updates.append(func():favor.disabled=Families.data().favored==id;endorse.disabled=Families.data().mandate==id)
	var loyalty:=_label(parent,"",13)
	_updates.append(func():
		var f:=Families.family(id);var old:=Families.family(String(Families.data().favored))
		loyalty.text="Favor: loyalty %.0f%% → %.0f%%" % [float(f.loyalty)*100,minf(1,float(f.loyalty)+(.15 if old.get("id","")!=id else 0))*100]
		if not old.is_empty() and old.id!=id:loyalty.text+=" · "+String(old.name)+" −15 points; becomes a rival")
	_button(parent,"Withdraw patronage and endorsement","neutral","","Funding and trade rules keep their current settings.")
	_label(parent,"Last three decisions",14)
	var history:=_label(parent,"",13)
	_updates.append(func():
		var lines:PackedStringArray=[]
		for event:Dictionary in Families.data().history.slice(0,3):lines.append("Day %d · %s" % [int(event.day),String(event.text)])
		history.text="\n".join(lines))

func _build_values(parent:Node,id:String)->void:
	_label(parent,"Official → lived values · their preferred direction",16)
	var f:=Families.family(id)
	for axis:String in f.character.values:
		var definition:=Values.value_definition(axis)
		var tile:=preload("res://scripts/hud/comparison_tile.gd").new();parent.add_child(tile)
		_updates.append(func():
			var values:Dictionary=GameState.societal_values;var target:=float(Families.family(id).character.values[axis])
			tile.fill(String(definition.get("name",axis)),"OFFICIAL",roundi(float(values.official.get(axis,.5))*100),"LIVED",roundi(float(values.lived.get(axis,.5))*100),"Wants %.0f / 100 · %s" % [target*100,definition.get("high",axis) if target>.5 else definition.get("low",axis)])
			for bar:ProgressBar in tile.bars:bar.max_value=100)
	_label(parent,"Favor moves official values first. Public acceptance follows results; inherited traditions last after patronage. These are current readings, not a forecast.",13)
	if not String(f.party).is_empty():
		var party:Dictionary=Families.data().parties.get(String(f.party),{})
		_label(parent,String(party.get("name","")),18)
		var leader:=GovernmentPeopleSystem.person_snapshot(int(party.get("head",0)))
		_label(parent,"Party leader: "+String(leader.get("name","Vacant")),16)
		_label(parent,"Founding house: "+String(party.get("founder","")),13)
		_label(parent,"Platform: "+", ".join(party.get("members",[])),14)

func _build_spending(parent:Node,id:String)->void:
	var program:=Families.program(id);var line:=String(program.line)
	_label(parent,"Requested service · "+line.capitalize(),18)
	var cost:=_label(parent,"",17)
	_updates.append(func():cost.text="%.1f %s / day · %.0f%% last funded" % [Purse.line_cost_per_day(line),Purse.unit_word(),float(GameState.realm_purse.get("funded",{}).get(line,0))*100] if line!="relief" else "Relief buys actual unmet food needs; its cost varies.")
	var fund:=_button(parent,"Fund "+line,"fund",id,"Uses the existing public purse and adds 8 loyalty points. Service is delivered only as funds allow.")
	_updates.append(func():fund.disabled=Purse.line_on(line))
	_label(parent,"Payment requires funds in the public purse. Enabling a service does not promise full delivery or change the worker split.",13)
	var quote:=Business.quote(String(program.stance))
	_label(parent,"Trade rules · "+Business.stance_name(String(program.stance)),18)
	_label(parent,String(quote.get("words","")),14)
	var trade:=_button(parent,"Adopt "+Business.stance_name(String(program.stance)),"trade",id,"Changes the realm's existing trade rules; adds 8 loyalty points to this head.")
	_updates.append(func():trade.disabled=Business.stance()==String(program.stance))

func view_state()->Dictionary:return {"page":page}
func restore_view_state(state:Dictionary)->void:_show_page(clampi(int(state.get("page",0)),0,2))
