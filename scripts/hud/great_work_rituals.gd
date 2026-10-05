extends RefCounted
## Dedication is visual testimony to an existing engine result. These are
## ceremonial models, markers and gestures; none spend goods or operate a work.
const Design=preload("res://scripts/hud/great_work_design.gd")
const FORMS:={
	"ring":["circle_of_witnesses","The circle of witnesses","witness_stones","place","circle","bow_shallow","A place is left in the small circle of stones.","The last witness-stone joins the circle."],
	"mound":["earth_and_memory","The sealing of the earth","earth_bowl","place","arc","bow_shallow","A stone rests beside a ceremonial bowl of earth.","The stone is lowered into the bowl of earth."],
	"stair":["first_ascent","The first ascent","ascent_steps","raise","steps","point_up","A marker waits below three ceremonial steps.","The marker rises to the highest ceremonial step."],
	"tower":["horizon_standard","The raising of the standard","tower_standard","raise","avenue","raise_hand","A small standard waits at the foot of its mast.","The standard is raised before the tower."],
	"hall":["common_threshold","The common threshold","hall_door","open","avenue","wave","A model doorway stands closed before the hall.","The little doors open toward the gathering."],
	"cistern":["water_bowl","The promise of the water-bowl","cistern_bowl","pour","paired","nod_slow","A ceremonial water-bowl waits above a small basin.","The water-bowl is tipped in a symbolic dedication of the cistern."],
	"granary":["first_sheaf","The binding of the first sheaf","grain_sheaf","bind","paired","nod_proud","An unbound ceremonial sheaf lies beside its cord.","The cord closes around the ceremonial sheaf."],
	"bridge":["first_crossing","The first crossing","bridge_span","cross","avenue","wave","A model span marks the path between the guests.","The dedication's witness crosses the marked threshold beside the model span."],
	"causeway":["road_stone","The joining of the road","road_stones","place","avenue","point","A gap remains between the ceremonial paving stones.","The last ceremonial paving stone joins the two sides."],
	"dam":["sluice_seal","The lifting of the sluice seal","sluice_gate","open","paired","nod_proud","A miniature sluice waits behind its ceremonial seal.","The miniature sluice lifts to mark the dedication."],
	"colossus":["sculptors_reveal","The sculptor's unveiling","sculptor_figure","reveal","arc","clap_soft","A small sculptor's figure waits under a cloth.","The sculptor's study is unveiled before the completed colossus."],
	"garden":["first_branch","The first branch","garden_sapling","plant","circle","nod_slow","A ceremonial sapling waits above its planting bowl.","The sapling settles into the ceremonial planting bowl."],
	"observatory":["sky_alignment","The first alignment","sky_marker","align","arc","point_up","A sighting marker waits beside the sky-wheel.","The marker turns into line with the ceremonial sky-wheel."],
	"gate":["open_threshold","The open threshold","gate_arch","cross","avenue","wave","A small arch marks the gathering's threshold.","The dedication's witness passes through the ceremonial threshold."],
	"canal":["joining_waters","The joining of the waters","canal_channels","pour","paired","nod_slow","Two ceremonial bowls wait beside a model channel.","A bowl tips toward the model channel in a symbolic joining of waters."],
	"archive":["first_record","The laying of the record","archive_tablet","place","paired","nod_slow","An inscribed dedication tablet waits beside its stand.","The dedication tablet is laid on its stand."],
	"amphitheatre":["opening_beat","The opening beat","theatre_drum","strike","crescent","clap_soft","A ceremonial drum and beater wait before the seats.","The beater gives the ceremonial drum its opening stroke."],
	"lighthouse":["first_beacon","The first beacon","beacon_brazier","kindle","arc","point_up","A small beacon waits on its ceremonial stand.","The dedication beacon is kindled before the lighthouse."]
}
const LEGACY:={
	"ancestor_ring":["names_in_stone","The keeping of the names","ancestor_markers","place","circle","bow_shallow","A name-stone waits beside the lineage markers.","The name-stone joins the lineage markers in remembrance."],
	"great_hall":["many_hearths","The welcome of many hearths","many_hearths","kindle","crescent","wave","Three small ceremonial hearths wait before the hall.","The central ceremonial hearth is lit between the others."],
	"rain_court":["rain_share","The bowl of collected rain","rain_bowls","pour","paired","nod_slow","A shallow bowl waits above three rain cups.","The ceremonial bowl tips toward the three rain cups."],
	"flood_terraces":["high_water_mark","The setting of the flood mark","flood_reed","raise","steps","point","A reed marker waits beside a stepped model of the fields.","The ceremonial reed rises beside the model's upper terrace."],
	"star_steps":["seasonal_sightline","The sightline of the seasons","season_wand","align","steps","point_up","A sighting wand waits above a small stepped sky-marker.","The wand turns along the ceremonial sightline."],
	"kiln_court":["hundred_fires","The first of a hundred fires","kiln_hearth","kindle","crescent","nod_proud","A small kiln-mouth waits beside a shaped clay vessel.","The ceremonial kiln-mouth glows beside the vessel."],
	"long_song":["verse_of_the_house","The verse of the house","song_rods","strike","crescent","raise_hand","The memory rods wait beside their sounding frame.","The rods meet the sounding frame to mark the dedication's verse."],
	"common_stores":["covenant_seal","The seal of the covenant","covenant_measure","bind","paired","nod_slow","A ceremonial grain measure waits with an open seal.","The seal closes on the ceremonial measure."],
	"safe_passage":["unbarred_way","The unbarred way","sanctuary_posts","open","avenue","wave","A ceremonial cord lies across the sanctuary's two wayposts.","The cord is drawn aside between the sanctuary wayposts."],
	"living_orchard":["root_and_branch","The joining of root and branch","grafted_tree","plant","circle","nod_slow","Two small branches wait above a ceremonial root bowl.","The paired branches settle together into the root bowl."],
	"stone_crown":["crown_of_the_ridge","The lifting of the ridge crown","ridge_crown","raise","arc","raise_hand","A crown of small stones waits below a ridged pedestal.","The stone crown rises onto the ceremonial ridge."],
	"measures_house":["witnessed_measure","The witnessed measure","common_balance","balance","paired","nod_proud","A ceremonial balance rests unevenly beside the measuring rod.","The beam comes level beside the common measuring rod."]
}
const PURPOSES:={
	"honor_dead":["memory","A quiet gesture keeps the work's dedication with the remembered dead.","bow_shallow",Color("a89db4")],
	"bind_tribes":["joined","The joined cords stand for the work's purpose of bringing people together.","nod_slow",Color("bc8258")],
	"tame_flood":["water","The wave-mark recalls the work's purpose of taming water.","nod_slow",Color("6297a0")],
	"feed_people":["harvest","The grain-mark recalls the work's purpose of feeding people.","nod_proud",Color("b3984d")],
	"watch_heavens":["sky","The sky-mark recalls the work's purpose of watching the heavens.","point_up",Color("718aab")],
	"awe_rivals":["crown","The raised ridge-mark recalls the work's purpose of awing rivals.","raise_hand",Color("a67360")],
	"remember_knowledge":["record","The marked tablet recalls the work's purpose of keeping knowledge.","nod_slow",Color("9f8b62")],
	"welcome_strangers":["welcome","The open-way mark recalls the work's purpose of welcoming strangers.","wave",Color("7b9d85")],
	"master_craft":["craft","The tool-mark recalls the work's purpose of showing mastery.","nod_proud",Color("b17d55")],
	"defy_gods":["defiance","The upright mark recalls the work's purpose of defying the heavens.","raise_hand",Color("a66b75")],
	"mark_triumph":["triumph","The branch wreath recalls the work's purpose of marking a triumph.","clap_soft",Color("85985a")],
	"give_thanks":["thanks","The flower-mark recalls the work's purpose of giving thanks.","bow_shallow",Color("bb8b80")]
}

