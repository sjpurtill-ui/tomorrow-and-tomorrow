extends RefCounted
## Read-only rural representatives of locally completed construction. Calendar
## dates and population never grant materials, buildings, or installed methods.
const EARLY=preload("res://scripts/early_settlement_visual.gd")
const TOWN=preload("res://scripts/organic_town_visual.gd")
const LATE=preload("res://scripts/settlement_architecture_kit.gd")
const MAX_PLOTS:=2048
const MAX_VARIANTS:=32
const MAX_PROPS:=3
const GRADE_KINDS:=["rooted_lean_to","round_household","house_small","earthen_household","rubble_household"]
const PROP_KNOWLEDGE:={
	"drying_rack":["indirect_solar_food_drying","smoking","fish_drying","meat_drying","food_drying"],
	"pots":["painted_pottery","clay_shaping","pottery","coiled_pottery"],
	"quern":["flour_sifting","grain_grinding","saddle_quern","mixed_grain_legume_meals"],
	"well":["well_siting","lined_well_shafts"],
	"pen_wattle":["animal_taming","herding_rotas","herd_size_limits"],
	"cart":["spoked_wheel_assembly"]}

static func capture(knowledge:Array,fabric:Dictionary,plots:Array=[])->Dictionary:
	var groups:Dictionary={}
	var completed:=0
	var late_count:=0
	var plot_radius:=0.0
	for index in mini(plots.size(),MAX_PLOTS):
		var plot:Dictionary=plots[index]
		# The town renderer uses this same recorded polygon extent. Expose the
		# result to the country plan so it does not scan all plots a second time.
		for point:Vector2 in plot.get("polygon",[]):plot_radius=maxf(plot_radius,point.length())
		if String(plot.get("land_use","")) not in ["residential_compound","mixed_household"]:continue
		if String(plot.get("status","active")) not in ["active","stressed","damaged"]:continue
		if float(plot.get("construction_progress",1.0))<0.999:continue
		if float((plot.get("damage",{}) as Dictionary).get("structural",0.0))>0.65:continue
		completed+=1
		var generation:=int(plot.get("fabric_generation",0))
		if generation<4:continue
		late_count+=1
		var features:=LATE.installed_features(plot)
		var family:="modern" if generation>=12 else ("industrial" if generation>=11 else "masonry")
		if features&1:family="timber"
		var wall:=String(plot.get("material_family",""))
		var material:="earth" if wall=="earth" else ("brick" if wall=="brick" else "stone")
		var chimney:=false
		var applied:Array=(plot.get("building_materials",{}) as Dictionary).get("applied",[])
		for id in ["wall_chimneys","multi_flue_chimney_stacks","narrow_throat_fireplace"]:
			if id in applied:chimney=true
		var descriptor:={"kit":"late","kind":family+"_villa","storeys":clampi(int(plot.get("storeys",1)),1,2),"features":features,"material":material+"|"+LATE.roof_for(plot)+("_chimney" if chimney else "")}
		var key:=str(descriptor)
		if not groups.has(key):groups[key]={"descriptor":descriptor,"count":0}
		groups[key].count+=1
	# Keep a small, deterministic palette even in a large mixed city. Tiny
	# shares disappear only at a five-percent presentation threshold.
	var keys:Array=groups.keys()
	keys.sort_custom(func(a:String,b:String)->bool:
		var left:int=groups[a].count;var right:int=groups[b].count
		return a<b if left==right else left>right)
	var variants:Array=[]
	for key:String in keys.slice(0,MAX_VARIANTS):
		var weight:=roundi(float(groups[key].count)/maxi(1,late_count)*20.0)
		if weight<=0:continue
		var descriptor:Dictionary=groups[key].descriptor.duplicate(true)
		descriptor["weight"]=weight
		variants.append(descriptor)
	# Many individually rare valid forms still need one truthful representative.
	if variants.is_empty() and not keys.is_empty():
		var descriptor:Dictionary=groups[keys[0]].descriptor.duplicate(true)
		descriptor["weight"]=1;variants.append(descriptor)
	# Raw source counts select the bounded palette, but must not reorder equal
	# quantized shares and reroll every farm after a minor daily change.
	variants.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a)<str(b))
	var props:Array=["woodpile"]
	for kind:String in PROP_KNOWLEDGE:
		for id:String in PROP_KNOWLEDGE[kind]:
			if id in knowledge:props.append(kind);break
	return {"homes":_homes(fabric.get("homes",[])),"late_share":roundf(float(late_count)/maxi(1,completed)*20.0)/20.0,"variants":variants,"props":props,"road_quality":roundf(clampf(float((fabric.get("effects",{}) as Dictionary).get("roads",0.0)),0.0,1.0)*20.0)/20.0,"plot_radius_km":plot_radius,"completed_residential":completed,"sampled_plots":mini(plots.size(),MAX_PLOTS)}

