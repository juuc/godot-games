extends Camera2D

# --- Zoom Configuration ---
# 모바일 게임에 적합한 줌 범위 설정
@export var min_zoom: float = 1.5  # 최소 줌 (가장 멀리)
@export var max_zoom: float = 5.0  # 최대 줌 (가장 가깝게)
@export var zoom_speed: float = 0.15  # 줌 변화 속도

# Handles camera input.
# _input is called whenever an InputEvent occurs (keyboard, mouse, etc.)
func _input(_event):
	# "zoom_in" and "zoom_out" should be mapped in Project Settings -> Input Map
	# (e.g. Mouse Wheel Up/Down)

	if Input.is_action_just_pressed("zoom_in"):
		var new_zoom = zoom.x + zoom_speed
		new_zoom = clamp(new_zoom, min_zoom, max_zoom)
		zoom = Vector2(new_zoom, new_zoom)

	if Input.is_action_just_pressed("zoom_out"):
		var new_zoom = zoom.x - zoom_speed
		new_zoom = clamp(new_zoom, min_zoom, max_zoom)
		zoom = Vector2(new_zoom, new_zoom)
