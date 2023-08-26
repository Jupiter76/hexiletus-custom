extends Node2D

@onready var game = get_node("/root/Game")

var dimensions:float

const DIST_MULT = 200.0
var obj_btns:Array = []
var overlays:Array = []
var rsrcs:Array = []
@onready var bldg_overlay_timer = $BuildingOverlayTimer
var discovered_gal:Array = []
var curr_bldg_overlay:int = 0

func _ready():
	rsrcs.resize(len(game.galaxy_data))
	var conquered = true
	for g_i in game.galaxy_data:
		if g_i.is_empty():
			continue
		conquered = conquered and g_i[11]
		var galaxy_btn = TextureButton.new()
		var galaxy = Sprite2D.new()
		galaxy_btn.texture_normal = game.galaxy_textures[g_i[9]]
		self.add_child(galaxy)
		galaxy.add_child(galaxy_btn)
		obj_btns.append(galaxy_btn)
		galaxy_btn.connect("mouse_entered",Callable(self,"on_galaxy_over").bind(g_i[1]))
		galaxy_btn.connect("mouse_exited",Callable(self,"on_galaxy_out"))
		galaxy_btn.connect("pressed",Callable(self,"on_galaxy_click").bind(g_i[0], g_i[1]))
		var radius = pow(g_i[6] / game.GALAXY_SCALE_DIV, 0.5)
		galaxy_btn.position = Vector2(-galaxy_btn.texture_normal.get_width(), -galaxy_btn.texture_normal.get_height()) / 2.0 * radius
		galaxy_btn.scale.x = radius
		galaxy_btn.scale.y = radius
		galaxy.rotation = g_i[12]
		galaxy_btn.modulate = g_i[15].get("modulate", Color.WHITE)
		galaxy.position = g_i[3]
		dimensions = max(dimensions, g_i[3].length())
		Helper.add_overlay(galaxy, self, "galaxy", g_i, overlays)
		if g_i[15].has("GS"):
			var GS_marker:Sprite2D = Sprite2D.new()
			GS_marker.scale *= 2.0
			GS_marker.texture = preload("res://Graphics/Effects/spotlight_8.png")
			galaxy.add_child(GS_marker)
			var rsrc
			var prod:float
			var rsrc_mult:float = 1.0
			match g_i[15].GS:
				"ME":
					rsrc_mult = Helper.get_IR_mult("ME") * game.u_i.time_speed
					rsrc = add_rsrc(g_i[3], Color(0, 0.5, 0.9, 1), Data.rsrc_icons.ME, g_i[1], radius * 10.0)
				"PP":
					rsrc_mult = Helper.get_IR_mult("PP") * game.u_i.time_speed
					rsrc = add_rsrc(g_i[3], Color(0, 0.8, 0, 1), Data.rsrc_icons.PP, g_i[1], radius * 10.0)
				"RL":
					rsrc_mult = Helper.get_IR_mult("RL") * game.u_i.time_speed
					rsrc = add_rsrc(g_i[3], Color(0, 0.8, 0, 1), Data.rsrc_icons.RL, g_i[1], radius * 10.0)
				_:
					rsrc = null
			if is_instance_valid(rsrc):
				rsrc.set_text("%s/%s" % [Helper.format_num(g_i[15].prod_num * rsrc_mult), tr("S_SECOND")])
		if g_i[10] and not g_i[15].has("GS"):
			discovered_gal.append(g_i)
	if conquered:
		game.u_i.cluster_data[game.c_c].conquered = true
	if game.overlay_data.cluster.visible:
		Helper.toggle_overlay(obj_btns, overlays, true)
	if len(discovered_gal) > 0:
		bldg_overlay_timer.start(0.05)

