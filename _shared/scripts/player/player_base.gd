class_name PlayerBase
extends CharacterBody2D

## 모든 플레이어의 기본 클래스
## 체력, 이동, 데미지 처리를 담당합니다.

signal health_changed(current: float, max_health: float)
signal died()
signal level_up(new_level: int)
signal xp_changed(current: int, required: int)

# --- Movement ---
@export var speed: int = 200

# --- Health ---
@export var max_health: float = 100.0
var current_health: float
var is_invincible: bool = false
@export var invincibility_duration: float = 1.0

# --- Experience ---
var current_xp: int = 0
var current_level: int = 1
var xp_to_next_level: int = 10

# --- Animation State ---
var last_direction := Vector2.DOWN

# --- Sprite Reference (자식에서 설정) ---
var player_sprite: AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	_on_ready()

## 자식 클래스에서 오버라이드
func _on_ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	var direction = _get_input_direction()

	if direction != Vector2.ZERO:
		velocity = _calculate_velocity(direction, delta)
		last_direction = direction
	else:
		velocity = Vector2.ZERO

	# 이동 전 위치 저장 (밀림 방지용)
	var prev_position = global_position

	move_and_slide()

	# 밀려서 이동 불가 지역에 들어갔는지 체크
	if not _is_current_position_valid():
		global_position = prev_position

	_on_physics_process(delta)

## 입력 방향 (오버라이드 가능)
func _get_input_direction() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

## 속도 계산 (오버라이드 가능 - 타일 충돌 등)
func _calculate_velocity(direction: Vector2, _delta: float) -> Vector2:
	return direction * speed

## 추가 physics 처리 (자식에서 오버라이드)
func _on_physics_process(_delta: float) -> void:
	pass

## 현재 위치가 유효한지 체크 (자식에서 오버라이드 - 지형 충돌 등)
func _is_current_position_valid() -> bool:
	return true

# --- Health System ---

## 데미지 받기
func take_damage(amount: float, _knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or current_health <= 0:
		return

	current_health -= amount
	health_changed.emit(current_health, max_health)

	_flash_damage()
	_start_invincibility()

	if current_health <= 0:
		_die()

## 피격 시 깜빡임 효과
func _flash_damage() -> void:
	if player_sprite:
		player_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and player_sprite:
			player_sprite.modulate = Color.WHITE

## 무적 시간 처리
func _start_invincibility() -> void:
	is_invincible = true

	var blink_count = int(invincibility_duration / 0.1)
	for i in range(blink_count):
		if not is_instance_valid(self):
			return
		if player_sprite:
			player_sprite.modulate.a = 0.3
		await get_tree().create_timer(0.05).timeout
		if not is_instance_valid(self):
			return
		if player_sprite:
			player_sprite.modulate.a = 1.0
		await get_tree().create_timer(0.05).timeout

	is_invincible = false

## 사망 처리
func _die() -> void:
	died.emit()
	_on_die()

## 자식에서 오버라이드 (게임오버 등)
func _on_die() -> void:
	pass

## 체력 회복
func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

# --- Experience System ---

## 경험치 획득
func add_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit(current_xp, xp_to_next_level)

	while current_xp >= xp_to_next_level:
		_level_up()

## 레벨업
func _level_up() -> void:
	current_xp -= xp_to_next_level
	current_level += 1
	xp_to_next_level = _calculate_xp_for_level(current_level)

	level_up.emit(current_level)
	xp_changed.emit(current_xp, xp_to_next_level)
	_on_level_up()

## 레벨업 시 호출 (자식에서 오버라이드)
func _on_level_up() -> void:
	pass

## 레벨별 필요 경험치 계산
func _calculate_xp_for_level(level: int) -> int:
	return 10 + (level - 1) * 5
