extends Node2D

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/projectile.tscn")

var player: Player = null
var weapons: Array[WeaponData] = []
var blade_angle: float = 0.0
var blackholes: Array[Dictionary] = []
var _blade_positions: Array[Vector2] = []
var _blade_range: float = 0.0
var _nova_pulse_timer: float = 5.0


func setup(p: Player) -> void:
	player = p
	var all := WeaponData.get_all_weapons()
	weapons.clear()
	for w in all:
		w.level = 0
		w.timer = 0.0
		weapons.append(w)


func add_weapon(weapon_id: String) -> void:
	for w in weapons:
		if w.id == weapon_id:
			w.level = 1
			return


func upgrade_weapon(weapon_id: String) -> void:
	for w in weapons:
		if w.id == weapon_id and w.level > 0 and w.level < w.max_level:
			w.level += 1
			return


func get_active_weapons() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for w in weapons:
		if w.level > 0:
			result.append(w)
	return result


func _physics_process(delta: float) -> void:
	if not player or GameManager.current_state != GameManager.GameState.PLAYING:
		return

	if GameManager.death_timer >= 0:
		return

	for w in weapons:
		if w.level <= 0:
			continue

		if w.id == "blade":
			blade_angle += (3.0 * player.attack_speed_mult) * delta
			_process_blade(w, delta)
			continue

		if w.id == "nova_pulse":
			_nova_pulse_timer -= delta
			if _nova_pulse_timer <= 0:
				_nova_pulse_timer = 5.0
				_fire_nova_pulse(w, player.global_position, w.get_damage(player), false)
			continue

		w.timer -= delta
		if w.timer <= 0:
			w.timer = w.get_cooldown(player)
			_fire_weapon(w)

	_process_blackholes(delta)
	queue_redraw()


func _get_nearest_enemy(pos: Vector2, max_range: float) -> Enemy:
	var best: Enemy = null
	var best_dist := max_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and e.alive:
			var d := pos.distance_to(e.global_position)
			if d < best_dist:
				best_dist = d
				best = e
	return best


func _get_enemies_in_range(pos: Vector2, max_range: float) -> Array:
	var result := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and e.alive and pos.distance_to(e.global_position) < max_range:
			result.append(e)
	return result


func _spawn_projectile(pos: Vector2, angle: float, speed: float, dmg: float, col: Color, crit: bool, src: String, delay: float = 0.0) -> void:
	var proj := PROJECTILE_SCENE.instantiate()
	proj.setup(pos, angle, speed, dmg, col, crit, src)
	proj.launch_delay = delay
	get_tree().current_scene.call_deferred("add_child", proj)


func _fire_weapon(w: WeaponData) -> void:
	var pos := player.global_position
	var is_crit: bool = randf() < player.crit_chance
	var base_dmg := w.get_damage(player)
	var rng := w.get_range()
	var target := _get_nearest_enemy(pos, rng)

	match w.id:
		"wand":
			_fire_wand(w, target, pos, base_dmg, is_crit)
		"shotgun":
			_fire_shotgun(w, target, pos, base_dmg, is_crit)
		"lightning":
			_fire_lightning(w, target, pos, base_dmg, is_crit)
		"mine":
			_fire_mine(w, pos, base_dmg)
		"aura":
			_fire_aura(w, pos, base_dmg)
		"laser":
			_fire_laser(w, target, pos, base_dmg, is_crit)
		"frost":
			_fire_frost(w, target, pos, base_dmg, is_crit)
		"rocket":
			_fire_rocket(w, target, pos, base_dmg, is_crit)
		"boomerang":
			_fire_boomerang(w, target, pos, base_dmg, is_crit)
		"flamethrower":
			_fire_flamethrower(w, target, pos, base_dmg)
		"machinegun":
			_fire_machinegun(w, target, pos, base_dmg, is_crit)
		"sniper":
			_fire_sniper(w, target, pos, base_dmg, is_crit)
		"nova_pulse":
			_fire_nova_pulse(w, pos, base_dmg, is_crit)
		"blackhole":
			_fire_blackhole(w, target, pos, base_dmg, is_crit)
		"dagger_storm":
			_fire_dagger_storm(w, pos, base_dmg, is_crit)
		"poison_arrow":
			_fire_poison_arrow(w, target, pos, base_dmg, is_crit)


