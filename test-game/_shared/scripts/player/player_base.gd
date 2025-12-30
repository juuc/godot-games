class_name PlayerBase
extends CharacterBody2D

## 모든 플레이어의 기본 클래스
## 체력, 이동, 데미지 처리를 담당합니다.
## EventBus를 통해 이벤트 발행
## StatManager로 스탯 관리

signal health_changed(current: float, max_health: float)
signal died()
signal level_up(new_level: int)
signal xp_changed(current: int, required: int)
signal stats_updated()

# --- Base Stats (초기값, StatManager에 전달) ---
@export_group("Base Stats")
@export var base_speed: float = 200.0
@export var base_max_health: float = 100.0
@export var base_invincibility_duration: float = 1.0

# --- Runtime State ---
var current_health: float
var is_invincible: bool = false

# --- Experience ---
var current_xp: int = 0
var current_level: int = 1
var xp_to_next_level: int = 10

# --- Animation State ---
var last_direction := Vector2.DOWN

# --- Sprite Reference (자식에서 설정) ---
var player_sprite: AnimatedSprite2D

# --- Core Systems ---
var event_bus: Node = null
var stat_manager = null  ## StatManager 인스턴스

# --- Computed Stats (StatManager에서 계산) ---
var speed: float:
	get:
		if stat_manager:
			return stat_manager.get_move_speed()
		return base_speed

var max_health: float:
	get:
		if stat_manager:
			return stat_manager.get_max_health()
		return base_max_health

var invincibility_duration: float:
	get:
		if stat_manager:
			return stat_manager.get_stat(11)  # INVINCIBILITY_DURATION
		return base_invincibility_duration

func _ready() -> void:
	add_to_group("player")

	# EventBus 참조 획득
	event_bus = get_node_or_null("/root/EventBus")

	# StatManager 초기화
	_init_stat_manager()

	current_health = max_health

	_on_ready()

## StatManager 초기화
func _init_stat_manager() -> void:
	var StatManagerClass = load("res://_shared/scripts/progression/stat_manager.gd")
	if StatManagerClass:
		stat_manager = StatManagerClass.new()
		# 기본 스탯 설정
		stat_manager.set_base_stat(0, base_max_health)  # MAX_HEALTH
		stat_manager.set_base_stat(1, base_speed)       # MOVE_SPEED
		stat_manager.set_base_stat(11, base_invincibility_duration)  # INVINCIBILITY_DURATION
		stat_manager.stats_changed.connect(_on_stats_changed)

## 스탯 변경 시 호출
func _on_stats_changed() -> void:
	# 최대 체력이 증가하면 현재 체력도 비례해서 증가
	var new_max = max_health
	if current_health > new_max:
		current_health = new_max
	health_changed.emit(current_health, new_max)
	stats_updated.emit()

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

	# 로컬 시그널
	health_changed.emit(current_health, max_health)

	# EventBus로 이벤트 발행
	if event_bus:
		event_bus.player_damaged.emit(self, amount, current_health)

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
	# 로컬 시그널
	died.emit()

	# EventBus로 이벤트 발행
	if event_bus:
		event_bus.player_died.emit(self, global_position)

	_on_die()

## 자식에서 오버라이드 (게임오버 등)
func _on_die() -> void:
	pass

## 체력 회복
func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)

	# 로컬 시그널
	health_changed.emit(current_health, max_health)

	# EventBus로 이벤트 발행
	if event_bus:
		event_bus.player_healed.emit(self, amount, current_health)

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

	# 로컬 시그널
	level_up.emit(current_level)
	xp_changed.emit(current_xp, xp_to_next_level)

	# EventBus로 이벤트 발행
	if event_bus:
		event_bus.player_level_up.emit(self, current_level)

	_on_level_up()

## 레벨업 무적 효과 (반짝임 + 2초 무적)
func _start_levelup_invincibility() -> void:
	is_invincible = true

	var duration = 2.0
	var blink_interval = 0.1
	var blink_count = int(duration / blink_interval)

	for i in range(blink_count):
		if not is_instance_valid(self):
			return
		if player_sprite:
			# 황금색으로 반짝임
			player_sprite.modulate = Color(1.0, 0.9, 0.3, 1.0)
		await get_tree().create_timer(blink_interval / 2).timeout
		if not is_instance_valid(self):
			return
		if player_sprite:
			player_sprite.modulate = Color.WHITE
		await get_tree().create_timer(blink_interval / 2).timeout

	is_invincible = false

## 레벨업 시 호출 (자식에서 오버라이드)
func _on_level_up() -> void:
	pass

## 레벨별 필요 경험치 계산
func _calculate_xp_for_level(level: int) -> int:
	return 10 + (level - 1) * 5

# --- Stat Modifier API ---

## 스킬에서 수정자 적용
func apply_skill_modifier(skill, level: int) -> void:
	if not stat_manager:
		return

	# 기존 스킬 수정자 제거
	stat_manager.remove_modifiers_by_source(skill.id)

	# 새 수정자 생성 및 적용
	if skill.has_method("create_modifier"):
		var modifier = skill.create_modifier(level)
		if modifier:
			stat_manager.add_modifier(modifier)

## 모든 스킬 수정자 재적용 (SkillManager와 연동)
func apply_all_skill_modifiers(skill_manager) -> void:
	if not stat_manager:
		return

	# 모든 수정자 초기화
	stat_manager.clear_modifiers()

	# 획득한 스킬들의 수정자 적용
	if skill_manager and skill_manager.has_method("get_acquired_skills"):
		var acquired = skill_manager.get_acquired_skills()
		for skill_id in acquired:
			var skill = skill_manager.get_skill(skill_id)
			var skill_level = skill_manager.get_skill_level(skill_id)
			if skill and skill.has_method("create_modifier"):
				var modifier = skill.create_modifier(skill_level)
				if modifier:
					stat_manager.add_modifier(modifier)

## StatManager 직접 접근 (고급 사용)
func get_stat_manager():
	return stat_manager
