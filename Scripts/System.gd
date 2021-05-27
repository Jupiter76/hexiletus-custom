extends Node2D

onready var game = get_node("/root/Game")
onready var stars_info = game.system_data[game.c_s]["stars"]
onready var star_graphic = preload("res://Graphics/Stars/Star.png")
onready var view = get_parent()

#Used to prevent view from moving outside viewport
var dimensions:float

const PLANET_SCALE_DIV = 6400000.0 / 2.0
const STAR_SCALE_DIV = 300.0/2.63
var glows = []
var star_time_bars = []
var planet_time_bars = []
var planet_plant_bars = []
var star_rsrcs = []
var planet_rsrcs = []
var planet_hovered:int = -1

func _ready():
	refresh_planets()
	refresh_stars()
	if game.tutorial:
		if game.tutorial.tut_num == 27:
			game.tutorial.begin()
		elif game.tutorial.tut_num == 30 and len(game.ship_data) > 0:
			game.tutorial.begin()

func refresh_planets():
	for planet_thing in get_tree().get_nodes_in_group("planet_stuff"):
		planet_thing.remove_from_group("planet_stuff")
		remove_child(planet_thing)
		planet_thing.queue_free()
	glows.clear()
	for p_i in game.planet_data:
		var orbit = game.orbit_scene.instance()
		orbit.radius = p_i["distance"]
		self.add_child(orbit)
		orbit.add_to_group("planet_stuff")
		var planet_btn = TextureButton.new()
		var planet_glow = TextureButton.new()
		var planet = Sprite.new()
		var planet_glow_texture = preload("res://Graphics/Misc/Glow.png")
		planet_btn.texture_normal = game.planet_textures[p_i.type - 3]
		planet_glow.texture_normal = planet_glow_texture
		self.add_child(planet)
		planet.add_child(planet_glow)
		planet.add_child(planet_btn)
		planet_btn.connect("mouse_entered", self, "on_planet_over", [p_i.id, p_i.l_id])
		planet_glow.connect("mouse_entered", self, "on_glow_planet_over", [p_i.id, p_i.l_id, planet_glow])
		planet_btn.connect("mouse_exited", self, "on_btn_out")
		planet_glow.connect("mouse_exited", self, "on_btn_out")
		planet_btn.connect("pressed", self, "on_planet_click", [p_i["id"], p_i.l_id])
		planet_glow.connect("pressed", self, "on_planet_click", [p_i["id"], p_i.l_id])
		planet_btn.rect_position = Vector2(-320, -320)
		planet_btn.rect_pivot_offset = Vector2(320, 320)
		planet_btn.rect_scale.x = p_i["size"] / PLANET_SCALE_DIV
		planet_btn.rect_scale.y = p_i["size"] / PLANET_SCALE_DIV
		planet_glow.rect_pivot_offset = Vector2(100, 100)
		planet_glow.rect_position = Vector2(-100, -100)
		planet_glow.rect_scale *= p_i["distance"] / 1200.0
		if game.system_data[game.c_s].conquered:
			p_i.conquered = true
		if p_i.conquered:
			if p_i.has("bldg"):
				planet_glow.modulate = Color(0.2, 0.2, 1, 1)
			elif p_i.has("wormhole"):
				planet_glow.modulate = Color(0.74, 0.6, 0.78, 1)
			elif p_i.type in [11, 12]:
				planet_glow.modulate = Color.burlywood
			else:
				planet_glow.modulate = Color(0, 1, 0, 1)
		else:
			if p_i.type in [11, 12]:
				planet_glow.modulate = Color.burlywood
			else:
				planet_glow.modulate = Color(1, 0, 0, 1)
		var v:Vector2 = polar2cartesian(p_i.distance, p_i.angle)
		dimensions = p_i.distance
		if p_i.has("MS"):
			planet_glow.modulate = Color(0.6, 0.6, 0.6, 1)
			var MS = Sprite.new()
			MS.texture = load("res://Graphics/Megastructures/%s_%s.png" % [p_i.MS, p_i.MS_lv])
			MS.scale *= 0.2
			if p_i.MS == "M_SE":
				MS.position.x = -50 * cos(p_i.angle)
				MS.position.y = -50 * sin(p_i.angle)
				MS.rotation = p_i.angle + PI / 2
			elif p_i.MS == "M_MME":
				MS.scale *= 0.25
				add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.minerals_icon, p_i.l_id, false)
			planet.add_child(MS)
			if p_i.bldg.is_constructing:
				var time_bar = game.time_scene.instance()
				time_bar.rect_position = Vector2(0, -80)
				planet.add_child(time_bar)
				time_bar.modulate = Color(0, 0.74, 0, 1)
				planet_time_bars.append({"node":time_bar, "p_i":p_i, "parent":planet})
		if p_i.has("bldg") and p_i.bldg.has("name"):
			planet.add_child(Helper.add_lv_boxes(p_i, Vector2.ZERO))
			match p_i.bldg.name:
				"AE":
					add_rsrc(v, Color(0.89, 0.55, 1.0, 1), Data.rsrc_icons.AE, p_i.l_id, false)
				"MM":
					add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.rsrc_icons.MM, p_i.l_id, false)
			if p_i.has("plant") and p_i.plant.is_growing:
				var time_bar = game.time_scene.instance()
				time_bar.rect_position = Vector2(0, -80)
				planet.add_child(time_bar)
				time_bar.modulate = Color(105/255.0, 65/255.0, 40/255.0, 1)
				planet_plant_bars.append({"node":time_bar, "p_i":p_i, "parent":planet})
		planet.position = polar2cartesian(p_i.distance, p_i.angle)
		planet.add_to_group("planet_stuff")
		glows.append(planet_glow)
	
