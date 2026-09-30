extends "res://scripts/hud/settlement_overview.gd"
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
var values_grid:GridContainer
var memory_grid:GridContainer
var roots_grid:GridContainer
## The daily refresh (update_block) keeps every node while the page keeps its
## shape and writes the day's values, words and meters into them; the
## artifacts showcase is drawn again only when what it shows changed.
var _culture_shape:Array=[]
var _culture:Dictionary={}
func setup(block:Dictionary)->void:
	data=block;name="CulturePanel";add_theme_constant_override("separation",18)
	_culture_shape=culture_shape(block)
	_culture={"values":[],"effects":[],"reputation":[],"roots":[]}
	var opening:=HBoxContainer.new();opening.add_theme_constant_override("separation",22);add_child(opening)
	var image:=TextureRect.new();image.texture=Visuals.art("culture");image.custom_minimum_size=Vector2(230,190);image.size_flags_horizontal=Control.SIZE_EXPAND_FILL;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;opening.add_child(image)
	if Portrait.Early.active():
		image.texture=Portrait.Early.civic_scene(data.get("lived_values",{}))
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.tooltip_text="A picture of how the people live now."
	_culture.image=image
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.size_flags_stretch_ratio=1.15;identity.add_theme_constant_override("separation",9);opening.add_child(identity)
	identity.add_child(T.make_label("THE SOCIETY WE ARE BECOMING",12,T.GOLD_TEXT))
	_culture.identity=_serif(String(data.identity.name).capitalize(),28);identity.add_child(_culture.identity)
	_culture.summary=_line(identity,String(data.identity.summary),13,T.BODY)
	_note(identity,"Values grow from everyday life and the choices remembered across generations.")
	_rule(self)
	var direction:=HBoxContainer.new();direction.add_theme_constant_override("separation",18);add_child(direction)
	var purpose:=VBoxContainer.new();purpose.size_flags_horizontal=Control.SIZE_EXPAND_FILL;direction.add_child(purpose)
	purpose.add_child(T.make_label("THIS GENERATION’S DIRECTION",12,T.GOLD_TEXT))
	_culture.direction=_serif(String(data.direction.get("name","A direction still to be chosen")),23);purpose.add_child(_culture.direction)
	_culture.vision=_line(purpose,String(data.direction.get("vision","Choose the purpose this generation will pursue.")),13,T.BODY)
	_button(direction,"Review direction",data.on_direction,"Review your chosen ambition and its consequences")
	(direction.get_child(direction.get_child_count()-1) as Control).size_flags_vertical=Control.SIZE_SHRINK_CENTER
	_rule(self)
	if data.has("artifacts"):
		_culture.showcase=preload("res://scripts/hud/artifact_gallery.gd").showcase(data.artifacts);add_child(_culture.showcase)
		_culture.showcase_print=_showcase_print(data)
		_rule(self)
	add_child(T.make_label("VALUES IN EVERYDAY LIFE",12,T.GOLD_TEXT))
	values_grid=GridContainer.new();values_grid.columns=3;values_grid.add_theme_constant_override("h_separation",18);values_grid.add_theme_constant_override("v_separation",18);add_child(values_grid)
	for value:Dictionary in data.values:
		var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",7);values_grid.add_child(card)
		var art:=TextureRect.new();art.texture=Visuals.art(String(value.art));art.custom_minimum_size.y=112;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;card.add_child(art)
		card.add_child(_serif(String(value.label).capitalize(),20));_note(card,String(value.meaning))
		var spectrum:=ProgressBar.new();spectrum.name="ValueSpectrum";spectrum.show_percentage=false;spectrum.custom_minimum_size.y=5;spectrum.value=float(value.value)*100;card.add_child(spectrum)
		spectrum.add_theme_stylebox_override("background",T.flat(T.TRACK));spectrum.add_theme_stylebox_override("fill",T.flat(T.GREEN))
		var leaning:=_line(card,_leaning(float(value.value),String(value.low),String(value.high)),13,T.BODY)
		(_culture.values as Array).append({"spectrum":spectrum,"leaning":leaning})
	_rule(self)
	add_child(T.make_label("WHAT OUR WAYS CHANGE",12,T.GOLD_TEXT))
	memory_grid=GridContainer.new();memory_grid.columns=3;memory_grid.add_theme_constant_override("h_separation",22);memory_grid.add_theme_constant_override("v_separation",18);add_child(memory_grid)
	for effect:Dictionary in data.get("effects",[]):
		_effect_card(memory_grid,effect)
		(_culture.effects as Array).append(_card_refs)
	_rule(self)
	add_child(T.make_label("REPUTATION FROM OUR CONDUCT",12,T.GOLD_TEXT))
	_note(self,"Built by treatment of prisoners and conquered people. Different neighbors also remember their own dealings with us.")
	var reputation_grid:=GridContainer.new();reputation_grid.name="ReputationGrid";reputation_grid.columns=3;reputation_grid.add_theme_constant_override("h_separation",22);reputation_grid.add_theme_constant_override("v_separation",18);add_child(reputation_grid)
	for reputation:Dictionary in data.get("reputation",[]):
		var card:=_effect_card(reputation_grid,reputation)
		var refs:=_card_refs
		card.tooltip_text=String(reputation.tip)
		var meter:=ProgressBar.new();meter.show_percentage=false;meter.custom_minimum_size.y=6;meter.value=float(reputation.value)*100;card.add_child(meter)
		meter.add_theme_stylebox_override("background",T.flat(T.TRACK));meter.add_theme_stylebox_override("fill",T.flat(T.GOLD))
		refs["card"]=card;refs["meter"]=meter
		(_culture.reputation as Array).append(refs)
	# The provider owns view state so daily body rebuilds preserve the disclosure.
	var view_state:Dictionary=data.get("view_state",{})
	var roots:=VBoxContainer.new();roots.name="CulturalRoots";roots.visible=bool(view_state.get("roots_open",false));roots.add_theme_constant_override("separation",12)
	var toggle:=Button.new();toggle.name="CulturalRootsToggle";toggle.text="Hide our cultural roots" if roots.visible else "Show our cultural roots"
	toggle.alignment=HORIZONTAL_ALIGNMENT_LEFT
	toggle.add_theme_color_override("font_color",T.INK)
	toggle.add_theme_color_override("font_hover_color",T.INK)
	toggle.add_theme_color_override("font_pressed_color",T.INK)
	toggle.add_theme_stylebox_override("normal",T.flat(T.TRACK))
	toggle.add_theme_stylebox_override("hover",T.flat(T.TRACK))
	toggle.add_theme_stylebox_override("pressed",T.flat(T.TRACK))
	add_child(toggle);add_child(roots)
	toggle.pressed.connect(func():
		roots.visible=not roots.visible
		view_state["roots_open"]=roots.visible
		toggle.text="Hide our cultural roots" if roots.visible else "Show our cultural roots")
	roots_grid=GridContainer.new();roots_grid.columns=3;roots_grid.add_theme_constant_override("h_separation",22);roots_grid.add_theme_constant_override("v_separation",18);roots.add_child(roots_grid)
	for memory:Dictionary in data.memories:
		var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",6);roots_grid.add_child(card)
		card.add_child(T.make_label(Visuals.name_for(String(memory.domain)).to_upper(),12,T.GOLD_TEXT))
		var current:=_serif(String(memory.current),19);card.add_child(current)
		var refs:={"current":current,"inherited":null}
		if String(memory.inherited)!=String(memory.current):refs.inherited=_line(card,"Our forebears leaned to "+String(memory.inherited).to_lower()+".",13,T.BODY)
		(_culture.roots as Array).append(refs)
	if data.memories.is_empty():_note(roots,"No lasting traditions recorded yet.")
	_rule(self)
	var actions:=HFlowContainer.new();actions.add_theme_constant_override("h_separation",10);add_child(actions)
	_button(actions,"Talk with our leader in court",data.on_council,"Call the local leader to the court")
	_button(actions,"What we are good and poor at",data.on_capacities,"Twelve things a people needs, weakest first")
	_button(actions,"Government",data.on_government,"Officials and standing orders")
	resized.connect(_culture_layout);_culture_layout()
