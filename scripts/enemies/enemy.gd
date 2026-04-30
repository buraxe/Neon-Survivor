class_name Enemy
extends CharacterBody2D

signal died(enemy)

enum Type { NORMAL, FAST, HEAVY, RANGED, ELITE, SPECIAL, BOSS, FINAL_BOSS }

@export var enemy_type: Type = Type.NORMAL

var hp: float = 40.0
var max_hp: float = 40.0
var speed: float = 100.0
var damage: float = 20.0
var radius: float = 18.0
var color: Color = Color(0.29, 0.87, 0.50)

var alive: bool = true
var freeze_timer: float = 0.0
var flash_timer: float = 0.0
var show_hp_timer: float = 0.0
var stuck_timer: float = 0.0
var stuck_dir: float = 0.0
var is_elite: bool = false
var is_special: bool = false
var is_boss: bool = false
var is_final_boss: bool = false
var enemy_level: int = 1

var _target: Player = null
var _base_color: Color = Color(0.29, 0.87, 0.50)
var _shoot_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _attack_pattern: int = 0
var _pattern_timer: float = 4.0
var _dash_timer: float = 0.0
var _dash_dx: float = 0.0
var _dash_dy: float = 0.0
var _phase_two: bool = false
var _rage_mode: bool = false
var _rage_timer: float = 0.0
var _poison_timer: float = 0.0
var _poison_damage: float = 0.0
var _poison_tick_timer: float = 0.0
const POISON_TICK_INTERVAL: float = 1.0

var _shoot_cooldown: float = 2.5
var _explode_on_death: bool = false
var _explode_dmg: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO


func setup(type: Type, level: int) -> void:
	enemy_type = type
	enemy_level = level
	_target = GameManager.player

	var current_min := int(GameManager.game_time / 60.0)
	var first_min_mult := 1.2 if current_min == 0 else 1.0

	var enemy_scaling: float
	if current_min < 10:
		enemy_scaling = 0.12 + current_min * 0.015
	else:
		enemy_scaling = minf(0.27 + (current_min - 10) * 0.06, 0.9)

	var early_mult := enemy_scaling * (1.25 if GameManager.first_boss_killed else 1.0)
	var level_mult := 1.0
	var dmg_level_mult := 1.0
	match GameManager.current_level:
		1: level_mult = 1.0; dmg_level_mult = 1.0
		2: level_mult = 1.5; dmg_level_mult = 1.3
		3: level_mult = 2.0; dmg_level_mult = 1.6
		4: level_mult = 2.5; dmg_level_mult = 2.0
	var elite_mult := 1.0
	if type == Type.ELITE:
		if current_min == 0:
			elite_mult = 3.0
		elif current_min < 10:
			elite_mult = 1.5

	match type:
		Type.NORMAL:
			hp = (50 + level * 20) * 1.15 * early_mult * first_min_mult
			speed = 100.0
			damage = ceili((18 + level * 3) * 1.05 * early_mult) + 2
			radius = 18.0
			color = Color(0.29, 0.87, 0.50)
		Type.FAST:
			hp = (25 + level * 4) * early_mult * first_min_mult
			speed = 200.0
			damage = ceili((12 + level * 2) * 1.1 * early_mult)
			radius = 12.0
			color = Color(0.98, 0.80, 0.14)
		Type.HEAVY:
			hp = (105 + level * 35) * 1.2 * early_mult * first_min_mult
			speed = 60.0
			damage = ceili((30 + level * 3) * 1.1 * early_mult)
			radius = 26.0
			color = Color(0.66, 0.33, 0.97)
		Type.RANGED:
			hp = (35 + level * 12) * 1.2 * early_mult * first_min_mult
			speed = 65.0
			damage = ceili((10 + level * 2) * early_mult)
			radius = 16.0
			color = Color(0.96, 0.45, 0.71)
		Type.ELITE:
			is_elite = true
			var base_hp := (80 + level * 20) * 1.3 * early_mult * first_min_mult * elite_mult
			hp = base_hp * (15.0 if early_mult < 0.5 else 4.0)
			speed = 100.0
			damage = ceili((25 + level * 3) * 1.1 * early_mult * 2.0)
			radius = 22.0
			color = Color(0.98, 0.45, 0.09)
		Type.SPECIAL:
			is_special = true
			var s_mult := 1.0 + GameManager.special_wave_minute * 0.5
			hp = (80 + level * 25) * 1.5 * s_mult * first_min_mult
			speed = 110.0 + GameManager.special_wave_minute * 8.0
			damage = ceili((25 + level * 4) * 1.3 * s_mult)
			radius = 20.0 + minf(GameManager.special_wave_minute, 20.0)
			color = Color(1.0, 0.4, 0.0)
		Type.BOSS:
			is_boss = true
			hp = 1200.0 * (1.0 + level * 0.3)
			speed = 95.0
			damage = ceili(15.0 + level * 2)
			radius = 45.0
			color = Color(0.96, 0.25, 0.37)
			_shoot_timer = 0.8 + randf() * 0.5
			_attack_cooldown = 1.0 + randf() * 0.8
			_attack_pattern = 0
			_pattern_timer = 4.0
			GameManager.boss_active = self
			_show_boss_bar("⚠ BOSS")
		Type.FINAL_BOSS:
			is_final_boss = true
			is_boss = true
			hp = 60000.0
			speed = 75.0
			damage = 60
			radius = 65.0
			color = Color(0.86, 0.15, 0.15)
			_shoot_timer = 0.3 + randf() * 0.3
			_attack_cooldown = 1.5 + randf() * 1.0
			_attack_pattern = 0
			_phase_two = false
			GameManager.boss_active = self
			_show_boss_bar("💀 NEON OVERLORD")

	hp *= GameManager.skull_difficulty_mult * level_mult
	max_hp = hp
	damage = ceili(damage * GameManager.skull_difficulty_mult * dmg_level_mult)
	_base_color = color

	var circle := CircleShape2D.new()
	circle.radius = radius
	$CollisionShape2D.shape = circle
	$Hurtbox/CollisionShape2D.shape = circle

	queue_redraw()