func refresh_stars():
	for star in get_tree().get_nodes_in_group("stars"):
		star.remove_from_group("stars")
		remove_child(star)
	for time_bar in star_time_bars:
		remove_child(time_bar.node)
	for rsrc in star_rsrcs:
		remove_child(rsrc.node)
	star_time_bars.clear()
	star_rsrcs.clear()
	#var combined_star_size = 0
	for i in range(0, stars_info.size()):
		var star_info = stars_info[i]
		var star = TextureButton.new()
		star.texture_normal = star_graphic
		self.add_child(star)
		star.rect_pivot_offset = Vector2(300, 300)
		#combined_star_size += star_info["size"]
		star.rect_scale.x = max(0.04, star_info["size"] / STAR_SCALE_DIV)
		star.rect_scale.y = max(0.04, star_info["size"] / STAR_SCALE_DIV)
		star.rect_position = star_info["pos"] - Vector2(300, 300)
		star.connect("mouse_entered", self, "on_star_over", [i])
		star.connect("mouse_exited", self, "on_btn_out")
		star.connect("pressed", self, "on_star_pressed", [i])
		star.modulate = Helper.get_star_modulate(star_info["class"])
		star.add_to_group("stars")
		if star_info.has("MS"):
			var MS = Sprite.new()
			MS.texture = load("res://Graphics/Megastructures/%s_%s.png" % [star_info.MS, star_info.MS_lv])
			MS.position = Vector2(300, 300)
			star.add_child(MS)
			if star_info.MS in ["M_DS", "M_MB"]:
				if star_info.MS == "M_DS":
					add_rsrc(star_info.pos, Color(0, 0.8, 0, 1), Data.energy_icon, i, true)
				elif star_info.MS == "M_MB":
					add_rsrc(star_info.pos, Color(0, 0.8, 0, 1), Data.SP_icon, i, true)
			if star_info.bldg.is_constructing:
				var time_bar = game.time_scene.instance()
				time_bar.rect_position = star_info["pos"] - Vector2(0, 80)
				add_child(time_bar)
				time_bar.modulate = Color(0, 0.74, 0, 1)
				star_time_bars.append({"node":time_bar, "id":i})

var glow_over

func on_planet_over (id:int, l_id:int):
	show_planet_info(id, l_id)

func on_glow_planet_over (id:int, l_id:int, glow):
	glow_over = glow
	show_planet_info(id, l_id)

