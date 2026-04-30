extends Node

signal game_started(shape: String, weapon_id: String)
signal game_paused
signal game_resumed
signal game_over
signal victory
signal next_level_requested(portal_position: Vector2)
signal dev_skip_to_level_requested(level: int)

enum GameState {
	MAIN_MENU,
	CHARACTER_SELECT,
	WEAPON_SELECT,
	PLAYING,
	PAUSED,
	LEVEL_UP,
	CHEST,
	GAME_OVER,
	VICTORY,
	SETTINGS,
}

var current_state: GameState = GameState.MAIN_MENU
var player: CharacterBody2D = null
var game_time: float = 0.0
var kill_count: int = 0
var selected_shape: String = ""
var selected_weapon: String = ""
var skull_difficulty_mult: float = 1.0
var skull_score_mult: int = 1
var skulls_collected: int = 0
var current_level: int = 1
var final_boss_spawned: bool = false
var first_boss_killed: bool = false
var first_elite_spawned: bool = false
var special_wave_active: bool = false
var special_wave_minute: int = 0
var special_wave_timer: float = 0.0
var upgrade_rerolls: int = 5
var total_rerolls_used: int = 0
var death_timer: float = -1.0
var boss_active: Node2D = null
var last_boss_spawn: float = 0.0
var shake_intensity: float = 100.0
var graphics_quality: String = "medium"
var damage_stats: Dictionary = {}
var heal_stats: Dictionary = {}

# === EVRIM SISTEMI ===
var evolved_enemy_type: int = -1
var evolution_trait: String = ""
var pressure_wave_active: bool = false
var pressure_wave_timer: float = 0.0
var _dev_start_level: int = 0

const DEV_MODE: bool = true

var settings: Dictionary = {
	"crt_enabled": true,
	"crt_affects_ui": false,
	"crt_curvature": 40,
	"crt_chroma": 50,
	"crt_bloom": 0,
	"crt_vignette": 40,
	"crt_noise": 30,
	"crt_flicker": 50,
	"crt_scanlines": 60,
	"shake_intensity": 100,
	"graphics_quality": "medium",
	"music_volume": 80,
	"sfx_volume": 80,
}

# Meta progression
var total_coins: int = 0
var run_coins: int = 0
var total_spent: int = 0
var weapon_slots: int = 2
var passive_slots: int = 2

var unlocked_characters: Array[String] = ["circle"]
var unlocked_weapons: Array[String] = ["wand", "shotgun", "blade", "aura"]
var unlocked_passives: Array[String] = ["p_shield", "p_hp", "p_xpboost", "p_speed"]
var unlocked_ultimates: Array[String] = ["circle"]

var meta_stats: Dictionary = {
	"atk_speed": 0,
	"damage": 0,
	"max_hp": 0,
	"speed": 0,
	"crit_chance": 0,
}

const META_COST_BASE: int = 300


func _ready() -> void:
	_load_settings()
	_load_progress()


func change_state(new_state: GameState) -> void:
	current_state = new_state


func request_next_level(portal_pos: Vector2) -> void:
	next_level_requested.emit(portal_pos)


func pick_evolution() -> void:
	evolved_enemy_type = -1
	evolution_trait = ""
	if current_level <= 1:
		return
	var types := [0, 1, 2, 3]
	evolved_enemy_type = types[randi() % types.size()]
	var traits := ["explode", "shield", "split", "dash"]
	if evolved_enemy_type != 1:
		traits.append("speed_boost")
	evolution_trait = traits[randi() % traits.size()]


func dev_skip_to_level(level: int) -> void:
	current_level = level
	pick_evolution()
	pressure_wave_active = false
	pressure_wave_timer = 0.0
	# Eğer oyun zaten çalışıyorsa signal gönder
	if current_state == GameState.PLAYING:
		dev_skip_to_level_requested.emit(level)


func start_game(shape: String, weapon_id: String) -> void:
	selected_shape = shape
	selected_weapon = weapon_id
	_reset_game_state()
	if _dev_start_level > 0:
		current_level = _dev_start_level
		_dev_start_level = 0
	pick_evolution()
	game_started.emit(shape, weapon_id)
	change_state(GameState.PLAYING)


func pause_game() -> void:
	if current_state != GameState.PLAYING:
		return
	get_tree().paused = true
	change_state(GameState.PAUSED)
	game_paused.emit()


func resume_game() -> void:
	if current_state != GameState.PAUSED and current_state != GameState.SETTINGS:
		return
	get_tree().paused = false
	change_state(GameState.PLAYING)
	game_resumed.emit()


func trigger_game_over() -> void:
	if death_timer >= 0:
		return
	death_timer = 1.8


func show_game_over() -> void:
	change_state(GameState.GAME_OVER)
	get_tree().paused = true
	game_over.emit()


func trigger_victory() -> void:
	change_state(GameState.VICTORY)
	get_tree().paused = true
	victory.emit()


func _reset_game_state() -> void:
	game_time = 0.0
	kill_count = 0
	skull_difficulty_mult = 1.0
	skull_score_mult = 1
	skulls_collected = 0
	current_level = 1
	final_boss_spawned = false
	first_boss_killed = false
	first_elite_spawned = false
	special_wave_active = false
	special_wave_minute = 0
	special_wave_timer = 0.0
	upgrade_rerolls = 5
	total_rerolls_used = 0
	death_timer = -1.0
	boss_active = null
	last_boss_spawn = 0.0
	damage_stats.clear()
	heal_stats.clear()
	run_coins = 0
	evolved_enemy_type = -1
	evolution_trait = ""
	pressure_wave_active = false
	pressure_wave_timer = 0.0


