extends SceneTree
## Headless signal audit; generated WAV/JSON evidence stays outside the project.
const Voice:=preload("res://scripts/hud/court_voice.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
const LINE:="Great one, the stores are thin. We ask for rain, and for patience with the young ones."
func _init()->void:call_deferred("run")
func run()->void:
	var args:=OS.get_cmdline_user_args()
	var dir:=args[0] if not args.is_empty() else "/tmp/tat-court-voice-audit"
	DirAccess.make_dir_recursive_absolute(dir)
	var rows:Array=[]
	for register:String in ["man","woman","old_man","old_woman"]:
		var voice:=Voice.plain(register,42)
		for mood:String in ["neutral","afraid","tired"]:
			var feel:=Voice.feeling(mood)
			var sc:=Voice.Score.new(4.3,float(voice.f0))
			Voice.paint_line(sc,voice,Voice.plan(voice,LINE,4.0),feel,false)
			var samples:=Voice.voice_score(sc,voice,feel,42)
			Synth.to_stream(samples,0.62).save_to_wav(dir.path_join(register+"_"+mood+".wav"))
			var vs:=0.0;var vn:=0;var ns:=0.0;var nn:=0
			for i in samples.size():
				var frame:=mini(i/Voice.FRAME,sc.n-1)
				if sc.av[frame]>0.5:
					vs+=samples[i]*samples[i];vn+=1
				elif sc.af[frame]>0.05 or sc.ah[frame]>0.05:
					ns+=samples[i]*samples[i];nn+=1
			rows.append({"register":register,"mood":mood,"peak":Synth.peak_of(samples),"voice_rms":sqrt(vs/maxi(1,vn)),"noise_rms":sqrt(ns/maxi(1,nn)),"voiced_samples":vn,"noise_samples":nn})
		for source:String in ["vowel","breath","sibilant"]:
			var sc:=Voice.Score.new(1.0,float(voice.f0))
			sc.aspiration_gain=Voice.SPEECH_ASPIRATION_GAIN
			var formants:=Voice._vowel_formants("a",float(voice.fs))
			sc.f1.fill(formants[0]);sc.f2.fill(formants[1]);sc.f3.fill(formants[2]);sc.rd.fill(float(voice.rd))
			if source=="vowel":sc.av.fill(1.0)
			elif source=="breath":sc.ah.fill(0.55)
			else:sc.af.fill(0.42);sc.ff.fill(6000.0);sc.fq.fill(1.6)
			var samples:=Voice.voice_score(sc,voice,{},42)
			rows.append({"register":register,"source":source,"rms":Synth.rms_of(samples,2205,19845),"peak":Synth.peak_of(samples)})
	# Optional pre-change script verifies deliberate whispers and Foley exactly.
	if args.size()>1:
		var previous:=GDScript.new()
		previous.source_code=FileAccess.get_file_as_string(args[1])
		if previous.reload()!=OK:quit(1);return
		for register:String in ["man","woman","old_man","old_woman"]:
			var voice:=Voice.plain(register,42)
			if Voice.render_samples(voice,LINE,4.0,"neutral",true)!=previous.render_samples(voice,LINE,4.0,"neutral",true):
				push_error("Whisper changed: "+register);quit(1);return
			var steps:=[[0.02,"a",0.0,0.0,1.0],[0.2,"a",0.0,0.8,1.0],[0.08,"a",0.0,0.0,1.0]]
			if Voice.gesture(voice,steps,42)!=previous.gesture(voice,steps,42):
				push_error("Breath gesture changed: "+register);quit(1);return
		print("Unchanged: four whispered lines and four breath gestures (sample-for-sample)")
	var file:=FileAccess.open(dir.path_join("metrics.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(rows,"  "));file.close()
	print(JSON.stringify(rows));quit()
