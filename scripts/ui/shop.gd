extends Control

@onready var back_button: Button = $TopBar/BackButton
@onready var reset_button: Button = $TopBar/ResetButton
@onready var coin_label: Label = $ScrollContainer/VBoxContainer/CoinLabel
@onready var item_container: VBoxContainer = $ScrollContainer/VBoxContainer

var _characters: Array[Dictionary] = [
	{"id": "square", "name": "KARE", "desc": "200 HP, 25 Kalkan. Ozel: Kalkan patlamasi.", "cost": 100},
	{"id": "triangle", "name": "UCGEN", "desc": "100 HP, +%20 Hiz, +%25 Kritik. Ozel: Zehir bulutu.", "cost": 150},
]

var _weapons: Array[Dictionary] = [
	{"id": "lightning", "name": "Tesla Bobini", "desc": "Dusmanlar arasi seken elektrik.", "cost": 80},
	{"id": "mine", "name": "Zaman Ayarli Mayin", "desc": "Yere guclu patlayicilar birakir.", "cost": 60},
	{"id": "laser", "name": "Yorunge Lazer", "desc": "Rastgele alanlara dikey saldiri.", "cost": 90},
	{"id": "frost", "name": "Buz Novasi", "desc": "Dusmanlari dondurur ve yavaslatir.", "cost": 70},
	{"id": "rocket", "name": "Roketatar", "desc": "Devasa patlayan roketler.", "cost": 100},
	{"id": "boomerang", "name": "Bumerang", "desc": "Geri donen olumcul disk.", "cost": 60},
	{"id": "flamethrower", "name": "Alev Thrower", "desc": "Yakin mesafe surekli ates.", "cost": 70},
	{"id": "machinegun", "name": "Makineli Tufek", "desc": "Cok hizli mermi yagmuru.", "cost": 80},
	{"id": "sniper", "name": "Keskin Nisanci", "desc": "Cok uzak menzilli tek atis.", "cost": 90},
	{"id": "nova_pulse", "name": "Nova Darbesi", "desc": "Cevrede yayilan enerji halkasi.", "cost": 100},
	{"id": "blackhole", "name": "Kara Delik", "desc": "Dusmanlari icine ceker.", "cost": 120},
	{"id": "dagger_storm", "name": "Hancer Firtinasi", "desc": "8 yonde es zamanli hancer.", "cost": 80},
	{"id": "poison_arrow", "name": "Zehirli Ok", "desc": "Zehirli ok atar.", "cost": 70},
]

var _passives: Array[Dictionary] = [
	{"id": "p_atk_speed", "name": "Hiz Asirtma", "desc": "Saldiri hizini %20 artirir.", "cost": 60},
	{"id": "p_crit", "name": "Optik Vizor", "desc": "Kritik sansi %10 artirir.", "cost": 80},
	{"id": "p_dmg", "name": "Guc Cekirdegi", "desc": "Tum hasari %20 artirir.", "cost": 90},
	{"id": "p_proj", "name": "Coklu Kanal", "desc": "+1 ek mermi/etki.", "cost": 100},
	{"id": "p_magnet", "name": "Miknatis", "desc": "Toplama mesafesi %50 artar.", "cost": 50},
	{"id": "p_evasion", "name": "Refleks", "desc": "%10 dodge sansi.", "cost": 70},
	{"id": "p_vampir", "name": "Vampirizm", "desc": "Hasarin %0.02'sini HP olarak al.", "cost": 100},
	{"id": "p_critdmg", "name": "Hayati Darbe", "desc": "Kritik hasar +0.5x.", "cost": 90},
	{"id": "p_regen", "name": "Biyorejenerasyon", "desc": "+1 HP/10sn.", "cost": 60},
	{"id": "p_size", "name": "Genisleme", "desc": "Alan etkileri +%20 buyur.", "cost": 50},
]

var _ultimates: Array[Dictionary] = [
	{"id": "circle", "name": "Daire Ultisi", "desc": "5 saniye %100 saldiri hizi.", "cost": 300},
	{"id": "square", "name": "Kare Ultisi", "desc": "Kalkani patlatir ve hasar verir.", "cost": 300},
	{"id": "triangle", "name": "Ucgen Ultisi", "desc": "Ileri atilma ve zehir bulutu.", "cost": 300},
]

var _meta_stats: Array[Dictionary] = [
	{"id": "atk_speed", "name": "Saldiri Hizi", "desc": "Tum karakterler +%5 saldiri hizi.", "per_level": 5},
	{"id": "damage", "name": "Hasar", "desc": "Tum karakterler +%5 hasar.", "per_level": 5},
	{"id": "max_hp", "name": "Max HP", "desc": "Tum karakterler +10 max HP.", "per_level": 10},
	{"id": "speed", "name": "Hareket Hizi", "desc": "Tum karakterler +%5 hiz.", "per_level": 5},
	{"id": "crit_chance", "name": "Kritik Sans", "desc": "Tum karakterler +%3 kritik sans.", "per_level": 3},
]


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	_render_shop()
	back_button.grab_focus()


