extends CanvasLayer

@onready var upgrade_container: VBoxContainer = %UpgradeContainer
@onready var take_button: Button = %TakeButton
@onready var skip_button: Button = %SkipButton
@onready var title_label: Label = %Title

var _choices: Array[Dictionary] = []
var _rarity: int = 1


func setup(rarity: int) -> void:
	_rarity = rarity
	match rarity:
		1: title_label.text = "🎁 SANDIK"
		2: title_label.text = "🎁 NADİR SANDIK"
		3: title_label.text = "🎁 EFSANE SANDIK"


func _ready() -> void:
	get_tree().paused = true
	GameManager.change_state(GameManager.GameState.CHEST)
	AudioManager.set_lofi(true)
	_show_choices()
	take_button.pressed.connect(_on_take)
	skip_button.pressed.connect(_on_skip)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP:
				_move_focus(-1)
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_S, KEY_DOWN:
				_move_focus(1)
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				var focused := get_viewport().gui_get_focus_owner()
				if focused and focused is Button:
					focused.emit_signal("pressed")
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_ESCAPE:
				_on_skip()
				if get_viewport(): get_viewport().set_input_as_handled()
				return


func _move_focus(dir: int) -> void:
	var buttons: Array[Control] = []
	for child in upgrade_container.get_children():
		if child is Control:
			buttons.append(child)
	buttons.append(take_button)
	buttons.append(skip_button)

	var focused := get_viewport().gui_get_focus_owner()
	var current_idx := -1
	for i in buttons.size():
		if buttons[i] == focused:
			current_idx = i
			break

	if current_idx < 0:
		if buttons.size() > 0:
			buttons[0].grab_focus()
		return

	var next_idx := clampi(current_idx + dir, 0, buttons.size() - 1)
	buttons[next_idx].grab_focus()


func _show_choices() -> void:
	for child in upgrade_container.get_children():
		child.queue_free()

	var pool := _build_chest_pool()
	if pool.is_empty():
		_close()
		return

	pool.shuffle()
	var choice_count := _rarity
	_choices = pool.slice(0, mini(choice_count, pool.size()))

	for i in _choices.size():
		var c: Dictionary = _choices[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 60)
		btn.focus_mode = Control.FOCUS_ALL

		if c.type == "coin":
			btn.text = "%s  %s\n%s" % [c.icon, c.name, c.desc]
		else:
			var cur_level := 0
			var detail_text := ""
			if c.type == "weapon":
				var w := _find_weapon(c.id)
				if w:
					cur_level = w.level
					if cur_level > 0:
						detail_text = _get_weapon_upgrade_text(c.id, cur_level)
			else:
				cur_level = _get_passive_level(c.id)
				if cur_level > 0:
					detail_text = _get_passive_upgrade_text(c.id, cur_level)

			if detail_text != "":
				btn.text = "%s  %s  Lv.%d → %d\n%s" % [c.icon, c.name, cur_level, cur_level + 1, detail_text]
			else:
				btn.text = "%s  %s\n%s" % [c.icon, c.name, c.desc]
		upgrade_container.add_child(btn)

	if upgrade_container.get_child_count() > 0:
		take_button.call_deferred("grab_focus")


func _get_weapon_upgrade_text(weapon_id: String, cur_level: int) -> String:
	var wm := _get_weapon_manager()
	if not wm:
		return ""
	var w := _find_weapon(weapon_id)
	if not w:
		return ""
	
	var dmg_now := w.base_damage + (cur_level - 1) * w.base_damage * 0.15
	var dmg_next := w.base_damage + cur_level * w.base_damage * 0.15
	var rng_now := w.base_range + (cur_level - 1) * 15.0
	var rng_next := w.base_range + cur_level * 15.0
	
	return "%s\nHasar: %.0f → %.0f | Menzil: %.0f → %.0f" % [w.desc, dmg_now, dmg_next, rng_now, rng_next]


