extends Area2D

enum Type { HP, SPEED, DAMAGE, ATK_SPEED, CRIT, PROJECTILE, SHIELD }

@export var shrine_type: Type = Type.HP

var charge_time: float = 0.0
var charged: bool = false
var used: bool = false
var _player: Player = null

const SHRINE_COLORS := {
	Type.HP: Color(0.96, 0.25, 0.37),
	Type.SPEED: Color(0.055, 0.647, 0.91),
	Type.DAMAGE: Color(0.98, 0.45, 0.09),
	Type.ATK_SPEED: Color(0.98, 0.88, 0.14),
	Type.CRIT: Color(0.98, 0.75, 0.14),
	Type.PROJECTILE: Color(0.66, 0.33, 0.97),
	Type.SHIELD: Color(0.133, 0.827, 0.933),
}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	$CollisionShape2D.shape = circle


func _process(delta: float) -> void:
	if used:
		return
	if _player and global_position.distance_to(_player.global_position) < 50:
		charge_time += delta
		if charge_time >= 4.0 and not charged:
			charged = true
			_apply_buff()
			used = true
			queue_free()
	else:
		charge_time = maxf(0, charge_time - delta * 0.5)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player = null


func _apply_buff() -> void:
	if not _player:
		return
	match shrine_type:
		Type.HP:
			_player.add_max_hp(5)
			_spawn_text("+5 MAX CAN!", Color(0.75, 0.52, 0.99))
		Type.SPEED:
			_player.stats.speed += 5
			_spawn_text("+5 HIZ!", Color(0.75, 0.52, 0.99))
		Type.DAMAGE:
			_player.damage_mult += 0.05
			_spawn_text("+%5 HASAR!", Color(0.75, 0.52, 0.99))
		Type.ATK_SPEED:
			_player.attack_speed_mult += 0.05
			_spawn_text("+%5 SALDIRI HIZI!", Color(0.75, 0.52, 0.99))
		Type.CRIT:
			_player.crit_chance += 0.05
			_spawn_text("+%5 KRITIK!", Color(0.75, 0.52, 0.99))
		Type.PROJECTILE:
			_player.projectile_count += 1
			_spawn_text("+1 MERMI!", Color(0.75, 0.52, 0.99))
		Type.SHIELD:
			_player.max_shield += 5
			_player.shield += 5
			if _player.shield_regen <= 0:
				_player.shield_regen = 8.0
			_player.shield_changed.emit(_player.shield, _player.max_shield)
			_spawn_text("+5 KALKAN!", Color(0.75, 0.52, 0.99))


func _spawn_text(text: String, color: Color) -> void:
	var ft_scene: PackedScene = preload("res://scenes/effects/floating_text.tscn")
	var ft := ft_scene.instantiate()
	ft.global_position = global_position + Vector2(0, -40)
	ft.setup(text, color, 16)
	get_tree().current_scene.call_deferred("add_child", ft)


func _draw() -> void:
	if used:
		return
	var color: Color = SHRINE_COLORS[shrine_type]
	var pulse := 1.0 + 0.2 * sin(Time.get_ticks_msec() / 200.0)
	
	draw_circle(Vector2.ZERO, 30.0 * pulse, Color(color.r, color.g, color.b, 0.3))
	draw_arc(Vector2.ZERO, 30.0 * pulse, 0, TAU, 32, color, 3.0)
	
	if charge_time > 0 and not charged:
		var progress := charge_time / 4.0
		draw_arc(Vector2.ZERO, 35.0, -TAU / 4.0, -TAU / 4.0 + TAU * progress, 32, Color.WHITE, 4.0)
		
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(-8, 50), "%ds" % ceili(4.0 - charge_time), HORIZONTAL_ALIGNMENT_CENTER, 16, 12, Color.WHITE)
	
	# Icon shapes
	var icon_color := Color.WHITE
	match shrine_type:
		Type.HP:
			draw_rect(Rect2(-4, -10, 8, 20), icon_color)
			draw_rect(Rect2(-10, -4, 20, 8), icon_color)
		Type.SPEED:
			var pts := PackedVector2Array([Vector2(0, -10), Vector2(8, 0), Vector2(0, 10), Vector2(-8, 0)])
			draw_colored_polygon(pts, icon_color)
		Type.DAMAGE:
			draw_rect(Rect2(-8, -8, 16, 16), icon_color)
			draw_rect(Rect2(-4, -12, 8, 20), icon_color)
		Type.ATK_SPEED:
			draw_circle(Vector2.ZERO, 8, icon_color)
			for i in 3:
				var a := (TAU / 3) * i - PI / 2
				draw_line(Vector2.ZERO, Vector2(cos(a) * 12, sin(a) * 12), icon_color, 3.0)
		Type.CRIT:
			for i in 5:
				var a := (TAU / 5) * i - PI / 2
				var next_a := (TAU / 5) * (i + 1) - PI / 2
				draw_line(Vector2(cos(a) * 10, sin(a) * 10), Vector2(cos(next_a) * 10, sin(next_a) * 10), icon_color, 3.0)
		Type.PROJECTILE:
			draw_rect(Rect2(-3, -10, 6, 20), icon_color)
			for i in 3:
				draw_rect(Rect2(-8 + i * 8, -10 + i * 6, 6, 12), icon_color)
		Type.SHIELD:
			var shield_pts := PackedVector2Array([
				Vector2(-10, -5), Vector2(0, -12), Vector2(10, -5),
				Vector2(10, 5), Vector2(0, 12), Vector2(-10, 5)
			])
			draw_colored_polygon(shield_pts, icon_color)
