class_name EnemyBase
extends CharacterBody2D

## 모든 적의 기본 클래스
##
## 체력, 이동, 데미지 처리를 담당합니다.
## EventBus를 통해 이벤트 발행
## 드롭 처리는 EnemyDropController에 위임

const EnemyDropControllerClass = preload("res://_shared/scripts/enemies/enemy_drop_controller.gd")

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
var animation_speed: float = 10.0

## 공격
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_cooldown: float = 1.0
var attack_range: float = 25.0
var has_dealt_damage: bool = false

## 애니메이션 프레임 설정
var walk_frames_start: int = 0
var walk_frames_end: int = 5
var attack_frames_start: int = 6
var attack_frames_end: int = 9

## Separation (적끼리 겹침 방지)
var separation_radius: float = 20.0
var separation_force: float = 80.0

## Elite 플래그 (거리 컬링 제외)
var is_elite: bool = false

## 난이도 스케일링 (SpawnManager에서 설정)
var damage_multiplier: float = 1.0
var health_multiplier: float = 1.0

## 드롭 컨트롤러 (드롭 로직 위임)
var drop_controller: EnemyDropControllerClass

func set_damage_multiplier(mult: float) -> void:
	damage_multiplier = mult

func set_health_multiplier(mult: float) -> void:
	health_multiplier = mult
	if enemy_data:
		current_health = enemy_data.max_health * mult

## Elite 시각 효과 및 설정 적용
func apply_elite_visuals(stat_mult: float = 3.0) -> void:
	is_elite = true
	add_to_group("elites")

	set_health_multiplier(stat_mult)
	set_damage_multiplier(stat_mult)

	if sprite:
		sprite.scale *= 1.5
		sprite.modulate = Color(1.0, 0.4, 0.4)

func _ready() -> void:
	add_to_group("enemies")

	event_bus = Services.event_bus
	drop_controller = EnemyDropControllerClass.new()

	_load_config()

	if enemy_data:
		current_health = enemy_data.max_health
	else:
		current_health = 10.0

	sprite = get_node_or_null("Sprite2D") as Sprite2D

	if event_bus:
		event_bus.enemy_spawned.emit(self)

## GameConfig에서 설정값 로드
func _load_config() -> void:
	var config = Services.config
	if not config:
		return

	knockback_decay = config.knockback_decay
	attack_cooldown = config.enemy_attack_cooldown
	attack_range = config.enemy_attack_range
	separation_radius = config.enemy_separation_radius
	separation_force = config.enemy_separation_force
	animation_speed = config.enemy_animation_speed

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if attack_timer > 0:
		attack_timer -= delta

	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)

	_check_attack()

	if is_attacking:
		velocity = knockback_velocity
		_update_attack_animation(delta)
	else:
		var move_velocity = _get_movement_velocity()
		velocity = move_velocity + knockback_velocity
		_update_sprite_direction()

	move_and_slide()

## 오버라이드: 이동 방향 계산
func _get_movement_velocity() -> Vector2:
	if not target:
		return Vector2.ZERO

	var direction = (target.global_position - global_position).normalized()
	var speed = enemy_data.move_speed if enemy_data else 50.0
	var chase_velocity = direction * speed

	var separation = _get_separation_velocity()

	return chase_velocity + separation

## 주변 적들과의 분리 벡터 계산
func _get_separation_velocity() -> Vector2:
	var separation = Vector2.ZERO
	var nearby_count = 0

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not is_instance_valid(enemy):
			continue

		var to_self = global_position - enemy.global_position
		var distance = to_self.length()

		if distance < separation_radius and distance > 0:
			separation += to_self.normalized() * (separation_radius - distance) / separation_radius
			nearby_count += 1

	if nearby_count > 0:
		separation = separation.normalized() * separation_force

	return separation

## 스프라이트 방향 및 걷기 애니메이션 업데이트
func _update_sprite_direction() -> void:
	if not sprite:
		return

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	var walk_frame_count = walk_frames_end - walk_frames_start + 1
	if velocity.length() > 1.0 and walk_frame_count > 1:
		animation_timer += get_physics_process_delta_time() * animation_speed
		sprite.frame = walk_frames_start + (int(animation_timer) % walk_frame_count)
	else:
		sprite.frame = walk_frames_start
		animation_timer = 0.0

## 공격 범위 체크 및 공격 시작
func _check_attack() -> void:
	if not target or is_attacking or attack_timer > 0:
		return

	var distance = global_position.distance_to(target.global_position)
	if distance <= attack_range:
		_start_attack()

func _start_attack() -> void:
	is_attacking = true
	has_dealt_damage = false
	animation_timer = 0.0

func _update_attack_animation(delta: float) -> void:
	if not sprite:
		is_attacking = false
		return

	var attack_frame_count = attack_frames_end - attack_frames_start + 1
	animation_timer += delta * animation_speed

	var current_frame_index = int(animation_timer) % attack_frame_count
	sprite.frame = attack_frames_start + current_frame_index

	if current_frame_index >= 2 and not has_dealt_damage:
		_deal_damage_to_target()
		has_dealt_damage = true

	if animation_timer >= attack_frame_count:
		_end_attack()

func _deal_damage_to_target() -> void:
	if not target:
		return

	var distance = global_position.distance_to(target.global_position)
	if distance > attack_range * 1.5:
		return

	if target.has_method("take_damage"):
		var base_damage = enemy_data.damage if enemy_data else 10.0
		var damage_amount = base_damage * damage_multiplier
		var knockback_dir = (target.global_position - global_position).normalized()
		target.take_damage(damage_amount, knockback_dir)

func _end_attack() -> void:
	is_attacking = false
	attack_timer = attack_cooldown
	animation_timer = 0.0

## 데미지 받기
func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	if is_dead:
		return

	current_health -= amount

	damaged.emit(self, amount)

	if event_bus:
		event_bus.enemy_damaged.emit(self, amount)

	# 데미지 팝업 (EnemyDropController에 위임)
	if drop_controller:
		drop_controller.spawn_damage_popup(amount, global_position)

	if knockback_force > 0 and enemy_data:
		var resistance = enemy_data.knockback_resistance
		knockback_velocity += knockback_dir * knockback_force * (1.0 - resistance)

	_flash_damage()

	if current_health <= 0:
		_die()

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

	died.emit(self, global_position)

	if event_bus:
		event_bus.enemy_killed.emit(self, global_position, xp)
	else:
		var level = get_tree().get_first_node_in_group("level")
		if level and level.has_method("on_enemy_killed"):
			level.on_enemy_killed(xp)

	# 드롭 처리 (EnemyDropController에 위임)
	if drop_controller:
		drop_controller.spawn_drops(enemy_data, global_position, target)

	queue_free()

## 타겟 설정
func set_target(new_target: Node2D) -> void:
	target = new_target
