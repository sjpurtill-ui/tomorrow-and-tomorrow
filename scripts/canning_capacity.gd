extends RefCounted
## Shared read-only stock constraint for investment, operation and conversion.
const RESERVE_DAYS:=3.0
const PERISHABLES:=["Fresh food","Fish","Fresh meat","Fresh plants"]
static func available_input(stocks:Dictionary,daily_demand:float)->float:
	var total:=0.0
	var perishables:=0.0
	for food:String in stocks:
		var amount:=maxf(0,float(stocks[food]));total+=amount
		if food in PERISHABLES:perishables+=amount
	return minf(perishables,maxf(0,total-maxf(0,daily_demand)*RESERVE_DAYS))
