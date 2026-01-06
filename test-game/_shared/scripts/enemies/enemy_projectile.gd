class_name EnemyProjectile
extends Area2D

## 적이 발사하는 발사체
##
## 플레이어에게만 데미지를 주고, 적/벽은 무시합니다.
## EnemyAttackController에서 생성합니다.

signal hit(body: Node)

@export var speed: float = 200.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT

## 스프라이트 참조 (자식에서 설정)
var sprite: Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite = get_node_or_null("Sprite2D") as Sprite2D
	
	# 방향에 따라 스프라이트 회전
	if sprite:
		rotation = direction.angle()
	
	# 수명 타이머
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	# 플레이어만 공격
	if not body.is_in_group("player"):
		return
	
	if body.has_method("take_damage"):
		var knockback_dir = direction.normalized()
		body.take_damage(damage, knockback_dir)
	
	hit.emit(body)
	_on_hit(body)
	queue_free()

## 충돌 시 추가 처리 (자식에서 오버라이드)
func _on_hit(_body: Node) -> void:
	pass

## 발사체 초기화
func setup(dir: Vector2, spd: float, dmg: float) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
	
	# 방향에 따라 회전
	rotation = direction.angle()
