class_name Projectile
extends Area2D

## 기본 발사체 클래스
## 직선 이동, 충돌 시 데미지 처리

signal hit(body: Node)

@export var speed: float = 2000.0
@export var damage: float = 1.0
@export var knockback_force: float = 100.0
@export var lifetime: float = 0.5

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# 스폰 시 이미 겹쳐있는 적 처리 (1프레임 대기 후 체크)
	await get_tree().physics_frame
	_check_overlapping_bodies()

	# 수명 타이머
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

## 스폰 시 이미 겹쳐있는 바디 체크
func _check_overlapping_bodies() -> void:
	if not is_instance_valid(self):
		return

	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage, direction, knockback_force)
			hit.emit(body)
			_on_hit(body)
			queue_free()
			return

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, direction, knockback_force)

	hit.emit(body)
	_on_hit(body)
	queue_free()

## 충돌 시 추가 처리 (자식에서 오버라이드)
func _on_hit(_body: Node) -> void:
	pass
