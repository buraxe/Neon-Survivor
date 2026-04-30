extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const SPAWN_DISTANCE_MIN := 700.0
const SPAWN_DISTANCE_MAX := 900.0
const MAX_ENEMIES := 200
const DESPAWN_DISTANCE := 2000.0

var _spawn_timer: float = 0.0
var _wave_timer: float = 0.0
var _last_boss_time: float = 0.0
var _first_elite_spawned: bool = false
var _special_wave_timer: float = 0.0


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if not GameManager.player:
		return

	if GameManager.death_timer >= 0:
		return
	
	# Lv4'te (Grand Final) boss sonrasi sonsuz baski
	if GameManager.current_level == 4:
		if GameManager.pressure_wave_active:
			_pressure_wave_logic(delta)
		_cleanup_far_enemies()
		_resolve_enemy_collisions()
		return

	_spawn_timer += delta
	_wave_timer += delta

	# Boss sonrasi baski dalgasi (Lv1-3)
	if GameManager.pressure_wave_active:
		_pressure_wave_logic(delta)

	var spawn_rate := _get_spawn_rate()
	if _spawn_timer >= 1.0 / maxf(spawn_rate, 0.001):
		_spawn_timer = 0.0
		_try_spawn_enemy()

	if int(GameManager.game_time) > 0 and fmod(GameManager.game_time, 60.0) < delta * 2:
		_spawn_wave()

	if not GameManager.boss_active and GameManager.game_time > 600 and not GameManager.final_boss_spawned:
		GameManager.final_boss_spawned = true
		_spawn_boss(true)

	if not GameManager.boss_active and not GameManager.final_boss_spawned and GameManager.game_time > _last_boss_time + 120:
		_spawn_boss(false)

	if not _first_elite_spawned and GameManager.game_time >= 60:
		_first_elite_spawned = true
		GameManager.first_elite_spawned = true
		_spawn_elite()

	if GameManager.special_wave_active:
		_special_wave_timer += delta
		if _special_wave_timer >= 60:
			_special_wave_timer -= 60
			GameManager.special_wave_minute += 1
		var enemy_count := get_tree().get_nodes_in_group("enemies").size()
		if enemy_count < MAX_ENEMIES and _special_wave_timer >= 2.0:
			_special_wave_timer -= 2.0
			_spawn_enemy(Enemy.Type.SPECIAL)

	_cleanup_far_enemies()
	_resolve_enemy_collisions()


func _get_spawn_rate() -> float:
	var t := GameManager.game_time
	if GameManager.boss_active:
		return 0.5 * (1.0 + GameManager.current_level * 0.3)

	var level_mult := 1.0 + (GameManager.current_level - 1) * 0.25

	if t < 60:
		return minf(3.0, (0.15 + t * 0.06) * level_mult)
	elif t < 180:
		return minf(4.5, (1.0 + (t - 60) * 0.012) * level_mult)
	elif t < 240:
		return minf(5.0, (1.5 + (t - 180) * 0.01) * level_mult)
	elif GameManager.first_boss_killed:
		return minf(3.5, (0.8 + (t - 240) * 0.008) * level_mult)
	else:
		return minf(2.5, (0.5 + (t - 240) * 0.005) * level_mult)


func _try_spawn_enemy() -> void:
	var enemy_count := get_tree().get_nodes_in_group("enemies").size()
	if enemy_count >= MAX_ENEMIES:
		return

	var e_type := _pick_enemy_type()
	_spawn_enemy(e_type)


func _pick_enemy_type() -> int:
	var t := GameManager.game_time
	var r := randf()

	var elite_chance := minf(0.15, 0.003 * (t - 60) / 10)
	if GameManager.first_boss_killed:
		elite_chance *= 1.5
	if GameManager.current_level >= 3:
		elite_chance *= 1.3

	if t > 60 and r < elite_chance:
		return Enemy.Type.ELITE
	if t > 45 and r < 0.28:
		return Enemy.Type.FAST
	if t > 90 and r > 0.78:
		return Enemy.Type.HEAVY
	if t > 70 and r > 0.55 and r <= 0.78:
		var ranged_count := get_tree().get_nodes_in_group("enemies").filter(
			func(e): return e is Enemy and e.enemy_type == Enemy.Type.RANGED
		).size()
		if ranged_count < 15:
			return Enemy.Type.RANGED

	return Enemy.Type.NORMAL


