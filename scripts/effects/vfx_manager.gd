extends Node2D

const PARTICLE_SCENE: PackedScene = preload("res://scenes/effects/particle.tscn")
const FLOATING_TEXT_SCENE: PackedScene = preload("res://scenes/effects/floating_text.tscn")

var _particles: Array[Node2D] = []
var _floating_texts: Array[Node2D] = []
var _visuals: Array[Dictionary] = []


func _process(delta: float) -> void:
	_update_particles(delta)
	_update_floating_texts(delta)
	_update_visuals(delta)


func spawn_particles(pos: Vector2, color: Color, count: int, speed: float) -> void:
	var mult := _get_particle_multiplier()
	if mult == 0:
		return
	
	var final_count := ceili(count * mult)
	for i in final_count:
		var p := PARTICLE_SCENE.instantiate()
		p.global_position = pos
		p.color = color
		p.speed = speed
		p.lifetime = 0.6
		get_tree().current_scene.call_deferred("add_child", p)
		_particles.append(p)
		p.tree_exited.connect(func(): _particles.erase(p))

	if _get_graphics_quality() == "high" and count >= 8:
		var spark_count := ceili(count * 0.7)
		for i in spark_count:
			var p := PARTICLE_SCENE.instantiate()
			p.global_position = pos
			p.color = Color.WHITE
			p.speed = speed * 0.35
			p.lifetime = 0.2
			p.size = 2.0
			get_tree().current_scene.call_deferred("add_child", p)
			_particles.append(p)
			p.tree_exited.connect(func(): _particles.erase(p))


func spawn_lightning(start: Vector2, end_pos: Vector2) -> void:
	_visuals.append({
		"type": "lightning",
		"start": start,
		"end": end_pos,
		"color": Color(0.99, 0.88, 0.14),
		"lifetime": 0.4,
		"max_lifetime": 0.4,
		"width": 4.0,
	})
	_visuals.append({
		"type": "lightning",
		"start": start,
		"end": end_pos,
		"color": Color.WHITE,
		"lifetime": 0.3,
		"max_lifetime": 0.3,
		"width": 2.0,
	})


func spawn_laser(pos: Vector2, radius: float) -> void:
	_visuals.append({
		"type": "laser",
		"pos": pos,
		"radius": radius,
		"lifetime": 0.3,
		"max_lifetime": 0.3,
	})


func spawn_nova(pos: Vector2, radius: float, color: Color) -> void:
	_visuals.append({
		"type": "nova",
		"pos": pos,
		"max_radius": radius,
		"current_radius": 0.0,
		"color": color,
		"lifetime": 0.4,
		"max_lifetime": 0.4,
	})


func spawn_floating_text(text: String, pos: Vector2, color: Color, size: int = 14) -> void:
	var ft := FLOATING_TEXT_SCENE.instantiate()
	ft.global_position = pos
	ft.setup(text, color, size)
	get_tree().current_scene.call_deferred("add_child", ft)
	_floating_texts.append(ft)
	ft.tree_exited.connect(func(): _floating_texts.erase(ft))


func _update_particles(delta: float) -> void:
	for p in _particles:
		if p:
			p.update_particle(delta)
	queue_redraw()


func _update_floating_texts(delta: float) -> void:
	for ft in _floating_texts:
		if ft:
			ft.update_text(delta)


func _update_visuals(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in _visuals.size():
		var v: Dictionary = _visuals[i]
		v.lifetime -= delta
		if v.type == "nova":
			v.current_radius += (v.max_radius - v.current_radius) * 10.0 * delta
		if v.lifetime <= 0:
			to_remove.append(i)
	
	for i in range(to_remove.size() - 1, -1, -1):
		_visuals.remove_at(to_remove[i])
	queue_redraw()


func _get_particle_multiplier() -> float:
	match _get_graphics_quality():
		"low": return 0.0
		"medium": return 1.0
		"high": return 3.2
	return 1.0


func _get_graphics_quality() -> String:
	return GameManager.graphics_quality


func _draw() -> void:
	for v in _visuals:
		var alpha := clampf(v.lifetime / v.max_lifetime, 0.0, 1.0)
		
		if v.type == "lightning":
			var color := Color(v.color.r, v.color.g, v.color.b, alpha)
			draw_line(v.start, v.end, color, v.width)
		
		elif v.type == "laser":
			var color := Color(0.97, 0.98, 1.0, alpha)
			draw_circle(v.pos, v.radius * (v.lifetime / v.max_lifetime), color)
			draw_rect(Rect2(v.pos.x - v.radius / 2.0, v.pos.y - 1000.0, v.radius, 1000.0), color)
		
		elif v.type == "nova":
			var color := Color(v.color.r, v.color.g, v.color.b, alpha * 0.4)
			draw_circle(v.pos, v.current_radius, color)
			var border_color := Color(v.color.r, v.color.g, v.color.b, alpha)
			draw_arc(v.pos, v.current_radius, 0.0, TAU, 32, border_color, 3.0)
