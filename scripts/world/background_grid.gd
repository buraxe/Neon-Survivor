extends Node2D

@export var bg_color: Color = Color(0.008, 0.024, 0.09)
@export var dot_color: Color = Color(1, 1, 1, 0.05)
@export var dot_spacing: float = 50.0
@export var dot_size: float = 2.0

var _camera: Camera2D


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not _camera:
		_camera = get_viewport().get_camera_2d()
		if not _camera:
			return

	var cam_pos: Vector2 = _camera.global_position
	var half_viewport: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var cam_zoom: float = minf(_camera.zoom.x, _camera.zoom.y)

	var start_x: float = floor((cam_pos.x - half_viewport.x / cam_zoom) / dot_spacing) * dot_spacing
	var start_y: float = floor((cam_pos.y - half_viewport.y / cam_zoom) / dot_spacing) * dot_spacing
	var end_x: float = cam_pos.x + half_viewport.x / cam_zoom + dot_spacing
	var end_y: float = cam_pos.y + half_viewport.y / cam_zoom + dot_spacing

	var x: float = start_x
	while x < end_x:
		var y: float = start_y
		while y < end_y:
			draw_rect(Rect2(x, y, dot_size, dot_size), dot_color)
			y += dot_spacing
		x += dot_spacing
