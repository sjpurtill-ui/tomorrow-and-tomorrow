extends Node

var failures:Array[String]=[]

func _ready()->void:
	call_deferred("_run")

func _run()->void:
	_setup_capable_settlement()
	_test_benchmarks_require_real_capability()
	_test_ten_year_stability()
	_test_shortage_and_default_shock()
	_test_reserve_capped_monetary_shock()
	if not failures.is_empty():
		for failure in failures: push_error("Economy stress regression: "+failure)
		get_tree().quit(1)
		return
	print("ECONOMY_STRESS_PASS ",JSON.stringify({"day":GameState.elapsed_days,"metrics":GameState.economy_metrics,"ledger_entries":GameState.economic_ledger.size(),"history_days":GameState.economy_history.size()}))
	get_tree().quit(0)

func _setup_capable_settlement()->void:
	GameState.reset_for_new_world(771204)
	EconomySystem.reset_for_new_world()
	GameState.population_exact=120.0
	GameState.population_total=120
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle","Public Stores","Open Work Area"]
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true,"days":3.0}
	GameState.resource_stockpiles={"Food":4800.0,"Timber":260.0,"Stone":210.0,"Clay":80.0,"Fiber Plants":75.0,"Copper Ore":320.0,"Tin Ore":30.0,"Iron Ore":40.0}
	GameState.simulation_metrics={"food_days":40.0,"food_consumption":120.0,"food_intake_ratio":1.0,"logistics":0.48,"legitimacy":0.72,"food_production":130.0,"storage_function":0.62}
	GameState.society_capacities={"production":0.46,"institutions":0.48,"logistics":0.48}
	GameState.population_allocations["Administration"]=7
	GameState.material_metrics={"delivered_today":25.0,"lost_today":0.0}
	GameState.discovery_adoption["tallies"]=0.70
	GameState.discovery_adoption["standard_measures"]=0.70
	GameState.discovery_adoption["copper_smelting"]=0.0
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.initialize()
	if not CivilizationSystem.civilizations.is_empty():
		var civ:Dictionary=CivilizationSystem.civilizations[0]
		var relation:Dictionary=civ.get("player_relation",{})
		relation["contact_level"]=2
		relation["met_day"]=0
		relation["home_location_known"]=true
		relation["treaty"]="trade"
		relation["trade"]=100.0
		relation["at_war"]=false
		civ["player_relation"]=relation
		CivilizationSystem.civilizations[0]=civ

func _test_benchmarks_require_real_capability()->void:
	GameState.elapsed_days=1.0
	EconomySystem.process_day()
	_check(GameState.economy_stage==EconomySystem.STAGE_SUBSISTENCE,"ore alone bypassed the smelting gate")
	GameState.discovery_adoption["copper_smelting"]=0.30
	GameState.elapsed_days=2.0
	EconomySystem.process_day()
	_check(GameState.economy_stage==EconomySystem.STAGE_METAL,"capable settlement did not reach weighed-metal exchange")
	GameState.elapsed_days=3.0
	EconomySystem.process_day()
	_check(GameState.economy_stage==EconomySystem.STAGE_CURRENCY,"capable metal economy did not reach currency")

func _test_ten_year_stability()->void:
	GameState.resource_stockpiles["Fiber Plants"]=0.0
	for day in range(4,3654):
		GameState.elapsed_days=float(day)
		GameState.resource_stockpiles["Food"]=4800.0
		GameState.resource_stockpiles["Timber"]=260.0
		GameState.resource_stockpiles["Stone"]=210.0
		GameState.material_metrics["delivered_today"]=25.0
		GameState.material_metrics["lost_today"]=0.0
		EconomySystem.process_day()
	_check(is_equal_approx(GameState.private_currency+GameState.currency_hoards+GameState.public_treasury+GameState.mutual_aid_reserve,GameState.currency_supply),"currency was not conserved over ten years")
	_check(GameState.economy_history.size()==730,"bounded daily history did not retain exactly two years")
	_check(GameState.economic_ledger.size()<=1000,"economic ledger exceeded its retention bound")
	_check(GameState.credit_outstanding>0.0 and GameState.credit_outstanding<100.0,"healthy credit failed to reach a bounded stock")
	_check(GameState.credit_outstanding<=float(GameState.economy_metrics.credit_limit)+0.001,"private credit exceeded supportable capacity over ten years")
	_check(is_equal_approx(float(GameState.economy_metrics.liquid_money),GameState.private_currency),"long-run liquidity counted idle public or pooled currency as transactional")
	var liquidity:Dictionary=GameState.economy_metrics.currency_liquidity
	_check(is_equal_approx(float(liquidity.transactional_share)+float(liquidity.nontransactional_share),1.0),"long-run currency account shares stopped reconciling")
	_check(float(GameState.economy_metrics.tax_compliance)>=0.18 and float(GameState.economy_metrics.tax_compliance)<=0.98,"long-run levy compliance escaped its institutional bounds")
	_check(float(GameState.economy_metrics.effective_tax_rate)<=GameState.tax_rate+0.001,"long-run effective levy exceeded the statutory rate")
	_check(String(GameState.economy_metrics.public_spending_priority) in EconomySystem.PUBLIC_SPENDING_PRIORITIES,"long-run public spending priority became invalid")
	_check(float(GameState.economy_metrics.civil_payment_coverage)>=0.0 and float(GameState.economy_metrics.civil_payment_coverage)<=1.0 and float(GameState.economy_metrics.military_payment_coverage)>=0.0 and float(GameState.economy_metrics.military_payment_coverage)<=1.0,"long-run category payment coverage escaped its bounds")
	_check(float(GameState.economy_metrics.price_index)>0.35 and float(GameState.economy_metrics.price_index)<2.5,"stable price index escaped plausible bounds")
	_check(GameState.external_trade_exports>0.0 and GameState.external_trade_imports>0.0,"capable economy conducted no funded regional trade")
	_check(is_equal_approx(GameState.external_trade_credit,GameState.external_trade_exports-GameState.external_trade_imports-GameState.external_trade_losses),"regional trade account lost unrecorded value over ten years")
	_check(GameState.external_trade_credit<=float(GameState.economy_metrics.external_trade.claim_limit)+0.001,"regional export claims grew beyond counterpart capacity")

