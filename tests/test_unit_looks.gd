extends GdUnitTestSuite
## Units look right in every age (docs/MILITARY_SYSTEM_V2.md section 7): every
## land kit in the equipment ledger draws its own ink glyph, from the club to
## the combat frame; battle plates, production icons and roster insignia draw
## the kit's glyph while the battle rules keep their coarse arm; the war chart
## reads a force's branch and era from its kits; a battle crosses the weapons
## its armies carry, spears to swords to muskets to rifles, then the armour
## sign and the lattice. Also writes the contact sheet of every glyph at 48 and
## 24 px to artifacts/unit_glyph_sheet.png for review (artifacts/ is not kept).

const Icons:=preload("res://scripts/resource_icons.gd")
const Ledger:=preload("res://scripts/equipment_ledger.gd")
const Blocks:=preload("res://scripts/battle_blocks.gd")
const Catalog:=preload("res://scripts/military_unit_catalog.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const BattleMarks:=preload("res://scripts/hud/battle_marks.gd")
const Presentation:=preload("res://scripts/warfare_map_presentation.gd")
const Roster:=preload("res://scripts/hud/military_roster_visuals.gd")
const Sim:=preload("res://scripts/combat_simulator.gd")
const Record:=preload("res://scripts/battle_record.gd")

const INK:=Color("#2b2118")
const ACCENT:=Color("#4f9bb8")


## Every glyph id the ledger's land kits use (armour kits draw the spear).
static func _ledger_glyphs()->Array:
	var out:Array=[]
	for kit in Ledger.KITS:
		var glyph:=Ledger.glyph(String(kit))
		if not out.has(glyph): out.append(glyph)
	for kit in Ledger.ARMOR_FAMILY:
		var glyph:=Ledger.glyph(String(kit))
		if not out.has(glyph): out.append(glyph)
	return out


static func _inked(image:Image)->int:
	var inked:=0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x,y).a>0.5: inked+=1
	return inked


static func _force(kit:String,count:int=1000,unit:String="")->Array:
	return [{"unit":unit,"weapon":kit,"count":count}]


func test_every_ledger_glyph_draws_its_own_mark()->void:
	var glyphs:=_ledger_glyphs()
	assert_int(glyphs.size()).is_greater_equal(50)
	var seen:Dictionary={}
	for glyph in glyphs:
		assert_bool(Icons.ARM_GLYPHS.has(glyph)).override_failure_message("%s is not in ARM_GLYPHS" % glyph).is_true()
		var image:=Icons.arm_texture(String(glyph),INK,ACCENT,48).get_image()
		image.clear_mipmaps()
		# Not the engine's fallback dot: a real mark with some ink on it.
		assert_int(_inked(image)).override_failure_message("%s draws almost nothing" % glyph).is_greater(150)
		var data:=image.get_data()
		for other in seen:
			assert_bool(data==seen[other]).override_failure_message("%s draws the same as %s" % [glyph,other]).is_false()
		seen[glyph]=data
	# The fallback dot is kept for unknown names, never for a ledger glyph.
	var dot:=Icons.arm_texture("no_such_arm",INK,ACCENT,48).get_image()
	dot.clear_mipmaps()
	for glyph in seen: assert_bool(dot.get_data()==seen[glyph]).is_false()
	# The battle rules' coarse arms still draw (arm_of's names).
	for arm in ["club","spear","pike","sword","axe","bow","sling","javelin","horse","chariot","elephant","musket","rifle","machine_gun","guns","armour","engineers","support"]:
		assert_int(_inked(Icons.arm_texture(arm,INK,ACCENT,48).get_image())).is_greater(100)


func test_the_side_colour_is_only_a_touch()->void:
	# One paper, ink strokes; the side's colour is a sash, a pennon, a boss or
	# a sensor's glow, never most of the mark.
	for glyph in _ledger_glyphs():
		var parts:=Icons.arm_glyph(String(glyph),Color.BLACK,Color.RED)
		var accented:=parts.filter(func(p:Dictionary)->bool: return (p.col as Color)==Color.RED)
		assert_int(accented.size()).override_failure_message("%s has %d accent parts" % [glyph,accented.size()]).is_between(0,2)
		assert_int(parts.size()).is_greater(accented.size()*2)