static func describe(work:Dictionary,known:Array,era:Dictionary)->Dictionary:
	var design:Dictionary=Design.describe(work)
	if not bool(design.get("valid",false)):return {}
	var data:Array=LEGACY.get(String(design.id),FORMS.get(String(design.form),[]))
	if data.is_empty():return {}
	var purpose:Array=PURPOSES.get(String(design.purpose),PURPOSES.give_thanks)
	var mode:=era_mode(known,era)
	return {"id":design.id,"design_id":design.design_id,"form":design.form,"purpose":design.purpose,
		"ritual_id":data[0],"title":data[1],"prop":data[2],"action":data[3],"formation":data[4],"gesture":purpose[2] if String(design.purpose) in ["honor_dead","defy_gods"] else data[5],"before":data[6],"after":data[7],
		"purpose_emblem":purpose[0],"purpose_caption":purpose[1],"purpose_gesture":purpose[2],"accent":purpose[3],"mode":mode,"symbolic":true}

static func era_mode(known:Array,profile:Dictionary)->String:
	var period:=String(profile.get("period","early"))
	if period=="modern" and ("solid_state_lighting" in known or "electric_street_lighting" in known or "filament_lamp_works" in known):return "illumination"
	if period in ["industrial","modern"] and String(profile.get("outfit","hide"))!="hide":return "ribbon"
	if period in ["medieval","early_modern"] and String(profile.get("outfit","hide"))!="hide":return "unveiling"
	return "offering"