func _get_passive_upgrade_text(passive_id: String, cur_level: int) -> String:
	var player := GameManager.player
	if passive_id == "p_shield" and player:
		var cur_shield := int(player.max_shield)
		var new_shield := cur_shield + 15
		return "Kalkan: %d → %d" % [cur_shield, new_shield]

	var per_level_vals := {
		"p_speed": [cur_level * 15, (cur_level + 1) * 15],
		"p_atk_speed": [cur_level * 20, (cur_level + 1) * 20],
		"p_crit": [cur_level * 10, (cur_level + 1) * 10],
		"p_dmg": [cur_level * 20, (cur_level + 1) * 20],
		"p_proj": [cur_level, cur_level + 1],
		"p_hp": [cur_level * 30, (cur_level + 1) * 30],
		"p_magnet": [cur_level * 25, (cur_level + 1) * 25],
		"p_evasion": [cur_level * 5, (cur_level + 1) * 5],
		"p_vampir": [cur_level * 2, (cur_level + 1) * 2],
		"p_critdmg": [cur_level * 50, (cur_level + 1) * 50],
		"p_regen": [cur_level, cur_level + 1],
		"p_xpboost": [cur_level * 25, (cur_level + 1) * 25],
		"p_size": [cur_level * 20, (cur_level + 1) * 20],
	}
	var vals: Array = per_level_vals.get(passive_id, [0, 0])
	var labels := {
		"p_speed": "Hareket hizi",
		"p_atk_speed": "Saldiri hizi",
		"p_crit": "Kritik sansi",
		"p_dmg": "Hasar",
		"p_proj": "Ek mermi",
		"p_hp": "Max HP",
		"p_magnet": "Toplama mesafesi",
		"p_evasion": "Dodge sansi",
		"p_vampir": "Vampirizm",
		"p_critdmg": "Kritik hasar",
		"p_regen": "HP regen",
		"p_xpboost": "XP bonusu",
		"p_size": "Alan etkisi",
	}
	var label: String = labels.get(passive_id, "")
	return "%s: %d → %d" % [label, vals[0], vals[1]]


func _build_chest_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var wm := _get_weapon_manager()
	if not wm:
		return pool

	var active_weapons: Array[WeaponData] = wm.get_active_weapons()
	var at_weapon_cap: bool = active_weapons.size() >= GameManager.weapon_slots

	for w in wm.weapons:
		if not GameManager.unlocked_weapons.has(w.id):
			continue
		if w.level > 0 and w.level < w.max_level:
			pool.append({
				"id": w.id,
				"name": w.name,
				"desc": w.desc,
				"icon": w.icon,
				"type": "weapon",
			})
		elif w.level == 0 and not at_weapon_cap:
			pool.append({
				"id": w.id,
				"name": w.name,
				"desc": w.desc,
				"icon": w.icon,
				"type": "weapon",
			})

	var all_passives := [
		{"id": "p_speed", "name": "Hız Modülü", "desc": "Hareket hızını %15 artırır.", "icon": "👟", "type": "passive"},
		{"id": "p_atk_speed", "name": "Hız Aşırtma", "desc": "Saldırı hızını %20 artırır.", "icon": "🔋", "type": "passive"},
		{"id": "p_crit", "name": "Optik Vizör", "desc": "Kritik şansı %10 artırır.", "icon": "🎯", "type": "passive"},
		{"id": "p_dmg", "name": "Güç Çekirdeği", "desc": "Tüm hasarı %20 artırır.", "icon": "🔥", "type": "passive"},
		{"id": "p_proj", "name": "Çoklu Kanal", "desc": "+1 ek mermi/etki.", "icon": "➕", "type": "passive"},
		{"id": "p_hp", "name": "Yenileme", "desc": "+30 max HP, tam doldurma.", "icon": "🧪", "type": "passive"},
		{"id": "p_magnet", "name": "Mıknatıs", "desc": "Toplama mesafesi %50 artar.", "icon": "🧲", "type": "passive"},
		{"id": "p_evasion", "name": "Refleks", "desc": "%10 dodge şansı.", "icon": "💨", "type": "passive"},
		{"id": "p_shield", "name": "Enerji Kalkanı", "desc": "+15 kalkan, 8/s yenilenir.", "icon": "🛡️", "type": "passive"},
		{"id": "p_vampir", "name": "Vampirizm", "desc": "Hasarın %0.02'sini HP olarak al.", "icon": "🩸", "type": "passive"},
		{"id": "p_critdmg", "name": "Hayati Darbe", "desc": "Kritik hasar +0.5x.", "icon": "💀", "type": "passive"},
		{"id": "p_regen", "name": "Biyorejenerasyon", "desc": "+1 HP/10sn.", "icon": "💚", "type": "passive"},
		{"id": "p_xpboost", "name": "Veri Madenciliği", "desc": "XP %25 artar.", "icon": "📚", "type": "passive"},
		{"id": "p_size", "name": "Genişleme", "desc": "Alan etkileri +%20 büyür.", "icon": "🔮", "type": "passive"},
	]

	var player := GameManager.player
	if player:
		for pd in all_passives:
			if not GameManager.unlocked_passives.has(pd.id):
				continue
			if _has_passive(pd.id) or _count_passives() < GameManager.passive_slots:
				pool.append(pd)

	# 10% chance to add coins as a choice
	if randf() < 0.1:
		pool.append({"id": "coin_bonus", "name": "Altın", "desc": "Anında 25 coin kazan.", "icon": "💰", "type": "coin"})

	return pool


