extends RefCounted
## Continuous population reference for aggregate land cover, never a population
## or housing authority. Classification changes the city composition, not its
## physical extent overnight. Log interpolation keeps area increasing at every
## knot because density always grows more slowly than population.
const KNOTS:=[Vector2(1,350),Vector2(80,500),Vector2(400,750),Vector2(2500,1050),Vector2(18000,2200),Vector2(1000000,3600),Vector2(10000000,4600)]
static func density(population:int)->float:
	var people:=maxf(1.0,population)
	for index in range(1,KNOTS.size()):
		var a:Vector2=KNOTS[index-1];var b:Vector2=KNOTS[index]
		if people<=b.x:
			var t:=inverse_lerp(log(a.x),log(b.x),log(people))
			return exp(lerpf(log(a.y),log(b.y),t))
	return KNOTS[-1].y
static func radius(population:int)->float:
	return sqrt(maxf(1.0,population)/(PI*density(population)))