func _culture_layout()->void:
	var columns:=3 if size.x>=650 else 2 if size.x>=450 else 1
	if values_grid:values_grid.columns=columns
	if memory_grid:memory_grid.columns=columns
	if roots_grid:roots_grid.columns=columns

	var reputation_grid:=get_node_or_null("ReputationGrid") as GridContainer
	if reputation_grid:reputation_grid.columns=columns

## The labels of the card _effect_card made last, for the live refresh.
var _card_refs:Dictionary={}
func _effect_card(parent:Control,item:Dictionary)->VBoxContainer:
	var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",8);parent.add_child(card)
	var kicker:=T.make_label(String(item.label).to_upper(),12,T.GOLD_TEXT);card.add_child(kicker)
	var title:=_serif(String(item.title),19);card.add_child(title)
	var detail:=_line(card,String(item.detail),13,T.BODY)
	_card_refs={"label":kicker,"title":title,"detail":detail}
	return card

## The live refresh: while the page keeps its shape, every value, word and
## meter takes the day's figure in place; the artifacts showcase is drawn
## again only when its figures or pieces changed. Another shape is drawn
## afresh.
func update_block(block:Dictionary)->bool:
	if _culture.is_empty() or culture_shape(block)!=_culture_shape:return false
	data=block
	if Portrait.Early.active():(_culture.image as TextureRect).texture=Portrait.Early.civic_scene(data.get("lived_values",{}))
	_put(_culture.identity,String(data.identity.name).capitalize())
	_put(_culture.summary,String(data.identity.summary))
	_put(_culture.direction,String(data.direction.get("name","A direction still to be chosen")))
	_put(_culture.vision,String(data.direction.get("vision","Choose the purpose this generation will pursue.")))
	if _culture.has("showcase") and _showcase_print(data)!=_culture.showcase_print:
		var stale:Control=_culture.showcase
		var at:=stale.get_index()
		remove_child(stale);stale.queue_free()
		_culture.showcase=preload("res://scripts/hud/artifact_gallery.gd").showcase(data.artifacts);add_child(_culture.showcase);move_child(_culture.showcase,at)
		_culture.showcase_print=_showcase_print(data)
	for index in (data.values as Array).size():
		var value:Dictionary=data.values[index];var refs:Dictionary=_culture.values[index]
		(refs.spectrum as ProgressBar).value=float(value.value)*100
		_put(refs.leaning,_leaning(float(value.value),String(value.low),String(value.high)))
	var effects:Array=data.get("effects",[])
	for index in effects.size():_fill_card(_culture.effects[index],effects[index])
	var reputation:Array=data.get("reputation",[])
	for index in reputation.size():
		var refs:Dictionary=_culture.reputation[index]
		_fill_card(refs,reputation[index])
		(refs.card as Control).tooltip_text=String(reputation[index].tip)
		(refs.meter as ProgressBar).value=float(reputation[index].value)*100
	for index in (data.memories as Array).size():
		var memory:Dictionary=data.memories[index];var refs:Dictionary=_culture.roots[index]
		_put(refs.current,String(memory.current))
		if refs.inherited!=null:_put(refs.inherited,"Our forebears leaned to "+String(memory.inherited).to_lower()+".")
	return true

