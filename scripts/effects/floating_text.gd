extends Node2D

var _text: String = ""
var _color: Color = Color.WHITE
var _size: int = 14
var _lifetime: float = 1.0
var _elapsed: float = 0.0


func setup(text: String, color: Color, size: int = 14) -> void:
	_text = text
	_color = color
	_size = size


func _process(delta: float) -> void:
	_elapsed += delta
	position.y -= 40.0 * delta
	queue_redraw()
	if _elapsed >= _lifetime:
		queue_free()


func _draw() -> void:
	var alpha := clampf(1.0 - _elapsed / _lifetime, 0.0, 1.0)
	var c := Color(_color.r, _color.g, _color.b, alpha)
	draw_string(ThemeDB.fallback_font, Vector2(-10, 0), _text, HORIZONTAL_ALIGNMENT_CENTER, -1, _size, c)
