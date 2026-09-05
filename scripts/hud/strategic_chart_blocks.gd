extends RefCounted
const History:=preload("res://scripts/strategic_history.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
static func population(scope:String,local:bool=false)->Dictionary:
	return History.block("population","POPULATION OVER TIME",scope,"people",[{"key":"population","label":"Local residents" if local else "Civilization population","color":Tokens.GREEN}],"Selected city · modeled resident share." if local else "Civilization total · includes people away on missions; not a city count.")
static func reserves(scope:String)->Dictionary:
	return History.block("reserves","RESERVE RUNWAY",scope,"days",[{"key":"food_days","label":"Food","color":Tokens.AMBER},{"key":"water_days","label":"Water","color":Tokens.TEAL}],"Selected city's reserves at recorded demand; these are historical observations, not a forecast.")
static func food_flow(scope:String)->Dictionary:
	return History.block("food_flow","FOOD PRODUCTION & CONSUMPTION",scope,"rations/day",[{"key":"food_production","label":"Produced","color":Tokens.GREEN},{"key":"food_eaten","label":"Eaten","color":Tokens.AMBER}],"Selected city · daily rates at each snapshot, not monthly totals. Spoilage and mission issues also affect stores.")
static func stocks(scope:String)->Dictionary:
	return History.block("stocks","PHYSICAL MATERIAL STORES",scope,"stored units",[{"key":"Timber","label":"Timber","color":Tokens.GREEN},{"key":"Stone","label":"Stone","color":Tokens.BLUE},{"key":"Clay","label":"Clay","color":Tokens.AMBER},{"key":"Fiber Plants","label":"Fiber","color":Tokens.TEAL}],"Selected city's delivered stocks. Physical goods are not currency or a monetary valuation of wealth.")
static func finance(scope:String)->Dictionary:
	if GameState.economy_stage=="weighed_metal":
		return History.block("metal","EXCHANGE METAL IN CIRCULATION",scope,"metal-value units",[{"key":"metal","label":"Weighed metal","color":Tokens.GOLD}],"Selected city exchange account; excludes uncommitted ore and stored goods.")
	return History.block("currency","CURRENCY BALANCES",scope,"currency units",[{"key":"treasury","label":"Public treasury","color":Tokens.GOLD},{"key":"private_currency","label":"Active household currency","color":Tokens.TEAL},{"key":"hoards","label":"Household hoards","color":Tokens.BLUE},{"key":"aid","label":"Mutual-aid reserve","color":Tokens.GREEN}],"Selected city's monetary accounts. These are currency holdings, not total private assets or enterprise valuation. Gaps before currency adoption are unrecorded, not zero.")
