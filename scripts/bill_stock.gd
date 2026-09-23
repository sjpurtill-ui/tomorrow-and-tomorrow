extends RefCounted
## Checking and paying flattened bills against one local stock.
##
## Infrastructure bills used to name manufactured parts and repairs drew one
## part at a time. With Civilian Goods those bills are flattened once per unit
## (goods_bills.gd) and scaled here, so varying repair quantities do not fill
## the flatten cache with one-off keys.

const Bills=preload("res://scripts/goods_bills.gd")

## Flattened bill for one unit of `item`.
static func unit(item:String)->Dictionary:
	return Bills.flatten({item:1.0})

## Adds `unit_bill` × `quantity` into `into` and returns it.
static func add_scaled(into:Dictionary,unit_bill:Dictionary,quantity:float)->Dictionary:
	for item:String in unit_bill:into[item]=float(into.get(item,0.0))+float(unit_bill[item])*quantity
	return into

## A new mutable bill of `unit_bill` × `quantity`.
static func scaled(unit_bill:Dictionary,quantity:float)->Dictionary:
	return add_scaled({},unit_bill,quantity)

## Units of `unit_bill` the stock can pay for (INF for an empty bill).
static func affordable(stock:Dictionary,unit_bill:Dictionary)->float:
	var result:=INF
	for item:String in unit_bill:
		if float(unit_bill[item])<=0:continue
		result=minf(result,maxf(0.0,float(stock.get(item,0.0)))/float(unit_bill[item]))
	return result

static func can_pay(stock:Dictionary,bill:Dictionary)->bool:
	for item:String in bill:
		if float(stock.get(item,0.0))<float(bill[item]):return false
	return true

static func pay(stock:Dictionary,bill:Dictionary)->void:
	for item:String in bill:stock[item]=float(stock.get(item,0.0))-float(bill[item])

## Whether two bills name the same items at the same quantities, within a
## relative tolerance that survives save round trips.
static func same(a:Variant,b:Dictionary)->bool:
	if not a is Dictionary or (a as Dictionary).size()!=b.size():return false
	for item:String in b:
		var value:Variant=a.get(item)
		if not (value is int or value is float) or not is_finite(float(value)):return false
		if absf(float(value)-float(b[item]))>maxf(.000001,absf(float(b[item]))*.000001):return false
	return true