static func render_profile(profile:Dictionary)->Dictionary:
	var result:Dictionary={}
	for key in ["homes","late_share","variants","props","road_quality"]:
		if profile.has(key):result[key]=profile[key].duplicate(true) if profile[key] is Array or profile[key] is Dictionary else profile[key]
	return result

static func signature(profile:Dictionary)->int:
	return hash(render_profile(profile))

static func home(profile:Dictionary,stable_id:String,style:Dictionary={})->Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=hash(stable_id)
	var result:Dictionary={}
	var variants:Array=profile.get("variants",[])
	if not variants.is_empty() and rng.randf()<float(profile.get("late_share",0.0)):
		var total:=0
		for variant:Dictionary in variants:total+=int(variant.weight)
		var roll:=rng.randi_range(1,maxi(1,total))
		for variant:Dictionary in variants:
			roll-=int(variant.weight)
			if roll<=0:result=variant.duplicate(true);break
		result.erase("weight")
		result["facade"]=posmod(hash(stable_id+":facade"),3) if String(result.kind).begins_with("modern_") else 0
	else:
		var homes:Array=profile.get("homes",[1.0,0.0,0.0,0.0,0.0])
		var roll:=rng.randf();var grade:=0
		for index in homes.size():
			roll-=float(homes[index])
			if roll<=0.0:grade=index;break
		var kind:String=GRADE_KINDS[clampi(grade,0,4)]
		# A people's established vernacular still supplies its early shelter.
		var kinds:Array=style.get("kinds",[])
		if grade<=1 and not kinds.is_empty():kind=String(kinds[posmod(hash(stable_id),kinds.size())])
		result={"kit":"town" if kind in TOWN.KIT else "early","kind":kind,"storeys":1,"features":0,"material":""}
	var props:Array=["woodpile"]
	var candidates:Array=profile.get("props",[]).duplicate()
	# The late kit keeps ordinary rural stores, without inventing a machine or
	# repeating obsolete hand-querns around every industrial/modern dwelling.
	if String(result.kind).begins_with("industrial_") or String(result.kind).begins_with("modern_"):candidates=["timber_stack","baskets"]
	while props.size()<MAX_PROPS and not candidates.is_empty():
		var index:=rng.randi_range(0,candidates.size()-1)
		var kind:String=candidates.pop_at(index)
		if kind not in props:props.append(kind)
	result["props"]=props
	return result

static func mesh(descriptor:Dictionary)->Mesh:
	var kind:=String(descriptor.get("kind","rooted_lean_to"))
	match String(descriptor.get("kit","early")):
		"late":return LATE.mesh_for(kind,clampi(int(descriptor.get("storeys",1)),1,2),int(descriptor.get("features",0)),String(descriptor.get("material","stone|timber")),int(descriptor.get("facade",0)))
		"town":return TOWN.kit_mesh(TOWN.KIT.find(kind))
	return EARLY.kit_mesh(kind)

static func _homes(source:Array)->Array:
	var values:Array=[0.0,0.0,0.0,0.0,0.0]
	var total:=0.0
	for index in mini(source.size(),5):
		var value:=float(source[index])
		values[index]=maxf(0.0,value) if is_finite(value) else 0.0
		total+=values[index]
	if total<=0.0:return [1.0,0.0,0.0,0.0,0.0]
	var rounded_total:=0.0
	for index in 5:
		values[index]=roundf(float(values[index])/total*20.0);rounded_total+=values[index]
	for index in 5:values[index]=float(values[index])/rounded_total
	return values
