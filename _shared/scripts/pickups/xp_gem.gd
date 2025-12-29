class_name XpGem
extends Area2D

## 경험치 젬
## 플레이어가 가까이 오면 자석처럼 끌려가고, 접촉 시 경험치 획득

@export var xp_value: int = 1
@export var magnet_speed: float = 300.0
@export var magnet_range: float = 50.0

var target: Node2D = null
var is_magnetized: bool = false

func _ready() -> void:
	add_to_group("xp_gems")

	# 플레이어 찾기
	await get_tree().process_frame
	target = get_tree().get_first_node_in_group("player")

	# 충돌 시그널
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not target:
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
		# 플레이어에게 경험치 전달
		if body.has_method("add_xp"):
			body.add_xp(xp_value)

		queue_free()
