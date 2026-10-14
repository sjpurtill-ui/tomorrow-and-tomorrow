extends GdUnitTestSuite
## ONE SCREEN PER CATEGORY (dock_panel.gd): the pages of a category stand as
## tabs in one row of its one screen. A tab of another page opens that page;
## a page alone keeps its own tabs.

const Dock:=preload("res://scripts/hud/dock_panel.gd")

class Page extends RefCounted:
	var title:="";var tabs:Array=[]
	var hidden:Array=[];var aliases:Dictionary={}
	func _init(name:String,names:Array)->void:
		title=name;tabs=names
	func meta()->Dictionary:return {"title":title,"subtabs":tabs,"hidden_subtabs":hidden,"subtab_aliases":aliases}
	func tab(_sub:int)->Dictionary:return {"blocks":[]}
	func signature()->Array:return [title]

func _dock()->Control:
	var dock:Control=auto_free(Dock.new());add_child(dock);dock.size=Vector2(900,700)
	return dock

func _shown(dock:Control)->Array:
	var out:Array=[]
	for button:Button in dock.tab_buttons:
		if button.visible:out.append(button.text)
	return out

func test_a_category_is_one_row_of_tabs_and_a_neighbours_tab_opens_its_page()->void:
	var town:=Page.new("Town",["Overview","History"])
	var people:=Page.new("People",["OVERVIEW"])
	var ways:=Page.new("Culture",["Culture","Council"])
	var dock:=_dock()
	var opened:Array=[]
	dock.siblings=[{"section":"settlement","provider":town,"labels":[]},{"section":"overview","provider":people,"labels":["People"]},{"section":"civ","provider":ways,"labels":[]}]
	dock.open_page=func(section:String,sub:int)->void:opened.append([section,sub])
	dock.present(town,1)
	assert_array(_shown(dock)).is_equal(["Overview","History","People","Culture","Council"])
	# The open page's own tab is the lit one.
	var lit:Array=dock._flat.filter(func(entry:Dictionary)->bool:return bool(entry.active))
	assert_int(lit.size()).is_equal(1)
	assert_str(String(lit[0].text)).is_equal("History")
	# Its own tab turns the page; a neighbour's asks the HUD for that page.
	dock._on_tab_pressed(0)
	assert_int(dock.sub).is_equal(0)
	assert_array(opened).is_empty()
	dock._on_tab_pressed(4)
	assert_array(opened).is_equal([["civ",1]])
	assert_object(dock.provider).is_same(town)

func test_a_page_alone_keeps_its_own_tabs()->void:
	var research:=Page.new("Research",["Where we look","Knowledge tree","What we know"])
	var dock:=_dock()
	dock.siblings=[{"section":"inquiry","provider":research,"labels":[]}]
	dock.present(research,2)
	assert_array(_shown(dock)).is_equal(["Where we look","Knowledge tree","What we know"])
	dock._on_tab_pressed(1)
	assert_int(dock.sub).is_equal(1)
	# A detail page that is no member of the category shows only its own.
	var detail:=Page.new("Health",["Health","Sickness"])
	dock.present(detail,0)
	assert_array(_shown(dock)).is_equal(["Health","Sickness"])

func test_merged_subpages_keep_legacy_links_and_neighbour_navigation()->void:
	var work:=Page.new("Production",["Daily work","Daily work","Workshop orders"])
	work.hidden=[1];work.aliases={1:0}
	var food:=Page.new("Food",["Food"])
	var dock:=_dock()
	dock.siblings=[{"section":"economy","provider":food},{"section":"production","provider":work}]
	dock.present(work,1)
	assert_int(dock.sub).is_equal(1)
	assert_array(_shown(dock)).is_equal(["Food","Daily work","Workshop orders"])
	var lit:Array=dock._flat.filter(func(entry:Dictionary)->bool:return bool(entry.active))
	assert_int(lit.size()).is_equal(1)
	assert_int(int(lit[0].sub)).is_equal(0)
	dock._on_tab_pressed(2)
	assert_int(dock.sub).is_equal(2)
	dock.present(work,0)
	dock.siblings=[]
	dock.rebuild()
	assert_array(_shown(dock)).is_equal(["Daily work","Workshop orders"])
