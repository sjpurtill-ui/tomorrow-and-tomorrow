extends "res://scripts/hud/settlement_overview.gd"
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
var values_grid:GridContainer
var memory_grid:GridContainer
func setup(block:Dictionary)->void:
	data=block;name="CulturePanel";add_theme_constant_override("separation",18)
	var opening:=HBoxContainer.new();opening.add_theme_constant_override("separation",22);add_child(opening)
	var image:=TextureRect.new();image.texture=Visuals.art("culture");image.custom_minimum_size=Vector2(230,190);image.size_flags_horizontal=Control.SIZE_EXPAND_FILL;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;opening.add_child(image)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.size_flags_stretch_ratio=1.15;identity.add_theme_constant_override("separation",9);opening.add_child(identity)
	identity.add_child(T.make_label("THE SOCIETY WE ARE BECOMING",11,T.GOLD))
	identity.add_child(_serif(String(data.identity.name).capitalize(),28))
	_note(identity,String(data.identity.summary))
	_note(identity,"Values grow from everyday life and the choices remembered across generations.")
	_rule(self)
	var direction:=HBoxContainer.new();direction.add_theme_constant_override("separation",18);add_child(direction)
	var purpose:=VBoxContainer.new();purpose.size_flags_horizontal=Control.SIZE_EXPAND_FILL;direction.add_child(purpose)
	purpose.add_child(T.make_label("THIS GENERATION’S DIRECTION",11,T.GOLD));purpose.add_child(_serif(String(data.direction.get("name","A direction still to be chosen")),23))
	_note(purpose,String(data.direction.get("vision","Choose the purpose this generation will pursue.")))
	_button(direction,"Review direction",data.on_direction,"Review your chosen ambition and its consequences")
	(direction.get_child(direction.get_child_count()-1) as Control).size_flags_vertical=Control.SIZE_SHRINK_CENTER
	_rule(self)
	add_child(T.make_label("VALUES IN EVERYDAY LIFE",11,T.GOLD))
	values_grid=GridContainer.new();values_grid.columns=3;values_grid.add_theme_constant_override("h_separation",18);values_grid.add_theme_constant_override("v_separation",18);add_child(values_grid)
	for value:Dictionary in data.values:
		var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",7);values_grid.add_child(card)
		var art:=TextureRect.new();art.texture=Visuals.art(String(value.art));art.custom_minimum_size.y=112;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;card.add_child(art)
		card.add_child(_serif(String(value.label).capitalize(),20));_note(card,String(value.meaning))
		var spectrum:=ProgressBar.new();spectrum.name="ValueSpectrum";spectrum.show_percentage=false;spectrum.custom_minimum_size.y=5;spectrum.value=float(value.value)*100;card.add_child(spectrum)
		spectrum.add_theme_stylebox_override("background",T.flat(T.TRACK));spectrum.add_theme_stylebox_override("fill",T.flat(T.GREEN))
		_note(card,String(value.low).capitalize()+"  ↔  "+String(value.high).capitalize())
	_rule(self)
	add_child(T.make_label("HOW CULTURE SHAPES PLAY",11,T.GOLD))
	memory_grid=GridContainer.new();memory_grid.columns=3;memory_grid.add_theme_constant_override("h_separation",22);memory_grid.add_theme_constant_override("v_separation",18);add_child(memory_grid)
	for effect:Dictionary in data.get("effects",[]):
		_effect_card(memory_grid,effect)
	_rule(self)
	add_child(T.make_label("REPUTATION FROM OUR CONDUCT",11,T.GOLD))
	_note(self,"Built by treatment of prisoners and conquered people. Different neighbors also remember their own dealings with us.")
	var reputation_grid:=GridContainer.new();reputation_grid.name="ReputationGrid";reputation_grid.columns=3;reputation_grid.add_theme_constant_override("h_separation",22);reputation_grid.add_theme_constant_override("v_separation",18);add_child(reputation_grid)
	for reputation:Dictionary in data.get("reputation",[]):
		var card:=_effect_card(reputation_grid,reputation)
		card.tooltip_text=String(reputation.tip)
		var meter:=ProgressBar.new();meter.show_percentage=false;meter.custom_minimum_size.y=6;meter.value=float(reputation.value)*100;card.add_child(meter)
		meter.add_theme_stylebox_override("background",T.flat(T.TRACK));meter.add_theme_stylebox_override("fill",T.flat(T.GOLD))
	var roots:=VBoxContainer.new();roots.visible=false
	var toggle:=Button.new();toggle.text="Cultural roots ▸";add_child(toggle);add_child(roots)
	toggle.pressed.connect(func():roots.visible=not roots.visible;toggle.text="Cultural roots ▾" if roots.visible else "Cultural roots ▸")
	for memory:Dictionary in data.memories:
		_note(roots,String(memory.domain).capitalize()+" · "+String(memory.current))
		if String(memory.inherited)!=String(memory.current):_note(roots,"Inherited: "+String(memory.inherited))
	if data.memories.is_empty():_note(roots,"No lasting traditions recorded yet.")
	_rule(self)
	var actions:=HFlowContainer.new();actions.add_theme_constant_override("h_separation",10);add_child(actions)
	_button(actions,"Speak with our leader",data.on_council,"Open the council conversation")
	_button(actions,"Society’s strengths & needs",data.on_capacities,"See all twelve capacities")
	_button(actions,"People in government",data.on_government,"Review officeholders and policies")
	resized.connect(_culture_layout);_culture_layout()
func _culture_layout()->void:
	var columns:=3 if size.x>=650 else 2 if size.x>=450 else 1
	if values_grid:values_grid.columns=columns
	if memory_grid:memory_grid.columns=columns

	var reputation_grid:=get_node_or_null("ReputationGrid") as GridContainer
	if reputation_grid:reputation_grid.columns=columns

func _effect_card(parent:Control,item:Dictionary)->VBoxContainer:
	var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",8);parent.add_child(card)
	card.add_child(T.make_label(String(item.label).to_upper(),11,T.GOLD))
	card.add_child(_serif(String(item.title),19))
	_note(card,String(item.detail))
	return card