func take_damage(amount: float, is_crit: bool = false, silent: bool = false, source: String = "other") -> void:
	if not alive:
		return
	hp -= amount
	flash_timer = 0.1
	if amount > 0:
		show_hp_timer = 2.0
	if not silent or is_crit:
		_spawn_floating_text(floori(amount), is_crit)
	if not silent and amount > 0:
		var valid_sources := ["wand", "shotgun", "blade", "lightning", "mine", "aura", "laser", "frost", "rocket", "boomerang", "flamethrower", "machinegun", "sniper", "nova_pulse", "blackhole", "dagger_storm", "poison_arrow", "poison_cloud", "shield_bomb"]
		if valid_sources.has(source):
			if not GameManager.damage_stats.has(source):
				GameManager.damage_stats[source] = {"hits": 0, "damage": 0.0}
			GameManager.damage_stats[source].hits += 1
			GameManager.damage_stats[source].damage += amount
	if _target and _target.life_steal > 0 and amount > 0:
		var stolen := amount * _target.life_steal
		_target.heal(stolen)
	if hp <= 0:
		_die()


func freeze(duration: float) -> void:
	freeze_timer = maxf(freeze_timer, duration)


func apply_poison(dmg: float, duration: float) -> void:
	_poison_damage += dmg
	_poison_timer = maxf(_poison_timer, duration)
	_poison_tick_timer = 0.0


func _physics_process(delta: float) -> void:
	if not alive or not _target:
		return

	if flash_timer > 0:
		flash_timer -= delta
	if freeze_timer > 0:
		freeze_timer -= delta
	if show_hp_timer > 0:
		show_hp_timer -= delta
	if _poison_timer > 0:
		_poison_timer -= delta
		_poison_tick_timer -= delta
		if _poison_tick_timer <= 0:
			_poison_tick_timer = POISON_TICK_INTERVAL
			if _poison_damage > 0:
				hp -= _poison_damage
				flash_timer = 0.1
				if hp <= 0:
					_die()
		if _poison_timer <= 0:
			_poison_damage = 0.0
			_poison_tick_timer = 0.0

	if _knockback_vel.length() > 1.0:
		velocity = _knockback_vel
		_knockback_vel *= 0.85
		move_and_slide()
		queue_redraw()
		return

	if is_boss:
		_update_boss_hp_bar()

	queue_redraw()

	var cur_speed := speed
	if freeze_timer > 0:
		cur_speed *= 0.3

	if enemy_type == Type.RANGED:
		_ai_ranged(delta, cur_speed)
	elif is_boss:
		_ai_boss(delta, cur_speed)
	else:
		_ai_chase(delta, cur_speed)

	_check_player_collision()


