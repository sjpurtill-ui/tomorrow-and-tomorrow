extends VBoxContainer
## Wagonways between your own settlements, in plain words: one sentence per
## route that can be laid, with its cost, and one verb. The usual track width
## and wagon count are chosen for you; the route is the only choice.
const Rail=preload("res://scripts/rail_freight.gd")
const Plain=preload("res://scripts/hud/production_plain.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
## The first route's button (kept for tests and keyboard focus).
var build:Button
var report:=Label.new()
var offers_box:=VBoxContainer.new()
var refresh_elapsed:=0.0
func _ready()->void:
	name="Wagonways";add_theme_constant_override("separation",6)
	add_child(T.make_label("WAGONWAYS BETWEEN OUR PLACES",12,T.GOLD_TEXT))
	report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(report)
	offers_box.add_theme_constant_override("separation",6);add_child(offers_box)
	refresh()
func _process(delta:float)->void:
	refresh_elapsed+=delta
	if refresh_elapsed>=5.0:
		refresh_elapsed=0.0;refresh()
func _cost_words(cost:Dictionary)->String:
	var parts:Array[String]=[]
	for item:String in cost:parts.append("%s %s" % [Plain.number(float(cost[item])),item.to_lower()])
	return ", ".join(parts) if not parts.is_empty() else "nothing"
func refresh(update_report:bool=true)->void:
	if update_report:report.text=Rail.describe()
	for child in offers_box.get_children():child.queue_free()
	build=null
	var places:Array[Dictionary]=[]
	for record:Dictionary in WorldSimulation.state.player_settlements:
		if Rail.available_city(String(record.id)):places.append(record)
	if places.size()<2:
		var none:=T.make_label("A wagonway needs two of our settlements to join.",13,T.MUTED);none.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;offers_box.add_child(none);return
	for from:Dictionary in places:
		for to:Dictionary in places:
			if String(from.id)==String(to.id):continue
			var terms:=Rail.quote(String(from.id),String(to.id))
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);offers_box.add_child(row)
			var ok:=bool(terms.get("ok",false))
			var text:=T.make_label("From %s to %s. %s" % [String(from.name),String(to.name),("Costs "+_cost_words(terms.get("cost",{}))+".") if ok else String(terms.get("error",""))],13,T.BODY if ok else T.MUTED)
			text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text)
			var button:=Button.new();button.text="Lay it";button.disabled=not ok;button.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(button)
			var source_id:=String(from.id);var destination_id:=String(to.id)
			button.pressed.connect(func()->void:
				var result:=Rail.install(source_id,destination_id)
				report.text=String(result.get("error","The wagonway is supplied and waits for builders."))+"\n"+Rail.describe()
				refresh(false))
			if build==null:build=button
