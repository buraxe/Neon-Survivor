extends Control

@onready var back_button: Button = $TopBar/BackButton
@onready var crt_check: CheckBox = $ScrollContainer/VBoxContainer/CRTBox/CRTCheck
@onready var crt_plus_check: CheckBox = $ScrollContainer/VBoxContainer/CRTPlusBox/CRTPlusCheck
@onready var shake_slider: HSlider = $ScrollContainer/VBoxContainer/ShakeBox/ShakeSlider
@onready var shake_label: Label = $ScrollContainer/VBoxContainer/ShakeBox/ShakeHeader/ShakeLabel
@onready var quality_low: Button = $ScrollContainer/VBoxContainer/QualityBox/QualityButtons/QualityLow
@onready var quality_medium: Button = $ScrollContainer/VBoxContainer/QualityBox/QualityButtons/QualityMedium
@onready var quality_high: Button = $ScrollContainer/VBoxContainer/QualityBox/QualityButtons/QualityHigh
@onready var curvature_slider: HSlider = $ScrollContainer/VBoxContainer/CurvatureBox/CurvatureSlider
@onready var curvature_label: Label = $ScrollContainer/VBoxContainer/CurvatureBox/CurvatureHeader/CurvatureVal
@onready var chroma_slider: HSlider = $ScrollContainer/VBoxContainer/ChromaBox/ChromaSlider
@onready var chroma_label: Label = $ScrollContainer/VBoxContainer/ChromaBox/ChromaHeader/ChromaVal
@onready var vignette_slider: HSlider = $ScrollContainer/VBoxContainer/VignetteBox/VignetteSlider
@onready var vignette_label: Label = $ScrollContainer/VBoxContainer/VignetteBox/VignetteHeader/VignetteVal
@onready var music_slider: HSlider = $ScrollContainer/VBoxContainer/MusicBox/MusicSlider
@onready var music_label: Label = $ScrollContainer/VBoxContainer/MusicBox/MusicHeader/MusicVal
@onready var sfx_slider: HSlider = $ScrollContainer/VBoxContainer/SFXBox/SFXSlider
@onready var sfx_label: Label = $ScrollContainer/VBoxContainer/SFXBox/SFXHeader/SFXVal


func _ready() -> void:
	crt_check.button_pressed = GameManager.settings.crt_enabled
	_update_crt_plus_visibility()
	crt_plus_check.button_pressed = GameManager.settings.get("crt_affects_ui", false)
	shake_slider.value = GameManager.settings.shake_intensity
	shake_label.text = "%d%%" % GameManager.settings.shake_intensity
	curvature_slider.value = GameManager.settings.crt_curvature
	curvature_label.text = "%d" % GameManager.settings.crt_curvature
	chroma_slider.value = GameManager.settings.crt_chroma
	chroma_label.text = "%d" % GameManager.settings.crt_chroma
	vignette_slider.value = GameManager.settings.crt_vignette
	vignette_label.text = "%d" % GameManager.settings.crt_vignette
	music_slider.value = GameManager.settings.music_volume
	music_label.text = "%d%%" % GameManager.settings.music_volume
	sfx_slider.value = GameManager.settings.sfx_volume
	sfx_label.text = "%d%%" % GameManager.settings.sfx_volume
	_update_quality_buttons()

	crt_check.toggled.connect(_on_crt_toggled)
	crt_plus_check.toggled.connect(_on_crt_plus_toggled)
	shake_slider.value_changed.connect(_on_shake_changed)
	curvature_slider.value_changed.connect(_on_curvature_changed)
	chroma_slider.value_changed.connect(_on_chroma_changed)
	vignette_slider.value_changed.connect(_on_vignette_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	quality_low.pressed.connect(func(): _set_quality("low"))
	quality_medium.pressed.connect(func(): _set_quality("medium"))
	quality_high.pressed.connect(func(): _set_quality("high"))
	back_button.pressed.connect(_on_back_pressed)

	back_button.grab_focus()


func _update_crt_plus_visibility() -> void:
	crt_plus_check.visible = GameManager.settings.crt_enabled


func _on_crt_toggled(enabled: bool) -> void:
	GameManager.settings.crt_enabled = enabled
	_update_crt_plus_visibility()
	_apply_crt_live()


func _on_crt_plus_toggled(enabled: bool) -> void:
	GameManager.settings.crt_affects_ui = enabled
	_apply_crt_live()


func _on_curvature_changed(value: float) -> void:
	GameManager.settings.crt_curvature = int(value)
	curvature_label.text = "%d" % int(value)
	_apply_crt_live()


func _on_chroma_changed(value: float) -> void:
	GameManager.settings.crt_chroma = int(value)
	chroma_label.text = "%d" % int(value)
	_apply_crt_live()


func _on_vignette_changed(value: float) -> void:
	GameManager.settings.crt_vignette = int(value)
	vignette_label.text = "%d" % int(value)
	_apply_crt_live()


func _on_shake_changed(value: float) -> void:
	GameManager.settings.shake_intensity = int(value)
	GameManager.shake_intensity = value
	shake_label.text = "%d%%" % int(value)


func _set_quality(quality: String) -> void:
	GameManager.settings.graphics_quality = quality
	GameManager.graphics_quality = quality
	_update_quality_buttons()


func _update_quality_buttons() -> void:
	var q: String = GameManager.settings.graphics_quality
	quality_low.disabled = q == "low"
	quality_medium.disabled = q == "medium"
	quality_high.disabled = q == "high"


func _on_music_changed(value: float) -> void:
	GameManager.settings.music_volume = int(value)
	music_label.text = "%d%%" % int(value)
	AudioManager.set_music_volume(int(value))


func _on_sfx_changed(value: float) -> void:
	GameManager.settings.sfx_volume = int(value)
	sfx_label.text = "%d%%" % int(value)
	AudioManager.set_sfx_volume(int(value))


func _apply_crt_live() -> void:
	var gw := get_tree().current_scene
	if gw and gw.has_node("CRTLayer/CRTOverlay"):
		var crt := gw.get_node("CRTLayer/CRTOverlay")
		if crt.has_method("apply_settings"):
			crt.apply_settings()


func _on_back_pressed() -> void:
	GameManager.save_settings()
	if get_parent() is CanvasLayer and get_parent().name == "PauseMenu":
		queue_free()
	else:
		GameManager.change_state(GameManager.GameState.MAIN_MENU)
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