func _ai_chase(delta: float, cur_speed: float) -> void:
	if not _target:
		return
	var to_player := _target.global_position - global_position
	var angle := to_player.angle()
	var dist := to_player.length()

	var space := get_world_2d().direct_space_state
	var forward := to_player.normalized()

	# Cast rays in many directions to find open path
	var best_dir := forward
	var best_score := -1.0
	var ray_len := 60.0
	var test_angles := [0.0, -0.4, 0.4, -0.8, 0.8, -1.2, 1.2, -1.6, 1.6, -PI * 0.5, PI * 0.5, -PI * 0.75, PI * 0.75, PI, -PI]

	for ta in test_angles:
		var test_dir := forward.rotated(ta)
		var end_pos := global_position + test_dir * ray_len
		var query := PhysicsRayQueryParameters2D.create(global_position, end_pos)
		query.collision_mask = 32
		var result := space.intersect_ray(query)
		var clear_dist := ray_len
		if result:
			clear_dist = result.position.distance_to(global_position)

		# Score: prefer directions toward player, but reward clear paths heavily
		var toward_score := maxf(0.0, test_dir.dot(forward))
		var clear_score := clear_dist / ray_len
		var score := toward_score * 0.3 + clear_score * 0.7
		if score > best_score:
			best_score = score
			best_dir = test_dir

	var ox := global_position.x
	var oy := global_position.y
	velocity = best_dir * cur_speed
	move_and_slide()

	# Stuck detection - if barely moved, try perpendicular escape with more force
	if absf(global_position.x - ox) < 0.2 and absf(global_position.y - oy) < 0.2:
		stuck_timer += delta
		if stuck_timer > 0.08:
			if stuck_dir == 0:
				stuck_dir = 1.0 if randf() > 0.5 else -1.0
			var perp := Vector2(-forward.y, forward.x) * stuck_dir
			# Also try moving away from wall
			var wall_query := PhysicsRayQueryParameters2D.create(global_position, global_position + forward * 20.0)
			wall_query.collision_mask = 32
			var wall_result := space.intersect_ray(wall_query)
			if wall_result:
				var wall_normal: Vector2 = wall_result.get("normal", Vector2.ZERO)
				if wall_normal.length() > 0.1:
					perp = wall_normal
			velocity = perp * cur_speed * 2.0
			move_and_slide()
			if stuck_timer > 0.8:
				stuck_dir = -stuck_dir
	else:
		stuck_timer = 0.0
		stuck_dir = 0.0


func _ai_ranged(delta: float, cur_speed: float) -> void:
	if not _target:
		return
	var dist := global_position.distance_to(_target.global_position)
	var angle := global_position.direction_to(_target.global_position).angle()
	var prefer_dist := 300.0

	var to_player := _target.global_position - global_position
	var forward := to_player.normalized()

	var dir := Vector2(cos(angle), sin(angle))
	if dist < prefer_dist:
		dir = -dir
	elif dist > prefer_dist + 50:
		dir = dir * 0.3
	else:
		dir = Vector2.ZERO

	# Wall avoidance
	if dir.length() > 0.01:
		var space := get_world_2d().direct_space_state
		var best_dir := dir.normalized()
		var best_score := -1.0
		var ray_len := radius + 35.0
		var test_angles := [0.0, -0.8, 0.8, -1.5, 1.5]
		var move_forward := dir.normalized()

		for ta in test_angles:
			var test_dir := move_forward.rotated(ta)
			var end_pos := global_position + test_dir * ray_len
			var query := PhysicsRayQueryParameters2D.create(global_position, end_pos)
			query.collision_mask = 32
			var result := space.intersect_ray(query)
			var clear_dist := ray_len
			if result:
				clear_dist = result.position.distance_to(global_position)

			var toward_score := maxf(0.0, test_dir.dot(move_forward))
			var clear_score := clear_dist / ray_len
			var score := toward_score * 0.4 + clear_score * 0.6
			if score > best_score:
				best_score = score
				best_dir = test_dir

		velocity = best_dir * cur_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	_shoot_cooldown -= delta
	if _shoot_cooldown <= 0 and dist < 500:
		_shoot_cooldown = 2.0
		var proj_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
		var proj := proj_scene.instantiate()
		proj.setup(global_position, angle, 350, damage * 0.8, color, false, "ranged_enemy")
		proj.collision_layer = 8
		proj.collision_mask = 1
		get_tree().current_scene.call_deferred("add_child", proj)


