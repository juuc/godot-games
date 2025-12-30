class_name TreasureChest
extends Area2D

## 보물상자 픽업
## 플레이어 접촉 시 무기/패시브 선택 UI 표시
## 자석 효과 없음 - 플레이어가 직접 접근해야 함

@export var float_amplitude: float = 3.0  ## 부유 효과 진폭
@export var float_speed: float = 2.0  ## 부유 속도

var event_bus: Node = null
var initial_position: Vector2 = Vector2.ZERO
var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("treasure_chests")
	add_to_group("pickups")

	# EventBus 참조
	event_bus = get_node_or_null("/root/EventBus")

	# 초기 위치 저장 (부유 효과용)
	initial_position = global_position

	# 충돌 시그널
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# 부유 효과 (시각적 차별화)
	time_passed += delta
	global_position.y = initial_position.y + sin(time_passed * float_speed) * float_amplitude

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# EventBus로 보물상자 획득 이벤트 발행
		if event_bus:
			event_bus.treasure_collected.emit(self, body)

		# Player에게 직접 호출 (EventBus 없을 때 폴백)
		if body.has_method("on_treasure_collected"):
			body.on_treasure_collected()

		queue_free()
