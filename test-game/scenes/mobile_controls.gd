extends CanvasLayer

# --- Mobile Controls ---
# 가상 조이스틱 + 발사 버튼을 포함한 모바일 컨트롤 UI

@onready var joystick: Control = $MarginContainer/Joystick
@onready var fire_button: Button = $FireButtonContainer/FireButton

var joystick_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 조이스틱 시그널 연결
	joystick.joystick_input.connect(_on_joystick_input)

	# 발사 버튼 이벤트
	fire_button.button_down.connect(_on_fire_pressed)
	fire_button.button_up.connect(_on_fire_released)

func _on_joystick_input(direction: Vector2) -> void:
	joystick_direction = direction

func _on_fire_pressed() -> void:
	# fire 액션 시뮬레이션
	Input.action_press("fire")

func _on_fire_released() -> void:
	Input.action_release("fire")

# 외부에서 조이스틱 방향 가져오기
func get_joystick_direction() -> Vector2:
	return joystick_direction
