extends "res://tools/court_wardrobe_audit.gd"
## Diagnostic companion to the unchanged strict stretch audit. Reports physical
## edge extension as well as ratios; it does not turn failures into passes.

func _ready()->void:
	var bins:={"up_to_10mm":0,"10_to_20mm":0,"20_to_40mm":0,"over_40mm":0}
	var parts:Dictionary={};var clips:Dictionary={};var total:=0;var flagged:=0
	for variant:String in Figure.BODIES:
		for outfit:String in Wardrobe.OUTFITS:
			var f:=Figure.new();add_child(f);f.setup({"variant":variant,"outfit":outfit})
			f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			var acting=Acting.of(f);acting.active=false
			var probes:=_probes(f,outfit)
			for clip:String in ["walk_in","walk_out","sit","sit_cross","kneel","bow"]:
				Audit._reset(f,acting)
				if clip in ["walk_in","walk_out","sit"]:f.play(clip,0,0)
				else:Acting.play(f,clip,{"blend":0.0})
				for sample in 8:
					for step in 5:Audit._frame(f,acting)
					var pose:=Audit._pose(f.skeleton,false);var extension:=-1.0
					for probe:Dictionary in probes:
						if probe.kind!="edges":continue
						var p:=Audit._skin(probe,pose)
						for edge in probe.rest.size():
							var rest:float=probe.rest[edge]
							if rest<Audit.STRETCH_MIN_EDGE:continue
							var length:=p[edge*2].distance_to(p[edge*2+1]);var ratio:=length/rest
							if ratio<=Audit.STRETCH_MAX:continue
							var growth:=length-rest;extension=maxf(extension,growth)
							var key:=String(probe.name)
							if growth>float((parts.get(key,{}) as Dictionary).get("growth",-1.0)):
								parts[key]={"growth":growth,"rest":rest,"posed":length,"ratio":ratio,
									"where":"%s %s %s t=%.2f" % [variant,outfit,clip,(sample+1)/6.0],
									"a":str(probe.verts[edge*2]),"b":str(probe.verts[edge*2+1])}
					total+=1
					if extension<0:continue
					flagged+=1;clips[clip]=int(clips.get(clip,0))+1
					var bin_key:="up_to_10mm" if extension<=.01 else ("10_to_20mm" if extension<=.02 else ("20_to_40mm" if extension<=.04 else "over_40mm"))
					bins[bin_key]+=1
			f.free()
	print("WARDROBE_STRAIN ",JSON.stringify({"samples":total,"flagged":flagged,"maximum_extension_per_flagged_sample":bins,"clips":clips,"parts":parts}))
	get_tree().quit(1 if flagged else 0)