func _spawn_enemy(type: int) -> void:
	var player := GameManager.player
	if not player:
		return

	var angle := randf() * TAU
	var dist := SPAWN_DISTANCE_MIN + randf() * (SPAWN_DISTANCE_MAX - SPAWN_DISTANCE_MIN)
	
	# Lv4'te arena sınırları içinde spawn et
	if GameManager.current_level == 4:
		dist = clampf(dist, 300.0, 700.0)
	
	var spawn_pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist
	
	# Lv4'te spawn pozisyonunu arena sınırlarına kıstır
	if GameManager.current_level == 4:
		var half := 870.0
		spawn_pos.x = clampf(spawn_pos.x, -half, half)
		spawn_pos.y = clampf(spawn_pos.y, -half, half)

	var enemy := ENEMY_SCENE.instantiate()
	enemy.add_to_group("enemies")
	enemy.global_position = spawn_pos
	enemy.setup(type, int(GameManager.game_time / 20))
	enemy.died.connect(_on_enemy_died)
	call_deferred("add_child", enemy)


func _spawn_wave() -> void:
	if GameManager.boss_active:
		return
	var level_mult := 1.0 + (GameManager.current_level - 1) * 0.3
	var base_count := int((4 + int(GameManager.game_time / 60) * 2) * level_mult)
	if GameManager.first_boss_killed:
		base_count = int((8 + int(GameManager.game_time / 60) * 4) * level_mult)
	var wave_count := mini(base_count, MAX_ENEMIES - get_tree().get_nodes_in_group("enemies").size())

	for i in wave_count:
		var r := randf()
		var e_type: int
		if r < 0.3:
			e_type = Enemy.Type.FAST
		elif r > 0.85:
			e_type = Enemy.Type.HEAVY
		elif r > 0.6:
			e_type = Enemy.Type.RANGED
		else:
			e_type = Enemy.Type.NORMAL
		_spawn_enemy(e_type)
	
	# Boss sonrasi dalgalarda elit ekle
	if GameManager.first_boss_killed and GameManager.game_time > 600:
		var elite_count := mini(2 + GameManager.current_level, 5)
		for i in elite_count:
			if randf() < 0.15:
				_spawn_enemy(Enemy.Type.ELITE)


func _cleanup_far_enemies() -> void:
	var player := GameManager.player
	if not player:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Enemy and e.global_position.distance_to(player.global_position) > DESPAWN_DISTANCE:
			e.queue_free()


func _resolve_enemy_collisions() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var count := enemies.size()
	if count < 2:
		return

	for i in range(mini(count, 80)):
		var idx_a := randi_range(0, count - 1)
		var idx_b := randi_range(0, count - 1)
		if idx_a == idx_b:
			continue
		var a: Enemy = enemies[idx_a]
		var b: Enemy = enemies[idx_b]
		if not a.alive or not b.alive:
			continue

		var diff := b.global_position - a.global_position
		var dist := diff.length()
		var min_dist := a.radius + b.radius
		if dist < min_dist and dist > 0.01:
			var overlap := (min_dist - dist) * 0.5
			var n := diff / dist
			a.global_position -= n * overlap
			b.global_position += n * overlap

	if GameManager.player:
		var player_pos := GameManager.player.global_position
		var player_radius: float = 20.0
		for e in enemies:
			if not e.alive:
				continue
			var diff: Vector2 = e.global_position - player_pos
			var dist: float = diff.length()
			var min_dist: float = e.radius + player_radius
			if dist < min_dist * 0.6 and dist > 0.01:
				var overlap: float = (min_dist - dist) * 0.4
				var n: Vector2 = diff / dist
				e.global_position += n * overlap