func on_bldg_overlay_timeout():
	var g_i = discovered_gal[curr_bldg_overlay]
	var bldgs:Dictionary = {}
	var MSs:Dictionary = {}
	var system_data2:Array = game.open_obj("Galaxies", g_i[0])
	for s_i in system_data2:
		if not s_i[10]:
			continue
		var planet_data2:Array = game.open_obj("Systems", s_i[0])
		for p_i in planet_data2:
			if p_i.is_empty():
				continue
			if p_i.has("tile_num") and p_i.bldg.has("name"):
				Helper.add_to_dict(bldgs, p_i.bldg.name, p_i.tile_num)
			if p_i.has("MS"):
				Helper.add_to_dict(MSs, p_i.MS, 1)
		for _star in s_i[9]:
			if _star[7].has("MS"):
				Helper.add_to_dict(MSs, _star[7].MS, 1)
		#await get_tree().process_frame
	var sc:float = pow(g_i[6] / game.GALAXY_SCALE_DIV, 0.5)
	if not bldgs.is_empty():
		var grid_panel = preload("res://Scenes/BuildingInfo.tscn").instantiate()
		grid_panel.get_node("Top").visible = false
		var grid = grid_panel.get_node("PanelContainer/GridContainer")
		grid_panel.scale *= 7.0
		for bldg in bldgs:
			var bldg_count = preload("res://Scenes/EntityCount.tscn").instantiate()
			grid.add_child(bldg_count)
			bldg_count.get_node("Texture2D").texture = game.bldg_textures[bldg]
			bldg_count.get_node("Texture2D").mouse_filter = Control.MOUSE_FILTER_IGNORE
			bldg_count.get_node("Label").text = "x %s" % Helper.format_num(bldgs[bldg])
		add_child(grid_panel)
		grid_panel.add_to_group("Grids")
		grid_panel.name = "Grid_%s" % g_i[1]
		grid_panel.position.x = g_i[3].x - grid.size.x / 2.0 * grid_panel.scale.x
		grid_panel.position.y = g_i[3].y - grid_panel.size.y * grid_panel.scale.y - 170 * sc
	if not MSs.is_empty():
		var MS_grid_panel = preload("res://Scenes/BuildingInfo.tscn").instantiate()
		MS_grid_panel.get_node("Bottom").visible = false
		var MS_grid = MS_grid_panel.get_node("PanelContainer/GridContainer")
		MS_grid_panel.scale *= 7.0
		for MS in MSs:
			var MS_count = preload("res://Scenes/EntityCount.tscn").instantiate()
			MS_grid.add_child(MS_count)
			MS_count.get_node("Texture2D").texture = load("res://Graphics/Megastructures/%s_0.png" % MS)
			MS_count.get_node("Label").text = "x %s" % Helper.format_num(MSs[MS])
		add_child(MS_grid_panel)
		MS_grid_panel.add_to_group("MSGrids")
		MS_grid_panel.name = "MSGrid_%s" % g_i[1]
		MS_grid_panel.position.x = g_i[3].x - MS_grid.size.x / 2.0 * MS_grid_panel.scale.x
		MS_grid_panel.position.y = g_i[3].y + 170 * sc
	curr_bldg_overlay += 1
	if curr_bldg_overlay >= len(discovered_gal):
		bldg_overlay_timer.stop()

func add_rsrc(v:Vector2, mod:Color, icon, id:int, sc:float = 1):
	var rsrc:ResourceStored = game.rsrc_stored_scene.instantiate()
	add_child(rsrc)
	rsrc.set_current_bar_visibility(false)
	rsrc.set_icon_texture(icon)
	rsrc.scale *= 5.0
	rsrc.position = v + Vector2(0, 70 * 5.0)
	rsrc.set_panel_modulate(mod)
	rsrcs[id] = rsrc
	return rsrc

func e(n, e):
	return n * pow(10, e)

