class_name XpGem
extends Area2D

## 경험치 젬
## 플레이어가 가까이 오면 자석처럼 끌려가고, 접촉 시 경험치 획득
## EventBus를 통해 pickup_collected 이벤트 발행

@export var xp_value: int = 1
@export var magnet_speed: float = 300.0
@export var magnet_range: float = 50.0

var target: Node2D = null
var is_magnetized: bool = false
var event_bus: Node = null

func _ready() -> void:
	add_to_group("xp_gems")
	add_to_group("pickups")

	# EventBus 참조
	event_bus = get_node_or_null("/root/EventBus")

	# 플레이어 찾기 (자석 효과용)
	await get_tree().process_frame
	_find_player()

	# 플레이어 스폰 이벤트 구독 (동적 플레이어 대응)
	if event_bus:
		event_bus.player_spawned.connect(_on_player_spawned)

	# 충돌 시그널
	body_entered.connect(_on_body_entered)

## 플레이어 찾기 (그룹 기반)
func _find_player() -> void:
	target = get_tree().get_first_node_in_group("player")

## 플레이어 스폰 시 타겟 업데이트
func _on_player_spawned(player: Node2D) -> void:
	target = player

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return

	var distance = global_position.distance_to(target.global_position)

	# 자석 범위 내면 끌려감
	if distance < magnet_range or is_magnetized:
		is_magnetized = true
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * magnet_speed * delta

		# 속도 증가 (가까워질수록 빨라짐)
		magnet_speed += 500.0 * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# EventBus로 픽업 이벤트 발행
		if event_bus:
			event_bus.pickup_collected.emit(self, body)
			event_bus.xp_gained.emit(xp_value, 0)  # total은 수신자가 계산

		# 플레이어에게 직접 XP 전달 (EventBus 없을 때 폴백)
		if body.has_method("add_xp"):
			body.add_xp(xp_value)

		queue_free()
