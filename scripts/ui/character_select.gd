extends Control

@onready var back_button: Button = $BackButton
@onready var circle_button: Button = $VBoxContainer/HBoxContainer/CircleButton
@onready var triangle_button: Button = $VBoxContainer/HBoxContainer/TriangleButton
@onready var square_button: Button = $VBoxContainer/HBoxContainer/SquareButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	circle_button.pressed.connect(func(): _select_shape("circle"))
	triangle_button.pressed.connect(func(): _select_shape("triangle"))
	square_button.pressed.connect(func(): _select_shape("square"))

	_update_locks()
	circle_button.grab_focus()


func _update_locks() -> void:
	var unlocked := GameManager.unlocked_characters
	if not unlocked.has("triangle"):
		triangle_button.disabled = true
		triangle_button.text = "🔺 ÜÇGEN\n🔒 KİLİTLİ\n(150 💰)"
	if not unlocked.has("square"):
		square_button.disabled = true
		square_button.text = "🟥 KARE\n🔒 KİLİTLİ\n(100 💰)"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_S, KEY_UP, KEY_DOWN, KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT:
				if event.keycode in [KEY_A, KEY_LEFT]:
					_move_focus(-1)
				else:
					_move_focus(1)
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				var focused := get_viewport().gui_get_focus_owner()
				if focused and focused is Button:
					focused.emit_signal("pressed")
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_ESCAPE:
				_on_back_pressed()
				if get_viewport(): get_viewport().set_input_as_handled()
				return


func _move_focus(dir: int) -> void:
	var buttons := [circle_button, triangle_button, square_button]
	var current_idx := -1
	var focused := get_viewport().gui_get_focus_owner()
	for i in buttons.size():
		if buttons[i] == focused:
			current_idx = i
			break

	if current_idx < 0:
		circle_button.grab_focus()
		return

	var next_idx := clampi(current_idx + dir, 0, buttons.size() - 1)
	buttons[next_idx].grab_focus()


func _select_shape(shape: String) -> void:
	GameManager.selected_shape = shape
	GameManager.change_state(GameManager.GameState.WEAPON_SELECT)
	get_tree().change_scene_to_file("res://scenes/ui/weapon_select.tscn")


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
