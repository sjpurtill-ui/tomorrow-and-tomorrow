extends RefCounted
## Presentation identities for the complete supported catalog. All choices
## come from the work's saved definition, never the viewer's current year.
## Architecture and ceremony share this read-only description; it grants no
## practice, worker, material, reward or construction progress.
const Concept:=preload("res://scripts/wonder_concept.gd")
const Catalog:=preload("res://scripts/undertaking_catalog.gd")
const SCALES:={"modest":.78,"grand":1.0,"audacious":1.3}
const TIER_STYLES:=["First craft","Dressed masonry","Arcades and columns","Vaults and buttresses","Iron and precision","Engineered forms"]

# title, construction phases, emblem, architectural accent
const FORMS:={
	"ring":["The circle of standing stones",["Setting out","Raising stones","Setting lintels","Standing"],"circle","a89671"],
	"mound":["The terraced earthwork",["Groundworks","Banking earth","Crowning the mound","Standing"],"summit","849166"],
	"stair":["The monumental stair",["Footings","Laying flights","Crowning the ascent","Standing"],"ascent","c29c67"],
	"tower":["The rising tower",["Footings","Raising storeys","Finishing the crown","Standing"],"pinnacle","a5afbb"],
	"hall":["The great gathering hall",["Setting posts","Raising the frame","Closing the roof","Standing"],"hearth","b0794c"],
	"cistern":["The water court",["Excavating","Lining the basin","Finishing the water court","Standing"],"water","6b9ba5"],
	"granary":["The raised storehouses",["Setting piers","Raising the stores","Sealing the roofs","Standing"],"sheaf","c4a05e"],
	"bridge":["The great crossing",["Setting abutments","Raising the spans","Laying the crossing","Standing"],"crossing","8aada8"],
	"causeway":["The raised causeway",["Groundworks","Banking the road","Laying the crest","Standing"],"road","a39071"],
	"dam":["The river wall",["Setting foundations","Raising the wall","Finishing the spillways","Standing"],"sluice","668b9f"],
	"colossus":["The great carved figure",["Laying the plinth","Raising the figure","Crowning the carving","Standing"],"figure","b69a74"],
	"garden":["The ordered garden",["Marking the paths","Forming the beds","Planting the canopy","Standing"],"bough","718958"],
	"observatory":["The house of the heavens",["Aligning foundations","Raising the sky court","Setting the instruments","Standing"],"stars","7892ae"],
	"gate":["The monumental gateway",["Footings","Raising the gatehouses","Joining the arch","Standing"],"threshold","b4915b"],
	"canal":["The great waterway",["Cutting the channel","Lining the banks","Setting the crossings","Standing"],"channel","6b9a9b"],
	"archive":["The house of memory",["Footings","Raising the galleries","Finishing the reading court","Standing"],"record","95779a"],
	"amphitheatre":["The open theatre",["Shaping the bowl","Raising the tiers","Finishing the stage","Standing"],"voice","b17769"],
	"lighthouse":["The guiding beacon",["Setting the sea plinth","Raising the lantern tower","Crowning the beacon","Standing"],"beacon","d3ae61"],
}

# form, material, title, construction phases, emblem, architectural accent
const LEGACY:={
	"ancestor_ring":["ring","stone","Ancestors' Ring",["Marking lineage places","Raising the ancestor stones","Joining the remembrance circle","Standing"],"lineages","a392ad"],
	"great_hall":["hall","timber","Hall of Many Hearths",["Setting the long posts","Raising the many-hearth frame","Closing the great roof","Standing"],"many_hearths","c58d59"],
	"rain_court":["cistern","brick","Court of Collected Rain",["Excavating the catchment","Lining the collecting court","Setting the rain channels","Standing"],"rain","76a1af"],
	"flood_terraces":["stair","earth","Gardens Above the Flood",["Surveying the high ground","Banking the planted terraces","Finishing the flood steps","Standing"],"flood_gardens","79925f"],
	"star_steps":["observatory","stone","Steps of the Watching Sky",["Aligning the first light","Raising the sky steps","Setting the sighting stones","Standing"],"solstice","b4a6cb"],
	"kiln_court":["kilns","brick","Court of a Hundred Fires",["Laying the fire court","Building the kiln chambers","Closing the firing domes","Standing"],"kiln_fire","bc7146"],
	"long_song":["hall","timber","House of the Long Song",["Setting the singers' hall","Raising the sounding galleries","Closing the song roof","Standing"],"song","af8194"],
	"common_stores":["granary","timber","Granary of the Covenant",["Setting the raised piers","Building the covenant bins","Finishing the seal court","Standing"],"covenant","c3a15c"],
	"safe_passage":["ring","stone","Sanctuary of Safe Passage",["Marking the sanctuary","Raising its open thresholds","Finishing the shelter gates","Standing"],"sanctuary","89a69a"],
	"living_orchard":["garden","earth","Orchard of Generations",["Marking the generations","Forming the orchard walks","Planting the named groves","Standing"],"generations","779952"],
	"stone_crown":["mound","stone","Crown of the Ridge",["Laying the ridge base","Raising the crown terraces","Setting the beacon crown","Standing"],"crown","bba66f"],
	"measures_house":["hall","timber","House of Common Measures",["Setting the measuring court","Raising the paired halls","Placing the standards","Standing"],"measure","92aeb0"],
}

