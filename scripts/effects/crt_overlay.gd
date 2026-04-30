extends ColorRect

@export var crt_shader: Shader = preload("res://assets/shaders/crt.gdshader")
@export var bloom_shader: Shader = preload("res://assets/shaders/bloom.gdshader")

var _time: float = 0.0
var _enabled: bool = true


func _ready() -> void:
	material = ShaderMaterial.new()
	(material as ShaderMaterial).shader = crt_shader
	apply_settings()


func _process(delta: float) -> void:
	_time += delta
	if _enabled and material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("time", _time)


func apply_settings() -> void:
	if not material is ShaderMaterial:
		return
	var mat := material as ShaderMaterial
	mat.set_shader_parameter("curvature", GameManager.settings.crt_curvature / 100.0 if GameManager.settings.crt_enabled else 0.0)
	mat.set_shader_parameter("chroma", GameManager.settings.crt_chroma / 100.0 if GameManager.settings.crt_enabled else 0.0)
	mat.set_shader_parameter("scanlines", GameManager.settings.crt_scanlines / 100.0 if GameManager.settings.crt_enabled else 0.0)
	mat.set_shader_parameter("vignette", GameManager.settings.crt_vignette / 100.0 if GameManager.settings.crt_enabled else 0.0)
	mat.set_shader_parameter("flicker_amount", GameManager.settings.crt_flicker / 100.0 if GameManager.settings.crt_enabled else 0.0)
	visible = GameManager.settings.crt_enabled

	var parent_layer := get_parent()
	if parent_layer is CanvasLayer:
		if GameManager.settings.get("crt_affects_ui", false):
			parent_layer.layer = 20
		else:
			parent_layer.layer = 5


func toggle(enabled: bool) -> void:
	_enabled = enabled
	visible = enabled
