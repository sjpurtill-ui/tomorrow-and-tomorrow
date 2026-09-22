extends VBoxContainer
## Compact government cards. Vacancies have no invented person or actions.

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
	_add_gauge(row,"LEGITIMACY",legitimacy,Tokens.GOLD,"Public acceptance of the government")
	_add_gauge(row,"COUNCIL SUPPORT",support,Tokens.TEAL,"Support for the current government")

func _add_gauge(parent:HBoxContainer,label_text:String,value:float,color:Color,tip:String)->void:
	var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.tooltip_text=tip;box.add_theme_constant_override("separation",6);parent.add_child(box)
	var heading:=HBoxContainer.new();heading.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_child(heading)
	var label:=Tokens.make_label(label_text,9,Tokens.MUTED,0.06);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;heading.add_child(label)
	heading.add_child(Tokens.make_label("%d%%" % roundi(value*100.0),18,color))
	var track:=ColorRect.new();track.color=Tokens.TRACK;track.custom_minimum_size=Vector2(0,3);box.add_child(track)
	var fill:=ColorRect.new();fill.color=color;fill.anchor_right=clampf(value,0,1);fill.anchor_bottom=1.0;track.add_child(fill)

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
	identity.add_child(Tokens.make_label(String(item.get("office_title","OFFICE")).to_upper(),9,Tokens.MUTED if vacant else accent,0.08))
	var name_label:=Tokens.make_label("Vacant" if vacant else String(item.get("name","Unknown")),17,Tokens.TEXT_DIM if vacant else Tokens.INK);name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;identity.add_child(name_label)
	if vacant:
		identity.add_child(Tokens.make_label("Awaiting a successor",10,Tokens.MUTED))
		return
	var traits:Array=item.get("traits",[])
	if not traits.is_empty():
		var trait_text:=PackedStringArray()
		for index in mini(2,traits.size()): trait_text.append(String(traits[index]).capitalize())
		var trait_label:=Tokens.make_label(" · ".join(trait_text),10,Tokens.TEXT_SOFT);trait_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;identity.add_child(trait_label)
	var skills:Array=item.get("skills",[])
	if not skills.is_empty():
		var skill_row:=HBoxContainer.new();skill_row.add_theme_constant_override("separation",7);identity.add_child(skill_row)
		for skill_variant in skills:
			var skill:Dictionary=skill_variant
			var track:=ColorRect.new();track.color=Tokens.TRACK;track.custom_minimum_size=Vector2(0,3);track.size_flags_horizontal=Control.SIZE_EXPAND_FILL;track.tooltip_text="%s · %d / 100" % [String(skill.get("name","")).capitalize(),int(skill.get("value",0))];track.mouse_filter=Control.MOUSE_FILTER_STOP;skill_row.add_child(track)
			var fill:=ColorRect.new();fill.color=skill.get("color",accent);fill.anchor_right=clampf(float(skill.get("value",0))/100.0,0,1);fill.anchor_bottom=1.0;fill.mouse_filter=Control.MOUSE_FILTER_IGNORE;track.add_child(fill)
	var controls:=VBoxContainer.new();controls.alignment=BoxContainer.ALIGNMENT_CENTER;controls.add_theme_constant_override("separation",5);row.add_child(controls)
	var fit:=Glyph.new();fit.name="OfficeFit";fit.setup("fit",Tokens.capacity_color(float(item.get("fit",0))*100.0),1,float(item.get("fit",0)));fit.custom_minimum_size=Vector2(44,44);fit.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;fit.tooltip_text="%d%% fit for office" % roundi(float(item.get("fit",0))*100.0);fit.mouse_filter=Control.MOUSE_FILTER_STOP;controls.add_child(fit)
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",5);controls.add_child(actions)
	_add_action(actions,"dismiss",Tokens.TEXT_DIM,String(item.get("dismiss_tip","Dismiss")),item.get("on_dismiss",Callable()))
	_add_action(actions,"execute",Tokens.RED,String(item.get("execute_tip","Execute")),item.get("on_execute",Callable()))

func _add_action(parent:HBoxContainer,kind:String,color:Color,tip:String,callback:Variant)->void:
	var button:=Button.new();button.name="Cabinet"+kind.capitalize();button.custom_minimum_size=Vector2(30,30);button.tooltip_text=tip
	button.add_theme_stylebox_override("normal",Tokens.flat(Color.TRANSPARENT,Tokens.BORDER_SOFT,1,5));button.add_theme_stylebox_override("hover",Tokens.flat(Tokens.HOVER_BG,color,1,5));button.add_theme_stylebox_override("focus",Tokens.flat(Color.TRANSPARENT,color,2,5));parent.add_child(button)
	var glyph:=Glyph.new();glyph.setup(kind,color);glyph.custom_minimum_size=Vector2.ZERO;glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);button.add_child(glyph)
	button.disabled=not callback is Callable or not (callback as Callable).is_valid()
	if not button.disabled: button.pressed.connect(callback as Callable)
