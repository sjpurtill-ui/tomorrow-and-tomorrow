extends Control
## Visual check of the guard badge on our towns' name tags: those keeping
## watch, then in lighter ink "+N" townsfolk who would rise, and the badge's
## hover words over an open card. Run only through
## tools/run_isolated_gpu_probe.ps1:
##   res://tests/town_badge_capture.tscn -- --out=<png path>
## Draws the real label layer (scripts/hud/city_labels.gd) on plain chart
## paper at twice the size, with the player's case: two on watch at home.
## No map, no save.
const Labels:=preload("res://scripts/hud/city_labels.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

func _ready()->void:
	var out:=""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):out=argument.trim_prefix("--out=")
	get_tree().root.content_scale_factor=2.0
	await get_tree().process_frame
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var paper:=ColorRect.new();paper.color=T.PAPER;paper.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(paper)
	var layer:Control=Labels.new();add_child(layer)
	var screen:=Rect2(Vector2.ZERO,get_viewport_rect().size)
	layer.last_bounds=screen
	# Top: the two name tags at rest. Below: Ashfire open, its badge's words.
	var towns:=[["ashfire","Ashfire",2,5,2,Vector2(120,90)],["seanfire","Seanfire",0,3,0,Vector2(420,90)],["ashfire_open","Ashfire",2,5,2,Vector2(120,200)]]
	var cards:Array[Dictionary]=[]
	for town:Array in towns:
		var label:=Label3D.new();label.text="%s  •  %d" % [town[1],60 if town[2]>0 else 34]
		var card:Dictionary=Labels._measure_card(label,{},false,"Seanfolk",false,T.voice_font(),screen,{},String(town[0]),{"watch":town[2],"rise":town[3],"bands":town[4]})
		label.free()
		var at:Vector2=town[5]
		var rect:=Rect2(at,Vector2(float(card.name_width),float(card.lines.size())*20+10))
		card.merge({"id":String(town[0]),"kind":"city","compact":true,"rect":rect,"anchor":Vector2(rect.get_center().x,rect.end.y+8),"detail_extent":card.detail,
			"population":card.count,"affiliation":"Seanfolk","color":T.GOLD,"flag":null,"clearance":8.0},true)
		# As refresh lays it out: a town of ours carries no scout summary.
		card.erase("summary")
		cards.append(card)
	layer.cards=cards
	layer.pinned_id="ashfire_open"
	layer.badge_hover_id="ashfire_open";layer.badge_elapsed=1.0
	for frame in 8:await get_tree().process_frame
	layer.queue_redraw()
	for frame in 4:await get_tree().process_frame
	RenderingServer.force_draw(true,0.0)
	await get_tree().process_frame
	if out!="" and DisplayServer.get_name()!="headless":
		var image:=get_viewport().get_texture().get_image()
		if image:image.save_png(out)
	print("TOWN BADGE CAPTURE -> ",out)
	get_tree().quit()
