extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var shop_button: Button = $VBoxContainer/ShopButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton


func _ready() -> void:
	play_button.grab_focus()
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	AudioManager.play_music_by_name("fight_2", 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP:
				var buttons := [play_button, shop_button, settings_button]
				var focused := get_viewport().gui_get_focus_owner()
				var idx := 0
				for i in buttons.size():
					if buttons[i] == focused:
						idx = i
						break
				idx = maxi(idx - 1, 0)
				buttons[idx].grab_focus()
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_S, KEY_DOWN:
				var buttons := [play_button, shop_button, settings_button]
				var focused := get_viewport().gui_get_focus_owner()
				var idx := 0
				for i in buttons.size():
					if buttons[i] == focused:
						idx = i
						break
				idx = mini(idx + 1, buttons.size() - 1)
				buttons[idx].grab_focus()
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				var focused := get_viewport().gui_get_focus_owner()
				if focused and focused is Button:
					focused.emit_signal("pressed")
				if get_viewport(): get_viewport().set_input_as_handled()
				return


func _on_play_pressed() -> void:
	AudioManager.stop_music(0.5)
	await get_tree().create_timer(0.5).timeout
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")


func _on_settings_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SETTINGS)
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")
