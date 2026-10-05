extends SceneTree
## Headless audio examples from the same recordings and timing used at court.
const Voice:=preload("res://scripts/hud/court_voice.gd")
const Reactions:=preload("res://scripts/hud/court_reactions.gd")
const Gore:=preload("res://scripts/hud/court_gore_foley.gd")
const Synth:=preload("res://scripts/hud/court_synth.gd")
func _initialize()->void:
	call_deferred("render_examples")
func render_examples()->void:
	var folder:=ProjectSettings.globalize_path("res://artifacts/execution-preview/")
	DirAccess.make_dir_recursive_absolute(folder)
	for sex:String in ["male","female"]:
		var spec:=Voice.spec({"name":"Ash","age":32,"sex":sex},"player",7)
		var samples:=Synth.buffer(6.0)
		Synth.mix_into(samples,Gore.make("whoomph",0),0,0.24)
		Synth.mix_into(samples,Reactions.make("burn_scream",spec,81),Synth.n_of(0.1),db_to_linear(-5.0))
		for at:float in [1.2,3.1,5.4]:Synth.mix_into(samples,Gore.make("fire_pop",2),Synth.n_of(at),0.16)
		var stream:=Synth.to_stream(samples)
		var error:=stream.save_to_wav(folder+"burn-recorded-"+sex+".wav")
		if error!=OK:push_error("Could not save audio example");quit(1);return
		print("BURN_VOICE_PREVIEW ",sex," seconds=",stream.get_length()," peak=",Synth.peak_of(samples))
	quit(0)
