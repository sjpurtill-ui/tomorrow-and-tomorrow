extends GdUnitTestSuite
## Nation borders (nation_borders.gd): what a people knows decides its look
## (none, frontier, state; a fixed line needs both sides at the Peace
## Congress), every people wears its own colour and ours stands apart,
## frontiers fade at their ends, two peoples never share ground, nothing is
## drawn on water or on ground we have not charted, the rebuild key holds
## still without a change, and a war lights the real meeting line.
const Borders:=preload("res://scripts/nation_borders.gd")
const Partition:=preload("res://scripts/nation_border_partition.gd")
const BorderInk:=preload("res://scripts/nation_border_ink.gd")
const Stroke:=preload("res://scripts/scout_chart_stroke.gd")
const IDENTITIES:=preload("res://scripts/civilization_identity.gd")

const ORIGIN:=Vector2(-10.0,-10.0)
const CELL:=0.25
const N:=81
const BLUE:=Color("85bdeb")
const GREEN:=Color("b5d77e")

var _knowledge:Dictionary={}
var _published:Array=[]
var _day:=0


var _forts:Dictionary={}
func before_test()->void:
	_knowledge=Borders.knowledge_override.duplicate(true)
	_published=Borders.published
	_day=int(GameState.elapsed_days)
	# Borders here are drawn from towns alone: no forts, no old posts counted.
	_forts=GameState.border_forts.duplicate(true)
	GameState.border_forts={"seeded":true}


func after_test()->void:
	Borders.knowledge_override=_knowledge
	Borders.published=_published
	GameState.elapsed_days=_day
	GameState.border_forts=_forts


# --- Fixtures ----------------------------------------------------------------

static func _style(color:Color,stage:int,foreign:bool,firm:=false)->Dictionary:
	var wash:float=[Borders.WASH_NONE,Borders.WASH_FRONTIER,Borders.WASH_STATE][stage]
	return {"color":color,"stage":stage,"firm":firm,"wash":wash,"foreign":foreign}


static func _claim(owner_index:int,center:Vector2,radius:float)->Dictionary:
	var claim:=Borders.make_claim("owner%d" % owner_index,"town%d" % owner_index,center,radius)
	claim["owner_index"]=owner_index
	return claim


## Two towns of equal claim whose lands overlap: they meet on x = 0, from
## (0, -4) to (0, 4), where both outlines cross.
static func _neighbours()->Array:
	return [_claim(0,Vector2(-3.0,0.0),5.0),_claim(1,Vector2(3.0,0.0),5.0)]


static func _flat(_point:Vector2)->float:
	return 1.0


static func _seen_everywhere()->Dictionary:
	return {"kind":"circle","x":0.0,"z":0.0,"radius":60.0}


static func _ground_input(claims:Array,styles:Array,ground:Callable,revealed:Array=[])->Dictionary:
	var heights:=PackedFloat32Array()
	heights.resize(N*N)
	for i in N*N: heights[i]=float(ground.call(ORIGIN+Vector2(float(i%N),float(int(float(i)/float(N))))*CELL))
	return {"origin":ORIGIN,"cell":CELL,"n":N,"claims":claims,"styles":styles,"heights":heights,"revealed":revealed,
		"view_km":20.0,"war":{},"player":0,"known_fade":CELL*0.6}


## The ground under `point` as the partition reads it (bilinear between nodes).
static func _ground(input:Dictionary,point:Vector2)->float:
	var heights:PackedFloat32Array=input.heights
	var f:=(point-ORIGIN)/CELL
	var ix:=clampi(floori(f.x),0,N-2)
	var iy:=clampi(floori(f.y),0,N-2)
	var t:=Vector2(clampf(f.x-float(ix),0.0,1.0),clampf(f.y-float(iy),0.0,1.0))
	var top:=lerpf(heights[iy*N+ix],heights[iy*N+ix+1],t.x)
	var bottom:=lerpf(heights[(iy+1)*N+ix],heights[(iy+1)*N+ix+1],t.x)
	return lerpf(top,bottom,t.y)


## The wash as triangles: [{owner, points [a, b, c], alpha (the largest)}].
static func _triangles(result:Dictionary)->Array:
	var vertices:PackedVector3Array=result.wash_vertices
	var colors:PackedColorArray=result.wash_colors
	var owners:PackedInt32Array=result.wash_owner
	var out:Array=[]
	for k in range(0,vertices.size(),3):
		var points:=PackedVector2Array([Vector2(vertices[k].x,vertices[k].z),Vector2(vertices[k+1].x,vertices[k+1].z),Vector2(vertices[k+2].x,vertices[k+2].z)])
		out.append({"owner":owners[k],"points":points,"alpha":maxf(colors[k].a,maxf(colors[k+1].a,colors[k+2].a))})
	return out


