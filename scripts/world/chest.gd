extends Node2D

var rarity: int = 1

@export var pulse_speed: float = 2.0
@export var glow_color: Color = Color(0.98, 0.75, 0.14)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + 0.1 * sin(Time.get_ticks_msec() / 200.0 * pulse_speed)
	var size := 15.0 * pulse
	
	match rarity:
		1:
			draw_rect(Rect2(-size, -size * 0.8, size * 2, size * 1.6), Color(0.6, 0.6, 0.6))
			draw_rect(Rect2(-size, -size * 0.8, size * 2, size * 1.6), Color.WHITE, false, 2.0)
		2:
			draw_rect(Rect2(-size, -size * 0.8, size * 2, size * 1.6), Color(0.13, 0.83, 0.93))
			draw_rect(Rect2(-size, -size * 0.8, size * 2, size * 1.6), Color(0.4, 0.9, 1.0), false, 2.0)
		3:
			draw_rect(Rect2(-size, -size * 0.8, size * 2, size * 1.6), Color(0.98, 0.75, 0.14))
			draw_arc(Vector2.ZERO, size * 1.5, 0, TAU, 32, Color(0.98, 0.75, 0.14, 0.4 + 0.3 * sin(Time.get_ticks_msec() / 150.0)), 3.0)
	
	draw_rect(Rect2(-3, -3, 6, 6), Color.WHITE)
