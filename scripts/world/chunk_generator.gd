extends Node2D

const CHUNK_SIZE := 1000.0
const WALLS_PER_CHUNK := 5
const SAFE_RADIUS := 400.0
const WALL_SCENE: PackedScene = preload("res://scenes/world/wall.tscn")

var _generated_chunks: Dictionary = {}


func _process(_delta: float) -> void:
	if not GameManager.player:
		return
	if GameManager.current_level == 4:
		return
	var cx := floori(GameManager.player.global_position.x / CHUNK_SIZE)
	var cy := floori(GameManager.player.global_position.y / CHUNK_SIZE)

	for x in range(cx - 1, cx + 2):
		for y in range(cy - 1, cy + 2):
			var key := "%d,%d" % [x, y]
			if not _generated_chunks.has(key):
				_generate_chunk(x, y)
				_generated_chunks[key] = true

	var player_pos := GameManager.player.global_position
	var all_walls := get_tree().get_nodes_in_group("walls")
	for wall in all_walls:
		if wall.global_position.distance_to(player_pos) > 2500:
			wall.queue_free()


func _generate_chunk(cx: int, cy: int) -> void:
	var ox := cx * CHUNK_SIZE
	var oy := cy * CHUNK_SIZE

	for i in WALLS_PER_CHUNK:
		var wx := ox + randf() * CHUNK_SIZE
		var wy := oy + randf() * CHUNK_SIZE

		if Vector2(wx, wy).length() < SAFE_RADIUS:
			continue

		var wall_type := randi() % 10
		var s := 40.0 + randf() * 80.0
		var t := 15.0 + randf() * 15.0

		match wall_type:
			0: # Artı (+)
				_spawn_wall(wx, wy, Vector2(s, t))
				_spawn_wall(wx, wy, Vector2(t, s))
			1: # L şekli (köşe)
				_spawn_wall(wx, wy, Vector2(s, t))
				_spawn_wall(wx, wy, Vector2(t, s))
			2: # T şekli
				_spawn_wall(wx, wy, Vector2(s, t))
				_spawn_wall(wx, wy, Vector2(t, s))
				_spawn_wall(wx - s * 0.5, wy, Vector2(s, t))
			3: # U şekli
				_spawn_wall(wx, wy, Vector2(t, s))
				_spawn_wall(wx, wy, Vector2(t, s))
				_spawn_wall(wx, wy + s * 0.5, Vector2(s * 1.2, t))
			4: # H şekli
				_spawn_wall(wx, wy, Vector2(t, s))
				_spawn_wall(wx + s * 0.6, wy, Vector2(t, s))
				_spawn_wall(wx + s * 0.3, wy, Vector2(s * 0.6, t))
			5: # Paralel duvarlar
				_spawn_wall(wx, wy, Vector2(s, t))
				_spawn_wall(wx, wy + s * 0.5, Vector2(s, t))
			6: # Büyük blok
				_spawn_wall(wx, wy, Vector2(s * 0.8, s * 0.8))
			7: # Uzun koridor
				_spawn_wall(wx, wy, Vector2(s * 1.5, t))
			8: # Köşe + blok
				_spawn_wall(wx, wy, Vector2(s, t))
				_spawn_wall(wx, wy, Vector2(t, s))
				_spawn_wall(wx + s * 0.3, wy + s * 0.3, Vector2(s * 0.4, s * 0.4))
			9: # Tek kare
				_spawn_wall(wx, wy, Vector2(s, s))


func _spawn_wall(x: float, y: float, size: Vector2) -> void:
	var wall := WALL_SCENE.instantiate()
	wall.global_position = Vector2(x, y)
	wall.add_to_group("walls")
	wall.setup(size)
	call_deferred("add_child", wall)
