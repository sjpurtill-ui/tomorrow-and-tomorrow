extends RefCounted
## Authored close-view architecture. Inputs are immutable design identities;
## dimensions below are metres, returned pieces use the map's kilometre units.
## One bounded triangle batch per material/pass, never one node per detail.
const Map:=preload("res://scripts/undertaking_map_visual.gd")
const FORMS:Array[String]=["ring","mound","stair","tower","hall","cistern","granary","bridge","causeway","dam","colossus","garden","observatory","gate","canal","archive","amphitheatre","lighthouse"]
const LEGACIES:Array[String]=["ancestor_ring","great_hall","rain_court","flood_terraces","star_steps","kiln_court","long_song","common_stores","safe_passage","living_orchard","stone_crown","measures_house"]
const WOOD:=Color("786047")
const LEAF:=Color("536b49")
const DARK:=Color("4f514b")
const WATER:=Color("628c95")
static var _units:Dictionary={}

static func pieces(design:Dictionary)->Array:
	var b:=Builder.new(design)
	var key:=String(design.get("design_id",""))
	if key.begins_with("legacy:"):
		match key.trim_prefix("legacy:"):
			"ancestor_ring":b.ancestor_ring()
			"great_hall":b.great_hall()
			"rain_court":b.rain_court()
			"flood_terraces":b.flood_terraces()
			"star_steps":b.star_steps()
			"kiln_court":b.kiln_court()
			"long_song":b.long_song()
			"common_stores":b.common_stores()
			"safe_passage":b.safe_passage()
			"living_orchard":b.living_orchard()
			"stone_crown":b.stone_crown()
			"measures_house":b.measures_house()
	else:
		match String(design.get("form","")):
			"ring":b.ring()
			"mound":b.mound()
			"stair":b.stair()
			"tower":b.tower()
			"hall":b.hall()
			"cistern":b.cistern()
			"granary":b.granary()
			"bridge":b.bridge()
			"causeway":b.causeway()
			"dam":b.dam()
			"colossus":b.colossus()
			"garden":b.garden()
			"observatory":b.observatory()
			"gate":b.gate()
			"canal":b.canal()
			"archive":b.archive()
			"amphitheatre":b.amphitheatre()
			"lighthouse":b.lighthouse()
	if b.parts.is_empty():return [] # Invalid identities never become a generic hall.
	b.craft_detail()
	b.ornament()
	return b.parts

