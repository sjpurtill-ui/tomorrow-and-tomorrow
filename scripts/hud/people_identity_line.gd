extends RefCounted
## A people's tongue and look, small and plain, on its card (the Standing
## page and the Known World): the tongue's name with two of its names and two
## of its towns, and chips of their skin from light to deep, their hair and
## the dyes of their cloth, with the words for it on the pointer
## (people_language.gd, people_appearance.gd). Static; preload.

const Kit:=preload("res://scripts/hud/paper_kit.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Lang:=preload("res://scripts/people_language.gd")
const Looks:=preload("res://scripts/people_appearance.gd")
const EraNames:=preload("res://scripts/era_names.gd")

## The line for a people (owner: "player" or a people's id), added to parent.
static func build(parent:Node,owner:String)->VBoxContainer:
	var box:=VBoxContainer.new()
	box.name="Tongue"
	box.add_theme_constant_override("separation",3)
	box.mouse_filter=Control.MOUSE_FILTER_PASS
	if parent!=null:parent.add_child(box)
	# Names as that people give them now (bynames before writing).
	var line:=Kit.label(box,Lang.card_line(owner,Lang.NO_SEED,EraNames.stage(owner)),"note")
	line.name="TongueLine"
	var look:=Looks.profile(owner)
	var chips:=HBoxContainer.new()
	chips.name="Look"
	chips.add_theme_constant_override("separation",3)
	chips.mouse_filter=Control.MOUSE_FILTER_PASS
	chips.tooltip_text=String(look.words)+"."
	box.add_child(chips)
	for group:Array in [look.skin,look.hair,look.cloth]:
		if chips.get_child_count()>0:
			var gap:=Control.new();gap.custom_minimum_size=Vector2(6,0);gap.mouse_filter=Control.MOUSE_FILTER_IGNORE;chips.add_child(gap)
		for colour in group:chips.add_child(_chip(Color(String(colour))))
	var words:=Kit.label(chips,String(look.skin_words)+" skin","note",Color(0,0,0,0),false)
	words.name="LookWords"
	words.mouse_filter=Control.MOUSE_FILTER_PASS
	return box

static func _chip(colour:Color)->Control:
	var chip:=Panel.new()
	chip.custom_minimum_size=Vector2(12,12)
	chip.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	chip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxFlat.new()
	style.bg_color=colour
	style.set_corner_radius_all(6)
	style.border_color=T.RULE
	style.set_border_width_all(1)
	chip.add_theme_stylebox_override("panel",style)
	return chip
