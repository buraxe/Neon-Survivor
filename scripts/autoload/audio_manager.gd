extends Node

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 12

enum SFXType {
	GEM_PICKUP,
	ENEMY_DEATH,
	LEVEL_UP,
	BOSS_SPAWN,
	DAMAGE,
	SHOOT,
	EXPLOSION,
	CHEST_OPEN,
	SHRINE_CHARGE,
	POWERUP,
}

var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _lofi_lpf_idx: int = -1
var _lofi_hpf_idx: int = -1
var _lofi_active: bool = false
var _target_volume_db: float = 0.0
var _music_tween: Tween = null


func _ready() -> void:
	_ensure_audio_buses()
	
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)
	
	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)
	
	_setup_lofi_filter()
	_preload_all_sfx()
	_preload_all_music()
	set_music_volume(GameManager.settings.music_volume)
	set_sfx_volume(GameManager.settings.sfx_volume)


func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
		AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")


func _setup_lofi_filter() -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx < 0:
		return
	
	var lpf := AudioEffectLowPassFilter.new()
	lpf.cutoff_hz = 20500.0
	lpf.resonance = 0.5
	_lofi_lpf_idx = AudioServer.get_bus_effect_count(bus_idx)
	AudioServer.add_bus_effect(bus_idx, lpf)
	
	var hpf := AudioEffectHighPassFilter.new()
	hpf.cutoff_hz = 10.0
	hpf.resonance = 0.5
	_lofi_hpf_idx = AudioServer.get_bus_effect_count(bus_idx)
	AudioServer.add_bus_effect(bus_idx, hpf)


var _lofi_tween_progress: float = 0.0
var _lofi_tweening: bool = false
var _lofi_target: float = 0.0


func set_lofi(enabled: bool) -> void:
	if _lofi_active == enabled and not _lofi_tweening:
		return
	_lofi_active = enabled
	_lofi_target = 1.0 if enabled else 0.0
	_lofi_tween_progress = 0.0
	_lofi_tweening = true


func _process(delta: float) -> void:
	if _lofi_tweening:
		_lofi_tween_progress += delta / 0.5
		if _lofi_tween_progress >= 1.0:
			_lofi_tween_progress = 1.0
			_lofi_tweening = false
		
		var t := _lofi_tween_progress
		var bus_idx := AudioServer.get_bus_index("Music")
		if bus_idx < 0:
			return
		var lpf_effect: AudioEffectLowPassFilter = AudioServer.get_bus_effect(bus_idx, _lofi_lpf_idx)
		var hpf_effect: AudioEffectHighPassFilter = AudioServer.get_bus_effect(bus_idx, _lofi_hpf_idx)
		if not lpf_effect or not hpf_effect:
			return
		
		var lpf_cutoff: float = lerp(20500.0, 4000.0, t) if _lofi_target > 0.5 else lerp(4000.0, 20500.0, t)
		var hpf_cutoff: float = lerp(10.0, 400.0, t) if _lofi_target > 0.5 else lerp(400.0, 10.0, t)
		lpf_effect.cutoff_hz = lpf_cutoff
		hpf_effect.cutoff_hz = hpf_cutoff


func _preload_all_sfx() -> void:
	for type in SFXType.values():
		_sfx_cache[type] = _generate_sfx(type)


func _preload_all_music() -> void:
	_music_cache["main_theme"] = preload("res://assets/audio/music/main_theme.ogg")
	_music_cache["fight_1"] = preload("res://assets/audio/music/fight_1.ogg")
	_music_cache["fight_2"] = preload("res://assets/audio/music/fight_2.ogg")
	_music_cache["boss_theme"] = preload("res://assets/audio/music/boss_theme.ogg")
	
	for key in _music_cache:
		var stream: AudioStream = _music_cache[key]
		if stream is AudioStream:
			stream.loop = true


func play_music_by_name(track_name: String, fade_time: float = 1.0) -> void:
	var stream: AudioStream = _music_cache.get(track_name)
	if stream:
		play_music(stream, fade_time)


func play_sfx(type: SFXType) -> void:
	var stream: AudioStreamWAV = _sfx_cache.get(type)
	if not stream:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return