func _ai_boss(delta: float, cur_speed: float) -> void:
	if not _target:
		return

	if _dash_timer > 0:
		_dash_timer -= delta
		velocity = Vector2(_dash_dx, _dash_dy)
		move_and_slide()
		_check_player_collision()
		queue_redraw()
		return

	if _attack_cooldown > 0:
		_attack_cooldown -= delta

	if _rage_mode:
		_rage_timer -= delta
		if _rage_timer <= 0:
			_rage_mode = false

	_shoot_timer -= delta
	if _shoot_timer <= 0 and _attack_cooldown <= 0:
		if is_final_boss:
			_final_boss_attack()
		else:
			_normal_boss_attack()
		_shoot_timer = 0.5 + randf() * 0.5
		_attack_cooldown = 1.0 + randf() * 0.8

	var angle := global_position.direction_to(_target.global_position).angle()
	velocity = Vector2(cos(angle), sin(angle)) * cur_speed
	move_and_slide()


func _normal_boss_attack() -> void:
	if not _target:
		return
	_attack_pattern = (_attack_pattern + 1) % 9
	var p_angle := global_position.direction_to(_target.global_position).angle()

	match _attack_pattern:
		0:
			_spawn_enemy_projectile(p_angle, 350, damage * 0.7, Color(0.96, 0.25, 0.37))
		1:
			var bc := 8 + enemy_level
			for i in bc:
				var a := (TAU / bc) * i
				_spawn_enemy_projectile(a, 200, damage * 0.5, Color(0.98, 0.45, 0.09))
		2:
			for i in range(-2, 3):
				_spawn_enemy_projectile(p_angle + i * 0.22, 320, damage * 0.55, Color(0.66, 0.33, 0.97))
		3:
			var a := p_angle
			_dash_dx = cos(a) * 350
			_dash_dy = sin(a) * 350
			_dash_timer = 0.6
		4:
			for i in range(1 + int(enemy_level / 3.0)):
				var minion := _spawn_minion("fast", enemy_level)
				minion.hp *= 4
				minion.max_hp = minion.hp
				minion.radius = 15
				minion.color = Color(0.98, 0.44, 0.52)
		5:
			for i in 3:
				var m := _spawn_enemy_projectile(randf() * TAU, 150, damage * 0.6, Color(1.0, 0.0, 1.0))
				m.radius = 12
				m.lifetime = 4.0
				m.is_homing = true
		6:
			for ring in 2:
				for i in range(-1, 2):
					_spawn_enemy_projectile(p_angle + i * 0.18, 380, damage * 0.5, Color(0.49, 0.83, 0.99))
		7:
			for i in 2:
				var _sa := p_angle + (i - 1) * 0.5
				var bomber := _spawn_minion("elite", enemy_level)
				bomber.radius = 14
				bomber.hp = 80
				bomber.max_hp = 80
				bomber.speed = 80.0
				bomber._explode_on_death = true
				bomber._explode_dmg = damage * 1.5
		8:
			for i in 14:
				var a := (TAU / 14) * i + GameManager.game_time
				_spawn_enemy_projectile(a, 250, damage * 0.4, Color(0.66, 0.33, 0.97))

	if randf() < 0.2:
		var extra := randi() % 4
		match extra:
			0: _spawn_enemy_projectile(p_angle, 400, damage * 0.5, Color(0.96, 0.25, 0.37))
			1:
				for i in 8:
					_spawn_enemy_projectile((TAU / 8) * i, 200, damage * 0.3, Color(0.98, 0.45, 0.09))
			2:
				var m := _spawn_enemy_projectile(randf() * TAU, 150, damage * 0.5, Color(1.0, 0.0, 1.0))
				m.radius = 10
				m.lifetime = 3.0
				m.is_homing = true


