extends RefCounted
## Aggregate storage, shared by every actor. Rates are game calibration, not
## food-safety shelf lives. More room never improves preservation by itself.
const STORED_DAILY_LOSS:=0.003
const KEEPER_BUFFER_DAYS:=30.0

static func climate_factor(temperature:float,wetness:float)->float:
	return clampf(pow(2.0,(temperature-15.0)/20.0)*lerpf(.8,1.4,clampf(wetness,0,1)),.4,2.5)

static func keeper_load(people:float,stored:float)->float:
	return maxf(people,maxf(0,stored)/KEEPER_BUFFER_DAYS)

## Constant-current-conditions estimate with no incoming food. Fresh is eaten
## first while the stored reserve continues to deteriorate. O(1), read-only.
static func reserve_days(fresh:float,stored:float,need:float,fresh_rate:float,stored_rate:float)->float:
	if need<=0:return -1.0
	fresh=maxf(0,fresh);stored=maxf(0,stored)
	var fresh_days:=_pool_days(fresh,need,fresh_rate)
	var remaining:=stored*pow(1.0-clampf(stored_rate,0,1),fresh_days)
	return fresh_days+_pool_days(remaining,need,stored_rate)

static func _pool_days(stock:float,need:float,rate:float)->float:
	rate=clampf(rate,0,1)
	if stock<=0 or rate>=1:return 0.0
	if rate<.00000001:return stock/need
	return log(1.0+stock*rate/need)/-log(1.0-rate)
