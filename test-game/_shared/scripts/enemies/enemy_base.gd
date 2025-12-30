class_name EnemyBase
extends CharacterBody2D

## 모든 적의 기본 클래스
## 체력, 이동, 데미지 처리를 담당합니다.
## EventBus를 통해 이벤트 발행

signal died(enemy: EnemyBase, position: Vector2)
signal damaged(enemy: EnemyBase, amount: float)

@export var enemy_data: EnemyData

## 현재 상태
var current_health: float
var target: Node2D  ## 추적 대상 (플레이어)
var is_dead: bool = false

## EventBus 참조
var event_bus: Node = null

## 넉백
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 10.0

## 스프라이트 참조 (자식 노드에서 설정)
var sprite: Sprite2D

## 애니메이션
var animation_timer: float = 0.0
var animation_speed: float = 10.0  ## 초당 프레임 수

## 공격
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_cooldown: float = 1.0  ## 공격 쿨다운 (초)
var attack_range: float = 25.0  ## 공격 범위
var has_dealt_damage: bool = false  ## 이번 공격에서 데미지를 줬는지

## 애니메이션 프레임 설정
var walk_frames_start: int = 0
var walk_frames_end: int = 5
var attack_frames_start: int = 6
var attack_frames_end: int = 9

## Separation (적끼리 겹침 방지)
var separation_radius: float = 20.0  ## 분리 감지 반경
var separation_force: float = 80.0  ## 분리 힘

## Elite 플래그 (거리 컬링 제외)
var is_elite: bool = false

## 난이도 스케일링 (SpawnManager에서 설정)
var damage_multiplier: float = 1.0
var health_multiplier: float = 1.0

func set_damage_multiplier(mult: float) -> void:
	damage_multiplier = mult

func set_health_multiplier(mult: float) -> void:
	health_multiplier = mult
	if enemy_data:
		current_health = enemy_data.max_health * mult

## Elite 시각 효과 및 설정 적용
func apply_elite_visuals(stat_mult: float = 3.0) -> void:
	is_elite = true
	add_to_group("elites")  # 미니맵 표시용

	# 스탯 강화
	set_health_multiplier(stat_mult)
	set_damage_multiplier(stat_mult)

	# 시각적 구분
	if sprite:
		sprite.scale *= 1.5  # 1.5배 크기
		sprite.modulate = Color(1.0, 0.4, 0.4)  # 붉은 색조

func _ready() -> void:
	add_to_group("enemies")

	# EventBus 참조 획득
	event_bus = get_node_or_null("/root/EventBus")

	if enemy_data:
		current_health = enemy_data.max_health
	else:
		current_health = 10.0

	# 스프라이트 찾기
	sprite = get_node_or_null("Sprite2D") as Sprite2D

	# 스폰 이벤트 발행
	if event_bus:
		event_bus.enemy_spawned.emit(self)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 공격 쿨다운 처리
	if attack_timer > 0:
		attack_timer -= delta

	# 넉백 처리
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)

	# 공격 범위 체크
	_check_attack()

	# 공격 중이면 이동 안함
	if is_attacking:
		velocity = knockback_velocity
		_update_attack_animation(delta)
	else:
		# 이동 (자식 클래스에서 오버라이드)
		var move_velocity = _get_movement_velocity()
		velocity = move_velocity + knockback_velocity
		# 스프라이트 방향 및 걷기 애니메이션
		_update_sprite_direction()

	move_and_slide()

## 오버라이드: 이동 방향 계산
func _get_movement_velocity() -> Vector2:
	if not target:
		return Vector2.ZERO

	var direction = (target.global_position - global_position).normalized()
	var speed = enemy_data.move_speed if enemy_data else 50.0
	var chase_velocity = direction * speed

	# 다른 적들과 분리
	var separation = _get_separation_velocity()

	return chase_velocity + separation

## 주변 적들과의 분리 벡터 계산 (겹침 방지)
func _get_separation_velocity() -> Vector2:
	var separation = Vector2.ZERO
	var nearby_count = 0

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not is_instance_valid(enemy):
			continue

		var to_self = global_position - enemy.global_position
		var distance = to_self.length()

		if distance < separation_radius and distance > 0:
			# 거리가 가까울수록 강하게 밀어냄
			separation += to_self.normalized() * (separation_radius - distance) / separation_radius
			nearby_count += 1

	if nearby_count > 0:
		separation = separation.normalized() * separation_force

	return separation

