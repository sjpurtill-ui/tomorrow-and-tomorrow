extends "res://scripts/hud/settlement_overview.gd"
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const PAGE_SIZE:=6
var page:=0
var records:VBoxContainer
var page_label:Label
var previous:Button
var next:Button
func setup(block:Dictionary)->void:
	data=block;name="SettlementChronicle";add_theme_constant_override("separation",12)
	var controls:=HBoxContainer.new();add_child(controls)
	page_label=T.make_label("",12,T.MUTED);page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_child(page_label)
	previous=Button.new();previous.text="Newer";previous.pressed.connect(func():page-=1;_page());controls.add_child(previous)
	next=Button.new();next.text="Older";next.pressed.connect(func():page+=1;_page());controls.add_child(next)
	records=VBoxContainer.new();records.add_theme_constant_override("separation",14);add_child(records);_page()
func _page()->void:
	for child in records.get_children():records.remove_child(child);child.queue_free()
	var events:Array=data.events
	page=clampi(page,0,maxi(0,(events.size()-1)/PAGE_SIZE))
	var start:=page*PAGE_SIZE;var end:=mini(events.size(),start+PAGE_SIZE)
	page_label.text="%d–%d of %d recorded events" % [start+1,end,events.size()] if not events.is_empty() else "No events recorded yet"
	previous.disabled=page==0;next.disabled=end>=events.size()
	for i in range(start,end):
		var event:Dictionary=events[i]
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);records.add_child(row)
		var date:=VBoxContainer.new();date.custom_minimum_size.x=72;row.add_child(date)
		date.add_child(_serif("%d" % (int(event.day)/365+1),24));date.add_child(T.make_label("Year · day %d" % (posmod(int(event.day),365)+1),10,T.MUTED))
		var picture:=TextureRect.new();picture.custom_minimum_size=Vector2(104,92);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture=Buildings.texture(int(event.get("art",0))) if event.kind in ["Founding","Building"] else Visuals.for_discovery(event)
		if picture.texture==null:picture.texture=Visuals.art("knowledge")
		row.add_child(picture)
		var description:=VBoxContainer.new();description.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(description)
		description.add_child(T.make_label(String(event.kind).to_upper()+" · "+String(event.scope),10,T.GOLD))
		description.add_child(_serif(String(event.title),20));_note(description,String(event.get("description","")))
		_rule(records)
