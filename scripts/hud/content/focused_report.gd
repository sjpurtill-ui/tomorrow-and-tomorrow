extends "res://scripts/hud/content/dock_content_base.gd"
## A focused, live report; the shell owns Back history, never simulation state.
var report_title:String
var context:String
var read:Callable
var revision:Callable
func _init(world:Node,shell:Control,title:String,context_label:String,reader:Callable,changed:Callable)->void:
	super(world,shell)
	report_title=title;context=context_label;read=reader;revision=changed
func meta()->Dictionary:
	return {"eyebrow":context,"title":report_title,"subtabs":[]}
func tab(_sub:int)->Dictionary:
	return read.call()
func signature()->Array:
	return revision.call()
