extends "Panel.gd"

var GS_costs:Dictionary = {}
var costs:Dictionary = {}
var g_i:Dictionary
var tile_num:int
var bldg:String = ""
var surface:float

func _ready():
	set_polygon($Background.rect_size)

func refresh():
	g_i = game.galaxy_data[game.c_g]
	$ScrollContainer/VBoxContainer/TriangulumProbe.visible = game.science_unlocked.TPCC
	var planet_num:float = round(g_i.system_num * 4000 * pow(g_i.dark_matter, 1.1))
	#							 1.3 ~= E(X^2)/E(X)^2
	surface = round(planet_num * 1.3 * 4 * PI * pow((1000000 + 6000000 * 2.5) * g_i.dark_matter, 2))
	if bldg != "":
		update_info()

func update_info():
	var error:bool = false
	costs = Data.costs[bldg].duplicate(true)
	costs.stone = PI / 10.0
	costs.mythril = 1 / 10000000.0
	costs.erase("time")
	$Control/ProductionPerSec.visible = bldg != "TP"
	$Control/Production.visible = bldg != "TP"
	if bldg != "TP":
		for cost in costs:
			costs[cost] *= surface
	else:
		if g_i.system_num <= 9000:
			$Control/GalaxyInfo.text = tr("TP_ERROR")
			error = true
	if bldg == "ME":
		$Control/Costs.text = "%s (%s %s)" % [tr("COSTS"), Helper.format_num(surface), tr("ME_NAME_S").to_lower()]
		$Control/ProductionPerSec.text = "PRODUCTION_PER_SECOND"
		Helper.put_rsrc($Control/Production, 32, {"minerals":Data.path_1.ME.value * surface * Helper.get_IR_mult("ME")})
	elif bldg == "PP":
		$Control/Costs.text = "%s (%s %s)" % [tr("COSTS"), Helper.format_num(surface), tr("PP_NAME_S").to_lower()]
		$Control/ProductionPerSec.text = "PRODUCTION_PER_SECOND"
		Helper.put_rsrc($Control/Production, 32, {"energy":Data.path_1.PP.value * surface * Helper.get_IR_mult("PP")})
	elif bldg == "RL":
		$Control/Costs.text = "%s (%s %s)" % [tr("COSTS"), Helper.format_num(surface), tr("RL_NAME_S").to_lower()]
		$Control/ProductionPerSec.text = "PRODUCTION_PER_SECOND"
		Helper.put_rsrc($Control/Production, 32, {"SP":Data.path_1.RL.value * surface * Helper.get_IR_mult("RL")})
	elif bldg == "MS":
		$Control/Costs.text = "%s (%s %s)" % [tr("COSTS"), Helper.format_num(surface), tr("MS_NAME_S").to_lower()]
		$Control/ProductionPerSec.text = "STORAGE"
		Helper.put_rsrc($Control/Production, 32, {"minerals":Data.path_1.MS.value * surface * Helper.get_IR_mult("MS")})
	elif bldg == "GH":
		$Control/Costs.text = "%s (%s %s)" % [tr("COSTS"), Helper.format_num(surface), tr("GH_NAME_S").to_lower()]
		$Control/ProductionPerSec.text = ""
		Helper.put_rsrc($Control/Production, 32, {})
		costs.soil = 10 * surface
	$Control/Convert.visible = not error
	Helper.put_rsrc($Control/CostsHBox, 32, costs, true, true)
	$Control.visible = true

func _on_GS_pressed(extra_arg_0):
	bldg = extra_arg_0
	update_info()

func _on_Convert_pressed():
	pass
#	if game.check_enough(costs):
#		game.deduct_resources(costs)
#		game.toggle_panel(self)
#		game.popup(tr("CONVERT_SUCCESS"), 2.0)
#		game.switch_view("cluster")
#	else:
#		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)