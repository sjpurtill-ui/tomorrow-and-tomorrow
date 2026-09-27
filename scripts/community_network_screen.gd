extends Control
var map:Control
var detail:Label
var quote:Label
var status:Label
var project_detail:Label
var project_choice:OptionButton
var project_button:Button
var proposal:Button
var selected:="player"
var timer:=0.0
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg:=ColorRect.new(); bg.color=Color("11252e"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,24)
	add_child(margin)
	var layout:=VBoxContainer.new(); layout.add_theme_constant_override("separation",12); margin.add_child(layout)
	var header:=HBoxContainer.new(); layout.add_child(header)
	var title:=_label(header,26); title.text="WHAT CAN WE ACCOMPLISH TOGETHER?"; title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(header,"RETURN · F9",func(): queue_free())
	var intro:=_label(layout,15); intro.text="Meet other communities, build lasting traditions, and decide what cooperation should mean for your people."
	var body:=HBoxContainer.new(); body.size_flags_vertical=Control.SIZE_EXPAND_FILL; layout.add_child(body)
	map=preload("res://scripts/community_network_map.gd").new(); map.size_flags_horizontal=Control.SIZE_EXPAND_FILL; body.add_child(map)
	map.selected.connect(func(id:String): selected=id; _refresh())
	var sidebar:=VBoxContainer.new(); sidebar.custom_minimum_size.x=360; body.add_child(sidebar)
	detail=_label(sidebar,18)
	quote=_label(sidebar,15)
	# Proposals are made in the court, in the conversation with their ruler.
	proposal=_button(sidebar,"Address their ruler in the court",func():
		if selected!="player": queue_free(); WorldSimulation.diplomacy.open(selected))
	var legend:=_label(layout,14); legend.text="Gold: trade · Green: non-aggression · Red: war · Grey: contact only. This is a relationship diagram, not a geographical map."
	var row:=HBoxContainer.new(); layout.add_child(row)
	project_choice=OptionButton.new(); project_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(project_choice)
	for id in CommunityNetwork.PROJECTS:
		project_choice.add_item(CommunityNetwork.PROJECTS[id].name); project_choice.set_item_metadata(project_choice.item_count-1,id)
	project_choice.item_selected.connect(func(_i:int): _refresh())
	project_button=_button(row,"BACK THIS PROJECT",func():
		var result:Dictionary=WorldSimulation.communities.start(String(project_choice.get_selected_metadata())); status.text=String(result.get("error","Project backed. Your people handle the work.")); _refresh())
	project_detail=_label(layout,16)
	status=_label(layout,15)
	_refresh()
func _label(parent:Node,font:int)->Label:
	var l:=Label.new(); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",font); parent.add_child(l); return l
func _button(parent:Node,text:String,action:Callable)->Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=36; b.pressed.connect(action); parent.add_child(b); return b
func _process(delta:float)->void:
	timer+=delta
	if timer>1: timer=0; _refresh()
func _refresh()->void:
	var nodes:=WorldSimulation.communities.nodes(); map.update_nodes(nodes)
	var current:Dictionary=nodes[0]
	for node in nodes:
		if node.id==selected: current=node
	selected=String(current.id); map.selection=selected
	if current.id=="player":
		detail.text="YOUR PEOPLE\nChoose a shared project below. Select a known community to consider cooperation."
		quote.text="Scouts and encounters reveal other communities. Their people decide whether to accept your proposals."
		proposal.disabled=true
	else:
		detail.text="%s\nCurrent relationship: %s\nAutonomy: independent\nCommon opportunity: exchange or mutual security." % [current.name,"war" if current.war else String(current.treaty).replace("_"," ")]
		proposal.disabled=ForeignDiplomacy.leader(selected).is_empty()
		quote.text="Trade, peace and every other word to them are sent from the court, in the conversation with their ruler."
	var id:=String(project_choice.get_selected_metadata()); var definition:Dictionary=CommunityNetwork.PROJECTS[id]
	var costs:Array[String]=[]
	for item in definition.cost: costs.append("%d %s" % [int(definition.cost[item]),item])
	var reason:=WorldSimulation.communities.blocker(id)
	project_button.disabled=reason!=""
	project_detail.text="%s\nCosts: %s · %d work-days with at least four knowledge/administration workers.\n%s All research is 8%% slower while the project is underway." % [definition.purpose,", ".join(costs),int(definition.work),definition.effect]
	if reason!="": project_detail.text+="\n"+reason
	if WorldSimulation.communities.active!="": project_detail.text+="\nActive: %s · %d%% of work complete" % [CommunityNetwork.PROJECTS[WorldSimulation.communities.active].name,roundi(WorldSimulation.communities.progress/float(CommunityNetwork.PROJECTS[WorldSimulation.communities.active].work)*100)]
