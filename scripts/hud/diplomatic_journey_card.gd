extends VBoxContainer
var status:Dictionary={}

func _ready()->void:
	add_theme_constant_override("separation",12)
	var title:=HBoxContainer.new();add_child(title)
	var flag:=TextureRect.new();flag.texture=preload("res://scripts/city_map_identity.gd").foreign(String(status.get("civ_id",""))).texture;flag.custom_minimum_size=Vector2(48,30);flag.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flag.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;title.add_child(flag)
	var destination:=Label.new();destination.text=String(status.get("destination",status.get("civilization","Foreign home")));destination.add_theme_font_size_override("font_size",22);destination.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;destination.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_child(destination)
	var facts:=Label.new();facts.text="%s · %d envoys · %.0f km from home" % [String(status.get("phase","Outbound")),int(status.get("personnel",0)),float(status.get("distance_km",0))];add_child(facts)
	var bar:=ProgressBar.new();bar.max_value=1;bar.value=float(status.get("progress",0));bar.show_percentage=false;bar.custom_minimum_size.y=12;add_child(bar)
	var steps:=HBoxContainer.new();add_child(steps)
	for pair in [["Departed",int(status.get("depart_day",0))],["Expected arrival",int(status.get("arrival_day",0))],["Expected home",int(status.get("return_day",0))]]:
		var step:=Label.new();step.text="%s\nYear %d · Day %d" % [pair[0],1+int(pair[1])/365,int(pair[1])%365+1];step.size_flags_horizontal=Control.SIZE_EXPAND_FILL;steps.add_child(step)
	var result:=Label.new();result.text="%d days until their reply comes home. You can close this window to resume the journey." % int(status.get("days_remaining",0));result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(result)
