extends VBoxContainer
## A foreign city as the scouts brought it home: an inked sketch drawn only
## from returned estimates, their account in plain words, and each estimate
## drawn as an uncertainty band against the player's own settlement.
## Never reads the hidden city ledger; everything comes from the block.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const V:=preload("res://scripts/hud/city_report_visuals.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
const GROUPS:=[["THE PEOPLE",["population","life_expectancy","infant_mortality","education"]],["STRENGTH",["garrison","fortification","damage"]],["LIVELIHOOD",["gdp","science_capacity","production","logistics","supply"]]]
const CAPACITY:=["fortification","production","logistics","damage","science","health","education"]
const WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten"]
## The sketch inks itself in once per city, not on every daily refresh.
static var last_revealed:=""
var data:Dictionary
var sketch:Sketch

func setup(block:Dictionary)->void:
	data=block;name="CityDossier";add_theme_constant_override("separation",16)
	sketch=Sketch.new();sketch.data=block;add_child(sketch)
	if String(block.get("city_id",""))!=last_revealed:
		last_revealed=String(block.get("city_id",""))
		sketch.reveal=0.0
		if sketch.is_inside_tree():sketch.ink_in()
		else:sketch.ready.connect(sketch.ink_in,CONNECT_ONE_SHOT)
	if String(block.get("account",""))!="":
		var quote:=PanelContainer.new()
		var rule:=StyleBoxFlat.new();rule.bg_color=Color.TRANSPARENT;rule.border_color=T.GOLD;rule.border_width_left=2;rule.content_margin_left=14;rule.content_margin_top=2;rule.content_margin_bottom=2
		quote.add_theme_stylebox_override("panel",rule);add_child(quote)
		var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",6);quote.add_child(stack)
		var words:=Label.new();words.text=String(block.account);words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		T.text(words,"voice_small",T.BODY);words.add_theme_font_override("font",T.voice_font(true));stack.add_child(words)
		stack.add_child(T.text(Label.new(),"kicker",T.INK_MUTED))
		(stack.get_child(1) as Label).text="SOURCE · "+String(block.get("source","unknown")).to_upper()
	var unknown:Array[String]=[]
	var legend_shown:=false
	for group:Array in GROUPS:
		var shown:Array=[]
		for key:String in group[1]:
			var item:Dictionary=_item(key)
			if item.is_empty():continue
			if Dictionary(item.field).is_empty():unknown.append(String(item.name).get_slice(" · ",0));continue
			shown.append(item)
		if shown.is_empty():continue
		var head:=HBoxContainer.new();add_child(head)
		var kicker:=T.text(Label.new(),"kicker",T.INK_MUTED) as Label;kicker.text=String(group[0]);kicker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(kicker)
		if String(block.get("home_name",""))!="" and not legend_shown:
			legend_shown=true
			var legend:=T.text(Label.new(),"kicker",T.GOLD) as Label;legend.text="▮ "+String(block.home_name).to_upper();head.add_child(legend)
		var rows:=VBoxContainer.new();rows.add_theme_constant_override("separation",2);add_child(rows)
		for item:Dictionary in shown:rows.add_child(_row(item))
	if not unknown.is_empty():
		var note:=Label.new();note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		note.text="Not yet seen: %s. Scouts who watch longer or come closer can learn these." % ", ".join(PackedStringArray(unknown))
		T.text(note,"small",T.INK_MUTED);add_child(note)

func _item(key:String)->Dictionary:
	for item:Dictionary in data.get("items",[]):
		if String(item.get("key",""))==key:return item
	return {}