func show_M_SE_costs(p_i:Dictionary):
	var vbox = game.get_node("UI/Panel/VBox")
	game.get_node("UI/Panel").visible = true
	bldg_costs = Data.MS_costs["M_SE_%s" % ((p_i.MS_lv + 1) if p_i.has("MS") else 0)].duplicate(true)
	for cost in bldg_costs:
		if cost != "energy":
			bldg_costs[cost] = round(bldg_costs[cost] * p_i.size / 12000.0)
		else:
			bldg_costs.energy = round(bldg_costs.energy * p_i.size / 48000.0 * pow(max(0.25, p_i.pressure), 1.1))
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)

func show_M_MME_costs(p_i:Dictionary):
	if p_i.type in [11, 12]:
		var vbox = game.get_node("UI/Panel/VBox")
		game.get_node("UI/Panel").visible = true
		bldg_costs = Data.MS_costs["M_MME_%s" % ((p_i.MS_lv + 1) if p_i.has("MS") else 0)].duplicate(true)
		for cost in bldg_costs:
			bldg_costs[cost] = round(bldg_costs[cost] * pow(p_i.size / 13000.0, 2))
		Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
		Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)
		Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
		Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_output(p_i, 1)}, false)

func show_M_MPCC_costs(p_i:Dictionary):
	var vbox = game.get_node("UI/Panel/VBox")
	game.get_node("UI/Panel").visible = true
	bldg_costs = Data.MS_costs.M_MPCC_0.duplicate(true)
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)

func show_planet_info(id:int, l_id:int):
	planet_hovered = l_id
	var p_i = game.planet_data[l_id]
	var wid:int = Helper.get_wid(p_i.size)
	var building:bool = game.bottom_info_action in ["building-M_SE", "building-M_MME", "building-M_MPCC"]
	var has_MS:bool = p_i.has("MS")
	var vbox = game.get_node("UI/Panel/VBox")
	if building:
		var MS:String = game.bottom_info_action.split("-")[1]
		call("show_%s_costs" % MS, p_i)
	elif has_MS:
		game.get_node("UI/Panel").visible = true
		Helper.put_rsrc(vbox, 32, {})
		var num_stages = 3
		if p_i.MS == "M_MPCC":
			num_stages = 0
		var stage:String = "%s (%s)" % [tr("%s_NAME" % p_i.MS), tr("STAGE_X_X") % [p_i.MS_lv, num_stages]]
		Helper.add_label(stage)
		if p_i.MS == "M_SE":
			Helper.add_label(tr("M_SE_%s_BENEFITS" % p_i.MS_lv), -1, false)
		elif p_i.MS == "M_MME":
			Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
			Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_output(p_i)}, false)
		if not p_i.bldg.is_constructing:
			if p_i.MS_lv < num_stages and game.science_unlocked["%s%s" % [p_i.MS.split("_")[1], (p_i.MS_lv + 1)]]:
				MS_constr_data.obj = p_i
				MS_constr_data.confirm = false
				Helper.add_label(tr("PRESS_F_TO_CONTINUE_CONSTR"))
	if Helper.ships_on_planet(l_id) and not p_i.conquered:
		game.show_tooltip(tr("CLICK_TO_BATTLE"))
	else:
		var tooltip:String
		if game.help.planet_details:
			game.help_str = "planet_details"
			tooltip = "%s\n%s: %s km (%sx%s)\n%s: %s AU\n%s: %s °C\n%s: %s bar\n%s" % [p_i.name, tr("DIAMETER"), round(p_i.size), wid, wid, tr("DISTANCE_FROM_STAR"), Helper.clever_round(p_i.distance / 569.25, 3), tr("SURFACE_TEMPERATURE"), Helper.clever_round(p_i.temperature - 273), tr("ATMOSPHERE_PRESSURE"), Helper.clever_round(p_i.pressure), tr("MORE_DETAILS")]
			if p_i.conquered:
				tooltip += "\n%s" % tr("CTRL_CLICK_TO_SEND_SHIPS")
				if p_i.has("bldg"):
					tooltip += "\n%s" % tr("PRESS_F_TO_UPGRADE")
			tooltip += "\n%s" % tr("HIDE_SHORTCUTS")
		else:
			tooltip = "%s\n%s: %s km (%sx%s)\n%s: %s AU\n%s: %s °C\n%s: %s bar" % [p_i.name, tr("DIAMETER"), round(p_i.size), wid, wid, tr("DISTANCE_FROM_STAR"), Helper.clever_round(p_i.distance / 569.25, 3), tr("SURFACE_TEMPERATURE"), Helper.clever_round(p_i.temperature - 273), tr("ATMOSPHERE_PRESSURE"), Helper.clever_round(p_i.pressure)]
		game.show_tooltip(tooltip)

