extends RefCounted
## Research news has one home: the Chronicle (scripts/chronicle.gd). A first
## discovery in a field and the era-defining practices are its moment cards;
## every other finding is folded into the season's "what we learned" notice.
## There is no separate research toast or unread counter.
##
## The only thing left here is the player's own opt-in: with "Discovery
## pauses: Every discovery" chosen in the research atlas, each new finding
## also opens its full illustrated reading card (hud/discovery_popup.gd).
const DiscoveryNotice=preload("res://scripts/hud/discovery_popup.gd")
const MILESTONES=["seed_selection","public_schools","printing_process","steam_propulsion","powered_flight","reactor_engineering"]
const MODES=["milestones","all","quiet"]

static func important(event:Dictionary,mode:String,first_batch:bool=false)->bool:
	return mode=="all" or (mode=="milestones" and (first_batch or String(event.get("id","")) in MILESTONES))

## Returns the opened reading card, or null when the Chronicle alone tells it.
static func announce(terrain_node:Node,hud_node:Node,events:Array[Dictionary])->CanvasLayer:
	if events.is_empty() or not is_instance_valid(hud_node):return null
	if GameState.research_notification_mode!="all":return null
	var fresh:Array[Dictionary]=[]
	for event:Dictionary in events:
		var id:=String(event.get("id",""))
		if id.is_empty() or id not in GameState.known_discoveries:continue
		fresh.append(event)
	if fresh.is_empty():return null
	return DiscoveryNotice.announce(terrain_node,hud_node,fresh)
