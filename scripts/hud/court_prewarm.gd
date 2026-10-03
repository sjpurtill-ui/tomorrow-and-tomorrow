extends Node
## Warms the modelled court before it is first opened (L), so the first
## audience does not stop the game while the people and the place load.
## Started once, a few seconds after the game's rail is up or the first time
## the Court button is hovered (command_rail_hud.gd), it:
##   - asks the resource loader's own threads for the figures' bodies, the
##     current age's set and the animals (ResourceLoader.load_threaded_request);
##     the main thread only looks at their progress, one check a frame;
##   - when each is in, hands it to the figure and set caches (scene_for is
##     then a lookup: the resource is already loaded);
##   - reads the acting's clip libraries (court_acting.gd) on a worker thread,
##     one body at a time, and the figures' manifest.
## Nothing here builds anything in the game's world or changes its state; it
## never waits on a load, so neither the frame nor the simulation stalls. If
## the court is opened first, the court loads what it still needs as before.

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Self:=preload("res://scripts/hud/court_prewarm.gd")

## The bodies the acting has clip libraries for (court_acting.gd).
const ACTING_BODIES:=["male_adult","female_adult","male_old","female_old","male_young","female_young","child"]
## The animals that may stand about the hall.
const ANIMALS:=["dog","goat"]

static var started:=false
static var done:=false
## Seconds from the start to the end (for the probe).
static var took:=0.0

## The one hook (command_rail_hud.gd): the warm-up starts `delay` seconds after
## the button is in the tree, or at once when it is first hovered.
static func attach(button:Control,delay:=4.0)->void:
	if button==null:return
	button.mouse_entered.connect(func()->void:start(button),CONNECT_ONE_SHOT)
	var later:=func()->void:
		if is_instance_valid(button) and button.is_inside_tree():
			button.get_tree().create_timer(delay,false).timeout.connect(func()->void:if is_instance_valid(button):start(button))
	if button.is_inside_tree():later.call()
	else:button.tree_entered.connect(later,CONNECT_ONE_SHOT)

## Begins the warm-up (once a run). host: any node in the tree.
static func start(host:Node)->void:
	if started or host==null or not host.is_inside_tree():return
	if not Figure3D.enabled:return
	started=true
	var node:=Self.new()
	node.name="CourtPrewarm"
	host.get_tree().root.add_child.call_deferred(node)

# --- one warm-up ------------------------------------------------------------------

## path -> what to do with it once loaded ("body:<variant>", "set:<kind>", "animal:<species>")
var _pending:Dictionary={}
## Loaded resources held so they stay in the resource cache until handed over.
var _held:Array=[]
var _acting:Array=[]
var _task:=-1
var _began:=0

func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	_began=Time.get_ticks_msec()
	for v:String in Figure3D.BODIES:
		_request(Figure3D.DIR+"court_figure_%s.glb" % v,"body:"+v)
	var kind:=CourtSet.kind_for(Backdrop.current_stage(),Backdrop.current_tier())
	var entry:Dictionary=(CourtSet.manifest().get("sets",{}) as Dictionary).get(kind,{})
	_request(CourtSet.DIR+String(entry.get("glb","court_set_%s.glb" % kind)),"set:"+kind)
	for species:String in ANIMALS:
		var path:=_animal_path(species)
		if not path.is_empty():_request(path,"animal:"+species)
	_acting=ACTING_BODIES.duplicate()

func _request(path:String,what:String)->void:
	if not ResourceLoader.exists(path):return
	if ResourceLoader.load_threaded_request(path,"",false)==OK:_pending[path]=what

## The animal's file, as court_animal_3d.gd names it.
func _animal_path(species:String)->String:
	var entry:Dictionary=(CourtSet.Animal.manifest().get("species",{}) as Dictionary).get(species,{})
	if entry.is_empty():return ""
	return CourtSet.Animal.DIR+String(entry.get("glb","court_%s.glb" % species))

func _process(_delta:float)->void:
	# The loaders' progress: one look a frame, never a wait.
	for path:String in _pending.keys():
		var status:=ResourceLoader.load_threaded_get_status(path)
		if status==ResourceLoader.THREAD_LOAD_IN_PROGRESS:continue
		var what:String=_pending[path]
		_pending.erase(path)
		if status==ResourceLoader.THREAD_LOAD_LOADED:
			_held.append(ResourceLoader.load_threaded_get(path))
			_hand_over(what)
		break
	# The acting's clips, one body at a time on a worker thread.
	if _task>=0:
		if _running!=_task:_task=-1;return
		if not WorkerThreadPool.is_task_completed(_task):return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task=-1;_running=-1
	if not _acting.is_empty() and not _court_open():
		var variant:String=_acting.pop_front()
		_task=WorkerThreadPool.add_task(Acting.library.bind(variant),false,"court acting clips")
		_running=_task
		return
	if _pending.is_empty() and _acting.is_empty() and _task<0:
		done=true
		took=float(Time.get_ticks_msec()-_began)/1000.0
		_held.clear()
		queue_free()

## The caches take what is loaded (a lookup now: the resource is in memory).
func _hand_over(what:String)->void:
	var kind:=what.get_slice(":",0);var name_of:=what.get_slice(":",1)
	match kind:
		"body":Figure3D.scene_for(name_of)
		"set":CourtSet.scene_for(name_of)
		"animal":CourtSet.Animal.scene_for(name_of)

## While a court is open the acting reads its own clips there; the worker
## stays out of its way (the two must not fill the same library at once).
func _court_open()->bool:
	return get_tree().get_first_node_in_group("court_stage")!=null

## The court is opening: a clip library still being read on the worker is
## finished first (the court would read the same one). Waits only in that
## case, and only for the rest of that one body's clips.
static var _running:=-1
static func settle()->void:
	if _running>=0:
		WorkerThreadPool.wait_for_task_completion(_running)
		_running=-1