var MS_constr_data:Dictionary = {}

func _input(event):
	if Input.is_action_just_released("F"):
		if not MS_constr_data.empty():
			if not MS_constr_data.confirm:
				var MS:String = MS_constr_data.obj.MS
				call("show_%s_costs" % MS, MS_constr_data.obj)
				MS_constr_data.confirm = true
				Helper.add_label(tr("F_TO_CONFIRM"))
			else:
				build_MS(MS_constr_data.obj, MS_constr_data.obj.MS)
		elif planet_hovered != -1 and game.planet_data[planet_hovered].has("bldg") and game.planet_data[planet_hovered].bldg.has("name"):
			game.add_upgrade_panel([], game.planet_data[planet_hovered])

func build_MS(obj:Dictionary, MS:String):
	var curr_time = OS.get_system_time_msecs()
	if game.check_enough(bldg_costs):
		game.deduct_resources(bldg_costs)
		if MS != "M_MB":
			if obj.has("MS"):
				obj.MS_lv += 1
			else:
				obj.MS_lv = 0
		else:
			game.energy += obj.bldg.stored
		obj.MS = MS
		game.system_data[game.c_s].has_MS = true
		obj.bldg = {}
		obj.bldg.is_constructing = true
		obj.bldg.construction_date = curr_time
		obj.bldg.construction_length = bldg_costs.time * 1000
		obj.bldg.XP = round(bldg_costs.money / 100.0)
		if MS in ["M_DS", "M_MME", "M_MB"]:
			obj.bldg.stored = 0
			obj.bldg.collect_date = obj.bldg.construction_date + obj.bldg.construction_length
		game.get_node("UI/Panel").visible = false
		MS_constr_data.clear()
		Helper.save_obj("Systems", game.c_s_g, game.planet_data)
		refresh_planets()
		refresh_stars()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func on_planet_click (id:int, l_id:int):
	if game.tutorial and game.tutorial.visible:
		return
	var p_i = game.planet_data[l_id]
	if not view.dragged:
		var building:bool = game.bottom_info_action in ["building-M_SE", "building-M_MME", "building-M_MPCC"]
		if building:
			if p_i.conquered:
				if not p_i.has("MS"):
					var MS:String = game.bottom_info_action.split("-")[1]
					if MS == "M_MME" and not p_i.type in [11, 12]:
						game.popup(tr("ONLY_GAS_GIANT"), 2.0)
					else:
						call("build_MS", p_i, MS)
				else:
					game.popup(tr("MS_ALREADY_PRESENT_PLANET"), 2.0)
			else:
				game.popup(tr("PLANET_MS_ERROR"), 2.5)
			return
		elif p_i.has("MS"):
			var t:String = game.item_to_use.type
			if t == "":
				if p_i.MS == "M_MME":
					var stored = p_i.bldg.stored
					var min_info:Dictionary = Helper.add_minerals(stored)
					p_i.bldg.stored = min_info.remainder
					game.HUD.refresh()
					return
				elif p_i.MS == "M_MPCC":
					game.PC_panel.id = id
					game.PC_panel.l_id = l_id
					game.PC_panel.probe_tier = 1
					game.toggle_panel(game.PC_panel)
					game.get_node("UI/Panel/VBox").visible = false
					game.hide_tooltip()
					return
			elif p_i.bldg.is_constructing:
				var curr_time = OS.get_system_time_msecs()
				var orig_num:int = game.item_to_use.num
				var speedup_time = game.speedups_info[game.item_to_use.name].time / 20.0
				var time_remaining = p_i.bldg.construction_date + p_i.bldg.construction_length - curr_time
				var num_needed = min(game.item_to_use.num, ceil((time_remaining) / float(speedup_time)))
				p_i.bldg.construction_date -= speedup_time * num_needed
				var time_sped_up = min(speedup_time * num_needed, time_remaining)
				if p_i.bldg.has("collect_date"):
					p_i.bldg.collect_date -= time_sped_up
				game.item_to_use.num -= num_needed
				game.remove_items(game.item_to_use.name, num_needed)
				game.update_item_cursor()
				return
		elif p_i.has("bldg"):
			if p_i.bldg.name == "GH":
				if p_i.has("plant"):
					if not p_i.plant.is_growing:
						items_collected.clear()
						var plant:String = Helper.get_plant_produce(p_i.plant.name)
						var produce:float = game.craft_agriculture_info[p_i.plant.name].produce * p_i.tile_num
						produce *= p_i.bldg.path_2_value
						game.show[plant] = true
						Helper.add_item_to_coll(items_collected, plant, produce)
						game.show_collect_info(items_collected)
						p_i.erase("plant")
					else:
						game.greenhouse_panel.tile_num = p_i.tile_num
						game.greenhouse_panel.p_i = p_i
						game.greenhouse_panel.fertilizer = true
						game.toggle_panel(game.greenhouse_panel)
				else:
					game.greenhouse_panel.tile_num = p_i.tile_num
					game.greenhouse_panel.p_i = p_i
					game.greenhouse_panel.fertilizer = false
					game.toggle_panel(game.greenhouse_panel)
			else:
				items_collected.clear()
				if p_i.bldg.name == "MM":
					Helper.collect_MM(p_i, p_i, items_collected, OS.get_system_time_msecs(), p_i.tile_num)
				elif p_i.bldg.name == "AE":
					Helper.collect_AE(p_i, p_i, items_collected, OS.get_system_time_msecs(), p_i.tile_num)
				game.show_collect_info(items_collected)
		if Input.is_action_pressed("shift"):
			game.c_p = l_id
			game.c_p_g = id
			game.switch_view("planet_details")
		elif (Input.is_action_pressed("Q") or p_i.conquered) and not Input.is_action_pressed("ctrl"):
			if not p_i.conquered:
				game.stats.planets_conquered += 1
				game.planet_data[l_id].conquered = true
				var all_conquered = true
				for planet in game.planet_data:
					if not planet.conquered:
						all_conquered = false
				if game.system_data[game.c_s].conquered != all_conquered:
					game.system_data[game.c_s].conquered = all_conquered
					Helper.save_obj("Galaxies", game.c_g_g, game.system_data)
			if not p_i.type in [11, 12]:
				if not p_i.has("bldg") or not p_i.bldg.has("name"):
					game.c_p = l_id
					game.c_p_g = id
					game.switch_view("planet")
					Helper.save_obj("Systems", game.c_s_g, game.planet_data)
			else:
				game.popup(tr("NO_ACTIVITY_ON_GAS_GIANT"), 2.0)
		else:
			if Helper.ships_on_planet(l_id) and not p_i.conquered:
				game.c_p = l_id
				game.c_p_g = id
				game.is_conquering_all = false
				game.switch_view("battle")
			else:
				if len(game.ship_data) > 0:
					if not p_i.conquered or Input.is_action_pressed("ctrl"):
						game.send_ships_panel.dest_p_id = l_id
						game.toggle_panel(game.send_ships_panel)
				else:
					game.long_popup(tr("NO_SHIPS_DESC"), tr("NO_SHIPS"))

