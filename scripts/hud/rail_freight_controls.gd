extends VBoxContainer
const Rail=preload("res://scripts/rail_freight.gd")
var source:=OptionButton.new()
var destination:=OptionButton.new()
var gauge:=OptionButton.new()
var wagons:=SpinBox.new()
var refresh_elapsed:=0.0
var build:=Button.new()
var report:=Label.new()
func _ready()->void:
	for record:Dictionary in WorldSimulation.state.player_settlements:
		if not Rail.available_city(String(record.id)):continue
		source.add_item(String(record.name));source.set_item_metadata(source.item_count-1,String(record.id))
		destination.add_item(String(record.name));destination.set_item_metadata(destination.item_count-1,String(record.id))
	if destination.item_count>1:destination.select(1)
	gauge.add_item("900 mm wagons",900);gauge.add_item("1435 mm wagons",1435)
	add_child(source);add_child(destination);add_child(gauge)
	wagons.min_value=1;wagons.max_value=Rail.F.MAX_WAGONS;wagons.step=1;wagons.value=2;wagons.prefix="Wagons: ";add_child(wagons)
	wagons.value_changed.connect(func(_value:float)->void:refresh())
	build.text="Build supplied wagonway";add_child(build)
	report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(report)
	build.pressed.connect(func()->void:
		if source.selected<0 or destination.selected<0:return
		var result:=Rail.install(String(source.get_item_metadata(source.selected)),String(destination.get_item_metadata(destination.selected)),gauge.get_selected_id(),int(wagons.value))
		report.text=String(result.get("error","Paid route awaits construction work."))+"\n"+Rail.describe()
		refresh(false))
	for picker:OptionButton in [source,destination,gauge]:picker.item_selected.connect(func(_index:int)->void:refresh())
	refresh()
func _process(delta:float)->void:
	refresh_elapsed+=delta
	if refresh_elapsed>=5.0:
		refresh_elapsed=0.0;refresh()
func refresh(update_report:bool=true)->void:
	if update_report:report.text=Rail.describe()
	if source.selected<0 or destination.selected<0:build.disabled=true;return
	var terms:=Rail.quote(String(source.get_item_metadata(source.selected)),String(destination.get_item_metadata(destination.selected)),gauge.get_selected_id(),int(wagons.value))
	build.disabled=not bool(terms.get("ok",false))
	var detail:=String(terms.get("error",""))
	for item:String in terms.get("cost",{}):detail+="\n%.1f %s" % [float(terms.cost[item]),item]
	build.tooltip_text=detail
