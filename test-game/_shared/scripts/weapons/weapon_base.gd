class_name WeaponBase
extends Node2D

## 무기 기본 클래스
## 발사, 쿨다운, 데미지 계산을 처리합니다.
## EventBus를 통해 이벤트 발행

signal fired(weapon: WeaponBase, projectiles: Array)
signal reloaded(weapon: WeaponBase)

## WeaponData 리소스 (class_name 대신 Resource 타입 사용 - CLI 호환)
@export var weapon_data: Resource

## 소유자 참조
var owner_node: Node2D = null

## 발사 위치 (자식 노드로 설정)
var muzzle: Node2D = null

## 쿨다운 관리
var can_fire: bool = true
var cooldown_timer: float = 0.0

## 스탯 수정자 (스킬 등에서 적용)
var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0  ## 무기 레벨 배수 (WeaponManager)
var skill_fire_rate_multiplier: float = 1.0  ## 스킬 배수 (StatManager)
var projectile_speed_multiplier: float = 1.0
var additional_projectiles: int = 0

## EventBus 참조
var event_bus: Node = null

## 현재 조준 방향
var aim_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# EventBus 참조
	event_bus = get_node_or_null("/root/EventBus")

	# 소유자 찾기
	owner_node = get_parent()

	# Muzzle 노드 찾기
	muzzle = get_node_or_null("Muzzle")
	if not muzzle:
		muzzle = self

func _process(delta: float) -> void:
	# 쿨다운 처리
	if not can_fire:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_fire = true
			reloaded.emit(self)

## 발사 시도
func try_fire() -> bool:
	if not can_fire or not weapon_data:
		return false

	_fire()
	return true

## 자동 발사 (auto_fire가 true일 때 외부에서 호출)
func auto_fire_tick() -> void:
	if weapon_data and weapon_data.auto_fire:
		try_fire()

## 실제 발사 로직
func _fire() -> void:
	can_fire = false
	cooldown_timer = _get_fire_rate()

	var projectiles: Array[Node2D] = []
	var total_projectiles = weapon_data.projectiles_per_shot + additional_projectiles

	# 발사 방향 계산
	var fire_direction = aim_direction
	if weapon_data.auto_aim:
		var target = _find_nearest_enemy()
		if target:
			fire_direction = (target.global_position - global_position).normalized()

	# 다중 발사체 각도 계산
	var start_angle = fire_direction.angle()
	var angle_step = deg_to_rad(weapon_data.spread_angle)
	var total_spread = angle_step * (total_projectiles - 1)
	var first_angle = start_angle - total_spread / 2

	for i in range(total_projectiles):
		var angle = first_angle + angle_step * i if total_projectiles > 1 else start_angle
		var direction = Vector2.RIGHT.rotated(angle)

		var projectile = _spawn_projectile(direction)
		if projectile:
			projectiles.append(projectile)

	# 발사 사운드
	_play_fire_sound()

	# 시그널 발행
	fired.emit(self, projectiles)

	# EventBus 발행
	if event_bus and owner_node:
		for proj in projectiles:
			event_bus.projectile_fired.emit(proj, owner_node)

## 발사체 생성
func _spawn_projectile(direction: Vector2) -> Node2D:
	if not weapon_data.projectile_scene:
		return null

	var projectile = weapon_data.projectile_scene.instantiate()

	# 위치 설정
	var spawn_pos = muzzle.global_position if muzzle else global_position
	projectile.global_position = spawn_pos

	# 방향 설정
	projectile.rotation = direction.angle()
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)
	elif "direction" in projectile:
		projectile.direction = direction

	# 스탯 적용
	if "damage" in projectile:
		projectile.damage = _get_damage()
	if "speed" in projectile:
		projectile.speed = _get_projectile_speed()
	if "knockback_force" in projectile:
		projectile.knockback_force = weapon_data.knockback_force
	if "lifetime" in projectile:
		projectile.lifetime = weapon_data.projectile_lifetime
	if "pierce_count" in projectile:
		projectile.pierce_count = weapon_data.pierce_count

	# 씬에 추가
	get_tree().root.add_child(projectile)

	return projectile

## 가장 가까운 적 찾기
func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_squared_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest

## 발사 사운드 재생
func _play_fire_sound() -> void:
	if weapon_data.fire_sound:
		var audio = AudioStreamPlayer.new()
		audio.stream = weapon_data.fire_sound
		audio.bus = "SFX"
		add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)

# --- 스탯 계산 (수정자 적용) ---

func _get_damage() -> float:
	return weapon_data.base_damage * damage_multiplier

func _get_fire_rate() -> float:
	return weapon_data.fire_rate * fire_rate_multiplier * skill_fire_rate_multiplier

func _get_projectile_speed() -> float:
	return weapon_data.projectile_speed * projectile_speed_multiplier

# --- 수정자 API ---

## 데미지 수정자 설정
func set_damage_multiplier(value: float) -> void:
	damage_multiplier = value

## 발사 속도 수정자 설정 - 무기 레벨용 (WeaponManager)
func set_fire_rate_multiplier(value: float) -> void:
	fire_rate_multiplier = value

## 발사 속도 수정자 설정 - 스킬용 (Player/StatManager)
func set_skill_fire_rate_multiplier(value: float) -> void:
	skill_fire_rate_multiplier = value

## 추가 발사체 수 설정
func set_additional_projectiles(count: int) -> void:
	additional_projectiles = count

## 모든 수정자 초기화
func reset_modifiers() -> void:
	damage_multiplier = 1.0
	fire_rate_multiplier = 1.0
	skill_fire_rate_multiplier = 1.0
	projectile_speed_multiplier = 1.0
	additional_projectiles = 0

## 조준 방향 설정
func set_aim_direction(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		aim_direction = direction.normalized()