## CIE76 colour difference in Lab (sRGB, D65).
static func _delta_e(a:Color,b:Color)->float:
	return _lab(a).distance_to(_lab(b))


static func _lab(color:Color)->Vector3:
	var linear:=[color.r,color.g,color.b].map(func(c:float)->float: return c/12.92 if c<=0.04045 else pow((c+0.055)/1.055,2.4))
	var x:float=(linear[0]*0.4124+linear[1]*0.3576+linear[2]*0.1805)/0.95047
	var y:float=linear[0]*0.2126+linear[1]*0.7152+linear[2]*0.0722
	var z:float=(linear[0]*0.0193+linear[1]*0.1192+linear[2]*0.9505)/1.08883
	var f:=func(t:float)->float: return pow(t,1.0/3.0) if t>0.008856 else 7.787*t+16.0/116.0
	return Vector3(116.0*float(f.call(y))-16.0,500.0*(float(f.call(x))-float(f.call(y))),200.0*(float(f.call(y))-float(f.call(z))))


# --- What a people knows ---------------------------------------------------------

func test_stage_follows_what_a_people_knows()->void:
	Borders.knowledge_override={"player":[],"civ_02":["boundary_marker_surveys"],
		"civ_03":["boundary_marker_surveys","kingship","sovereign_realms_congress"],
		"civ_04":["boundary_marker_surveys","kingship","boundary_treaties"]}
	assert_int(Borders.stage_of("player")).is_equal(Borders.STAGE_NONE)
	assert_int(Borders.stage_of("civ_02")).is_equal(Borders.STAGE_FRONTIER)
	assert_int(Borders.stage_of("civ_03")).is_equal(Borders.STAGE_STATE)
	# A kingdom with boundary treaties is still a frontier; its wash only firms a little.
	assert_int(Borders.stage_of("civ_04")).is_equal(Borders.STAGE_FRONTIER)
	var kingdom:=Borders.style("civ_04")
	var plain:=Borders.style("civ_02")
	assert_bool(bool(kingdom.firm)).is_true()
	assert_float(float(kingdom.wash)).is_greater(float(plain.wash))
	assert_float(float(kingdom.wash)).is_less(float(plain.wash)*1.3)
	# Before marking its land a people has only a faint wash.
	assert_float(float(Borders.style("player").wash)).is_less(float(plain.wash)*0.5)
	assert_bool(bool(Borders.style("player").foreign)).is_false()
	assert_bool(bool(plain.foreign)).is_true()
	# How two peoples' meeting line is drawn.
	assert_str(Borders.line_kind(0,0)).is_equal("")
	assert_str(Borders.line_kind(1,0)).is_equal("frontier")
	assert_str(Borders.line_kind(0,1)).is_equal("frontier")
	assert_str(Borders.line_kind(1,1)).is_equal("frontier")
	assert_str(Borders.line_kind(2,1)).is_equal("frontier")
	assert_str(Borders.line_kind(2,2)).is_equal("state")


func test_a_fixed_line_needs_both_sides_at_the_congress()->void:
	for case:Array in [[2,2,"state"],[2,1,"frontier"],[1,2,"frontier"],[1,0,"frontier"],[0,1,"frontier"],[0,0,""]]:
		var styles:=[_style(Borders.PLAYER_COLOR,int(case[0]),false),_style(BLUE,int(case[1]),true)]
		var result:=Borders.compose(_ground_input(_neighbours(),styles,_flat,[_seen_everywhere()]))
		assert_int((result.lines as Array).size()).is_equal(1)
		for line:Dictionary in result.lines:
			assert_str(String(line.kind)).is_equal(String(case[2]))
	# Mutual: knowing the congress alone fixes nothing with a people that does not.
	var one_sided:=Borders.compose(_ground_input(_neighbours(),[_style(Borders.PLAYER_COLOR,2,false),_style(BLUE,1,true)],_flat,[_seen_everywhere()]))
	var line:Dictionary=one_sided.lines[0]
	var alphas:=BorderInk.profile(line,20.0/900.0)
	assert_float(alphas[0]).is_less(0.2)
	# Both at the congress: one crisp line, even from end to end.
	var agreed:=Borders.compose(_ground_input(_neighbours(),[_style(Borders.PLAYER_COLOR,2,false),_style(BLUE,2,true)],_flat,[_seen_everywhere()]))
	for alpha in BorderInk.profile(agreed.lines[0],20.0/900.0): assert_float(alpha).is_equal(1.0)


