extends CanvasLayer
## Full-width, retained draft. Simulation ticks never rebuild the editor.
const D=preload("res://scripts/division_design.gd")
const S=preload("res://scripts/division_statistics.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Icons=preload("res://scripts/resource_icons.gd")
const Kits=preload("res://scripts/equipment_ledger.gd")
var campaign:Node
var template_id:=1
var cells:Array=[]
var selected_slot:=5
var slot_buttons:Array=[]
var stat_labels:Dictionary={}
var name_input:LineEdit
var count_input:SpinBox
var status:Label
var equipment_box:VBoxContainer
var chooser:VBoxContainer
var choices:GridContainer
var search:LineEdit
var columns:GridContainer
var stats_columns:GridContainer
var template_choices:HFlowContainer
var query:=""
var choice_page:=0
var template_page:=0
var draft_dirty:=false
var preview_drill:=.25
var composition_panel:VBoxContainer
var statistics_panel:VBoxContainer
var view_switch:HFlowContainer
var show_stats:=false
var root:PanelContainer
var notice:Label
var total_line:Label
var save_button:Button
var use_button:Button
var automatic_name:=false
var load_error:=""

func _ready()->void:
	if campaign==null:campaign=MilitaryCampaign
	layer=92
	root=PanelContainer.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(root)
	root.add_theme_stylebox_override("panel",T.paper_panel_style(false,T.RADIUS_CARD,16))
	var shell:=VBoxContainer.new();root.add_child(shell)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;shell.add_child(scroll)
	var page:=VBoxContainer.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;page.add_theme_constant_override("separation",10);scroll.add_child(page)
	var heading:=HBoxContainer.new();page.add_child(heading)
	var title:=label("DIVISION DESIGNER",24);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
	heading.add_child(button("Close",func():queue_free()))
	template_choices=HFlowContainer.new();template_choices.name="Designs";page.add_child(template_choices)
	var name_row:=HBoxContainer.new();page.add_child(name_row)
	name_input=LineEdit.new();name_input.name="DesignName";name_input.max_length=64;name_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_row.add_child(name_input)
	name_input.text_changed.connect(func(_s:String):draft_dirty=true;automatic_name=false)
	name_row.add_child(button("New",_new_design));name_row.add_child(button("Duplicate",_duplicate))
	total_line=label("",14);total_line.name="Manpower";page.add_child(total_line)
	view_switch=HFlowContainer.new();page.add_child(view_switch)
	view_switch.add_child(button("Composition",func():show_stats=false;_layout()))
	view_switch.add_child(button("Statistics & cost",func():show_stats=true;_layout()))
	columns=GridContainer.new();columns.columns=2;columns.add_theme_constant_override("h_separation",20);page.add_child(columns)
	var layout:=VBoxContainer.new();composition_panel=layout;layout.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(layout)
	layout.add_child(label("SUPPORT                 COMBAT GROUPS",13))
	var grid:=GridContainer.new();grid.columns=6;grid.name="FormationGrid";grid.add_theme_constant_override("h_separation",5);grid.add_theme_constant_override("v_separation",5);layout.add_child(grid)
	slot_buttons.resize(30)
	for row in 5:
		for column in 6:
			var index:=row if column==0 else 5+row*5+column-1
			var b:=button("+",_select_slot.bind(index));b.name="Slot%d"%index;b.toggle_mode=true;b.custom_minimum_size=Vector2(54,44);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			b.expand_icon=true;b.add_theme_constant_override("icon_max_width",26);b.add_theme_font_size_override("font_size",12)
			grid.add_child(b);slot_buttons[index]=b
	var controls:=HBoxContainer.new();layout.add_child(controls)
	controls.add_child(label("People in selected group",13))
	count_input=SpinBox.new();count_input.name="GroupSize";count_input.min_value=1;count_input.max_value=D.MAX_MEN;count_input.step=1;count_input.custom_minimum_size.x=90;controls.add_child(count_input)
	count_input.value_changed.connect(_change_count)
	controls.add_child(button("Remove",_remove))
	var scale:=HFlowContainer.new();scale.name="SizePresets";layout.add_child(scale)
	for size:int in D.size_presets(campaign.watch_manpower()):scale.add_child(button(str(size),func():count_input.value=size))
	chooser=VBoxContainer.new();chooser.name="UnitChooser";layout.add_child(chooser)
	search=LineEdit.new();search.placeholder_text="Find a unit or equipment";chooser.add_child(search)
	search.text_changed.connect(func(value:String):query=value.to_lower();choice_page=0;_choices())
	choices=GridContainer.new();choices.columns=2;chooser.add_child(choices)
	var pages:=HBoxContainer.new();chooser.add_child(pages)
	pages.add_child(button("‹",func():choice_page=maxi(0,choice_page-1);_choices()))
	pages.add_child(button("›",func():choice_page+=1;_choices()))
	status=label("",12);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;chooser.add_child(status)
	var stats:=VBoxContainer.new();statistics_panel=stats;stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(stats)
	var preview:=HFlowContainer.new();stats.add_child(preview)
	preview.add_child(label("AT FULL EQUIPMENT",12))
	preview.add_child(button("Raw drill",func():preview_drill=.25;_stats()))
	preview.add_child(button("Trained",func():preview_drill=.8;_stats()))
	stats_columns=GridContainer.new();stats_columns.columns=3;stats_columns.add_theme_constant_override("h_separation",14);stats.add_child(stats_columns)
	for section:Array in [["BASE STATS",S.BASE_FIELDS],["COMBAT STATS",S.COMBAT_FIELDS]]:
		var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stats_columns.add_child(box);box.add_child(label(section[0],13))
		for field:Array in section[1]:
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);box.add_child(row)
			row.tooltip_text=String(S.TIPS.get(field[0],""))
			var caption:=label(field[1],12);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(caption)
			var value:=label("0",12);value.name=String(field[0]);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(value);stat_labels[field[0]]=value
			value.tooltip_text=row.tooltip_text;caption.tooltip_text=row.tooltip_text
	equipment_box=VBoxContainer.new();equipment_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stats_columns.add_child(equipment_box)
	var footer:=HFlowContainer.new();shell.add_child(footer)
	save_button=button("Save design",_save);save_button.name="SaveDesign";footer.add_child(save_button)
	use_button=button("Use as army standard",_use);use_button.name="UseStandard";footer.add_child(use_button)
	footer.add_child(button("Reset draft",func():_load_design(template_id)))
	notice=label("",13);notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;shell.add_child(notice)
	var source:=label("People → Defense supplies the manpower. Generals command.",12);source.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;shell.add_child(source)
	campaign._ensure_army_templates()
	if campaign._template_index(template_id)<0:template_id=int(campaign.army_templates[0].template_id)
	_load_design(template_id)
	root.resized.connect(_layout);_layout()