var bldg_costs:Dictionary

func on_star_over (id:int):
	var star = stars_info[id]
	var star_type:String = star.type
	var star_tier:String = ""
	if star_type.substr(0, 11) == "hypergiant ":
		star_type = star_type.split(" ")[0]
		star_tier = " %s" % star.type.split(" ")[1]
	var tooltip = tr("STAR_TITLE").format({"type":"%s%s" % [tr(star_type.to_upper()), star_tier.to_upper()], "class":star.class})
	tooltip += "\n%s\n%s\n%s\n%s" % [	tr("STAR_TEMPERATURE") % [star.temperature], 
										tr("STAR_SIZE") % [star.size],
										tr("STAR_MASS") % [star.mass],
										tr("STAR_LUMINOSITY") % [Helper.e_notation(star.luminosity) if star.luminosity < 0.0001 else star.luminosity]]
	#var building:bool = game.bottom_info_action == "building_DS"
	var has_MS:bool = star.has("MS")
	var vbox = game.get_node("UI/Panel/VBox")
	if game.bottom_info_action == "building_DS":
		game.get_node("UI/Panel").visible = true
		bldg_costs = Data.MS_costs.M_DS_0.duplicate(true)
		for cost in bldg_costs:
			bldg_costs[cost] = round(bldg_costs[cost] * pow(star.size, 2))
		Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
		Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)
		Helper.add_label(tr("PRODUCTION_PER_SECOND"))
		Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_output(star)}, false)
	elif game.bottom_info_action == "building_MB":
		game.get_node("UI/Panel").visible = true
		bldg_costs = Data.MS_costs.M_MB.duplicate(true)
		for cost in bldg_costs:
			bldg_costs[cost] = round(bldg_costs[cost] * pow(star.size, 2))
		Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
		Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)
		Helper.add_label(tr("PRODUCTION_PER_SECOND"))
		Helper.put_rsrc(vbox, 32, {"SP":Helper.get_DS_output(star)}, false)
	elif game.bottom_info_action == "building_PK":
		game.get_node("UI/Panel").visible = true
		bldg_costs = Data.MS_costs.M_PK_0.duplicate(true)
		Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
		Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)
		Helper.add_label(tr("PK0_POWER"), -1, true, true)
	elif has_MS:
		game.get_node("UI/Panel").visible = true
		Helper.put_rsrc(vbox, 32, {})
		var num_stages = 4
		if star.MS == "M_PK":
			num_stages = 2
		var stage:String = "%s (%s)" % [tr("%s_NAME" % star.MS), tr("STAGE_X_X") % [star.MS_lv, num_stages]]
		Helper.add_label(stage)
		if star.MS == "M_DS":
			Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
			Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_output(star)}, false)
		elif star.MS == "M_MB":
			Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
			Helper.put_rsrc(vbox, 32, {"energy":Helper.get_MB_output(star)}, false)
		elif star.MS == "M_PK":
			Helper.add_label(tr("PK%s_POWER" % star.MS_lv), -1, true, true)
		if not star.bldg.is_constructing and star.MS_lv < num_stages:
			if star.MS == "M_DS" and game.science_unlocked["DS%s" % (star.MS_lv + 1)]:
				MS_constr_data.obj = star
				MS_constr_data.confirm = false
				Helper.add_label(tr("PRESS_F_TO_CONTINUE_CONSTR"))
			elif star.MS == "M_PK" and game.science_unlocked["PK%s" % (star.MS_lv + 1)]:
				MS_constr_data.obj = star
				MS_constr_data.confirm = false
				Helper.add_label(tr("PRESS_F_TO_CONTINUE_CONSTR"))
	game.show_tooltip(tooltip)

