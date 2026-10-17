extends GdUnitTestSuite
## Ordinary court speech must carry a voice rather than equally loud air.
## Measure rendered samples against their authored voiced/noise intervals,
## so changing controls without changing the audible signal cannot pass.
const Voice:=preload("res://scripts/hud/court_voice.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
const LINE:="Great one, the stores are thin. We ask for rain, and for patience with the young ones."

func test_normal_replies_keep_noise_below_voiced_syllables()->void:
	for register:String in ["man","woman","old_man","old_woman"]:
		for mood:String in ["neutral","afraid","tired"]:
			var voice:=Voice.plain(register,42)
			var feel:=Voice.feeling(mood)
			var sc:=Voice.Score.new(4.3,float(voice.f0))
			Voice.paint_line(sc,voice,Voice.plan(voice,LINE,4.0),feel,false)
			var samples:=Voice.voice_score(sc,voice,feel,42)
			var voiced_energy:=0.0;var voiced_count:=0
			var noise_energy:=0.0;var noise_count:=0
			for i in samples.size():
				var frame:=mini(i/Voice.FRAME,sc.n-1)
				if sc.av[frame]>0.5:
					voiced_energy+=samples[i]*samples[i];voiced_count+=1
				elif sc.af[frame]>0.05 or sc.ah[frame]>0.05:
					noise_energy+=samples[i]*samples[i];noise_count+=1
			assert_int(voiced_count).is_greater(1000)
			assert_int(noise_count).is_greater(1000)
			var voiced_rms:=sqrt(voiced_energy/maxi(1,voiced_count))
			var noise_rms:=sqrt(noise_energy/maxi(1,noise_count))
			assert_float(voiced_rms).is_greater(0.01)
			assert_float(noise_rms/voiced_rms).override_failure_message(register+" "+mood+": air overpowers the voice").is_less(0.6)

func test_explicit_whispers_and_breath_gestures_remain_audible()->void:
	var voice:=Voice.plain("man",42)
	var whisper:=Voice.render(voice,LINE,4.0,"neutral",true)
	var samples:=Synth.samples_of(whisper)
	assert_float(Synth.rms_of(samples)).is_greater(0.03)
	assert_float(Synth.peak_of(samples)).is_less_equal(0.63)
	var breath:=Voice.gesture(voice,[[0.02,"a",0.0,0.0,1.0],[0.2,"a",0.0,0.8,1.0],[0.08,"a",0.0,0.0,1.0]],42)
	assert_float(Synth.rms_of(breath)).is_greater(0.1)