static func voice_facts(ritual:Dictionary,committed:bool=false)->Dictionary:
	return {"title":ritual.get("title",""),"mode":ritual.get("mode","offering"),"symbolic":true,"dedicated":committed,
		"scene":ritual.get("after","") if committed else ritual.get("before",""),"purpose":ritual.get("purpose_caption","")}

static func guest_position(formation:String,index:int,total:int)->Vector3:
	var side:=-1.0 if index%2==0 else 1.0
	var row:=float(index/2)
	match formation:
		"circle":
			var angle:=lerpf(-1.25,1.25,float(index)/maxf(1,total-1))
			return Vector3(sin(angle)*3.0,0,cos(angle)*1.7+.6)
		"crescent":return Vector3((float(index)-float(total-1)*.5)*1.15,0,2.1-absf(float(index)-float(total-1)*.5)*.28)
		"avenue":return Vector3(side*2.6,0,row*1.0+.15)
		"steps":return Vector3(side*(2.1+row*.65),0,1.0+row*.5)
		"paired":return Vector3(side*(2.25+row*.65),0,row*.85+.65)
		_:return Vector3(side*(2.05+row*.8),0,row*.55+.5)

static func camera_offset(ritual:Dictionary)->Vector3:
	# A frontal threshold shot keeps the crossing witness clear of the posts.
	if String(ritual.get("form",""))=="gate":return Vector3(2.2,3.6,9.4)
	match String(ritual.get("formation","arc")):
		"avenue":return Vector3(5.6,3.6,9.4)
		"circle":return Vector3(6.5,5.5,9.0)
		"steps":return Vector3(5.0,4.6,9.0)
		"paired":return Vector3(5.5,4.0,9.5)
		"crescent":return Vector3(3.5,3.8,10.3)
		_:return Vector3(6.0,4.5,10.0)