func test_a_formation_is_drawn_as_its_kit_but_fights_as_its_arm()->void:
	for kit in Ledger.KITS:
		var unit:=""
		for candidate in Catalog.ARCHETYPES:
			if Catalog.equipment_for(String(candidate)).has(kit): unit=String(candidate); break
		assert_str(Blocks.glyph_of(unit,String(kit))).override_failure_message("%s/%s" % [unit,kit]).is_equal(Ledger.glyph(String(kit)))
		# The icon is drawn from the ledger; the battle rules keep their arm.
		assert_bool(Icons.ARM_GLYPHS.has(Blocks.arm_of(unit,String(kit)))).is_true()
	# The combat arms are unchanged (DEPLOY_ORDER, SUPPORT key on them).
	assert_str(Blocks.arm_of("light_tank","light_tank_kit")).is_equal("armour")
	assert_str(Blocks.arm_of("field_artillery","field_gun")).is_equal("guns")
	assert_str(Blocks.glyph_of("light_tank","light_tank_kit")).is_equal("light_tank")
	assert_str(Blocks.glyph_of("modern_artillery","modern_field_gun")).is_equal("howitzer")
	# A known unit with no weapon named draws its first catalog kit; anything
	# else draws the arm it fights as.
	assert_str(Blocks.glyph_of("heavy_tank","")).is_equal("heavy_tank")
	assert_str(Blocks.glyph_of("generic","generic")).is_equal(Blocks.arm_of("generic","generic"))
	assert_str(Blocks.glyph_of("levy","improvised")).is_equal("club")


func test_battle_plates_carry_the_kit_glyph_and_the_arm_words()->void:
	var sim:=Sim.new()
	var make:=func(name:String,parts:Array)->Dictionary:
		var formations:Array=[]
		for part in parts: formations.append({"unit":String(part[0]),"weapon":String(part[1]),"count":int(part[2]),"equipment":int(part[2]),"training":0.7})
		var force:=sim.create_formation_force(name,formations,0.8,0.8)
		force["commander"]=sim.create_commander(name+" general",0.7,0.7,0.5,0.7)
		return force
	var a:Dictionary=make.call("Ours",[["light_tank","light_tank_kit",300],["rifle_infantry","service_rifle",2000]])
	var d:Dictionary=make.call("Theirs",[["rifle_infantry","service_rifle",2200]])
	var result:=sim.simulate(a,d,{"seed":7,"ground":{"kind":"open"}})
	result["home_side"]="attacker"
	var view:=Record.view(result,{"stage":"reckoned"})
	var glyphs:Dictionary={}
	for plate in (view.start.left.front as Array)+(view.start.left.rear as Array):
		glyphs[String(plate.glyph)]=String(plate.arm)
	assert_str(String(glyphs.get("light_tank",""))).is_equal("armour")
	assert_str(String(glyphs.get("rifle",""))).is_equal("rifle")


func test_production_icons_use_the_ledger_glyph()->void:
	for kit in Ledger.KITS:
		assert_str(Icons.equipment_arm(String(kit))).is_equal(Ledger.glyph(String(kit)))
	assert_str(Icons.equipment_arm("plate_spear")).is_equal("spear")
	for item in ["arrows","heavy_shells","transport_cart","galley_equipment","fighter_equipment"]:
		assert_str(Icons.equipment_arm(item)).is_equal("")
	assert_str(Icons.equipment_arm("supply_lorry")).is_equal("lorry")
	var tank:=Icons.equipment_texture("light_tank_kit",INK,ACCENT,40).get_image()
	var frame:=Icons.equipment_texture("combat_frame",INK,ACCENT,40).get_image()
	assert_bool(tank.get_data()==frame.get_data()).is_false()


