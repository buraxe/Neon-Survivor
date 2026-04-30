extends Node2D

enum Shape { CIRCLE, TRIANGLE, SQUARE }

@export var shape_type: Shape = Shape.CIRCLE
@export var shape_color: Color = Color(0.024, 0.714, 0.831)
@export var shape_radius: float = 18.0
@export var glow_amount: float = 20.0
var ultimate_active: bool = false


func _draw() -> void:
	match shape_type:
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, shape_radius, shape_color)
			draw_arc(Vector2.ZERO, shape_radius, 0.0, TAU, 32, Color.WHITE, 3.0, true)
		Shape.TRIANGLE:
			var pts := PackedVector2Array([
				Vector2(0, -shape_radius - 4),
				Vector2(shape_radius, shape_radius),
				Vector2(-shape_radius, shape_radius)
			])
			draw_colored_polygon(pts, shape_color)
			draw_polyline(pts, Color.WHITE, 3.0, true)
		Shape.SQUARE:
			var s := shape_radius
			var rect := Rect2(-s, -s, s * 2, s * 2)
			draw_rect(rect, shape_color, false, 0, 8.0)
			draw_rect(rect, shape_color)
			draw_rect(rect, Color.WHITE, false, 3.0, 8.0)

	if shape_color.a > 0 and shape_type != Shape.TRIANGLE:
		draw_circle(Vector2.ZERO, shape_radius + 2, Color(shape_color.r, shape_color.g, shape_color.b, 0.15))

	if ultimate_active:
		var pulse := 1.0 + 0.3 * sin(Time.get_ticks_msec() / 100.0)
		var glow_r := shape_radius + 8 * pulse
		draw_circle(Vector2.ZERO, glow_r, Color(0.98, 0.85, 0.14, 0.15))
		draw_arc(Vector2.ZERO, glow_r, 0.0, TAU, 32, Color(0.98, 0.85, 0.14, 0.7), 4.0, true)
