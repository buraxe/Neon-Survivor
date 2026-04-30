extends Area2D

var value: int = 2
var _being_pulled: bool = false
var _instant_pull: bool = false

@onready var pickup_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("gems")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not GameManager.player:
		return

	var player := GameManager.player
	var dist := global_position.distance_to(player.global_position)
	var pull_radius: float = player.pickup_radius

	if dist < pull_radius or _instant_pull:
		_being_pulled = true

	if _being_pulled:
		var speed: float = 800.0
		if _instant_pull:
			speed = 2000.0
		var dir := global_position.direction_to(player.global_position)
		global_position += dir * speed * delta

		if dist < player.stats.radius + 15:
			player.gain_xp(value)
			queue_free()


func pull_to_player() -> void:
	if GameManager.player:
		_instant_pull = true
		_being_pulled = true


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.gain_xp(value)
		AudioManager.play_sfx(AudioManager.SFXType.GEM_PICKUP)
		queue_free()


func _draw() -> void:
	var gem_color := Color(0.055, 0.647, 0.91)
	if _instant_pull:
		gem_color = Color(0.65, 0.55, 0.98)
	draw_circle(Vector2.ZERO, 4, gem_color)
	var pts := PackedVector2Array([
		Vector2(0, -8), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0)
	])
	draw_colored_polygon(pts, gem_color)