class Builder extends RefCounted:
	var parts:Array=[]
	var d:Dictionary
	var t:int
	var scale:float
	var tone:Color
	var trim:Color
	var accent:Color
	var seed:int
	func _init(design:Dictionary)->void:
		d=design;t=clampi(int(d.get("tier",0)),0,5);scale=clampf(float(d.get("scale",1.0)),.5,1.5)
		seed=posmod(int(d.get("seed",0)),2147483647)
		# The recorded builder's token supplies small, persistent proportions.
		scale*=lerpf(.98,1.02,float(seed%997)/996.0)
		tone=Map.MATERIAL_TINTS.get(String(d.get("material","stone")),Color("9b917a"))
		trim=tone.lightened(.14);accent=d.get("accent",Color("8b754c"))
	func p(at:Vector3,size:Vector3,color:Color,kind:String="box",yaw:float=0.0,plan:bool=true,finish:bool=false)->void:
		parts.append({"position":at*scale*.001,"size":size*scale*.001,"color":color,"kind":kind,"basis":Basis(Vector3.UP,yaw),"plan":plan,"finish":finish})
	func box(x:float,y:float,z:float,w:float,h:float,deep:float,color:Color,yaw:float=0.0,plan:bool=true)->void:p(Vector3(x,y,z),Vector3(w,h,deep),color,"box",yaw,plan)
	func roundel(x:float,y:float,z:float,w:float,h:float,deep:float,color:Color,kind:String="cylinder",plan:bool=true)->void:p(Vector3(x,y,z),Vector3(w,h,deep),color,kind,0,plan)
	func beam(a:Vector3,b:Vector3,width:float,color:Color)->void:
		var direction:=b-a
		p(a,Vector3(width,direction.length(),width),color,"box",0,false)
		parts.back().basis=Basis(Quaternion(Vector3.UP,direction.normalized()))
	func roof(x:float,y:float,z:float,w:float,h:float,deep:float,yaw:float=0.0)->void:
		var color:=Color("857050") if String(d.get("material",""))=="timber" else tone.darkened(.18)
		p(Vector3(x,y,z),Vector3(w,h,deep),color,"roof",yaw)
	func column(x:float,y:float,z:float,height:float,radius:float=1.0)->void:
		roundel(x,y,z,radius*2.6,.6,radius*2.6,trim)
		roundel(x,y+.6,z,radius*2,height-.9,radius*2,tone)
		roundel(x,y+height-.3,z,radius*2.7,.4,radius*2.7,trim)
	func arch(x:float,y:float,z:float,span:float,height:float,deep:float,yaw:float=0.0)->void:
		p(Vector3(x,y,z),Vector3(span,height,deep),tone,"arch",yaw)
	func steps(x:float,y:float,z:float,w:float,rise:float,run:float,count:int=12)->void:
		for i in count:box(x,y+i*rise/count,z-i*run/count,w,rise/count,run/count+.06,trim)
	func rail(a:Vector3,b:Vector3,height:float=1.3,count:int=9)->void:
		beam(a+Vector3.UP*height,b+Vector3.UP*height,.24,trim)
		for i in count:box(lerpf(a.x,b.x,float(i)/(count-1)),a.y,lerpf(a.z,b.z,float(i)/(count-1)),.35,height,.35,trim,0,false)
	func tree(x:float,y:float,z:float,age:float=1.0)->void:
		roundel(x,y,z,.7*age,3.5*age,.7*age,WOOD,"cylinder",false)
		p(Vector3(x,y+2.6*age,z),Vector3(6*age,5*age,5.5*age),LEAF.lightened(.025*(seed%4)),"dome",0,false,true)
	func hall_shell(x:float,z:float,w:float,deep:float,height:float,open_front:bool=false)->void:
		box(x,0,z,w+2,.8,deep+2,trim)
		for side in [-1,1]:
			box(x+side*(w*.5-.6),.8,z,1.2,height,deep,tone)
			for i in 6:box(x+side*(w*.5+.08),2.3,z+(i-2.5)*deep/7,.3,2.8,1.3,DARK,0,false)
		box(x,.8,z-deep*.5,w,height,1.2,tone)
		if not open_front:
			for side in [-1,1]:box(x+side*(w*.25+1),.8,z+deep*.5,w*.5-2,height,1.2,tone)
		for side in [-1,1]:
			for i in 6:column(x+side*(w*.5-2.2),.8,z+(i-2.5)*deep/6,height,.65)
		roof(x,height+.8,z,w+4,maxf(3,w*.28),deep+4)
		beam(Vector3(x,height+.8+w*.28,z-deep*.5-2),Vector3(x,height+.8+w*.28,z+deep*.5+2),.5,WOOD)
	func tier_bands(x:float,z:float,w:float,deep:float,height:float)->void:
		for i in 1+t:box(x,(i+1)*height/(t+2),z,w+.5,.32,deep+.5,trim,0,false)
	func ring()->void:
		var count:=12+2*(seed%3)
		for i in count:
			var a:=TAU*i/count;var height:=6.5+float((seed+i*7)%5)*.35
			p(Vector3(cos(a)*28,0,sin(a)*24),Vector3(2.5,height,2.0),tone,"taper",-a)
			if t>=1:
				var next:=TAU*(i+1)/count
				beam(Vector3(cos(a)*28,7.9,sin(a)*24),Vector3(cos(next)*28,7.9,sin(next)*24),1.4,trim)
		roundel(0,0,0,10,.8,10,trim)
		for i in 8:box(cos(i*TAU/8)*8,0,sin(i*TAU/8)*8,1.5,.6,1.5,tone,0,false)
	func mound()->void:
		for i in 5:roundel(0,i*2.1,0,58-i*9,2.8,49-i*7,tone.lerp(Color("7e8460"),.2),"taper")
		for i in 24:
			var a:=TAU*i/24;box(cos(a)*29,0,sin(a)*24,2,1.3,2,trim,a,false)
		for x in [-2.8,2.8]:box(x,0,23,1.8,4,3,tone)
		box(0,4,23,7.8,1.4,3,trim);box(0,.2,24,3.5,3.6,.15,DARK,0,false)
	func stair()->void:
		for i in 4:box(0,i*3.3,-i*3,60-i*10,3.3,43-i*7,tone.darkened(.025*i))
		steps(0,0,31,14,13.2,31,24)
		for side in [-1,1]:
			beam(Vector3(side*8,0,33),Vector3(side*8,13.5,0),1.1,trim)
			column(side*8,13.2,-6,4,1.2)
		box(0,13.2,-9,8,1.4,5,trim)
	func tower()->void:
		box(0,0,0,23,2,23,trim)
		var height:=29.0+t*1.4
		if t<=1:
			roundel(0,2,0,15,height,15,tone,"taper")
			for i in 4:box(0,7+i*5,7.2-i*.3,1.1,2.4,.18,DARK,0,false)
			roof(0,height+2,0,17,5,17)
		else:
			for i in 4:
				var w:=16.0-i*(1.0 if t<5 else 2.1)
				box(0,2+i*height/4,0,w,height/4,w,tone)
				box(0,2+(i+1)*height/4-.4,0,w+1.2,.65,w+1.2,trim)
				for side in [-1,1]:
					box(side*(w*.5+.02),5+i*height/4,0,.14,3,w*.48,Color("728487") if t>=5 else DARK,0,false)
			if t==3:
				for a in 4:p(Vector3(cos(a*PI*.5)*10,0,sin(a*PI*.5)*10),Vector3(3,19,5),tone,"buttress",-a*PI*.5)
			if t==4:
				for side in [-1,1]:beam(Vector3(side*11,0,7),Vector3(side*6,height+2,7),.7,tone.darkened(.18))
			if t<5:roof(0,height+2,0,13,5,13)
			else:box(0,height+2,0,9,1.2,9,trim)
	func hall()->void:
		hall_shell(0,0,29,48,8+t*.5)
		for x in [-10,0,10]:column(x,.8,29,7,.9)
		roof(0,7.8,29,33,3,10)
		steps(0,0,35,16,.8,4,4)
	func cistern()->void:
		box(0,0,0,49,.7,41,tone.darkened(.1))
		for x in [-23,23]:box(x,.7,0,3,4,41,tone)
		for z in [-19,19]:box(0,.7,z,46,4,3,tone)
		for i in 4:box(0,.8+i*.7,15-i*2,19,.7,2,trim)
		for side in [-1,1]:
			for i in 5:column(side*28,0,(i-2)*9,6,.7)
			roof(side*28,6,0,8,2.2,43)
		for z in [-12,0,12]:roundel(0,.7,z,3,2.5,3,trim,"cylinder",false)
	func granary()->void:
		for x in [-19,19]:
			for z in [-15,-5,5,15]:
				for dx in [-6,6]:box(x+dx,0,z,1.6,3.2,1.6,tone)
			box(x,3.2,0,16,1,39,trim)
			for z in [-12,0,12]:
				roundel(x,4.2,z,12,8,10,tone,"cylinder")
				p(Vector3(x,12.2,z),Vector3(13,3,11),trim,"cone")
				box(x,6.3,z+5,2,3,.16,WOOD,0,false)
		steps(0,0,25,9,4.2,13,10)
		box(0,3.2,9,23,1,7,WOOD)
	func bridge()->void:
		for x in [-42,-14,14,42]:
			box(x,0,0,5,9,14,tone)
			p(Vector3(x,0,-8),Vector3(5,6,5),tone,"buttress",PI)
		for x in [-28,0,28]:
			if t>=2 and String(d.material)!="iron":arch(x,5,0,27,9,11)
			else:
				for z in [-6,6]:
					beam(Vector3(x-13,9,z),Vector3(x,15,z),.65,tone)
					beam(Vector3(x,15,z),Vector3(x+13,9,z),.65,tone)
		box(0,14,0,94,1.6,14,trim)
		for z in [-6.3,6.3]:rail(Vector3(-46,15.6,z),Vector3(46,15.6,z),1.7,21)
	func causeway()->void:
		box(0,0,0,113,3,13,tone)
		for z in [-8,8]:
			p(Vector3(0,0,z),Vector3(6,3,113),tone.darkened(.08),"buttress",PI*.5 if z>0 else -PI*.5)
			for x in [-48,-32,-16,0,16,32,48]:box(x,3,z*.68,1,1.8,1,trim,0,false)
		for x in [-36,0,36]:box(x,.25,6.52,4,1.6,.12,DARK,0,false)
		for x in [-50,50]:box(x,3,0,1.4,.15,11,trim,0,false)
	func dam()->void:
		for i in 13:
			var a:=lerpf(-.7,.7,float(i)/12)
			p(Vector3(sin(a)*65,0,(1-cos(a))*25),Vector3(10,17,8.2),tone,"buttress",PI*.5-a)
			box(sin(a)*65,17,(1-cos(a))*25,8.2,1.2,5,trim,-a)
		for x in [-18,0,18]:
			box(x,0,7,8,11,12,tone)
			box(x,2,13.04,4,7,.16,DARK,0,false)
			box(x,18,3,5,4,5,tone);roof(x,22,3,6,2,6)
	func colossus()->void:
		for i in 3:box(0,i*1.4,0,24-i*4,1.4,19-i*3,trim)
		for side in [-1,1]:
			box(side*3.6,4.2,1,4.7,2,8,tone)
			p(Vector3(side*3.6,6.2,0),Vector3(4.2,12,5),tone,"taper")
		p(Vector3(0,17,0),Vector3(13,13,8),tone,"taper")
		beam(Vector3(-7,28,0),Vector3(-10,18,1),3.1,tone)
		beam(Vector3(7,28,0),Vector3(10,33,0),3.1,tone)
		p(Vector3(0,30,0),Vector3(7,8,6),trim,"taper")
		box(0,34,3,2.2,1.2,.6,tone.darkened(.2),0,false)
		box(0,38,0,8,1.2,7,accent)
		for x in [-3,0,3]:box(x,39,0,1,2.2,1,accent,0,false)
	func garden()->void:
		box(0,0,0,62,.35,53,Color("898567"))
		box(0,.35,0,7,.18,53,trim);box(0,.35,0,62,.18,6,trim)
		for x in [-22,-11,11,22]:
			for z in [-16,16]:
				box(x,.35,z,8,.65,14,tone);box(x,1,z,7.2,.12,13.2,Color("695e44"),0,false)
				tree(x,1.12,z,.65+.12*posmod(seed+int(x)+int(z),3))
		roundel(0,.53,0,8,1.2,8,tone);roundel(0,1.6,0,5,.2,5,trim)
		for x in [-29,29]:
			for z in [-22,0,22]:column(x,.35,z,4.5,.5)
			box(x,4.85,0,2,.35,49,WOOD)
	func observatory()->void:
		roundel(0,0,0,45,2,45,tone)
		for i in 12:
			var a:=TAU*i/12;box(cos(a)*19,2,sin(a)*19,1.2,.6,1.2,trim,a,false)
		if t<=1:
			for a in [0.0,TAU/3,2*TAU/3]:column(cos(a)*13,2,sin(a)*13,7,1)
			box(0,2,0,.8,10,.8,tone)
			beam(Vector3(-16,2.1,0),Vector3(16,2.1,0),.5,accent)
		else:
			roundel(0,2,0,18,9,18,tone)
			p(Vector3(0,11,0),Vector3(20,12,20),trim,"dome")
			box(0,11,9.4,2.1,6,.25,DARK,0,false)
			for x in [-6,6]:column(x,2,14,5,.75)
			if t>=4:beam(Vector3(0,18,0),Vector3(0,24,7),1.8,tone.darkened(.3))
		steps(0,0,28,10,2,7,6)
	func gate()->void:
		for x in [-14,14]:
			box(x,0,0,9,17,12,tone);box(x,17,0,11,1.3,14,trim)
			box(x,.7,6.1,3.5,9,.25,tone.darkened(.23),0,false)
		if t>=2:arch(0,10,0,25,11,9)
		else:box(0,17,0,37,3.5,10,tone)
		box(0,21,0,40,2,12,trim)
		for x in [-17,-8,0,8,17]:box(x,23,0,2.5,2,3,accent,0,false)
		steps(0,0,13,41,1.1,6,4)
	func canal()->void:
		box(0,0,0,102,.6,25,tone.darkened(.18))
		for z in [-11,11]:
			box(0,.6,z,105,4,3,tone)
			box(0,4.6,z,105,.45,4,trim)
			for x in [-45,-22,0,22,45]:box(x,5,z,1,1.3,1,WOOD,0,false)
		for x in [-25,25]:
			for side in [-1,1]:box(x,0,side*5.8,1.2,4.5,11,WOOD,side*.2)
			for z in [-15,15]:box(x,0,z,5,6,5,tone);box(x,6,z,7,.6,7,trim)
		box(0,.61,0,100,.12,18,Color("697d7a"),0,false)
	func archive()->void:
		# Three closed repositories and an open reading court, never a hall alias.
		hall_shell(-20,-4,14,38,8);hall_shell(20,-4,14,38,8)
		hall_shell(0,-24,24,12,11)
		box(0,0,1,25,.7,37,trim)
		for x in [-10,10]:
			for z in [-12,0,12]:column(x,.7,z,6,.6)
			box(x,6.7,0,2,.45,31,trim)
		for x in [-5,5]:
			for z in [-8,3,13]:
				box(x,.7,z,5,1.6,2.2,WOOD,0,false)
				for j in 3:box(x-1.5+j*1.5,2.3,z,1,.18,1.7,accent,0,false)
	func amphitheatre()->void:
		for row in 6:
			for i in 18:
				var a:=lerpf(.14,PI-.14,float(i)/17)
				var r:=18+row*3.7
				box(cos(a)*r,row*1.25,-sin(a)*r,5.8,1.25,3.1,tone.lightened(.014*row),-a+PI*.5)
		box(0,0,4,34,1.4,10,trim)
		for x in [-14,-7,0,7,14]:column(x,1.4,9,7,.7)
		box(0,8.4,9,33,.7,2,trim)
		for x in [-36,36]:steps(x,0,0,4,7.5,20,12)
	func lighthouse()->void:
		roundel(0,0,0,28,2,28,trim)
		roundel(0,2,0,18,29,18,tone,"taper")
		for i in 4:roundel(0,6+i*6,0,17-i*.75,.6,17-i*.75,trim,"cylinder",false)
		roundel(0,31,0,17,1.5,17,trim)
		for i in 8:
			var a:=TAU*i/8;column(cos(a)*5.5,32.5,sin(a)*5.5,5,.45)
		if t>=4:
			p(Vector3(0,33,0),Vector3(6,4,6),Color("a8c4bf"),"dome",0,false,true)
		else:roundel(0,32.5,0,4,1.5,4,DARK,"cylinder",false)
		p(Vector3(0,37.5,0),Vector3(17,5,17),tone.darkened(.22),"cone")
		steps(0,0,21,8,2,8,6)

	# Each legacy work keeps a separate silhouette and its own physical fixtures.
	func ancestor_ring()->void:
		for i in 12:
			var a:=TAU*i/12;var b:=TAU*(i+1)/12
			p(Vector3(cos(a)*25,0,sin(a)*22),Vector3(3.2,8.8,2.6),tone,"taper",-a)
			beam(Vector3(cos(a)*25,8.8,sin(a)*22),Vector3(cos(b)*25,8.8,sin(b)*22),1.8,trim)
			for mark in 3:box(cos(a)*22.9,2+mark*.8,sin(a)*20.1,.9,.18,.2,accent,-a,false)
		for i in 5:box((i-2)*4,0,0,1.8,2.5+float(i%2),1.2,tone,0,false)
	func great_hall()->void:
		hall_shell(0,0,35,66,10)
		for x in [-23,23]:hall_shell(x,4,10,34,6,true)
		for z in [-20,0,20]:
			roundel(0,.85,z,5,.45,5,DARK,"cylinder",false)
			box(0,20,z,2.3,2,3.8,tone.darkened(.25),0,false)
		for x in [-10,10]:box(x,.8,0,2,1.2,49,WOOD,0,false)
	func rain_court()->void:
		cistern()
		for x in [-16,16]:
			for z in [-12,12]:roundel(x,.8,z,6,3.5,6,tone,"taper",false)
		for x in [-27,27]:
			for z in [-19,19]:beam(Vector3(x,6,z),Vector3(x*.58,2.6,z*.65),.7,trim)
		steps(0,0,26,15,4.7,11,10)
	func flood_terraces()->void:
		for row in 5:
			box(0,row*1.6,-row*8,65-row*5,1.6,16,tone)
			for x in [-22,-11,0,11,22]:
				box(x,row*1.6+1.6,-row*8,7,.16,6,Color("65754d"),0,false)
			box(-26+row*2,row*1.6+1.6,-row*8,1.2,.12,15,Color("708783"),0,false)
		steps(27,0,8,5,8,40,20)
	func star_steps()->void:
		stair()
		for i in 7:
			var a:=lerpf(PI*.18,PI*.82,float(i)/6)
			box(cos(a)*12,13.2,-9-sin(a)*6,1.3,3.5+float(i%2),1.2,tone,-a)
		for i in 12:box(0,.15+i*.55,31-i*1.3,.55,.08,1.1,accent,0,false)
	func kiln_court()->void:
		box(0,0,0,55,.5,43,trim)
		for x in [-18,-6,6,18]:
			for z in [-12,12]:
				roundel(x,.5,z,8,2.5,8,tone)
				p(Vector3(x,3,z),Vector3(8,5,8),tone,"dome")
				roundel(x,7.2,z,1.4,2,1.4,tone.darkened(.18),"cylinder",false)
				box(x,1,z+4.05,2.2,2.4,.14,Color("754b32"),0,false)
				# Warm fired lining, not a running fire or fabricated production.
				box(x,1.3,z+4.14,1.35,1.35,.08,Color("b87942"),0,false)
		for x in [-18,0,18]:box(x,.5,0,8,1.4,3,WOOD,0,false)
	func long_song()->void:
		hall_shell(0,0,31,37,8,true)
		for row in 4:box(0,.8+row*.65,-4-row*3,23,.65,2,WOOD)
		p(Vector3(0,.8,15),Vector3(19,2,12),trim,"cylinder")
		for side in [-1,1]:
			for i in 5:box(side*17,1.2,13-i*6,.7,8-i*.7,2.5,WOOD,side*.14,false)
		for x in [-9,-3,3,9]:box(x,1,22,1.4,3,1,accent,0,false)
	func common_stores()->void:
		granary()
		for x in [-7,7]:
			box(x,0,-25,5,7,5,tone)
			p(Vector3(x,7,-25),Vector3(6,3,6),trim,"cone")
			box(x,3,-22.4,1.1,1.1,.25,accent,0,false)
		box(0,0,22,11,1.2,7,trim)
	func safe_passage()->void:
		for i in 16:
			if i in [0,1,7,8,9,15]:continue
			var a:=TAU*i/16;box(cos(a)*27,0,sin(a)*23,2.3,4.8,2.3,tone)
		for side in [-1,1]:
			for z in [-6,6]:column(side*27,0,z,6,1)
			box(side*27,6,0,3,1.2,16,WOOD)
			hall_shell(0,side*23,22,9,4,true)
		box(0,0,0,61,.25,7,trim)
	func living_orchard()->void:
		box(0,0,0,64,.3,57,Color("848461"))
		for row in 4:
			for col in 5:
				var x:=(col-2)*12.0;var z:=(row-1.5)*14.0
				if col==2:continue
				tree(x,.3,z,.62+.11*row)
				box(x+2,.3,z+2,1,.8,.65,trim,0,false)
		box(0,.3,0,6,.16,57,trim);box(0,.3,0,64,.16,5,trim)
		tree(0,.46,-23,1.45)
	func stone_crown()->void:
		for i in 4:roundel(0,i*3,0,64-i*11,3.5,53-i*9,tone,"taper")
		for i in 12:
			var a:=TAU*i/12;box(cos(a)*17,12,sin(a)*13,3.6,4.8,3,trim,-a)
		for x in [-12,0,12]:roundel(x,12,0,3,1.2,3,DARK,"cylinder",false)
		steps(0,0,31,8,12,30,24)
	func measures_house()->void:
		hall_shell(-20,0,14,37,6,true);hall_shell(20,0,14,37,6,true)
		box(0,0,0,25,.65,41,trim)
		for z in [-13,0,13]:
			box(0,.65,z,12,1.6,3,tone)
			for i in 6:roundel(-4+i*1.6,2.25,z,.65+i*.14,.45+i*.19,.65+i*.14,accent,"cylinder",false)
		box(0,.7,-23,2,5.5,1,trim)
		for i in 8:box(0,1+i*.55,-22.47,1.4,.1,.08,DARK,0,false)

	func craft_detail()->void:
		# The same footprint is finished with the recorded craft's joinery,
		# dressed paving or precision joints, never the viewer's current era.
		var area:AABB=load("res://scripts/hud/great_work_architecture.gd").extent(parts);var z:float=area.end.z/(scale*.001)+1.1
		var w:=minf(19.0,area.size.x/(scale*.001)*.55)
		for i in 5+t:
			var x:=(float(i)/maxf(1,4+t)-.5)*w
			var width:=w/(6+t)
			p(Vector3(x,0,z),Vector3(width,.22+float((seed+i)%3)*.05,1.6),trim,"taper" if t==0 else "box",.035*float((seed+i)%3-1) if t==0 else 0,false)
		if t>=2:
			for x in [-w*.5,w*.5]:
				box(x,0,z,1.1,1.1,1.1,tone,0,false)
				for i in t-1:box(x,.4+i*.23,z,1.3,.1,1.3,trim,0,false)
		if t>=4:
			for x in [-w*.5,w*.5]:box(x,.25,z+.6,.55,.28,.12,Color("727773"),0,false)
	func ornament()->void:
		var area:AABB=load("res://scripts/hud/great_work_architecture.gd").extent(parts);var z:float=area.end.z/(scale*.001)+2.4
		var ink:Color=d.get("purpose_accent",accent)
		match String(d.get("purpose","")):
			"honor_dead":
				for x in [-3,0,3]:box(x,0,z,1.4,2.6,.7,ink,0,false)
			"bind_tribes":
				for i in 5:box((i-2)*1.4,0,z,.8,2.5+float(i%2),.8,ink,0,false)
				box(0,2.4,z,7,.45,.9,trim,0,false)
			"tame_flood":
				box(0,0,z,1,4,.9,ink,0,false)
				for i in 7:box(0,.5+i*.45,z+.48,.7,.08,.1,trim,0,false)
			"feed_people":
				for i in 3:roundel((i-1)*2,0,z,1.6,1.8,1.6,ink,"taper",false)
			"watch_heavens":
				roundel(0,0,z,6,.35,4,trim,"cylinder",false);box(0,.35,z,.35,3.5,.35,ink,0,false)
			"awe_rivals":
				for x in [-2,2]:p(Vector3(x,0,z),Vector3(1.1,4,1.1),ink,"cone",0,false)
			"remember_knowledge":
				for i in 4:box((i-1.5)*1.4,0,z,1,2.2,.4,ink,0,false)
			"welcome_strangers":
				for x in [-3,3]:box(x,0,z,3,1,1.1,trim,0,false)
			"master_craft":
				box(0,0,z,5,1.5,2,trim,0,false);beam(Vector3(-1.5,1.5,z),Vector3(1.5,1.5,z),.3,ink)
			"defy_gods":p(Vector3(0,0,z),Vector3(1.6,4.4,1.6),ink,"taper",0,false)
			"mark_triumph":
				box(0,0,z,5,2.4,.8,trim,0,false)
				for i in 8:p(Vector3(cos(TAU*i/8)*1.4,1.2+sin(TAU*i/8),z+.5),Vector3(.6,.7,.25),ink,"dome",0,false)
			"give_thanks":
				roundel(0,0,z,4,.6,3,trim,"cylinder",false)
				for x in [-1,0,1]:roundel(x,.6,z,.8,.7,.8,ink,"taper",false)

