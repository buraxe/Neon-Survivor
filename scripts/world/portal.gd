extends Area2D

var _active: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Spawn animasyonu
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active = true


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body is Player:
		_active = false
		var gw := get_tree().current_scene
		if gw and gw.has_method("advance_level"):
			gw.advance_level()