func test_before_marking_a_people_has_a_faint_wash_and_no_line()->void:
	var result:=Borders.compose(_ground_input(_neighbours(),[_style(Borders.PLAYER_COLOR,0,false),_style(BLUE,0,true)],_flat,[_seen_everywhere()]))
	assert_str(String((result.lines[0] as Dictionary).kind)).is_equal("")
	for ink in result.ink: assert_int((ink as Stroke.Ink).vertices.size()).is_equal(0)
	var strongest:=0.0
	for color in (result.wash_colors as PackedColorArray): strongest=maxf(strongest,color.a)
	assert_float(strongest).is_greater(0.0)
	assert_float(strongest).is_less_equal(Borders.WASH_NONE+0.0001)


# --- Colours ---------------------------------------------------------------------

func test_every_people_wears_its_own_colour_and_ours_stands_apart()->void:
	assert_that(Borders.nation_color("player")).is_equal(Borders.PLAYER_COLOR)
	var seen:Dictionary={}
	for number in range(1,13):
		var id:="civ_%02d" % number
		var color:=Borders.nation_color(id)
		# The colour its emblem's band and its towns' marks wear on the map.
		assert_that(color).is_equal(Color(String(IDENTITIES.identity(int(WorldSimulation.state.world_seed),id).color)))
		seen[color.to_html()]=true
	assert_int(seen.size()).is_equal(12)
	# Ours is further from every people's map colour than any two of theirs are
	# from each other, clear of their emblems' fields, the war red and gold.
	var closest_pair:=INF
	for i in IDENTITIES.PALETTES.size():
		for j in range(i+1,IDENTITIES.PALETTES.size()):
			closest_pair=minf(closest_pair,_delta_e(Color(String(IDENTITIES.PALETTES[i][1])),Color(String(IDENTITIES.PALETTES[j][1]))))
	for palette:Array in IDENTITIES.PALETTES:
		assert_float(_delta_e(Borders.PLAYER_COLOR,Color(String(palette[1])))).is_greater(maxf(30.0,closest_pair))
		assert_float(_delta_e(Borders.PLAYER_COLOR,Color(String(palette[0])))).is_greater(12.0)
	assert_float(_delta_e(Borders.PLAYER_COLOR,Color("#c9574a"))).is_greater(30.0)
	assert_float(_delta_e(Borders.PLAYER_COLOR,Color("#d3a835"))).is_greater(30.0)
	# Each side of a line wears its own people's colour.
	var result:=Borders.compose(_ground_input(_neighbours(),[_style(Borders.PLAYER_COLOR,1,false),_style(BLUE,1,true)],_flat,[_seen_everywhere()]))
	var by_owner:Dictionary={}
	for k in (result.wash_owner as PackedInt32Array).size():
		var tint:Color=result.wash_colors[k]
		by_owner[int(result.wash_owner[k])]=Color(tint.r,tint.g,tint.b)
	assert_that(by_owner[0]).is_equal(Color(Borders.PLAYER_COLOR.r,Borders.PLAYER_COLOR.g,Borders.PLAYER_COLOR.b))
	assert_that(by_owner[1]).is_equal(Color(BLUE.r,BLUE.g,BLUE.b))


# --- Lines -----------------------------------------------------------------------

func test_a_frontier_runs_the_real_meeting_line_and_fades_at_both_ends()->void:
	var result:=Borders.compose(_ground_input(_neighbours(),[_style(Borders.PLAYER_COLOR,1,false),_style(BLUE,1,true)],_flat,[_seen_everywhere()]))
	assert_int((result.lines as Array).size()).is_equal(1)
	var line:Dictionary=result.lines[0]
	assert_int(int(line.a)).is_equal(0)
	assert_int(int(line.b)).is_equal(1)
	assert_bool(bool(line.open_start) and bool(line.open_end)).is_true()
	var points:PackedVector2Array=line.points
	# On the meeting line, x = 0, from where the outlines cross to where they cross again.
	for point in points: assert_float(absf(point.x)).is_less(CELL*0.25)
	var ends:=[points[0],points[points.size()-1]]
	ends.sort_custom(func(a:Vector2,b:Vector2)->bool: return a.y<b.y)
	assert_float((ends[0] as Vector2).distance_to(Vector2(0.0,-4.0))).is_less(CELL*1.5)
	assert_float((ends[1] as Vector2).distance_to(Vector2(0.0,4.0))).is_less(CELL*1.5)
	# Full in the middle, fading out at both ends.
	var alphas:=BorderInk.profile(line,20.0/900.0)
	var middle:=alphas[int(alphas.size()/2.0)]
	assert_float(middle).is_greater(0.9)
	assert_float(alphas[0]).is_less(middle*0.25)
	assert_float(alphas[alphas.size()-1]).is_less(middle*0.25)
	# The lower-numbered people lies on the line's left.
	var normals:=BorderInk.normals(points)
	var mid_index:=int(points.size()/2.0)
	var left:=points[mid_index]+normals[mid_index]*1.0
	assert_float(Partition.claim_score(_neighbours()[0],left)).is_greater(Partition.claim_score(_neighbours()[1],left))
	# Against open land there is no stroke: only this one shared line exists.
	var ink:Stroke.Ink=result.ink[2]
	assert_int(ink.vertices.size()).is_greater(0)


