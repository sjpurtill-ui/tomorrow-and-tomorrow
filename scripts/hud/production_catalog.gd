extends VBoxContainer
const T=preload("res://scripts/hud/hud_tokens.gd")
const Selection=preload("res://scripts/hud/production_selection.gd")
const Folio=preload("res://scripts/hud/production_folio.gd")
const P=preload("res://scripts/persistent_production.gd")
const Plain=preload("res://scripts/hud/production_plain.gd")
const Ledger=preload("res://scripts/equipment_ledger.gd")

func setup(block:Dictionary)->void:
	add_theme_constant_override("separation",10)
	var browser:=Selection.new();add_child(browser);browser.setup(block.get("view_state",{}),6)
	for entry:Dictionary in block.get("items",[]):
		var key:=String(entry.get("item",entry.label))
		var reading:=VBoxContainer.new();reading.add_theme_constant_override("separation",12)
		browser.add_record(key,String(entry.label),"",reading)
		var lead:=HBoxContainer.new();lead.add_theme_constant_override("separation",12);reading.add_child(lead)
		var art:=TextureRect.new();art.texture=Folio.product_texture(key);art.custom_minimum_size=Vector2(80,80);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;lead.add_child(art)
		var title:=_label(lead,String(entry.label),24);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_label(reading,String(entry.get("sub","")),17)
		var stats:=String(Ledger.card_words(key));if not stats.is_empty():_label(reading,stats,15)
		var recipe:Dictionary=P.recipe(MilitaryCampaign,key);var needs:PackedStringArray=[]
		for resource:String in recipe.get("materials",{}):needs.append("%s %s" % [Plain.number(float(recipe.materials[resource])),ResourceSystem.display_name(resource).to_lower()])
		if not needs.is_empty():_label(reading,"Each needs "+", ".join(needs),15)
		var action:=Button.new();action.text=String(block.get("verb","Choose"))+" · "+String(entry.label);action.custom_minimum_size.y=44;action.clip_text=true;action.tooltip_text=action.text;T.apply_button_style(action,true);reading.add_child(action)
		action.disabled=bool(entry.get("disabled",false));action.pressed.connect(func():var callback:Variant=entry.get("on_press");if callback is Callable:callback.call())
	if block.get("items",[]).is_empty():_label(self,"No known products available.",16)
	browser.refresh()

func _label(parent:Node,words:String,points:int)->Label:
	var label:=T.make_label(words,points,T.INK);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label);return label
