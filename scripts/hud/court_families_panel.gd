extends HBoxContainer
## The domestic court: durable interests, their actual requests, and consequences.
const Families=preload("res://scripts/major_families.gd")
const Tokens=preload("res://scripts/hud/hud_tokens.gd")
const Purse=preload("res://scripts/realm_purse.gd")
const Business=preload("res://scripts/enterprise.gd")
const Tracker=preload("res://scripts/order_tracker.gd")
signal selected(id:String)
signal changed
signal summon(person_id:int)

func _label(parent:Node,text:String,size:int=15)->Label:
	var label:=Tokens.make_label(text,size,Tokens.TEXT_SOFT)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent:Node,title:String,action:String,id:String,tip:String="",disabled:bool=false)->Button:
	var button:=Button.new();button.text=title;button.tooltip_text=tip;button.disabled=disabled
	button.name=action.capitalize()+id;button.custom_minimum_size.y=34;Tokens.apply_button_style(button)
	parent.add_child(button)
	button.pressed.connect(func()->void:
		var order:=Tracker.register(title,"court")
		var result:=Families.decide(action,id)
		if result.ok:Tracker.done(order,String(result.text))
		else:Tracker.refuse(order,String(result.text))
		changed.emit())
	return button

func build(id:String)->void:
	name="FamilyCourt";size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",18)
	var d:=Families.data()
	var list_scroll:=ScrollContainer.new();list_scroll.name="FamilyListScroll";list_scroll.custom_minimum_size.x=270
	list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(list_scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",6);list_scroll.add_child(list)
	_label(list,"HOUSES AND THEIR HEADS",15)
	for f:Dictionary in d.get("families",[]):
		var button:=Button.new();button.name="Select"+String(f.id);button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		var head:=GovernmentPeopleSystem.person_snapshot(int(f.head))
		button.text="%s%s\n%s · %s" % ["★ " if d.favored==f.id else "",String(f.name),String(Families.TRADES[f.id][0]),String(head.get("name","Vacant"))]
		button.custom_minimum_size=Vector2(270,60);button.clip_text=true
		button.tooltip_text=button.text;Tokens.apply_button_style(button,String(f.id)==id)
		var picked:=String(f.id);button.pressed.connect(func()->void:selected.emit(picked));list.add_child(button)
	var scroll:=ScrollContainer.new();scroll.name="FamilyDetailScroll";scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
	var details:=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",10);scroll.add_child(details)
	_label(details,Families.brief())
	var f:=Families.family(id)
	if f.is_empty():return
	var head:=GovernmentPeopleSystem.person_snapshot(int(f.head))
	_label(details,String(f.name),24)
	_label(details,"%s · %s\nFounded by %s · %d changes of head" % [String(head.get("name","Vacant")),String(Families.STAGES[int(f.stage)]),String(f.founder),int(f.successions)])
	_label(details,"Constituency: %d people currently assigned to %s. These are existing workers, not extra population or soldiers." % [int(GameState.population_allocations.get(id,0)),String(Families.TRADES[id][0]).to_lower()])
	_label(details,"Standing %.1f · loyalty %.0f%% · rival: %s" % [float(f.standing),float(f.loyalty)*100.0,String(Families.family(String(f.rival)).get("name","none"))])
	if int(f.stage)<5:
		_label(details,"Next: %s at %s people, then %.0f / %d months of organization. Favor and public office accelerate it." % [String(Families.STAGES[int(f.stage)+1]),String.num_int64(Families.THRESHOLDS[int(f.stage)]),float(f.months),int(Families.MATURITY[int(f.stage)])],13)
	if not String(f.party).is_empty():
		var party:Dictionary=d.parties.get(String(f.party),{})
		var leader:=GovernmentPeopleSystem.person_snapshot(int(party.get("head",0)))
		_label(details,"%s · %s\nLeader: %s · founding house: %s\nPlatform constituencies: %s" % [String(party.get("name","")),"Established party" if party.get("full",false) else "Organizing coalition",String(leader.get("name","")),String(party.get("founder","")),", ".join(party.get("members",[]))])
	var actions:=HFlowContainer.new();details.add_child(actions)
	_button(actions,"Favor this head","favor",id,"One head holds your patronage and has their program endorsed. Replacing them leaves a lasting rival.",String(d.favored)==id)
	_button(actions,"Endorse program","entrust",id,"Applies this program's efficiency bonuses and drawbacks without moving workers.",String(d.mandate)==id)
	var call_button:=Button.new();call_button.text="Speak to the head";Tokens.apply_button_style(call_button);actions.add_child(call_button)
	call_button.pressed.connect(func()->void:summon.emit(int(f.head)))
	var p:=Families.program(id)
	var shares:PackedStringArray=[]
	for role:String in p.weights:shares.append("%s %.0f%%" % [role,float(p.weights[role])*100.0])
	_label(details,"THEIR PROGRAM",16)
	_label(details,"Program priorities: "+", ".join(shares)+" of its bonus. Rival opposition can reduce the endorsed trade's bonus by 3 percentage points, or 6 once political factions form. Nobody is reassigned.")
	var character:Dictionary=f.character
	_label(details,"Wants to "+String(character.want)+". Fears "+String(character.fear)+".")
	_label(details,"“"+Families.Character.speech(character,int(GameState.elapsed_days)/30,float(GameState.simulation_metrics.get("food_intake_ratio",1))<.8)+"”",17)
	var cultural:PackedStringArray=[]
	for axis:String in character.values:
		var definition:=preload("res://scripts/societal_values_model.gd").value_definition(axis)
		cultural.append(String(definition.get("high",axis) if float(character.values[axis])>.5 else definition.get("low",axis)).to_lower())
	_label(details,"Argues for: "+", ".join(cultural)+". Official values shift first; public acceptance depends on results. Traditions outlast patronage.")
	var actual:PackedStringArray=[]
	for role:String in Families.bonuses():actual.append("%s %+.1f%%" % [String(Families.EFFECT_NAMES[role]),float(Families.bonuses()[role])*100.0])
	_label(details,"Current bonuses and drawbacks: "+(", ".join(actual) if not actual.is_empty() else "none"),13)
	_label(details,"Spending request: %s, about %.1f %s per day at today's employment; the existing purse pays only what it can afford." % [String(p.line),Purse.line_cost_per_day(String(p.line)),Purse.unit_word()])
	_button(details,"Fund "+String(p.line),"fund",id,"Enables this public spending line. Other funded services keep their existing settings.",Purse.line_on(String(p.line)))
	var quote:=Business.quote(String(p.stance))
	_label(details,"Trade proposal: %s. %s Changes use the existing business rules, including their trust cost and boom/bust risks." % [Business.stance_name(String(p.stance)),String(quote.get("words",""))])
	_button(details,"Adopt "+Business.stance_name(String(p.stance))+" trade rules","trade",id,"Changes the whole realm's business stance.",Business.stance()==String(p.stance))
	_button(details,"Withdraw patronage and endorsement","neutral","","Existing funding and trade rules remain until you change them.",String(d.favored).is_empty() and String(d.mandate).is_empty())
	if not d.culture.is_empty():
		var memory:PackedStringArray=[]
		for axis:String in d.culture:
			var definition:=preload("res://scripts/societal_values_model.gd").value_definition(axis)
			memory.append("%s %.1f%%" % [String(definition.get("name",axis)),float(d.culture[axis])*100.0])
		_label(details,"Inherited cultural tendencies (50% is neutral): "+", ".join(memory)+". These continue to influence values after patronage ends.",13)
	_label(details,"RECENT DECISIONS AND CONTESTS",16)
	var shown:=0
	for event:Dictionary in d.history:
		_label(details,"Day %d · %s" % [int(event.day),String(event.text)],13)
		shown+=1
		if shown>=8:break
