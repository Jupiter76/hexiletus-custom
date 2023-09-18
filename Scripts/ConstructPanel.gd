extends Panel
signal hide_construct

@onready var game = get_node("/root/Game")
var basic_bldgs:Array = [Building.MINERAL_EXTRACTOR, Building.POWER_PLANT, Building.RESEARCH_LAB, Building.BORING_MACHINE, Building.SOLAR_PANEL, Building.ATMOSPHERE_EXTRACTOR]
var storage_bldgs:Array = [Building.MINERAL_SILO, Building.BATTERY]
var production_bldgs:Array = [Building.STONE_CRUSHER, Building.GLASS_FACTORY, Building.STEAM_ENGINE, Building.ATOM_MANIPULATOR, Building.SUBATOMIC_PARTICLE_REACTOR]
var support_bldgs:Array = [Building.GREENHOUSE, Building.CENTRAL_BUSINESS_DISTRICT]
var vehicles_bldgs:Array = [Building.ROVER_CONSTRUCTION_CENTER, Building.SHIPYARD, Building.PROBE_CONSTRUCTION_CENTER]

var tab = "basic"

func _ready():
	var added_buildings = Mods.added_buildings
	for key in added_buildings:
		match added_buildings[key].type:
			"basic":
				basic_bldgs.append(key)
			"storage":
				storage_bldgs.append(key)
			"production":
				production_bldgs.append(key)
			"support":
				support_bldgs.append(key)
			"vehicles":
				vehicles_bldgs.append(key)

func refresh():
	$VBoxContainer/Unique.visible = game.engineering_bonus.max_unique_building_tier > 0
	for btn in $ScrollContainer/VBoxContainer.get_children():
		if btn is Button:
			btn.queue_free()
	$ScrollContainer/VBoxContainer/HBoxContainer.visible = tab == "unique"
	if tab == "unique":
		var tier_arr:Array = tr("TIER_X").split(" ")
		if tier_arr[0] == "%s":
			$ScrollContainer/VBoxContainer/HBoxContainer/Label.move_to_front()
			$ScrollContainer/VBoxContainer/HBoxContainer/Label.text = tier_arr[1]
		else:
			$ScrollContainer/VBoxContainer/HBoxContainer/Tier.move_to_front()
			$ScrollContainer/VBoxContainer/HBoxContainer/Label.text = tier_arr[0]
		var selected_tier:int = $ScrollContainer/VBoxContainer/HBoxContainer/Tier.value
		for bldg in len(UniqueBuilding.names):
			if bldg in game.unique_bldgs_discovered.keys() and selected_tier in game.unique_bldgs_discovered[bldg].keys():
				var btn = Button.new()
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.expand_icon = true
				btn.icon = load("res://Graphics/Buildings/Unique/%s.png" % UniqueBuilding.names[bldg])
				btn.custom_minimum_size.y = 100
				$ScrollContainer/VBoxContainer.add_child(btn)
				btn.connect("mouse_entered", Callable(self, "on_unique_bldg_over").bind(bldg))
				btn.connect("mouse_exited", Callable(game, "hide_tooltip"))
				btn.connect("pressed", Callable(self, "on_unique_bldg_click").bind(bldg))
	else:
		for bldg in self["%s_bldgs" % tab]:
			if game.new_bldgs.has(bldg):
				var btn = Button.new()
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.expand_icon = true
				btn.icon = load("res://Graphics/Buildings/%s.png" % Building.names[bldg])
				btn.custom_minimum_size.y = 100
				$ScrollContainer/VBoxContainer.add_child(btn)
				btn.connect("mouse_entered", Callable(self, "on_bldg_over").bind(bldg))
				btn.connect("mouse_exited", Callable(game, "hide_tooltip"))
				btn.connect("pressed", Callable(self, "on_bldg_click").bind(bldg))