func _final_boss_attack() -> void:
	if not _target:
		return

	if not _phase_two and hp < max_hp * 0.5:
		_phase_two = true
		speed = 110.0
		damage = 75
		_shoot_timer = 0.4

	_attack_pattern = (_attack_pattern + 1) % 14
	var p_angle := global_position.direction_to(_target.global_position).angle()
	var p_speed := 450.0 if _phase_two else 350.0

	if hp < max_hp * 0.5 and not _rage_mode:
		_rage_mode = true
		_rage_timer = 10.0

	match _attack_pattern:
		0:
			_spawn_enemy_projectile(p_angle, p_speed, damage * 0.8, Color(0.86, 0.15, 0.15))
		1:
			var bc := 14 if _phase_two else 10
			for i in bc:
				_spawn_enemy_projectile((TAU / bc) * i + GameManager.game_time, 250, damage * 0.5, Color(0.98, 0.45, 0.09))
		2:
			for i in range(-3, 4):
				_spawn_enemy_projectile(p_angle + i * 0.2, p_speed, damage * 0.6, Color(0.66, 0.33, 0.97))
		3:
			var a := p_angle
			_dash_dx = cos(a) * 400
			_dash_dy = sin(a) * 400
			_dash_timer = 0.8
			for i in 5:
				_spawn_enemy_projectile(randf() * TAU, 180, damage * 0.4, Color(0.86, 0.15, 0.15), global_position + Vector2(cos(randf() * TAU), sin(randf() * TAU)) * 100)
		4:
			for i in 3:
				var sa := randf() * TAU
				var sd := 250.0 + randf() * 150.0
				_spawn_minion("heavy", enemy_level + 3, global_position + Vector2(cos(sa), sin(sa)) * sd)
		5:
			for ring in 3:
				var bc := 10 + ring * 3
				for i in bc:
					_spawn_enemy_projectile((TAU / bc) * i + ring * 0.25, 160.0 + ring * 60, damage * 0.35, Color(0.98, 0.75, 0.14))
		6:
			for i in 7:
				_spawn_enemy_projectile(p_angle + (i - 3) * 0.15, p_speed, damage * 0.7, Color(0.86, 0.15, 0.15))
		7:
			for i in 3:
				var m := _spawn_enemy_projectile(randf() * TAU, 180, damage * 0.5, Color(1.0, 0.0, 1.0))
				m.radius = 14
				m.lifetime = 5.0
				m.is_homing = true
		8:
			for i in 4:
				var sa := p_angle + (i - 2) * 0.5
				var bomber := _spawn_minion("elite", enemy_level, global_position + Vector2(cos(sa), sin(sa)) * 100)
				bomber.radius = 16
				bomber.hp = 200
				bomber.max_hp = 200
				bomber.speed = 80.0
				bomber._explode_on_death = true
				bomber._explode_dmg = damage * 2
		9:
			for i in 14:
				var a := randf() * TAU
				var dist := 150.0 + randf() * 350.0
				var start_pos := global_position + Vector2(cos(a), sin(a)) * dist
				var fall_angle := start_pos.direction_to(global_position).angle()
				var meteor := _spawn_enemy_projectile(fall_angle, 500, damage * 0.8, Color(1.0, 0.27, 0.0), start_pos)
				meteor.radius = 12
				meteor.lifetime = 1.2
		10:
			if _target and _target.alive:
				var vfx := _get_vfx()
				_target.take_damage(damage * 1.5)
				if vfx:
					vfx.spawn_lightning(global_position, _target.global_position)
		11:
			for ring in 3:
				var bc := 6
				for i in bc:
					_spawn_enemy_projectile((TAU / bc) * i + GameManager.game_time * 2, 220, damage * 0.4, Color(0.13, 0.77, 0.37))
		12:
			for i in 24:
				var a := (TAU / 24) * i + GameManager.game_time * 0.5
				var proj := _spawn_enemy_projectile(a, 180, damage * 0.3, Color(0.0, 0.8, 0.9))
				proj.radius = 8
		13:
			for i in 12:
				var a := p_angle + (i - 6) * 0.12
				var proj := _spawn_enemy_projectile(a, 500, damage * 0.6, Color(1.0, 0.0, 0.5))
				proj.radius = 10
				proj.lifetime = 0.8

	if randf() < 0.25:
		var extra := randi() % 6
		match extra:
			0: _spawn_enemy_projectile(p_angle, p_speed, damage * 0.5, Color(0.86, 0.15, 0.15))
			1:
				for i in 6:
					_spawn_enemy_projectile((TAU / 6) * i + GameManager.game_time, 220, damage * 0.3, Color(0.98, 0.45, 0.09))
			2:
				for i in range(-1, 2):
					_spawn_enemy_projectile(p_angle + i * 0.25, p_speed, damage * 0.4, Color(0.66, 0.33, 0.97))
			3:
				for i in 3:
					var m := _spawn_enemy_projectile(randf() * TAU, 150, damage * 0.4, Color(1.0, 0.0, 1.0))
					m.radius = 10
					m.lifetime = 4.0
					m.is_homing = true
			4:
				pass

	if _phase_two:
		var extra2 := randi() % 3
		match extra2:
			0:
				for i in 2:
					var m := _spawn_minion("fast", enemy_level, global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50)))
					m.hp *= 3
					m.max_hp = m.hp
			1:
				for i in range(-2, 3):
					_spawn_enemy_projectile(p_angle + i * 0.2, 380, damage * 0.6, Color(0.86, 0.15, 0.15))
			2:
				pass

	_shoot_timer = 0.25 + randf() * 0.2 if _phase_two else 0.4 + randf() * 0.3
	_attack_cooldown = 1.5 + randf() * 1.0



