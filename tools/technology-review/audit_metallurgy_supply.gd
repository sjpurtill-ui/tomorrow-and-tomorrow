extends SceneTree
## Structural audit of registered entries or isolated candidates; no registration writes.
func _initialize()->void:call_deferred("run")
func run()->void:
	for id:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(id).set_process(false)
	var discovery:=root.get_node("DiscoverySystem");discovery.initialize()
	var ids:Array=[]
	var catalog:Array=discovery.technology_catalog.duplicate(true)
	var proposed:Array=preload("res://scripts/metallurgy_process_knowledge.gd").entries()
	for entry:Dictionary in proposed:
		if not discovery.catalog_by_id.has(entry.id):catalog.append(entry)
	for entry:Dictionary in discovery.technology_catalog:ids.append(entry.id)
	for entry:Dictionary in proposed:
		if entry.id not in ids:ids.append(entry.id)
	var products:Dictionary=load("res://scripts/civilian_industry.gd").PRODUCTS.duplicate(true)
	for recipe:Dictionary in products.values():
		if recipe.has("thermal_program"):recipe.machine_inspection=load("res://scripts/metallurgy_sections.gd").COST
		if recipe.has("induction_frequency"):recipe.machine_inspection=load("res://scripts/induction_workshop.gd").INSPECTION
	var audit=preload("res://tools/production_dependency_audit.gd")
	var result:Dictionary=audit.audit(products,load("res://scripts/technology_operations.gd").PLANTS,root.get_node("ResourceSystem").catalog.keys()+load("res://scripts/household_clothing.gd").HUNTING_BYPRODUCTS.keys(),ids,audit.operating_routes(),load("res://scripts/sec_specialist_supply.gd").RESERVE)
	var pathways:Script=load("res://scripts/knowledge_pathways.gd")
	var graph:Array=[]
	for entry:Dictionary in catalog:graph.append(pathways.graph_entry(entry))
	var dormant_audit:Script=load("res://tools/technology-review/dormant_or_audit.gd")
	graph=dormant_audit.factor_common(graph,catalog)
	var dormant:Array=dormant_audit.pending(graph)
	result.errors.append_array(load("res://scripts/technology_requirements.gd").validate(graph,dormant))
	var authored:Dictionary={}
	for filename:String in ["materials-construction-flight.json","materials-process-depth.json","manufacturing-process-depth.json"]:
		var records:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://docs/technology-review/master-catalog/"+filename))
		if not records is Array:result.errors.append("Cannot read authored source: "+filename);continue
		for entry:Dictionary in records:authored[entry.id]=entry
	var baseline:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/technology-review/master-catalog/implemented-baseline.json"))
	for row:Dictionary in baseline.get("items",[]):
		var reconciliation:Dictionary=row.get("implementation_reconciliation",{})
		if reconciliation.get("editorial_source","") not in ["materials-construction-flight.json","materials-process-depth.json","manufacturing-process-depth.json"]:continue
		if not authored.has(row.id):authored[row.id]={"id":row.id,"name":row.name,"requires_all":reconciliation.get("previous_requires_all",[]),"requires_any":reconciliation.get("previous_requires_any",[])}
	for entry:Dictionary in proposed:
		if not authored.has(entry.id):result.errors.append("Missing authored identity: "+String(entry.id));continue
		for field:String in ["name","requires_all","requires_any"]:
			if entry.get(field)!=authored[entry.id].get(field):result.errors.append(String(entry.id)+": changed authored "+field)
		for item:String in entry.get("production_items",[]):
			if not products.has(item) or products[item].gate!=entry.id:result.errors.append(String(entry.id)+": incorrect production binding "+item)
		for item:String in entry.get("inspection_items",[]):
			if not products.has(item) or products[item].get("inspection_gate")!=entry.id:result.errors.append(String(entry.id)+": incorrect inspection binding "+item)
	for item:String in products:
		var gate:=String(products[item].get("inspection_gate",""))
		if not gate.is_empty() and gate not in ids:result.errors.append(item+": unresolved inspection gate "+gate)
	result.integrated_definitions=discovery.technology_catalog.size()
	result.unregistered_candidates=catalog.size()-discovery.technology_catalog.size()
	result.candidate_graph_definitions=catalog.size()
	result.assumptions="Structural sources only; all knowledge and raw resources assumed available. Any not-yet-registered metallurgy IDs are supplied locally; registered entries are used directly. Quality success, actual quantities, calendar, labor, capital qualification and acquisition are not proved. Includes deferred section/induction inspection inputs."
	print(JSON.stringify(result))
	quit(0 if result.errors.is_empty() and result.blocked_products.is_empty() and result.blocked_plants.is_empty() else 1)
