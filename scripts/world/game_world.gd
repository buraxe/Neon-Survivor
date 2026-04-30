extends Node2D

@onready var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var vfx_manager: Node2D = $VFXManager
@onready var special_manager: Node2D = $SpecialManager
@onready var crt_overlay: ColorRect = $CRTLayer/CRTOverlay
@onready var pause_menu: CanvasLayer = $PauseMenu

var player: Player = null
var _arena_walls: Array[StaticBody2D] = []
const ARENA_SIZE: float = 1800.0
var _current_music: String = ""


func _ready() -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING and GameManager.DEV_MODE:
		GameManager.start_game("circle", "wand")
	_spawn_player()
	camera.position_smoothing_enabled = false
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	GameManager.next_level_requested.connect(_on_next_level_requested)
	GameManager.dev_skip_to_level_requested.connect(_on_dev_skip_level)


func _spawn_player() -> void:
	if player:
		player.queue_free()

	player = player_scene.instantiate()
	add_child(player)
	player.setup(GameManager.selected_shape)
	player.died.connect(_on_player_died)
	player.level_changed.connect(_on_level_up)

	GameManager.player = player

	camera.global_position = player.global_position

	if hud:
		hud.setup(player)
		if hud.has_method("show_level_transition"):
			hud.show_level_transition(GameManager.current_level)
	
	# Lv4 (ARENA) kurulumu - dev skip ile baslatildiysa
	if GameManager.current_level == 4:
		_setup_arena()
		_spawn_arena_boss()
		if player:
			player.global_position = Vector2.ZERO
			camera.global_position = Vector2.ZERO
		camera.zoom = Vector2.ONE
	
	if crt_overlay:
		crt_overlay.apply_settings()
	
	# Müzik başlat
	_current_music = ""
	_update_music()


func _on_level_up(_new_level: int) -> void:
	AudioManager.play_sfx(AudioManager.SFXType.LEVEL_UP)


var _death_zoom_timer: float = 0.0

func _process(delta: float) -> void:
	if _death_zoom_timer > 0:
		_death_zoom_timer -= delta
		camera.zoom = camera.zoom.lerp(Vector2(0.3, 0.3), delta * 5.0)
		if _death_zoom_timer <= 0:
			GameManager.show_game_over()
		return

	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	if GameManager.death_timer >= 0:
		GameManager.death_timer -= delta
		if GameManager.death_timer <= 0:
			GameManager.death_timer = -1.0
			GameManager.show_game_over()
		return

	GameManager.game_time += delta
	
	_update_music()


func _physics_process(_delta: float) -> void:
	if player and GameManager.current_state == GameManager.GameState.PLAYING:
		camera.global_position = player.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
			pause_menu.show_pause()
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			GameManager.resume_game()
			pause_menu.hide_pause()


func _on_player_died() -> void:
	GameManager.change_state(GameManager.GameState.GAME_OVER)
	_death_zoom_timer = 0.6


func _on_game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")


func _on_victory() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/victory.tscn")


func _on_next_level_requested(portal_pos: Vector2) -> void:
	_spawn_portal(portal_pos)


func _spawn_portal(pos: Vector2) -> void:
	var portal_scene: PackedScene = preload("res://scenes/world/portal.tscn")
	var portal := portal_scene.instantiate()
	portal.global_position = pos
	call_deferred("add_child", portal)


func advance_level() -> void:
	GameManager.current_level += 1
	GameManager.game_time = 0.0
	GameManager.final_boss_spawned = false
	GameManager.first_boss_killed = false
	GameManager.first_elite_spawned = false
	GameManager.boss_active = null
	GameManager.special_wave_active = false
	GameManager.special_wave_minute = 0
	GameManager.special_wave_timer = 0.0
	GameManager.pressure_wave_active = false
	GameManager.pressure_wave_timer = 0.0
	GameManager.pick_evolution()
	_current_music = ""
	
	# Tüm enemy'leri temizle
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy:
			e.queue_free()
	
	# Enemy spawner'ı resetle
	if has_node("EnemySpawner"):
		var spawner := get_node("EnemySpawner")
		spawner._first_elite_spawned = false
		spawner._last_boss_time = 0.0
		spawner._special_wave_timer = 0.0
		spawner._spawn_timer = 0.0
		spawner._wave_timer = 0.0
	
	# Player'ı full heal
	if player:
		player.heal(player.stats.max_hp)
	
	# Lv4 (GRAND FINAL) kurulumu
	if GameManager.current_level == 4:
		_setup_arena()
		_spawn_arena_boss()
		if player:
			player.global_position = Vector2.ZERO
			camera.global_position = Vector2.ZERO
		camera.zoom = Vector2.ONE
	
	# Mevcut portalları temizle
	for p in get_tree().get_nodes_in_group("portals"):
		if p is Area2D:
			p.queue_free()
	
	# HUD'da seviye göster
	if hud and hud.has_method("show_level_transition"):
		hud.show_level_transition(GameManager.current_level)


