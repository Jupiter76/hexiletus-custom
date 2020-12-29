extends Node2D

onready var game = get_node("/root/Game")
onready var stars_info = game.system_data[game.c_s]["stars"]
onready var star_graphic = preload("res://Graphics/Stars/Star.png")
onready var view = get_parent()

var stars

const PLANET_SCALE_DIV = 6400000.0
const STAR_SCALE_DIV = 300.0/2.63
var glows = []

func _ready():
	#var combined_star_size = 0
	for i in range(0, stars_info.size()):
		var star_info = stars_info[i]
		var star = TextureButton.new()
		star.texture_normal = star_graphic
		self.add_child(star)
		star.rect_pivot_offset = Vector2(300, 300)
		#combined_star_size += star_info["size"]
		star.rect_scale.x = max(0.02, star_info["size"] / STAR_SCALE_DIV)
		star.rect_scale.y = max(0.02, star_info["size"] / STAR_SCALE_DIV)
		star.rect_position = star_info["pos"] - Vector2(300, 300)
		star.connect("mouse_entered", self, "on_star_over", [i])
		star.connect("mouse_exited", self, "on_btn_out")
		star.modulate = game.get_star_modulate(star_info["class"])
	
	var orbit_scene = preload("res://Scenes/Orbit.tscn")
	var planets_info = []
	for p_i in game.planet_data:
		var orbit = orbit_scene.instance()
		orbit.radius = p_i["distance"]
		self.add_child(orbit)
		var planet_btn = TextureButton.new()
		var planet_glow = TextureButton.new()
		var planet = Sprite.new()
		var planet_texture = load("res://Graphics/Planets/" + String(p_i["type"]) + ".png")
		var planet_glow_texture = preload("res://Graphics/Misc/Glow.png")
		planet_btn.texture_normal = planet_texture
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
		if p_i.conquered:
			planet_glow.modulate = Color(0, 1, 0, 1)
		else:
			planet_glow.modulate = Color(1, 0, 0, 1)
		planet.position.x = cos(p_i["angle"]) * p_i["distance"]
		planet.position.y = sin(p_i["angle"]) * p_i["distance"]
		glows.append(planet_glow)

var glow_over

func on_planet_over (id:int, l_id:int):
	show_planet_info(id, l_id)

func on_glow_planet_over (id:int, l_id:int, glow):
	glow_over = glow
	show_planet_info(id, l_id)

func show_planet_info(id:int, l_id:int):
	var p_i = game.planet_data[l_id]
	var wid:int = Helper.get_wid(p_i.size)
	if game.c_sc == game.ships_c_coords.sc and game.c_c == game.ships_c_coords.c and game.c_g == game.ships_c_coords.g and game.c_s == game.ships_c_coords.s and l_id == game.ships_c_coords.p and not p_i.conquered:
		game.show_tooltip(tr("CLICK_TO_BATTLE"))
	else:
		game.show_tooltip("%s\n%s: %s km (%sx%s)\n%s: %s AU\n%s: %s °C\n%s: %s bar\n%s" % [p_i.name, tr("DIAMETER"), round(p_i.size), wid, wid, tr("DISTANCE_FROM_STAR"), game.clever_round(p_i.distance / 569.25, 3), tr("SURFACE_TEMPERATURE"), game.clever_round(p_i.temperature - 273), tr("ATMOSPHERE_PRESSURE"), game.clever_round(p_i.pressure), tr("MORE_DETAILS")])

func on_planet_click (id:int, l_id:int):
	var p_i = game.planet_data[l_id]
	if not view.dragged:
		if Input.is_action_pressed("shift"):
			game.c_p = l_id
			game.c_p_g = id
			game.switch_view("planet_details")
		elif Input.is_action_pressed("Q") or p_i.conquered:
			game.c_p = l_id
			game.c_p_g = id
			game.switch_view("planet")
			p_i.conquered = true
			Helper.save_obj("Systems", game.c_s_g, game.planet_data)
		else:
			if game.c_sc == game.ships_c_coords.sc and game.c_c == game.ships_c_coords.c and game.c_g == game.ships_c_coords.g and game.c_s == game.ships_c_coords.s and l_id == game.ships_c_coords.p and not p_i.conquered:
				game.c_p = l_id
				game.c_p_g = id
				game.switch_view("battle")
			else:
				if len(game.ship_data) > 0:
					game.send_ships_panel.dest_p_id = l_id
					game.toggle_panel(game.send_ships_panel)
				else:
					game.long_popup(tr("NO_SHIPS_DESC"), tr("NO_SHIPS"))

func on_star_over (id:int):
	var star = stars_info[id]
	var tooltip = tr("STAR_TITLE").format({"type":tr(star.type.to_upper()).to_lower(), "class":star.class})
	tooltip += "\n%s\n%s\n%s\n%s" % [	tr("STAR_TEMPERATURE") % [star.temperature], 
										tr("STAR_SIZE") % [star.size],
										tr("STAR_MASS") % [star.mass],
										tr("STAR_LUMINOSITY") % [star.luminosity]]
	game.show_tooltip(tooltip)

func on_btn_out ():
	glow_over = null
	game.hide_tooltip()

func _process(_delta):
	for glow in glows:
		glow.modulate.a = clamp(0.6 / (view.scale.x * glow.rect_scale.x) - 0.1, 0, 1)
		if glow.modulate.a == 0 and glow.visible:
			if glow == glow_over:
				game.hide_tooltip()
			glow.visible = false
		if glow.modulate.a != 0:
			glow.visible = true

func _on_System_tree_exited():
	queue_free()
