class_name Player
extends CharacterBody2D

@onready var shape_drawer: Node2D = $ShapeDrawer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_collision: CollisionShape2D = $PickupArea/CollisionShape2D
@onready var weapon_orbit: Node2D = $WeaponOrbit
@onready var weapon_manager: Node2D = $WeaponManager
@onready var ultimate_timer_node: Timer = $UltimateTimer

var stats: PlayerStats
var shape_name: String = "circle"

var hp: float = 120.0
var level: int = 1
var xp: int = 0
var xp_needed: int = 30
var pickup_radius: float = 100.0
var damage_mult: float = 1.0
var attack_speed_mult: float = 1.0
var projectile_count: int = 1
var aoe_mult: float = 1.0
var crit_chance: float = 0.0
var crit_mult: float = 2.0
var invincible_timer: float = 0.0
var joystick_direction: Vector2 = Vector2.ZERO
var _melee_damage_cooldown: float = 0.0
var _input_block_timer: float = 0.0

var max_shield: float = 0.0
var shield: float = 0.0
var shield_regen: float = 0.0
var shield_regen_timer: float = 0.0
var life_steal: float = 0.0
var hp_regen: float = 0.0
var xp_boost: float = 1.0
var evasion: float = 0.0
var armor: float = 0.0

var weapons: Array = []
var passives: Array = []

signal hp_changed(current: float, maximum: float)
signal shield_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int)
signal level_changed(new_level: int)
signal died
signal ultimate_changed(current: float, maximum: float)
signal ultimate_activated
signal ultimate_deactivated

var ultimate_max: float = 50.0
var ultimate_charge: float = 0.0
var ultimate_active: bool = false
var ultimate_timer: float = 0.0
const ULTIMATE_DURATION: float = 5.0


func setup(shape: String) -> void:
	shape_name = shape
	stats = PlayerStats.get_stats_for_shape(shape)

	# Apply meta stats
	var meta := GameManager.meta_stats
	stats.speed *= 1.0 + meta.get("speed", 0) * 0.05
	stats.max_hp += meta.get("max_hp", 0) * 10
	damage_mult += meta.get("damage", 0) * 0.05
	attack_speed_mult += meta.get("atk_speed", 0) * 0.05
	crit_chance += meta.get("crit_chance", 0) * 0.03

	hp = stats.max_hp
	if pickup_collision.shape:
		pickup_collision.shape.radius = pickup_radius

	match shape:
		"circle":
			shape_drawer.shape_type = 0
		"triangle":
			shape_drawer.shape_type = 1
		"square":
			shape_drawer.shape_type = 2
			max_shield = 25.0
			shield = 25.0
			shield_regen = 8.0

	shape_drawer.shape_color = stats.color
	shape_drawer.shape_radius = stats.radius
	shape_drawer.queue_redraw()

	var circle_shape := CircleShape2D.new()
	circle_shape.radius = stats.radius
	collision_shape.shape = circle_shape

	weapon_manager.setup(self)
	weapon_manager.add_weapon(GameManager.selected_weapon)

	hp_changed.emit(hp, stats.max_hp)
	if max_shield > 0:
		shield_changed.emit(shield, max_shield)


func block_inputs(duration: float) -> void:
	_input_block_timer = duration


func _physics_process(delta: float) -> void:
	if ultimate_active:
		ultimate_timer -= delta
		if ultimate_timer <= 0:
			ultimate_active = false
			attack_speed_mult /= 2.0
			ultimate_deactivated.emit()
			ultimate_changed.emit(ultimate_charge, ultimate_max)

	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	if _input_block_timer > 0:
		_input_block_timer -= delta

	if invincible_timer > 0:
		invincible_timer -= delta
		shape_drawer.visible = fmod(Time.get_ticks_msec() / 150.0, 2.0) < 1.0
	elif ultimate_active:
		shape_drawer.visible = true
		shape_drawer.ultimate_active = true
		shape_drawer.queue_redraw()
	else:
		shape_drawer.visible = true
		if shape_drawer.ultimate_active:
			shape_drawer.ultimate_active = false
		if shape_name == "square" and max_shield > 0:
			shape_drawer.queue_redraw()

	if _melee_damage_cooldown > 0:
		_melee_damage_cooldown -= delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if joystick_direction.length() > 0.1:
		input_dir = joystick_direction.normalized()
	velocity = input_dir * stats.speed
	move_and_slide()

	if hp_regen > 0 and hp < stats.max_hp:
		hp = minf(stats.max_hp, hp + hp_regen * delta)
		hp_changed.emit(hp, stats.max_hp)

	if max_shield > 0 and shield < max_shield:
		shield_regen_timer -= delta
		if shield_regen_timer <= 0:
			shield = minf(max_shield, shield + shield_regen * delta)
			shield_changed.emit(shield, max_shield)

	if stats.max_hp > 0:
		hp = clampf(hp, 0, stats.max_hp)

	if shape_name == "circle" and Input.is_action_just_pressed("ultimate") and not ultimate_active and ultimate_charge >= ultimate_max and _input_block_timer <= 0 and GameManager.unlocked_ultimates.has("circle"):
		activate_ultimate()

	if shape_name == "square" and Input.is_action_just_pressed("ultimate") and not ultimate_active and ultimate_charge >= ultimate_max and _input_block_timer <= 0 and GameManager.unlocked_ultimates.has("square"):
		activate_shield_bomb()

	if shape_name == "triangle" and Input.is_action_just_pressed("ultimate") and not ultimate_active and ultimate_charge >= ultimate_max and _input_block_timer <= 0 and GameManager.unlocked_ultimates.has("triangle"):
		activate_poison_cloud()


