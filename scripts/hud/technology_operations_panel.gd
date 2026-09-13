extends VBoxContainer
const Ops=preload("res://scripts/technology_operations.gd")
var subject:=""
var rows:Dictionary={}
var elapsed:=0.0
var specimen_report:Label
func _ready()->void:
	if subject in preload("res://scripts/rail_freight.gd").REQUIRED:
		add_child(preload("res://scripts/hud/rail_freight_controls.gd").new())
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
	if subject in ["nuclear_magnetic_resonance_spectroscopy","size_exclusion_chromatography"]:
		specimen_report=Label.new();specimen_report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(specimen_report)
	refresh()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=1:elapsed=0;refresh()
func refresh()->void:
	if is_instance_valid(specimen_report):
		specimen_report.text=preload("res://scripts/sec_acquisition.gd").report_text() if subject=="size_exclusion_chromatography" else preload("res://scripts/nmr_acquisition.gd").report_text()
	for id:String in rows:
		var row:Dictionary=rows[id];var spec:Dictionary=Ops.PLANTS[id]
		var record:Dictionary=Ops.data().plants.get(id,{})
		row.label.text="%s · %d installed · %d being commissioned. Requires %.1f Crafting operators per unit and %.1f power units per day." % [spec.name,int(record.get("installed",0)),int(record.get("building",0)),float(spec.workers),float(spec.power)]
		if spec.has("storage"):
			row.label.text="%s · %d installed · %d being commissioned. Up to %.2f Crafting operators per active unit. Each stores %.1f energy units, charges up to %.1f and supplies up to %.1f per day; charging and discharge incur losses." % [spec.name,int(record.get("installed",0)),int(record.get("building",0)),float(spec.workers),float(spec.storage.capacity),float(spec.storage.charge_rate),float(spec.storage.discharge_rate)]
		if float(spec.services.get("electricity",0))>0:row.label.text+=" Nominal generation: %.1f power units per day." % float(spec.services.electricity)
		if id=="water_hammer":row.label.text+=" Requires a confirmed river within 0.75 km. All installed hammers share the site’s seasonal capacity; freezing or dry conditions stop the drive. Forging consumes its daily hammer work."
		if spec.services.has("specimen_observation"):row.label.text+=" Uses slide supplies each operating day to help researchers examine returned physical specimens; ordinary study work is still required."
		if spec.services.has("radio_records"):row.label.text+=" Sends agreed research records home from a physically reached partner with an operating station, up to 120 km. Both endpoints spend daily capacity; local study and physical return travel remain required."
		if spec.has("analysis_family"):row.label.text+=" Uses supplies and finite daily instrument time to examine compatible "+String(spec.analysis_family)+" equipment; other communications families need their own bench."
		row.label.text+="\n"+Ops.status(id)
		var terms:=Ops.quote(id)
		row.build.disabled=terms.has("error")
		row.build.tooltip_text=String(terms.get("message",terms.get("error","")))
		row.pause.disabled=record.is_empty();row.pause.text="Pause next day" if record.get("enabled",true) else "Resume next day"
