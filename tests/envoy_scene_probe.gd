extends "res://tests/audience_modal_probe.gd"
## The envoy audience as a scene: a foreign people offers a prehistoric piece
## with a hunting string. Checks the plain object name, the one-sentence
## business line, full-text answer cards, the popovers and the fit. Windowed
## (tools/run_isolated_gpu_probe.ps1) it writes captures to res://reports/audience/.
##   <godot> --headless --path <worktree> res://tests/envoy_scene_probe.tscn

const ART:=preload("res://scripts/artifact_collection.gd")
const PREHISTORY:=preload("res://scripts/prehistoric_artifacts.gd")

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	out_dir=ProjectSettings.globalize_path("res://reports/audience/")
	if capture:DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	if capture:
		get_window().size=Vector2i(1920,1080);get_window().content_scale_size=Vector2i(1920,1080)
		await _frames(2)
	_check_names()
	for mode in (["dark","light"] if capture else ["light"]):
		HudTokens.set_color_mode(mode)
		await _exercise_artifact_gift(director,mode,"rival_a" if mode=="dark" or not capture else "rival_b")
	await _exercise_threat(director)
	if failures.is_empty():
		print("ENVOY_SCENE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:printerr("ENVOY_SCENE FAIL: ",failure)
		get_tree().quit(1)

func _check_names()->void:
	## Every catalogue piece has a short plain name, whatever its variation.
	for id in [210,210+123*3,5,4095]:
		var item:=PREHISTORY.definition(id)
		if item.is_empty():continue
		var plain:=ART.plain_name(item)
		if plain.is_empty() or plain.contains(" · ") or plain.length()>32 or plain.begins_with("the "):_fail("catalogue %d has no plain name: '%s' (from '%s')" % [id,plain,item.get("name","")])
		print("ENVOY_SCENE name %d: '%s' -> '%s' / %s" % [id,item.get("name",""),plain,ART.plain_label(item)])
	var toggle:=PREHISTORY.definition(210)
	if ART.plain_name(toggle)!="carved bone toggle":_fail("the bone that held a cord end is not a carved bone toggle: %s" % ART.plain_name(toggle))

func _exercise_artifact_gift(director:Node,mode:String,giver:String)->void:
	# The giver's own view of our people, as projections build it in play.
	WorldSimulation.scoped(giver,func()->void:
		for civ in WorldSimulation.world.civilizations:
			if String(civ.get("id",""))=="human":return
		WorldSimulation.world.civilizations.append({"id":"human","name":"Home","player_relation":{"at_war":false}}))
	var piece:=ART.find_at(777,Vector2(4000+randi()%1000,100),1)
	var variant:Dictionary={}
	for key in PREHISTORY.experiments:
		if String(PREHISTORY.experiments[key].get("name","")).begins_with("The bone that held a cord end · "):variant=PREHISTORY.experiments[key];break
	piece.merge(variant,true);piece.rarity=0
	WorldSimulation.scoped(giver,func()->void:WorldSimulation.state.society_exchange.collections[piece.id]=piece)
	var audience:=Hall.debug_situation("artifact_gift",giver)
	if audience.is_empty():_fail("artifact gift was not raised");return
	var id:=String(audience.id)
	# Pin the string to the hunting bargain the player saw.
	var situation:Dictionary=Hall.find(id).situation
	situation["string"]={"type":"hunting","text":"In return their hunters want to hunt in your river bend for two winters, about 2 food a month.","place":"river bend","monthly":2.0}
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	var business:=modal.find_child("Business",true,false) as Label
	if business==null:_fail("no business sentence");return
	print("ENVOY_SCENE business: ",business.text)
	if not "carved bone toggle" in business.text:_fail("business line lacks the plain name: %s" % business.text)
	if " · " in business.text or "(common)" in business.text or "working contact" in business.text:_fail("business line leaks catalogue words: %s" % business.text)
	var name_label:=modal.find_child("OfferName",true,false) as Label
	if name_label==null or name_label.text!="Carved bone toggle":_fail("offer plinth name: %s" % (name_label.text if name_label else "-"))
	var picture:=modal.find_child("OfferPicture",true,false) as TextureRect
	if picture==null or picture.texture==null:_fail("the offered piece is not shown")
	var cards:Array=modal.options_row.get_children()
	if cards.size()<3 or cards.size()>4:_fail("expected 3-4 answer cards, got %d" % cards.size())
	for option_card in cards:
		for label in option_card.find_children("*","Label",true,false):
			var l:=label as Label
			if l.clip_text or l.text_overrun_behavior!=TextServer.OVERRUN_NO_TRIMMING or l.max_lines_visible>=0:_fail("card text can be cut: %s" % l.text)
		var line:=option_card.find_child("OptionConsequence",true,false) as Label
		print("ENVOY_SCENE card: %s — %s" % [String((option_card.find_child("OptionTitle",true,false) as Label).text),line.text if line else "-"])
	var accept:Node=modal.options_row.find_child("Option_accept",true,false)
	var accept_line:=accept.find_child("OptionConsequence",true,false) as Label if accept else null
	if accept_line==null or not ("We keep the carved bone toggle" in accept_line.text and "48" in accept_line.text):_fail("accept card does not say what it costs: %s" % (accept_line.text if accept_line else "-"))
	var shown:int=modal.speech_box.get_child_count()
	for line in Hall.find(id).lines:print("ENVOY_SCENE line %s: %s" % [String(line.get("role","")),String(line.get("text",""))])
	if shown<1 or shown>3:_fail("scene shows %d spoken lines" % shown)
	if modal.transcript.get_child_count()<(Hall.find(id).lines as Array).size():_fail("full transcript not kept behind 'What was said'")
	if modal.find_child("VoiceIndicator",true,false)==null or modal.find_child("AudienceFrequency",true,false)==null or modal.find_child("MakeThemWait",true,false)==null:_fail("settings menu lacks its controls")
	if (modal.find_child("CourtSettings",true,false) as Control).visible:_fail("settings menu should start closed")
	if not get_viewport().get_visible_rect().encloses(modal.card.get_global_rect()):_fail("card escapes the viewport %s" % modal.card.get_global_rect())
	if modal.card.size.y>modal.DESIGN_SIZE.y+1.0:_fail("card grew past its design height: %s" % modal.card.size)
	var veil:=modal.find_child("Veil",true,false) as Control
	var stage:=modal.find_child("EnvoyStage",true,false) as Control
	print("ENVOY_SCENE layout card=%s stage=%s veil=%s" % [modal.card.size,stage.size if stage else Vector2.ZERO,veil.size if veil else Vector2.ZERO])
	if capture:await _capture("envoy-artifact-%s-scene" % mode)
	modal.toggle_popover("WhatYouKnow")
	await _frames(2)
	var dossier:=modal.find_child("WhatYouKnow",true,false) as Control
	if dossier==null or not dossier.visible:_fail("'What you know' did not open")
	elif not modal.card.get_global_rect().encloses(dossier.get_global_rect()):_fail("'What you know' spills out of the card")
	if capture and mode=="light":await _capture("envoy-artifact-%s-dossier" % mode)
	modal.toggle_popover("WhatWasSaid")
	await _frames(2)
	if dossier and dossier.visible:_fail("popovers are not exclusive")
	if capture and mode=="light":await _capture("envoy-artifact-%s-said" % mode)
	modal.toggle_popover("WhatWasSaid")
	var result:Dictionary=modal.choose("accept")
	if not bool(result.get("ok",false)):_fail("accept failed: %s" % result)
	await _frames(3)
	if capture and mode=="light":await _capture("envoy-artifact-%s-resolved" % mode)
	print("ENVOY_SCENE %s outcome: %s" % [mode,String(result.get("outcome",""))])
	var dismiss:=modal.find_child("Dismiss",true,false) as Button
	if dismiss:dismiss.pressed.emit()
	await _frames(2)

func _exercise_threat(director:Node)->void:
	## A demand for goods: the goods themselves stand in the scene.
	HudTokens.set_color_mode("dark")
	var audience:=Hall.debug_force("threat")
	if audience.is_empty():_fail("threat was not raised");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	var name_label:=modal.find_child("OfferName",true,false) as Label
	if name_label==null or name_label.text.is_empty():_fail("the demanded goods are not shown")
	var business:=modal.find_child("Business",true,false) as Label
	print("ENVOY_SCENE threat business: ",business.text if business else "-")
	for option_card in modal.options_row.get_children():
		var line:=option_card.find_child("OptionConsequence",true,false) as Label
		print("ENVOY_SCENE threat card: %s — %s" % [String((option_card.find_child("OptionTitle",true,false) as Label).text),line.text if line else "-"])
	if modal.card.size.y>modal.DESIGN_SIZE.y+1.0:_fail("threat card grew past its design height: %s" % modal.card.size)
	if capture:await _capture("envoy-threat-dark-scene")
	modal.make_them_wait()
	await _frames(2)
