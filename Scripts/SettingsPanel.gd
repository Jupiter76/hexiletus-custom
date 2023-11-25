extends "Panel.gd"

"""
audio sliders are set to each bus
(you can find the buses by looking at the bottom of the screen and clicking Audio)
"""
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")
func _ready():
	set_polygon(size)
	var current_viewport = get_viewport().size
	$TabContainer/GRAPHICS/DisplayRes.add_item("Auto", 0)
	if DisplayServer.screen_get_size().y > 1440:
		$TabContainer/GRAPHICS/DisplayRes.add_item("3840 x 2160", 1)
	if DisplayServer.screen_get_size().y > 1080:
		$TabContainer/GRAPHICS/DisplayRes.add_item("2560 x 1440", 2)
	$TabContainer/GRAPHICS/DisplayRes.add_item("1920 x 1080", 3)
	$TabContainer/GRAPHICS/DisplayRes.add_item("1280 x 720", 4)
	$TabContainer/GRAPHICS/DisplayRes.add_item("853 x 480", 5)
	$TabContainer/GRAPHICS/DisplayRes.add_item("640 x 360", 6)
	$TabContainer/GRAPHICS/DisplayRes.add_item("427 x 240", 7)
	$TabContainer/GRAPHICS/DisplayRes.add_item("256 x 144", 8)
	$TabContainer/GRAPHICS/DisplayRes.add_item("128 x 72", 9)
	$TabContainer/GRAPHICS/DisplayRes.add_item("64 x 36", 10)
	$TabContainer/GRAPHICS/DisplayRes.add_item("32 x 18", 11)
	$TabContainer/GRAPHICS/DisplayRes.add_item("16 x 9", 12)
	if err == OK:
		set_difficulty()
		$TabContainer/SFX/Master.value = config.get_value("audio", "master", 0)
		update_volumes(0, config.get_value("audio", "master", 0))
		$TabContainer/SFX/Music.value = config.get_value("audio", "music", 0)
		update_volumes(1, config.get_value("audio", "music", 0))
		$TabContainer/SFX/SFX.value = config.get_value("audio", "SFX", 0)
		update_volumes(2, config.get_value("audio", "SFX", 0))
		$TabContainer/SFX/MusicPitch.button_pressed = config.get_value("audio", "pitch_affected", true)
		$TabContainer/GRAPHICS/Vsync.button_pressed = config.get_value("graphics", "vsync", true)
		$TabContainer/GRAPHICS/AutosaveLight.button_pressed = config.get_value("saving", "autosave_light", true)
		$TabContainer/GRAPHICS/EnableShaders.button_pressed = config.get_value("graphics", "enable_shaders", true)
		$TabContainer/GRAPHICS/Screenshake.button_pressed = config.get_value("graphics", "screen_shake", true)
		$TabContainer/GAME/EnableAutosave.button_pressed = config.get_value("saving", "enable_autosave", true)
		$TabContainer/GAME/AutosellMinerals.button_pressed = config.get_value("game", "autosell", true)
		$TabContainer/GAME/CaveGenInfo.button_pressed = config.get_value("game", "cave_gen_info", false)
		var autosave_interval = config.get_value("saving", "autosave", 10)
		var max_fps = config.get_value("rendering", "max_fps", 60)
		$TabContainer/GRAPHICS/Fullscreen.button_pressed = ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))
		$TabContainer/GAME/Autosave.value = autosave_interval
		$TabContainer/GAME/AutoSwitch.button_pressed = config.get_value("game", "auto_switch_buy_sell", false)
		$TabContainer/GRAPHICS/FPS/FPS.value = max_fps
		$TabContainer/MISC/OPCursor.button_pressed = config.get_value("misc", "op_cursor", false)
		$TabContainer/MISC/Discord.button_pressed = config.get_value("misc", "discord", true)
		set_notation()

func _on_Main_audio_value_changed(value):
	update_volumes(0, value)
	if err == OK:
		config.set_value("audio", "master", value)
		config.save("user://settings.cfg")

func _on_Music_value_changed(value):
	update_volumes(1, value)
	if err == OK:
		config.set_value("audio", "music", value)
		config.save("user://settings.cfg")

func _on_Sound_Effects_value_changed(value):
	update_volumes(2, value)
	if err == OK:
		config.set_value("audio", "SFX", value)
		config.save("user://settings.cfg")

func update_volumes(bus:int, value:float):
	AudioServer.set_bus_volume_db(bus, value)
	AudioServer.set_bus_mute(bus,value <= -40)

