extends VBoxContainer
## Two explicitly labelled amounts. Bar length is magnitude; sign stays numeric.
const T=preload("res://scripts/hud/hud_tokens.gd")
const E=preload("res://scripts/effect_explainer.gd")
var bars:Array[ProgressBar]=[]
var values:Array[Label]=[]
var direction:Label
func setup(row:Dictionary)->void:
	name="Effect_"+String(row.id);size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",4)
	var title:=_label(String(row.label),15,T.INK);add_child(title)
	var key:=String(row.id);var good:=E.good(key);var active:=float(row.current);var unlocked:=float(row.unlocked)
	var tone:=E.tone(key,active)
	var meaning:="No active effect" if is_zero_approx(active) else ("Helping" if tone>0 else "Cost" if tone<0 else "Trade-off")
	if bool(row.get("inert",false)):meaning="Not used yet"
	elif bool(E.KEYS.get(key,{}).get("steer_only",false)):meaning="Research guidance only"
	direction=_label(("↓ Lower helps" if good<0 else "↑ Higher helps" if good>0 else "Mixed effects")+" · "+meaning,11,T.TEAL if tone>=0 else T.AMBER);add_child(direction)
	var scale:=maxf(.0001,maxf(absf(unlocked),absf(active)))
	for i in 2:
		var amount:=unlocked if i==0 else active
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",7);add_child(line)
		var caption:=_label("Unlocked" if i==0 else "Active now",12,T.INK_MUTED);caption.custom_minimum_size.x=67;line.add_child(caption)
		var meter:=ProgressBar.new();meter.name="Unlocked" if i==0 else "Active";meter.min_value=0;meter.step=0.0;meter.max_value=scale;meter.value=absf(amount);meter.show_percentage=false;meter.custom_minimum_size=Vector2(36,8);meter.size_flags_vertical=Control.SIZE_SHRINK_CENTER;meter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		meter.add_theme_stylebox_override("background",T.flat(T.TRACK,Color.TRANSPARENT,0,2));meter.add_theme_stylebox_override("fill",T.flat(T.GOLD if i==0 else T.TEAL,Color.TRANSPARENT,0,2));line.add_child(meter);bars.append(meter)
		var value:=_label("%+.2f"%(amount*100),14,T.GOLD if i==0 else T.TEAL);value.custom_minimum_size.x=62;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;line.add_child(value);values.append(value)
	var note:=_label("Effect points · bar range 0–%.2f"%(scale*100),10,T.INK_MUTED);add_child(note)
	tooltip_text=String(E.KEYS.get(key,{}).get("what",""))+"\nOne point = 0.01 of this effect's modifier; it is not a percentage of total output. Each pair shares its own magnitude scale. A minus sign reduces the named effect. Active totals include adoption, means, focus, trials, era limits and upkeep; they need not be a simple fraction of unlocked knowledge."
	mouse_filter=Control.MOUSE_FILTER_STOP
func _label(text:String,points:int,color:Color)->Label:
	var label:=T.make_label(text,points,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return label