func test_two_peoples_never_share_ground()->void:
	# A strong town and a weaker neighbour, overlapping deeply.
	var claims:=[_claim(0,Vector2(-3.0,0.0),6.0),_claim(1,Vector2(2.0,1.0),3.5)]
	var styles:=[_style(Borders.PLAYER_COLOR,1,false),_style(GREEN,1,false)]
	var result:=Borders.compose(_ground_input(claims,styles,_flat))
	var buckets:Dictionary={}
	var triangles:=_triangles(result)
	for index in triangles.size():
		var triangle:Dictionary=triangles[index]
		var box:=Rect2((triangle.points as PackedVector2Array)[0],Vector2.ZERO)
		for point in (triangle.points as PackedVector2Array): box=box.expand(point)
		for bx in range(floori(box.position.x/CELL),floori(box.end.x/CELL)+1):
			for by in range(floori(box.position.y/CELL),floori(box.end.y/CELL)+1):
				(buckets.get_or_add(Vector2i(bx,by),[]) as Array).append(index)
	var checked:=0
	for x in range(0,110):
		for y in range(0,90):
			var point:=Vector2(-8.0+float(x)*0.1037,-5.0+float(y)*0.1113)
			var holders:Dictionary={}
			for index in buckets.get(Vector2i(floori(point.x/CELL),floori(point.y/CELL)),[]):
				var triangle:Dictionary=triangles[index]
				var corners:PackedVector2Array=triangle.points
				if float(triangle.alpha)>0.0 and Geometry2D.point_is_inside_triangle(point,corners[0],corners[1],corners[2]): holders[int(triangle.owner)]=true
			assert_int(holders.size()).is_less_equal(1)
			checked+=1
	assert_int(checked).is_greater(5000)
	# And each piece belongs to whoever has the stronger claim there.
	for triangle:Dictionary in triangles:
		var corners:PackedVector2Array=triangle.points
		var centre:=(corners[0]+corners[1]+corners[2])/3.0
		var a:=Partition.claim_score(claims[0],centre)
		var b:=Partition.claim_score(claims[1],centre)
		if absf(a-b)<0.02: continue
		assert_int(int(triangle.owner)).is_equal(0 if a>b else 1)


func test_nothing_is_drawn_on_water()->void:
	# A sea east of x = 2 on a sloping shore, and a round lake in our land.
	var ground:=func(point:Vector2)->float:
		return minf((2.0-point.x)*0.5+Partition.SEA,point.distance_to(Vector2(-4.0,-1.5))-1.6)
	var claims:=_neighbours()
	var styles:=[_style(Borders.PLAYER_COLOR,1,false),_style(BLUE,1,false)]
	var input:=_ground_input(claims,styles,ground)
	var result:=Borders.compose(input)
	var vertices:PackedVector3Array=result.wash_vertices
	var colors:PackedColorArray=result.wash_colors
	var drawn_east:=0
	for k in vertices.size():
		if colors[k].a<=0.0: continue
		var point:=Vector2(vertices[k].x,vertices[k].z)
		assert_float(_ground(input,point)).is_greater_equal(Partition.SEA-0.0001)
		if int(result.wash_owner[k])==1: drawn_east+=1
	# The eastern people still holds its strip of shore.
	assert_int(drawn_east).is_greater(0)
	assert_int((result.lines as Array).size()).is_greater(0)
	for line:Dictionary in result.lines:
		for point in (line.points as PackedVector2Array):
			assert_float(_ground(input,point)).is_greater_equal(Partition.SEA*0.5-0.0001)


func test_a_strangers_land_shows_only_where_we_have_been()->void:
	var seen:={"kind":"circle","x":1.0,"z":0.0,"radius":2.5}
	var styles:=[_style(Borders.PLAYER_COLOR,1,false),_style(BLUE,1,true)]
	var result:=Borders.compose(_ground_input(_neighbours(),styles,_flat,[seen]))
	var theirs:=0
	var ours_beyond:=0
	var vertices:PackedVector3Array=result.wash_vertices
	for k in vertices.size():
		var point:=Vector2(vertices[k].x,vertices[k].z)
		if (result.wash_colors[k] as Color).a<=0.0: continue
		if int(result.wash_owner[k])==1:
			assert_float(point.distance_to(Vector2(1.0,0.0))).is_less_equal(2.5+0.0001)
			theirs+=1
		elif point.distance_to(Vector2(1.0,0.0))>2.5: ours_beyond+=1
	assert_int(theirs).is_greater(0)
	# Our own land shows whether or not a scout has walked it.
	assert_int(ours_beyond).is_greater(0)
	for line:Dictionary in result.lines:
		for point in (line.points as PackedVector2Array):
			assert_float(point.distance_to(Vector2(1.0,0.0))).is_less_equal(2.5+0.0001)
	# Nothing charted near them: nothing of theirs at all.
	var unseen:=Borders.compose(_ground_input(_neighbours(),styles,_flat,[]))
	for k in (unseen.wash_owner as PackedInt32Array).size():
		if int(unseen.wash_owner[k])==1: assert_float((unseen.wash_colors[k] as Color).a).is_equal(0.0)
	assert_int((unseen.lines as Array).size()).is_equal(0)


