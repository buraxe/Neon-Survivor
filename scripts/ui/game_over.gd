extends Control

@onready var restart_button: Button = $VBoxContainer/ButtonBox/RestartButton
@onready var shop_button: Button = $VBoxContainer/ButtonBox/ShopButton
@onready var menu_button: Button = $VBoxContainer/ButtonBox/MenuButton
@onready var stats_label: RichTextLabel = $VBoxContainer/StatsLabel


func _ready() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.GAME_OVER)
	GameManager.commit_run_coins()
	AudioManager.stop_music(1.0)
	restart_button.grab_focus()
	restart_button.pressed.connect(_on_restart)
	shop_button.pressed.connect(_on_shop)
	menu_button.pressed.connect(_on_menu)
	_show_stats()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT, KEY_W, KEY_UP, KEY_S, KEY_DOWN:
				var buttons := [restart_button, shop_button, menu_button]
				var focused := get_viewport().gui_get_focus_owner()
				var idx := 0
				for i in buttons.size():
					if buttons[i] == focused:
						idx = i
						break
				if event.keycode in [KEY_A, KEY_LEFT, KEY_W, KEY_UP]:
					idx = maxi(idx - 1, 0)
				else:
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


func _show_stats() -> void:
	var m := int(GameManager.game_time / 60.0)
	var s := int(fmod(GameManager.game_time, 60.0))
	var text := "[center][font_size=48][color=#ef4444]ÖLDÜN[/color][/font_size]\n\n"
	text += "[font_size=20]Yok Edilen: [color=white]%d[/color] | Süre: [color=white]%02d:%02d[/color] | 💰 [color=#fbbf24]%d Coin[/color][/font_size]\n\n" % [GameManager.kill_count, m, s, GameManager.run_coins]

	var total_damage := 0.0
	for source in GameManager.damage_stats:
		total_damage += GameManager.damage_stats[source].damage

	if total_damage > 0:
		text += "[font_size=12][color=#f87171]VERİLEN HASAR[/color][/font_size]\n"
		var sorted := GameManager.damage_stats.keys()
		sorted.sort_custom(func(a, b): return GameManager.damage_stats[b].damage > GameManager.damage_stats[a].damage)
		for source in sorted:
			var data: Dictionary = GameManager.damage_stats[source]
			var pct: float = data.damage / total_damage * 100
			text += "[font_size=11]%s: [color=white]%d[/color] (%.1f%%)[/font_size]\n" % [source, int(data.damage), pct]
		text += "[font_size=13][color=#f87171]TOPLAM: [color=white]%d[/color][/color][/font_size]\n" % int(total_damage)

	text += "\n[font_size=11][color=#64748b]ESC ile devam et[/color][/font_size][/center]"
	stats_label.text = text


func _on_restart() -> void:
	get_tree().paused = false
	GameManager._reset_game_state()
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _on_shop() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")


func _on_menu() -> void:
	GameManager.reset_to_menu()
