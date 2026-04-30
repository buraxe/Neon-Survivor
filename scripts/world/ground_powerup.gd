class_name GroundPowerup
extends Area2D

enum Type { HP, BOMB, MAGNET }

var type: Type = Type.HP
var age: float = 0.0
var max_age: float = 30.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const POWERUP_COLORS := {
	Type.HP: Color(0.96, 0.25, 0.37),
	Type.BOMB: Color(0.98, 0.80, 0.14),
	Type.MAGNET: Color(0.65, 0.55, 0.98),
}

const POWERUP_SHAPES := {
	Type.HP: "cross",
	Type.BOMB: "circle",
	Type.MAGNET: "diamond",
}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	collision_shape.shape = circle


func _process(delta: float) -> void:
	age += delta
	if age >= max_age:
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_apply(body)
		queue_free()


func _apply(player: Player) -> void:
	match type:
		Type.HP:
			var heal_amt: float = player.stats.max_hp * 0.25
			player.heal(heal_amt)
			_spawn_text("+%d CAN!" % ceili(heal_amt), Color(0.96, 0.25, 0.37))
		Type.BOMB:
			var blast_r := 350.0
			var count := 0
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Enemy and e.alive:
					if global_position.distance_to(e.global_position) < blast_r:
						e.take_damage(player.damage_mult * 150, true, false, "bomba")
						count += 1
			var vfx_node := _get_vfx()
			if vfx_node:
				vfx_node.spawn_nova(global_position, blast_r, Color(0.98, 0.80, 0.14))
				vfx_node.spawn_particles(global_position, Color(0.98, 0.60, 0.10), 40, 250)
				vfx_node.spawn_particles(global_position, Color(1.0, 1.0, 0.5), 20, 150)
			_spawn_text("BOMBA! x%d" % count, Color(0.98, 0.80, 0.14))
		Type.MAGNET:
			for g in get_tree().get_nodes_in_group("gems"):
				if g is Area2D and g.has_method("pull_to_player"):
					g.pull_to_player()
			_spawn_text("🧲 MIKNATIS!", Color(0.65, 0.55, 0.98))


func _spawn_text(text: String, color: Color) -> void:
	var ft_scene: PackedScene = preload("res://scenes/effects/floating_text.tscn")
	var ft := ft_scene.instantiate()
	ft.global_position = global_position + Vector2(0, -40)
	ft.setup(text, color, 20)
	get_tree().current_scene.call_deferred("add_child", ft)


func _get_vfx() -> Node2D:
	var gw := get_tree().current_scene
	if gw and gw.has_node("VFXManager"):
		return gw.get_node("VFXManager")
	return null


func _draw() -> void:
	var color: Color = POWERUP_COLORS[type]
	var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() / 250.0)
	var fade := minf(1.0, (max_age - age) / 2.0)
	var c := Color(color.r, color.g, color.b, 0.3 * fade)
	
	draw_circle(Vector2.ZERO, 18.0 * pulse, c)
	draw_arc(Vector2.ZERO, 18.0 * pulse, 0, TAU, 32, Color(color.r, color.g, color.b, fade), 2.5)
	
	var shape: String = POWERUP_SHAPES[type]
	var shape_color := Color(1, 1, 1, fade)
	match shape:
		"cross":
			draw_rect(Rect2(-4, -10, 8, 20), shape_color)
			draw_rect(Rect2(-10, -4, 20, 8), shape_color)
		"circle":
			draw_circle(Vector2.ZERO, 8, shape_color)
		"diamond":
			var pts := PackedVector2Array([
				Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0)
			])
			draw_colored_polygon(pts, shape_color)
