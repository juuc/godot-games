class_name EnemyDropController
extends RefCounted

## 적 드롭 아이템 관리
##
## XP 젬, 체력 픽업, 보물상자, 데미지 팝업 스폰을 담당합니다.
## EnemyBase에서 사용합니다.

const ResourcePathsClass = preload("res://_shared/scripts/core/resource_paths.gd")

## 씬 캐시
var xp_gem_scene: PackedScene = null
var health_pickup_scene: PackedScene = null
var treasure_chest_scene: PackedScene = null
var damage_popup_scene: PackedScene = null

## 드롭 아이템 스폰
func spawn_drops(enemy_data: EnemyData, position: Vector2, target: Node2D) -> void:
	if not enemy_data:
		return

	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return

	# XP 젬 스폰
	if enemy_data.xp_value > 0:
		_spawn_xp_gem(enemy_data.xp_value, position, scene_tree)

	# 체력 픽업 스폰 (플레이어 체력에 따라 확률 조정)
	_try_spawn_health_pickup(enemy_data, position, target, scene_tree)

	# 보물상자 스폰 (낮은 확률)
	_try_spawn_treasure_chest(enemy_data, position, scene_tree)

## XP 젬 스폰
func _spawn_xp_gem(xp_value: int, position: Vector2, scene_tree: SceneTree) -> void:
	# 씬 로드 (캐시)
	if not xp_gem_scene:
		xp_gem_scene = ResourcePathsClass.load_scene(ResourcePathsClass.PICKUP_XP_GEM)

	if not xp_gem_scene:
		return

	var gem = xp_gem_scene.instantiate()
	gem.xp_value = xp_value
	gem.global_position = position

	scene_tree.current_scene.call_deferred("add_child", gem)

## 체력 픽업 드롭 시도
func _try_spawn_health_pickup(enemy_data: EnemyData, position: Vector2, target: Node2D, scene_tree: SceneTree) -> void:
	# GameConfig에서 기본값 가져오기
	var config = Services.config
	var base_chance = config.health_drop_base_chance if config else 0.05
	var low_hp_chance = config.health_drop_low_hp_chance if config else 0.20
	var low_hp_threshold = config.health_drop_low_hp_threshold if config else 0.3

	# EnemyData가 있으면 덮어쓰기
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
		_spawn_health_pickup(position, scene_tree)

## 체력 픽업 스폰
func _spawn_health_pickup(position: Vector2, scene_tree: SceneTree) -> void:
	# 씬 로드 (캐시)
	if not health_pickup_scene:
		health_pickup_scene = ResourcePathsClass.load_scene(ResourcePathsClass.PICKUP_HEALTH)

	if not health_pickup_scene:
		return

	var pickup = health_pickup_scene.instantiate()
	pickup.global_position = position

	scene_tree.current_scene.call_deferred("add_child", pickup)

## 보물상자 드롭 시도
func _try_spawn_treasure_chest(enemy_data: EnemyData, position: Vector2, scene_tree: SceneTree) -> void:
	var config = Services.config
	var chance = config.treasure_drop_chance if config else 0.01

	if enemy_data and "treasure_drop_chance" in enemy_data:
		chance = enemy_data.treasure_drop_chance

	if randf() <= chance:
		_spawn_treasure_chest(position, scene_tree)

## 보물상자 스폰
func _spawn_treasure_chest(position: Vector2, scene_tree: SceneTree) -> void:
	# 씬 로드 (캐시)
	if not treasure_chest_scene:
		treasure_chest_scene = ResourcePathsClass.load_scene(ResourcePathsClass.PICKUP_TREASURE)

	if not treasure_chest_scene:
		return

	var chest = treasure_chest_scene.instantiate()
	chest.global_position = position

	scene_tree.current_scene.call_deferred("add_child", chest)

## 데미지 팝업 생성
func spawn_damage_popup(amount: float, position: Vector2) -> void:
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return

	# 씬 로드 (캐시)
	if not damage_popup_scene:
		damage_popup_scene = ResourcePathsClass.load_scene(ResourcePathsClass.UI_DAMAGE_POPUP)

	if not damage_popup_scene:
		return

	var popup = damage_popup_scene.instantiate()
	popup.global_position = position + Vector2(0, -10)  # 약간 위에

	scene_tree.current_scene.call_deferred("add_child", popup)

	# setup은 다음 프레임에 호출 (씬 트리에 추가된 후)
	popup.call_deferred("setup", amount, "damage")
