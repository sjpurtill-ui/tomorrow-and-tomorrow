extends CanvasLayer
## Daily findings remain in the existing discovery archive. Only selected
## milestones interrupt; the compact digest never owns a simulation pause.
const DiscoveryNotice=preload("res://scripts/hud/discovery_popup.gd")
const MILESTONES=["seed_selection","public_schools","printing_process","steam_propulsion","powered_flight","reactor_engineering"]
const MODES=["milestones","all","quiet"]
var terrain:Node
var hud:Node
var unread:=0
var latest:=""
var seen:Dictionary={}
var notice:HBoxContainer
var open_button:Button
static func important(event:Dictionary,mode:String,first_batch:bool=false)->bool:
	return mode=="all" or (mode=="milestones" and (first_batch or String(event.get("id","")) in MILESTONES))
static func announce(terrain_node:Node,hud_node:Node,events:Array[Dictionary])->CanvasLayer:
	if events.is_empty() or not is_instance_valid(hud_node):return null
	var digest:Variant=hud_node.get_meta("research_digest") if hud_node.has_meta("research_digest") else null
	if not is_instance_valid(digest):
		digest=new();digest.terrain=terrain_node;digest.hud=hud_node;hud_node.set_meta("research_digest",digest);hud_node.add_child(digest)
	digest.receive(events)
	return digest
func _ready()->void:
	layer=70
	notice=HBoxContainer.new();add_child(notice)
	notice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	notice.position=Vector2(get_viewport().get_visible_rect().size.x-320,get_viewport().get_visible_rect().size.y-160)
	open_button=Button.new();open_button.custom_minimum_size=Vector2(265,40);notice.add_child(open_button)
	open_button.pressed.connect(open_archive)
	var dismiss:=Button.new();dismiss.text="×";dismiss.tooltip_text="Clear research digest";notice.add_child(dismiss)
	dismiss.pressed.connect(clear)
	get_viewport().size_changed.connect(layout)
	notice.hide()
func layout()->void:
	notice.position=Vector2(maxf(0,get_viewport().get_visible_rect().size.x-320),maxf(0,get_viewport().get_visible_rect().size.y-160))
func receive(events:Array[Dictionary])->void:
	var interruptions:Array[Dictionary]=[]
	var first_batch:=GameState.known_discoveries.size()<=events.size()
	for event:Dictionary in events:
		var id:=String(event.get("id",""))
		if id.is_empty() or id not in GameState.known_discoveries or seen.has(id):continue
		seen[id]=true
		if seen.size()>8192:seen.erase(seen.keys()[0])
		if important(event,GameState.research_notification_mode,first_batch):interruptions.append(event)
		else:unread+=1;latest=id
	open_button.text="Research: %d new finding%s" % [unread,"" if unread==1 else "s"]
	notice.visible=unread>0
	if not interruptions.is_empty():DiscoveryNotice.announce(terrain,hud,interruptions)
func clear()->void:
	unread=0;notice.hide()
func open_archive()->void:
	preload("res://scripts/hud/knowledge_atlas.gd").open(terrain,hud,"inquiry")
	var atlas=hud.get_meta("knowledge_atlas").get_child(0)
	atlas.set_view("known");atlas.select(latest)
	clear()
