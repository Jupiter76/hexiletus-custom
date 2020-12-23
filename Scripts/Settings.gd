extends Panel

onready var game = get_node("/root/Game")
"""
audio sliders are set to each bus
(you can find the buses by looking at the bottom of the screen and clicking Audio)
"""
var tween
var polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")
func _ready():
	tween = Tween.new()
	add_child(tween)
	if err == OK:
		$Master.value = config.get_value("audio", "master", 0)
		update_volumes(0, config.get_value("audio", "master", 0))
		$Music.value = config.get_value("audio", "music", 0)
		update_volumes(1, config.get_value("audio", "music", 0))
		$SFX.value = config.get_value("audio", "SFX", 0)
		update_volumes(2, config.get_value("audio", "SFX", 0))
		$Vsync.pressed = config.get_value("graphics", "vsync", true)
		$AutosaveLight.pressed = config.get_value("saving", "autosave_light", false)
		var autosave_interval = config.get_value("saving", "autosave", 10)
		$Label3.text = "%s %s" % [autosave_interval, tr("S_SECOND")]
		$Autosave.value = autosave_interval

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
	if value > -40:
		AudioServer.set_bus_mute(bus,false)
	else:
		AudioServer.set_bus_mute(bus,true)

func refresh():
	if game.c_v == "STM":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		game.STM.show_help("")
		game.STM.set_process(false)

func _on_Vsync_toggled(button_pressed):
	if err == OK:
		OS.vsync_enabled = button_pressed
		config.set_value("graphics", "vsync", button_pressed)
		config.save("user://settings.cfg")


func _on_Autosave_value_changed(value):
	if err == OK:
		$Label3.text = "%s %s" % [value, tr("S_SECOND")]
		game.autosave_interval = value
		config.set_value("saving", "autosave", value)
		config.save("user://settings.cfg")
		game.get_node("Autosave").stop()
		game.get_node("Autosave").wait_time = value
		game.get_node("Autosave").start()


func _on_AutosaveLight_toggled(button_pressed):
	if err == OK:
		config.set_value("saving", "autosave_light", button_pressed)
		config.save("user://settings.cfg")
		if game.HUD:
			game.HUD.refresh()