func refresh():
	if game.c_v == "STM":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		game.STM.show_help("")
		game.STM.set_process(false)
	if game.c_v != "" and game.science_unlocked.has("ASM"):
		$TabContainer/GAME/AutosellMinerals.disabled = false
		$TabContainer/GAME/AutosellMineralsLabel.modulate = Color.WHITE
	else:
		$TabContainer/GAME/AutosellMinerals.disabled = true
		$TabContainer/GAME/AutosellMineralsLabel.modulate = Color(0.5, 0.5, 0.5, 1.0)
	$TabContainer/GRAPHICS/Fullscreen.text = "%s (F11)" % [tr("FULLSCREEN")]
	$TabContainer/SFX/MusicPitchLabel.text = "%s  [img]Graphics/Icons/help.png[/img]" % tr("TIME_SPEED_AFFECTS_PITCH")
	set_difficulty()

func _on_Vsync_toggled(button_pressed):
	if err == OK:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if (button_pressed) else DisplayServer.VSYNC_DISABLED)
		config.set_value("graphics", "vsync", button_pressed)
		config.save("user://settings.cfg")


func _on_Autosave_value_changed(value):
	if err == OK:
		$TabContainer/GAME/Label3.text = "%s %s" % [value, tr("S_SECOND")]
		Settings.autosave_interval = value
		config.set_value("saving", "autosave", value)
		config.save("user://settings.cfg")
		if game.c_v != "":
			game.get_node("Autosave").stop()
			game.get_node("Autosave").wait_time = value
			game.get_node("Autosave").start()


func _on_AutosaveLight_toggled(button_pressed):
	if err == OK:
		config.set_value("saving", "autosave_light", button_pressed)
		config.save("user://settings.cfg")
		if game.HUD:
			game.HUD.refresh()


func _on_EnableAutosave_toggled(button_pressed):
	if err == OK:
		config.set_value("saving", "enable_autosave", button_pressed)
		config.save("user://settings.cfg")
		if game.HUD:
			game.HUD.refresh()

func _on_FPS_value_changed(value):
	if err == OK:
		$TabContainer/GRAPHICS/FPS/Label2.text = str(value)
		Engine.max_fps = value
		Settings.max_fps = value
		config.set_value("rendering", "max_fps", value)
		config.save("user://settings.cfg")


func _on_AutosellMinerals_mouse_entered():
	game.show_tooltip(tr("AUTOSELL_MINERALS_DESC"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_AutosellMinerals_toggled(button_pressed):
	if err == OK:
		config.set_value("game", "autosell", button_pressed)
		Settings.autosell = button_pressed
		config.save("user://settings.cfg")

func _on_Easy_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1])


func _on_Normal_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1.25])


func _on_Hard_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1.5])


func set_difficulty():
	$TabContainer/GAME/HBoxContainer/Easy.button_pressed = false
	$TabContainer/GAME/HBoxContainer/Normal.button_pressed = false
	$TabContainer/GAME/HBoxContainer/Hard.button_pressed = false
	if err == OK:
		var diff = config.get_value("game", "e_diff", 1)
		if diff == 0:
			$TabContainer/GAME/HBoxContainer/Easy.button_pressed = true
		elif diff == 1:
			$TabContainer/GAME/HBoxContainer/Normal.button_pressed = true
		else:
			$TabContainer/GAME/HBoxContainer/Hard.button_pressed = true

func _on_Easy_pressed():
	if err == OK:
		config.set_value("game", "e_diff", 0)
		config.save("user://settings.cfg")
		set_difficulty()

func _on_Normal_pressed():
	if err == OK:
		config.set_value("game", "e_diff", 1)
		config.save("user://settings.cfg")
		set_difficulty()

func _on_Hard_pressed():
	if err == OK:
		config.set_value("game", "e_diff", 2)
		config.save("user://settings.cfg")
		set_difficulty()

func _on_Fullscreen_toggled(button_pressed):
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (button_pressed) else Window.MODE_WINDOWED


func _on_Standard_pressed():
	if err == OK:
		config.set_value("game", "notation", "standard")
		config.save("user://settings.cfg")
		set_notation()

func _on_Standard_mouse_entered():
	game.show_tooltip("k < M < B < T < q < Q < s < S < O < N")


func _on_SI_pressed():
	if err == OK:
		config.set_value("game", "notation", "SI")
		config.save("user://settings.cfg")
		set_notation()

func _on_SI_mouse_entered():
	game.show_tooltip("k < M < G < T < P < E < Z < Y < R < Q")