func test_the_chart_reads_branch_and_era_from_the_kits()->void:
	assert_str(ArmyMarks.force_branch(_force("light_tank_kit",300,"light_tank"))).is_equal("armour")
	assert_str(ArmyMarks.force_branch(_force("main_battle_tank"))).is_equal("armour")
	assert_str(ArmyMarks.force_branch(_force("mechanized_kit"))).is_equal("armour")
	assert_str(ArmyMarks.force_branch(_force("motorized_kit"))).is_equal("motor")
	assert_str(ArmyMarks.force_branch(_force("rocket_launcher"))).is_equal("guns")
	assert_str(ArmyMarks.force_branch(_force("precision_launcher"))).is_equal("guns")
	assert_str(ArmyMarks.force_branch(_force("dragoon_kit"))).is_equal("horse")
	assert_str(ArmyMarks.force_branch(_force("elephant_kit"))).is_equal("horse")
	assert_str(ArmyMarks.force_branch(_force("crossbow"))).is_equal("missile")
	assert_str(ArmyMarks.force_branch(_force("combat_frame"))).is_equal("autonomous")
	assert_str(ArmyMarks.force_branch(_force("drone_team"))).is_equal("autonomous")
	assert_str(ArmyMarks.force_branch(_force("musket"))).is_equal("foot")
	# A few tanks lead how a rifle army is read only when they weigh enough.
	assert_str(ArmyMarks.force_branch(_force("service_rifle",20000)+_force("light_tank_kit",150))).is_equal("foot")
	assert_str(ArmyMarks.force_branch(_force("service_rifle",4000)+_force("armored_vehicle",2500))).is_equal("armour")
	# Eras: before powder, powder, rifles, motors and armour.
	assert_int(ArmyMarks.force_era(_force("spear"))).is_equal(0)
	assert_int(ArmyMarks.force_era(_force("trebuchet"))).is_equal(0)
	assert_int(ArmyMarks.force_era(_force("musket"))).is_equal(1)
	assert_int(ArmyMarks.force_era(_force("service_rifle"))).is_equal(2)
	assert_int(ArmyMarks.force_era(_force("light_tank_kit"))).is_equal(3)
	assert_int(ArmyMarks.force_era(_force("combat_frame"))).is_equal(3)
	# A medical detachment does not date a spear host.
	assert_int(ArmyMarks.force_era(_force("spear",3000)+_force("medical_kit",40))).is_equal(0)
	assert_float(ArmyMarks.force_year([])).is_equal(-1.0)
	# A formation with no weapon named is read from its unit's catalog kit.
	assert_str(ArmyMarks.force_branch([{"unit":"armored_formation","count":500}])).is_equal("armour")
	# The mark that follows: a musket army flies the gunpowder colours; a
	# tank army is a staff-map box with the armour oval.
	var muskets:={"army_id":1,"troops":3000,"formations":_force("musket",3000,"musketeer")}
	assert_int(Presentation.formation_era(muskets)).is_equal(1)
	assert_str(ArmyMarks.kind(3000,"reckoned",Presentation.formation_era(muskets))).is_equal("colours")
	var tanks:={"army_id":2,"troops":3000,"formations":_force("light_tank_kit",3000,"light_tank")}
	assert_int(Presentation.formation_era(tanks)).is_equal(3)
	assert_str(Presentation.formation_branch(tanks)).is_equal("armour")
	assert_str(Presentation.formation_role(tanks)).is_equal("armored")
	assert_str(ArmyMarks.kind(3000,"reckoned",Presentation.formation_era(tanks))).is_equal("formation")
	var frames:={"army_id":3,"troops":800,"formations":_force("combat_frame",800)}
	assert_str(Presentation.formation_branch(frames)).is_equal("autonomous")
	# A sighting of a known unit is read from its kit too.
	assert_str(ArmyMarks.branch("infantry","heavy_tank")).is_equal("armour")
	assert_str(ArmyMarks.branch("","crossbowman")).is_equal("missile")
	# The marks draw: the colours for every branch, the lattice in the box.
	for kind in ["colours","formation","army"]:
		for branch in ["foot","horse","missile","guns","engineers","motor","armour","autonomous"]:
			assert_int(_inked(Icons.army_texture(kind,branch,INK,ACCENT).get_image())).is_greater(150)
	var lattice:=Icons.army_texture("formation","autonomous",INK,ACCENT).get_image()
	var foot:=Icons.army_texture("formation","foot",INK,ACCENT).get_image()
	assert_bool(lattice.get_data()==foot.get_data()).is_false()