static func extent(parts:Array)->AABB:
	var low:=Vector3(INF,INF,INF);var high:=Vector3(-INF,-INF,-INF)
	for part:Dictionary in parts:
		var basis:Basis=part.get("basis",Basis.IDENTITY)
		for i in 8:
			var point:Vector3=basis*(Vector3(.5 if i&1 else -.5,1.0 if i&2 else 0.0,.5 if i&4 else -.5)*part.size)+part.position
			low=low.min(point);high=high.max(point)
	return AABB(low,high-low) if not parts.is_empty() else AABB()

static func footprint(parts:Array)->Rect2:
	var bounds:=extent(parts)
	return Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))

## Clip real triangles at the current course, including curved arch voussoirs
## and sloping beams. No incomplete arch is replaced by a solid rectangular box.
static func append_piece(surface:SurfaceTool,part:Dictionary,limit:float=INF)->void:
	var unit:=_unit(String(part.kind));var basis:Basis=part.get("basis",Basis.IDENTITY)
	var cut:Dictionary={}
	var crosses:=is_finite(limit) and extent([part]).position.y<limit and extent([part]).end.y>limit
	for i in range(0,unit.size(),3):
		# Each voussoir is convex. Cap it separately, preserving the arch void.
		if part.kind=="arch" and i>0 and i%36==0:
			_cap(surface,cut,limit,part.color);cut.clear()
		var points:Array[Vector3]=[]
		for j in 3:points.append(basis*(unit[i+j]*part.size)+part.position)
		var normal:Vector3=(points[2]-points[0]).cross(points[1]-points[0]).normalized()
		if normal.is_zero_approx():continue
		if is_finite(limit):points=_clip(points,limit)
		if crosses:
			for point:Vector3 in points:
				if absf(point.y-limit)<.00000001:cut[Vector2(roundf(point.x*1e9),roundf(point.z*1e9))]=Vector2(point.x,point.z)
		for j in range(1,points.size()-1):
			for at:Vector3 in [points[0],points[j],points[j+1]]:
				surface.set_color(part.color);surface.set_normal(normal);surface.add_vertex(at)
	_cap(surface,cut,limit,part.color)