func label(text:String,points:int)->Label:
	var l:=Label.new();l.text=text;l.add_theme_font_override("font",T.font("ui"));l.add_theme_font_size_override("font_size",points);l.add_theme_color_override("font_color",T.INK);return l
func button(text:String,action:Callable)->Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=32;T.apply_button_style(b);b.add_theme_font_size_override("font_size",13)
	for state:String in ["normal","hover","pressed","disabled"]:
		var style:=b.get_theme_stylebox(state).duplicate() as StyleBox;style.content_margin_top=4;style.content_margin_bottom=4;style.content_margin_left=8;style.content_margin_right=8;b.add_theme_stylebox_override(state,style)
	b.pressed.connect(action);return b
func clear(box:Node)->void:
	for child in box.get_children():box.remove_child(child);child.queue_free()
func _layout()->void:
	columns.columns=2 if root.size.x>=1100 else 1
	stats_columns.columns=3 if root.size.x>=650 else 2
	view_switch.visible=root.size.x<1100
	composition_panel.visible=root.size.x>=1100 or not show_stats
	statistics_panel.visible=root.size.x>=1100 or show_stats
func _load_design(id:int)->void:
	var index:int=campaign._template_index(id)
	if index<0:return
	template_id=id;cells=D.slots(campaign.army_templates[index]);name_input.text=String(campaign.army_templates[index].name);draft_dirty=false
	automatic_name=bool(campaign.army_templates[index].get("automatic_name",false)) or (id==1 and name_input.text=="LEVY BAND")
	load_error=D.migration_error(campaign.army_templates[index])
	selected_slot=5;_templates();_refresh()
	if not load_error.is_empty():notice.text=load_error
func _templates()->void:
	clear(template_choices)
	var designs:Array=campaign.army_templates
	template_page=clampi(template_page,0,maxi(0,(designs.size()-1)/6))
	for t:Dictionary in designs.slice(template_page*6,template_page*6+6):
		var id:=int(t.template_id)
		var b:=button(String(t.name)+( " • standard" if id==campaign.active_division_template_id else ""),func():
			if draft_dirty:notice.text="Save or reset this draft before switching designs.";return
			_load_design(id))
		b.toggle_mode=true;b.set_pressed_no_signal(id==template_id);template_choices.add_child(b)
	if designs.size()>6:template_choices.add_child(button("More designs ›",func():template_page=(template_page+1)%ceili(designs.size()/6.0);_templates()))
func _new_design()->void:
	if draft_dirty:notice.text="Save or reset this draft before creating another design.";return
	var result:Dictionary=campaign.create_army_template("New formation")
	if result.has("error"):notice.text=result.error;return
	_load_design(int(result.template.template_id));automatic_name=true
func _duplicate()->void:
	var result:Dictionary=campaign.create_army_template(name_input.text+" copy")
	if result.has("error"):notice.text=result.error;return
	var copy_id:=int(result.template.template_id)
	var saved:=D.save(campaign,copy_id,name_input.text+" copy",cells)
	if saved.has("error"):
		campaign.delete_army_template(copy_id);notice.text=saved.error;return
	_load_design(copy_id)
func _select_slot(index:int)->void:
	selected_slot=index;choice_page=0;_refresh()
func _change_count(value:float)->void:
	if cells.is_empty() or (cells[selected_slot] as Dictionary).is_empty():return
	cells[selected_slot].count=int(value);draft_dirty=true;_refresh()