func _spawn_boss(is_final: bool) -> void:
	if not GameManager.player:
		return
	var boss_type := Enemy.Type.FINAL_BOSS if is_final else Enemy.Type.BOSS
	var angle := randf() * TAU
	var dist := 700.0
	var spawn_pos := GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var boss := ENEMY_SCENE.instantiate()
	boss.add_to_group("enemies")
	boss.global_position = spawn_pos
	call_deferred("add_child", boss)
	await get_tree().process_frame
	boss.setup(boss_type, int(GameManager.game_time / 20))
	boss.died.connect(_on_enemy_died)
	boss.died.connect(_on_boss_died)
	GameManager.boss_active = boss
	_last_boss_time = GameManager.game_time


func _spawn_elite() -> void:
	if not GameManager.player:
		return
	var angle := randf() * TAU
	var spawn_pos := GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * 750
	var elite := ENEMY_SCENE.instantiate()
	elite.add_to_group("enemies")
	elite.global_position = spawn_pos
	elite.setup(Enemy.Type.ELITE, int(GameManager.game_time / 20))
	elite.died.connect(_on_enemy_died)
	call_deferred("add_child", elite)


func _on_enemy_died(_enemy: Enemy) -> void:
	var player := GameManager.player
	if player and player.has_method("charge_ultimate"):
		player.charge_ultimate(1.0)


func _on_boss_died(_enemy: Enemy) -> void:
	GameManager.boss_active = null


func _pressure_wave_logic(delta: float) -> void:
	if not GameManager.player:
		return
	GameManager.pressure_wave_timer -= delta
	if GameManager.pressure_wave_timer > 0:
		return
	var is_grand: bool = GameManager.current_level == 4
	var spawn_interval := 0.8 if is_grand else 1.5
	GameManager.pressure_wave_timer = spawn_interval
	var enemy_count := get_tree().get_nodes_in_group("enemies").size()
	if enemy_count >= MAX_ENEMIES:
		return
	var types := [Enemy.Type.NORMAL, Enemy.Type.FAST, Enemy.Type.HEAVY, Enemy.Type.RANGED]
	var type: int = types[randi() % types.size()]
	var angle := randf() * TAU
	var dist := 400.0 + randf() * 300.0
	var spawn_pos := GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * dist
	
	# Lv4'te arena sınırlarına kıstır
	if is_grand:
		var half := 870.0
		spawn_pos.x = clampf(spawn_pos.x, -half, half)
		spawn_pos.y = clampf(spawn_pos.y, -half, half)
	
	var enemy := ENEMY_SCENE.instantiate()
	enemy.add_to_group("enemies")
	enemy.global_position = spawn_pos
	enemy.died.connect(_on_enemy_died)
	call_deferred("add_child", enemy)
	await get_tree().process_frame
	if not is_instance_valid(enemy):
		return
	var lvl := int(GameManager.game_time / 20)
	if is_grand:
		lvl = maxi(lvl, 15)
	enemy.setup(type, lvl)
	if is_grand:
		# Lv4 düşmanları daha güçlü
		enemy.hp *= 3.0
		enemy.max_hp = enemy.hp
		enemy.damage = ceili(enemy.damage * 2.0)
		enemy.speed *= 1.2
	
	# Final boss sonrasi dalgalarda elit şansı
	if is_grand and randf() < 0.2:
		var elite := ENEMY_SCENE.instantiate()
		elite.add_to_group("enemies")
		var elite_angle := randf() * TAU
		var elite_dist := 400.0 + randf() * 200.0
		var elite_pos := GameManager.player.global_position + Vector2(cos(elite_angle), sin(elite_angle)) * elite_dist
		elite_pos.x = clampf(elite_pos.x, -870.0, 870.0)
		elite_pos.y = clampf(elite_pos.y, -870.0, 870.0)
		elite.global_position = elite_pos
		elite.died.connect(_on_enemy_died)
		call_deferred("add_child", elite)
		await get_tree().process_frame
		if not is_instance_valid(elite):
			return
		elite.setup(Enemy.Type.ELITE, lvl)
		elite.hp *= 4.0
		elite.max_hp = elite.hp
		elite.damage = ceili(elite.damage * 2.5)
