extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var source_id: String = "weapon"
var color: Color = Color(0.133, 0.827, 0.933)
var is_crit: bool = false
var radius: float = 7.0
var lifetime: float = 2.0
var is_homing: bool = false
var is_pierce: bool = false
var is_flame: bool = false
var is_boomerang: bool = false
var boomerang_phase: float = 0.0
var aoe_radius: float = 0.0
var aoe_damage_mult: float = 1.0
var freeze_duration: float = 0.0
var poison_percent: float = 0.0
var poison_duration: float = 0.0
var poison_stacks: int = 0
var _hit_enemies: Array = []
var _elapsed: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var launch_delay: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision_shape.shape = circle

	if is_boomerang:
		_origin = global_position

	body_entered.connect(_on_body_entered)
	visible = launch_delay <= 0.0


func setup(pos: Vector2, angle: float, speed: float, dmg: float, col: Color, crit: bool, src: String) -> void:
	global_position = pos
	velocity = Vector2(cos(angle), sin(angle)) * speed
	damage = dmg
	color = col
	is_crit = crit
	source_id = src


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if launch_delay > 0:
		launch_delay -= delta
		if launch_delay <= 0:
			visible = true
		return
	if _elapsed >= lifetime:
		queue_free()
		return

	if is_homing:
		var target: Node2D = null
		if source_id == "boss_projectile":
			target = GameManager.player
		else:
			target = _find_nearest_enemy(350)
		if target:
			var target_angle := global_position.direction_to(target.global_position).angle()
			var cur_angle := velocity.angle()
			var diff := wrapf(target_angle - cur_angle, -PI, PI)
			var new_angle := cur_angle + diff * 0.15
			var speed := velocity.length()
			velocity = Vector2(cos(new_angle), sin(new_angle)) * speed

	if is_boomerang:
		boomerang_phase += delta
		if boomerang_phase > 0.7:
			var player := GameManager.player
			if player:
				var a := global_position.direction_to(player.global_position).angle()
				var speed := velocity.length()
				velocity = Vector2(cos(a), sin(a)) * speed * 1.3

	# Wall collision check via raycast (prevent passing through thin walls)
	var space := get_world_2d().direct_space_state
	var to_pos := global_position + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, to_pos)
	query.collision_mask = 32
	var result := space.intersect_ray(query)
	if result and not is_pierce and not is_flame and not is_boomerang:
		global_position = result.position
		_explode()
		queue_free()
		return

	global_position = to_pos
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		var enemy: Enemy = body
		if not enemy.alive:
			return

		if is_pierce:
			if enemy in _hit_enemies:
				return
			_hit_enemies.append(enemy)
		elif not is_flame and not is_boomerang:
			_explode()
			queue_free()

		enemy.take_damage(damage, is_crit, false, source_id)

		if freeze_duration > 0:
			enemy.freeze(freeze_duration)

		if poison_percent > 0 and enemy.alive:
			enemy.take_damage(damage * poison_percent, false, true, source_id)
			enemy.apply_poison(damage * poison_percent, poison_duration)

	if body is Player:
		var player: Player = body
		player.take_damage(damage)
		queue_free()

	if not is_pierce and body is StaticBody2D:
		_explode()
		queue_free()


func _explode() -> void:
	if aoe_radius <= 0:
		return
	var vfx := _get_vfx()
	if vfx:
		vfx.spawn_nova(global_position, aoe_radius, color)
		vfx.spawn_particles(global_position, color, 15, 80)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and e.alive:
			if global_position.distance_to(e.global_position) < aoe_radius:
				e.take_damage(damage * aoe_damage_mult, false, true, source_id + "_aoe")


func _find_nearest_enemy(max_dist: float) -> Enemy:
	var best: Enemy = null
	var best_dist := max_dist
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Enemy and e.alive:
			var d := global_position.distance_to(e.global_position)
			if d < best_dist:
				best_dist = d
				best = e
	return best


func _get_vfx() -> Node2D:
	var gw := get_tree().current_scene
	if gw and gw.has_node("VFXManager"):
		return gw.get_node("VFXManager")
	return null


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	if is_crit:
		draw_circle(Vector2.ZERO, radius + 2, Color(color.r, color.g, color.b, 0.4))
