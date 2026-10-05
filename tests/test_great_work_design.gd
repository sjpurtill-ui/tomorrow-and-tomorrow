extends GdUnitTestSuite
const Design:=preload("res://scripts/hud/great_work_design.gd")
const Concept:=preload("res://scripts/wonder_concept.gd")
const Catalog:=preload("res://scripts/undertaking_catalog.gd")

func test_catalog_is_exhaustive_without_a_generic_fallback()->void:
	assert_int(Design.catalog_ids().size()).is_equal(Concept.FORMS.size()+Catalog.all().size())
	for form:String in Concept.FORMS:
		var id:=Concept.make_id(form,"honor_dead","grand",String(Concept.FORMS[form].materials[0]),1,"design")
		var design:=Design.describe({"id":id})
		assert_bool(design.valid).is_true()
		assert_str(design.design_id).is_equal("form:"+form)
		assert_str(design.form).is_equal(form)
		assert_int(design.construction_labels.size()).is_equal(4)
		assert_str(design.emblem).is_not_empty()
	for entry:Dictionary in Catalog.all():
		var design:=Design.describe({"id":entry.id})
		assert_bool(design.valid).is_true()
		assert_str(design.design_id).is_equal("legacy:"+String(entry.id))
		assert_str(design.title).is_equal(entry.title)
		assert_str(design.purpose).is_equal(entry.purpose)
	assert_bool(Design.describe({"id":"missing_work"}).valid).is_false()

func test_all_purposes_preserve_their_own_symbol_and_words()->void:
	assert_int(Design.PURPOSES.size()).is_equal(Concept.PURPOSES.size())
	var symbols:Dictionary={}
	for purpose:String in Concept.PURPOSES:
		var design:=Design.describe({"id":Concept.make_id("ring",purpose,"grand","stone",0,"purpose")})
		assert_str(design.purpose).is_equal(purpose)
		assert_str(design.purpose_words).is_not_empty()
		symbols[design.purpose_emblem]=true
	assert_int(symbols.size()).is_equal(Concept.PURPOSES.size())

func test_saved_identity_survives_changes_to_live_calendar_and_technology()->void:
	var source:={"work_id":Concept.make_id("archive","remember_knowledge","audacious","stone",2,"unique"),"progress":.52}
	var before:=var_to_str(source)
	var first:=Design.describe(source)
	# Unrelated UI/current-world hints must not rewrite the saved commission.
	source["year"]=3000;source["tier"]=5;source["known"]=["solid_state_lighting"]
	var second:=Design.describe(source)
	assert_dict(second).is_equal(first)
	source.erase("year");source.erase("tier");source.erase("known")
	assert_str(var_to_str(source)).is_equal(before)
	assert_str(first.form).is_equal("archive")
	assert_int(first.tier).is_equal(2)

func test_ambition_and_material_are_recorded_visual_variants()->void:
	var last_scale:=0.0
	for ambition:String in Concept.AMBITIONS:
		var d:=Design.describe({"id":Concept.make_id("tower","awe_rivals",ambition,"iron",4,"tower")})
		assert_float(d.scale).is_greater(last_scale)
		last_scale=d.scale
		assert_str(d.material).is_equal("iron")
		assert_int(d.tier).is_equal(4)
	var a:=Design.describe({"id":Concept.make_id("ring","honor_dead","grand","stone",0,"one")})
	var b:=Design.describe({"id":Concept.make_id("ring","honor_dead","grand","stone",0,"two")})
	assert_int(a.seed).is_not_equal(b.seed)

func test_profiles_do_not_share_mutable_construction_labels()->void:
	var work:={"id":"ancestor_ring"}
	var first:=Design.describe(work)
	first.construction_labels[0]="Changed by a view"
	assert_str(Design.describe(work).construction_labels[0]).is_not_equal("Changed by a view")

func test_legacy_identity_preserves_specialized_forms_and_materials()->void:
	assert_str(Design.describe({"id":"rain_court"}).form).is_equal("cistern")
	assert_str(Design.describe({"id":"star_steps"}).form).is_equal("observatory")
	assert_str(Design.describe({"id":"kiln_court"}).form).is_equal("kilns")
	assert_str(Design.describe({"id":"great_hall"}).material).is_equal("timber")
	assert_str(Design.describe({"id":"flood_terraces"}).material).is_equal("earth")

func test_ring_phases_follow_recorded_joinery_and_material()->void:
	var early:=Design.describe({"id":Concept.make_id("ring","give_thanks","grand","timber",0,"posts")})
	assert_str(early.title).contains("posts")
	assert_str(early.construction_labels[1]).is_equal("Raising posts")
	assert_str(early.construction_labels[2]).is_equal("Finishing the circle")
	var joined:=Design.describe({"id":Concept.make_id("ring","give_thanks","grand","stone",1,"joined")})
	assert_str(joined.construction_labels[2]).is_equal("Setting lintels")