# --- Rebuilding --------------------------------------------------------------------

static func _outline(center:Vector2,radius:float)->PackedVector2Array:
	var out:=PackedVector2Array()
	for i in 32: out.append(center+Vector2.from_angle(TAU*float(i)/32.0)*radius*(1.0+0.06*sin(3.0*TAU*float(i)/32.0)))
	return out


func test_the_rebuild_key_holds_still_without_a_change()->void:
	var town:={"id":"home","primary":true,"position":Vector2(40.0,-12.0),"claim_radius_km":2.0,"boundary":_outline(Vector2(40.0,-12.0),2.0)}
	var key:=Borders.claims_key(Borders.own_claims([town]))
	assert_int(Borders.claims_key(Borders.own_claims([town]))).is_equal(key)
	# Growth short of about 2% redraws nothing; real growth or a new town does.
	var grown:=town.duplicate(true)
	grown.claim_radius_km=2.004
	grown.boundary=_outline(Vector2(40.0,-12.0),2.004)
	assert_int(Borders.claims_key(Borders.own_claims([grown]))).is_equal(key)
	grown.claim_radius_km=2.2
	grown.boundary=_outline(Vector2(40.0,-12.0),2.2)
	assert_int(Borders.claims_key(Borders.own_claims([grown]))).is_not_equal(key)
	var second:={"id":"ford","position":Vector2(52.0,-9.0),"claim_radius_km":1.0,"boundary":_outline(Vector2(52.0,-9.0),1.0)}
	assert_int(Borders.claims_key(Borders.own_claims([town,second]))).is_not_equal(key)
	# The layer: a day passing changes nothing it draws, so nothing rebuilds.
	var layer:Node3D=auto_free(preload("res://scripts/nation_border_layer.gd").new())
	layer.call("set_own_claims",[town])
	layer.call("_read_world",84.0)
	var own_key:=int(layer.get("own_key"))
	var world_key:=int(layer.get("world_key"))
	GameState.elapsed_days+=1
	layer.call("set_own_claims",[town])
	layer.call("_read_world",84.0)
	assert_int(int(layer.get("own_key"))).is_equal(own_key)
	assert_int(int(layer.get("world_key"))).is_equal(world_key)
	# The grid moves in steps: a small pan or zoom keeps it, a real one does not.
	var grid:=Borders.grid_for(Vector2(10.0,-12.0),84.0)
	assert_that(Borders.grid_for(Vector2(14.0,-10.0),84.0).key).is_equal(grid.key)
	assert_that(Borders.grid_for(Vector2(10.0,-12.0),92.0).key).is_equal(grid.key)
	assert_that(Borders.grid_for(Vector2(160.0,-12.0),84.0).key).is_not_equal(grid.key)
	assert_that(Borders.grid_for(Vector2(10.0,-12.0),200.0).key).is_not_equal(grid.key)
	# The grid always covers the view about its target.
	for target:Vector2 in [Vector2(40.0,-12.0),Vector2(-1234.5,876.0)]:
		for view in [3.0,84.0,1700.0]:
			var g:=Borders.grid_for(target,view)
			assert_bool((g.box as Rect2).grow(-float(view)*1.5).has_point(target)).is_true()


# --- War ---------------------------------------------------------------------------