func on_star_pressed (id:int):
	var curr_time = OS.get_system_time_msecs()
	var star = stars_info[id]
	if game.bottom_info_action in ["building_DS", "building_PK"]:
		if game.system_data[game.c_s].conquered:
			if not star.has("MS"):
				if game.bottom_info_action == "building_DS":
					build_MS(star, "M_DS")
				elif game.bottom_info_action == "building_PK":
					build_MS(star, "M_PK")
			else:
				game.popup(tr("MS_ALREADY_PRESENT"), 2.0)
		else:
			game.popup(tr("STAR_MS_ERROR"), 3.0)
	elif game.bottom_info_action == "building_MB":
		if game.system_data[game.c_s].conquered:
			if not star.has("MS") or star.MS != "M_DS":
				game.popup(tr("MB_ERROR_1"), 3.0)
			else:
				if star.MS_lv == 4:
					build_MS(star, "M_MB")
				else:
					game.popup(tr("MB_ERROR_2"), 3.0)
		else:
			game.popup(tr("STAR_MS_ERROR"), 3.0)
	elif star.has("MS"):
		var t:String = game.item_to_use.type
		if t == "":
			if star.MS == "M_DS":
				game.energy += star.bldg.stored
				star.bldg.stored = 0
				game.HUD.refresh()
			elif star.MS == "M_MB":
				game.SP += star.bldg.stored
				star.bldg.stored = 0
				game.HUD.refresh()
			elif star.MS == "M_PK" and not star.bldg.is_constructing:
				game.planetkiller_panel.star = star.duplicate(true)
				game.toggle_panel(game.planetkiller_panel)
		elif star.bldg.is_constructing:
			var orig_num:int = game.item_to_use.num
			var speedup_time = game.speedups_info[game.item_to_use.name].time / 20.0
			var time_remaining = star.bldg.construction_date + star.bldg.construction_length - curr_time
			var num_needed = min(game.item_to_use.num, ceil((time_remaining) / float(speedup_time)))
			star.bldg.construction_date -= speedup_time * num_needed
			var time_sped_up = min(speedup_time * num_needed, time_remaining)
			if star.bldg.has("collect_date"):
				star.bldg.collect_date -= time_sped_up
			game.item_to_use.num -= num_needed
			game.remove_items(game.item_to_use.name, num_needed)
			game.update_item_cursor()
			return

