extends RefCounted
## The war ledger's drawn marks, shared by the Feuds page (hud/war_ledger_
## board.gd) and the feud's card on the map (hud/war_map_overlay.gd), so a
## feud looks the same wherever it is read:
##   dead    two bars meeting at a middle line, ours to the left in our blue
##           and theirs to the right in their red, on one scale;
##   worn    how worn each people is, with the engine's turning points on
##           theirs (PEACE_WORN: they may seek peace; ENEMY_SPENT: their
##           raiders stay home);
##   quiet   the clock since blood was last spilled: hot until
##           FEUD_HOT_DAYS, simmering until FEUD_COLD_DAYS, then cold;
##   chip    HOT, SIMMERING, WAR or ENDED;
##   card    all of them together, for the map's pointer.
## Each draws into the rect it is given. Static helpers; preload.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const OURS:=Color("#3d7f9c")
const THEIRS:=Color("#a8463a")
const OCHRE:=Color("#a8782a")
const PAPER_TEXT:=Color("#f6efe1")
## Heights each mark wants at full size.
const DEAD_H:=36.0
const WORN_H:=50.0
const QUIET_H:=50.0
const WORN_LABEL_W:=56.0


## The dead scale's top: 10, 20, 50, 100, 200, 500 ... at or above the most
## dead, so a single death is a sliver, not a full bar.
static func nice(most:int)->int:
	var step:=10
	while step<most:
		if step*2>=most: return step*2
		if step*5>=most: return step*5
		step*=10
	return step


