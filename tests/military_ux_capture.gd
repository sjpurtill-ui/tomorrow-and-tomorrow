extends Node
## Visual check for the HOI4-style military pieces (not a test suite): the
## army bar with its deployment card, and the map counters in every state,
## drawn on the chart's paper. Run windowed:
##   <godot> --path <worktree> res://tests/military_ux_capture.tscn -- --capture=reports/ux/pieces.png
## Writes the image and quits. Builds its own small world; touches no save.

const ArmyBar:=preload("res://scripts/hud/army_bar.gd")
const Counter:=preload("res://scripts/hud/army_counter.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

var out_path:="res://reports/ux/pieces.png"

func _ready()->void:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--capture="): out_path=String(a).trim_prefix("--capture=")
	WorldSimulation.clear()
	GameState.reset_for_new_world(4141)
	GameState.settlement_site_committed=true
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	var sim=MilitaryCampaign.simulator
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	# In drill: 20 spearmen a third through, 6 waiting, 3 drafts for a band.
	MilitaryCampaign.training_queue.assign([
		{"id":1,"unit":"spearman","weapon":"spear","count":20,"initial_count":20,"progress_days":10.0,"required_days":30.0,"start_day":0},
		{"id":2,"mode":"field_draft","army_id":1,"unit":"spearman","weapon":"spear","count":3,"progress_days":4.0,"required_days":17.0}])
	MilitaryCampaign.aggregate_recruits=6
	var home:Vector2=CivilizationSystem.player_world_origin
	var make:=func(id:int,name:String,men:int,status:String,offset:Vector2,extra:Dictionary)->Dictionary:
		var force:Dictionary=sim.create_formation_force(name,[{"id":id,"unit":"spearman","weapon":"spear","count":men,"authorized_count":20,"equipment":men,"equipment_required":20,"training":0.6}],0.7,0.8)
		var at:=home+offset
		force.merge({"army_id":id,"name":name,"status":status,"position":{"x":at.x,"z":at.y},"supply_level":0.6,"commander":{"name":name.get_slice(" ",0)}},true)
		force.merge(extra,true)
		return force
	MilitaryCampaign.field_armies.assign([
		make.call(1,"Ennis band",17,"moving",Vector2(80,0),{"living_off_land":true,"provision_ratio":0.8}),
		make.call(2,"Hewin band",20,"stationed",Vector2(-60,30),{"provision_ratio":0.3,"hungry_days":5.0})])
	var root:=Control.new();root.size=Vector2(1600,900);add_child(root)
	var paper:=ColorRect.new();paper.color=Color("#d9cba4");paper.size=root.size;root.add_child(paper)
	var sheet:=Sheet.new();sheet.size=Vector2(1600,560);root.add_child(sheet)
	var bar:Control=ArmyBar.new();bar.position=Vector2(20,600);bar.size=Vector2(1560,240);root.add_child(bar)
	await get_tree().process_frame
	bar.place(Rect2(Vector2(20,600),Vector2(1560,240)))
	bar.refresh()
	for i in 6: await get_tree().process_frame
	RenderingServer.force_draw(true,0.0)
	var image:=get_viewport().get_texture().get_image()
	if image: image.save_png(ProjectSettings.globalize_path(out_path))
	get_tree().quit()


class Sheet extends Control:
	## The counters in every state, labelled.
	const Counter:=preload("res://scripts/hud/army_counter.gd")
	func _draw()->void:
		var ours:=Color("#4f9bb8"); var theirs:=Color("#b5503c")
		var rows:=[
			["Marching, living off the land",{"side":"ours","glyph":"spear","troops":17,"strength":0.85,"will":0.7,"supply":"strained","foraging":true,"state":"marching","march_done":0.35,"days_left":6,"accent":ours}],
			["Holding, starving",{"side":"ours","glyph":"spear","troops":20,"strength":1.0,"will":0.4,"supply":"starving","state":"hungry","accent":ours}],
			["Three bands stacked",{"side":"ours","glyph":"club","troops":14,"strength":0.9,"will":0.8,"supply":"well","state":"holding","members":3,"accent":ours}],
			["Selected, fed",{"side":"ours","glyph":"musket","troops":1240,"strength":0.7,"will":0.9,"supply":"well","state":"besieging","selected":true,"accent":ours}],
			["Their host, as seen",{"side":"theirs","glyph":"spear","low":90,"high":150,"will_low":0.4,"will_high":0.7,"state":"marching","accent":theirs}],
			["Old report",{"side":"theirs","glyph":"horse","low":30,"high":40,"stale":true,"state":"holding","accent":theirs}],
			["Rifles",{"side":"ours","glyph":"rifle","troops":3200,"strength":0.95,"will":0.75,"supply":"well","state":"fighting","accent":ours}],
			["Tanks",{"side":"ours","glyph":"tank","troops":800,"strength":0.6,"will":0.5,"supply":"strained","state":"marching","march_done":0.8,"days_left":2,"accent":ours}],
			["Combat frames",{"side":"ours","glyph":"combat_frame","troops":120,"strength":1.0,"will":1.0,"supply":"well","state":"holding","accent":ours}],
		]
		var font:=preload("res://scripts/hud/hud_tokens.gd").font("ui")
		for i in rows.size():
			var col:=i%3; var row:=i/3
			var centre:=Vector2(170+col*520,90+row*170)
			Counter.draw(self,centre,rows[i][1],1.0,1.0)
			Counter.draw(self,centre+Vector2(240,0),rows[i][1],0.85,1.0)
			draw_string(font,centre+Vector2(-80,48),String(rows[i][0]),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#2b2118"))
