extends RefCounted
## Only physical communications examples benefit from this finite daily service.
const Ops=preload("res://scripts/technology_operations.gd")
const K=preload("res://scripts/communications_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const FAMILIES={
	"optical":["shutter_signal_frames","optical_telegraphy"],
	"electrical":["telegraph_keys","electromagnet_sounders","line_insulators","telegraph_return_circuits","electrical_telegraphy","polarized_telegraph_relays","duplex_telegraphy","punched_message_tape","teleprinter_mechanisms","automatic_telegraphy","acoustic_diaphragms","carbon_microphones","electromagnetic_earpieces","telephone_circuits","manual_switchboards","balanced_conductor_pairs","inductive_line_loading","telephone_repeaters"],
	"radio":["resonant_tuned_circuits","variable_air_capacitors","aerial_matching","crystal_radio_detection","tuned_radio_reception","vacuum_diodes","triode_valves","feedback_radio_oscillators","radio_telegraphy","amplitude_modulation","frequency_modulation","frequency_conversion","superheterodyne_reception"],
	"digital":["pulse_code_modulation","data_modems","packet_routers","store_forward_archives"]
}
static func family(item:Dictionary)->String:
	if not bool(item.get("reverse_engineered",false)):return ""
	var subject:=String(item.get("discovery_id",""))
	if String(I.product(String(item.get("specimen_item",""))).get("gate",""))!=subject:return ""
	for name:String in FAMILIES:
		if subject in FAMILIES[name]:return name
	return ""
static func eligible(item:Dictionary)->bool:return not family(item).is_empty()
static func use(item:Dictionary,progress:float,remaining:float)->float:
	var group:=family(item)
	if progress<=0 or group.is_empty():return 0.0
	var service:="analysis_"+group
	var extra:=minf(maxf(0,remaining-progress),minf(progress*.25,Ops.service(service)))
	if extra>0:Ops.data().services[service]-=extra
	return extra