func _on_take() -> void:
	if _choices.is_empty():
		_close()
		return

	var player := GameManager.player
	if not player:
		_close()
		return

	for choice in _choices:
		if choice.type == "coin":
			GameManager.add_coins(25)
		elif choice.type == "weapon":
			var wm := _get_weapon_manager()
			if wm:
				var w := _find_weapon(choice.id)
				if w and w.level > 0:
					wm.upgrade_weapon(choice.id)
				elif w:
					wm.add_weapon(choice.id)
		else:
			_apply_passive(choice.id, player)

	_close()


func _on_skip() -> void:
	_close()


func _apply_passive(id: String, p: Player) -> void:
	match id:
		"p_speed": p.stats.speed *= 1.15
		"p_atk_speed": p.attack_speed_mult += 0.15
		"p_crit": p.crit_chance += 0.1
		"p_dmg": p.damage_mult += 0.15
		"p_proj": p.projectile_count += 1
		"p_hp": p.add_max_hp(25)
		"p_magnet": p.pickup_radius *= 1.25
		"p_evasion": p.evasion += 0.05
		"p_shield":
			p.max_shield += 15
			p.shield += 15
			p.shield_regen = maxf(p.shield_regen, 8.0)
			p.shield_changed.emit(p.shield, p.max_shield)
		"p_vampir": p.life_steal += 0.0002
		"p_critdmg": p.crit_mult += 0.4
		"p_regen": p.hp_regen += 0.1
		"p_xpboost": p.xp_boost += 0.25
		"p_size": p.aoe_mult += 0.2

	if not p.passives.has(id):
		p.passives.append(id)


func _get_passive_level(id: String) -> int:
	var player := GameManager.player
	if not player:
		return 0
	var count := 0
	for pid in player.passives:
		if pid == id:
			count += 1
	return count


func _has_passive(id: String) -> bool:
	var player := GameManager.player
	if not player:
		return false
	return player.passives.has(id)


func _count_passives() -> int:
	var player := GameManager.player
	if not player:
		return 0
	return player.passives.size()


func _close() -> void:
	AudioManager.set_lofi(false)
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)
	if GameManager.player and GameManager.player.has_method("block_inputs"):
		GameManager.player.block_inputs(0.2)
	queue_free()


func _get_weapon_manager() -> Node:
	if not GameManager.player:
		return null
	return GameManager.player.get_node_or_null("WeaponManager")


func _find_weapon(weapon_id: String) -> WeaponData:
	var wm := _get_weapon_manager()
	if not wm:
		return null
	for w in wm.weapons:
		if w.id == weapon_id:
			return w
	return null