func _fire_wand(w: WeaponData, target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	for i in player.projectile_count:
		var t: Enemy = target if target else _get_nearest_enemy(pos, w.get_range())
		if not t:
			continue
		var angle := pos.direction_to(t.global_position).angle()
		_spawn_projectile(pos, angle, 450, dmg * pow(0.7, i), Color(0.133, 0.827, 0.933), crit, "wand", i * 0.12)


func _fire_shotgun(w: WeaponData, target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	var base_angle := pos.direction_to(target.global_position).angle() if target else randf() * TAU
	var count := 5 + w.level
	if player.projectile_count > 1:
		var targets: Array = _get_enemies_in_range(pos, w.get_range() * player.aoe_mult)
		targets.shuffle()
		for shot_idx in player.projectile_count:
			var t: Enemy = targets[shot_idx % max(targets.size(), 1)] if targets.size() > 0 else target
			var t_angle := pos.direction_to(t.global_position).angle() if t else base_angle
			for i in count:
				var angle := t_angle + (i - count / 2.0) * 0.08
				_spawn_projectile(pos, angle, 500, dmg * pow(0.5, i), Color(0.98, 0.75, 0.14), crit, "shotgun", shot_idx * 0.12)
	else:
		for i in count:
			var angle := base_angle + (i - count / 2.0) * 0.08
			_spawn_projectile(pos, angle, 500, dmg * pow(0.5, i), Color(0.98, 0.75, 0.14), crit, "shotgun")


func _fire_lightning(w: WeaponData, _target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	var vfx := _get_vfx()
	var enemies := _get_enemies_in_range(pos, w.get_range())
	if enemies.size() == 0:
		return
	enemies.shuffle()
	var last: Enemy = enemies[0]
	last.take_damage(dmg, crit, false, "lightning")
	if vfx:
		vfx.spawn_lightning(pos, last.global_position)
	for i in 3 + w.level:
		var next: Enemy = null
		var best_dist := w.get_range()
		for e in enemies:
			if e != last and e.alive:
				var d := last.global_position.distance_to(e.global_position)
				if d < best_dist:
					best_dist = d
					next = e
		if next:
			next.take_damage(dmg * 0.8, crit, false, "lightning")
			if vfx:
				vfx.spawn_lightning(last.global_position, next.global_position)
			last = next


func _fire_mine(_w: WeaponData, pos: Vector2, dmg: float) -> void:
	var proj := PROJECTILE_SCENE.instantiate()
	proj.setup(pos, 0, 0, dmg * 1.5, Color(0.98, 0.80, 0.14), false, "mine")
	proj.lifetime = 8.0
	proj.radius = 16.0 * player.aoe_mult
	proj.aoe_radius = 175.0 * player.aoe_mult
	get_tree().current_scene.call_deferred("add_child", proj)


func _fire_aura(_w: WeaponData, pos: Vector2, dmg: float) -> void:
	var enemies := _get_enemies_in_range(pos, _w.get_range() * player.aoe_mult)
	for e in enemies:
		e.take_damage(dmg * 0.4, false, true, "aura")


func _fire_laser(_w: WeaponData, _target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	var targets := _get_enemies_in_range(pos, _w.get_range() * player.aoe_mult)
	targets.shuffle()
	var count := mini(player.projectile_count + int(_w.level / 2.0), targets.size())
	var vfx := _get_vfx()
	for i in count:
		var t: Enemy = targets[i]
		t.take_damage(dmg * 1.5, crit, false, "laser")
		if vfx:
			vfx.spawn_laser(t.global_position, 40)
		for e in _get_enemies_in_range(t.global_position, 40):
			if e != t:
				e.take_damage(dmg * 0.5, false, false, "laser")


func _fire_frost(w: WeaponData, _target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	var rng := w.get_range() * player.aoe_mult
	var enemies := _get_enemies_in_range(pos, rng)
	var vfx := _get_vfx()
	for e in enemies:
		e.take_damage(dmg, crit, false, "frost")
		e.freeze(3.0)
	if vfx:
		vfx.spawn_nova(pos, rng, Color(0.49, 0.83, 0.99))


func _fire_rocket(_w: WeaponData, target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	if not target:
		return
	var targets: Array = _get_enemies_in_range(pos, _w.get_range() * player.aoe_mult)
	targets.shuffle()
	for i in player.projectile_count:
		var t: Enemy = targets[i] if i < targets.size() else target
		if not t:
			continue
		var angle := pos.direction_to(t.global_position).angle()
		var proj := PROJECTILE_SCENE.instantiate()
		proj.setup(pos, angle, 400, dmg * pow(0.7, i), Color(0.98, 0.45, 0.09), crit, "rocket")
		proj.radius = 7
		proj.aoe_radius = 100.0 * player.aoe_mult
		proj.aoe_damage_mult = 0.8
		proj.launch_delay = i * 0.12
		get_tree().current_scene.call_deferred("add_child", proj)


func _fire_boomerang(_w: WeaponData, target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	if not target:
		return
	var targets: Array = _get_enemies_in_range(pos, _w.get_range())
	targets.shuffle()
	for i in player.projectile_count:
		var t: Enemy = targets[i] if i < targets.size() else target
		if not t:
			continue
		var angle := pos.direction_to(t.global_position).angle()
		var proj := PROJECTILE_SCENE.instantiate()
		proj.setup(pos, angle, 500, dmg * pow(0.7, i), Color(0.65, 0.55, 0.98), crit, "boomerang")
		proj.is_boomerang = true
		proj.lifetime = 1.5
		proj.launch_delay = i * 0.12
		get_tree().current_scene.call_deferred("add_child", proj)


func _fire_flamethrower(w: WeaponData, target: Enemy, pos: Vector2, dmg: float) -> void:
	var targets: Array = _get_enemies_in_range(pos, w.get_range())
	targets.shuffle()
	var cone_count := player.projectile_count
	if cone_count == 0:
		cone_count = 1
	for c in cone_count:
		var t: Enemy = targets[c] if c < targets.size() else target
		var base_angle := pos.direction_to(t.global_position).angle() if t else randf() * TAU
		var pellet_count := 2 + w.level
		for i in pellet_count:
			var angle := base_angle + randf_range(-0.3, 0.3)
			var proj := PROJECTILE_SCENE.instantiate()
			proj.setup(pos, angle, 300 + randf() * 100, dmg * 0.5 * pow(0.5, i), Color(0.98, 0.45, 0.09), false, "flamethrower")
			proj.radius = 4
			proj.lifetime = 0.3 + randf() * 0.2
			proj.is_flame = true
			proj.launch_delay = c * 0.12
			get_tree().current_scene.call_deferred("add_child", proj)


func _fire_machinegun(_w: WeaponData, target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	var targets: Array = _get_enemies_in_range(pos, _w.get_range())
	targets.shuffle()
	for i in player.projectile_count:
		var t: Enemy = targets[i] if i < targets.size() else target
		if not t:
			continue
		var angle := pos.direction_to(t.global_position).angle() + randf_range(-0.05, 0.05)
		var proj := PROJECTILE_SCENE.instantiate()
		proj.setup(pos, angle, 800, dmg * pow(0.7, i), Color(0.98, 0.75, 0.14), crit, "machinegun")
		proj.radius = 4
		proj.lifetime = 1.5
		proj.launch_delay = i * 0.12
		get_tree().current_scene.call_deferred("add_child", proj)


func _fire_sniper(_w: WeaponData, target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	if not target:
		return
	var targets: Array = _get_enemies_in_range(pos, _w.get_range())
	targets.shuffle()
	for i in player.projectile_count:
		var t: Enemy = targets[i] if i < targets.size() else target
		if not t:
			continue
		var proj := PROJECTILE_SCENE.instantiate()
		proj.setup(pos, pos.direction_to(t.global_position).angle(), 1400, dmg * pow(0.7, i), Color(0.88, 0.95, 1.0), crit, "sniper")
		proj.radius = 5
		proj.lifetime = 1.0
		proj.is_pierce = _w.level >= 2
		proj.launch_delay = i * 0.12
		get_tree().current_scene.call_deferred("add_child", proj)


func _fire_nova_pulse(w: WeaponData, pos: Vector2, dmg: float, _crit: bool) -> void:
	var rng := (w.get_range() + w.level * 30) * player.aoe_mult
	var vfx := _get_vfx()
	if vfx:
		vfx.spawn_nova(pos, rng, Color(0.75, 0.52, 0.99))
	var enemies := _get_enemies_in_range(pos, rng)
	for e in enemies:
		e.take_damage(dmg, false, true, "nova_pulse")
		var dir: Vector2 = e.global_position.direction_to(pos)
		e._knockback_vel = -dir * 300.0


func _fire_blackhole(w: WeaponData, target: Enemy, pos: Vector2, dmg: float, _crit: bool) -> void:
	var bh_pos := target.global_position if target else pos
	var vfx := _get_vfx()
	if vfx:
		vfx.spawn_particles(bh_pos, Color(0.49, 0.23, 0.93), 20, 120)
	blackholes.append({
		"pos": bh_pos,
		"range": (w.get_range() + w.level * 20) * 0.3 * player.aoe_mult,
		"dmg": dmg * 0.15,
		"life": 3.0,
		"tick_timer": 0.0,
	})


func _fire_dagger_storm(w: WeaponData, pos: Vector2, dmg: float, crit: bool) -> void:
	var count := 8 + (w.level - 1) * 2 + player.projectile_count * 2
	for i in count:
		var angle := (TAU / count) * i
		var proj := PROJECTILE_SCENE.instantiate()
		proj.setup(pos, angle, 600, dmg * pow(0.5, i), Color(0.98, 0.45, 0.09), crit, "dagger_storm")
		proj.radius = 5
		proj.lifetime = 1.0
		get_tree().current_scene.call_deferred("add_child", proj)


func _fire_poison_arrow(_w: WeaponData, target: Enemy, pos: Vector2, dmg: float, crit: bool) -> void:
	if not target:
		return
	var targets: Array = _get_enemies_in_range(pos, _w.get_range())
	targets.shuffle()
	for i in player.projectile_count:
		var t: Enemy = targets[i] if i < targets.size() else target
		if not t:
			continue
		var proj := PROJECTILE_SCENE.instantiate()
		proj.setup(pos, pos.direction_to(t.global_position).angle(), 500, dmg * pow(0.7, i), Color(0.13, 0.77, 0.37), crit, "poison_arrow")
		proj.radius = 5
		proj.lifetime = 1.2
		proj.poison_percent = 0.2
		proj.poison_duration = 5.0
		proj.launch_delay = i * 0.12
		get_tree().current_scene.call_deferred("add_child", proj)


func _process_blade(w: WeaponData, _delta: float) -> void:
	var count := 1 + int(w.level / 2.0) + player.projectile_count - 1
	var blade_range := w.get_range() * player.aoe_mult
	_blade_range = blade_range
	_blade_positions.clear()

	for i in count:
		var a := blade_angle + (TAU / count) * i
		var bx := player.global_position.x + cos(a) * blade_range
		var by := player.global_position.y + sin(a) * blade_range
		_blade_positions.append(Vector2(bx, by))

		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Enemy and e.alive:
				if Vector2(bx, by).distance_to(e.global_position) < 25 * player.aoe_mult + e.radius:
					e.take_damage(w.get_damage(player) * 0.1, false, true, "blade")

	queue_redraw()


func _process_blackholes(delta: float) -> void:
	var to_remove := []
	for i in blackholes.size():
		var bh: Dictionary = blackholes[i]
		bh.life -= delta
		bh.tick_timer -= delta
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Enemy and e.alive:
				var d: float = e.global_position.distance_to(bh.pos)
				if d < bh.range:
					if bh.tick_timer <= 0:
						e.take_damage(bh.dmg, false, true, "blackhole")
					if d > 5:
						var pull_strength: float = (1.0 - d / bh.range) * 350.0
						var dir: Vector2 = e.global_position.direction_to(bh.pos)
						e.global_position += dir * pull_strength * delta
		if bh.life <= 0:
			to_remove.append(i)
	for i in range(to_remove.size() - 1, -1, -1):
		blackholes.remove_at(to_remove[i])


func _get_vfx() -> Node2D:
	var gw := get_tree().current_scene
	if gw and gw.has_node("VFXManager"):
		return gw.get_node("VFXManager")
	return null


func _draw() -> void:
	if not player:
		return
	for bh in blackholes:
		var local_pos := to_local(bh.pos)
		var r: float = bh.range
		draw_circle(local_pos, r, Color(0.49, 0.23, 0.93, 0.12))
		draw_arc(local_pos, r, 0, TAU, 32, Color(0.49, 0.23, 0.93, 0.35), 2.0)
		var spiral_points: int = 40
		var spiral_arms: int = 3
		var spiral_max_angle: float = TAU * 3.0
		var t := Time.get_ticks_msec() / 1000.0
		for arm in spiral_arms:
			var arm_offset: float = arm * TAU / float(spiral_arms) + t * 2.0
			var points := PackedVector2Array()
			for i in spiral_points:
				var frac: float = float(i) / float(spiral_points)
				var angle: float = arm_offset + frac * spiral_max_angle
				var sr: float = frac * r * 0.85
				points.append(local_pos + Vector2(cos(angle), sin(angle)) * sr)
			draw_polyline(points, Color(0.6, 0.3, 1.0, 0.4), 1.5)

	for pos in _blade_positions:
		draw_circle(to_local(pos), 8, Color(0.75, 0.95, 1.0, 0.6))

	var wm := player.get_node_or_null("WeaponManager")
	if wm:
		for w in wm.get_active_weapons():
			match w.id:
				"aura":
					var aura_rng: float = w.get_range() * player.aoe_mult
					draw_circle(Vector2.ZERO, aura_rng, Color(0.3, 0.9, 0.3, 0.08))
					draw_arc(Vector2.ZERO, aura_rng, 0, TAU, 32, Color(0.3, 0.9, 0.3, 0.25), 2.0)