## 스프라이트 방향 및 걷기 애니메이션 업데이트
func _update_sprite_direction() -> void:
	if not sprite:
		return

	# 좌우 방향 전환
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	# 걷기 애니메이션 (움직일 때만)
	var walk_frame_count = walk_frames_end - walk_frames_start + 1
	if velocity.length() > 1.0 and walk_frame_count > 1:
		animation_timer += get_physics_process_delta_time() * animation_speed
		sprite.frame = walk_frames_start + (int(animation_timer) % walk_frame_count)
	else:
		# 정지 시 첫 프레임
		sprite.frame = walk_frames_start
		animation_timer = 0.0

## 공격 범위 체크 및 공격 시작
func _check_attack() -> void:
	if not target or is_attacking or attack_timer > 0:
		return

	var distance = global_position.distance_to(target.global_position)
	if distance <= attack_range:
		_start_attack()

## 공격 시작
func _start_attack() -> void:
	is_attacking = true
	has_dealt_damage = false
	animation_timer = 0.0

## 공격 애니메이션 업데이트
func _update_attack_animation(delta: float) -> void:
	if not sprite:
		is_attacking = false
		return

	var attack_frame_count = attack_frames_end - attack_frames_start + 1
	animation_timer += delta * animation_speed

	var current_frame_index = int(animation_timer) % attack_frame_count
	sprite.frame = attack_frames_start + current_frame_index

	# 공격 중간에 데미지 (프레임 2에서)
	if current_frame_index >= 2 and not has_dealt_damage:
		_deal_damage_to_target()
		has_dealt_damage = true

	# 애니메이션 완료
	if animation_timer >= attack_frame_count:
		_end_attack()

## 타겟에게 데미지
func _deal_damage_to_target() -> void:
	if not target:
		return

	# 거리 재확인
	var distance = global_position.distance_to(target.global_position)
	if distance > attack_range * 1.5:
		return

	# 플레이어에게 데미지
	if target.has_method("take_damage"):
		var base_damage = enemy_data.damage if enemy_data else 10.0
		var damage_amount = base_damage * damage_multiplier
		var knockback_dir = (target.global_position - global_position).normalized()
		target.take_damage(damage_amount, knockback_dir)

## 공격 종료
func _end_attack() -> void:
	is_attacking = false
	attack_timer = attack_cooldown
	animation_timer = 0.0

## 데미지 받기
func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	if is_dead:
		return

	current_health -= amount

	# 로컬 시그널 발행
	damaged.emit(self, amount)

	# EventBus로 이벤트 발행
	if event_bus:
		event_bus.enemy_damaged.emit(self, amount)

	# 데미지 팝업 생성
	_spawn_damage_popup(amount)

	# 넉백 적용
	if knockback_force > 0 and enemy_data:
		var resistance = enemy_data.knockback_resistance
		knockback_velocity += knockback_dir * knockback_force * (1.0 - resistance)

	# 피격 이펙트 (깜빡임)
	_flash_damage()

	if current_health <= 0:
		_die()

## 피격 시 깜빡임 효과
func _flash_damage() -> void:
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and sprite:
			sprite.modulate = Color.WHITE

## 사망 처리
func _die() -> void:
	if is_dead:
		return

	is_dead = true
	var xp = enemy_data.xp_value if enemy_data else 0

	# 로컬 시그널 발행
	died.emit(self, global_position)

	# EventBus로 이벤트 발행 (권장)
	if event_bus:
		event_bus.enemy_killed.emit(self, global_position, xp)
	else:
		# 폴백: 직접 레벨에 통보 (하위 호환성)
		var level = get_tree().get_first_node_in_group("level")
		if level and level.has_method("on_enemy_killed"):
			level.on_enemy_killed(xp)

	# 드롭 처리
	_spawn_drops()

	queue_free()

## XP 젬 씬 (프로젝트에서 설정)
var xp_gem_scene: PackedScene = null

## 체력 픽업 씬
var health_pickup_scene: PackedScene = null

## 보물상자 씬
var treasure_chest_scene: PackedScene = null

