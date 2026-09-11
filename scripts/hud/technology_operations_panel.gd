extends VBoxContainer
const Ops=preload("res://scripts/technology_operations.gd")
var subject:=""
var rows:Dictionary={}
var elapsed:=0.0
func _ready()->void:
	for id:String in Ops.PLANTS:
		var spec:Dictionary=Ops.PLANTS[id]
		if spec.gate!=subject:continue
		var label:=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(label)
		var actions:=VBoxContainer.new();add_child(actions)
		var build:=Button.new();build.text="Install "+String(spec.name);actions.add_child(build)
		var pause:=Button.new();actions.add_child(pause)
		var message:=Label.new();message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(message)
		rows[id]={"label":label,"build":build,"pause":pause,"message":message}
		build.pressed.connect(func()->void:
			var result:=Ops.install(id)
			message.text=String(result.get("message",result.get("error","")));refresh())
		pause.pressed.connect(func()->void:
			Ops.set_enabled(id,not bool(Ops.data().plants.get(id,{}).get("enabled",true)));refresh())
	refresh()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=1:elapsed=0;refresh()
func refresh()->void:
	for id:String in rows:
		var row:Dictionary=rows[id];var spec:Dictionary=Ops.PLANTS[id]
		var record:Dictionary=Ops.data().plants.get(id,{})
		row.label.text="%s · %d installed · %d being commissioned. Requires %.1f Crafting operators per unit and %.1f power units per day." % [spec.name,int(record.get("installed",0)),int(record.get("building",0)),float(spec.workers),float(spec.power)]
		row.label.text+="\n"+Ops.status(id)
		var terms:=Ops.quote(id)
		row.build.disabled=terms.has("error")
		row.build.tooltip_text=String(terms.get("message",terms.get("error","")))
		row.pause.disabled=record.is_empty();row.pause.text="Pause next day" if record.get("enabled",true) else "Resume next day"
