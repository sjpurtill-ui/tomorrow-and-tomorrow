extends VBoxContainer
const T=preload("res://scripts/hud/hud_tokens.gd")
const S=preload("res://scripts/hud/econ_sheet.gd")
func setup(data:Dictionary)->void:
	name="PopulationBalance";add_theme_constant_override("separation",8)
	var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",18);row.add_theme_constant_override("v_separation",8);add_child(row)
	var known:=bool(data.get("known",false));var vitals:=bool(data.get("vitals_known",false))
	for item:Array in [["Previously",S.n(data.get("before",0)) if known else "Unknown"],["+ Born",S.n(data.get("births",0)) if vitals else "Unknown"],["− Died",S.n(data.get("deaths",0)) if vitals else "Unknown"],["± Other change","%+d" % int(data.get("other",0)) if vitals else "Unknown"],["= Alive now",S.n(data.get("current",0))]]:
		var cell:=VBoxContainer.new();cell.custom_minimum_size.x=112;cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(cell)
		cell.add_child(T.make_label(item[0],13,T.INK_MUTED));cell.add_child(T.make_label(item[1],24,T.INK))
	var note:=T.make_label("All our people · days %d–%d. Other change is the remaining recorded difference; arrivals and departures are not separately recorded." % [int(data.from_day),int(data.to_day)] if known else "All our people. A dated population baseline is needed to reconcile change.",13,T.INK_MUTED)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(note)
	if known and not vitals:
		var warning:=T.make_label("Birth/death tracking does not cover this whole interval. Recorded population change: %+d." % int(data.change),13,T.AMBER);warning.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(warning)
