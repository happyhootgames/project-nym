class_name PlayerCamera
extends Camera2D

# =========================================================
# ZOOM SETTINGS
# Smaller value = closer zoom
# Bigger value = farther zoom
# =========================================================

@export var default_zoom: Vector2 = Vector2(1.0, 1.0)
@export var house_zoom: Vector2 = Vector2(0.85, 0.85)
@export var dialogue_zoom: Vector2 = Vector2(0.7, 0.7)

@export var zoom_duration: float = 1

var _zoom_tween: Tween


func _ready() -> void:
	zoom = default_zoom
	GameEventBus.camera_zoom.connect(_on_zoom_request)


func set_default_zoom() -> void:
	_tween_to_zoom(default_zoom)


func set_house_zoom() -> void:
	_tween_to_zoom(house_zoom)


func set_dialogue_zoom() -> void:
	_tween_to_zoom(dialogue_zoom)


func _tween_to_zoom(target_zoom: Vector2) -> void:
	if _zoom_tween != null:
		_zoom_tween.kill()

	_zoom_tween = create_tween()
	_zoom_tween.set_trans(Tween.TRANS_SINE)
	_zoom_tween.set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(self, "zoom", target_zoom, zoom_duration)

func _on_zoom_request(is_zooming: bool) -> void:
	if is_zooming:
		set_house_zoom()
	else:
		set_default_zoom()