func on_btn_out ():
	glow_over = null
	game.get_node("UI/Panel").visible = false
	game.hide_tooltip()
	MS_constr_data.clear()

func _process(_delta):
	for glow in glows:
		glow.modulate.a = clamp(0.6 / (view.scale.x * glow.rect_scale.x) - 0.1, 0, 1)
		if glow.modulate.a == 0 and glow.visible:
			if glow == glow_over:
				game.hide_tooltip()
			glow.visible = false
		if glow.modulate.a != 0:
			glow.visible = true
	var curr_time = OS.get_system_time_msecs()
	for time_bar_obj in star_time_bars:
		var time_bar = time_bar_obj.node
		var id = time_bar_obj.id
		var star = stars_info[id]
		var progress = (curr_time - star.bldg.construction_date) / float(star.bldg.construction_length)
		time_bar.get_node("TimeString").text = Helper.time_to_str(star.bldg.construction_length - curr_time + star.bldg.construction_date)
		time_bar.get_node("Bar").value = progress
		if progress > 1:
			if star.bldg.is_constructing:
				star.bldg.is_constructing = false
				game.xp += star.bldg.XP
				game.HUD.refresh()
			remove_child(time_bar)
			star_time_bars.erase(time_bar_obj)
	for time_bar_obj in planet_time_bars:
		var time_bar = time_bar_obj.node
		var p_i = time_bar_obj.p_i
		var progress = (curr_time - p_i.bldg.construction_date) / float(p_i.bldg.construction_length)
		time_bar.get_node("TimeString").text = Helper.time_to_str(p_i.bldg.construction_length - curr_time + p_i.bldg.construction_date)
		time_bar.get_node("Bar").value = progress
		if progress > 1:
			if p_i.bldg.is_constructing:
				p_i.bldg.is_constructing = false
				game.xp += p_i.bldg.XP
				game.HUD.refresh()
			time_bar_obj.parent.remove_child(time_bar)
			time_bar.queue_free()
			planet_time_bars.erase(time_bar_obj)
			Helper.save_obj("Systems", game.c_s_g, game.planet_data)
	for time_bar_obj in planet_plant_bars:
		var time_bar = time_bar_obj.node
		if not time_bar:
			continue
		var p_i = time_bar_obj.p_i
		var progress = (curr_time - p_i.plant.plant_date) / float(p_i.plant.grow_time)
		time_bar.get_node("TimeString").text = Helper.time_to_str(p_i.plant.grow_time - curr_time + p_i.plant.plant_date)
		time_bar.get_node("Bar").value = progress
		if progress > 1:
			if p_i.plant.is_growing:
				p_i.plant.is_growing = false
			time_bar_obj.parent.remove_child(time_bar)
			time_bar.queue_free()
			planet_plant_bars.erase(time_bar_obj)
	for rsrc_obj in star_rsrcs:
		var star = stars_info[rsrc_obj.id]
		if star.bldg.is_constructing:
			continue
		var value = Helper.update_MS_rsrc(star)
		var rsrc = rsrc_obj.node
		var current_bar = rsrc.get_node("Control/CurrentBar")
		current_bar.value = value
		rsrc.get_node("Control/Label").text = Helper.format_num(star.bldg.stored, 4)
	for rsrc_obj in planet_rsrcs:
		var planet = game.planet_data[rsrc_obj.id]
		if planet.bldg.is_constructing:
			continue
		var rsrc = rsrc_obj.node
		var current_bar = rsrc.get_node("Control/CurrentBar")
		var capacity_bar = rsrc.get_node("Control/CapacityBar")
		var value = Helper.update_MS_rsrc(planet)
		if not value:
			continue
		if planet.bldg.has("name") and planet.bldg.name == "MM":
			var cap = round(planet.bldg.path_2_value * planet.bldg.IR_mult)
			if planet.bldg.stored >= cap:
				current_bar.value = 0
				capacity_bar.value = 1
			else:
				current_bar.value = value
				capacity_bar.value = min(planet.bldg.stored / float(cap), 1)
			rsrc.get_node("Control/Label").text = "%s / %s m" % [planet.depth + planet.bldg.stored, planet.depth + cap]
		else:
			current_bar.value = value
			rsrc.get_node("Control/Label").text = Helper.format_num(planet.bldg.stored, 4)

