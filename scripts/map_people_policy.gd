extends RefCounted
## Map presentation only: no walking or standing human figures on the land.
## Population, workers, scouts, journeys and military forces remain aggregate
## simulation facts. Buildings, smoke, wildlife and abstract chart marks stay.
const DRAW_PEOPLE:=false

static func show_people()->bool:return DRAW_PEOPLE

static func representative_count(requested:int)->int:
	return maxi(0,requested) if DRAW_PEOPLE else 0