func _spawn_enemy_projectile(angle: float, proj_speed: float, dmg: float, col: Color, pos: Vector2 = Vector2.ZERO) -> Node2D:
	var proj_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
	var proj := proj_scene.instantiate()
	var spawn_pos := pos if pos != Vector2.ZERO else global_position
	proj.setup(spawn_pos, angle, proj_speed, dmg, col, false, "boss_projectile")
	proj.radius = 6
	proj.collision_layer = 8
	proj.collision_mask = 1
	get_tree().current_scene.call_deferred("add_child", proj)
	return proj


func _spawn_minion(type_str: String, level: int, spawn_pos: Vector2 = Vector2.ZERO) -> Node2D:
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")
	var minion := enemy_scene.instantiate()
	minion.add_to_group("enemies")
	var pos := spawn_pos if spawn_pos != Vector2.ZERO else global_position
	minion.global_position = pos
	match type_str:
		"fast":
			minion.setup(Type.FAST, level)
		"heavy":
			minion.setup(Type.HEAVY, level)
		"elite":
			minion.setup(Type.ELITE, level)
		_:
			minion.setup(Type.NORMAL, level)
	get_tree().current_scene.call_deferred("add_child", minion)
	return minion


func _get_enemies_in_range(max_dist: float) -> Array:
	var result := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and e.alive and e != self:
			if global_position.distance_to(e.global_position) < max_dist:
				result.append(e)
	return result


func _check_player_collision() -> void:
	if not _target or not alive:
		return
	if global_position.distance_to(_target.global_position) < radius + _target.stats.radius:
		if _target._melee_damage_cooldown <= 0:
			_target._melee_damage_cooldown = 0.5
			_target.take_damage(damage)


