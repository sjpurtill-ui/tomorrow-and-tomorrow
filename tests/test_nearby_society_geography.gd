extends GdUnitTestSuite
const Geography=preload("res://scripts/nearby_society_geography.gd")
func test_connected_geography_is_repeatable_and_bounded()->void:
	var land:=func(_p:Vector2)->bool:return true
	var sites:=Geography.sites(Vector2.ZERO,land,1729)
	assert_int(sites.size()).is_equal(3)
	assert_array(sites).is_equal(Geography.sites(Vector2.ZERO,land,1729))
	for site in sites:assert_float(site.length()).is_between(96.0,224.0)
func test_water_cannot_be_crossed_to_place_a_neighbor()->void:
	var land:=func(p:Vector2)->bool:return p.x<32
	for site in Geography.sites(Vector2.ZERO,land,1729):assert_float(site.x).is_less(32.0)
func test_island_does_not_receive_invented_connected_communities()->void:
	assert_array(Geography.sites(Vector2.ZERO,func(p:Vector2)->bool:return p.length()<30,1729)).is_empty()
