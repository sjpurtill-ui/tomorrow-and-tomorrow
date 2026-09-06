extends "res://scripts/hud/content/dock_content_base.gd"
var military:Object
var template_id:int
func _init(world:Node,shell:Control,source:Object,id:int)->void:
	super(world,shell);military=source;template_id=id
func meta()->Dictionary:
	var title:="Army design removed"
	for template:Dictionary in MilitaryCampaign.army_template_snapshot().templates:
		if int(template.template_id)==template_id:title=String(template.name)
	return {"eyebrow":"PREPARE ONE ARMY · SHARED HOME RESERVE","title":title,"subtabs":["1 · COMPOSITION","2 · RECRUIT & TRAIN","3 · DEPLOY"]}
func tab(step:int)->Dictionary:
	return {"blocks":military._builds_blocks(MilitaryCampaign.military_capabilities(),template_id,step)}
func signature()->Array:return military.signature()