func test_war_lights_the_real_meeting_line()->void:
	# Us, the enemy, and a third people whose land touches both.
	var claims:=[_claim(0,Vector2(-3.0,0.0),5.0),_claim(1,Vector2(3.0,0.0),5.0),_claim(2,Vector2(0.0,7.0),4.0)]
	var styles:=[_style(Borders.PLAYER_COLOR,1,false),_style(BLUE,1,true),_style(GREEN,1,true)]
	var input:=_ground_input(claims,styles,_flat,[_seen_everywhere()])
	input.war={1:"war"}
	var result:=Borders.compose(input)
	var lit:=0
	for line:Dictionary in result.lines:
		var pair:=[int(line.a),int(line.b)]
		if String(line.war)=="":
			assert_bool(pair==[0,1]).is_false()
			continue
		assert_array(pair).is_equal([0,1])
		assert_str(String(line.war)).is_equal("war")
		for point in (line.points as PackedVector2Array):
			# On the curve where the two claims are equal: the real meeting line.
			assert_float(absf(Partition.claim_score(claims[0],point)-Partition.claim_score(claims[1],point))).is_less(0.03)
			lit+=1
	assert_int(lit).is_greater(4)
	# The red underlay is drawn along it.
	assert_int((result.ink[0] as Stroke.Ink).vertices.size()).is_greater(0)
	# And the feud's mark sits on it (war_map_overlay.gd).
	Borders.publish(result.lines,PackedStringArray(["player","civ_02","civ_03"]))
	var mark:=Borders.meeting_point("player","civ_02",Vector2(0.0,-1.0))
	assert_bool(mark.is_finite()).is_true()
	assert_float(absf(Partition.claim_score(claims[0],mark)-Partition.claim_score(claims[1],mark))).is_less(0.03)
	assert_bool(Borders.meeting_point("player","civ_09",Vector2(0.0,-1.0)).is_finite()).is_false()


# --- Words and shapes ----------------------------------------------------------------

func test_a_border_says_what_it_is_in_a_few_words()->void:
	assert_str(Borders.line_words("frontier","the Kezari")).is_equal("Frontier of the Kezari: claimed, not agreed")
	assert_str(Borders.line_words("state","the Kezari")).is_equal("Border of the Kezari: fixed at the Peace Congress")
	assert_str(Borders.line_words("frontier","the Kezari","the Esurai")).is_equal("Frontier of the Kezari and the Esurai: claimed, not agreed")
	assert_str(Borders.line_words("frontier","the Kezari","","war")).is_equal("Frontier of the Kezari: claimed, not agreed. At war: their men cross here")
	assert_str(Borders.line_words("","the Kezari","","feud")).is_equal("Where our land meets the Kezari. A feud: their men cross here")
	assert_str(Borders.research_note("boundary_marker_surveys")).is_equal("Our lands are marked: our frontier shows on the map.")
	assert_str(Borders.research_note("sovereign_realms_congress")).is_equal("Borders with realms that also know this become fixed lines.")
	assert_str(Borders.research_note("fire_making")).is_equal("")


func test_a_claim_keeps_its_own_outline()->void:
	var outline:=_outline(Vector2(5.0,5.0),2.0)
	var claim:=Borders.make_claim("player","t",Vector2(5.0,5.0),2.0,outline)
	assert_float(Partition.claim_score(claim,Vector2(5.0,5.0))).is_equal(1.0)
	for point in outline: assert_float(Partition.claim_score(claim,point)).is_equal_approx(0.0,0.03)
	assert_float(Partition.claim_score(claim,Vector2(5.0,5.0).lerp(outline[5],0.5))).is_equal_approx(0.5,0.03)
	# A claim judged only from a head count is a circle of its worked ground.
	var judged:=Borders.make_claim("civ_02","x",Vector2.ZERO,Borders.estimated_radius(5000.0))
	assert_float(float(judged.radius)).is_equal_approx(Borders.estimated_radius(5000.0),0.0001)
	assert_float(Borders.estimated_radius(5000.0)).is_greater(Borders.estimated_radius(500.0))


func test_the_research_screens_say_what_it_does_to_the_map()->void:
	var Board:=preload("res://scripts/hud/inquiry_board.gd")
	var surveys:Dictionary=Board._card_words({"id":"boundary_marker_surveys","effects":{"legitimacy":0.002},"progress":0.3})
	assert_str(String(surveys.would)).contains("Our lands are marked: our frontier shows on the map.")
	assert_str(String(surveys.tooltip)).contains("On the map: Our lands are marked")
	var congress:Dictionary=Board._card_words({"id":"sovereign_realms_congress","effects":{},"progress":0.1})
	assert_str(String(congress.would)).contains("Borders with realms that also know this become fixed lines.")
	var other:Dictionary=Board._card_words({"id":"fire_making","effects":{},"progress":0.1})
	assert_str(String(other.would)).not_contains("map")


func test_the_wash_and_ink_shaders_compile()->void:
	# The dummy renderer still parses shader code: a broken shader lists no uniforms.
	var names:=func(path:String)->Array: return (load(path) as Shader).get_shader_uniform_list().map(func(u:Dictionary)->String: return String(u.name))
	var wash:Array=names.call("res://scripts/nation_border_wash.gdshader")
	for wanted in ["fade","terrain_grid","terrain_heights","coast_grid0","coast_level0"]: assert_array(wash).contains([wanted])
	assert_array(names.call("res://scripts/nation_border_ink.gdshader")).contains(["fade"])