## All ritual objects are metre-scale symbolic props, not resource records.
## Return finite property motions for the stage to play only after dedication.
static func build(ritual:Dictionary)->Dictionary:
	var root:=Node3D.new();root.name="WorkSpecificRitual"
	var fixed:=Node3D.new();fixed.name="Setting";root.add_child(fixed)
	var token:=Node3D.new();token.name="CeremonialToken";root.add_child(token)
	var after:=Node3D.new();after.name="CompletedRite";root.add_child(after)
	after.visible=false
	var stone:=Color("77756c");var wood:=Color("6f5037");var clay:=Color("916646")
	var accent:Color=ritual.accent;var grain:=Color("b5a065");var blue:=Color("608d9a")
	var prop:=String(ritual.prop)
	match prop:
		"witness_stones":
			for index in 9:
				var angle:=float(index)*TAU/10
				_box(fixed,Vector3(.20,.34,.20),Vector3(cos(angle)*.82,.17,sin(angle)*.82),stone)
			token.position=Vector3(cos(TAU*.9)*.82,0,sin(TAU*.9)*.82);_box(token,Vector3(.20,.42,.20),Vector3(0,.21,0),accent)
		"earth_bowl":
			_bowl(fixed,Vector3.ZERO,.72,clay);_sphere(fixed,Vector3(0,.26,0),Vector3(.62,.12,.62),Color("625442"))
			token.position=Vector3(0,.33,0);_sphere(token,Vector3.ZERO,Vector3(.18,.12,.14),stone)
		"ascent_steps":
			for index in 3:_box(fixed,Vector3(1.25-float(index)*.3,.25,.55),Vector3(0,.125+index*.25,-index*.35),stone)
			token.position=Vector3(0,.12,-.7);_box(token,Vector3(.16,.5,.16),Vector3(0,.25,0),accent)
		"tower_standard":
			_cylinder(fixed,Vector3(0,1.15,0),.055,2.3,wood);_cylinder(fixed,Vector3(0,.09,0),.46,.18,stone)
			token.position=Vector3(.34,.55,0);_box(token,Vector3(.62,.4,.025),Vector3.ZERO,accent)
		"hall_door":
			_arch(fixed,1.75,1.6,wood);token.position=Vector3(-.75,0,0);_box(token,Vector3(1.48,1.38,.09),Vector3(.74,.69,0),wood.lightened(.13));_sphere(token,Vector3(1.28,.75,.07),Vector3.ONE*.045,accent)
		"cistern_bowl":
			_bowl(fixed,Vector3(0,.05,0),.72,stone);_cylinder(fixed,Vector3(0,.025,0),.94,.05,clay)
			token.position=Vector3(-.5,.95,0);_pitcher(token,clay);_stream(after,Vector3(-.3,.66,0),blue)
		"grain_sheaf":
			_sheaf(fixed,Vector3(0,.08,0),grain);_cylinder(fixed,Vector3(0,.045,0),.72,.09,wood)
			token.position=Vector3(0,.54,0);_ring(token,.28,.025,accent)
		"bridge_span":
			for side in [-1.0,1.0]:_box(fixed,Vector3(.45,.5,.65),Vector3(side*.8,.25,0),stone)
			_box(fixed,Vector3(2.25,.16,.85),Vector3(0,.55,0),wood);_box(fixed,Vector3(2.65,.04,.32),Vector3(0,.03,0),blue)
			token.position=Vector3(-.9,.68,0);_sphere(token,Vector3.ZERO,Vector3(.10,.045,.10),accent)
		"road_stones":
			for index in [-2,-1,1,2]:_box(fixed,Vector3(.44,.14,.68),Vector3(float(index)*.46,.07,0),stone)
			token.position=Vector3(0,.07,0);_box(token,Vector3(.44,.14,.68),Vector3.ZERO,accent)
		"sluice_gate":
			_arch(fixed,1.6,1.8,wood);_box(fixed,Vector3(1.5,.12,1.8),Vector3(0,.06,0),stone)
			for z in [-.65,.65]:_box(fixed,Vector3(1.16,.025,.4),Vector3(0,.13,z),blue)
			token.position=Vector3(0,.6,0);_box(token,Vector3(1.25,1.0,.12),Vector3.ZERO,wood.lightened(.12))
		"sculptor_figure":
			_cylinder(fixed,Vector3(0,.13,0),.5,.26,stone);_small_figure(fixed,Vector3(0,.26,0),stone.lightened(.2))
			token.position=Vector3(0,.91,.31);_box(token,Vector3(.82,1.34,.025),Vector3.ZERO,accent)
		"garden_sapling":
			_bowl(fixed,Vector3.ZERO,.65,clay);token.position=Vector3(0,.18,0);_tree(token,1.35,Color("627450"),wood)
		"sky_marker":
			_box(fixed,Vector3(1.5,.14,1.25),Vector3(0,.07,0),stone);var sky:=Node3D.new();fixed.add_child(sky);sky.position=Vector3(0,1.2,0);sky.rotation.x=PI*.5;_ring(sky,.53,.045,accent)
			token.position=Vector3(0,.95,0);_box(token,Vector3(1.45,.07,.07),Vector3.ZERO,wood)
		"gate_arch":
			_arch(fixed,1.65,2.8,stone);_box(fixed,Vector3(1.8,.08,1.65),Vector3(0,.04,0),clay)
			token.position=Vector3(-.75,.1,.45);_box(token,Vector3(.24,.04,.4),Vector3.ZERO,accent)
		"canal_channels":
			for side in [-1.0,1.0]:_bowl(fixed,Vector3(side*.9,0,0),.43,stone)
			for side in [-1.0,1.0]:_box(fixed,Vector3(1.45,.18,.12),Vector3(0,.09,side*.22),clay)
			token.position=Vector3(-.72,.82,0);_pitcher(token,clay);_stream(after,Vector3(-.48,.54,0),blue)
		"archive_tablet":
			_table(fixed,wood);_box(fixed,Vector3(.64,.07,.62),Vector3(.34,.86,0),stone)
			token.position=Vector3(-.15,.9,0);_tablet(token,clay,accent)
		"theatre_drum":
			_cylinder(fixed,Vector3(0,.5,0),.56,.7,wood);_cylinder(fixed,Vector3(0,.865,0),.58,.03,grain)
			token.position=Vector3(.17,1.12,0);_box(token,Vector3(.055,.65,.055),Vector3(0,.3,0),wood);_sphere(token,Vector3(0,.03,0),Vector3.ONE*.09,accent)
		"beacon_brazier":
			for side in [-1.0,1.0]:_box(fixed,Vector3(.09,.85,.09),Vector3(side*.35,.425,0),wood)
			_bowl(fixed,Vector3(0,.85,0),.48,stone);after.position=Vector3(0,1.05,0);_flame(after,accent)
		"ancestor_markers":
			for index in 5:
				var angle:=float(index)*TAU/5;var at:=Vector3(cos(angle)*.78,0,sin(angle)*.78)
				_box(fixed,Vector3(.16,.5,.28),at+Vector3(0,.25,0),stone);_box(fixed,Vector3(.09,.018,.018),at+Vector3(0,.36,.15),accent)
			token.position=Vector3(0,.12,0);_sphere(token,Vector3.ZERO,Vector3(.22,.12,.18),accent)
		"many_hearths":
			for x in [-.85,0.0,.85]:_hearth(fixed,Vector3(x,0,0),stone)
			after.position=Vector3(0,.16,0);_flame(after,accent)
		"rain_bowls":
			for x in [-.6,0.0,.6]:_bowl(fixed,Vector3(x,0,0),.29,clay)
			token.position=Vector3(-.24,.92,0);_pitcher(token,stone);_stream(after,Vector3(.03,.61,0),blue)
		"flood_reed":
			for index in 3:_box(fixed,Vector3(1.75-index*.4,.16,.46),Vector3(0,.08+index*.16,-index*.4),Color("727b55"))
			token.position=Vector3(.75,.1,-.7);_box(token,Vector3(.07,1.35,.07),Vector3(0,.675,0),wood)
			for mark in 4:_box(token,Vector3(.2,.04,.04),Vector3(.06,.35+mark*.23,.035),accent)
		"season_wand":
			for index in 3:_box(fixed,Vector3(1.3-index*.28,.2,.5),Vector3(0,.1+index*.2,-index*.35),stone)
			token.position=Vector3(0,.88,-.3);_box(token,Vector3(1.5,.045,.045),Vector3.ZERO,wood);_star(token,Vector3(.6,.18,0),.18,accent)
		"kiln_hearth":
			_sphere(fixed,Vector3(0,.38,-.12),Vector3(.65,.47,.5),clay);_box(fixed,Vector3(.37,.31,.04),Vector3(0,.23,.39),Color("3c322b"));_pitcher(fixed,clay.lightened(.2),Vector3(.92,.16,0))
			after.position=Vector3(0,.23,.43);_flame(after,accent)
		"song_rods":
			_arch(fixed,1.45,1.5,wood)
			for index in 5:_cylinder(fixed,Vector3((index-2)*.23,.86,0),.04,.52+index*.13,wood.lightened(.04*index))
			token.position=Vector3(-.6,1.0,.24);_box(token,Vector3(1.05,.055,.055),Vector3(.5,0,0),accent)
		"covenant_measure":
			_cylinder(fixed,Vector3(0,.35,0),.52,.7,wood);_cylinder(fixed,Vector3(0,.71,0),.53,.05,grain)
			token.position=Vector3(0,.77,0);_ring(token,.43,.05,accent);_box(token,Vector3(.18,.06,.22),Vector3(0,.02,.42),clay)
		"sanctuary_posts":
			for side in [-1.0,1.0]:_cylinder(fixed,Vector3(side*.92,.8,0),.09,1.6,wood);_sphere(fixed,Vector3(side*.92,1.66,0),Vector3(.13,.1,.13),stone)
			token.position=Vector3(-.92,1.14,0);_box(token,Vector3(1.84,.065,.035),Vector3(.92,0,0),accent)
		"grafted_tree":
			_bowl(fixed,Vector3.ZERO,.73,clay);token.position=Vector3(0,.15,0);_tree(token,1.4,Color("647c48"),wood);_tree(token,1.0,Color("859357"),wood,Vector3(.32,0,0));_ring(token,.23,.026,accent,Vector3(.1,.56,0))
		"ridge_crown":
			for index in 3:_box(fixed,Vector3(1.55-index*.36,.16,.85-index*.14),Vector3(0,.08+index*.16,0),stone)
			token.position=Vector3(0,.03,0)
			for index in 7:
				var angle:=index*TAU/7;_box(token,Vector3(.16,.32,.16),Vector3(cos(angle)*.4,.16,sin(angle)*.4),accent)
		"common_balance":
			_table(fixed,wood);_cylinder(fixed,Vector3(0,1.25,0),.055,.8,stone);_box(fixed,Vector3(1.1,.04,.06),Vector3(0,.84,.35),grain)
			token.position=Vector3(0,1.65,0);_box(token,Vector3(1.45,.07,.07),Vector3.ZERO,wood)
			for side in [-1.0,1.0]:_cylinder(token,Vector3(side*.62,-.2,0),.018,.4,accent);_bowl(token,Vector3(side*.62,-.44,0),.24,stone)
	# The purpose has its own small relief beside the work-specific rite.
	# Keep the purpose mark beyond the six recorded guests' standing places.
	var emblem:=Node3D.new();emblem.name="Purpose_"+String(ritual.purpose_emblem);root.add_child(emblem);emblem.position=Vector3(3.8,.55,-.35)
	_cylinder(root,Vector3(3.8,.27,-.35),.34,.54,stone);_purpose(emblem,String(ritual.purpose_emblem),accent)
	var action:=String(ritual.action);var motions:Array=[]
	match action:
		"place","plant":
			motions.append({"node":token,"property":"position","to":token.position});token.position+=Vector3(.45,.72,.30)
		"raise":motions.append({"node":token,"property":"position","to":token.position+Vector3(0,float({"ascent_steps":.63,"flood_reed":.38,"ridge_crown":.45}.get(prop,.9)),0)})
		"open":
			if prop=="sluice_gate":motions.append({"node":token,"property":"position:y","to":token.position.y+.9})
			else:motions.append({"node":token,"property":"rotation:y","to":-PI*.5})
		"pour":motions.append({"node":token,"property":"rotation:z","to":-.92})
		"reveal":motions.append({"node":token,"property":"scale:x","to":.02})
		"bind":
			motions.append({"node":token,"property":"position","to":token.position});token.position+=Vector3(.65,.3,.3)
		"align":token.rotation.y=-.8;motions.append({"node":token,"property":"rotation:y","to":.0})
		"strike":token.rotation.z=-.5;motions.append({"node":token,"property":"rotation:z","to":.4})
		"balance":token.rotation.z=.23;motions.append({"node":token,"property":"rotation:z","to":.0})
		"cross":motions.append({"node":token,"property":"position:x","to":token.position.x+1.6})
		"kindle":
			after.scale=Vector3.ONE*.08;motions.append({"node":after,"property":"scale","to":Vector3.ONE})
	return {"root":root,"motions":motions,"after":after,"focus":Vector3(0,.8,0)}

