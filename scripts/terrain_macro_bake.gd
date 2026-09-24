extends RefCounted
## One deterministic lattice raster for a single world seed, built on ONE
## background WorkerThreadPool thread. A band sampler fills whole lattice rows and
## returns its channels as packed arrays; the worker assembles them and, when a
## cache path is given, reads or writes a compressed copy in user://.
##
## Deliberately single-threaded: in debug/editor builds every GDScript object call
## validates through ObjectDB's global lock, so extra sampling threads do not go
## faster and slow the main thread (measured on a terrain-sampling workload:
## +20-37% main-thread cost with one busy bake thread, about 10x with nine).
##
## The worker also idles between bands (`duty` = busy fraction, default 0.5),
## which measured +12% main-thread cost; a first-time world bake therefore takes
## longer (~95 s for all levels) but costs frames far less. Cached worlds load
## in ~0.2 s on the worker and skip the bake entirely.
##
## Contract: nothing reads `channels` before `ready`; the owner must call cancel()
## before freeing any object the sampler calls. Every band depends only on its
## own coordinates, so the raster is identical however it is scheduled.

const CACHE_MAGIC:="TTMACRO1"

var rows:=0
var band:=8
var task_id:=-1
var ready:=false
var cancelled:=false
var from_cache:=false
var channels:Array=[]
var started_usec:=0
var finished_usec:=0
var cache_path:=""
var expected_sizes:=PackedInt32Array()
var cache_keep:=2
var duty:=0.5
var _sampler:Callable
var _result:Array=[]


func start(total_rows:int,band_rows:int,sampler:Callable,path:="",sizes:=PackedInt32Array(),keep:=2)->void:
	assert(task_id<0 and not ready)
	rows=total_rows
	band=maxi(1,band_rows)
	_sampler=sampler
	cache_path=path
	expected_sizes=sizes
	cache_keep=keep
	started_usec=Time.get_ticks_usec()
	task_id=WorkerThreadPool.add_task(_run,false,"Terrain macro bake")


func running()->bool:
	return task_id>=0


func _run()->void:
	## Worker thread.
	if cache_path!="" and _load_cache():return
	var bands:Array=[]
	var first:=0
	while first<rows:
		if cancelled:return
		var band_start:=Time.get_ticks_usec()
		bands.append(_sampler.call(first,mini(band,rows-first)))
		first+=band
		if duty<1.0:OS.delay_usec(int(float(Time.get_ticks_usec()-band_start)*(1.0-duty)/maxf(0.05,duty)))
	var merged_channels:Array=[]
	var head:Array=bands[0]
	for channel in head.size():
		var merged:Variant=head[channel]
		for index in range(1,bands.size()):
			var part:Array=bands[index]
			merged.append_array(part[channel])
		merged_channels.append(merged)
	if cancelled:return
	_result=merged_channels
	if cache_path!="":_store_cache()


func poll()->bool:
	## Main thread only. Returns true once the raster is assembled and readable.
	if ready or task_id<0:return ready
	if not WorkerThreadPool.is_task_completed(task_id):return false
	WorkerThreadPool.wait_for_task_completion(task_id)
	task_id=-1
	if cancelled or _result.is_empty():return false
	channels=_result
	_result=[]
	finished_usec=Time.get_ticks_usec()
	ready=true
	return true


func cancel()->void:
	cancelled=true
	if task_id>=0:
		WorkerThreadPool.wait_for_task_completion(task_id)
		task_id=-1
	_result=[]
	channels.clear()
	ready=false


func elapsed_ms()->float:
	return float(finished_usec-started_usec)/1000.0 if ready else -1.0


func _load_cache()->bool:
	if not FileAccess.file_exists(cache_path):return false
	var file:=FileAccess.open_compressed(cache_path,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	if file==null:return false
	var magic:Variant=file.get_var()
	var loaded:Array=[]
	if magic is String and String(magic)==CACHE_MAGIC:
		for size in expected_sizes:
			var channel:Variant=file.get_var()
			if channel==null or not (channel is PackedFloat32Array or channel is PackedInt32Array or channel is PackedByteArray) or channel.size()!=size:
				loaded.clear();break
			loaded.append(channel)
	file.close()
	if loaded.size()!=expected_sizes.size() or loaded.is_empty():return false
	_result=loaded
	from_cache=true
	return true


func _store_cache()->void:
	var directory:=cache_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(directory)
	var file:=FileAccess.open_compressed(cache_path,FileAccess.WRITE,FileAccess.COMPRESSION_ZSTD)
	if file==null:return
	file.store_var(CACHE_MAGIC)
	for channel:Variant in _result:file.store_var(channel)
	file.close()
	# Bounded: keep only the most recently written files of this kind.
	var prefix:=cache_path.get_file().get_slice("_s",0)+"_s"
	var files:Array[String]=[]
	for name in DirAccess.get_files_at(directory):
		if name.begins_with(prefix) and name.ends_with(".bin"):files.append(name)
	if files.size()<=cache_keep:return
	files.sort_custom(func(a:String,b:String)->bool:return FileAccess.get_modified_time(directory+"/"+a)>FileAccess.get_modified_time(directory+"/"+b))
	for index in range(cache_keep,files.size()):DirAccess.remove_absolute(directory+"/"+files[index])
