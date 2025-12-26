extends Control

# --- Virtual Joystick ---
# 모바일용 가상 조이스틱 구현
# 좌측 하단에 배치되어 터치/드래그로 이동 방향을 입력합니다.

signal joystick_input(direction: Vector2)

@export var max_distance: float = 64.0  # 조이스틱 최대 이동 거리
@export var deadzone: float = 0.2       # 데드존 (0~1)

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var is_pressed: bool = false
var touch_index: int = -1

func _ready() -> void:
	# 조이스틱 초기 위치 설정
	knob.pivot_offset = knob.size / 2

func _input(event: InputEvent) -> void:
	# 터치 시작
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_base(event.position):
				is_pressed = true
				touch_index = event.index
				_update_knob(event.position)
		else:
			if event.index == touch_index:
				_reset_knob()

	# 터치 드래그
	if event is InputEventScreenDrag:
		if event.index == touch_index and is_pressed:
			_update_knob(event.position)

	# 마우스 지원 (PC 테스트용)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _is_point_inside_base(event.position):
					is_pressed = true
					_update_knob(event.position)
			else:
				_reset_knob()

	if event is InputEventMouseMotion:
		if is_pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_update_knob(event.position)

func _is_point_inside_base(point: Vector2) -> bool:
	var base_rect = base.get_global_rect()
	return base_rect.has_point(point)

func _update_knob(touch_pos: Vector2) -> void:
	var base_center = base.global_position + base.size / 2
	var direction = touch_pos - base_center

	# 최대 거리 제한
	if direction.length() > max_distance:
		direction = direction.normalized() * max_distance

	# 노브 위치 업데이트
	knob.position = base.size / 2 + direction - knob.size / 2

	# 정규화된 방향 계산 (-1 ~ 1)
	var output = direction / max_distance

	# 데드존 적용
	if output.length() < deadzone:
		output = Vector2.ZERO

	joystick_input.emit(output)

func _reset_knob() -> void:
	is_pressed = false
	touch_index = -1
	# 노브를 중앙으로
	knob.position = base.size / 2 - knob.size / 2
	joystick_input.emit(Vector2.ZERO)

# 외부에서 현재 방향을 가져올 수 있는 함수
func get_direction() -> Vector2:
	if not is_pressed:
		return Vector2.ZERO

	var base_center = base.size / 2
	var knob_center = knob.position + knob.size / 2
	var direction = (knob_center - base_center) / max_distance

	if direction.length() < deadzone:
		return Vector2.ZERO

	return direction
