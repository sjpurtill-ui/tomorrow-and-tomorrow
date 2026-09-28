extends RefCounted
## LocalTerrain's per-vertex sampler chain for streamed regional patches, fused
## into one pass that any thread may run (codex/map-speed).
##
## It computes exactly what TerrainPatchBuilder asked of LocalTerrain's
## `_height_at`, `_terrain_color_at`, `_terrain_surface_fields_at` and
## `_terrain_seasonality_at` (with PlanetEnvironment's geology and
## seasonality), in the same arithmetic order, so every stored value is
## bit-identical (tests/test_terrain_patch_sampler.gd). What it saves: the
## four sampler calls and three Dictionaries a vertex, the continental noise
## that height, climate and seasonality each evaluated, and every lookup of
## the world seed.
##
## It owns duplicates of the noise it reads, so the terrain may reconfigure
## its own for a new world while a patch is still sampling here; the owner
## drops any patch sampled for another seed. Nothing here touches the scene.

const COAST_SHAPE:=preload("res://scripts/coast_shape.gd")
const PATCH_LIFT:=0.0006
const SEA_LEVEL:=0.0

var seed_value:=0
var world_depth:=20004.0
var planet_width:=40075.0
var planet_depth:=20004.0
var continent:FastNoiseLite
var terrain:FastNoiseLite
var detail:FastNoiseLite
var mountain:FastNoiseLite
var moisture:FastNoiseLite
var relief:FastNoiseLite
## PlanetEnvironment's: its continent (seasonality) when configured apart
## from the terrain's, and its three geology fields.
var env_continent:FastNoiseLite
var geology_a:FastNoiseLite
var geology_b:FastNoiseLite
var geology_c:FastNoiseLite
var shared_continent:=true
# Seed-derived constants the terrain recomputed at every vertex.
var _river_phase:=0.0
var _drainage_offset:=0.0
var _drainage_channel_offset:=0.0
var _drainage_phase_a:=0.0
var _drainage_phase_b:=0.0
var _drainage_phase_c:=0.0
var _drainage_phase_d:=0.0
var _cradle_cos:=1.0
var _cradle_sin:=0.0


## A sampler for `owner` (LocalTerrain) as configured now. Main thread.
static func from_terrain(owner:Object)->RefCounted:
	var sampler:=new()
	PlanetEnvironment.prepare_macro_sampling()
	sampler.seed_value=int(GameState.world_seed)
	sampler.world_depth=float(owner.get("world_depth"))
	sampler.planet_width=float(PlanetEnvironment.PLANET_WIDTH_KM)
	sampler.planet_depth=float(PlanetEnvironment.PLANET_DEPTH_KM)
	sampler.continent=(owner.get("continent_noise") as FastNoiseLite).duplicate()
	sampler.terrain=(owner.get("terrain_noise") as FastNoiseLite).duplicate()
	sampler.detail=(owner.get("detail_noise") as FastNoiseLite).duplicate()
	sampler.mountain=(owner.get("mountain_noise") as FastNoiseLite).duplicate()
	sampler.moisture=(owner.get("moisture_noise") as FastNoiseLite).duplicate()
	sampler.relief=(owner.get("mountain_relief").get("noise") as FastNoiseLite).duplicate()
	var env_continent_source:FastNoiseLite=PlanetEnvironment.get("_continent")
	sampler.shared_continent=same_noise(env_continent_source,sampler.continent)
	sampler.env_continent=sampler.continent if sampler.shared_continent else env_continent_source.duplicate()
	sampler.geology_a=(PlanetEnvironment.get("_geology_a") as FastNoiseLite).duplicate()
	sampler.geology_b=(PlanetEnvironment.get("_geology_b") as FastNoiseLite).duplicate()
	sampler.geology_c=(PlanetEnvironment.get("_geology_c") as FastNoiseLite).duplicate()
	sampler._prepare_constants()
	return sampler


## Two noises that return the same value at every point.
static func same_noise(a:FastNoiseLite,b:FastNoiseLite)->bool:
	if a==null or b==null:return false
	for property in ["seed","frequency","offset","noise_type","fractal_type","fractal_octaves","fractal_lacunarity","fractal_gain","fractal_weighted_strength","fractal_ping_pong_strength","cellular_distance_function","cellular_jitter","cellular_return_type","domain_warp_enabled"]:
		if a.get(property)!=b.get(property):return false
	return true


func _prepare_constants()->void:
	# Exactly the terrain's own expressions (local_terrain.gd), evaluated once.
	_river_phase=float(seed_value%97)*0.031
	var phase:=float(posmod(seed_value,10007))/10007.0
	_drainage_offset=(phase-0.5)*2.40
	_drainage_channel_offset=(phase-.5)*2.4
	_drainage_phase_a=phase*31.0
	_drainage_phase_b=phase*67.0
	_drainage_phase_c=phase*TAU
	_drainage_phase_d=phase*17.0
	var cradle_angle:=float(abs(seed_value)%6283)*0.001
	_cradle_cos=cos(cradle_angle)
	_cradle_sin=sin(cradle_angle)