static func draw_dead(canvas:CanvasItem,rect:Rect2,ours:int,theirs:int,compact:=false)->void:
	var font:=T.font("ui_strong")
	var fs:=13 if compact else 16
	var bar_h:=10.0 if compact else 14.0
	var y:=rect.position.y+((rect.size.y-bar_h)*0.5 if compact else 3.0)
	var mid:=rect.position.x+rect.size.x*0.5
	var room:=font.get_string_size("0000",HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x+8.0
	var half:=maxf(10.0,rect.size.x*0.5-room)
	var top:=float(nice(maxi(ours,theirs)))
	var lw:=half*float(ours)/top; var rw:=half*float(theirs)/top
	canvas.draw_rect(Rect2(Vector2(mid-half,y),Vector2(half*2.0,bar_h)),Color(T.INK,0.07))
	if ours>0: canvas.draw_rect(Rect2(Vector2(mid-lw,y),Vector2(lw,bar_h)),OURS)
	if theirs>0: canvas.draw_rect(Rect2(Vector2(mid,y),Vector2(rw,bar_h)),THEIRS)
	canvas.draw_line(Vector2(mid,y-3.0),Vector2(mid,y+bar_h+3.0),T.INK,1.5)
	var lt:=EraWords.grouped(ours); var rt:=EraWords.grouped(theirs)
	var base:=y+bar_h*0.5+float(fs)*0.36
	canvas.draw_string(font,Vector2(mid-lw-6.0-font.get_string_size(lt,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x,base),lt,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,OURS.darkened(0.35))
	canvas.draw_string(font,Vector2(mid+rw+6.0,base),rt,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,THEIRS.darkened(0.25))
	if compact: return
	var small:=T.font("ui")
	canvas.draw_string(small,Vector2(mid-half,y+bar_h+16.0),"ours dead",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)
	var tw:=small.get_string_size("theirs dead",HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	canvas.draw_string(small,Vector2(mid+half-tw,y+bar_h+16.0),"theirs dead",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)


static func draw_worn(canvas:CanvasItem,rect:Rect2,ours:float,theirs:float,marks:bool)->void:
	var font:=T.font("ui"); var strong:=T.font("ui_strong")
	var x0:=rect.position.x+WORN_LABEL_W; var w:=maxf(20.0,rect.size.x-WORN_LABEL_W-48.0)
	for row:Array in [["theirs",theirs,THEIRS,22.0],["ours",ours,OURS,38.0]]:
		var y:=rect.position.y+float(row[3])
		var share:=clampf(float(row[1]),0.0,1.0)
		canvas.draw_string(font,Vector2(rect.position.x,y+9.0),String(row[0]),HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)
		canvas.draw_rect(Rect2(Vector2(x0,y),Vector2(w,10.0)),Color(T.INK,0.08))
		if share>0.0: canvas.draw_rect(Rect2(Vector2(x0,y),Vector2(w*share,10.0)),row[2])
		canvas.draw_rect(Rect2(Vector2(x0,y),Vector2(w,10.0)),Color(T.INK,0.45),false,1.0)
		canvas.draw_string(strong,Vector2(x0+w+8.0,y+10.0),"%d%%" % roundi(share*100.0),HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK)
	if not marks: return
	# The turning points on theirs, each word on the far side of its mark.
	var peace:=x0+w*WarLoop.PEACE_WORN; var spent:=x0+w*WarLoop.ENEMY_SPENT
	for at:float in [peace,spent]: canvas.draw_line(Vector2(at,rect.position.y+16.0),Vector2(at,rect.position.y+33.0),T.INK,1.5)
	var said:="may seek peace"; var sw:=font.get_string_size(said,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	canvas.draw_string(font,Vector2(peace-sw-3.0,rect.position.y+13.0),said,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK if theirs>=WarLoop.PEACE_WORN else T.INK_MUTED)
	canvas.draw_string(font,Vector2(spent+3.0,rect.position.y+13.0),"raiders stay home",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK if theirs>=WarLoop.ENEMY_SPENT else T.INK_MUTED)


static func draw_quiet(canvas:CanvasItem,rect:Rect2,quiet:int)->void:
	var font:=T.font("ui"); var strong:=T.font("ui_strong")
	var span:=float(WarLoop.FEUD_COLD_DAYS)
	var x0:=rect.position.x; var w:=maxf(40.0,rect.size.x-44.0); var y:=rect.position.y+20.0; var h:=10.0
	var hot_x:=x0+w*float(WarLoop.FEUD_HOT_DAYS)/span
	canvas.draw_rect(Rect2(Vector2(x0,y),Vector2(hot_x-x0,h)),Color(THEIRS,0.30))
	canvas.draw_rect(Rect2(Vector2(hot_x,y),Vector2(x0+w-hot_x,h)),Color(OCHRE,0.22))
	var now:=x0+w*clampf(float(quiet)/span,0.0,1.0)
	canvas.draw_rect(Rect2(Vector2(x0,y),Vector2(now-x0,h)),Color(T.INK,0.55))
	canvas.draw_rect(Rect2(Vector2(x0,y),Vector2(w,h)),Color(T.INK,0.45),false,1.0)
	canvas.draw_line(Vector2(hot_x,y-3.0),Vector2(hot_x,y+h+3.0),T.INK,1.5)
	# Today's pointer, with the days above it.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(now,y-1.0),Vector2(now-5.0,y-8.0),Vector2(now+5.0,y-8.0)]),T.INK)
	var days:=("today" if quiet<=0 else "%d days" % quiet) if quiet<99999 else "never"
	var dw:=strong.get_string_size(days,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	canvas.draw_string(strong,Vector2(clampf(now-dw*0.5,x0,x0+w-dw),y-10.0),days,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK)
	canvas.draw_string(font,Vector2(x0,y+h+15.0),"hot",HORIZONTAL_ALIGNMENT_LEFT,-1,12,THEIRS.darkened(0.2))
	canvas.draw_string(font,Vector2(hot_x+4.0,y+h+15.0),"simmering",HORIZONTAL_ALIGNMENT_LEFT,-1,12,OCHRE.darkened(0.3))
	canvas.draw_string(strong,Vector2(x0+w+6.0,y+h-1.0),"cold",HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK_MUTED)


## The chip's colour: oxblood for hot or war, ochre for a simmering feud,
## ink for ended.
static func chip_tone(word:String)->Color:
	match word.to_upper():
		"HOT","WAR": return THEIRS
		"SIMMERING": return OCHRE
	return T.INK_MUTED

static func chip_width(word:String)->float:
	return T.font("ui_strong").get_string_size(word.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+24.0

static func draw_chip(canvas:CanvasItem,rect:Rect2,word:String)->void:
	canvas.draw_rect(rect,chip_tone(word))
	var font:=T.font("ui_strong")
	var text:=word.to_upper()
	var w:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	canvas.draw_string(font,Vector2(rect.position.x+(rect.size.x-w)*0.5,rect.position.y+rect.size.y*0.5+5.0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,PAPER_TEXT)


## The feud's card for the map's pointer: emblem, name, chip, the line of
## what and how long, the dead, how worn, and (a feud) the quiet clock.
const CARD_PAD:=12.0

static func card_size(entry:Dictionary,width:float)->Vector2:
	var h:=CARD_PAD+40.0+6.0+DEAD_H+6.0+WORN_H
	if String(entry.get("kind",""))=="feud": h+=6.0+QUIET_H
	return Vector2(width,h+CARD_PAD)

static func draw_card(canvas:CanvasItem,origin:Vector2,entry:Dictionary,width:float,state_word:String,subtitle:String)->Rect2:
	var box:=Rect2(origin,card_size(entry,width))
	canvas.draw_rect(Rect2(box.position+Vector2(0,3),box.size),Color(0,0,0,0.16))
	canvas.draw_rect(box,T.PAPER_RAISED)
	canvas.draw_rect(Rect2(box.position,Vector2(4,box.size.y)),chip_tone(state_word))
	canvas.draw_rect(box,Color(chip_tone(state_word),0.85),false,1.5)
	var x:=box.position.x+CARD_PAD+4.0; var inner:=width-CARD_PAD*2.0-4.0
	var y:=box.position.y+CARD_PAD
	var emblem:=Identity.emblem(String(entry.get("civ_id","")))
	if emblem: canvas.draw_texture_rect(emblem,Rect2(Vector2(x,y),Vector2(36,36)),false)
	var chip_w:=chip_width(state_word)
	draw_chip(canvas,Rect2(Vector2(x+inner-chip_w,y+4.0),Vector2(chip_w,24.0)),state_word)
	var name_font:=T.font("voice")
	canvas.draw_string(name_font,Vector2(x+44.0,y+17.0),String(entry.get("name","")),HORIZONTAL_ALIGNMENT_LEFT,inner-52.0-chip_w,20,T.INK)
	canvas.draw_string(T.font("ui"),Vector2(x+44.0,y+35.0),subtitle,HORIZONTAL_ALIGNMENT_LEFT,inner-48.0,12,T.INK_MUTED)
	y+=46.0
	draw_dead(canvas,Rect2(Vector2(x,y),Vector2(inner,DEAD_H)),int(entry.get("our_dead",0)),int(entry.get("their_dead",0)))
	y+=DEAD_H+6.0
	draw_worn(canvas,Rect2(Vector2(x,y),Vector2(inner,WORN_H)),float(entry.get("our_worn",0.0)),float(entry.get("their_worn",0.0)),String(entry.get("kind",""))=="feud")
	y+=WORN_H+6.0
	if String(entry.get("kind",""))=="feud": draw_quiet(canvas,Rect2(Vector2(x,y),Vector2(inner,QUIET_H)),int(entry.get("quiet",0)))
	return box