func set_notation():
	$TabContainer/MISC/HBoxContainer2/Standard.button_pressed = false
	$TabContainer/MISC/HBoxContainer2/SI.button_pressed = false
	$TabContainer/MISC/HBoxContainer2/Scientific.button_pressed = false
	if err == OK:
		var notation = config.get_value("game", "notation", "SI")
		if notation == "standard":
			$TabContainer/MISC/HBoxContainer2/Standard.button_pressed = true
			Helper.notation = 0
		elif notation == "SI":
			$TabContainer/MISC/HBoxContainer2/SI.button_pressed = true
			Helper.notation = 1
		else:
			$TabContainer/MISC/HBoxContainer2/Scientific.button_pressed = true
			Helper.notation = 2
	if is_instance_valid(game.HUD):
		game.HUD.refresh()


func _on_Scientific_pressed():
	if err == OK:
		config.set_value("game", "notation", "scientific")
		config.save("user://settings.cfg")
		set_notation()


func _on_MusicPitch_mouse_entered():
	game.show_tooltip(tr("TIME_SPEED_AFFECTS_PITCH_DESC"))


func _on_MusicPitch_toggled(button_pressed):
	if err == OK:
		Settings.pitch_affected = button_pressed
		if button_pressed and game.u_i:
			if game.c_v == "cave":
				if game.subject_levels.dimensional_power >= 4:
					game.music_player.pitch_scale = log(game.u_i.time_speed * game.tile_data[game.c_t].get("time_speed_bonus", 1.0) - 1.0 + exp(1.0))
				else:
					game.music_player.pitch_scale = game.u_i.time_speed
			elif game.c_v == "mining":
				if button_pressed and game.tile_data[game.c_t].has("time_speed_bonus"):
					game.pitch_increased_mining = true
				game.music_player.pitch_scale = game.u_i.time_speed * game.tile_data[game.c_t].get("time_speed_bonus", 1.0)
			elif game.c_v == "battle" and game.subject_levels.dimensional_power >= 4:
				game.music_player.pitch_scale = log(game.u_i.time_speed - 1.0 + exp(1.0))
			else:
				game.music_player.pitch_scale = game.u_i.time_speed
		else:
			game.music_player.pitch_scale = 1.0
		config.set_value("audio", "pitch_affected", button_pressed)
		config.save("user://settings.cfg")


func _on_EnableShaders_mouse_entered():
	game.show_tooltip(tr("ENABLE_SHADERS_DESC"))


func _on_EnableShaders_toggled(button_pressed):
	if err == OK:
		Settings.enable_shaders = button_pressed
		game.get_node("ClusterBG").visible = button_pressed
		game.get_node("Starfield").visible = button_pressed
		game.get_node("Starfield2").visible = button_pressed
		config.set_value("graphics", "enable_shaders", button_pressed)
		config.save("user://settings.cfg")


func _on_ResetTooltips_pressed():
	game.help = Data.default_help.duplicate()


func _on_Screenshake_toggled(button_pressed):
	if err == OK:
		Settings.screen_shake = button_pressed
		config.set_value("graphics", "screen_shake", button_pressed)
		config.save("user://settings.cfg")


func _on_CaveGenInfo_toggled(button_pressed):
	if err == OK:
		Settings.cave_gen_info = button_pressed
		config.set_value("game", "cave_gen_info", button_pressed)
		config.save("user://settings.cfg")

func _on_OPCursor_toggled(button_pressed):
	Settings.op_cursor = button_pressed
	if err == OK:
		config.set_value("misc", "op_cursor", button_pressed)
		config.save("user://settings.cfg")
	if button_pressed:
		Input.set_custom_mouse_cursor(preload("res://Cursor.png"))
	else:
		Input.set_custom_mouse_cursor(null)


func _on_OPCursor_mouse_entered():
	game.show_tooltip("it's pretty op")


func _on_OPCursor_mouse_exited():
	if Settings.op_cursor:
		game.show_tooltip(":)")
	else:
		game.show_tooltip(":(")
	await get_tree().create_timer(0.5).timeout
	game.hide_tooltip()


func _on_DisplayRes_item_selected(index):
	var id:int = $TabContainer/GRAPHICS/DisplayRes.get_item_id(index)
	Helper.set_resolution(id)
#	if not $TabContainer/GRAPHICS/KeepWindowSize.button_pressed and id != 0 and id < 9:
#		get_window().size = get_viewport().size


func _on_discord_toggled(button_pressed):
	if err == OK:
		config.set_value("misc", "discord", button_pressed)
		config.save("user://settings.cfg")
		if button_pressed:
			Helper.setup_discord()
			Helper.refresh_discord()
		else:
			Helper.refresh_discord("clear")


func _on_fps_pressed(extra_arg_0):
	$TabContainer/GRAPHICS/FPS/FPS.set_value(extra_arg_0)


func _on_auto_switch_toggled(button_pressed):
	Settings.auto_switch_buy_sell = button_pressed
	if err == OK:
		config.set_value("game", "auto_switch_buy_sell", button_pressed)
		config.save("user://settings.cfg")