func on_bldg_click(bldg:int):
	emit_signal("hide_construct")
	game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
	var base_cost = Data.costs[bldg].duplicate(true)
	for cost in base_cost:
		base_cost[cost] *= game.engineering_bonus.BCM
	if bldg == Building.GREENHOUSE:
		base_cost.energy = round(base_cost.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
	game.view.obj.construct(bldg, base_cost)

func on_bldg_over(bldg:int):
	var time_speed = game.u_i.time_speed
	var txt:String = "[font_size=20]%s[/font_size]\n%s\n\n%s\n" % [tr("%s_NAME" % Building.names[bldg].to_upper()), tr("%s_DESC" % Building.names[bldg].to_upper()), tr("COSTS")]
	var costs = Data.costs[bldg].duplicate(true)
	for cost in costs:
		costs[cost] *= game.engineering_bonus.BCM
	if bldg == Building.GREENHOUSE:
		costs.energy = round(costs.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
	if costs.has("time"):
		if game.subject_levels.dimensional_power >= 1:
			costs.time = 0.2
		else:
			costs.time /= game.u_i.time_speed
	var icons = []
	for cost in costs.keys():
		txt += "@i  \t"
		if cost == "time":
			txt += Helper.time_to_str(costs[cost])
			icons.append(Data.time_icon)
		elif cost in game.mat_info.keys():
			txt += Helper.format_num(costs[cost]) + " kg"
			icons.append(load("res://Graphics/Materials/%s.png" % cost))
		elif cost in game.met_info.keys():
			txt += Helper.format_num(costs[cost]) + " kg"
			icons.append(load("res://Graphics/Metals/%s.png" % cost))
		else:
			txt += Helper.format_num(costs[cost])
			icons.append(Data["%s_icon" % cost])
		txt += "\n"
	txt += "\n"
	var IR_mult = Helper.get_IR_mult(bldg)
	if bldg == Building.SOLAR_PANEL:
		txt += (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_SP_production(game.planet_data[game.c_p].temperature, Data.path_1[bldg].value * IR_mult * time_speed), true)]
	elif bldg == Building.ATMOSPHERE_EXTRACTOR:
		txt += (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_AE_production(game.planet_data[game.c_p].pressure, Data.path_1[bldg].value * IR_mult * time_speed), true)]
	elif bldg == Building.BATTERY:
		txt += (Data.path_1[bldg].desc + "\n") % [Helper.format_num(round(Data.path_1[bldg].value * IR_mult * game.u_i.charge))]
	elif Data.path_1.has(bldg):
		txt += (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Data.path_1[bldg].value * IR_mult * time_speed, true)]
	if Data.path_2.has(bldg):
		if Data.path_2[bldg].has("is_value_integer"):
			txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(round(Data.path_2[bldg].value * IR_mult))]
		else:
			txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(Data.path_2[bldg].value * IR_mult, true)]
	if Data.path_3.has(bldg):
		if bldg == Building.CENTRAL_BUSINESS_DISTRICT:
			txt += Data.path_3[bldg].desc.format({"n":Data.path_3[bldg].value}) + "\n"
		else:
			txt += (Data.path_3[bldg].desc + "\n") % [Data.path_3[bldg].value]
	if Data.desc_icons.has(bldg):
		icons.append_array(Helper.flatten(Data.desc_icons[bldg]))
	game.show_adv_tooltip(txt, icons)


func _on_basic_mouse_entered():
	tween_label($VBoxContainer/Basic/Label, 1.0)


func _on_basic_mouse_exited():
	if tab != "basic":
		tween_label($VBoxContainer/Basic/Label, 0.0)


func _on_storage_mouse_entered():
	tween_label($VBoxContainer/Storage/Label, 1.0)


func _on_storage_mouse_exited():
	if tab != "storage":
		tween_label($VBoxContainer/Storage/Label, 0.0)


func _on_production_mouse_entered():
	tween_label($VBoxContainer/Production/Label, 1.0)


func _on_production_mouse_exited():
	if tab != "production":
		tween_label($VBoxContainer/Production/Label, 0.0)


func _on_support_mouse_entered():
	tween_label($VBoxContainer/Support/Label, 1.0)


func _on_support_mouse_exited():
	if tab != "support":
		tween_label($VBoxContainer/Support/Label, 0.0)


func _on_vehicles_mouse_entered():
	tween_label($VBoxContainer/Vehicles/Label, 1.0)


func _on_vehicles_mouse_exited():
	if tab != "vehicles":
		tween_label($VBoxContainer/Vehicles/Label, 0.0)


func _on_tab_pressed(extra_arg_0:String):
	tab = extra_arg_0.to_lower()
	for btn in $VBoxContainer.get_children():
		if btn.name != extra_arg_0:
			tween_label(btn.get_node("Label"), 0.0)
	refresh()

func tween_label(label, final_val):
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", final_val, 0.1)


func _on_unique_mouse_entered():
	tween_label($VBoxContainer/Unique/Label, 1.0)


func _on_unique_mouse_exited():
	if tab != "unique":
		tween_label($VBoxContainer/Unique/Label, 0.0)

func on_unique_bldg_over(bldg:int):
	pass

func on_unique_bldg_click(bldg:int):
	pass


func _on_tier_value_changed(value):
	refresh()