func _on_System_tree_exited():
	queue_free()

func construct(_name:String):
	pass

func finish_construct():
	pass

func add_rsrc(v:Vector2, mod:Color, icon, id:int, is_star:bool):
	var rsrc = game.rsrc_stocked_scene.instance()
	add_child(rsrc)
	rsrc.get_node("TextureRect").texture = icon
	rsrc.rect_position = v + Vector2(0, 70)
	rsrc.get_node("Control").modulate = mod
	if is_star:
		star_rsrcs.append({"node":rsrc, "id":id})
	else:
		planet_rsrcs.append({"node":rsrc, "id":id})

var items_collected = {}

func collect_all():
	items_collected.clear()
	var planets = game.system_data[game.c_s].planets
	var progress:TextureProgress = game.HUD.get_node("Panel/CollectProgress")
	progress.max_value = len(planets)
	for star in game.system_data[game.c_s].stars:
		if star.has("MS"):
			if star.MS == "M_DS":
				Helper.update_MS_rsrc(star)
				Helper.add_item_to_coll(items_collected, "energy", star.bldg.stored)
				star.bldg.stored = 0
	for p_ids in planets:
		if game.c_v != "system":
			break
		var planet = game.planet_data[p_ids.local]
		if planet.has("MS"):
			if planet.MS == "M_MME":
				Helper.update_MS_rsrc(planet)
				var collect_data:Dictionary = Helper.add_minerals(planet.bldg.stored)
				Helper.add_item_to_coll(items_collected, "minerals", collect_data.added)
				planet.bldg.stored = collect_data.remainder
				continue
		elif planet.has("bldg"):
			if planet.bldg.name == "MM":
				Helper.collect_MM(planet, planet, items_collected, OS.get_system_time_msecs(), planet.tile_num)
			elif planet.bldg.name == "AE":
				Helper.collect_AE(planet, planet, items_collected, OS.get_system_time_msecs(), planet.tile_num)
		if not planet.discovered:
			progress.value += 1
			continue
		game.tile_data = game.open_obj("Planets", p_ids.global)
		var i:int
		for tile in game.tile_data:
			if tile:
				Helper.collect_rsrc(items_collected, planet, tile, i)
			i += 1
		Helper.save_obj("Planets", p_ids.global, game.tile_data)
		progress.value += 1
		if game.collect_speed_lag_ratio != 0:
			yield(get_tree().create_timer(0.01 * game.collect_speed_lag_ratio), "timeout")
	progress.visible = false
	game.show_collect_info(items_collected)
	game.HUD.refresh()
