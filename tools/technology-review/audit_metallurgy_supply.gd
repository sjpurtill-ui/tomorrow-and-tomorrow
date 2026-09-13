extends SceneTree
## Isolated structural audit only; does not register prototype discoveries.
func _initialize()->void:call_deferred("run")
func run()->void:
	for id:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(id).set_process(false)
	var discovery:=root.get_node("DiscoverySystem");discovery.initialize()
	var ids:Array=[]
	for entry:Dictionary in discovery.technology_catalog:ids.append(entry.id)
	for entry:Dictionary in preload("res://scripts/metallurgy_process_knowledge.gd").entries():ids.append(entry.id)
	var products:Dictionary=load("res://scripts/civilian_industry.gd").PRODUCTS.duplicate(true)
	for recipe:Dictionary in products.values():
		if recipe.has("thermal_program"):recipe.machine_inspection=load("res://scripts/metallurgy_sections.gd").COST
		if recipe.has("induction_frequency"):recipe.machine_inspection=load("res://scripts/induction_workshop.gd").INSPECTION
	var audit=preload("res://tools/production_dependency_audit.gd")
	var result:Dictionary=audit.audit(products,load("res://scripts/technology_operations.gd").PLANTS,root.get_node("ResourceSystem").catalog.keys()+load("res://scripts/household_clothing.gd").HUNTING_BYPRODUCTS.keys(),ids,audit.operating_routes(),load("res://scripts/sec_specialist_supply.gd").RESERVE)
	result.assumptions="Structural sources only; all knowledge and raw resources assumed available. The twelve metallurgy IDs are supplied locally to this audit without registration. Quality success, actual quantities, calendar, labor, capital qualification and acquisition are not proved. Includes deferred section/induction inspection inputs."
	print(JSON.stringify(result))
	quit(0 if result.errors.is_empty() and result.blocked_products.is_empty() and result.blocked_plants.is_empty() else 1)