func _die() -> void:
	alive = false
	GameManager.kill_count += GameManager.skull_score_mult
	died.emit(self)

	var vfx := _get_vfx()
	AudioManager.play_sfx(AudioManager.SFXType.ENEMY_DEATH)

	if is_final_boss:
		GameManager.boss_active = null
		GameManager.first_boss_killed = true
		GameManager.special_wave_active = true
		GameManager.add_coins(50)
		_hide_boss_bar()
		if vfx:
			vfx.spawn_particles(global_position, Color(0.86, 0.15, 0.15), 200, 400)
			vfx.spawn_particles(global_position, Color(0.98, 0.75, 0.14), 100, 300)
			vfx.spawn_nova(global_position, 300, Color(0.98, 0.75, 0.14))
		for i in 30:
			_spawn_gem_at(12)
		for i in 30:
			_spawn_gem_at(12)
		_spawn_chest(3)
		GameManager.pressure_wave_active = true
		GameManager.pressure_wave_timer = 5.0
		if GameManager.current_level < 4:
			GameManager.request_next_level(global_position)
		queue_free()
		return

	if is_boss:
		GameManager.boss_active = null
		GameManager.first_boss_killed = true
		GameManager.add_coins(25)
		_hide_boss_bar()
		GameManager.pressure_wave_active = true
		GameManager.pressure_wave_timer = 5.0
		if vfx:
			vfx.spawn_particles(global_position, color, 100, 200)
			vfx.spawn_nova(global_position, 150, color)
		for i in 20:
			_spawn_gem_at(10)
		_spawn_chest(2)
		queue_free()
		return

	if is_elite:
		GameManager.add_coins(5)
	elif randf() < 0.25:
		GameManager.add_coins(1)

	var gem_val := 2
	match enemy_type:
		Type.HEAVY: gem_val = 8
		Type.FAST: gem_val = 4
		Type.ELITE: gem_val = 15
		Type.SPECIAL: gem_val = 12

	if vfx:
		var p_count := 12
		var p_speed := 60.0
		if is_elite:
			p_count = 30
			p_speed = 80.0
			if randf() < 0.08:
				_spawn_chest(1)
		elif enemy_type == Type.NORMAL or enemy_type == Type.FAST or enemy_type == Type.HEAVY or enemy_type == Type.RANGED:
			if randf() < 0.02:
				_spawn_chest(1)
		elif is_special:
			p_count = 25
			p_speed = 90.0
		vfx.spawn_particles(global_position, color, p_count, p_speed)

	if _explode_on_death and _target and is_instance_valid(_target):
		var explode_range := 100.0
		if global_position.distance_to(_target.global_position) < explode_range:
			_target.take_damage(_explode_dmg)
			if vfx:
				vfx.spawn_nova(global_position, explode_range, Color(1.0, 0.4, 0.0))

	_spawn_gems(gem_val)
	queue_free()


func _spawn_gem_at(val: int) -> void:
	var gem_scene: PackedScene = preload("res://scenes/world/gem.tscn")
	var gem := gem_scene.instantiate()
	gem.global_position = _clamp_arena_pos(global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50)))
	gem.value = val
	get_tree().current_scene.call_deferred("add_child", gem)


func _spawn_gems(base_val: int) -> void:
	var gem_scene: PackedScene = preload("res://scenes/world/gem.tscn")
	var count := 1
	if is_elite:
		count = 5
	elif is_special:
		count = 3
	elif enemy_type == Type.NORMAL and randf() < 0.1:
		count = 2

	for i in count:
		var offset := Vector2(randf_range(-20, 20), randf_range(-20, 20))
		var gem := gem_scene.instantiate()
		gem.global_position = _clamp_arena_pos(global_position + offset)
		gem.value = base_val
		get_parent().call_deferred("add_child", gem)

	if is_boss:
		_spawn_powerup(global_position + Vector2(80, 0))
	elif is_elite:
		var r := randf()
		if r < 0.4:
			_spawn_powerup(global_position, GroundPowerup.Type.HP)
		elif r < 0.7:
			_spawn_powerup(global_position, GroundPowerup.Type.MAGNET)
		else:
			_spawn_powerup(global_position, GroundPowerup.Type.BOMB)
	elif is_special and randf() < 0.15:
		_spawn_powerup(global_position)
	elif not is_boss and not is_elite and not is_special and randf() < 0.008:
		_spawn_powerup(global_position)


func _spawn_powerup(pos: Vector2 = Vector2.ZERO, override_type: int = -1) -> void:
	var pu_scene: PackedScene = preload("res://scenes/world/ground_powerup.tscn")
	var pu := pu_scene.instantiate()
	pu.global_position = pos if pos != Vector2.ZERO else global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	if override_type >= 0:
		pu.type = override_type
	else:
		pu.type = randi() % 3
	get_parent().call_deferred("add_child", pu)


func _spawn_floating_text(amount: int, is_crit: bool) -> void:
	var text_scene: PackedScene = preload("res://scenes/effects/floating_text.tscn")
	var ft := text_scene.instantiate()
	ft.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	ft.setup(str(amount), Color("#fde047") if is_crit else Color("#e2e8f0"), 22 if is_crit else 14)
	get_parent().call_deferred("add_child", ft)