func _test_shortage_and_default_shock()->void:
	var food_price_before:=float(GameState.market_prices.Food)
	var default_before:=float(GameState.economy_metrics.default_rate)
	var pressure_before:=float(GameState.economy_metrics.social_pressure)
	GameState.resource_stockpiles["Food"]=5.0
	GameState.resource_stockpiles["Timber"]=0.0
	GameState.simulation_metrics["food_days"]=0.05
	GameState.simulation_metrics["legitimacy"]=0.30
	for day in range(3654,3834):
		GameState.elapsed_days=float(day)
		GameState.material_metrics["delivered_today"]=1.0
		GameState.material_metrics["lost_today"]=4.0
		EconomySystem.process_day()
	_check(float(GameState.market_prices.Food)>food_price_before*1.25,"severe food shortage did not raise its exchange value")
	_check(float(GameState.economy_metrics.default_rate)>default_before,"shortage and lost trust did not raise defaults")
	_check(float(GameState.economy_metrics.social_pressure)<pressure_before,"shortage did not worsen economic social pressure")

func _test_reserve_capped_monetary_shock()->void:
	GameState.resource_stockpiles["Food"]=4800.0
	GameState.resource_stockpiles["Timber"]=260.0
	GameState.simulation_metrics["food_days"]=40.0
	GameState.simulation_metrics["legitimacy"]=0.72
	GameState.material_metrics["delivered_today"]=0.0
	GameState.simulation_metrics["food_production"]=0.0
	for day in range(3834,4014):
		GameState.elapsed_days=float(day)
		EconomySystem.process_day()
	var price_before_issue:=float(GameState.market_prices.Food)
	var available_before:=EconomySystem._available_metal_value()
	var reserve_before:=EconomySystem._monetary_reserve_value()
	var commitment:=EconomySystem.commit_metal_to_reserve(100.0,"Stress reserve expansion")
	_check(float(commitment.accepted)>99.99,"available metal could not be committed for monetary backing")
	_check(EconomySystem._available_metal_value()<available_before,"reserve commitment left the same metal available to workshops")
	_check(EconomySystem._monetary_reserve_value()>reserve_before+99.99,"reserve commitment did not increase backing")
	var result:=EconomySystem.issue_currency(10000.0,"Stress issue")
	_check(float(result.accepted)<10000.0,"currency issue ignored reserve cap")
	_check(GameState.currency_supply<=EconomySystem._monetary_reserve_value()*2.5+0.001,"money supply exceeded its reserve ceiling")
	for day in range(4014,4194):
		GameState.elapsed_days=float(day)
		EconomySystem.process_day()
	_check(is_equal_approx(float(GameState.market_prices.Food),price_before_issue),"prices moved without a post-issue exchange observation")
	GameState.simulation_metrics["food_production"]=140.0
	GameState.elapsed_days=4194.0
	EconomySystem.process_day()
	_check(float(GameState.market_prices.Food)<price_before_issue*1.10,"unspent treasury issuance created implausible transaction-price inflation")
	_check(is_equal_approx(GameState.private_currency+GameState.currency_hoards+GameState.public_treasury+GameState.mutual_aid_reserve,GameState.currency_supply),"issuance broke account conservation")
	_check(bool(EconomySystem.accounting_audit().ok),"long-run economy failed its accounting audit")

func _check(condition:bool,message:String)->void:
	if not condition: failures.append(message)