static func _purpose(root:Node3D,key:String,colour:Color)->void:
	match key:
		"memory":
			for index in 3:_sphere(root,Vector3(0,index*.12,0),Vector3(.23-index*.04,.08,.16),colour)
		"joined":
			for side in [-1.0,1.0]:_ring(root,.16,.045,colour,Vector3(side*.11,.08,0))
		"water":
			for index in 3:_box(root,Vector3(.43,.035,.035),Vector3(0,.08+index*.1,sin(index)*.06),colour)
		"harvest":_sheaf(root,Vector3.ZERO,colour,.45)
		"sky":_star(root,Vector3(0,.22,0),.25,colour)
		"crown":
			for x in [-.2,0.0,.2]:_box(root,Vector3(.1,.22+(.1 if x==0 else 0),.12),Vector3(x,.11,0),colour)
		"record":_tablet(root,colour,colour.darkened(.45),Vector3.ZERO,.55)
		"welcome":_arch(root,.48,.45,colour)
		"craft":_box(root,Vector3(.055,.55,.055),Vector3(0,.22,0),colour);_box(root,Vector3(.35,.12,.13),Vector3(0,.43,0),colour)
		"defiance":_box(root,Vector3(.07,.5,.07),Vector3(0,.25,0),colour);_sphere(root,Vector3(0,.52,0),Vector3(.14,.06,.14),colour)
		"triumph":
			_ring(root,.23,.055,colour,Vector3(0,.08,0))
			for index in 6:_sphere(root,Vector3(cos(index*TAU/6)*.23,.1,sin(index*TAU/6)*.23),Vector3(.10,.04,.06),colour.lightened(.12))
		"thanks":
			for index in 6:_sphere(root,Vector3(cos(index*TAU/6)*.15,.1,sin(index*TAU/6)*.15),Vector3(.12,.06,.075),colour)