func reset_to_menu() -> void:
	get_tree().paused = false
	commit_run_coins()
	_reset_game_state()
	change_state(GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _load_settings() -> void:
	var saved = ConfigFile.new()
	if saved.load("user://settings.cfg") == OK:
		for key in settings.keys():
			settings[key] = saved.get_value("settings", key, settings[key])
	shake_intensity = settings.shake_intensity
	graphics_quality = settings.graphics_quality


func save_settings() -> void:
	var config = ConfigFile.new()
	for key in settings.keys():
		config.set_value("settings", key, settings[key])
	config.save("user://settings.cfg")


func _load_progress() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://progress.cfg") != OK:
		return
	total_coins = cfg.get_value("progress", "total_coins", 0)
	total_spent = cfg.get_value("progress", "total_spent", 0)
	current_level = cfg.get_value("progress", "current_level", 1)
	weapon_slots = cfg.get_value("progress", "weapon_slots", 2)
	passive_slots = cfg.get_value("progress", "passive_slots", 2)
	var raw_chars = cfg.get_value("progress", "unlocked_characters", ["circle"])
	unlocked_characters.assign(raw_chars)
	var raw_weapons = cfg.get_value("progress", "unlocked_weapons", ["wand", "shotgun", "blade", "aura"])
	unlocked_weapons.assign(raw_weapons)
	var raw_passives = cfg.get_value("progress", "unlocked_passives", ["p_shield", "p_hp", "p_xpboost", "p_speed"])
	unlocked_passives.assign(raw_passives)
	var raw_ultimates = cfg.get_value("progress", "unlocked_ultimates", [])
	unlocked_ultimates.assign(raw_ultimates)
	meta_stats = cfg.get_value("progress", "meta_stats", {
		"atk_speed": 0,
		"damage": 0,
		"max_hp": 0,
		"speed": 0,
		"crit_chance": 0,
	})


func save_progress() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "total_coins", total_coins)
	cfg.set_value("progress", "total_spent", total_spent)
	cfg.set_value("progress", "current_level", current_level)
	cfg.set_value("progress", "weapon_slots", weapon_slots)
	cfg.set_value("progress", "passive_slots", passive_slots)
	cfg.set_value("progress", "unlocked_characters", unlocked_characters)
	cfg.set_value("progress", "unlocked_weapons", unlocked_weapons)
	cfg.set_value("progress", "unlocked_passives", unlocked_passives)
	cfg.set_value("progress", "unlocked_ultimates", unlocked_ultimates)
	cfg.set_value("progress", "meta_stats", meta_stats)
	cfg.save("user://progress.cfg")


func add_coins(amount: int) -> void:
	run_coins += amount


func commit_run_coins() -> void:
	total_coins += run_coins
	run_coins = 0
	save_progress()


func get_meta_cost(stat_id: String) -> int:
	var level: int = meta_stats.get(stat_id, 0)
	return META_COST_BASE * (level + 1)


func get_slot_cost(is_weapon: bool) -> int:
	var current: int = weapon_slots if is_weapon else passive_slots
	return 200 * int(pow(2, current - 1))


func unlock_character(id: String, cost: int) -> bool:
	if total_coins < cost or unlocked_characters.has(id):
		return false
	total_coins -= cost
	total_spent += cost
	unlocked_characters.append(id)
	save_progress()
	return true


func unlock_weapon(id: String, cost: int) -> bool:
	if total_coins < cost or unlocked_weapons.has(id):
		return false
	total_coins -= cost
	total_spent += cost
	unlocked_weapons.append(id)
	save_progress()
	return true


func unlock_passive(id: String, cost: int) -> bool:
	if total_coins < cost or unlocked_passives.has(id):
		return false
	total_coins -= cost
	total_spent += cost
	unlocked_passives.append(id)
	save_progress()
	return true


func unlock_ultimate(id: String, cost: int) -> bool:
	if total_coins < cost or unlocked_ultimates.has(id):
		return false
	total_coins -= cost
	total_spent += cost
	unlocked_ultimates.append(id)
	save_progress()
	return true


func buy_slot(is_weapon: bool, cost: int) -> bool:
	if total_coins < cost:
		return false
	if is_weapon and weapon_slots >= 5:
		return false
	if not is_weapon and passive_slots >= 5:
		return false
	total_coins -= cost
	total_spent += cost
	if is_weapon:
		weapon_slots += 1
	else:
		passive_slots += 1
	save_progress()
	return true


func buy_meta_stat(stat_id: String) -> bool:
	var cost := get_meta_cost(stat_id)
	if total_coins < cost:
		return false
	if meta_stats.get(stat_id, 0) >= 5:
		return false
	total_coins -= cost
	total_spent += cost
	meta_stats[stat_id] = meta_stats.get(stat_id, 0) + 1
	save_progress()
	return true


func reset_all_progress() -> void:
	total_coins = 0
	total_spent = 0
	current_level = 1
	weapon_slots = 2
	passive_slots = 2
	unlocked_characters = ["circle"]
	unlocked_weapons = ["wand", "shotgun", "blade", "aura"]
	unlocked_passives = ["p_shield", "p_hp", "p_xpboost", "p_speed"]
	unlocked_ultimates = []
	meta_stats = {
		"atk_speed": 0,
		"damage": 0,
		"max_hp": 0,
		"speed": 0,
		"crit_chance": 0,
	}
	save_progress()
