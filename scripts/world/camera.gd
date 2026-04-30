extends Camera2D

var _shake_amount: float = 0.0
var _shake_decay: float = 20.0


func shake(amount: float) -> void:
	_shake_amount = maxf(_shake_amount, amount * (GameManager.shake_intensity / 100.0))


func _process(delta: float) -> void:
	if _shake_amount > 0:
		_shake_amount -= _shake_decay * delta
		if _shake_amount < 0:
			_shake_amount = 0
		offset = Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
	else:
		offset = Vector2.ZERO