func _render_shop() -> void:
	coin_label.text = "%d Coin" % GameManager.total_coins

	for child in item_container.get_children():
		if child != coin_label:
			child.queue_free()

	_add_category_title("KARAKTERLER")
	for item in _characters:
		var unlocked := GameManager.unlocked_characters.has(item.id)
		_add_item_row(item.name, item.desc, item.cost, unlocked, func(): _buy_character(item))

	_add_category_title("SILAHLAR")
	for item in _weapons:
		var unlocked := GameManager.unlocked_weapons.has(item.id)
		_add_item_row(item.name, item.desc, item.cost, unlocked, func(): _buy_weapon(item))

	_add_category_title("PASIFLER")
	for item in _passives:
		var unlocked := GameManager.unlocked_passives.has(item.id)
		_add_item_row(item.name, item.desc, item.cost, unlocked, func(): _buy_passive(item))

	_add_category_title("SLOTLAR")
	var w_slot_cost := GameManager.get_slot_cost(true)
	var w_maxed := GameManager.weapon_slots >= 5
	_add_item_row("Silah Slotu +1", "Maksimum silah sayisini artirir.", w_slot_cost, w_maxed, func(): _buy_slot(true))

	var p_slot_cost := GameManager.get_slot_cost(false)
	var p_maxed := GameManager.passive_slots >= 5
	_add_item_row("Pasif Slotu +1", "Maksimum pasif sayisini artirir.", p_slot_cost, p_maxed, func(): _buy_slot(false))

	_add_category_title("ULTIMATELER")
	for item in _ultimates:
		var unlocked := GameManager.unlocked_ultimates.has(item.id)
		_add_item_row(item.name, item.desc, item.cost, unlocked, func(): _buy_ultimate(item))

	_add_category_title("META ISTATISTIKLER")
	for item in _meta_stats:
		var level: int = GameManager.meta_stats.get(item.id, 0)
		var cost := GameManager.get_meta_cost(item.id)
		var maxed := level >= 5
		var desc := "%s (Seviye %d/10)" % [item.desc, level]
		_add_item_row(item.name, desc, cost, maxed, func(): _buy_meta(item))


func _add_category_title(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.6, 0.7, 1))
	item_container.add_child(lbl)


func _add_item_row(name_str: String, desc: String, cost: int, owned: bool, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = name_str
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.3, 0.5, 0.55, 1))
	info.add_child(desc_lbl)

	row.add_child(info)

	if owned:
		var owned_lbl := Label.new()
		owned_lbl.text = "ACIK"
		owned_lbl.add_theme_color_override("font_color", Color(0.2, 0.65, 0.35, 1))
		row.add_child(owned_lbl)
	else:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(100, 34)
		if GameManager.total_coins >= cost:
			btn.text = "%d" % cost
			btn.pressed.connect(callback)
		else:
			btn.text = "%d" % cost
			btn.disabled = true
		row.add_child(btn)

	item_container.add_child(row)


func _buy_character(item: Dictionary) -> void:
	if GameManager.unlock_character(item.id, item.cost):
		AudioManager.play_sfx(AudioManager.SFXType.LEVEL_UP)
		_render_shop()


func _buy_weapon(item: Dictionary) -> void:
	if GameManager.unlock_weapon(item.id, item.cost):
		AudioManager.play_sfx(AudioManager.SFXType.LEVEL_UP)
		_render_shop()


func _buy_passive(item: Dictionary) -> void:
	if GameManager.unlock_passive(item.id, item.cost):
		AudioManager.play_sfx(AudioManager.SFXType.LEVEL_UP)
		_render_shop()


func _buy_slot(is_weapon: bool) -> void:
	var cost := GameManager.get_slot_cost(is_weapon)
	if GameManager.buy_slot(is_weapon, cost):
		AudioManager.play_sfx(AudioManager.SFXType.LEVEL_UP)
		_render_shop()


func _buy_ultimate(item: Dictionary) -> void:
	if GameManager.unlock_ultimate(item.id, item.cost):
		AudioManager.play_sfx(AudioManager.SFXType.LEVEL_UP)
		_render_shop()


func _buy_meta(item: Dictionary) -> void:
	if GameManager.buy_meta_stat(item.id):
		AudioManager.play_sfx(AudioManager.SFXType.LEVEL_UP)
		_render_shop()


func _on_back_pressed() -> void:
	GameManager.reset_to_menu()


func _on_reset_pressed() -> void:
	GameManager.reset_all_progress()
	_render_shop()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER:
				var focused := get_viewport().gui_get_focus_owner()
				if focused and focused is Button:
					focused.emit_signal("pressed")
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_ESCAPE:
				_on_back_pressed()
				if get_viewport(): get_viewport().set_input_as_handled()
				return
