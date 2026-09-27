extends VBoxContainer
## Compact government cards. Vacancies have no invented person or actions.
## Each official shows, in words, how well they suit the office and what they
## are best at; the one action is to summon them to the court, where dismissal
## and punishment are spoken orders with their consequences shown.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Glyph:=preload("res://scripts/hud/government_glyph.gd")

func setup(block:Dictionary)->void:
	name="GovernmentCabinet"
	add_theme_constant_override("separation",12)
	_add_authority(float(block.get("legitimacy",0.0)),float(block.get("support",0.0)))
	for item_variant in block.get("items",[]) as Array:
		_add_office(item_variant as Dictionary)

func _add_authority(legitimacy:float,support:float)->void:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);add_child(row)
	_add_gauge(row,"The people accept our rule",legitimacy,Tokens.GOLD,"It falls when people go hungry, sick or unheard, and rises when they are fed, safe and listened to.")
	_add_gauge(row,"Our officials back us",support,Tokens.TEAL,"It rises when you heed and reward your officials, and falls when you ignore, shame or punish them.")

func _add_gauge(parent:HBoxContainer,label_text:String,value:float,color:Color,tip:String)->void:
	var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.tooltip_text=tip;box.add_theme_constant_override("separation",6);parent.add_child(box)
	var heading:=HBoxContainer.new();heading.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_child(heading)
	var label:=Tokens.make_label(label_text,13,Tokens.BODY);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;heading.add_child(label)
	heading.add_child(Tokens.make_label(_share_words(value),16,Tokens.text_for(color)))
	var track:=ColorRect.new();track.color=Tokens.TRACK;track.custom_minimum_size=Vector2(0,4);box.add_child(track)
	var fill:=ColorRect.new();fill.color=color;fill.anchor_right=clampf(value,0,1);fill.anchor_bottom=1.0;track.add_child(fill)
	var why:=Tokens.make_label(tip,12,Tokens.MUTED);why.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(why)

static func _share_words(value:float)->String:
	var words:="nearly all" if value>=0.85 else "most" if value>=0.6 else "about half" if value>=0.4 else "few" if value>=0.15 else "almost none"
	return "%s (%d in 100)" % [words.capitalize(),roundi(value*100.0)]

func _add_office(item:Dictionary)->void:
	var vacant:=bool(item.get("vacant",false))
	var accent:Color=item.get("accent",Tokens.GOLD)
	var card:=PanelContainer.new();card.name="OfficeCard";card.tooltip_text=String(item.get("tip",""))
	var style:=Tokens.flat(Tokens.ROW_BG,Tokens.BORDER_SOFT,1,6,12)
	card.add_theme_stylebox_override("panel",style);add_child(card)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row)
	var medallion:=Control.new();medallion.custom_minimum_size=Vector2(64,64);medallion.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(medallion)
	if not vacant and preload("res://scripts/hud/early_civ_art.gd").active():medallion.custom_minimum_size=Vector2(100,100)
	if vacant:
		var empty:=Glyph.new();empty.name="EmptySeat";empty.setup("vacant",Tokens.MUTED);empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);medallion.add_child(empty)
	else:
		var portrait:=preload("res://scripts/hud/person_portrait.gd").picture(item,0,0)
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);medallion.add_child(portrait)
	if not vacant:
		var seal:=Glyph.new();seal.name="OfficeSeal";seal.setup(String(item.get("office_key","office")),accent);seal.custom_minimum_size=Vector2.ZERO;seal.position=medallion.custom_minimum_size-Vector2(21,21);seal.size=Vector2(26,26)
		var seal_back:=Panel.new();seal_back.position=seal.position;seal_back.size=seal.size;seal_back.add_theme_stylebox_override("panel",Tokens.flat(Tokens.ROW_BG,Color.TRANSPARENT,0,13));seal_back.mouse_filter=Control.MOUSE_FILTER_IGNORE;medallion.add_child(seal_back);medallion.add_child(seal)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.alignment=BoxContainer.ALIGNMENT_CENTER;identity.add_theme_constant_override("separation",5);row.add_child(identity)
	identity.add_child(Tokens.make_label(String(item.get("office_title","OFFICE")).to_upper(),12,Tokens.MUTED if vacant else Tokens.text_for(accent),0.08))
	var name_label:=Tokens.make_label("Vacant" if vacant else String(item.get("name","Unknown")),17,Tokens.TEXT_DIM if vacant else Tokens.INK);name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;identity.add_child(name_label)
	if vacant:
		identity.add_child(Tokens.make_label("Empty. The government will appoint someone when a fit person is found.",13,Tokens.MUTED))
		return
	var traits:Array=item.get("traits",[])
	if not traits.is_empty():
		var trait_text:=PackedStringArray()
		for index in mini(2,traits.size()): trait_text.append(String(traits[index]).capitalize())
		var trait_label:=Tokens.make_label(" · ".join(trait_text),13,Tokens.TEXT_SOFT);trait_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;identity.add_child(trait_label)
	var fit_label:=Tokens.make_label(String(item.get("fit_words",preload("res://scripts/hud/home_plain.gd").fit_words(float(item.get("fit",0))))),13,Tokens.BODY);fit_label.name="OfficeFit";identity.add_child(fit_label)
	var skills:Array=item.get("skills",[])
	if not skills.is_empty():
		var parts:PackedStringArray=[]
		for skill_variant in skills:
			var skill:Dictionary=skill_variant
			parts.append("%s (%s)" % [String(skill.get("name","")).to_lower(),String(skill.get("words",preload("res://scripts/hud/home_plain.gd").skill_words(float(skill.get("value",0)))))])
		var skill_label:=Tokens.make_label("Best at: "+", ".join(parts),13,Tokens.TEXT_SOFT);skill_label.name="OfficeSkills";skill_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;identity.add_child(skill_label)
	var summon:=Button.new();summon.name="CabinetSummon";summon.text="Summon to court";summon.tooltip_text=String(item.get("summon_tip","Call them to the court"))
	summon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;summon.custom_minimum_size=Vector2(0,32)
	summon.add_theme_stylebox_override("normal",Tokens.flat(Color.TRANSPARENT,Tokens.BORDER_SOFT,1,2,10));summon.add_theme_stylebox_override("hover",Tokens.flat(Tokens.HOVER_BG,Tokens.GOLD,1,2,10))
	summon.add_theme_font_size_override("font_size",13);summon.add_theme_color_override("font_color",Tokens.BODY);summon.add_theme_color_override("font_hover_color",Tokens.INK);summon.add_theme_color_override("font_disabled_color",Tokens.MUTED);row.add_child(summon)
	var callback:Variant=item.get("on_summon",Callable())
	summon.disabled=not callback is Callable or not (callback as Callable).is_valid()
	if not summon.disabled:summon.pressed.connect(callback as Callable)
