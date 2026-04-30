extends Control

@onready var base: ColorRect = $Base
@onready var thumb: ColorRect = $Thumb

var is_active: bool = false
var touch_index: int = -1
var output: Vector2 = Vector2.ZERO
var max_distance: float = 50.0

signal joystick_input(direction: Vector2)


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_in_zone(event.position):
				touch_index = event.index
				is_active = true
				_update_thumb(event.position)
		elif event.index == touch_index:
			_reset()

	elif event is InputEventScreenDrag:
		if event.index == touch_index and is_active:
			_update_thumb(event.position)


func _is_in_zone(pos: Vector2) -> bool:
	var rect := get_global_rect()
	return rect.has_point(pos)


func _update_thumb(touch_pos: Vector2) -> void:
	var center := global_position + size * 0.5
	var diff := touch_pos - center
	var dist := diff.length()

	if dist > max_distance:
		diff = diff.normalized() * max_distance

	output = diff / max_distance
	thumb.position = base.size * 0.5 - thumb.size * 0.5 + diff
	joystick_input.emit(output)


func _reset() -> void:
	is_active = false
	touch_index = -1
	output = Vector2.ZERO
	thumb.position = base.size * 0.5 - thumb.size * 0.5
	joystick_input.emit(Vector2.ZERO)
