extends CanvasLayer
## A returned expedition should be visible without stealing the player's open
## report or changing time. The full record remains in the permanent archive.
const Archive:=preload("res://scripts/scout_archive.gd")
var terrain:Node
var hud:Control
var reports:Array[Dictionary]=[]
var notice:HBoxContainer
var open_button:Button

static func announce(terrain_node:Node,hud_node:Control,report:Dictionary)->CanvasLayer:
	if not is_instance_valid(hud_node):return null
	var digest:Variant=hud_node.get_meta("scout_return_digest") if hud_node.has_meta("scout_return_digest") else null
	if not is_instance_valid(digest):
		digest=new();digest.terrain=terrain_node;digest.hud=hud_node
		hud_node.set_meta("scout_return_digest",digest);hud_node.add_child(digest)
	digest.receive(report)
	return digest

func _ready()->void:
	layer=71
	notice=HBoxContainer.new();add_child(notice)
	open_button=Button.new();open_button.custom_minimum_size=Vector2(330,46);open_button.alignment=HORIZONTAL_ALIGNMENT_LEFT;open_button.pressed.connect(open_latest);notice.add_child(open_button)
	var dismiss:=Button.new();dismiss.text="×";dismiss.tooltip_text="Leave reports unread in the Expedition Archive";dismiss.pressed.connect(clear);notice.add_child(dismiss)
	get_viewport().size_changed.connect(layout);layout();notice.hide()

func layout()->void:
	var viewport:=get_viewport().get_visible_rect().size
	notice.position=Vector2(maxf(0,viewport.x-395),maxf(0,viewport.y-220))

func receive(report:Dictionary)->void:
	reports.append(report.duplicate(true))
	if reports.size()>8:reports.pop_front()
	refresh()

func refresh()->void:
	if reports.is_empty():notice.hide();return
	var summary:Dictionary=Archive.summary(reports[-1])
	open_button.text="EXPEDITION RETURNED · %s%s" % [String(summary.title)," · %d unread" % reports.size() if reports.size()>1 else ""]
	open_button.tooltip_text=String(summary.detail)+" Open the full illustrated report."
	notice.show()

func open_latest()->void:
	if reports.is_empty():return
	var report:Dictionary=reports.pop_back()
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_scout_report.gd").new(terrain,hud,report,preload("res://scripts/hud/content/dock_detail_scout_archive.gd").new(terrain,hud)))
	refresh()

func clear()->void:
	reports.clear();notice.hide()
