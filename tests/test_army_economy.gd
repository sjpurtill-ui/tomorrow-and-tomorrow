extends GdUnitTestSuite
## The army's cost card reads the difference a step makes, in plain words.
const Economy:=preload("res://scripts/army_economy.gd")


static func _reading(watch:int,food_net:float,births:float,pay:float,gear:float,carts:int,from:Dictionary={},lost:=0.0,eaten:=0.0)->Dictionary:
	return {"watch":watch,"food_net":food_net,"births":births,"pay_season":pay,"gear_days":gear,"carts":carts,"from":from,"food_lost":lost,"food_eaten":eaten,"free":3000}


func test_a_step_names_who_leaves_and_what_it_costs()->void:
	var now:=_reading(500,4000.0,0.0,100.0,0.0,1)
	var more:=_reading(1200,600.0,0.4,240.0,900.0,30,{"Food":650,"Crafting":50},3300.0,144.0)
	var lines:=Economy.step_words(now,more)
	assert_str(lines[0]).contains("700 more under arms").contains("food (650)").contains("making (50)")
	assert_str(lines[1]).contains("−3,400 rations a day")
	assert_str("\n".join(lines)).contains("0.4 in 100 fewer").contains("900 more maker-days").contains("29 more to build")


func test_no_step_no_words()->void:
	var now:=_reading(500,4000.0,0.0,100.0,0.0,1)
	assert_array(Array(Economy.step_words(now,now))).is_empty()


func test_from_words_biggest_first()->void:
	assert_str(Economy.from_words({"Crafting":5,"Food":40})).is_equal("food (40), making (5)")
	assert_str(Economy.from_words({})).is_equal("nobody")
