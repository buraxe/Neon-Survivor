extends Control

const WEAPONS_PER_PAGE := 6
var _current_page := 0
var _focused_idx := 0

var weapon_catalog: Array[Dictionary] = [
	{"id": "wand", "name": "Plazma Asa", "desc": "Güdümlü enerji topları fırlatır.", "icon": "🪄"},
	{"id": "shotgun", "name": "Pompalı", "desc": "Yakın mesafe katliam.", "icon": "🔫"},
	{"id": "blade", "name": "Nano Bıçak", "desc": "Etrafınızda ölümcül dönüş.", "icon": "⚔️"},
	{"id": "lightning", "name": "Tesla Bobini", "desc": "Düşmanlar arası seken elektrik.", "icon": "⚡"},
	{"id": "mine", "name": "Zaman Ayarlı Mayın", "desc": "Yere güçlü patlayıcılar bırakır.", "icon": "💣"},
	{"id": "aura", "name": "Radyasyon", "desc": "Yakındakileri sürekli eritir.", "icon": "☢️"},
	{"id": "laser", "name": "Yörünge Lazer", "desc": "Rastgele alanlara dikey saldırı.", "icon": "☄️"},
	{"id": "frost", "name": "Buz Novası", "desc": "Düşmanları dondurur ve yavaşlatır.", "icon": "❄️"},
	{"id": "rocket", "name": "Roketatar", "desc": "Devasa patlayan roketler.", "icon": "🚀"},
	{"id": "boomerang", "name": "Bumerang", "desc": "Geri dönen ölümcül disk.", "icon": "🪃"},
	{"id": "flamethrower", "name": "Alev Thrower", "desc": "Yakın mesafe sürekli ateş.", "icon": "🔥"},
	{"id": "machinegun", "name": "Makineli Tüfek", "desc": "Çok hızlı mermi yağmuru.", "icon": "🔫"},
	{"id": "sniper", "name": "Keskin Nişancı", "desc": "Çok uzak menzilli tek atış.", "icon": "🎯"},
	{"id": "nova_pulse", "name": "Nova Darbesi", "desc": "Çevrede yayılan enerji halkası.", "icon": "🌀"},
	{"id": "blackhole", "name": "Kara Delik", "desc": "Düşmanları içine çeker.", "icon": "🕳️"},
	{"id": "dagger_storm", "name": "Hançer Fırtınası", "desc": "8 yönde eş zamanlı hançer.", "icon": "🗡️"},
	{"id": "poison_arrow", "name": "Zehirli Ok", "desc": "Zehirli ok atar.", "icon": "🏹"},
]

@onready var grid_container: GridContainer = $VBoxContainer/HBoxContainer/GridContainer
@onready var prev_button: Button = $VBoxContainer/HBoxContainer/PrevButton
@onready var next_button: Button = $VBoxContainer/HBoxContainer/NextButton
@onready var back_button: Button = $BackButton
@onready var page_dots: HBoxContainer = $VBoxContainer/PageDots


func _ready() -> void:
	_current_page = 0
	_focused_idx = 0
	_filter_catalog()
	_render_page()
	prev_button.pressed.connect(func(): _change_page(-1))
	next_button.pressed.connect(func(): _change_page(1))
	back_button.pressed.connect(_on_back_pressed)


func _filter_catalog() -> void:
	var filtered: Array[Dictionary] = []
	for w in weapon_catalog:
		if GameManager.unlocked_weapons.has(w.id):
			filtered.append(w)
	weapon_catalog = filtered


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP, KEY_S, KEY_DOWN:
				if event.keycode in [KEY_W, KEY_UP]:
					_navigate(-1)
				else:
					_navigate(1)
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_A, KEY_LEFT:
				_change_page(-1)
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_D, KEY_RIGHT:
				_change_page(1)
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_Q:
				_change_page(-1)
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_E:
				_change_page(1)
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_select_focused()
				if get_viewport(): get_viewport().set_input_as_handled()
				return
			KEY_ESCAPE:
				_on_back_pressed()
				if get_viewport(): get_viewport().set_input_as_handled()
				return


func _navigate(dir: int) -> void:
	var start := _current_page * WEAPONS_PER_PAGE
	var end := mini(start + WEAPONS_PER_PAGE, weapon_catalog.size())
	var count := end - start
	if count <= 0:
		return

	_focused_idx = clampi(_focused_idx + dir, 0, count - 1)
	_focus_button(_focused_idx)


func _focus_button(idx: int) -> void:
	if idx >= 0 and idx < grid_container.get_child_count():
		var btn := grid_container.get_child(idx) as Control
		btn.grab_focus()


func _select_focused() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused and focused is Button:
		focused.emit_signal("pressed")


func _render_page() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	for child in page_dots.get_children():
		child.queue_free()

	var total_pages := ceili(float(weapon_catalog.size()) / WEAPONS_PER_PAGE)
	var start := _current_page * WEAPONS_PER_PAGE
	var end := mini(start + WEAPONS_PER_PAGE, weapon_catalog.size())

	for i in range(start, end):
		var weapon: Dictionary = weapon_catalog[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(280, 70)
		btn.focus_mode = Control.FOCUS_ALL
		btn.text = "%s  %s\n%s" % [weapon.icon, weapon.name, weapon.desc]
		var weapon_id: String = weapon.id
		btn.pressed.connect(func(): _select_weapon(weapon_id))
		grid_container.add_child(btn)

	for i in total_pages:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = Color(0.98, 0.75, 0.14, 1) if i == _current_page else Color(0.2, 0.26, 0.33, 1)
		page_dots.add_child(dot)

	prev_button.disabled = _current_page == 0
	next_button.disabled = _current_page == total_pages - 1

	_focused_idx = clampi(_focused_idx, 0, grid_container.get_child_count() - 1)
	if grid_container.get_child_count() > 0:
		_focus_button(_focused_idx)


func _change_page(dir: int) -> void:
	var total_pages := ceili(float(weapon_catalog.size()) / WEAPONS_PER_PAGE)
	_current_page = clampi(_current_page + dir, 0, total_pages - 1)
	_focused_idx = 0
	_render_page()


func _select_weapon(weapon_id: String) -> void:
	GameManager.start_game(GameManager.selected_shape, weapon_id)
	get_tree().change_scene_to_file("res://scenes/world/game_world.tscn")


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
