class_name PlayerStats
extends Resource

@export var shape_name: String = "circle"
@export var max_hp: int = 120
@export var speed: float = 260.0
@export var crit_chance: float = 0.10
@export var crit_mult: float = 2.0
@export var attack_speed_mult: float = 1.0
@export var color: Color = Color(0.024, 0.714, 0.831, 1)
@export var radius: float = 18.0
@export var max_shield: float = 0.0
@export var shield_regen: float = 0.0


static func get_stats_for_shape(shape: String) -> PlayerStats:
	var stats := PlayerStats.new()
	stats.shape_name = shape
	match shape:
		"circle":
			stats.max_hp = 150
			stats.speed = 260.0
			stats.crit_chance = 0.10
			stats.attack_speed_mult = 1.3
			stats.color = Color(0.024, 0.714, 0.831, 1)
			stats.radius = 18.0
		"triangle":
			stats.max_hp = 125
			stats.speed = 320.0
			stats.crit_chance = 0.25
			stats.attack_speed_mult = 1.0
			stats.color = Color(0.063, 0.725, 0.506, 1)
			stats.radius = 18.0
		"square":
			stats.max_hp = 200
			stats.speed = 260.0
			stats.crit_chance = 0.10
			stats.attack_speed_mult = 1.0
			stats.max_shield = 25.0
			stats.shield_regen = 2.0
			stats.color = Color(0.957, 0.247, 0.369, 1)
			stats.radius = 20.0
	return stats
