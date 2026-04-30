extends CanvasLayer

@onready var resume_button: Button = $Root/VBoxContainer/ResumeButton
@onready var settings_button: Button = $Root/VBoxContainer/SettingsButton
@onready var restart_button: Button = $Root/VBoxContainer/RestartButton
@onready var menu_button: Button = $Root/VBoxContainer/MenuButton


func _ready() -> void:
	resume_button.pressed.connect(_on_resume)
	settings_button.pressed.connect(_on_settings)
	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(_on_menu)
	visible = false


func show_pause() -> void:
	visible = true
	resume_button.grab_focus()


func hide_pause() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP:
				var buttons := [resume_button, settings_button, restart_button, menu_button]
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
				var buttons := [resume_button, settings_button, restart_button, menu_button]
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
			KEY_ESCAPE:
				GameManager.resume_game()
				hide_pause()
				if get_viewport(): get_viewport().set_input_as_handled()
				return


func _on_resume() -> void:
	GameManager.resume_game()
	hide_pause()


func _on_settings() -> void:
	var settings_scene: PackedScene = preload("res://scenes/ui/settings.tscn")
	var settings := settings_scene.instantiate()
	settings.process_mode = Node.PROCESS_MODE_ALWAYS
	settings.tree_exited.connect(_on_settings_closed)
	add_child(settings)
	$Root.visible = false


func _on_settings_closed() -> void:
	$Root.visible = true
	resume_button.grab_focus()


func _on_restart() -> void:
	hide_pause()
	GameManager.start_game(GameManager.selected_shape, GameManager.selected_weapon)
	get_tree().change_scene_to_file("res://scenes/world/game_world.tscn")


func _on_menu() -> void:
	hide_pause()
	GameManager.reset_to_menu()
