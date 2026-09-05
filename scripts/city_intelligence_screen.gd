extends Control
var city_id:=""
var civ_id:=""
var selector:OptionButton
var duration:OptionButton
var report:RichTextLabel
var costs:Label
var send:Button
var timer:=0.0

func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var background:=ColorRect.new(); background.color=Color("09171d"); background.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(background)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(margin)
	for edge:String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",16); margin.add_child(root)
	var top:=HBoxContainer.new(); root.add_child(top)
	var title:=Label.new(); title.text="THE CITY REPORTS"; title.add_theme_font_size_override("font_size",28); title.add_theme_color_override("font_color",Color("d6bc81")); title.size_flags_horizontal=SIZE_EXPAND_FILL; top.add_child(title)
	var close:=Button.new(); close.text="RETURN"; close.pressed.connect(func(): get_parent().queue_free()); top.add_child(close)
	var hint:=Label.new(); hint.text="What was seen, who brought it home, and what remains unknown."; root.add_child(hint)
	selector=OptionButton.new(); selector.custom_minimum_size.y=42; root.add_child(selector)
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player",civ_id):
		selector.add_item("%s · %.0f, %.0f km · %s" % [String(city.name),float(city.position.x),float(city.position.z),String(city.freshness)])
		selector.set_item_metadata(selector.item_count-1,String(city.city_id))
		if city.city_id==city_id: selector.select(selector.item_count-1)
	selector.item_selected.connect(func(_index:int): refresh())
	report=RichTextLabel.new(); report.bbcode_enabled=false; report.size_flags_vertical=SIZE_EXPAND_FILL; report.add_theme_font_size_override("normal_font_size",20); root.add_child(report)
	var actions:=HBoxContainer.new(); root.add_child(actions)
	duration=OptionButton.new(); actions.add_child(duration)
	for days:int in CivilizationSystem.SCOUT_DURATIONS: duration.add_item("%d-day reconnaissance" % days); duration.set_item_metadata(duration.item_count-1,days)
	duration.item_selected.connect(func(_index:int): refresh())
	costs=Label.new(); costs.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; costs.size_flags_horizontal=SIZE_EXPAND_FILL; actions.add_child(costs)
	send=Button.new(); send.text="SEND SCOUTS"; actions.add_child(send)
	send.pressed.connect(func():
		if selector.item_count==0: return
		var result:=CivilizationSystem.dispatch_scouts(int(duration.get_selected_metadata()),"city:"+String(selector.get_selected_metadata()))
		costs.text=String(result.get("error","Scouts departed. This report changes only when evidence returns.")))
	refresh()

func refresh()->void:
	if selector.item_count==0: report.text="No foreign city has been identified by a returned report."; send.disabled=true; return
	city_id=String(selector.get_selected_metadata())
	var city:Dictionary=CivilizationSystem.city_intelligence.known("player",city_id)
	report.text=CivilizationSystem.city_intelligence.describe(city)
	var quote:=CivilizationSystem.scout_mission_quote(int(duration.get_selected_metadata()),"city:"+city_id)
	send.disabled=not bool(quote.get("can_dispatch",false))
	costs.text=String(quote.get("error",quote.get("blocker",""))) if send.disabled else "%d people · %.1f Food · %d days planned\nArrival does not give instant knowledge at home." % [int(quote.personnel),float(quote.provisions),int(quote.duration_days)]

func _process(delta:float)->void:
	timer+=delta
	if timer>=5: timer=0; refresh()