func take_damage(amount: float) -> void:
	if invincible_timer > 0:
		return
	if randf() < evasion:
		return

	var dmg_left := maxf(1.0, amount - armor)

	if shield > 0:
		var absorbed := minf(shield, dmg_left)
		shield -= absorbed
		dmg_left -= absorbed
		shield_regen_timer = 4.0
		shield_changed.emit(shield, max_shield)
		if dmg_left <= 0:
			return

	hp -= dmg_left
	invincible_timer = 0.5
	hp_changed.emit(hp, stats.max_hp)

	var gw := get_tree().current_scene
	if gw and gw.has_node("Camera2D"):
		gw.get_node("Camera2D").shake(5.0)

	if hp <= 0:
		died.emit()
		GameManager.trigger_game_over()


func gain_xp(amount: int) -> void:
	xp += int(amount * xp_boost * GameManager.skull_difficulty_mult)
	if xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = int((xp_needed + 50) * 1.10)
		level_changed.emit(level)
		xp_changed.emit(xp, xp_needed)
		GameManager.change_state(GameManager.GameState.LEVEL_UP)
		get_tree().paused = true
		var lu_scene: PackedScene = preload("res://scenes/ui/level_up.tscn")
		var lu := lu_scene.instantiate()
		get_tree().current_scene.call_deferred("add_child", lu)
	xp_changed.emit(xp, xp_needed)


func heal(amount: float) -> void:
	hp = minf(stats.max_hp, hp + amount)
	hp_changed.emit(hp, stats.max_hp)


func add_max_hp(amount: int) -> void:
	stats.max_hp += amount
	hp = minf(stats.max_hp, hp + amount)
	hp_changed.emit(hp, stats.max_hp)


func charge_ultimate(amount: float = 1.0) -> void:
	if (shape_name != "circle" and shape_name != "square" and shape_name != "triangle") or ultimate_active:
		return
	if not GameManager.unlocked_ultimates.has(shape_name):
		return
	ultimate_charge = minf(ultimate_max, ultimate_charge + amount)
	ultimate_changed.emit(ultimate_charge, ultimate_max)


func activate_ultimate() -> void:
	ultimate_active = true
	ultimate_timer = ULTIMATE_DURATION
	attack_speed_mult *= 2.0
	ultimate_charge = 0.0
	ultimate_activated.emit()
	ultimate_changed.emit(ultimate_charge, ultimate_max)
	
	var gw := get_tree().current_scene
	if gw and gw.has_node("VFXManager"):
		var vfx := gw.get_node("VFXManager")
		vfx.spawn_particles(global_position, Color(0.98, 0.85, 0.14), 30, 200)
		vfx.spawn_nova(global_position, 200, Color(0.98, 0.85, 0.14))
	if gw and gw.has_node("Camera2D"):
		gw.get_node("Camera2D").shake(8.0)


func activate_shield_bomb() -> void:
	var bomb_damage: float = (max_shield * level) * 0.8
	var blast_radius: float = 250.0
	
	shield = 0.0
	shield_regen_timer = 4.0
	shield_changed.emit(shield, max_shield)
	
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and e.alive:
			var dist := global_position.distance_to(e.global_position)
			if dist < blast_radius:
				var falloff := 1.0 - (dist / blast_radius)
				e.take_damage(bomb_damage * falloff, true, false, "shield_bomb")
	
	ultimate_charge = 0.0
	ultimate_changed.emit(ultimate_charge, ultimate_max)
	ultimate_activated.emit()
	
	var gw := get_tree().current_scene
	if gw and gw.has_node("VFXManager"):
		var vfx := gw.get_node("VFXManager")
		vfx.spawn_nova(global_position, blast_radius, Color(0.957, 0.247, 0.369))
		vfx.spawn_particles(global_position, Color(0.957, 0.247, 0.369), 40, 250)
		vfx.spawn_particles(global_position, Color(1.0, 0.6, 0.6), 20, 150)
	if gw and gw.has_node("Camera2D"):
		gw.get_node("Camera2D").shake(12.0)


func activate_poison_cloud() -> void:
	var leap_dir := Vector2.ZERO
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() > 0.1:
		leap_dir = input_dir.normalized()
	else:
		leap_dir = Vector2(1, 0)
	
	var leap_dist := 150.0
	var old_pos := global_position
	global_position += leap_dir * leap_dist
	
	var poison_scene: PackedScene = preload("res://scenes/effects/poison_cloud.tscn")
	var cloud := poison_scene.instantiate()
	cloud.global_position = old_pos
	cloud.base_radius = 80.0
	cloud.current_radius = 80.0
	cloud.damage_per_tick = 15.0 + level * 3
	cloud.lifetime = 5.0
	get_tree().current_scene.call_deferred("add_child", cloud)
	
	ultimate_charge = 0.0
	ultimate_changed.emit(ultimate_charge, ultimate_max)
	ultimate_activated.emit()
	
	var gw := get_tree().current_scene
	if gw and gw.has_node("VFXManager"):
		var vfx := gw.get_node("VFXManager")
		vfx.spawn_particles(old_pos, Color(0.13, 0.77, 0.37), 20, 100)
	if gw and gw.has_node("Camera2D"):
		gw.get_node("Camera2D").shake(6.0)