func _row(item:Dictionary)->Control:
	var row:=PanelContainer.new();row.mouse_filter=Control.MOUSE_FILTER_STOP;row.tooltip_text=String(item.get("tip",""))
	var idle:=StyleBoxFlat.new();idle.bg_color=Color.TRANSPARENT;idle.set_content_margin_all(8);idle.content_margin_left=4
	var lit:StyleBoxFlat=idle.duplicate();lit.bg_color=T.GOLD_WASH
	row.add_theme_stylebox_override("panel",idle)
	var key:=String(item.key)
	row.mouse_entered.connect(func()->void:row.add_theme_stylebox_override("panel",lit);sketch.highlight=key;sketch.queue_redraw())
	row.mouse_exited.connect(func()->void:row.add_theme_stylebox_override("panel",idle);if sketch.highlight==key:sketch.highlight="";sketch.queue_redraw())
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",12);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(line)
	var icon:=TextureRect.new();icon.texture=V.icon(key);icon.custom_minimum_size=Vector2(24,24);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(icon)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",4);body.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(body)
	var top:=HBoxContainer.new();top.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(top)
	var label:=T.text(Label.new(),"body",T.INK) as Label;label.text=String(item.name);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(label)
	var value:=T.text(Label.new(),"body",T.INK) as Label;value.text=String(item.value);value.add_theme_font_override("font",T.font("ui_strong"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(value)
	var bar:=Scale.new();bar.key=key;bar.field=item.field;bar.own=float(item.get("own",-1.0));bar.ink=V.COLORS.get(key,T.INK);body.add_child(bar)
	if String(item.get("own_text",""))!="":
		var home:=T.text(Label.new(),"kicker",T.INK_MUTED) as Label;home.text=String(item.own_text);home.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(home)
	return row

## Plain words for what was seen, measured against home. No maxims.
static func account(city:Dictionary,own:Dictionary,home:String,today:int)->String:
	var fields:Dictionary=city.get("fields",{})
	var lines:Array[String]=[]
	var pop:Dictionary=fields.get("population",{})
	if not pop.is_empty():
		var range:=V.bounds(pop)
		var count:="about %d people" % roundi(range.x) if roundi(range.x)==roundi(range.y) else "between %d and %d people" % [roundi(range.x),roundi(range.y)]
		var sentence:="Our scouts counted "+count
		var mine:=float(own.get("population",-1))
		if home!="" and mine>0:
			var middle:=(range.x+range.y)*.5
			sentence+=", "+("fewer than live in " if middle<mine*.6 else "more than live in " if middle>mine*1.6 else "about as many as live in ")+home
		lines.append(sentence+".")
	var infants:Dictionary=fields.get("infant_mortality",{})
	var life:Dictionary=fields.get("life_expectancy",{})
	if not infants.is_empty():
		var tenths:=clampi(roundi(float((V.bounds(infants).x+V.bounds(infants).y)*.5)/100.0),0,10)
		lines.append("Nearly all their children live past infancy." if tenths==0 else "%s of every ten children born there die before they can walk." % String(WORDS[tenths]).capitalize())
	elif not life.is_empty():
		lines.append("Few of them live past %d." % roundi(V.bounds(life).y))
	var walls:Dictionary=fields.get("fortification",{})
	if not walls.is_empty():
		var high:=V.bounds(walls).y
		lines.append("They have no wall worth the name." if high<=.1 else "A low palisade rings the houses." if high<=.4 else "Their walls are high and kept in good repair.")
	var armed:Dictionary=fields.get("garrison",{})
	if not armed.is_empty():lines.append("Perhaps %s of them carry arms." % V.estimate("garrison",armed))
	var damage:Dictionary=fields.get("damage",{})
	if not damage.is_empty() and V.bounds(damage).y>=.2:lines.append("Some houses stood burned or broken.")
	var fresh:=V.freshness(city,today)
	var seen:=int(city.get("observed_day",-1))
	if seen>=0 and int(fresh.level)<=4:
		lines.append("That was %s%s" % [ago(today-seen),"; much may have changed since." if int(fresh.level)<=2 else "."])
	return " ".join(lines)

static func ago(days:int)->String:
	if days<=1:return "yesterday" if days==1 else "today"
	if days<45:return "%d days ago" % days
	if days<330:return "about %s months ago" % _count(roundi(days/30.0))
	if days<540:return "about a year ago"
	return "about %s years ago" % _count(roundi(days/365.0))

static func _count(value:int)->String:return String(WORDS[value]) if value<WORDS.size() else str(value)

## One estimate: an ink band from low to high, with a gold mark for home.
class Scale extends Control:
	var key:=""
	var field:Dictionary={}
	var own:=-1.0
	var ink:=T.INK
	func _init()->void:
		custom_minimum_size.y=12;mouse_filter=MOUSE_FILTER_IGNORE
	func _draw()->void:
		var range:=V.bounds(field)
		var top:=1.0 if key in CAPACITY else maxf(1.0,maxf(range.y,own)*1.25)
		var mid:=size.y*.5
		draw_line(Vector2(0,mid),Vector2(size.x,mid),T.RULE,1.0)
		for tick in 5:draw_line(Vector2(size.x*tick/4.0,mid-2),Vector2(size.x*tick/4.0,mid+2),T.RULE,1.0)
		var a:=clampf(range.x/top,0,1)*size.x;var b:=clampf(range.y/top,0,1)*size.x
		var band:=Color(ink,.55)
		if b-a<4:
			draw_circle(Vector2((a+b)*.5,mid),3.5,band)
		else:
			draw_rect(Rect2(a,mid-3,b-a,6),band)
			draw_circle(Vector2(a,mid),3,band);draw_circle(Vector2(b,mid),3,band)
		draw_line(Vector2((a+b)*.5,mid-4),Vector2((a+b)*.5,mid+4),T.INK,1.0)
		if own>=0:
			var x:=clampf(own/top,0,1)*size.x
			draw_line(Vector2(x,0),Vector2(x,size.y),T.GOLD,2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x-3.5,0),Vector2(x+3.5,0),Vector2(x,4)]),T.GOLD)

