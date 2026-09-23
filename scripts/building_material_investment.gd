extends RefCounted
## Former building-fabric supply planning. Fabric components are no longer
## made on workshop lines, and built capacity is moving to population-driven
## city capacities, so there is no fabric demand to order. The functions stay
## so existing callers (settlement trade targets) keep working.

## No workshop order: building parts are Civilian Goods and raw materials.
static func recommendation()->Dictionary:
	return {}

## No named fabric component stocks are targeted for repair or retrofit.
static func fabric_targets()->Dictionary:
	return {}

static func fabric_recommendation()->Dictionary:
	return {}
