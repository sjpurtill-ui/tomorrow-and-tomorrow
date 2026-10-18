extends VBoxContainer
## A retained, presentation-only view of the realm's household wealth and purse.
## The board supplies exact readings and the existing command callbacks.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const S:=preload("res://scripts/hud/econ_sheet.gd")
const ART_PATH:="res://assets/ui/wealth/prosperity-households.jpg"
const FIFTHS:=["Poorest fifth","Second fifth","Middle fifth","Fourth fifth","Wealthiest fifth"]
var data:Dictionary={}
var refs:Dictionary={}
var levels:Dictionary={}
var funding:Dictionary={}
var quintiles:Array=[]
var picture:HouseholdPicture
var fifths:WealthShares
var policy:GridContainer
var spending:GridContainer

func setup(block:Dictionary)->void:
	name="ProsperityAndPressure";theme=T.control_theme();size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	var title:=BoxContainer.new();title.name="ProsperityHeader";title.add_theme_constant_override("separation",12);add_child(title);refs.header=title
	var heading:=VBoxContainer.new();heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_theme_constant_override("separation",2);title.add_child(heading)
	heading.add_child(S.label("PROSPERITY & PRESSURE",14,T.INK_MUTED))
	heading.add_child(_label("Who shares in our prosperity?",23,T.INK,true))
	var totals:=VBoxContainer.new();totals.name="ProsperityTotals";totals.custom_minimum_size.x=240;totals.size_flags_horizontal=Control.SIZE_FILL;totals.add_theme_constant_override("separation",2);title.add_child(totals);refs.totals=totals
	refs.households=_label("",14,T.INK_MUTED);refs.households.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;totals.add_child(refs.households)
	refs.store=_label("",16,T.INK,true);refs.store.name="StoreAnswer";refs.store.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;totals.add_child(refs.store)
	refs.store_name=_label("",14,T.INK_MUTED);refs.store_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;totals.add_child(refs.store_name)
	picture=HouseholdPicture.new();picture.name="ProsperityPainting";picture.custom_minimum_size.y=200;add_child(picture)
	picture.tooltip_text="An illustrative view of households with different means. The painting is not a record of this settlement's buildings or a count of its people."
	if ResourceLoader.exists(ART_PATH):picture.texture=load(ART_PATH)
	elif FileAccess.file_exists(ART_PATH):picture.texture=ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(ART_PATH)))
	var share_head:=HFlowContainer.new();share_head.add_theme_constant_override("h_separation",18);add_child(share_head)
	share_head.add_child(S.label("Who holds the wealth",17,T.INK,true));share_head.add_child(S.label("Each group = one fifth of households",14,T.INK_MUTED))
	fifths=WealthShares.new();fifths.name="Fifths";fifths.custom_minimum_size.y=64;add_child(fifths)
	var shares:=GridContainer.new();shares.name="HouseholdWealthShares";shares.columns=5;shares.add_theme_constant_override("h_separation",10);add_child(shares)
	for index:int in 5:
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_constant_override("separation",2);shares.add_child(cell)
		var amount:=S.label("",16,T.INK,true);amount.name="WealthShare_"+str(index);amount.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cell.add_child(amount)
		var fifth_name:=_label(FIFTHS[index],14,T.INK_MUTED);fifth_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cell.add_child(fifth_name)
		quintiles.append(amount)
	refs.share_note=_label("",14,T.INK_MUTED);refs.share_note.name="Shares";add_child(refs.share_note)
	add_child(HSeparator.new())
	policy=GridContainer.new();policy.name="WealthColumns";policy.columns=2;policy.add_theme_constant_override("h_separation",24);policy.add_theme_constant_override("v_separation",12);add_child(policy)
	var pressure:=VBoxContainer.new();pressure.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pressure.add_theme_constant_override("separation",4);policy.add_child(pressure)
	refs.pressure=_label("",17,T.INK,true);refs.pressure.name="Pressure";pressure.add_child(refs.pressure)
	refs.causes=_label("",14,T.INK_MUTED);refs.causes.name="PressureContributors";pressure.add_child(refs.causes)
	var levy:=VBoxContainer.new();levy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;levy.add_theme_constant_override("separation",4);policy.add_child(levy)
	refs.levy=_label("",17,T.INK,true);refs.levy.name="LevyNow";levy.add_child(refs.levy)
	var choices:=HFlowContainer.new();choices.name="Levels";choices.add_theme_constant_override("h_separation",6);choices.add_theme_constant_override("v_separation",4);levy.add_child(choices)
	for key:String in ["light","usual","heavy"]:
		var button:=S.verb(key.capitalize(),func():_invoke("on_levy",key));button.name="Level_"+key;button.toggle_mode=true;choices.add_child(button);levels[key]=button
	refs.levy_cost=_label("",14,T.INK_MUTED);refs.levy_cost.name="LevyCost";levy.add_child(refs.levy_cost)
	add_child(HSeparator.new())
	var support:=HFlowContainer.new();support.add_theme_constant_override("h_separation",18);add_child(support)
	refs.funding_title=S.label("",17,T.INK,true);support.add_child(refs.funding_title)
	refs.funding_unit=S.label("",14,T.INK_MUTED);support.add_child(refs.funding_unit)
	spending=GridContainer.new();spending.name="FundingDecisions";spending.columns=3;spending.add_theme_constant_override("h_separation",12);spending.add_theme_constant_override("v_separation",8);add_child(spending)
	for spec:Array in [["crews","build","Hire crews"],["scholars","learn","Fund scholars"],["army","watch","Pay soldiers"]]:
		var key:=String(spec[0]);var cell:=VBoxContainer.new();cell.name="Line_"+key;cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_constant_override("separation",4);spending.add_child(cell)
		var action:=HBoxContainer.new();action.add_theme_constant_override("separation",6);cell.add_child(action)
		action.add_child(S.icon(String(spec[1]),20,"people"))
		var label:=_label(String(spec[2]),15,T.INK,true);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;action.add_child(label)
		var toggle:=CheckButton.new();toggle.name="Toggle";toggle.custom_minimum_size=Vector2(44,40);toggle.focus_mode=Control.FOCUS_ALL;action.add_child(toggle)
		toggle.pressed.connect(func():_invoke("on_line",key,not bool((data.get("lines",{}) as Dictionary).get(key,{}).get("on",false))))
		var cost:=_label("",16,T.INK,true);cost.name="Cost";cell.add_child(cost)
		var effect:=_label("",14,T.INK_MUTED);effect.name="Effect";cell.add_child(effect)
		var who:=_label("",14,T.INK_MUTED);who.name="Who";cell.add_child(who)
		var coverage:=ProgressBar.new();coverage.name="FundingCoverage";coverage.show_percentage=false;coverage.custom_minimum_size.y=6;coverage.add_theme_stylebox_override("background",T.flat(T.TRACK));coverage.add_theme_stylebox_override("fill",T.flat(T.TEAL));cell.add_child(coverage)
		var coverage_words:=_label("",12,T.INK_MUTED);cell.add_child(coverage_words)
		funding[key]={"coverage":coverage,"coverage_words":coverage_words,"cell":cell,"toggle":toggle,"cost":cost,"effect":effect,"who":who}
	refs.unpaid=_label("",14,T.RED_TEXT);refs.unpaid.name="Unpaid";add_child(refs.unpaid)
	refs.forecast=_label("",14,T.INK_MUTED);refs.forecast.name="Verdict";add_child(refs.forecast)
	refs.summary=_label("",14,T.INK_MUTED);refs.summary.name="HouseholdSummary";add_child(refs.summary)
	resized.connect(_arrange);update_view(block)

