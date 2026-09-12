extends RefCounted
## Optional consumable writing surfaces help comparison; no paper remains viable.
const PAPER_PER_WORK:=.01
const BONUS:=.2
const PRINTED_BONUS:=.3
static func use(work_available:float, remaining:float)->Dictionary:
	var base:=maxf(0.0,work_available)
	var need:=maxf(0.0,remaining)
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var printed:=minf(base,minf(maxf(0.0,float(stocks.get("Printed Sheets",0.0)))/PAPER_PER_WORK,need/(1.0+PRINTED_BONUS)))
	if printed>0.0:stocks["Printed Sheets"]=maxf(0.0,float(stocks["Printed Sheets"])-printed*PAPER_PER_WORK)
	base-=printed;need=maxf(0.0,need-printed*(1.0+PRINTED_BONUS))
	var supported:=minf(base,minf(maxf(0.0,float(stocks.get("Paper",0.0)))/PAPER_PER_WORK,need/(1.0+BONUS)))
	var extra:=supported*BONUS
	var spent:=minf(base,maxf(0.0,need-extra))
	if supported>0.0:stocks["Paper"]=maxf(0.0,float(stocks.Paper)-supported*PAPER_PER_WORK)
	return {"work":printed+spent,"progress":printed*(1.0+PRINTED_BONUS)+spent+extra,"paper":supported*PAPER_PER_WORK,"printed_sheets":printed*PAPER_PER_WORK}
