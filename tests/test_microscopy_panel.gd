extends GdUnitTestSuite
const LabPanel=preload("res://scripts/hud/microscopy_panel.gd")
const Samples=preload("res://scripts/microscopy_samples.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("lab_panel",923)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func fixture()->VBoxContainer:
	var panel=auto_free(LabPanel.new());panel.subject="laboratory_notebooks";add_child(panel);return panel
func test_pause_changes_only_local_lab_and_releases_reserved_workers()->void:
	WorldSimulation.scoped("lab_panel",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.known_discoveries.append("laboratory_notebooks");state.population_allocations.Knowledge=8
		var before:Dictionary=state.population_allocations.duplicate(true)
		var panel:=fixture();var workers:float=state.effective_workers("Knowledge")
		assert_str(panel.details.text).contains("reserved after absences and clinical care")
		panel.toggle.pressed.emit()
		assert_bool(state.microscopy.enabled).is_false()
		assert_float(state.effective_workers("Knowledge")).is_greater(workers)
		assert_dict(state.population_allocations).is_equal(before)
		panel.toggle.pressed.emit();assert_bool(state.microscopy.enabled).is_true())
func test_panel_reports_retained_measurement_without_exposing_latent_changes()->void:
	WorldSimulation.scoped("lab_panel",func()->void:
		var sample:=Samples.add(WorldSimulation.state.microscopy,"starter",1,0,"home",1,.01,{"viability":1.0})
		Samples.measure(WorldSimulation.state.microscopy,sample,2,false,[])
		var panel:=fixture();var before:String=panel.details.text
		sample.cells=10000;sample.viability=.01;panel.refresh()
		assert_str(panel.details.text).is_equal(before)
		assert_str(before).contains("observed day 2, 1.00 visible cells")
		assert_str(before).contains("Bench awaiting"))
func test_every_microscopy_identity_has_panel_and_unrelated_ids_do_not()->void:
	for entry:Dictionary in preload("res://scripts/microscopy_knowledge.gd").entries():assert_bool(LabPanel.supports(entry.id)).is_true()
	assert_bool(LabPanel.supports("plain_weaving")).is_false()