func update_view(block:Dictionary)->void:
	data=block
	S.put(refs.households,String(data.get("households","")))
	S.put(refs.store,String(data.get("balance","")));refs.store.tooltip_text=String(data.get("balance_tip",""))
	S.put(refs.store_name,String(data.get("account_name","")))
	fifths.values=data.get("shares",[]);fifths.queue_redraw()
	var known:=fifths.values.size()==5
	for index:int in 5:S.put(quintiles[index],"%s%%" % S.n(float(fifths.values[index])*100.0) if known else "—")
	S.put(refs.share_note,"Shares of household wealth, not numbers of people. Rounded readings." if known else "Household wealth shares have not been recorded.")
	var pressure_known:=bool(data.get("pressure_known",false));var pressure:=float(data.get("pressure",0.0))
	S.put(refs.pressure,"Pressure on trust target  %s%s" % ["−" if pressure<0.0 else "+" if pressure>0.0 else "",S.n(absf(pressure))] if pressure_known else "Pressure on trust target  —",T.AMBER_TEXT if pressure_known and pressure<0.0 else T.INK)
	S.put(refs.causes,String(data.get("causes","")));refs.pressure.tooltip_text=String(data.get("pressure_tip",""))
	S.put(refs.levy,String(data.get("levy_reading","")));S.put(refs.levy_cost,String(data.get("levy_cost","")))
	for key:String in levels:
		var button:Button=levels[key];button.set_pressed_no_signal(key==String(data.get("levy","")))
		button.tooltip_text=String((data.get("level_tips",{}) as Dictionary).get(key,""))
	S.put(refs.funding_title,"What %s supports" % String(data.get("account_name","the common store")))
	S.put(refs.funding_unit,"Estimated costs · %s / season" % String(data.get("unit","goods")))
	for key:String in funding:
		var item:Dictionary=(data.get("lines",{}) as Dictionary).get(key,{})
		var row:Dictionary=funding[key];var on:=bool(item.get("on",false))
		row.toggle.set_pressed_no_signal(on);row.toggle.tooltip_text=String(item.get("tip",""))
		var coverage:Variant=item.get("coverage",null);row.coverage.visible=coverage!=null
		if coverage!=null:row.coverage.value=clampf(float(coverage),0,1)*100
		row.coverage_words.text=("%.0f%% funded in the latest account" % (clampf(float(coverage),0,1)*100) if coverage!=null else "Funding coverage not recorded") if on else "Funding disabled"
		S.put(row.cost,String(item.get("cost","")));S.put(row.effect,String(item.get("effect","")),T.TEAL if on else T.INK_MUTED);S.put(row.who,String(item.get("who","")))
	S.put(refs.unpaid,String(data.get("unpaid","")));refs.unpaid.visible=not refs.unpaid.text.is_empty()
	S.put(refs.forecast,String(data.get("forecast","")));refs.forecast.tooltip_text=String(data.get("forecast_tip",""))
	S.put(refs.summary,String(data.get("summary","")))
	_arrange.call_deferred()