static func _material(colour:Color)->StandardMaterial3D:
	var material:=StandardMaterial3D.new();material.albedo_color=colour;material.roughness=.88;return material
static func _mesh(root:Node3D,mesh:Mesh,at:Vector3,colour:Color)->MeshInstance3D:
	var node:=MeshInstance3D.new();node.mesh=mesh;node.position=at;node.material_override=_material(colour);root.add_child(node);return node
static func _box(root:Node3D,dimensions:Vector3,at:Vector3,colour:Color)->MeshInstance3D:
	var mesh:=BoxMesh.new();mesh.size=dimensions;return _mesh(root,mesh,at,colour)
static func _cylinder(root:Node3D,at:Vector3,radius:float,height:float,colour:Color)->MeshInstance3D:
	var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=16;return _mesh(root,mesh,at,colour)
static func _sphere(root:Node3D,at:Vector3,extent:Vector3,colour:Color)->MeshInstance3D:
	var mesh:=SphereMesh.new();mesh.radius=1;mesh.height=2;mesh.radial_segments=12;mesh.rings=6;var node:=_mesh(root,mesh,at,colour);node.scale=extent;return node
static func _ring(root:Node3D,radius:float,tube:float,colour:Color,at:=Vector3.ZERO)->MeshInstance3D:
	var mesh:=TorusMesh.new();mesh.inner_radius=maxf(.005,radius-tube);mesh.outer_radius=radius+tube;mesh.rings=16;mesh.ring_segments=8;return _mesh(root,mesh,at,colour)
