extends CanvasLayer

# --- Zoom UI Controller ---
# 화면 좌상단에 줌 버튼을 표시하고 카메라 줌을 조절합니다.

@export var min_zoom: float = 1.5
@export var max_zoom: float = 5.0
@export var zoom_step: float = 0.5

var camera: Camera2D

func _ready() -> void:
	# 1프레임 대기 후 카메라 찾기
	await get_tree().process_frame
	_find_camera()
	_update_label()

func _find_camera() -> void:
	# Player/Camera2D 경로로 직접 찾기
	var world = get_parent()
	var player_node = world.get_node_or_null("Player")
	if player_node:
		camera = player_node.get_node_or_null("Camera2D")

func _on_zoom_in_pressed() -> void:
	if camera:
		var new_zoom = camera.zoom.x + zoom_step
		new_zoom = clamp(new_zoom, min_zoom, max_zoom)
		camera.zoom = Vector2(new_zoom, new_zoom)
		_update_label()

func _on_zoom_out_pressed() -> void:
	if camera:
		var new_zoom = camera.zoom.x - zoom_step
		new_zoom = clamp(new_zoom, min_zoom, max_zoom)
		camera.zoom = Vector2(new_zoom, new_zoom)
		_update_label()

func _update_label() -> void:
	var label = $MarginContainer/VBoxContainer/ZoomLabel
	if label and camera:
		label.text = "x%.1f" % camera.zoom.x