func _invoke(key:String,first:Variant=null,second:Variant=null)->void:
	var callback:Variant=data.get(key)
	if not callback is Callable:return
	if second!=null:callback.call(first,second)
	elif first!=null:callback.call(first)
	else:callback.call()

func _arrange()->void:
	if picture==null:return
	var narrow:=size.x>0.0 and size.x<560.0
	refs.header.vertical=narrow
	refs.totals.custom_minimum_size.x=0.0 if narrow else clampf(size.x*0.32,240.0,360.0)
	for key:String in ["households","store","store_name"]:
		refs[key].horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if narrow else HORIZONTAL_ALIGNMENT_RIGHT
		refs[key].autowrap_mode=TextServer.AUTOWRAP_WORD
	picture.custom_minimum_size.y=clampf(size.x*0.29,140.0,245.0)
	policy.columns=2 if size.x>=620 else 1
	spending.columns=3 if size.x>=620 else 1

static func _label(words:String,size:int,color:Color,strong:=false)->Label:
	var result:=S.label(words,size,color,strong);result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return result

class HouseholdPicture extends Control:
	var texture:Texture2D
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS;clip_contents=true;resized.connect(queue_redraw)
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),T.TILE_BG)
		if texture==null or size.x<=0 or size.y<=0:return
		var source:=texture.get_size();var region:=Rect2(Vector2.ZERO,source);var ratio:=size.x/size.y
		if source.x/source.y>ratio:region.size.x=source.y*ratio;region.position.x=(source.x-region.size.x)*0.5
		else:region.size.y=source.x/ratio;region.position.y=(source.y-region.size.y)*0.5
		draw_texture_rect_region(texture,Rect2(Vector2.ZERO,size),region)

class WealthShares extends Control:
	var values:Array=[]
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS;tooltip_text="Five equally sized groups of households, poorest to wealthiest. The bars compare their shares of household wealth on one common scale, from zero to the largest share.";resized.connect(queue_redraw)
	func _draw()->void:
		if values.size()!=5:return
		var largest:=0.0001
		for value:Variant in values:largest=maxf(largest,float(value))
		var unit:=size.x/5.0
		for index:int in 5:
			var height:=size.y*maxf(0.0,float(values[index]))/largest
			var x:=unit*index+maxf(0.0,unit*0.5-15.0)
			draw_line(Vector2(unit*index,size.y-1),Vector2(unit*(index+1)-10,size.y-1),T.RULE,1)
			if height>0:draw_rect(Rect2(x,size.y-height,30,height),T.TEAL)
