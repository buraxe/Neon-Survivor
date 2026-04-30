extends CanvasLayer

var max_weapons: int = 1
var max_passives: int = 1

@onready var upgrade_container: VBoxContainer = %UpgradeContainer
@onready var reroll_button: Button = %RerollButton
@onready var skip_button: Button = %SkipButton

var _full_pool: Array[Dictionary] = []


func _ready() -> void:
	max_weapons = GameManager.weapon_slots
	max_passives = GameManager.passive_slots
	AudioManager.set_lofi(true)
	_build_pool()
	_show_choices()
	reroll_button.pressed.connect(_on_reroll)
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
	buttons.append(reroll_button)
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


func _build_pool() -> void:
	_full_pool.clear()
	var wm := _get_weapon_manager()
	if not wm:
		return

	for w in wm.weapons:
		if GameManager.unlocked_weapons.has(w.id):
			_full_pool.append({
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
	for p in all_passives:
		if GameManager.unlocked_passives.has(p.id):
			_full_pool.append(p)


func _show_choices() -> void:
	for child in upgrade_container.get_children():
		child.queue_free()

	var rerolls_left := 5 - GameManager.total_rerolls_used
	reroll_button.text = "🔀 YENİLE (%d)" % rerolls_left
	reroll_button.disabled = rerolls_left <= 0

	var valid := _get_valid_pool()
	if valid.is_empty():
		return

	valid.shuffle()
	var choices := valid.slice(0, mini(3, valid.size()))

	for i in choices.size():
		var c: Dictionary = choices[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 70)
		btn.focus_mode = Control.FOCUS_ALL

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
		var choice: Dictionary = c.duplicate()
		btn.pressed.connect(func(): _apply_choice(choice))
		upgrade_container.add_child(btn)

	if upgrade_container.get_child_count() > 0:
		var first := upgrade_container.get_child(0) as Control
		first.call_deferred("grab_focus")


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
	
	var lines := []
	lines.append(w.desc)
	lines.append("Hasar: %.0f → %.0f | Menzil: %.0f → %.0f" % [dmg_now, dmg_next, rng_now, rng_next])
	return "\n".join(lines)


func _get_passive_upgrade_text(passive_id: String, cur_level: int) -> String:
	var player := GameManager.player
	if passive_id == "p_shield" and player:
		var cur_shield := int(player.max_shield)
		var new_shield := cur_shield + 15
		return "Kalkan: %d → %d" % [cur_shield, new_shield]

	var per_level := {
		"p_speed": "Hareket hizi: +%d",
		"p_atk_speed": "Saldiri hizi: +%d%%",
		"p_crit": "Kritik sansi: +%d%%",
		"p_dmg": "Hasar: +%d%%",
		"p_proj": "Ek mermi: +%d",
		"p_hp": "Max HP: +%d",
		"p_magnet": "Toplama mesafesi: +%d%%",
		"p_evasion": "Dodge sansi: +%d%%",
		"p_vampir": "Vampirizm: +%d%%",
		"p_critdmg": "Kritik hasar: +%d%%",
		"p_regen": "HP regen: +%d/10sn",
		"p_xpboost": "XP bonusu: +%d%%",
		"p_size": "Alan etkisi: +%d%%",
	}
	var fmt: String = per_level.get(passive_id, "")
	if fmt == "":
		return ""
	var val := 0
	match passive_id:
		"p_speed": val = int(cur_level * 15)
		"p_atk_speed": val = int(cur_level * 15)
		"p_crit": val = int(cur_level * 10)
		"p_dmg": val = int(cur_level * 15)
		"p_proj": val = cur_level
		"p_hp": val = int(cur_level * 25)
		"p_magnet": val = int(cur_level * 25)
		"p_evasion": val = int(cur_level * 5)
		"p_vampir": val = int(cur_level * 2)
		"p_critdmg": val = int(cur_level * 40)
		"p_regen": val = cur_level
		"p_xpboost": val = int(cur_level * 25)
		"p_size": val = int(cur_level * 20)
	
	var next_val := 0
	match passive_id:
		"p_speed": next_val = int((cur_level + 1) * 15)
		"p_atk_speed": next_val = int((cur_level + 1) * 15)
		"p_crit": next_val = int((cur_level + 1) * 10)
		"p_dmg": next_val = int((cur_level + 1) * 15)
		"p_proj": next_val = cur_level + 1
		"p_hp": next_val = int((cur_level + 1) * 25)
		"p_magnet": next_val = int((cur_level + 1) * 50)
		"p_evasion": next_val = int((cur_level + 1) * 5)
		"p_vampir": next_val = int((cur_level + 1) * 2)
		"p_critdmg": next_val = int((cur_level + 1) * 40)
		"p_regen": next_val = cur_level + 1
		"p_xpboost": next_val = int((cur_level + 1) * 25)
		"p_size": next_val = int((cur_level + 1) * 20)
	
	return "%s → %d" % [fmt % val, next_val]


func _get_valid_pool() -> Array:
	var wm := _get_weapon_manager()
	if not wm:
		return []

	var active: Array = wm.get_active_weapons()
	var at_weapon_cap: bool = active.size() >= max_weapons
	var at_passive_cap: bool = _count_passives() >= max_passives

	var result: Array = []
	for item in _full_pool:
		if item.type == "weapon":
			var w := _find_weapon(item.id)
			if not w:
				continue
			if w.level == 0 and at_weapon_cap:
				continue
			if w.level >= w.max_level:
				continue
			result.append(item)
		else:
			if at_passive_cap and not _has_passive(item.id):
				continue
			result.append(item)

	return result


func _apply_choice(choice: Dictionary) -> void:
	var player := GameManager.player
	if not player:
		return

	if choice.type == "weapon":
		var wm := _get_weapon_manager()
		if wm:
			var w := _find_weapon(choice.id)
			if w:
				if w.level == 0:
					wm.add_weapon(choice.id)
				else:
					wm.upgrade_weapon(choice.id)
	else:
		_apply_passive(choice.id, player)

	_close_and_resume()


func _on_skip() -> void:
	_close_and_resume()


func _apply_passive(id: String, p: Player) -> void:
	match id:
		"p_speed":
			p.stats.speed *= 1.15
		"p_atk_speed":
			p.attack_speed_mult += 0.15
		"p_crit":
			p.crit_chance += 0.1
		"p_dmg":
			p.damage_mult += 0.15
		"p_proj":
			p.projectile_count += 1
		"p_hp":
			p.add_max_hp(25)
		"p_magnet":
			p.pickup_radius *= 1.25
		"p_evasion":
			p.evasion += 0.05
		"p_shield":
			p.max_shield += 15
			p.shield += 15
			p.shield_regen = maxf(p.shield_regen, 8.0)
			p.shield_changed.emit(p.shield, p.max_shield)
		"p_vampir":
			p.life_steal += 0.0002
		"p_critdmg":
			p.crit_mult += 0.4
		"p_regen":
			p.hp_regen += 0.1
		"p_xpboost":
			p.xp_boost += 0.25
		"p_size":
			p.aoe_mult += 0.2

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


func _on_reroll() -> void:
	var rerolls_left := 5 - GameManager.total_rerolls_used
	if rerolls_left <= 0:
		return
	GameManager.total_rerolls_used += 1
	_show_choices()


func _close_and_resume() -> void:
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
