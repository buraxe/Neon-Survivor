extends CanvasLayer

@onready var hp_bar: ProgressBar = $Root/BottomCenter/HPContainer/HPPanel/HPBar
@onready var hp_label: Label = $Root/BottomCenter/HPContainer/HPPanel/HPLabel
@onready var shield_panel: Panel = $Root/BottomCenter/HPContainer/ShieldPanel
@onready var shield_bar: ProgressBar = $Root/BottomCenter/HPContainer/ShieldPanel/ShieldBar
@onready var shield_label: Label = $Root/BottomCenter/HPContainer/ShieldPanel/ShieldLabel
@onready var xp_bar: ProgressBar = $Root/TopBar/LeftPanel/LevelXP/VBox/XPBar
@onready var xp_label: Label = $Root/TopBar/LeftPanel/LevelXP/VBox/TopRow/XPLabel
@onready var level_label: Label = $Root/TopBar/LeftPanel/LevelXP/VBox/TopRow/LevelLabel
@onready var timer_label: Label = $Root/TimerLabel
@onready var kill_label: Label = $Root/TopBar/RightPanel/KillBox/KillLabel
@onready var coin_label: Label = $Root/TopBar/RightPanel/CoinBox/CoinLabel
@onready var pause_button: Button = $Root/TopBar/RightPanel/PauseButton
@onready var weapon_slots: HBoxContainer = $Root/TopBar/LeftPanel/Slots/WeaponSlots
@onready var passive_slots: HBoxContainer = $Root/TopBar/LeftPanel/Slots/PassiveSlots
@onready var boss_container: VBoxContainer = $Root/BossContainer
@onready var boss_bar: ProgressBar = $Root/BossContainer/BossBar
@onready var boss_label: Label = $Root/BossContainer/BossLabel
@onready var boss_poison_overlay: ColorRect = $Root/BossContainer/PoisonOverlay
@onready var ultimate_container: VBoxContainer = $Root/BottomCenter/HPContainer/UltimateContainer
@onready var ultimate_bar: ProgressBar = $Root/BottomCenter/HPContainer/UltimateContainer/UltimateBar
@onready var ultimate_label: Label = $Root/BottomCenter/HPContainer/UltimateContainer/UltimateLabel
@onready var low_hp_overlay: ColorRect = $Root/LowHpOverlay

var _player: Player = null
var _boss_name: String = ""


func setup(player: Player) -> void:
	_player = player
	player.hp_changed.connect(_on_hp_changed)
	player.shield_changed.connect(_on_shield_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.level_changed.connect(_on_level_changed)
	player.died.connect(_on_player_died)
	_on_hp_changed(player.hp, player.stats.max_hp)
	_on_xp_changed(player.xp, player.xp_needed)
	_on_level_changed(player.level)
	if player.max_shield > 0:
		_on_shield_changed(player.shield, player.max_shield)

	pause_button.pressed.connect(_on_pause_pressed)
	
	_set_bar_colors()
	_update_weapon_slots()
	_scale_for_mobile()

	_setup_low_hp_shader()

	if player.shape_name == "circle":
		ultimate_container.visible = true
		player.ultimate_changed.connect(_on_ultimate_changed)
		player.ultimate_activated.connect(_on_ultimate_activated)
		player.ultimate_deactivated.connect(_on_ultimate_deactivated)
		_on_ultimate_changed(player.ultimate_charge, player.ultimate_max)
	elif player.shape_name == "square":
		ultimate_container.visible = true
		player.ultimate_changed.connect(_on_square_ultimate_changed)
		player.ultimate_activated.connect(_on_shield_bomb_activated)
		_on_square_ultimate_changed(player.ultimate_charge, player.ultimate_max)
	elif player.shape_name == "triangle":
		ultimate_container.visible = true
		player.ultimate_changed.connect(_on_triangle_ultimate_changed)
		player.ultimate_activated.connect(_on_poison_cloud_activated)
		_on_triangle_ultimate_changed(player.ultimate_charge, player.ultimate_max)
	else:
		ultimate_container.visible = false


func _set_bar_colors() -> void:
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0, 0.7, 0.35)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)

	var boss_fill := StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.7, 0.12, 0.18)
	boss_bar.add_theme_stylebox_override("fill", boss_fill)

	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0, 0.65, 0.8)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)

	var ulti_fill := StyleBoxFlat.new()
	ulti_fill.bg_color = Color(0.7, 0.5, 0.15)
	ultimate_bar.add_theme_stylebox_override("fill", ulti_fill)

	var shield_fill := StyleBoxFlat.new()
	shield_fill.bg_color = Color(0, 0.6, 0.75)
	shield_bar.add_theme_stylebox_override("fill", shield_fill)