## A stand-in for the fused terrain sampler: rows of a square patch, heights
## from x alone, counting the rows it was asked for.
class RowSampler extends RefCounted:
	var rows:=0
	func sample_rows(job:Object,first_row:int,row_count:int)->Array:
		rows+=row_count
		var heights:=PackedFloat32Array()
		var spacing:=float(job.span)/float(int(job.resolution)-1)
		var half:=float(int(job.resolution)-1)*0.5
		for z in range(first_row,first_row+row_count):
			for x in int(job.resolution):
				var point:Vector2=job.center+Vector2(float(x)-half,float(z)-half)*spacing
				heights.append(point.x*0.01+Partition.PATCH_LIFT)
		return [heights]


func test_the_ground_is_sampled_once_per_node_and_where_it_lies()->void:
	var sampler:=RowSampler.new()
	var count:=9
	var cell:=0.5
	var origin:=Vector2(10.0,-4.0)
	var needed:=PackedByteArray()
	needed.resize(count*count)
	needed[2*count+3]=1
	needed[5*count+7]=1
	var cache:Dictionary={}
	var heights:=Partition.sample_heights(sampler,origin,cell,count,needed,cache,4)
	# Each needed node's own ground; the rest unread.
	assert_float(heights[2*count+3]).is_equal_approx((origin.x+3.0*cell)*0.01,0.0001)
	assert_float(heights[5*count+7]).is_equal_approx((origin.x+7.0*cell)*0.01,0.0001)
	assert_bool(is_nan(heights[0])).is_true()
	assert_int(sampler.rows).is_equal(2)
	# The same ground again comes from the cache.
	Partition.sample_heights(sampler,origin,cell,count,needed,cache,4)
	assert_int(sampler.rows).is_equal(2)


func test_the_layer_builds_on_a_worker_and_publishes_its_lines()->void:
	Borders.knowledge_override={"player":["boundary_marker_surveys"],"civ_02":["boundary_marker_surveys"]}
	var layer:Node3D=auto_free(preload("res://scripts/nation_border_layer.gd").new())
	add_child(layer)
	var seen:={"kind":"circle","x":40.0,"z":0.0,"radius":40.0,"source":"test","day":0}
	var areas:Array=CivilizationSystem.revealed_areas
	areas.append(seen)
	CivilizationSystem.fog_revision+=1
	layer.call("set_own_claims",[{"id":"home","primary":true,"position":Vector2(37.0,0.0),"claim_radius_km":5.0,"boundary":_outline(Vector2(37.0,0.0),5.0)}])
	var theirs:=Borders.make_claim("civ_02","town:x",Vector2(43.0,0.0),5.0)
	layer.set("foreign",[theirs])
	var grid:=Borders.grid_for(Vector2(40.0,0.0),20.0)
	layer.call("_start",grid,12345)
	var job:Object=layer.get("_job")
	assert_object(job).is_not_null()
	# The layer itself waits on the task once it is done (a task is waited on once).
	var began:=Time.get_ticks_msec()
	while not WorkerThreadPool.is_task_completed(int(job.get("task"))) and Time.get_ticks_msec()-began<20000: OS.delay_msec(5)
	layer.call("_poll")
	areas.erase(seen)
	CivilizationSystem.fog_revision+=1
	assert_int(int(layer.get("commits"))).is_equal(1)
	var wash:MeshInstance3D=layer.get("wash")
	assert_int((wash.mesh as ArrayMesh).get_surface_count()).is_equal(1)
	var inks:Array=layer.get("inks")
	assert_int(((inks[2] as MeshInstance3D).mesh as ArrayMesh).get_surface_count()).is_equal(1)
	# The frontier with the Kezari's town is published for the war marks and
	# says what it is on hover.
	var mark:=Borders.meeting_point("player","civ_02",Vector2(40.0,0.0))
	assert_float(mark.distance_to(Vector2(40.0,0.0))).is_less(0.5)
	var hover_lines:Array=layer.get("lines")
	assert_int(hover_lines.size()).is_equal(1)
	assert_str(String((hover_lines[0] as Dictionary).kind)).is_equal("frontier")