## Grid rows [first_row, first_row+row_count) of the patch `job` describes
## (TerrainPatchBuilder: center, span, resolution and its reuse lattice), as
## [heights, vertices, colors, climate, geology, seasons, sampled, reused]
## covering just those rows. A node the job's earlier patch holds at the
## identical coordinate is copied from it, never resampled.
func sample_rows(job:Object,first_row:int,row_count:int)->Array:
	var resolution:int=job.resolution
	var center:Vector2=job.center
	var spacing:float=float(job.span)/float(resolution-1)
	var half_cells:=float(resolution-1)*0.5
	var nodes:=resolution*row_count
	var heights:=PackedFloat32Array();heights.resize(nodes)
	var vertices:=PackedVector3Array();vertices.resize(nodes)
	var colors:=PackedColorArray();colors.resize(nodes)
	var climate_uv:=PackedVector2Array();climate_uv.resize(nodes)
	var geology_uv:=PackedVector2Array();geology_uv.resize(nodes)
	var seasons:=PackedFloat32Array();seasons.resize(nodes)
	# The earlier patch whose exact samples this one may reuse (the job's
	# _configure_reuse), read once.
	var reuse_resolution:int=job.reuse_resolution
	var reuse_stride:int=job.reuse_stride
	var reuse_offset:Vector2i=job.reuse_offset
	var reuse_center:Vector2=job.reuse_center
	var reuse_span:float=job.reuse_span
	var reuse_vertices:PackedVector3Array=job.reuse_vertices
	var reuse_colors:PackedColorArray=job.reuse_colors
	var reuse_climate:PackedVector2Array=job.reuse_climate
	var reuse_geology:PackedVector2Array=job.reuse_geology
	var reuse_seasons:PackedFloat32Array=job.reuse_seasons
	var reuse_cells:=float(reuse_resolution-1)
	var sampled:=0
	var reused:=0
	var index:=0
	for z_index in range(first_row,first_row+row_count):
		for x_index in resolution:
			# The builder's own coordinate: rounded through the float32 mesh.
			var point:=Vector2(center.x+(float(x_index)-half_cells)*spacing,center.y+(float(z_index)-half_cells)*spacing)
			var x:=float(point.x);var z:=float(point.y)
			if reuse_resolution>0 and (reuse_stride==1 or ((x_index-reuse_offset.x)%reuse_stride==0 and (z_index-reuse_offset.y)%reuse_stride==0)):
				# TerrainPatchBuilder._copy_shared_sample: only the identical
				# renderable coordinate may stand in for a fresh sample.
				var column:=roundi((x-reuse_center.x)/reuse_span*reuse_cells+reuse_cells*0.5)
				var row:=roundi((z-reuse_center.y)/reuse_span*reuse_cells+reuse_cells*0.5)
				if column>=0 and column<reuse_resolution and row>=0 and row<reuse_resolution:
					var source:=row*reuse_resolution+column
					var stored:=reuse_vertices[source]
					if stored.x==x and stored.z==z:
						vertices[index]=stored;heights[index]=stored.y;colors[index]=reuse_colors[source]
						climate_uv[index]=reuse_climate[source];geology_uv[index]=reuse_geology[source]
						seasons[index]=reuse_seasons[source]
						reused+=1;index+=1
						continue
			# --- LocalTerrain._world_height_at ---
			var latitude:=clampf(absf(z)/(world_depth*0.5),0.0,1.0)
			var continent_xz:=continent.get_noise_2d(x,z)
			var continental:=continent_xz*0.78
			continental+=continent.get_noise_2d(x*0.47+7813.0,z*0.47-4197.0)*0.34
			var cradle:=exp(-pow(x/1150.0,2.0)-pow(z/880.0,2.0))*1.05
			var land_signal:=continental+cradle-0.075-pow(latitude,3.2)*0.72
			# CoastShape.roughen
			var band:=1.0-smoothstep(COAST_SHAPE.COAST_BAND_INNER,COAST_SHAPE.COAST_BAND_OUTER,absf(land_signal))
			if band>0.0:
				var offset:=terrain.get_noise_2d(x*1.9+5310.0,z*1.9-2270.0)*0.010
				offset+=detail.get_noise_2d(x*0.61-4410.0,z*0.61+3920.0)*0.004
				offset+=detail.get_noise_2d(x*3.3+1290.0,z*3.3-770.0)*0.0015
				offset+=detail.get_noise_2d(x*14.0-3170.0,z*14.0+2630.0)*0.0004
				land_signal=land_signal+maxf(0.0,offset+COAST_SHAPE.SEAWARD_BIAS)*band
			var raw:float
			if land_signal<=0.0:
				# CoastShape.sea_height
				raw=-COAST_SHAPE.SHORE_DROP*smoothstep(0.0,COAST_SHAPE.SHORE_DROP_RAMP,-land_signal)-pow(-land_signal,1.22)*6.8
			else:
				var shore_relief:=smoothstep(0.0,COAST_SHAPE.SHORE_RELIEF_RAMP,land_signal)
				var rolling:=terrain.get_noise_2d(x,z)
				var local_detail:=detail.get_noise_2d(x,z)
				var hill_signal:=maxf(0.0,terrain.get_noise_2d(x+820.0,z-460.0)+0.10)
				var ridge:=1.0-absf(mountain.get_noise_2d(x,z))
				ridge=pow(clampf((ridge-0.34)/0.66,0.0,1.0),2.35)
				var belt:=clampf((mountain.get_noise_2d(x*0.41+9200.0,z*0.41-3800.0)+0.18)*1.55,0.0,1.0)
				# CoastShape.land_base, then the relief.
				var height:=(COAST_SHAPE.SHORE_BASE_HEIGHT*smoothstep(0.0,COAST_SHAPE.SHORE_BASE_RAMP,land_signal)+land_signal*1.48)+(rolling*1.42+local_detail*0.56+pow(hill_signal,2.0)*2.05+ridge*belt*8.4)*shore_relief
				var regional_roll:=detail.get_noise_2d(x*7.5+1640.0,z*7.5-930.0)*0.055
				var regional_ridge_signal:=1.0-absf(detail.get_noise_2d(x*4.2-2710.0,z*4.2+1850.0))
				var regional_ridge:=pow(clampf((regional_ridge_signal-0.48)/0.52,0.0,1.0),2.2)*0.075
				var regional_weight:=smoothstep(0.04,0.28,land_signal)
				height+=(regional_roll+regional_ridge)*regional_weight
				var cradle_x:=x*_cradle_cos-z*_cradle_sin
				var cradle_z:=x*_cradle_sin+z*_cradle_cos
				var range_band:=exp(-pow((cradle_x-55.0)/25.0,2.0))*exp(-pow(cradle_z/510.0,4.0))
				var range_teeth:=pow(clampf((1.0-absf(detail.get_noise_2d(x*0.72+330.0,z*0.72-710.0))-0.20)/0.80,0.0,1.0),1.55)
				height+=range_band*(0.65+range_teeth*6.8)*shore_relief
				# TerrainMountainRelief.height_at
				var strength:=smoothstep(.35,2.8,(ridge*belt*8.4+range_band*(0.65+range_teeth*6.8))*shore_relief)
				var mountain_height:=0.0
				if strength>0:
					var crest:=clampf(relief.get_noise_2d(x,z)*.5+.5,0,1)
					mountain_height=(pow(crest,2.2)*.8-.18)*strength
				height+=mountain_height*smoothstep(.2,.8,height)
				# LocalTerrain._local_drainage_distance_at
				var channel_index:=roundi((x-_drainage_offset)/2.40)
				var activation:=smoothstep(0.29,0.72,0.50+sin(z*1.11+float(channel_index)*1.73+_drainage_phase_a)*0.31+sin(z*0.37-float(channel_index)*2.41+_drainage_phase_b)*0.19)
				if activation>=0.28:
					var channel_x:=float(channel_index)*2.4+_drainage_channel_offset+sin(z*1.34+float(channel_index)*2.17+_drainage_phase_c)*.22+sin(z*3.71-float(channel_index)*.83+_drainage_phase_d)*.055
					var local_drainage_distance:=absf(x-channel_x)+lerpf(0.075,0.0,activation)
					if local_drainage_distance<0.11:
						var swale:=pow(1.0-local_drainage_distance/0.11,1.72)
						height-=swale*(0.0045+0.0045*swale)*smoothstep(0.004,0.03,height)
				# LocalTerrain._world_river_x
				if absf(z)<=760.0:
					var main_distance:=absf(x-(-18.0+sin(z/128.0+_river_phase)*32.0+sin(z/57.0-0.8)*14.0+sin(z/21.0+1.7)*4.5))
					if main_distance<4.8:
						var floodplain:=pow(1.0-main_distance/4.8,1.65)
						height=lerpf(height,minf(height,0.22+rolling*0.08),floodplain*0.90)
					if main_distance<0.34:
						height-=pow(1.0-main_distance/0.34,2.0)*0.0065
				raw=height
			var lifted:=raw+PATCH_LIFT
			heights[index]=lifted
			vertices[index]=Vector3(x,lifted,z)
			# --- LocalTerrain._climate_at, at the lifted height ---
			var temperature:=clampf(1.0-latitude-maxf(0.0,lifted)*0.055,0.0,1.0)
			var interior:=clampf((continent_xz-0.05)*1.2,0.0,0.5)
			var precipitation:=clampf(0.48+moisture.get_noise_2d(x,z)*0.52+terrain.get_noise_2d(x+1700.0,z-2300.0)*0.34-interior*0.55,0.0,1.0)
			precipitation=clampf(0.5+(precipitation-0.5)*1.9,0.0,1.0)
			var river_distance:=INF
			if absf(z)<=760.0:
				river_distance=absf(x-(-18.0+sin(z/128.0+_river_phase)*32.0+sin(z/57.0-0.8)*14.0+sin(z/21.0+1.7)*4.5))
			if river_distance<16.0: precipitation=maxf(precipitation,precipitation+((1.0-river_distance/16.0)*0.28))
			precipitation=clampf(precipitation,0.0,1.0)
			# --- LocalTerrain._terrain_color_at / _biome_from_climate ---
			if lifted<SEA_LEVEL:
				colors[index]=Color(Color("#21363a"),0.0)
			else:
				var woodland:=clampf((precipitation-0.40)*2.6,0.0,1.0)*clampf((temperature-0.16)*3.4,0.0,1.0)
				if lifted>3.2: woodland*=1.0-clampf((lifted-3.2)/5.2,0.0,0.74)
				woodland*=0.22+0.78*smoothstep(-0.30,0.30,detail.get_noise_2d(x*1.8+7.0,z*1.8-29.0))
				# Only the wetland and floodplain classes tint the ground.
				var wetland:=false
				var floodplain_land:=false
				if temperature>=0.16 and lifted<=6.0:
					if river_distance<3.2 and lifted<3.0:floodplain_land=true
					elif precipitation>0.70 and lifted<0.9 and river_distance<18.0:wetland=true
				var color:=Color("#7a6c4c").lerp(Color("#5f6a45"),clampf((precipitation-0.18)*3.2,0.0,1.0))
				color=color.lerp(Color("#a48a59"),(1.0-smoothstep(0.30,0.49,precipitation))*0.92)
				color=color.lerp(Color("#2c4a34"),woodland*0.9)
				if wetland: color=color.lerp(Color("#3a5348"),0.62)
				if floodplain_land: color=color.lerp(Color("#33553c"),0.70)
				elif river_distance<14.0: color=color.lerp(Color("#365443"),pow(1.0-river_distance/14.0,1.35)*0.38)
				if precipitation<0.18: color=color.lerp(Color("#8b7550"),0.5)
				if lifted>3.2: color=color.lerp(Color("#77766f"),clampf((lifted-3.2)/5.2,0.0,0.74))
				if temperature<0.22: color=color.lerp(Color("#bcbfb1"),clampf((0.22-temperature)*4.5,0.0,0.86))
				color.a=woodland
				colors[index]=color
			# --- LocalTerrain._terrain_surface_fields_at / PlanetEnvironment._geology ---
			var geology_a_value:=(geology_a.get_noise_2d(x,z)+1.0)*0.5
			var geology_b_value:=(geology_b.get_noise_2d(x-5300.0,z+2100.0)+1.0)*0.5
			var geology_c_value:=(geology_c.get_noise_2d(x+1700.0,z-7900.0)+1.0)*0.5
			var igneous:=clampf(geology_b_value*0.72+maxf(0.0,lifted)/9.0*0.28,0.0,1.0)
			var sedimentary:=clampf(geology_a_value*0.76+(1.0-geology_b_value)*0.24,0.0,1.0)
			var metamorphic:=clampf((1.0-geology_a_value)*0.40+geology_b_value*0.38+geology_c_value*0.22,0.0,1.0)
			var total:=maxf(.001,sedimentary+igneous+metamorphic)
			climate_uv[index]=Vector2(1.0+precipitation,temperature)
			geology_uv[index]=Vector2(sedimentary/total,igneous/total)
			# --- PlanetEnvironment.seasonality_at ---
			var env_interior:=interior if shared_continent else clampf((env_continent.get_noise_2d(x,z)-0.05)*1.2,0.0,0.5)
			seasons[index]=lerpf(5.0,22.0,clampf(absf(z)/(planet_depth*0.5),0.0,1.0))*lerpf(0.78,1.20,clampf(absf(x)/(planet_width*0.5)*0.35+env_interior*1.2,0.0,1.0))
			sampled+=1
			index+=1
	return [heights,vertices,colors,climate_uv,geology_uv,seasons,sampled,reused]
