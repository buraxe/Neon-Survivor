extends Node2D

var base_radius: float = 80.0
var current_radius: float = 80.0
var damage_per_tick: float = 25.0
var poison_duration: float = 3.0
var lifetime: float = 5.0
var age: float = 0.0
var tick_timer: float = 0.0
const TICK_INTERVAL: float = 1.0
const GROW_RATE: float = 0.10


func _ready() -> void:
	z_index = 1
	tick_timer = TICK_INTERVAL
	add_to_group("effects")


func _physics_process(delta: float) -> void:
	age += delta
	current_radius = base_radius * pow(1.0 + GROW_RATE, age)
	
	tick_timer -= delta
	if tick_timer <= 0:
		tick_timer = TICK_INTERVAL
		_apply_damage()
	
	if age >= lifetime:
		queue_free()
	
	queue_redraw()


func _apply_damage() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("take_damage") and e.get("alive") == true:
			var dist := global_position.distance_to(e.global_position)
			if dist < current_radius:
				e.take_damage(damage_per_tick, false, false, "poison_cloud")
				if e.has_method("apply_poison"):
					e.apply_poison(damage_per_tick, poison_duration)


func _draw() -> void:
	var alpha := maxf(0.1, 0.35 * (1.0 - age / lifetime))
	var pulse := 1.0 + 0.05 * sin(Time.get_ticks_msec() / 300.0)
	var r := current_radius * pulse
	
	draw_circle(Vector2.ZERO, r, Color(0.13, 0.77, 0.37, alpha))
	
	for i in 3:
		var ring_r := r * (0.3 + i * 0.25)
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 24, Color(0.13, 0.77, 0.37, alpha * 0.5), 1.5)