func _setup_low_hp_shader() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform bool full_screen = false;
void fragment() {
	vec2 uv = SCREEN_UV;
	float dx = abs(uv.x - 0.5) * 2.0;
	float dy = abs(uv.y - 0.5) * 2.0;
	float edge_dist = max(dx, dy);
	float alpha;
	if (full_screen) {
		alpha = intensity * 0.8;
	} else {
		float vignette = smoothstep(0.5, 1.0, edge_dist);
		float soft = smoothstep(0.2, 0.6, edge_dist);
		alpha = vignette * soft * intensity;
	}
	COLOR = vec4(0.85, 0.0, 0.0, alpha);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	low_hp_overlay.material = mat


func _scale_for_mobile() -> void:
	if DisplayServer.is_touchscreen_available():
		var scale_factor := 0.75
		for child in get_tree().get_nodes_in_group("hud_elements"):
			if child is Control:
				child.scale = Vector2(scale_factor, scale_factor)


func _process(_delta: float) -> void:
	if _player and GameManager.current_state == GameManager.GameState.PLAYING:
		var m := int(GameManager.game_time / 60.0)
		var s := int(fmod(GameManager.game_time, 60.0))
		timer_label.text = "%02d:%02d" % [m, s]
		kill_label.text = "💀 %d" % GameManager.kill_count
		coin_label.text = "💰 %d" % GameManager.run_coins
		_update_weapon_slots()

		var hp_ratio := _player.hp / _player.stats.max_hp
		if hp_ratio < 0.5:
			low_hp_overlay.visible = true
			var intensity := (0.5 - hp_ratio) * 2.0
			var mat: ShaderMaterial = low_hp_overlay.material
			if mat:
				mat.set_shader_parameter("intensity", intensity)
		else:
			low_hp_overlay.visible = false


func _on_hp_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "%d / %d" % [ceili(current), int(maximum)]


func _on_shield_changed(current: float, maximum: float) -> void:
	if maximum > 0:
		shield_panel.visible = true
		shield_bar.max_value = maximum
		shield_bar.value = current
		shield_label.text = "%d / %d" % [ceili(current), int(maximum)]
	else:
		shield_panel.visible = false


func _on_xp_changed(current: int, needed: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current
	xp_label.text = "%d / %d" % [current, needed]


func _on_level_changed(new_level: int) -> void:
	level_label.text = "LEVEL %d" % new_level


func show_boss_bar(boss_name: String) -> void:
	boss_container.visible = true
	_boss_name = boss_name
	boss_label.text = boss_name


func update_boss_hp(ratio: float) -> void:
	boss_bar.value = ratio * 100


func update_boss_poison(poison_dmg: float) -> void:
	if not boss_poison_overlay:
		return
	if poison_dmg > 0 and boss_bar.max_value > 0:
		var hp_ratio := boss_bar.value / 100.0
		var poison_ratio := poison_dmg / boss_bar.max_value
		var bar_w := 300.0
		var poison_w := poison_ratio * bar_w
		var poison_start_x := -bar_w * 0.5 + (1.0 - hp_ratio) * bar_w
		boss_poison_overlay.visible = true
		boss_poison_overlay.offset_left = poison_start_x
		boss_poison_overlay.offset_right = poison_start_x + poison_w
	else:
		boss_poison_overlay.visible = false


func hide_boss_bar() -> void:
	boss_container.visible = false


func show_level_transition(level: int) -> void:
	var label := Label.new()
	label.text = "SEVIYE %d" % level
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.8))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = 8
	label.anchor_left = 0.5
	label.anchor_top = 0.0
	label.anchor_right = 0.5
	label.anchor_bottom = 0.0
	label.offset_left = -160
	label.offset_top = 55
	label.offset_right = 160
	label.offset_bottom = 95
	$Root.add_child(label)
	
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(label, "modulate:a", 0.0, 1.5)
	tw.tween_callback(label.queue_free)
	
	_show_evolution_info()


func _show_evolution_info() -> void:
	if GameManager.evolved_enemy_type < 0:
		return
	var type_names := {
		0: "Normal",
		1: "Hizli",
		2: "Tank",
		3: "Uzaktan",
	}
	var trait_names := {
		"explode": "Patlayici (Olunce hasar verir)",
		"speed_boost": "Hizli (Daha hizli hareket)",
		"shield": "Kalkan (1 vurusu engeller)",
		"split": "Bolunme (Olunce ikiye ayrilir)",
		"dash": "Hamle (Ileri atilir)",
	}
	var type_name: String = type_names.get(GameManager.evolved_enemy_type, "Bilinmeyen")
	var trait_name: String = trait_names.get(GameManager.evolution_trait, "")
	if trait_name == "":
		return
	
	var info := Label.new()
	info.text = "⚠ EVRIM: %s dusmani → %s" % [type_name, trait_name]
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color(0.8, 0.25, 0.0))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.anchors_preset = 8
	info.anchor_left = 0.5
	info.anchor_top = 0.0
	info.anchor_right = 0.5
	info.anchor_bottom = 0.0
	info.offset_left = -300
	info.offset_top = 100
	info.offset_right = 300
	info.offset_bottom = 140
	$Root.add_child(info)
	
	var tw := create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(info, "modulate:a", 0.0, 1.5)
	tw.tween_callback(info.queue_free)


