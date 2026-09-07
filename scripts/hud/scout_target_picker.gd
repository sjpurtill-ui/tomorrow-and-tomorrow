extends VBoxContainer
## Group display choices without merging evidence or changing mission target IDs.
var detail:Label
var selector:OptionButton
var category:OptionButton
var subject:OptionButton
var options:Array=[]
var groups:Dictionary={}
var categories:Array=[]
const LABELS={"explore":"Exploration","investigate_contact":"Known encounters","investigate_lead":"Investigation leads","observe_city":"Reported cities"}

static func grouped(options_in:Array)->Dictionary:
	var result:Dictionary={}
	for option:Dictionary in options_in:
		var kind:=String(option.get("kind","explore"))
		if not LABELS.has(kind):kind="explore"
		var key:=String(option.get("civ_id",option.id)) if kind in ["investigate_lead","investigate_contact"] else String(option.id)
		if not result.has(kind):result[kind]={}
		if not result[kind].has(key):result[kind][key]=[]
		result[kind][key].append(option)
	return result

func setup(values:Array,selected:String)->void:
	options=values;groups=grouped(values)
	category=OptionButton.new();subject=OptionButton.new();selector=OptionButton.new()
	for control:OptionButton in [category,subject,selector]:
		control.fit_to_longest_item=false;control.custom_minimum_size.y=36
		control.get_popup().max_size=Vector2i(700,360);add_child(control)
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(detail)
	selector.item_selected.connect(func(index:int):detail.text=selector.get_item_tooltip(index))
	categories=groups.keys()
	for kind:String in categories:category.add_item("%s · %d destinations"%[LABELS[kind],groups[kind].size()])
	category.item_selected.connect(func(_index:int):_subjects();selector.item_selected.emit(selector.selected))
	subject.item_selected.connect(func(_index:int):_reports();selector.item_selected.emit(selector.selected))
	var selected_category:=0;var selected_subject:=""
	for i in categories.size():
		for key:String in groups[categories[i]]:
			for option:Dictionary in groups[categories[i]][key]:
				if String(option.id)==selected:selected_category=i;selected_subject=key
	category.select(selected_category);_subjects(selected_subject,selected)

func _subjects(selected_subject:String="",selected_id:String="")->void:
	subject.clear()
	var kind:String=categories[category.selected]
	for key:String in groups[kind]:
		var entries:Array=groups[kind][key]
		var first:Dictionary=entries[0]
		var label:=String(first.label).trim_prefix("INVESTIGATE LEAD · ").trim_prefix("OBSERVE ").trim_prefix("INVESTIGATE ").trim_suffix(" ENCOUNTER")
		subject.add_item(label+(" · %d accounts"%entries.size() if entries.size()>1 else ""))
		subject.set_item_metadata(subject.item_count-1,key)
		if key==selected_subject:subject.select(subject.item_count-1)
	_reports(selected_id)

func _reports(selected_id:String="")->void:
	selector.clear()
	var entries:Array=groups[categories[category.selected]][String(subject.get_item_metadata(subject.selected))]
	for option:Dictionary in entries:
		var index:=selector.item_count
		selector.add_item(("Account %d · "%[index+1] if entries.size()>1 else "")+String(option.description).get_slice("\n",0))
		selector.set_item_metadata(index,String(option.id));selector.set_item_tooltip(index,String(option.description))
		if String(option.id)==selected_id:selector.select(index)
	selector.visible=entries.size()>1
	subject.tooltip_text=String(entries[selector.selected].description)
	detail.text=subject.tooltip_text
