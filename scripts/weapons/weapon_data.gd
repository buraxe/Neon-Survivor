class_name WeaponData
extends Resource

@export var id: String = "wand"
@export var name: String = "Plazma Asa"
@export var desc: String = ""
@export var icon: String = "🪄"
@export var type: String = "weapon"
@export var base_damage: float = 25.0
@export var base_cooldown: float = 0.75
@export var base_range: float = 600.0
@export var level: int = 0
@export var max_level: int = 8

var timer: float = 0.0


func get_damage(player: Player) -> float:
	var is_crit: bool = randf() < player.crit_chance
	var base: float = base_damage + (level - 1) * _damage_per_level()
	var mult: float = player.damage_mult * (player.crit_mult if is_crit else 1.0)
	return base * mult


func get_cooldown(player: Player) -> float:
	return base_cooldown / player.attack_speed_mult


func get_range() -> float:
	return base_range + (level - 1) * 15.0


func _damage_per_level() -> float:
	return base_damage * 0.15


static func get_all_weapons() -> Array[WeaponData]:
	var list: Array[WeaponData] = []
	var configs := [
		{"id": "wand", "name": "Plazma Asa", "icon": "🪄", "desc": "Güdümlü enerji topları.", "dmg": 20.0, "cd": 0.75, "rng": 600.0},
		{"id": "shotgun", "name": "Pompalı", "icon": "🔫", "desc": "Yakın mesafe katliam.", "dmg": 15.0, "cd": 1.5, "rng": 300.0},
		{"id": "blade", "name": "Nano Bıçak", "icon": "⚔️", "desc": "Etrafında ölümcül dönüş.", "dmg": 25.0, "cd": 0.0, "rng": 100.0},
		{"id": "lightning", "name": "Tesla Bobini", "icon": "⚡", "desc": "Düşmanlar arası seken elektrik.", "dmg": 15.0, "cd": 1.8, "rng": 450.0},
		{"id": "mine", "name": "Mayın", "icon": "💣", "desc": "Yere güçlü patlayıcı bırakır.", "dmg": 50.0, "cd": 2.5, "rng": 200.0},
		{"id": "aura", "name": "Radyasyon", "icon": "☢️", "desc": "Yakındakileri sürekli eritir.", "dmg": 10.0, "cd": 0.1, "rng": 130.0},
		{"id": "laser", "name": "Yörünge Lazer", "icon": "☄️", "desc": "Rastgele alanlara dikey saldırı.", "dmg": 50.0, "cd": 3.0, "rng": 600.0},
		{"id": "frost", "name": "Buz Novası", "icon": "❄️", "desc": "Düşmanları dondurur.", "dmg": 15.0, "cd": 4.0, "rng": 250.0},
		{"id": "rocket", "name": "Roketatar", "icon": "🚀", "desc": "Devasa patlayan roketler.", "dmg": 50.0, "cd": 2.0, "rng": 500.0},
		{"id": "boomerang", "name": "Bumerang", "icon": "🪃", "desc": "Geri dönen ölümcül disk.", "dmg": 15.0, "cd": 1.5, "rng": 400.0},
		{"id": "flamethrower", "name": "Alev Thrower", "icon": "🔥", "desc": "Sürekli ateş püskürtür.", "dmg": 8.0, "cd": 0.05, "rng": 180.0},
		{"id": "machinegun", "name": "Makineli", "icon": "🔫", "desc": "Çok hızlı mermi yağmuru.", "dmg": 5.0, "cd": 0.2, "rng": 500.0},
		{"id": "sniper", "name": "Keskin Nişancı", "icon": "🎯", "desc": "Delip geçen ultra mermi.", "dmg": 55.0, "cd": 3, "rng": 1200.0},
		{"id": "nova_pulse", "name": "Nova Darbesi", "icon": "🌀", "desc": "Çevrede yayılan enerji halkası.", "dmg": 20.0, "cd": 5.0, "rng": 220.0},
		{"id": "blackhole", "name": "Kara Delik", "icon": "🕳️", "desc": "Düşmanları çeken yer çekimi.", "dmg": 20.0, "cd": 8.0, "rng": 350.0},
		{"id": "dagger_storm", "name": "Hançer Fırtınası", "icon": "🗡️", "desc": "8 yönde hançer atar.", "dmg": 15.0, "cd": 1.0, "rng": 480.0},
		{"id": "poison_arrow", "name": "Zehirli Ok", "icon": "🏹", "desc": "Zehirli ok atar.", "dmg": 15.0, "cd": 2.0, "rng": 600.0},
	]
	for c in configs:
		var w := WeaponData.new()
		w.id = c.id
		w.name = c.name
		w.icon = c.icon
		w.desc = c.desc
		w.base_damage = c.dmg
		w.base_cooldown = c.cd
		w.base_range = c.rng
		list.append(w)
	return list