func _fill_card(refs:Dictionary,item:Dictionary)->void:
	_put(refs.label,String(item.label).to_upper())
	_put(refs.title,String(item.title))
	_put(refs.detail,String(item.detail))

## What the page's nodes are: the values shown (their pictures, names and
## meanings), how many effects and reputations, the roots (and which name an
## older leaning), whether artifacts are shown, and the actions offered.
static func culture_shape(block:Dictionary)->Array:
	var values:Array=[]
	for value:Dictionary in block.get("values",[]):values.append([String(value.get("art","")),String(value.get("label","")),String(value.get("meaning",""))])
	var roots:Array=[]
	for memory:Dictionary in block.get("memories",[]):roots.append([String(memory.get("domain","")),String(memory.get("inherited",""))!=String(memory.get("current",""))])
	return [Portrait.Early.active(),values,(block.get("effects",[]) as Array).size(),(block.get("reputation",[]) as Array).size(),roots,(block.get("memories",[]) as Array).is_empty(),block.has("artifacts"),
		callable_key(block.get("on_direction")),callable_key(block.get("on_council")),callable_key(block.get("on_capacities")),callable_key(block.get("on_government"))]

## What the artifacts showcase is drawn from (its figures and finest pieces).
static func _showcase_print(block:Dictionary)->Array:
	var artifacts:Dictionary=block.get("artifacts",{})
	return [artifacts.get("summary",{}),artifacts.get("highlights",[])]

static func _leaning(value:float,low:String,high:String)->String:
	var toward:=high if value>=0.5 else low
	var strength:=absf(value-0.5)
	if strength<0.08:return "Balanced between %s and %s." % [low.to_lower(),high.to_lower()]
	return "%s toward %s." % ["Leans strongly" if strength>=0.3 else "Leans",toward.to_lower()]