## The settlement as the scouts might have drawn it. Houses follow the
## population estimate; the palisade, smoke, road, granary and spears appear
## only for the things they actually saw.
class Sketch extends Control:
	var data:Dictionary={}
	var highlight:=""
	var reveal:=1.0:
		set(value):reveal=value;queue_redraw()
	func _init()->void:
		custom_minimum_size.y=188;mouse_filter=MOUSE_FILTER_IGNORE;clip_contents=true
	func ink_in()->void:
		create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(self,"reveal",1.0,Motion.duration(Motion.SCENE))
	func _field(key:String)->Dictionary:return data.get("fields",{}).get(key,{})
	func _mid(key:String)->float:
		var range:=V.bounds(_field(key));return (range.x+range.y)*.5
	func _stroke(key:String,base:Color)->Color:return T.GOLD if highlight==key else base
	func _draw()->void:
		var w:=size.x;var h:=size.y
		draw_style_box(T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CARD),Rect2(Vector2.ZERO,size))
		var rng:=RandomNumberGenerator.new();rng.seed=hash(String(data.get("city_id","")))
		var ground:=h*.70
		# Two far ridges, washed and inked.
		for layer in 2:
			var ridge:=PackedVector2Array();var base_y:=h*(.34+layer*.13);var phase:=rng.randf()*TAU
			for step in 33:
				var x:=w*step/32.0
				ridge.append(Vector2(x,base_y+sin(x/w*TAU*(1.3+layer*.7)+phase)*h*.06+sin(x/w*TAU*4.1+phase*2.0)*h*.015))
			var fill:=ridge.duplicate();fill.append(Vector2(w,ground));fill.append(Vector2(0,ground))
			draw_colored_polygon(fill,Color(T.RULE,.16+layer*.10))
			draw_polyline(ridge,Color(T.RULE_STRONG,.55+layer*.2),1.2,true)
		draw_line(Vector2(10,ground),Vector2(w-10,ground),Color(T.INK,.55),1.2,true)
		# A few strokes of grass along the ground, as a hand would add them.
		var grass:=RandomNumberGenerator.new();grass.seed=rng.seed^31
		for i in 26:
			var gx:=grass.randf_range(14,w-14);var gy:=ground+grass.randf_range(4,h*.26)
			draw_line(Vector2(gx,gy),Vector2(gx-2,gy-4),Color(T.INK_MUTED,.30),1.0,true);draw_line(Vector2(gx+3,gy),Vector2(gx+4,gy-5),Color(T.INK_MUTED,.30),1.0,true)
		var cx:=w*.56;var spread:=w*.13
		# The road in, when carrying capacity was seen.
		if not _field("logistics").is_empty():
			var road:=PackedVector2Array()
			for step in 13:
				var t:=step/12.0
				road.append(Vector2(lerpf(cx-spread*.4,w*.04,t),lerpf(ground+3,h-4,t)+sin(t*PI)*10))
			var width:=1.2+_mid("logistics")*3.0
			for i in range(0,road.size()-1,2):draw_line(road[i],road[i+1],_stroke("logistics",Color(T.INK,.6)),width,true)
		# Houses: the likely count in ink, the possible extra in faint pencil.
		var pop:=V.bounds(_field("population"))
		var sure:=clampi(roundi(sqrt(maxf(pop.x,1))*1.6),2,30) if not _field("population").is_empty() else 6
		var maybe:=clampi(roundi(sqrt(maxf(pop.y,1))*1.6),sure,34) if not _field("population").is_empty() else 6
		var broken:=int(round(sure*clampf(_mid("damage")*1.6,0,.6))) if not _field("damage").is_empty() else 0
		var houses:Array=[]
		for i in maybe:
			var depth:=rng.randf()
			houses.append({"x":clampf(cx+rng.randfn(0,1)*spread*(1.0+depth*.5),w*.14,w*.84),"y":ground-4-depth*h*.22,"s":lerpf(13,7,depth),"sure":i<sure,"broken":i<broken,"order":i})
		houses.sort_custom(func(p:Dictionary,q:Dictionary)->bool:return float(p.y)<float(q.y))
		var shown:=int(ceil(reveal*maybe))
		for house:Dictionary in houses:
			if int(house.order)>=shown:continue
			_house(house)
		# Workshop smoke over a few roofs.
		if not _field("production").is_empty():
			var fires:=clampi(1+roundi(_mid("production")*5),1,5)
			for i in mini(fires,houses.size()):
				var house:Dictionary=houses[houses.size()-1-i*2 % houses.size()]
				var curl:=PackedVector2Array()
				for step in 10:curl.append(Vector2(float(house.x)+sin(step*.9+i)*4+step*1.6,float(house.y)-float(house.s)*2.1-step*4.2))
				draw_polyline(curl,_stroke("production",Color(T.INK_MUTED,.45*reveal)),1.4,true)
		# The granary, when food stores were judged.
		if not _field("supply").is_empty():
			var gx:=cx+spread*2.1;var r:=9.0
			draw_circle(Vector2(gx,ground-r),r,T.PAPER_RAISED);draw_arc(Vector2(gx,ground-r),r,0,TAU,24,_stroke("supply",T.INK),1.2,true)
			draw_colored_polygon(PackedVector2Array([Vector2(gx-r-3,ground-r),Vector2(gx,ground-r*2.9),Vector2(gx+r+3,ground-r)]),Color(T.AMBER,.45))
			draw_polyline(PackedVector2Array([Vector2(gx-r-3,ground-r),Vector2(gx,ground-r*2.9),Vector2(gx+r+3,ground-r)]),_stroke("supply",T.INK),1.2,true)
		# The palisade or wall across the front.
		if not _field("fortification").is_empty():
			var strength:=_mid("fortification");var left:=cx-spread*2.2;var right:=cx+spread*1.7
			if strength>.55:
				var top:=ground+8-10-strength*8
				draw_rect(Rect2(left,top,right-left,ground+8-top),Color(T.PAPER_RAISED,.9));draw_rect(Rect2(left,top,right-left,ground+8-top),_stroke("fortification",T.INK),false,1.2)
				var x:=left
				while x<right-8:draw_rect(Rect2(x,top-5,8,5),_stroke("fortification",T.INK),false,1.2);x+=16
			else:
				var stakes:=int((right-left)/5.0);var cover:=clampf(strength*1.8+.06,.06,1.0);var tall:=8.0+strength*20.0
				var gaps:=RandomNumberGenerator.new();gaps.seed=rng.seed^77
				for i in stakes:
					if gaps.randf()>cover:continue
					var x:=left+i*5.0;var y:=ground+9
					draw_line(Vector2(x,y),Vector2(x+gaps.randf_range(-.8,.8),y-tall*gaps.randf_range(.8,1.1)),_stroke("fortification",Color(T.INK,.8)),1.4,true)
		# Spears at the gate for those seen under arms.
		if not _field("garrison").is_empty():
			var count:=clampi(roundi(sqrt(_mid("garrison"))),1,12);var gx:=cx-spread*2.9
			for i in count:
				var x:=gx-i*5.0;var y:=ground+14-(i%2)*3
				draw_line(Vector2(x,y),Vector2(x,y-22),_stroke("garrison",T.INK),1.2,true)
				draw_colored_polygon(PackedVector2Array([Vector2(x-2,y-22),Vector2(x,y-28),Vector2(x+2,y-22)]),_stroke("garrison",T.INK))
		# Old news fades like old ink.
		var level:=int(data.get("fresh_level",5))
		if level<=4:draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),Color(T.PAPER_SUNK,.10 if level>=3 else .30))
		_stamp(level)
		var caption:=String(data.get("caption",""))
		if caption!="":draw_string(T.font("ui_strong"),Vector2(14,h-14),caption.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,w*.6,12,T.INK_MUTED)
	func _house(house:Dictionary)->void:
		var x:=float(house.x);var y:=float(house.y);var s:=float(house.s)
		var sure:=bool(house.sure)
		var line:=_stroke("population",Color(T.INK,.9 if sure else .28))
		if not sure:line=Color(line,.35) if highlight=="population" else line
		var body:=Rect2(x-s,y-s*.9,s*2,s*.9)
		if sure:draw_rect(body,T.PAPER_RAISED)
		draw_rect(body,line,false,1.1)
		var eave_l:=Vector2(x-s*1.25,y-s*.9);var eave_r:=Vector2(x+s*1.25,y-s*.9);var peak:=Vector2(x,y-s*2.0)
		if bool(house.broken) and sure:
			var fall:=Vector2(x+s*.2,y-s*1.25)
			draw_colored_polygon(PackedVector2Array([eave_l,peak,fall]),Color(T.INK,.30))
			draw_polyline(PackedVector2Array([eave_l,peak,fall]),_stroke("damage",line),1.1,true)
			draw_circle(Vector2(x+s*.5,y-s*.4),s*.55,Color(T.INK,.16))
			return
		if sure:draw_colored_polygon(PackedVector2Array([eave_l,peak,eave_r]),Color(T.AMBER,.38))
		draw_polyline(PackedVector2Array([eave_l,peak,eave_r,eave_l]),line,1.1,true)
		if sure:draw_line(Vector2(x,y),Vector2(x,y-s*.5),Color(T.INK,.7),1.0)
	func _stamp(level:int)->void:
		var status:=String(data.get("fresh_status",""))
		if status=="":return
		var tone:=T.TEAL if level==5 else T.AMBER if level>=3 else T.RED
		var font:=T.font("display");var small:=T.font("ui_strong")
		var width:=maxf(font.get_string_size(status.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,18).x,small.get_string_size(String(data.get("fresh_age","")),HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)+20
		draw_set_transform(Vector2(size.x-width*.5-18,34),-.12)
		var box:=Rect2(-width*.5,-20,width,40);var ink:=Color(tone,.8)
		draw_rect(box,ink,false,2.0);draw_rect(box.grow(-3),Color(tone,.45),false,1.0)
		draw_string(font,Vector2(-width*.5,2),status.to_upper(),HORIZONTAL_ALIGNMENT_CENTER,width,18,ink)
		draw_string(small,Vector2(-width*.5,15),String(data.get("fresh_age","")),HORIZONTAL_ALIGNMENT_CENTER,width,12,ink)
		draw_set_transform(Vector2.ZERO)