func _on_pause_pressed() -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.pause_game()
		var gw := get_tree().current_scene
		if gw and gw.has_node("PauseMenu"):
			gw.get_node("PauseMenu").show_pause()


func _on_player_died() -> void:
	for child in $Root.get_children():
		if child != low_hp_overlay:
			child.visible = false
	low_hp_overlay.visible = true
	var mat: ShaderMaterial = low_hp_overlay.material
	if mat:
		mat.set_shader_parameter("intensity", 1.0)
		mat.set_shader_parameter("full_screen", true)


func _update_weapon_slots() -> void:
	if not _player:
		return
	var wm := _player.get_node_or_null("WeaponManager")
	if not wm:
		return

	for child in weapon_slots.get_children():
		child.queue_free()
	for child in passive_slots.get_children():
		child.queue_free()

	for w in wm.get_active_weapons():
		var label := Label.new()
		label.text = "%s Lv.%d" % [w.icon, w.level]
		label.add_theme_color_override("font_color", Color(0.13, 0.6, 0.7))
		label.add_theme_font_size_override("font_size", 14)
		weapon_slots.add_child(label)

	var passive_icons := {
		"p_speed": "👟",
		"p_atk_speed": "🔋",
		"p_crit": "🎯",
		"p_dmg": "🔥",
		"p_proj": "➕",
		"p_hp": "🧪",
		"p_magnet": "🧲",
		"p_evasion": "💨",
		"p_shield": "🛡️",
		"p_vampir": "🩸",
		"p_critdmg": "💀",
		"p_regen": "💚",
		"p_xpboost": "📚",
		"p_size": "🔮",
	}

	for pid in _player.passives:
		if passive_icons.has(pid):
			var label := Label.new()
			label.text = passive_icons[pid]
			label.add_theme_font_size_override("font_size", 14)
			passive_slots.add_child(label)


func _on_ultimate_changed(current: float, maximum: float) -> void:
	ultimate_bar.max_value = maximum
	ultimate_bar.value = current
	if current >= maximum:
		_ult_glow()
	else:
		_ult_unglow()


func _on_ultimate_activated() -> void:
	_ult_unglow()


func _on_ultimate_deactivated() -> void:
	_ult_unglow()
	_on_ultimate_changed(_player.ultimate_charge, _player.ultimate_max)


func _on_shield_bomb_activated() -> void:
	pass


func _on_square_ultimate_changed(current: float, maximum: float) -> void:
	if _player.shape_name != "square":
		return
	ultimate_bar.max_value = maximum
	ultimate_bar.value = current
	if current >= maximum:
		_ult_glow()
	else:
		_ult_unglow()


func _on_triangle_ultimate_changed(current: float, maximum: float) -> void:
	if _player.shape_name != "triangle":
		return
	ultimate_bar.max_value = maximum
	ultimate_bar.value = current
	if current >= maximum:
		_ult_glow()
	else:
		_ult_unglow()


func _on_poison_cloud_activated() -> void:
	_ult_unglow()


var _ult_glow_box: StyleBoxFlat = null


func _ult_glow() -> void:
	if _ult_glow_box == null:
		_ult_glow_box = StyleBoxFlat.new()
		_ult_glow_box.bg_color = Color(0.7, 0.5, 0.15, 0.7)
		_ult_glow_box.shadow_color = Color(0.9, 0.7, 0.2, 0.5)
		_ult_glow_box.shadow_size = 6
		_ult_glow_box.shadow_offset = Vector2(0, 0)
		_ult_glow_box.corner_radius_top_left = 0
		_ult_glow_box.corner_radius_top_right = 0
		_ult_glow_box.corner_radius_bottom_left = 0
		_ult_glow_box.corner_radius_bottom_right = 0
	ultimate_bar.add_theme_stylebox_override("fill", _ult_glow_box)


func _ult_unglow() -> void:
	var ulti_fill := StyleBoxFlat.new()
	ulti_fill.bg_color = Color(0.7, 0.5, 0.15, 0.7)
	ulti_fill.corner_radius_top_left = 0
	ulti_fill.corner_radius_top_right = 0
	ulti_fill.corner_radius_bottom_left = 0
	ulti_fill.corner_radius_bottom_right = 0
	ultimate_bar.add_theme_stylebox_override("fill", ulti_fill)