func _setup_arena() -> void:
	# Eski duvarları temizle
	for wall in _arena_walls:
		if is_instance_valid(wall):
			wall.queue_free()
	_arena_walls.clear()
	
	var half := ARENA_SIZE * 0.5
	var wall_thickness := 60.0
	var wall_color := Color(0.1, 0.1, 0.15)
	
	# Duvar pozisyonları: Üst, Alt, Sol, Sağ
	var walls := [
		{"pos": Vector2(0, -half - wall_thickness * 0.5), "size": Vector2(ARENA_SIZE + wall_thickness * 2, wall_thickness)},
		{"pos": Vector2(0, half + wall_thickness * 0.5), "size": Vector2(ARENA_SIZE + wall_thickness * 2, wall_thickness)},
		{"pos": Vector2(-half - wall_thickness * 0.5, 0), "size": Vector2(wall_thickness, ARENA_SIZE + wall_thickness * 2)},
		{"pos": Vector2(half + wall_thickness * 0.5, 0), "size": Vector2(wall_thickness, ARENA_SIZE + wall_thickness * 2)},
	]
	
	for w in walls:
		var body := StaticBody2D.new()
		body.collision_layer = 32
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = w.size
		shape.shape = rect
		body.add_child(shape)
		body.global_position = w.pos
		
		# Görsel
		var visual := Polygon2D.new()
		var hw: float = w.size.x * 0.5
		var hh: float = w.size.y * 0.5
		visual.polygon = PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
		visual.color = wall_color
		body.add_child(visual)
		
		call_deferred("add_child", body)
		_arena_walls.append(body)


func _on_enemy_died(_enemy: Enemy) -> void:
	var player_ref := GameManager.player
	if player_ref and player_ref.has_method("charge_ultimate"):
		player_ref.charge_ultimate(1.0)


func _on_dev_skip_level(level: int) -> void:
	GameManager.game_time = 0.0
	_current_music = ""
	# Tüm enemy'leri temizle
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy:
			e.queue_free()
	
	# Mevcut portalları temizle
	for p in get_tree().get_nodes_in_group("portals"):
		if p is Area2D:
			p.queue_free()
	
	# Enemy spawner'ı resetle
	if has_node("EnemySpawner"):
		var spawner := get_node("EnemySpawner")
		spawner._first_elite_spawned = false
		spawner._last_boss_time = 0.0
		spawner._special_wave_timer = 0.0
		spawner._spawn_timer = 0.0
		spawner._wave_timer = 0.0
	
	# Player'ı full heal
	if player:
		player.heal(player.stats.max_hp)
		player.global_position = Vector2.ZERO
		camera.global_position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	
	# Lv4 (ARENA) kurulumu
	if level == 4:
		_setup_arena()
		_spawn_arena_boss()
	else:
		# Arena duvarlarını temizle
		for wall in _arena_walls:
			if is_instance_valid(wall):
				wall.queue_free()
		_arena_walls.clear()
	
	# HUD'da seviye göster
	if hud and hud.has_method("show_level_transition"):
		hud.show_level_transition(level)


func _spawn_arena_boss() -> void:
	var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")
	var boss = enemy_scene.instantiate()
	boss.add_to_group("enemies")
	boss.global_position = Vector2(0, -300)
	add_child(boss)
	boss.setup(Enemy.Type.FINAL_BOSS, 30)
	boss.hp *= 2.0
	boss.max_hp = boss.hp
	boss.damage = ceili(boss.damage * 1.5)
	boss.died.connect(_on_enemy_died)
	boss.died.connect(_on_boss_died)
	GameManager.boss_active = boss
	GameManager.final_boss_spawned = true


func _update_music() -> void:
	if GameManager.current_level == 4 and GameManager.final_boss_spawned:
		if _current_music != "main_theme":
			AudioManager.play_music_by_name("main_theme", 1.0)
			_current_music = "main_theme"
		return
	
	if GameManager.boss_active and is_instance_valid(GameManager.boss_active):
		AudioManager.play_music_by_name("boss_theme", 0.5)
		_current_music = "boss_theme"
		return
	
	if _current_music != "fight_1":
		AudioManager.play_music_by_name("fight_1", 1.0)
		_current_music = "fight_1"


func _on_boss_died(_enemy: Enemy) -> void:
	GameManager.boss_active = null
	_update_music()