func _draw() -> void:
	var draw_color := _base_color
	if flash_timer > 0:
		draw_color = Color.WHITE
	elif freeze_timer > 0:
		draw_color = Color(0.49, 0.83, 0.99)

	if is_final_boss:
		var pulse := 1.0 + 0.05 * sin(Time.get_ticks_msec() / 100.0)
		draw_circle(Vector2.ZERO, radius * pulse, draw_color)
		draw_arc(Vector2.ZERO, radius * pulse, 0, TAU, 32, Color(0.98, 0.75, 0.14), 5.0)
		draw_arc(Vector2.ZERO, radius * pulse + 12, 0, TAU, 32, Color(0.86, 0.15, 0.15, 0.3 + 0.3 * sin(Time.get_ticks_msec() / 200.0)), 3.0)
		return

	if is_boss:
		draw_circle(Vector2.ZERO, radius, draw_color)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color.WHITE, 4.0)
	else:
		match enemy_type:
			Type.HEAVY:
				draw_rect(Rect2(-radius, -radius, radius * 2, radius * 2), draw_color)
			Type.RANGED:
				var pts := PackedVector2Array([
					Vector2(0, -radius),
					Vector2(radius, 0),
					Vector2(0, radius),
					Vector2(-radius, 0)
				])
				draw_colored_polygon(pts, draw_color)
			_:
				draw_circle(Vector2.ZERO, radius, draw_color)

	if is_elite:
		var crown_color := Color(0.98, 0.75, 0.14)
		var crown_y := -radius - 8
		draw_rect(Rect2(-10, crown_y + 6, 20, 4), crown_color)
		for i in 3:
			var cx := -8 + i * 8
			var cy := crown_y + (0 if i == 1 else 4)
			draw_rect(Rect2(cx - 2, cy - 6, 4, 10), crown_color)
			draw_circle(Vector2(cx, cy - 6), 3, crown_color)

	if (hp < max_hp or show_hp_timer > 0) and not is_boss and not is_final_boss:
		var bar_w := maxf(35, radius * 2.5)
		var bar_h := 5.0
		var bar_y := -radius - 14.0
		var bar_x := -bar_w * 0.5
		draw_rect(Rect2(bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2), Color.BLACK)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.27, 0.04, 0.04))
		var hp_frac := clampf(hp / max_hp, 0, 1)
		draw_rect(Rect2(bar_x, bar_y, bar_w * hp_frac, bar_h), Color(0.86, 0.15, 0.15))

	if _poison_timer > 0:
		var t := Time.get_ticks_msec() / 100.0
		for i in 3:
			var a := t * 2.0 + (TAU / 3) * i
			var r := radius * 0.6
			var px := cos(a) * r
			var py := sin(a) * r
			draw_circle(Vector2(px, py), 2.5, Color(0.0, 0.5, 0.0, 0.8))


func _get_vfx() -> Node2D:
	var gw := get_tree().current_scene
	if gw and gw.has_node("VFXManager"):
		return gw.get_node("VFXManager")
	return null


func _show_boss_bar(boss_name: String) -> void:
	var gw := get_tree().current_scene
	if gw and gw.has_node("HUD"):
		var hud := gw.get_node("HUD")
		if hud.has_method("show_boss_bar"):
			hud.show_boss_bar(boss_name)


func _update_boss_hp_bar() -> void:
	var gw := get_tree().current_scene
	if gw and gw.has_node("HUD"):
		var hud := gw.get_node("HUD")
		if hud.has_method("update_boss_hp"):
			hud.update_boss_hp(clampf(hp / max_hp, 0.0, 1.0))
		if hud.has_method("update_boss_poison"):
			hud.update_boss_poison(_poison_damage)


func _hide_boss_bar() -> void:
	var gw := get_tree().current_scene
	if gw and gw.has_node("HUD"):
		var hud := gw.get_node("HUD")
		if hud.has_method("hide_boss_bar"):
			hud.hide_boss_bar()


func _spawn_chest(rarity: int) -> void:
	var gw := get_tree().current_scene
	if gw and gw.has_node("SpecialManager"):
		var sm := gw.get_node("SpecialManager")
		if sm.has_method("spawn_chest"):
			sm.spawn_chest(_clamp_arena_pos(global_position), rarity)


func _clamp_arena_pos(pos: Vector2) -> Vector2:
	if GameManager.current_level == 4:
		var half := 870.0
		return Vector2(clampf(pos.x, -half, half), clampf(pos.y, -half, half))
	return pos
