extends VBoxContainer
## Research detail for a clothing technique: what it adds and how much of the
## population is currently supplied through Civilian Goods.
const B=preload("res://scripts/household_clothing.gd")
const K=preload("res://scripts/clothing_knowledge.gd")
const Goods=preload("res://scripts/civilian_goods.gd")
var subject:=""
var details:Label
var elapsed:=0.0
func _ready()->void:
	if not K.METHODS.has(subject):return
	details=Label.new();details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(details)
	refresh()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=1:elapsed=0;refresh()
func refresh()->void:
	if not is_instance_valid(details):return
	var mode:=String(K.METHODS[subject].get("mode",""))
	var adoption:=clampf(WorldSimulation.discovery.adoption(subject),0.0,1.0) if subject in WorldSimulation.state.known_discoveries else 0.0
	var service:=B.coverage(WorldSimulation.state.population_exact,int(WorldSimulation.state.elapsed_days))
	var role:="Adds rain protection to supplied households." if mode=="rain_shell" else "Adds layered warmth to supplied households." if mode=="layer" else "Improves cold protection to %d%% when it is the best adopted garment method." % roundi(float(B.INSULATION.get(mode,0.0))*100.0) if B.INSULATION.has(mode) else "Changes how garments are finished; decoration adds no protection."
	details.text="%s\nAbout %d in 10 households use it. About %d in 10 households have the everyday goods they need, clothing among them.\nToday our clothing takes about %d%% off the harm of cold and %d%% off the harm of storms." % [role,roundi(adoption*10.0),roundi(Goods.coverage()*10.0),roundi(float(service.cold)*100.0),roundi(float(service.storm)*100.0)]
