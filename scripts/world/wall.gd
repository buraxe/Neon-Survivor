extends StaticBody2D

@export var wall_color: Color = Color(0.059, 0.09, 0.165, 0.8)
@export var border_color: Color = Color(0.22, 0.74, 0.97, 1.0)
@export var glow_color: Color = Color(0.22, 0.74, 0.97, 0.6)
@export var glow_amount: float = 15.0

var _size: Vector2 = Vector2(40, 40)


func setup(size: Vector2) -> void:
	_size = size
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = _size
	$CollisionShape2D.shape = rect_shape
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-_size * 0.5, _size)
	draw_rect(rect, wall_color)
	draw_rect(rect, border_color, false, 2.0)