func test_charted_ground_is_followed_through_growth_and_trims()->void:
	var layer:Node3D=auto_free(preload("res://scripts/nation_border_layer.gd").new())
	var areas:Array=CivilizationSystem.revealed_areas
	var saved:Array=areas.duplicate()
	areas.clear()
	areas.append({"kind":"circle","x":0.0,"z":0.0,"radius":5.0,"source":"a","day":1})
	areas.append({"kind":"trail","x":10.0,"z":0.0,"radius":2.0,"points":[{"x":10.0,"z":0.0},{"x":20.0,"z":0.0}],"source":"b","day":2})
	CivilizationSystem.fog_revision+=1
	assert_array(Array(layer.call("_sync_record_boxes"))).is_equal([0,1])
	# Nothing new: nothing read again.
	assert_array(Array(layer.call("_sync_record_boxes"))).is_empty()
	# The trail grows: only it is read again.
	((areas[1] as Dictionary).points as Array).append({"x":30.0,"z":5.0})
	CivilizationSystem.fog_revision+=1
	assert_array(Array(layer.call("_sync_record_boxes"))).is_equal([1])
	var boxes:Array=layer.get("_record_boxes")
	assert_bool((boxes[1] as Rect2).has_point(Vector2(31.5,6.5))).is_true()
	# A new record.
	areas.append({"kind":"circle","x":-40.0,"z":12.0,"radius":3.0,"source":"c","day":3})
	CivilizationSystem.fog_revision+=1
	assert_array(Array(layer.call("_sync_record_boxes"))).is_equal([1,2])
	# A trim drops ground already charted twice: the list shifts, nothing is new,
	# and every bound still belongs to its own record.
	areas.remove_at(0)
	CivilizationSystem.fog_revision+=1
	assert_array(Array(layer.call("_sync_record_boxes"))).is_empty()
	boxes=layer.get("_record_boxes")
	assert_int(boxes.size()).is_equal(2)
	for index in areas.size(): assert_that(boxes[index]).is_equal(layer.call("_record_box",areas[index]))
	areas.clear()
	areas.append_array(saved)
	CivilizationSystem.fog_revision+=1


func test_strangers_towns_are_read_as_our_people_know_them()->void:
	var intelligence:RefCounted=CivilizationSystem.city_intelligence
	var saved_records:Dictionary=intelligence.get("records")
	var saved_civilizations:Array=CivilizationSystem.civilizations
	CivilizationSystem.civilizations=[{"id":"civ_02","name":"Kezari","strategic_regions":[
		{"id":"c2_a","controller":"civ_02","position":Vector2(100.0,0.0),"boundary":_outline(Vector2(100.0,0.0),6.0),"settlement_founded":true,"population":5000.0},
		{"id":"c2_b","controller":"player","position":Vector2(130.0,0.0),"boundary":_outline(Vector2(130.0,0.0),3.0),"settlement_founded":true,"population":900.0},
		{"id":"c2_c","controller":"civ_02","position":Vector2(80.0,30.0),"boundary":[],"settlement_founded":true,"population":2000.0},
		{"id":"c2_d","controller":"civ_02","position":Vector2(90.0,-30.0),"boundary":_outline(Vector2(90.0,-30.0),4.0),"settlement_founded":true,"ledger":{"ruin":{"day":5}}}]}]
	intelligence.set("records",{"player":{
		"c2_a":{"city_id":"c2_a","civ_id":"civ_02","controller":"civ_02","position":{"x":100.0,"z":0.0},"fields":{}},
		# We took this one since the last report: our people know what they hold.
		"c2_b":{"city_id":"c2_b","civ_id":"civ_02","controller":"civ_02","position":{"x":130.0,"z":0.0},"fields":{}},
		# No outline kept: judged from the head count reported.
		"c2_c":{"city_id":"c2_c","civ_id":"civ_02","controller":"civ_02","position":{"x":80.0,"z":30.0},"fields":{"population":{"low":1800.0,"high":2200.0}}},
		# Burned by us: no land to draw.
		"c2_d":{"city_id":"c2_d","civ_id":"civ_02","controller":"civ_02","position":{"x":90.0,"z":-30.0},"fields":{}},
		# Seen, but whose it is nobody knows.
		"far":{"city_id":"far","civ_id":"","controller":"","position":{"x":95.0,"z":5.0},"fields":{}}}})
	var cache:Dictionary={}
	var claims:=Borders.foreign_claims(Vector2(100.0,0.0),500.0,cache)
	var by_id:Dictionary={}
	for claim:Dictionary in claims: by_id[String(claim.id)]=claim
	assert_array(by_id.keys()).contains_exactly_in_any_order(["town:c2_a","town:c2_b","town:c2_c"])
	assert_str(String(by_id["town:c2_a"].owner)).is_equal("civ_02")
	assert_str(String(by_id["town:c2_b"].owner)).is_equal("player")
	assert_float(float(by_id["town:c2_a"].radius)).is_between(5.5,6.6)
	assert_float(float(by_id["town:c2_c"].radius)).is_equal_approx(Borders.estimated_radius(2000.0),0.01)
	# Read again with nothing moved: every claim is the one already made.
	var again:=Borders.foreign_claims(Vector2(100.0,0.0),500.0,cache)
	for claim:Dictionary in again: assert_bool(is_same(claim,by_id[String(claim.id)])).is_true()
	# Out of reach: not read at all.
	assert_int(Borders.foreign_claims(Vector2(-900.0,0.0),100.0,{}).size()).is_equal(0)
	intelligence.set("records",saved_records)
	CivilizationSystem.civilizations=saved_civilizations