func _remove()->void:
	cells[selected_slot]={};draft_dirty=true;_refresh()
func _refresh()->void:
	if automatic_name:name_input.text=D.formation_name(D.entries(cells))
	for i in 30:
		var b:Button=slot_buttons[i];var cell:Dictionary=cells[i]
		b.set_pressed_no_signal(i==selected_slot)
		b.text="+";b.icon=null;b.tooltip_text="Add a support team" if i<5 else "Add a combat group"
		if not cell.is_empty():
			b.text=str(int(cell.count));b.icon=Icons.equipment_texture(String(cell.weapon),T.INK,T.GOLD,28)
			b.tooltip_text="%s · %s\n%d people"%[D.Catalog.archetype(String(cell.unit)).label,Kits.label(String(cell.weapon)),int(cell.count)]
	var selected:Dictionary=cells[selected_slot]
	count_input.set_value_no_signal(float(selected.get("count",1)))
	_choices();_stats()
func _choices()->void:
	clear(choices)
	var rows:Array=[]
	for unit:String in D.Catalog.ARCHETYPES:
		if selected_slot<5 and not D.support(unit):continue
		if selected_slot>=5 and String(D.Catalog.archetype(unit).get("branch",""))=="field_support":continue
		for weapon:String in D.Catalog.equipment_for(unit):
			var title:=String(D.Catalog.archetype(unit).label)+" · "+Kits.label(weapon)
			if not query.is_empty() and not title.to_lower().contains(query):continue
			var gate:Dictionary=campaign._training_gate(unit,weapon)
			rows.append({"unit":unit,"weapon":weapon,"title":title,"gate":gate})
	rows.sort_custom(func(a:Dictionary,b:Dictionary):return a.gate.is_empty() if a.gate.is_empty()!=b.gate.is_empty() else (Kits.year(a.weapon)<Kits.year(b.weapon) if Kits.year(a.weapon)!=Kits.year(b.weapon) else a.title<b.title))
	choice_page=clampi(choice_page,0,maxi(0,(rows.size()-1)/6))
	for r:Dictionary in rows.slice(choice_page*6,choice_page*6+6):
		var b:=button(String(D.Catalog.archetype(r.unit).label)+"\n"+Kits.label(r.weapon),func():
			cells[selected_slot]={"unit":r.unit,"weapon":r.weapon,"count":int(count_input.value)};draft_dirty=true;_refresh())
		b.name="Choose_"+String(r.unit)+"_"+String(r.weapon);b.disabled=not r.gate.is_empty();b.tooltip_text=String(r.gate.get("error",D.Catalog.archetype(r.unit).get("purpose","")))
		b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.custom_minimum_size=Vector2(140,40);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.icon=Icons.equipment_texture(r.weapon,T.INK,T.GOLD,24);choices.add_child(b)
	status.text="%s · %d / %d"%["Support choices" if selected_slot<5 else "Combat choices",choice_page+1,maxi(1,ceili(rows.size()/6.0))]
	if rows.is_empty():status.text="No matching units."
func _stats()->void:
	var stats:=S.read(campaign,D.entries(cells),preview_drill)
	for fields:Array in [S.BASE_FIELDS,S.COMBAT_FIELDS]:
		for f:Array in fields:stat_labels[f[0]].text=S.number(float(stats[f[0]]))+(" "+String(f[2]) if not String(f[2]).is_empty() else "")
	var allocated:int=campaign.watch_manpower()
	total_line.text="%d people per formation   •   %d allocated to Defense   •   %s drill"%[stats.manpower,allocated,"Raw" if preview_drill<.5 else "Trained"]
	if int(stats.manpower)>allocated:total_line.text+="   •   Short %d people"%(int(stats.manpower)-allocated)
	clear(equipment_box);equipment_box.add_child(label("EQUIPMENT COST",13))
	equipment_box.add_child(label("Manpower  %d"%stats.manpower,13))
	equipment_box.add_child(label("Training  %s days"%S.number(stats.training_time),13))
	equipment_box.add_child(label("Production  %s work"%S.number(stats.production_cost),13))
	for item:String in stats.equipment:
		var row:=HBoxContainer.new();equipment_box.add_child(row)
		var icon:=TextureRect.new();icon.texture=Icons.equipment_texture(item,T.INK,T.GOLD,24);icon.custom_minimum_size=Vector2(24,24);row.add_child(icon)
		var l:=label("%s ×%d"%[Kits.label(item),stats.equipment[item]],12);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(l)
	var error:=load_error if not load_error.is_empty() else D.validate(campaign,cells)
	save_button.disabled=not error.is_empty();use_button.disabled=not error.is_empty()
	save_button.tooltip_text=error;use_button.tooltip_text=error
func _save()->bool:
	var result:=D.save(campaign,template_id,name_input.text,cells);notice.text=String(result.get("error",result.get("message","")))
	if result.has("error"):return false
	campaign.army_templates[campaign._template_index(template_id)]["automatic_name"]=automatic_name
	draft_dirty=false;_templates();return true
func _use()->void:
	if not _save():return
	var result:=D.activate(campaign,template_id);notice.text=String(result.get("error",result.get("message","")));_templates()