func on_galaxy_over (id:int):
	var g_i = game.galaxy_data[id]
	var tooltip:String = g_i[2] if g_i[2] != null else ("%s %s" % [tr("GALAXY"), id])
	var icons = []
	if g_i[15].has("GS"):
		tooltip += "\n"
		var GS = g_i[15].GS
		if GS == "MS":
			icons = [Data.minerals_icon]
			tooltip += Data.path_1.MS.desc % Helper.format_num(g_i[15].prod_num * Helper.get_IR_mult("MS"))
		elif GS == "B":
			icons = [Data.energy_icon]
			tooltip += Data.path_1.B.desc % Helper.format_num(g_i[15].prod_num * Helper.get_IR_mult("B"))
		elif GS == "ME":
			icons = [Data.minerals_icon]
			tooltip += Data.path_1.RL.desc % Helper.format_num(g_i[15].prod_num * Helper.get_IR_mult("ME") * game.u_i.time_speed)
		elif GS == "PP":
			icons = [Data.energy_icon]
			tooltip += Data.path_1.PP.desc % Helper.format_num(g_i[15].prod_num * Helper.get_IR_mult("PP") * game.u_i.time_speed)
		elif GS == "RL":
			icons = [Data.SP_icon]
			tooltip += Data.path_1.RL.desc % Helper.format_num(g_i[15].prod_num * Helper.get_IR_mult("RL") * game.u_i.time_speed)
	else:
		tooltip += "\n%s: %s\n%s: %s\n%s: %s nT\n%s: %s" % [tr("SYSTEMS"), g_i[6], tr("DIFFICULTY"), g_i[4], tr("B_STRENGTH"), g_i[13] * e(1, 9), tr("DARK_MATTER"), g_i[14]]
	for grid in get_tree().get_nodes_in_group("Grids"):
		if grid.name != "Grid_%s" % g_i[1]:
			var tween = create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
			#grid.visible = false
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		if grid.name != "MSGrid_%s" % g_i[1]:
			var tween = create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
			#grid.visible = false
	game.show_adv_tooltip(tooltip, icons)

func on_galaxy_out ():
	for grid in get_tree().get_nodes_in_group("Grids"):
		#grid.visible = true
		var tween = create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		#grid.visible = true
		var tween = create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	game.hide_tooltip()

func on_galaxy_click (id:int, l_id:int):
	var g_i:Array = game.galaxy_data[l_id]
	var view = self.get_parent()
	if not view.dragged:
		if game.bottom_info_action == "convert_to_GS":
			if id == 0:
				game.popup(tr("GS_ERROR"), 1.5)
			elif not g_i[11]:
				game.popup(tr("NO_GS"), 2.0)
			elif not g_i[15].has("GS"):
				game._on_BottomInfo_close_button_pressed()
				game.gigastructures_panel.g_i = game.galaxy_data[l_id]
				game.gigastructures_panel.galaxy_id_g = id
				game.toggle_panel(game.gigastructures_panel)
		else:
			if not g_i[10] and g_i[6] > 9000:
				game.show_YN_panel("op_galaxy", tr("OP_GALAXY_DESC"), [l_id, id], tr("OP_GALAXY"))
			else:
				game.switch_view("galaxy", {"fn":"set_custom_coords", "fn_args":[["c_g", "c_g_g"], [l_id, id]]})
	view.dragged = false

func change_overlay(overlay_id:int, gradient:Gradient):
	var c_vl = game.overlay_data.cluster.custom_values[overlay_id]
	match overlay_id:
		0:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id][6])
				Helper.set_overlay_visibility(gradient, overlay, offset)
		1:
			for overlay in overlays:
				if game.galaxy_data[overlay.id][10]:
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)
		2:
			for overlay in overlays:
				if game.galaxy_data[overlay.id][15].has("explored"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)
		3:
			for overlay in overlays:
				if game.galaxy_data[overlay.id][11]:
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)
		4:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id][4])
				Helper.set_overlay_visibility(gradient, overlay, offset)
		5:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id][13] * e(1, 9))
				Helper.set_overlay_visibility(gradient, overlay, offset)
		6:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id][14])
				Helper.set_overlay_visibility(gradient, overlay, offset)
		7:
			for overlay in overlays:
				if game.galaxy_data[overlay.id][15].has("GS"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)


func _on_Galaxy_tree_exited():
	queue_free()
