# NEON SURVIVOR

> Karanlık bir neon cyberpunk evreninde hayatta kal. Düşman dalgalarını kes, silahlarını geliştir, boss'ları yen ve evrimin üstesinden gel.

Neon Survivor, **Vampire Survivors** tarzında bir **roguelite survivor** oyunudur. **Godot 4.6** motoru ile geliştirilmiştir. Tüm görseller kod ile çizilir (sprite kullanılmaz), bu sayede minimal dosya boyutu ve tutarlı bir neon estetik sağlanır.

---

## Nasıl Oynanır

### Kontroller

| Eylem | Klavye | Gamepad |
|-------|--------|---------|
| Hareket | WASD / Ok Tuşları | Sol Çubuk |
| Ultimate Yetenek | SPACE | Y Tuşu |
| Duraklat | ESC | Start |
| Menü Navigasyonu | W/S veya Ok Tuşları + Enter | Çubuk + A |

### Oyun Döngüsü

1. **Karakter Seç** -- Daire, Üçgen veya Kare
2. **Başlangıç Silahını Seç** -- Açılan silahlardan birini belirle
3. **Hayatta Kal** -- Sonsuz düşman dalgalarından kaç ve savaş
4. **Seviye Atla** -- Düşmanlardan düşen kristalleri topla, XP kazan, her level up'ta 3 yükseltme arasından seçim yap
5. **Boss'u Yen** -- Her 2 dakikada bir boss spawn olur. Boss'u yen, portal açılsın ve bir sonraki bölüme geç
6. **Final Boss** -- 4. seviyede (Grand Final) Neon Overlord ile savaş

---

## Karakterler

Her karakterin kendine özgü istatistikleri ve ultimate yeteneği vardır.

| Karakter | HP | Hız | Kritik | Özel Yetenek |
|----------|-----|------|--------|--------------|
| **Daire** | 150 | Orta | %10 | **Frenzy Mode** -- 5 saniye boyunca saldırı hızı %100 artar |
| **Üçgen** | 125 | Yüksek | %25 | **Zehir Bulutu** -- İleri atılma + kalıcı zehir bulutu bırakır |
| **Kare** | 200 + 25 Kalkan | Orta | %10 | **Kalkan Patlaması** -- Kalkanını patlatarak çevreye devasa hasar verir |

Üçgen ve Kare karakterleri **Dükkan**'dan coin ile açılır.

---

## Silah Sistemi

Oyunda **17 benzersiz silah** vardır. Her biri farklı saldırı deseni, menzil ve cooldown'a sahiptir. Tüm silahlar **8 seviyeye** kadar yükseltilebilir.

| Silah | Açıklama | Temel Hasar | Cooldown |
|-------|----------|------------|----------|
| Plazma Asa | Güdümlü enerji topları | 20 | 0.75s |
| Pompalı | Yakın mesafe çoklu saçma | 15 | 1.5s |
| Nano Bıçak | Etrafında dönen bıçaklar | 25 | Sürekli |
| Tesla Bobini | Düşmanlar arası seken elektrik | 15 | 1.8s |
| Mayın | Yere zamanlı patlayıcı bırakır | 50 | 2.5s |
| Radyasyon | Yakındakileri sürekli eritir (aura) | 10 | 0.1s |
| Yörünge Lazer | Rastgele alanlara dikey lazer | 50 | 3.0s |
| Buz Novası | Düşmanları dondurur | 15 | 4.0s |
| Roketatar | Devasa patlayan roketler | 50 | 2.0s |
| Bumerang | Geri dönen ölümcül disk | 15 | 1.5s |
| Alev Thrower | Sürekli ateş püskürtür | 8 | 0.05s |
| Makineli | Çok hızlı mermi yağmuru | 5 | 0.2s |
| Keskin Nişancı | Delip geçen ultra mermi | 55 | 3.0s |
| Nova Darbesi | Çevrede yayılan enerji halkası | 20 | 5.0s |
| Kara Delik | Düşmanları çeken yerçekimi alanı | 20 | 8.0s |
| Hançer Fırtınası | 8 yönde hançer atar | 15 | 1.0s |
| Zehirli Ok | Zehirleyen ok atar | 15 | 2.0s |

### Pasif Yükseltmeler

Level up sırasında silah yerine pasif yetenekler de seçilebilir. Pasifler stacklenebilir:

- **Hız Modülü** -- %15 hareket hızı
- **Hız Aşırtma** -- %15 saldırı hızı
- **Optik Vizör** -- %10 kritik şansı
- **Güç Çekirdeği** -- %15 hasar
- **Çoklu Kanal** -- +1 ek mermi/etki
- **Yenileme** -- +25 max HP
- **Mıknatıs** -- %25 toplama mesafesi
- **Refleks** -- %5 dodge şansı
- **Enerji Kalkanı** -- +15 kalkan (8/s yenilenir)
- **Vampirizm** -- Hasarın %0.02'si HP olarak alınır
- **Hayali Darbe** -- Kritik hasar +0.4x
- **Biyorejenerasyon** -- +1 HP / 10sn
- **Veri Madenciliği** -- %25 XP bonusu
- **Genişleme** -- Alan etkileri %20 büyür

---

## Düşman Türleri

| Tür | Davranış |
|-----|----------|
| **Normal** | Dengeli HP ve hız, doğrudan oyuncuya koşar |
| **Hızlı** | Düşük HP ama çok hızlı, erken dalgalarda belirir |
| **Ağır** | Yüksek HP, yavaş ama büyük hasar |
| **Uzaktan** | Mesafeden mermi atar, güvenli mesafe korur |
| **Elit** | Altın taçlı güçlü düşmanlar, yüksek ödül verir |
| **Özel** | Boss sonrası basınç dalgalarında spawn olur |
| **Boss** | 9 farklı saldırı deseni, minyon çağırır, dash yapar |
| **Final Boss (Neon Overlord)** | 14 farklı saldırı deseni, 2. faz (HP <%50), 60.000 HP |

### Boss Saldırı Desenleri

Normal Boss 9 farklı saldırı deseni kullanır: yönlü mermi, halka atışı, yaylım, dash, minyon çağırma, güdümlü mermi, çift halka, bombacı minyon, spiral.

Final Boss (Neon Overlord) ise 14 farklı desen + faz geçişi ile %50 HP altında rage mode'a girer.

---

## Evrim Sistemi

Her level geçişinde düşmanlar rastgele bir **evrim özelliği** kazanır:

- **Patlayıcı** -- Öldüğünde çevreye hasar verir
- **Hızlanma** -- Daha hızlı hareket eder
- **Kalkan** -- Bir vuruşu engeller
- **Bölünme** -- Öldüğünde ikiye ayrılır
- **Hamle** -- Öne doğru dash yapar

Bu özellik rastgele bir düşman türüne uygulanır ve seviye geçiş ekranında bildirilir.

---

## Dünya Mekanikleri

### Prosedürel Chunk Sistemi
Dünya chunk tabanlı prosedürel olarak üretilir. Her chunk (1000x1000) rastgele duvar kalıpları içerir: L, T, U, H, +, koridor, büyük blok ve daha fazlası. Uzak chunk'lardaki duvarlar otomatik temizlenir.

### Level 4 -- Grand Final Arena
4. seviyede sınırsız bir arena (1800x1800) oluşturulur. Duvarlarla çevrilidir, chunk sistemi devre dışıdır. Arena içinde Neon Overlord ile son savaş gerçekleşir.

### Tapınaklar (Shrine)
Her 45 saniyede oyuncunun etrafında rastgele tapınaklar spawn olur. 4 saniye bekleyerek kalıcı buff alınır: +5 Max HP, +5 Hız, +%5 Hasar, +%5 Saldırı Hızı, +%5 Kritik, +1 Mermi, +5 Kalkan.

### Kafatası (Skull)
Haritada nadiren beliren kafatası objeleri. Toplandığında **zorluk %20 artar** ama skor çarpanı da artar (risk/ödül mekaniği). Maksimum 5 kafatası toplanabilir.

### Sandıklar (Chest)
Boss'lar ve elit düşmanlardan düşer. 3 nadirlik seviyesi: Gri (normal), Mavi (nadir), Altın (epik). Yaklaştığınızda otomatik açılır.

### Yer Güçlendirmeleri (Ground Powerup)
- **Can (Kırmızı Haç)** -- %25 HP yenileme
- **Bomba (Sarı Daire)** -- 350 birimlik alan hasarı
- **Mıknatıs (Mor Elmas)** -- Tüm kristalleri oyuncuya çek

---

## Meta İlerleme (Dükkan)

Her run sonunda coin toplanır. Dükkandan kalıcı yükseltmeler satın alınır:

- **Yeni Karakterler** -- Kare (100 coin), Üçgen (150 coin)
- **Yeni Silahlar** -- 13 farklı silah (60-120 coin)
- **Yeni Pasifler** -- 10 farklı pasif (50-100 coin)
- **Silah/Pasif Slotları** -- En fazla 5'er adet (artan maliyet)
- **Ultimate Yetenekler** -- Her karakter için özel (300 coin)
- **Meta İstatistikler** -- Tüm karakterlere kalıcı bonus: +%5 saldırı hızı, +%5 hasar, +10 HP, +%5 hız, +%3 kritik (5 seviyeye kadar)

---

## Tasarım Tercihleri ve Teknik Yaklaşımlar

### Sprite-Free Kodsal Çizim
Oyunda hiçbir sprite asset'i kullanılmaz. Tüm görseller `_draw()` fonksiyonları ile GDScript üzerinden gerçek zamanlı çizilir:
- Oyuncu geometrik şekiller (daire, üçgen, kare) + neon kenar çizgileri
- Düşmanlar şekil+renk ile ayırt edilir, elitler taç simgesi taşır
- Silah etkileri (blade orbit, aura circle, black hole spiral) dinamik çizilir
- Kristaller, güçlendirmeler, tapınaklar, sandıklar -- hepsi procedural çizim

Bu yaklaşımın avantajları:
- Çok küçük dosya boyutu (asset bağımlılığı yok)
- Tutarlı neon estetik
- Kolay renk/boyut değişikliği
- Her nesne için özelleştirilmiş animasyon

### CRT Shader Etkisi
Gerçek zamanlı CRT post-processing shader uygulanır: eğrilik (curvature), chromatic aberration, scanline, vignette, flicker ve noise. Ayarlardan her parametre özelleştirilebilir veya tamamen kapatılabilir.

### Prosedürel Ses Üretimi
Tüm SFX'ler dosya yerine kod ile üretilir. `AudioManager._generate_sfx()` fonksiyonu `AudioStreamWAV` formatında ses dalgaları oluşturur:
- **Gem Pickup** -- Frekans sweep (800Hz → 4800Hz)
- **Enemy Death** -- Beyaz gürültü + decay
- **Level Up** -- Yükselen ton
- **Explosion** -- Düşük frekans bozulma
- Müzik ise `.ogg` dosyaları ile sağlanır (main_theme, fight_1, fight_2, boss_theme)

### Lofi Filter
Level up menüsü açıkken müziğe lofi low-pass + high-pass filtre uygulanır. Bu sayede menüde daha sakin bir atmosfer oluşur, kapatıldığında smooth geçişle normal müziğe dönülür.

### Düşman AI Sistemi
- **Chase AI** -- Raycast tabanlı yol bulma, duvarlardan kaçınma, takılma (stuck) tespiti ve kaçış mekaniği
- **Ranged AI** -- Güvenli mesafe koruma, yaklaştığında geri çekilme, periyodik mermi atışı
- **Boss AI** -- Pattern tabanlı saldırı dizisi, dash, minyon çağırma, güdümlü mermi, faz geçişi

### Düşman Ölçekleme
Düşman istatistikleri şu faktörlere göre dinamik olarak hesaplanır:
- Geçen süreye göre seviye (`game_time / 20`)
- Dakika bazlı zorluk çarpanı
- Mevcut level (Lv1: 1x, Lv2: 1.5x, Lv3: 2x, Lv4: 2.5x)
- İlk boss sonrası çarpan
- Elit çarpanı
- Kafatası zorluk çarpanı

### Performans
- Maksimum 200 aktif düşman limiti
- 2000 birim ötesindeki düşmanlar otomatik temizlenir
- Rasgele örnekleme ile düşmanlararası çarpışma çözümü (80 çift/kare)
- Grafik kalitesi ayarı ile parçacık çarpanı: Low (0x), Medium (1x), High (3.2x)
- VFX efektleri ömür tabanlı otomatik temizlenir

### Ekran Efektleri
- **Camera Shake** -- Hasar alındığında, ultimate aktifleştiğinde
- **Low HP Vignette** -- HP <%50 olduğunda kırmızı kenar karartma (shader tabanlı)
- **Death Zoom** -- Ölümden sonra yavaş zoom-in efekti
- **Floating Text** -- Hasar sayıları, iyileştirme, güçlendirme bildirimleri

---

## Seviye Yapısı

| Seviye | Açıklama |
|--------|----------|
| **1** | Başlangıç alanı, düşman dalgaları kademeli artar |
| **2** | Zorluk çarpanı 1.5x, evrim mekanikleri aktif |
| **3** | Zorluk çarpanı 2x, daha agresif spawn |
| **4 (Grand Final)** | Kapalı arena, Neon Overlord savaşı, sonsuz basınç dalgası |