func test_battle_marks_cross_the_weapons_of_their_age()->void:
	var eras:Array=[]
	for kit in ["spear","sword_shield","musket","service_rifle","light_tank_kit","drone_team"]:
		eras.append(BattleMarks.weapons_era(ArmyMarks.force_year(_force(kit))))
	assert_array(eras).is_equal([0,1,2,3,4,5])
	# A battle takes the later side's weapons.
	var battle:={"id":"b1","pos":Vector2.ZERO,"ours":false,"sides":{"a":{"troops":900,"year":ArmyMarks.force_year(_force("musket"))},"b":{"troops":700,"year":ArmyMarks.force_year(_force("pike"))}}}
	var placed:=BattleMarks.place([battle],[],1.0)
	assert_int(int(placed[0].era)).is_equal(2)
	# Kits unknown: the chart's own era, by the latest battle or the stage.
	var unknown:=BattleMarks.place([{"id":"b2","pos":Vector2.ZERO,"sides":{"a":{"troops":20},"b":{"troops":30}}}],[],1.0)
	assert_bool((unknown[0] as Dictionary).has("era")).is_false()
	assert_int(BattleMarks.chart_era(unknown,"hearth")).is_equal(0)
	assert_int(BattleMarks.chart_era(unknown,"lettered")).is_equal(1)
	assert_int(BattleMarks.chart_era(placed+unknown,"hearth")).is_equal(2)


func test_roster_insignia_is_the_units_own_mark()->void:
	assert_str(Roster.insignia_glyph("light_tank","army")).is_equal("light_tank")
	assert_str(Roster.insignia_glyph("trebuchet_crew","army")).is_equal("trebuchet")
	assert_str(Roster.insignia_glyph("unknown_legacy_type","army")).is_equal("")
	assert_str(Roster.insignia_glyph("light_tank","navy")).is_equal("")


func test_contact_sheet_of_every_glyph()->void:
	# For review only: every mark at 48 px and 24 px, on paper and on a dark
	# ground, in ARM_GLYPHS order (artifacts/unit_glyph_sheet.txt names them).
	var ids:Array=Icons.ARM_GLYPHS
	var cols:=9
	var cell:=Vector2i(112,60)
	var sheet:=Image.create(cols*cell.x,ceili(float(ids.size())/float(cols))*cell.y,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("#efe6d4"))
	var names:=PackedStringArray()
	for i in ids.size():
		var origin:=Vector2i((i%cols)*cell.x,(i/cols)*cell.y)
		sheet.fill_rect(Rect2i(origin+Vector2i(78,30),Vector2i(30,28)),Color("#3c4a3f"))
		for size in [48,24]:
			var image:=Icons.arm_texture(String(ids[i]),INK,ACCENT,size).get_image()
			image.clear_mipmaps()
			image.convert(Image.FORMAT_RGBA8)
			if size==48: sheet.blend_rect(image,Rect2i(0,0,48,48),origin+Vector2i(4,6))
			else:
				sheet.blend_rect(image,Rect2i(0,0,24,24),origin+Vector2i(52,4))
				sheet.blend_rect(image,Rect2i(0,0,24,24),origin+Vector2i(81,32))
		names.append("%d (row %d, col %d): %s" % [i,i/cols+1,i%cols+1,String(ids[i])])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	assert_int(sheet.save_png("res://artifacts/unit_glyph_sheet.png")).is_equal(OK)
	var listing:=FileAccess.open("res://artifacts/unit_glyph_sheet.txt",FileAccess.WRITE)
	if listing!=null: listing.store_string("\n".join(names)+"\n")