static func _bowl(root:Node3D,at:Vector3,radius:float,colour:Color)->void:
	_cylinder(root,at+Vector3(0,.055,0),radius*.85,.11,colour);_ring(root,radius*.84,radius*.11,colour,at+Vector3(0,.16,0))
static func _pitcher(root:Node3D,colour:Color,at:=Vector3.ZERO)->void:
	_sphere(root,at,Vector3(.23,.3,.23),colour);_cylinder(root,at+Vector3(0,.30,0),.11,.18,colour);var handle:=_ring(root,.18,.035,colour,at+Vector3(.22,.08,0));handle.rotation.x=PI*.5
static func _stream(root:Node3D,at:Vector3,colour:Color)->void:
	for index in 5:_sphere(root,at+Vector3(index*.028,-index*.095,0),Vector3(.03,.065,.03),colour)
static func _arch(root:Node3D,width:float,height:float,colour:Color)->void:
	for side in [-1.0,1.0]:_box(root,Vector3(.14,height,.18),Vector3(side*width*.5,height*.5,0),colour)
	_box(root,Vector3(width+.22,.16,.23),Vector3(0,height,0),colour)
static func _table(root:Node3D,colour:Color)->void:
	_box(root,Vector3(1.4,.1,.85),Vector3(0,.78,0),colour)
	for x in [-.5,.5]:
		for z in [-.27,.27]:_box(root,Vector3(.1,.74,.1),Vector3(x,.37,z),colour)
