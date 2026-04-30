extends Node2D

const SHRINE_SCENE: PackedScene = preload("res://scenes/world/shrine.tscn")
const SKULL_SCENE: PackedScene = preload("res://scenes/world/skull.tscn")
const CHEST_SCENE: PackedScene = preload("res://scenes/world/chest.tscn")

var _shrine_spawn_timer: float = 0.0
var _total_shrines_spawned: int = 0
var _max_shrines: int = 8
var _active_shrines: int = 0
var _skull: Node2D = null
var _chests: Array[Node2D] = []
var _skull_spawned: bool = false


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if GameManager.death_timer >= 0:
		return
	if not GameManager.player:
		return
	
	# Lv4'te shrine ve skull spawn yok
	if GameManager.current_level == 4:
		_update_chests(delta)
		return

	_spawn_timer_shrines(delta)
	_update_chests(delta)
	if not _skull_spawned and GameManager.player:
		_skull_spawned = true
		_spawn_skull()


func _spawn_timer_shrines(delta: float) -> void:
	if _total_shrines_spawned >= _max_shrines:
		return

	_shrine_spawn_timer += delta
	if _shrine_spawn_timer >= 45.0 and _active_shrines < 3:
		_shrine_spawn_timer = 0.0
		_spawn_shrine()


func _spawn_shrine() -> void:
	if not GameManager.player:
		return
	var angle := randf() * TAU
	var dist := 300.0 + randf() * 400.0
	var pos := GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * dist
	pos = _clamp_arena_pos(pos)

	var shrine := SHRINE_SCENE.instantiate()
	shrine.shrine_type = randi() % 7
	shrine.global_position = pos
	call_deferred("add_child", shrine)
	_total_shrines_spawned += 1
	_active_shrines += 1

	shrine.tree_exited.connect(func(): _active_shrines -= 1)


func _spawn_skull() -> void:
	if not GameManager.player:
		return
	var angle := randf() * TAU
	var dist := 1000.0 + randf() * 500.0
	var pos := GameManager.player.global_position + Vector2(cos(angle), sin(angle)) * dist
	pos = _clamp_arena_pos(pos)

	_skull = SKULL_SCENE.instantiate()
	_skull.global_position = pos
	call_deferred("add_child", _skull)


func _clamp_arena_pos(pos: Vector2) -> Vector2:
	if GameManager.current_level == 4:
		var half := 870.0
		return Vector2(clampf(pos.x, -half, half), clampf(pos.y, -half, half))
	return pos


func spawn_chest(pos: Vector2, rarity: int) -> void:
	var chest := CHEST_SCENE.instantiate()
	chest.global_position = _clamp_arena_pos(pos)
	chest.rarity = rarity
	call_deferred("add_child", chest)
	_chests.append(chest)
	chest.tree_exited.connect(func(): _chests.erase(chest))


func _update_chests(_delta: float) -> void:
	if not GameManager.player:
		return
	var to_remove: Array[int] = []
	for i in _chests.size():
		var chest: Node2D = _chests[i]
		if chest and chest.global_position.distance_to(GameManager.player.global_position) < 50:
			_open_chest(chest)
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		_chests.remove_at(to_remove[i])


func _open_chest(chest: Node2D) -> void:
	var rarity: int = chest.rarity
	chest.queue_free()

	var chest_scene: PackedScene = preload("res://scenes/ui/chest_open.tscn")
	var co := chest_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", co)
	co.call_deferred("setup", rarity)


func _spawn_text(text: String, color: Color) -> void:
	if not GameManager.player:
		return
	var ft_scene: PackedScene = preload("res://scenes/effects/floating_text.tscn")
	var ft := ft_scene.instantiate()
	ft.global_position = GameManager.player.global_position + Vector2(0, -60)
	ft.setup(text, color, 22)
	get_tree().current_scene.call_deferred("add_child", ft)
