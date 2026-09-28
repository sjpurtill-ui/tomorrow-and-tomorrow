extends VBoxContainer
## A town we hold, as our garrison knows it (scripts/held_town.gd): the town
## drawn with our banner at its gate, one plain opening line, then the facts
## in short sections. No report age, no ranges, no scouts: our own people
## are there, so every figure is today's.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const V:=preload("res://scripts/hud/city_report_visuals.gd")
const Dossier:=preload("res://scripts/hud/city_dossier.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
var data:Dictionary
var sketch:HeldSketch

func setup(block:Dictionary)->void:
	data=block;name="HeldTownDossier";add_theme_constant_override("separation",14)
	var report:Dictionary=block.get("report",{})
	sketch=HeldSketch.new();sketch.data=sketch_data(report,String(block.get("caption","")));add_child(sketch)
	var quote:=PanelContainer.new();quote.name="Lead"
	var rule:=StyleBoxFlat.new();rule.bg_color=Color.TRANSPARENT;rule.border_color=T.GOLD;rule.border_width_left=2;rule.content_margin_left=14;rule.content_margin_top=2;rule.content_margin_bottom=2
	quote.add_theme_stylebox_override("panel",rule);add_child(quote)
	var words:=Label.new();words.text=String(report.get("lead",""));words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	T.text(words,"voice_small",T.BODY);words.add_theme_font_override("font",T.voice_font(true));quote.add_child(words)
	var facts:Dictionary=report.get("facts",{})
	_section("THE TOWN",[
		{"key":"population","name":"People","value":EraWords.grouped(int(report.get("residents",0))),"text":String(facts.get("population",""))},
		{"key":"fortification","name":"Walls","value":"","text":String(facts.get("fortification",""))},
		{"key":"damage","name":"Damage","value":"","text":String(facts.get("damage",""))}])
	var happened:Array=[]
	for line in report.get("happened",[]):happened.append({"key":"events","name":"","value":"","text":String(line)})
	_section("WHAT HAPPENED THERE",happened)
	_section("OUR GARRISON",[
		{"key":"garrison","name":"Holding it" if String(report.get("commander",""))=="" else "%s's fighters" % String(report.commander).get_slice(" ",0),"value":EraWords.grouped(int(report.get("garrison",0))),"text":String(facts.get("garrison",""))},
		{"key":"supply","name":"Their food","value":"","text":String(facts.get("supply",""))}])
	_section("HOW THEY TAKE OUR RULE",[
		{"key":"mood","name":"Our rule","value":String(report.get("rule","")),"text":String(facts.get("resistance",""))}])

## The vignette's inputs: our exact figures as zero-width "ranges", no stamp.
static func sketch_data(report:Dictionary,caption:String)->Dictionary:
	var exact:=func(value:float)->Dictionary:return {"low":value,"high":value,"observed_low":value,"observed_high":value}
	var fields:={"population":exact.call(float(report.get("residents",0))),"fortification":exact.call(float(report.get("walls",0.0))),"damage":exact.call(float(report.get("damage",0.0)))}
	if int(report.get("garrison",0))>0:fields["garrison"]=exact.call(float(report.garrison))
	return {"city_id":String(report.get("city_id","")),"fields":fields,"fresh_level":5,"fresh_status":"","caption":"","held_caption":caption}

func _section(title:String,rows:Array)->void:
	var shown:=rows.filter(func(row:Dictionary)->bool:return String(row.text)!="")
	if shown.is_empty():return
	var kicker:=T.text(Label.new(),"kicker",T.INK_MUTED) as Label;kicker.text=title;add_child(kicker)
	var list:=VBoxContainer.new();list.add_theme_constant_override("separation",2);add_child(list)
	for row:Dictionary in shown:list.add_child(_row(row))

func _row(row:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var idle:=StyleBoxFlat.new();idle.bg_color=Color.TRANSPARENT;idle.set_content_margin_all(6);idle.content_margin_left=4
	var lit:StyleBoxFlat=idle.duplicate();lit.bg_color=T.GOLD_WASH
	panel.add_theme_stylebox_override("panel",idle)
	var key:=String(row.key)
	panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",lit);sketch.highlight=key;sketch.queue_redraw())
	panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",idle);if sketch.highlight==key:sketch.highlight="";sketch.queue_redraw())
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",12);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(line)
	var icon:=TextureRect.new();icon.texture=V.icon(key);icon.custom_minimum_size=Vector2(22,22);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(icon)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",2);body.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(body)
	if String(row.name)!="":
		var top:=HBoxContainer.new();top.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(top)
		var label:=T.text(Label.new(),"body",T.INK) as Label;label.text=String(row.name);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(label)
		if String(row.value)!="":
			var value:=T.text(Label.new(),"body",T.INK) as Label;value.name="Value";value.text=String(row.value);value.add_theme_font_override("font",T.font("ui_strong"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(value)
	var text:=T.text(Label.new(),"small" if String(row.name)!="" else "body",T.BODY) as Label
	text.name="Fact";text.text=String(row.text);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(text)
	return panel

## The town as the scouts' sketch draws it, but with our banner at the gate
## and our fighters' spears in gold.
class HeldSketch extends Dossier.Sketch:
	func _stroke(key:String,base:Color)->Color:
		if key=="garrison":return T.GOLD
		return super(key,base)
	func _draw()->void:
		super()
		var w:=size.x;var h:=size.y
		var ground:=h*.70;var cx:=w*.56;var spread:=w*.13
		var x:=cx-spread*2.9+8.0
		if x<18.0:x=18.0
		var top:=ground-h*.52
		draw_line(Vector2(x,ground+14),Vector2(x,top),T.INK,1.6,true)
		var emblem:Texture2D=Identity.emblem("player") if Engine.get_main_loop()!=null else null
		var flag:=Rect2(Vector2(x+1,top),Vector2(34,30))
		draw_rect(flag,T.PAPER_RAISED)
		if emblem!=null:draw_texture_rect(emblem,flag.grow(-2),false)
		draw_rect(flag,T.GOLD,false,1.2)
		# Who holds it, as the map card says it, across the whole foot of the sketch.
		var caption:=String(data.get("held_caption",""))
		if caption!="":
			var band:=Rect2(Vector2(1,h-26),Vector2(w-2,25))
			draw_rect(band,Color(T.PAPER_SUNK,.92))
			draw_string(T.font("ui_strong"),Vector2(12,h-9),caption,HORIZONTAL_ALIGNMENT_LEFT,w-24,12,T.GOLD_TEXT)