static func _tablet(root:Node3D,colour:Color,marks:Color,at:=Vector3.ZERO,factor:=1.0)->void:
	_box(root,Vector3(.55,.1,.48)*factor,at,colour)
	for row in 4:
		for column in 3:_box(root,Vector3(.065,.008,.014)*factor,at+Vector3((column-1)*.14,.055,(row-1.5)*.09)*factor,marks)
static func _sheaf(root:Node3D,at:Vector3,colour:Color,factor:=1.0)->void:
	for index in 9:
		var angle:=index*TAU/9;var offset:=Vector3(cos(angle)*.20,.5,sin(angle)*.20)*factor
		var stalk:=_cylinder(root,at+offset,.023*factor,.95*factor,colour);stalk.rotation.z=sin(angle)*.14
		_sphere(root,at+offset+Vector3(0,.52*factor,0),Vector3(.055,.16,.055)*factor,colour)
static func _tree(root:Node3D,height:float,leaves:Color,wood:Color,at:=Vector3.ZERO)->void:
	_cylinder(root,at+Vector3(0,height*.4,0),.035,height*.8,wood)
	for index in 5:
		var angle:=index*TAU/5;_sphere(root,at+Vector3(cos(angle)*.26,height*.65+index*.09,sin(angle)*.2),Vector3(.26,.15,.17),leaves)
static func _small_figure(root:Node3D,at:Vector3,colour:Color)->void:
	_box(root,Vector3(.26,.62,.2),at+Vector3(0,.44,0),colour);_sphere(root,at+Vector3(0,.88,0),Vector3.ONE*.16,colour)
	for side in [-1.0,1.0]:_box(root,Vector3(.09,.3,.12),at+Vector3(side*.09,.15,0),colour)
static func _hearth(root:Node3D,at:Vector3,colour:Color)->void:
	for index in 7:_sphere(root,at+Vector3(cos(index*TAU/7)*.32,.08,sin(index*TAU/7)*.32),Vector3(.12,.08,.12),colour)
static func _flame(root:Node3D,_accent:Color)->void:
	for index in 3:
		var node:=_sphere(root,Vector3((index-1)*.1,.18+index*.07,0),Vector3(.10,.26,.10),Color("c67c43"));var material:StandardMaterial3D=node.material_override
		material.emission_enabled=true;material.emission=Color("a65424");material.emission_energy_multiplier=.35
static func _star(root:Node3D,at:Vector3,radius:float,colour:Color)->void:
	for angle in [0.0,PI*.25,PI*.5,PI*.75]:
		var ray:=_box(root,Vector3(radius*2,.035,.04),at,colour);ray.rotation.z=angle