## 체력 픽업 드롭 설정 (EnemyData에서 읽거나 기본값 사용)
const DEFAULT_HEALTH_DROP_BASE_CHANCE: float = 0.05
const DEFAULT_HEALTH_DROP_LOW_HP_CHANCE: float = 0.20
const DEFAULT_HEALTH_DROP_LOW_HP_THRESHOLD: float = 0.3
const DEFAULT_TREASURE_DROP_CHANCE: float = 0.01

## 드롭 아이템 스폰 (자식에서 오버라이드 가능)
func _spawn_drops() -> void:
	if not enemy_data:
		return

	# XP 젬 스폰
	if enemy_data.xp_value > 0:
		_spawn_xp_gem()

	# 체력 픽업 스폰 (플레이어 체력에 따라 확률 조정)
	_try_spawn_health_pickup()

	# 보물상자 스폰 (낮은 확률)
	_try_spawn_treasure_chest()

## 체력 픽업 드롭 시도
func _try_spawn_health_pickup() -> void:
	# EnemyData에서 드롭 설정 읽기 (없으면 기본값 사용)
	var base_chance = DEFAULT_HEALTH_DROP_BASE_CHANCE
	var low_hp_chance = DEFAULT_HEALTH_DROP_LOW_HP_CHANCE
	var low_hp_threshold = DEFAULT_HEALTH_DROP_LOW_HP_THRESHOLD

	if enemy_data:
		base_chance = enemy_data.health_drop_base_chance
		low_hp_chance = enemy_data.health_drop_low_hp_chance
		low_hp_threshold = enemy_data.health_drop_low_hp_threshold

	var drop_chance = base_chance

	# 플레이어 체력이 낮으면 드롭 확률 증가
	if target and is_instance_valid(target):
		if "current_health" in target and "max_health" in target:
			var health_ratio = target.current_health / target.max_health
			if health_ratio <= low_hp_threshold:
				drop_chance = low_hp_chance

	if randf() <= drop_chance:
		_spawn_health_pickup()

## 체력 픽업 스폰
func _spawn_health_pickup() -> void:
	# 씬 로드 (캐시)
	if not health_pickup_scene:
		health_pickup_scene = load("res://scenes/pickups/health_pickup.tscn")

	if not health_pickup_scene:
		return

	var pickup = health_pickup_scene.instantiate()
	pickup.global_position = global_position

	get_tree().current_scene.call_deferred("add_child", pickup)

## XP 젬 스폰
func _spawn_xp_gem() -> void:
	# 씬 로드 (캐시)
	if not xp_gem_scene:
		xp_gem_scene = load("res://scenes/pickups/xp_gem.tscn")

	if not xp_gem_scene:
		return

	var gem = xp_gem_scene.instantiate()
	gem.xp_value = enemy_data.xp_value
	gem.global_position = global_position

	get_tree().current_scene.call_deferred("add_child", gem)

## 보물상자 드롭 시도
func _try_spawn_treasure_chest() -> void:
	var chance = DEFAULT_TREASURE_DROP_CHANCE

	if enemy_data and "treasure_drop_chance" in enemy_data:
		chance = enemy_data.treasure_drop_chance

	if randf() <= chance:
		_spawn_treasure_chest()

## 보물상자 스폰
func _spawn_treasure_chest() -> void:
	# 씬 로드 (캐시)
	if not treasure_chest_scene:
		treasure_chest_scene = load("res://scenes/pickups/treasure_chest.tscn")

	if not treasure_chest_scene:
		return

	var chest = treasure_chest_scene.instantiate()
	chest.global_position = global_position

	get_tree().current_scene.call_deferred("add_child", chest)

## 타겟 설정
func set_target(new_target: Node2D) -> void:
	target = new_target

## 데미지 팝업 씬
var damage_popup_scene: PackedScene = null

## 데미지 팝업 생성
func _spawn_damage_popup(amount: float) -> void:
	# 씬 로드 (캐시)
	if not damage_popup_scene:
		damage_popup_scene = load("res://scenes/ui/damage_popup.tscn")

	if not damage_popup_scene:
		return

	var popup = damage_popup_scene.instantiate()
	popup.global_position = global_position + Vector2(0, -10)  # 약간 위에

	get_tree().current_scene.call_deferred("add_child", popup)

	# setup은 다음 프레임에 호출 (씬 트리에 추가된 후)
	popup.call_deferred("setup", amount, "damage")
