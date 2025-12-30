class_name WeaponManager
extends RefCounted

## 다중 무기 관리자
## 최대 3개의 무기를 관리하고, 획득/업그레이드를 처리합니다.

signal weapon_acquired(weapon_data, level: int)
signal weapon_upgraded(weapon_data, new_level: int)
signal weapons_changed

const MAX_WEAPONS: int = 3

## 무기 풀 (선택 가능한 모든 무기)
var weapon_pool: Array = []

## 활성 무기 {weapon_id: {data: Resource, level: int}}
var active_weapons: Dictionary = {}

## 무기 인스턴스 (실제 발사 담당)
var weapon_instances: Array = []

## 무기 인스턴스의 부모 노드
var weapon_parent: Node2D = null

## EventBus 참조
var event_bus: Node = null

func _init() -> void:
	event_bus = Engine.get_main_loop().root.get_node_or_null("/root/EventBus") if Engine.get_main_loop() else null

## 무기 풀 설정
func set_weapon_pool(weapons: Array) -> void:
	weapon_pool = weapons

## 무기 인스턴스 부모 노드 설정
func set_weapon_parent(parent: Node2D) -> void:
	weapon_parent = parent

## 무기 추가 또는 업그레이드
func add_weapon(weapon_data) -> bool:
	var weapon_id = weapon_data.id

	if active_weapons.has(weapon_id):
		# 기존 무기 업그레이드
		return upgrade_weapon(weapon_id)
	else:
		# 새 무기 획득
		if active_weapons.size() >= MAX_WEAPONS:
			return false

		active_weapons[weapon_id] = {
			"data": weapon_data,
			"level": 1
		}

		weapon_acquired.emit(weapon_data, 1)
		weapons_changed.emit()
		return true

## 무기 업그레이드
func upgrade_weapon(weapon_id: String) -> bool:
	if not active_weapons.has(weapon_id):
		return false

	var weapon_info = active_weapons[weapon_id]
	var weapon_data = weapon_info.data
	var current_level = weapon_info.level
	var max_level = weapon_data.max_level if "max_level" in weapon_data else 5

	if current_level >= max_level:
		return false

	weapon_info.level += 1
	weapon_upgraded.emit(weapon_data, weapon_info.level)
	weapons_changed.emit()

	# 무기 인스턴스 스탯 업데이트
	_update_weapon_instance_stats(weapon_id)

	return true

## 무기 레벨 조회
func get_weapon_level(weapon_id: String) -> int:
	if active_weapons.has(weapon_id):
		return active_weapons[weapon_id].level
	return 0

## 새 무기 추가 가능 여부
func can_add_weapon() -> bool:
	return active_weapons.size() < MAX_WEAPONS

## 무기 인스턴스 생성 및 등록
func create_weapon_instance(weapon_data, WeaponBaseClass, MeleeWeaponBaseClass = null) -> Node2D:
	var instance: Node2D

	# 근접 무기 여부 확인
	var is_melee = weapon_data.is_melee if "is_melee" in weapon_data else false

	if is_melee and MeleeWeaponBaseClass:
		instance = MeleeWeaponBaseClass.new()
	else:
		instance = WeaponBaseClass.new()

	instance.name = "Weapon_" + weapon_data.id
	instance.weapon_data = weapon_data

	# Muzzle 노드 생성 (발사 위치)
	var muzzle = Node2D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector2(16, 0)
	instance.add_child(muzzle)

	weapon_instances.append(instance)

	# 초기 레벨 스탯 적용
	_apply_level_stats(instance, weapon_data, get_weapon_level(weapon_data.id))

	return instance

## 무기 인스턴스 제거
func remove_weapon_instance(weapon_id: String) -> void:
	for i in range(weapon_instances.size() - 1, -1, -1):
		var instance = weapon_instances[i]
		if instance.weapon_data and instance.weapon_data.id == weapon_id:
			weapon_instances.remove_at(i)
			instance.queue_free()
			break

## 모든 무기 인스턴스 반환
func get_weapon_instances() -> Array:
	return weapon_instances

## 레벨업 선택지용 옵션 생성
func get_available_options() -> Array:
	var options: Array = []

	for weapon_data in weapon_pool:
		var weapon_id = weapon_data.id
		var current_level = get_weapon_level(weapon_id)
		var max_level = weapon_data.max_level if "max_level" in weapon_data else 5

		# 최대 레벨이면 스킵
		if current_level >= max_level:
			continue

		# 새 무기인데 슬롯이 없으면 스킵
		if current_level == 0 and not can_add_weapon():
			continue

		options.append({
			"type": "weapon",
			"data": weapon_data,
			"level": current_level
		})

	return options

## 무기 인스턴스 스탯 업데이트
func _update_weapon_instance_stats(weapon_id: String) -> void:
	var weapon_info = active_weapons.get(weapon_id)
	if not weapon_info:
		return

	var weapon_data = weapon_info.data
	var level = weapon_info.level

	for instance in weapon_instances:
		if instance.weapon_data and instance.weapon_data.id == weapon_id:
			_apply_level_stats(instance, weapon_data, level)
			break

## 레벨에 따른 스탯 적용
func _apply_level_stats(instance, weapon_data, level: int) -> void:
	if level <= 0:
		return

	var level_index = level - 1  # 배열은 0부터 시작

	# 데미지 레벨 적용
	if "level_damage" in weapon_data and weapon_data.level_damage.size() > level_index:
		var base_damage = weapon_data.level_damage[level_index]
		instance.set_damage_multiplier(base_damage / weapon_data.base_damage)

	# 발사 속도 레벨 적용
	if "level_fire_rate" in weapon_data and weapon_data.level_fire_rate.size() > level_index:
		var fire_rate = weapon_data.level_fire_rate[level_index]
		instance.set_fire_rate_multiplier(fire_rate / weapon_data.fire_rate)

	# 발사체 수 레벨 적용 (샷건 등)
	if "level_projectiles" in weapon_data and weapon_data.level_projectiles.size() > level_index:
		var projectiles = weapon_data.level_projectiles[level_index]
		instance.set_additional_projectiles(projectiles - weapon_data.projectiles_per_shot)

	# 범위 레벨 적용 (근접 무기)
	if "level_range" in weapon_data and weapon_data.level_range.size() > level_index:
		if instance.has_method("set_range_multiplier"):
			var range_val = weapon_data.level_range[level_index]
			var base_range = weapon_data.base_range if "base_range" in weapon_data else 80.0
			instance.set_range_multiplier(range_val / base_range)

## 모든 무기 인스턴스에 조준 방향 설정
func set_aim_direction(direction: Vector2) -> void:
	for weapon in weapon_instances:
		if weapon.has_method("set_aim_direction"):
			weapon.set_aim_direction(direction)

## 모든 무기 자동 발사 틱
func auto_fire_tick() -> void:
	for weapon in weapon_instances:
		if weapon.has_method("auto_fire_tick"):
			weapon.auto_fire_tick()

## 모든 무기 인스턴스 초기화
func clear_all() -> void:
	for instance in weapon_instances:
		if is_instance_valid(instance):
			instance.queue_free()
	weapon_instances.clear()
	active_weapons.clear()