Boss yenildikten sonra portal spawn olur. Portala girerek bir sonraki seviyeye geçilir.

---

## Proje Yapısı

```
godot_project/
├── project.godot              # Godot proje yapılandırması
├── Neon Survivor.exe          # Windows çalıştırılabilir
├── Neon Survivor.pck          # Paketlenmiş kaynaklar
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd    # Global oyun durumu ve meta ilerleme
│   │   └── audio_manager.gd   # Ses yönetimi ve prosedürel SFX
│   ├── player/
│   │   ├── player.gd          # Oyuncu kontrolleri, hasar, XP, ultimate
│   │   ├── player_stats.gd    # Karakter istatistik tanımları
│   │   └── shape_drawer.gd    # Procedural oyuncu çizimi
│   ├── enemies/
│   │   └── enemy.gd           # Tüm düşman tipleri ve AI
│   ├── weapons/
│   │   ├── weapon_data.gd     # Silah tanımları ve hasar hesaplama
│   │   ├── weapon_manager.gd  # Silah ateşleme ve yönetim sistemi
│   │   └── projectile.gd      # Mermi fiziği ve çarpışma
│   ├── world/
│   │   ├── game_world.gd      # Ana oyun sahnesi, seviye yönetimi
│   │   ├── enemy_spawner.gd   # Spawn dalgaları ve boss tetikleme
│   │   ├── chunk_generator.gd # Prosedürel harita üretimi
│   │   ├── special_manager.gd # Tapınak, kafatası, sandık yönetimi
│   │   ├── portal.gd          # Seviye geçiş portalı
│   │   ├── gem.gd             # XP kristali
│   │   ├── chest.gd           # Sandık objesi
│   │   ├── shrine.gd          # Tapınak buff sistemi
│   │   ├── skull.gd           # Zorluk artırıcı kafatası
│   │   ├── ground_powerup.gd  # Yer güçlendirmeleri (Can/Bomba/Mıknatıs)
│   │   ├── wall.gd            # Duvar objesi
│   │   ├── background_grid.gd # Arka plan grid çizimi
│   │   └── camera.gd          # Kamera shake ve takip
│   ├── effects/
│   │   ├── vfx_manager.gd     # Parçacık, yıldırım, lazer, nova efektleri
│   │   ├── crt_overlay.gd     # CRT shader kontrolü
│   │   ├── particle.gd        # Parçacık fiziği
│   │   ├── floating_text.gd   # Hasar/bildirim metinleri
│   │   └── poison_cloud.gd    # Üçgen ultimate zehir bulutu
│   └── ui/
│       ├── main_menu.gd       # Ana menü
│       ├── character_select.gd# Karakter seçimi
│       ├── weapon_select.gd   # Silah seçimi
│       ├── hud.gd             # Oyun içi arayüz (HP, XP, Boss bar)
│       ├── level_up.gd        # Seviye atlama menüsü
│       ├── shop.gd            # Meta ilerleme dükkanı
│       ├── chest_open.gd      # Sandık açılımı
│       ├── game_over.gd       # Oyun sonu ekranı
│       ├── pause_menu.gd      # Duraklatma menüsü
│       ├── settings.gd        # Ayarlar (CRT, ses, grafik)
│       └── joystick.gd        # Mobil dokunmatik kontrol
├── scenes/                    # .tscn sahne dosyaları
├── assets/
│   ├── shaders/               # CRT, bloom, low_hp shader'ları
│   └── audio/music/           # Müzik dosyaları (OGG)
├── shaders/                   # Ek shader'lar
└── addons/
    └── controller_icons/      # Gamepad ikon desteği
```

---

## Teknik Detaylar

- **Motor:** Godot 4.6 (Forward Plus)
- **Çözünürlük:** 1280x720, canvas_items stretch, expand aspect
- **Fizik Katmanları:** Player, Enemies, Player Projectiles, Enemy Projectiles, Pickups, Walls, Area Effects
- **Girdi:** Klavye + Gamepad desteği (controller_icons addon ile)
- **Render:** Pixel snap aktif, nearest texture filter
- **Kayıt:** `user://settings.cfg` (ayarlar) ve `user://progress.cfg` (meta ilerleme)

---

## Lisans

Bu proje eğitim ve portfolyo amaçlıdır. Kaynak kodu referans olarak kullanılabilir.