func play_music(stream: AudioStream, fade_time: float = 1.0) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	
	if _music_player.playing:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_time * 0.5)
		_music_tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = -80.0
			_music_player.play()
		)
		_music_tween.tween_property(_music_player, "volume_db", _target_volume_db, fade_time * 0.5)
	else:
		_music_player.stream = stream
		_music_player.volume_db = _target_volume_db
		_music_player.play()


func stop_music(fade_time: float = 1.0) -> void:
	if not _music_player.playing:
		return
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_time)
	_music_tween.tween_callback(_music_player.stop)


func stop_all_sfx() -> void:
	for player in _sfx_players:
		player.stop()


func set_music_volume(volume: int) -> void:
	_target_volume_db = linear_to_db(volume / 100.0)
	if _music_player.playing and (_music_tween == null or not _music_tween.is_valid()):
		_music_player.volume_db = _target_volume_db


func set_sfx_volume(volume: int) -> void:
	var db := linear_to_db(volume / 100.0)
	for player in _sfx_players:
		player.volume_db = db


func _generate_sfx(type: SFXType) -> AudioStreamWAV:
	var samples: PackedFloat32Array = []
	var sample_rate := 44100.0
	
	match type:
		SFXType.GEM_PICKUP:
			for i in 2205:
				var t := float(i) / sample_rate
				var freq := 800.0 + t * 4000.0
				var env := exp(-t * 40.0)
				samples.append(sin(t * freq * TAU) * env * 0.3)
		
		SFXType.ENEMY_DEATH:
			for i in 8820:
				var t := float(i) / sample_rate
				var env := exp(-t * 15.0)
				samples.append((randf() * 2.0 - 1.0) * env * 0.2)
		
		SFXType.LEVEL_UP:
			for i in 22050:
				var t := float(i) / sample_rate
				var freq := 400.0 + t * 1200.0
				var env := exp(-t * 4.0)
				samples.append(sin(t * freq * TAU) * env * 0.25)
		
		SFXType.BOSS_SPAWN:
			for i in 44100:
				var t := float(i) / sample_rate
				var freq := 60.0 + sin(t * 3.0) * 20.0
				var env := exp(-t * 2.0)
				samples.append(sin(t * freq * TAU) * env * 0.3)
		
		SFXType.DAMAGE:
			for i in 4410:
				var t := float(i) / sample_rate
				var env := exp(-t * 30.0)
				samples.append(sin(t * 200.0 * TAU) * env * 0.3)
		
		SFXType.SHOOT:
			for i in 2205:
				var t := float(i) / sample_rate
				var env := exp(-t * 50.0)
				samples.append(sin(t * 600.0 * TAU) * env * 0.15)
		
		SFXType.EXPLOSION:
			for i in 22050:
				var t := float(i) / sample_rate
				var freq := 80.0 * exp(-t * 5.0)
				var env := exp(-t * 6.0)
				samples.append(sin(t * freq * TAU) * env * 0.35)
		
		SFXType.CHEST_OPEN:
			for i in 22050:
				var t := float(i) / sample_rate
				var freq := 1200.0 + sin(t * 20.0) * 400.0
				var env := exp(-t * 5.0)
				samples.append(sin(t * freq * TAU) * env * 0.2)
		
		SFXType.SHRINE_CHARGE:
			for i in 17640:
				var t := float(i) / sample_rate
				var freq := 300.0 + t * 2000.0
				var env := exp(-t * 3.0)
				samples.append(sin(t * freq * TAU) * env * 0.2)
		
		SFXType.POWERUP:
			for i in 17640:
				var t := float(i) / sample_rate
				var env := exp(-t * 5.0)
				var val := (sin(t * 523.0 * TAU) + sin(t * 659.0 * TAU) + sin(t * 784.0 * TAU)) / 3.0 * env * 0.2
				samples.append(val)
	
	if samples.is_empty():
		return null
	
	var wav := AudioStreamWAV.new()
	var data := PackedByteArray()
	for s in samples:
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		data.append(val & 0xFF)
		data.append((val >> 8) & 0xFF)
	
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 44100
	wav.stereo = false
	
	return wav
