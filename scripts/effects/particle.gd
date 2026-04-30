extends Node2D

var velocity: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var lifetime: float = 0.6
var size: float = 3.0
var speed: float = 60.0
var _elapsed: float = 0.0


func _ready() -> void:
	var angle := randf() * TAU
	var v := randf() * speed
	velocity = Vector2(cos(angle), sin(angle)) * v


func update_particle(delta: float) -> void:
	_elapsed += delta
	global_position += velocity * delta
	velocity *= 0.95
	
	if _elapsed >= lifetime:
		queue_free()
	
	queue_redraw()


func _draw() -> void:
	var alpha := clampf(1.0 - _elapsed / lifetime, 0.0, 1.0)
	var c := Color(color.r, color.g, color.b, alpha)
	draw_circle(Vector2.ZERO, size * alpha, c)
