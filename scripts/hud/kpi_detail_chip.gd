extends Button
## A top-bar chip. Hovering it opens the shared hover card (hud/hover_card.gd)
## with a short glance from kpi_detail_data.gd; clicking opens its full view.
const Data=preload("res://scripts/hud/kpi_detail_data.gd")
var metric_id:String

func hover_spec()->Dictionary:
	return Data.card(metric_id)