# Purpose is an independent layer: any valid conceived form may carry it.
# The words describe a symbolic dedication, never a new economic effect.
const PURPOSES:={
	"honor_dead":["Remembrance","names","a396b2","The names of those remembered are spoken before the work."],
	"bind_tribes":["The common pledge","joined_hands","bf995f","The assembly renews the promise that binds these people together."],
	"tame_flood":["The keeping of waters","water_bowl","719eaf","A vessel of water marks the charge entrusted to the keepers."],
	"feed_people":["The promise of provision","sheaf","c2a258","A ceremonial sheaf marks the promise to provide for the people."],
	"watch_heavens":["The watching of the sky","star_disc","879fc2","The assembly turns toward the sky that the work was raised to watch."],
	"awe_rivals":["The showing of strength","standard","a78562","The work is presented before the assembly as a statement of resolve."],
	"remember_knowledge":["The keeping of memory","record","a18bad","A ceremonial record marks the knowledge entrusted to this place."],
	"welcome_strangers":["The open threshold","open_gate","83a9a0","The assembly marks a threshold through which strangers may be welcomed."],
	"master_craft":["The honour of the makers","tools","b3875f","The makers' tools are presented in honour of the hands behind the work."],
	"defy_gods":["The declaration of defiance","raised_flame","aa726c","The assembly hears the declaration for which this work was raised."],
	"mark_triumph":["The remembrance of triumph","laurel","a6a26b","A ceremonial wreath marks the triumph named in the work's purpose."],
	"give_thanks":["The giving of thanks","bough","84a36b","A bough is presented as the assembly gives thanks."],
}

static func describe(work:Dictionary)->Dictionary:
	var concept:Dictionary=work.get("concept",{}) if work.get("concept") is Dictionary else {}
	var id:=String(work.get("work_id",work.get("id",concept.get("id",""))))
	var parsed:=Concept.parse(id)
	var definition:=Catalog.get_definition(id)
	var legacy:=LEGACY.has(id)
	var form:=String(parsed.get("form",work.get("form",work.get("shape",definition.get("form","")))))
	var material:=String(parsed.get("material",work.get("material",concept.get("material","stone"))))
	var title:="Great work"
	var phases:Array=[]
	var emblem:=""
	var accent:=Color("a89671")
	var valid:=false
	if legacy:
		var entry:Array=LEGACY[id]
		form=entry[0];material=entry[1];title=entry[2];phases=(entry[3] as Array).duplicate();emblem=entry[4];accent=Color(entry[5]);valid=true
	elif not parsed.is_empty() and FORMS.has(form):
		var entry:Array=FORMS[form]
		title=entry[0];phases=(entry[1] as Array).duplicate();emblem=entry[2];accent=Color(entry[3]);valid=true
	var purpose:=String(parsed.get("purpose",definition.get("purpose",work.get("purpose",concept.get("purpose","")))))
	var purpose_data:Array=PURPOSES.get(purpose,["The dedication","offering","a89671","The assembly marks the dedication of the work."])
	var ambition:=String(parsed.get("ambition",definition.get("ambition",work.get("ambition","grand"))))
	if not SCALES.has(ambition):ambition="grand"
	var tier:=clampi(int(parsed.get("tier",definition.get("tier",0))),0,5)
	if valid and not legacy and form=="ring":
		if material=="timber":
			title="The circle of standing posts"
			phases[1]="Raising posts"
		if tier==0:phases[2]="Finishing the circle"
	return {"valid":valid,"id":id,"design_id":("legacy:"+id if legacy else "form:"+form) if valid else "",
		"legacy":legacy,"form":form,"material":material,"purpose":purpose,"ambition":ambition,"tier":tier,
		"seed":absi(id.hash()),"scale":float(SCALES[ambition]),"title":title,"construction_labels":phases,
		"emblem":emblem,"accent":accent,"tier_style":TIER_STYLES[tier],
		"purpose_title":String(purpose_data[0]),"purpose_emblem":String(purpose_data[1]),
		"purpose_accent":Color(purpose_data[2]),"purpose_words":String(purpose_data[3])}

static func catalog_ids()->Array[String]:
	var result:Array[String]=[]
	for form:String in FORMS:result.append("form:"+form)
	for id:String in LEGACY:result.append("legacy:"+id)
	return result
