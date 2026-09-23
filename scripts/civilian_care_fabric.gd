extends RefCounted
## Aggregate supportive-care accounting. These coefficients are game rules,
## not diagnoses or clinical predictions. Population changes belong to the owner.
const MAX_EPISODES:=32
const MAX_HISTORY:=30
const OBSERVATION_WORK:=0.5
const PULSE_WORK:=0.125
const CARE_WORK:=0.5
const RECORD_CLAY:=0.005
const CARE_WATER:=0.25
const CARE_CLOTH:=0.02
## Supplies for one supported case: water plus the raw materials and Civilian
## Goods of CARE_CLOTH woven cloth. Reports still count cloth-equivalents.
static var CLOTH_UNIT:=preload("res://scripts/goods_bills.gd").flatten({"Woven Cloth":CARE_CLOTH})
static var CARE_UNIT:=preload("res://scripts/bill_stock.gd").add_scaled({"Freshwater":CARE_WATER},CLOTH_UNIT,1.0)

static func empty_state()->Dictionary:
	return {"enabled":true,"staff_share":0.25,"episodes":[],"next_id":1,"last_day":-1,"history":[],"report":{}}

static func outstanding(data:Dictionary)->float:
	var total:=0.0
	for episode:Dictionary in data.episodes:total+=float(episode.remaining)
	return total

static func fit_population(data:Dictionary,population:float)->void:
	var total:=outstanding(data)
	if total<=maxf(0,population):return
	var ratio:=maxf(0,population)/maxf(total,.000001)
	for episode:Dictionary in data.episodes:
		episode.remaining=float(episode.remaining)*ratio
		episode.observed=float(episode.observed)*ratio
		episode.cared=float(episode.cared)*ratio

static func admit(data:Dictionary,population:float,amount:float,severity:float,day:int)->float:
	fit_population(data,population)
	var accepted:=minf(maxf(0,amount),maxf(0,population-outstanding(data)))
	if accepted<=.000001:return 0.0
	var episode:={"id":int(data.next_id),"onset_day":day,"remaining":accepted,"severity":clampf(severity,0,1),"observed":0.0,"observation_day":-1,"prior_observation_day":-1,"assessed_severity":0.0,"cared":0.0,"care_day":-1,"continuity":0.0}
	data.next_id=int(data.next_id)+1
	if data.episodes.size()>=MAX_EPISODES:
		# Create an unobserved merged aggregate; do not let new admissions inherit
		# somebody else's observation or nursing continuity.
		var tail:Dictionary=data.episodes.back()
		var merged:=float(tail.remaining)+accepted
		episode.remaining=merged
		episode.severity=(float(tail.remaining)*float(tail.severity)+accepted*float(episode.severity))/merged
		episode.onset_day=mini(day,int(tail.onset_day))
		data.episodes.pop_back()
	data.episodes.append(episode)
	return accepted

static func available(stock:Dictionary,item:String)->float:
	return maxf(0,float(stock.get(item,0)))

static func serve(data:Dictionary,stock:Dictionary,workers:float,methods:Dictionary,day:int)->Dictionary:
	if int(data.last_day)>=day:return data.report
	var work:=maxf(0,workers) if bool(data.enabled) else 0.0
	var report:={"day":day,"staff_available":work,"staff_used":0.0,"observed":0.0,"pulse_assessed":0.0,"supported":0.0,"additional_recovery":0.0,"water_used":0.0,"cloth_used":0.0,"record_clay_used":0.0,"unmet":0.0}
	var start_work:=work
	# Existing observations determine priority. Latent severity is not visible
	# to scheduling until a funded assessment has actually occurred.
	data.episodes.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if float(a.assessed_severity)==float(b.assessed_severity):return int(a.onset_day)<int(b.onset_day)
		return float(a.assessed_severity)>float(b.assessed_severity))
	for episode:Dictionary in data.episodes:
		var remaining:=float(episode.remaining)
		if int(episode.care_day)!=day-1:episode.continuity=0.0
		var old_observation:=int(episode.observation_day)
		var observed:=0.0
		if bool(methods.get("rounds",false)) and work>0:
			var pulse:=bool(methods.get("pulse",false))
			var unit_work:=OBSERVATION_WORK+(PULSE_WORK if pulse else 0.0)
			# Reserve half of available time for practical care when it is known.
			var observation_budget:=work*.5 if bool(methods.get("nursing",false)) else work
			observed=minf(remaining,minf(observation_budget/unit_work,available(stock,"Clay")/RECORD_CLAY))
			if observed>.000001:
				work-=observed*unit_work;stock.Clay=available(stock,"Clay")-observed*RECORD_CLAY
				episode.prior_observation_day=old_observation;episode.observation_day=day;episode.observed=observed
				episode.assessed_severity=float(episode.severity) if pulse else floorf(float(episode.severity)*2.0)/2.0
				report.observed+=observed;report.record_clay_used+=observed*RECORD_CLAY
				if pulse:report.pulse_assessed+=observed
		var treated:=0.0
		if bool(methods.get("nursing",false)) and int(episode.observation_day)==day:
			treated=minf(float(episode.observed),minf(work/CARE_WORK,preload("res://scripts/bill_stock.gd").affordable(stock,CARE_UNIT)))
			if treated>.000001:
				work-=treated*CARE_WORK
				preload("res://scripts/bill_stock.gd").pay(stock,preload("res://scripts/bill_stock.gd").scaled(CARE_UNIT,treated))
				var prior_fraction:=minf(treated,float(episode.cared))/maxf(.000001,remaining) if int(episode.care_day)==day-1 else 0.0
				episode.continuity=minf(1.0,float(episode.continuity)*prior_fraction+treated/maxf(.000001,remaining)*.25)
				episode.cared=treated;episode.care_day=day
				# Continued observation and care improve a bounded recoverable burden;
				# no observation alone, staffing alone or stock ownership grants recovery.
				var followed:=int(episode.prior_observation_day)>=0 and int(episode.prior_observation_day)==day-1
				var recovered:=minf(remaining,treated*(.03+(.03*float(episode.continuity) if followed else 0.0)))
				episode.remaining=maxf(0,remaining-recovered)
				episode.observed=minf(float(episode.observed),float(episode.remaining))
				episode.cared=minf(float(episode.cared),float(episode.remaining))
				report.supported+=treated;report.additional_recovery+=recovered
				report.water_used+=treated*CARE_WATER;report.cloth_used+=treated*CARE_CLOTH
		if treated<=.000001:episode.continuity=0.0;episode.cared=0.0
		report.unmet+=maxf(0,remaining-treated)
	data.episodes=data.episodes.filter(func(e:Dictionary)->bool:return float(e.remaining)>.000001)
	report.staff_used=start_work-work
	data.last_day=day;data.report=report
	data.history.append(report.duplicate(true))
	while data.history.size()>MAX_HISTORY:data.history.pop_front()
	return report
