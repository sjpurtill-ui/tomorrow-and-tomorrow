extends GdUnitTestSuite
## WITHIN ONE PEOPLE, NOBODY ALIKE (scripts/hud/court_figure_look.gd).
## A people shares its skin range, its hair colours and its dyes; its members
## each have their own shade of them, kept for life:
## - the same person always comes out the same, and varying twice changes nothing;
## - a hall of one fair-haired people shows fair, honey and brown heads, not
##   one colour, and never ash-white unless they are old;
## - the old stay grey; near-black hair stays dark;
## - skin stays within a few percent of the people's tone;
## - builds and heights differ; the clasp is rare; a room keeps at most one;
## - a child (by years) gets the child's body, no beard.
## Presentation only. Offline.

const FigureLook:=preload("res://scripts/hud/court_figure_look.gd")

func _look(i:int,hair:String,variant:="male_adult",extra:={})->Dictionary:
	var face:={}
	for shape in ["jaw","chin","cheek","nose"]:face[shape]=float(((i*37+shape.hash())%201)-100)/100.0
	var look:={"variant":variant,"hair":"cropped","hair_colour":Color(hair),"skin":Color("72472c"),"face":face,
		"cloth":[Color("a8432f"),Color("6e5541"),Color("c9a43c")],"stance":"clasped"}
	look.merge(extra,true)
	return look


func test_the_same_person_comes_out_the_same_and_once_only()->void:
	var a:=FigureLook.vary(_look(3,"bfa57a"))
	var b:=FigureLook.vary(_look(3,"bfa57a"))
	assert_str(var_to_str(a)).is_equal(var_to_str(b))
	assert_str(var_to_str(FigureLook.vary(a))).is_equal(var_to_str(a))


func test_a_fair_people_has_many_shades_of_hair_and_none_ash_white()->void:
	var values:=[]
	for i in 24:
		var c:Color=FigureLook.vary(_look(i,"bfa57a")).hair_colour
		values.append(c.v)
		assert_float(c.s).override_failure_message("ash-white hair %s" % c.to_html(false)).is_greater(0.30)
	values.sort()
	assert_float(float(values[-1])-float(values[0])).is_greater(0.25)


func test_the_old_stay_grey_and_dark_hair_stays_dark()->void:
	for i in 12:
		var grey:Color=FigureLook.vary(_look(i,"a8a299","male_old",{"years":66})).hair_colour
		assert_float(grey.s).is_less(0.16)
		assert_float(grey.v).is_greater(0.45)
		var dark:Color=FigureLook.vary(_look(i,"1b1511")).hair_colour
		assert_float(dark.v).is_less(0.31)


func test_skin_stays_within_the_peoples_tone()->void:
	for i in 20:
		var skin:Color=FigureLook.vary(_look(i,"1b1511")).skin
		assert_float(absf(skin.v-Color("72472c").v)).is_less(0.04)


func test_builds_and_heights_differ_and_the_clasp_is_rare()->void:
	var builds:={};var clasped:=0;var tall:={}
	for i in 30:
		var look:=FigureLook.vary(_look(i,"1b1511"))
		builds[String(look.build)]=true
		tall[snappedf(float(look.tall),0.01)]=true
		if String(look.stance)=="clasped":clasped+=1
		var scale:=FigureLook.scale_of(look)
		assert_float(scale.y).is_between(0.92,1.09)
	assert_int(builds.size()).is_greater_equal(3)
	assert_int(tall.size()).is_greater_equal(5)
	assert_int(clasped).is_less(15)
	# The one asked to keep it does.
	assert_str(String(FigureLook.vary(_look(1,"1b1511","male_adult",{"keep_stance":true})).stance)).is_equal("clasped")


func test_a_room_keeps_at_most_one_clasp()->void:
	var taken:={}
	var clasped:=0
	for i in 8:
		if FigureLook.room_stance(_look(i,"1b1511"),taken)=="clasped":clasped+=1
	assert_int(clasped).is_less_equal(1)


func test_a_child_gets_a_childs_body_and_no_beard()->void:
	var child:=FigureLook.vary(_look(5,"1b1511","male_young",{"years":8,"beard":"beard_short","hair":"balding"}))
	assert_str(String(child.variant)).is_equal("child")
	assert_str(String(child.beard)).is_empty()
	assert_str(String(child.hair)).is_not_equal("balding")
