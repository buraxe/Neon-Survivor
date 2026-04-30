extends Area2D

var used: bool = false

const MAX_SKULLS := 5
var _total_spawned: int = 0
var _spawn_timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	$CollisionShape2D.shape = circle


func _process(delta: float) -> void:
	if used:
		return
	_spawn_timer += delta
	if _total_spawned < MAX_SKULLS and _spawn_timer > 30.0 and randf() < 0.0008:
		_spawn_timer = 0
		_total_spawned += 1
		visible = true
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not used:
		used = true
		GameManager.skulls_collected += 1
		var old_mult := GameManager.skull_difficulty_mult
		GameManager.skull_difficulty_mult += 0.2
		GameManager.skull_score_mult = 1 + GameManager.skulls_collected
		
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Enemy and e.alive:
				var mult := GameManager.skull_difficulty_mult / old_mult
				e.hp *= mult
				e.max_hp *= mult
				e.damage = ceili(e.damage * mult)
		
		_spawn_text("ZORLUK +20%!", Color(0.94, 0.27, 0.27))
		queue_free()


func _spawn_text(text: String, color: Color) -> void:
	var ft_scene: PackedScene = preload("res://scenes/effects/floating_text.tscn")
	var ft := ft_scene.instantiate()
	ft.global_position = global_position + Vector2(0, -40)
	ft.setup(text, color, 20)
	get_tree().current_scene.call_deferred("add_child", ft)


func _draw() -> void:
	if used:
		return
	var pulse := 1.0 + 0.2 * sin(Time.get_ticks_msec() / 200.0)
	var color := Color(0.94, 0.27, 0.27)
	
	draw_circle(Vector2.ZERO, 30.0 * pulse, Color(color.r, color.g, color.b, 0.3))
	draw_arc(Vector2.ZERO, 30.0 * pulse, 0, TAU, 32, color, 3.0)
	
	# Draw skull icon
	var head_r := 10.0
	draw_circle(Vector2(0, -2), head_r, color)
	# Eyes
	draw_circle(Vector2(-4, -3), 2.5, Color.BLACK)
	draw_circle(Vector2(4, -3), 2.5, Color.BLACK)
	# Nose
	var nose_pts := PackedVector2Array([Vector2(0, 0), Vector2(-2, 4), Vector2(2, 4)])
	draw_colored_polygon(nose_pts, Color.BLACK)
	# Teeth
	for i in 3:
		var tx := -4 + i * 4
		draw_rect(Rect2(tx, 5, 3, 4), Color.BLACK)