static func _cap(surface:SurfaceTool,cut:Dictionary,level:float,color:Color)->void:
	if cut.size()<3:return
	var hull:=Geometry2D.convex_hull(PackedVector2Array(cut.values()))
	for i in range(1,hull.size()-2):
		var a:=Vector3(hull[0].x,level,hull[0].y);var b:=Vector3(hull[i].x,level,hull[i].y);var c:=Vector3(hull[i+1].x,level,hull[i+1].y)
		if (c-a).cross(b-a).y<0:
			var swap:=b;b=c;c=swap
		for point:Vector3 in [a,b,c]:surface.set_color(color);surface.set_normal(Vector3.UP);surface.add_vertex(point)

static func _clip(points:Array[Vector3],limit:float)->Array[Vector3]:
	var output:Array[Vector3]=[]
	for i in points.size():
		var a:=points[i];var b:=points[(i+1)%points.size()]
		if a.y<=limit:output.append(a)
		if (a.y<=limit)!=(b.y<=limit):output.append(a.lerp(b,(limit-a.y)/(b.y-a.y)))
	return output

static func _unit(kind:String)->PackedVector3Array:
	if _units.has(kind):return _units[kind]
	var vertices:=PackedVector3Array()
	if kind in ["box","roof","dome","water"]:
		var source:=Map._unit(kind if kind!="water" else "box")
		for i in range(0,source.size(),3):_triangle(vertices,source[i],source[i+1],source[i+2],Vector3(0,.3 if kind=="roof" else .5,0))
	elif kind=="arch":
		for i in 16:
			var a:=PI*i/16;var b:=PI*(i+1)/16
			var face:=[Vector3(cos(a)*.5,sin(a),-.5),Vector3(cos(b)*.5,sin(b),-.5),Vector3(cos(b)*.37,sin(b)*.74,-.5),Vector3(cos(a)*.37,sin(a)*.74,-.5)]
			_prism(vertices,face,Vector3(0,0,1))
	elif kind=="buttress":
		_prism(vertices,[Vector3(-.5,0,-.5),Vector3(.5,0,-.5),Vector3(.15,1,-.5),Vector3(-.15,1,-.5)],Vector3(0,0,1))
	else:
		var top:=.5 if kind=="cylinder" else (0.0 if kind=="cone" else .34)
		for i in 12:
			var a:=TAU*i/12;var b:=TAU*(i+1)/12
			var low_a:=Vector3(cos(a)*.5,0,sin(a)*.5);var low_b:=Vector3(cos(b)*.5,0,sin(b)*.5)
			var high_a:=Vector3(cos(a)*top,1,sin(a)*top);var high_b:=Vector3(cos(b)*top,1,sin(b)*top)
			_triangle(vertices,low_a,high_a,high_b,Vector3.ZERO)
			_triangle(vertices,low_a,high_b,low_b,Vector3.ZERO)
			_triangle(vertices,Vector3.ZERO,low_b,low_a,Vector3(0,.5,0))
			_triangle(vertices,Vector3.UP,high_a,high_b,Vector3(0,.5,0))
	_units[kind]=vertices
	return vertices

static func _prism(vertices:PackedVector3Array,front:Array,depth:Vector3)->void:
	var center:=Vector3.ZERO
	for point:Vector3 in front:center+=point+depth*.5
	center/=front.size()
	for i in range(1,front.size()-1):
		_triangle(vertices,front[0],front[i],front[i+1],center)
		_triangle(vertices,front[0]+depth,front[i]+depth,front[i+1]+depth,center)
	for i in front.size():
		var a:Vector3=front[i];var b:Vector3=front[(i+1)%front.size()]
		_triangle(vertices,a,b,b+depth,center);_triangle(vertices,a,b+depth,a+depth,center)

static func _triangle(vertices:PackedVector3Array,a:Vector3,b:Vector3,c:Vector3,inside:Vector3)->void:
	if (c-a).cross(b-a).dot((a+b+c)/3.0-inside)<0:
		vertices.append(a);vertices.append(c);vertices.append(b)
	else:vertices.append(a);vertices.append(b);vertices.append(c)
