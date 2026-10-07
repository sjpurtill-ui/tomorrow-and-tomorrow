class_name WarNeighboursTest
extends GdUnitTestSuite
## Neighbours are peoples whose countries come near meeting, never a people
## across the sea (war_loop.gd neighbours).

const WAR:=preload("res://scripts/war_loop.gd")
const KX:=18000.0
const KZ:=9000.0


func _civ(x_km:float,z_km:float,people:float,reach:=0.1)->Dictionary:
	return {"id":"c%d_%d" % [int(x_km),int(z_km)],"position":Vector2(x_km/KX,z_km/KZ),"population":people,"world_reach":reach}


func test_founding_bands_a_continent_apart_are_not_neighbours()->void:
	assert_bool(WAR.neighbours(_civ(0,0,200),_civ(1100,0,200))).is_false()


func test_grown_peoples_whose_lands_near_each_other_are_neighbours()->void:
	assert_bool(WAR.neighbours(_civ(0,0,15000),_civ(1100,0,15000))).is_true()


func test_a_people_across_the_sea_is_never_a_neighbour()->void:
	assert_bool(WAR.neighbours(_civ(-4000,0,15000),_civ(4000,0,15000))).is_false()


func test_close_bands_are_neighbours_however_small()->void:
	assert_bool(WAR.neighbours(_civ(0,0,150),_civ(300,0,150))).is_true()


## Proximity drives war: closeness rises as two countries grow toward each
## other, from 0 past a march's reach to 1 where they meet.
func test_proximity_rises_as_countries_grow_toward_each_other()->void:
	# Two grown peoples drawn ever closer: closeness never falls as the gap
	# shrinks, is graded on the way (not a switch), and is nothing far apart.
	var last:=-1.0
	var graded:=false
	for step in range(30,0,-1):
		var near:=WAR.proximity_between(_civ(0,0,15000),_civ(step*100.0,0,15000))
		assert_float(near).is_greater_equal(last)
		graded=graded or (near>0.05 and near<0.95)
		last=near
	assert_bool(graded).is_true()
	assert_float(last).is_equal(1.0)
	assert_float(WAR.proximity_between(_civ(0,0,200),_civ(1100,0,200))).is_equal(0.0)
	assert_float(WAR.proximity_between(_civ(-4000,0,15000),_civ(4000,0,15000))).is_equal(0.0)
