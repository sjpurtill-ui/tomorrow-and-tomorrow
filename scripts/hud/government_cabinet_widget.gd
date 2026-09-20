extends VBoxContainer
## Visual cabinet: authority gauges, office seals, abstract portraits, ability
## bars, and icon-only removal controls.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Glyph:=preload("res://scripts/hud/government_glyph.gd")

func setup(block:Dictionary)->void:
	name="GovernmentCabinet"
	add_theme_constant_override("separation",10)
	_add_authority(float(block.get("legitimacy",0.0)),float(block.get("support",0.0)))
	for item_variant in block.get("items",[]) as Array:
		_add_office(item_variant as Dictionary)

func _add_authority(legitimacy:float,support:float)->void:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);add_child(row)
	_add_gauge(row,"LEGITIMACY",legitimacy,Tokens.GOLD,"Public acceptance of the government")
	_add_gauge(row,"COUNCIL",support,Tokens.TEAL,"Support for the current government")
	var auto:=PanelContainer.new();auto.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	auto.add_theme_stylebox_override("panel",Tokens.tile_style(Tokens.GREEN));auto.tooltip_text="Vacancies are filled automatically from living public figures."
	row.add_child(auto)
	var auto_box:=VBoxContainer.new();auto_box.alignment=BoxContainer.ALIGNMENT_CENTER;auto.add_child(auto_box)
	var mark:=Tokens.make_label("↻",25,Tokens.GREEN);mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;auto_box.add_child(mark)
	var label:=Tokens.make_label("SUCCESSION",8,Tokens.MUTED,0.08);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;auto_box.add_child(label)

func _add_gauge(parent:HBoxContainer,label_text:String,value:float,color:Color,tip:String)->void:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.tooltip_text=tip
	panel.add_theme_stylebox_override("panel",Tokens.tile_style(color));parent.add_child(panel)
	var box:=VBoxContainer.new();box.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_theme_constant_override("separation",1);panel.add_child(box)
	var value_label:=Tokens.make_label("%d" % roundi(value*100.0),21,color);value_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(value_label)
	var track:=ColorRect.new();track.color=Tokens.TRACK;track.custom_minimum_size=Vector2(0,4);box.add_child(track)
	var fill:=ColorRect.new();fill.color=color;fill.anchor_right=clampf(value,0,1);fill.anchor_bottom=1.0;track.add_child(fill)
	var label:=Tokens.make_label(label_text,8,Tokens.MUTED,0.08);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(label)

func _add_office(item:Dictionary)->void:
	var accent:Color=item.get("accent",Tokens.GOLD)
	var card:=PanelContainer.new();card.name="OfficeCard";card.tooltip_text=String(item.get("tip",""))
	var style:=Tokens.flat(Tokens.ROW_BG,accent,1,6);style.border_width_left=4;style.content_margin_left=12;style.content_margin_right=10;style.content_margin_top=10;style.content_margin_bottom=10
	card.add_theme_stylebox_override("panel",style);add_child(card)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",11);card.add_child(row)
	var seal:=Glyph.new();seal.setup(String(item.get("office_key","office")),accent);seal.custom_minimum_size=Vector2(44,64);seal.tooltip_text=String(item.get("office_title","Office"));row.add_child(seal)
	var portrait:=Glyph.new();portrait.setup("portrait",accent,int(item.get("person_id",1)));portrait.custom_minimum_size=Vector2(58,64);row.add_child(portrait)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.add_theme_constant_override("separation",3);row.add_child(identity)
	identity.add_child(Tokens.make_label(String(item.get("office_title","OFFICE")).to_upper(),9,accent,0.1))
	var name_label:=Tokens.make_label(String(item.get("name","Vacant")),16,Tokens.INK);name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;identity.add_child(name_label)
	var traits:Array=item.get("traits",[])
	if not traits.is_empty():
		var trait_row:=HBoxContainer.new();trait_row.add_theme_constant_override("separation",5);identity.add_child(trait_row)
		for index in mini(2,traits.size()):
			var pill:=Label.new();pill.text=String(traits[index]).to_upper();Tokens.style_label(pill,8,Tokens.TEXT_SOFT,0.04);pill.add_theme_stylebox_override("normal",Tokens.flat(Tokens.ACTIVE_BG,Color.TRANSPARENT,0,8,5));trait_row.add_child(pill)
	for skill_variant in item.get("skills",[]) as Array:
		var skill:Dictionary=skill_variant
		var skill_row:=HBoxContainer.new();skill_row.add_theme_constant_override("separation",5);skill_row.tooltip_text=String(skill.get("name",""));identity.add_child(skill_row)
		var short:=Tokens.make_label(String(skill.get("short","")),8,Tokens.MUTED);short.custom_minimum_size=Vector2(25,0);skill_row.add_child(short)
		var track:=ColorRect.new();track.color=Tokens.TRACK;track.custom_minimum_size=Vector2(0,4);track.size_flags_horizontal=Control.SIZE_EXPAND_FILL;track.size_flags_vertical=Control.SIZE_SHRINK_CENTER;skill_row.add_child(track)
		var fill:=ColorRect.new();fill.color=skill.get("color",accent);fill.anchor_right=clampf(float(skill.get("value",0))/100.0,0,1);fill.anchor_bottom=1.0;track.add_child(fill)
	var controls:=VBoxContainer.new();controls.alignment=BoxContainer.ALIGNMENT_CENTER;controls.add_theme_constant_override("separation",4);row.add_child(controls)
	var fit:=Glyph.new();fit.setup("fit",Tokens.capacity_color(float(item.get("fit",0))*100.0),1,float(item.get("fit",0)));fit.custom_minimum_size=Vector2(44,44);fit.tooltip_text="%d%% fit for office" % roundi(float(item.get("fit",0))*100.0);controls.add_child(fit)
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",4);controls.add_child(actions)
	_add_action(actions,"dismiss",Tokens.TEXT_DIM,String(item.get("dismiss_tip","Dismiss")),item.get("on_dismiss",Callable()))
	_add_action(actions,"execute",Tokens.RED,String(item.get("execute_tip","Execute")),item.get("on_execute",Callable()))

func _add_action(parent:HBoxContainer,kind:String,color:Color,tip:String,callback:Variant)->void:
	var button:=Button.new();button.name="Cabinet"+kind.capitalize();button.custom_minimum_size=Vector2(32,30);button.tooltip_text=tip
	button.add_theme_stylebox_override("normal",Tokens.flat(Color.TRANSPARENT,Tokens.BORDER_SOFT,1,4));button.add_theme_stylebox_override("hover",Tokens.flat(Tokens.HOVER_BG,color,1,4));button.add_theme_stylebox_override("focus",StyleBoxEmpty.new());parent.add_child(button)
	var glyph:=Glyph.new();glyph.setup(kind,color);glyph.set_anchors_preset(Control.PRESET_FULL_RECT);glyph.custom_minimum_size=Vector2.ZERO;button.add_child(glyph)
	if callback is Callable: button.pressed.connect(func()->void:(callback as Callable).call())
