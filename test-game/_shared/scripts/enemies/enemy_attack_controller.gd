class_name EnemyAttackController
extends RefCounted

## 적 공격 로직 관리
##
## 근접 및 원거리 공격 처리를 담당합니다.
## EnemyBase에서 사용합니다.

const ResourcePathsClass = preload("res://_shared/scripts/core/resource_paths.gd")

signal attack_started
signal attack_finished
signal projectile_fired(projectile: Node2D)

## 공격 가능 여부 체크
func can_attack(enemy_position: Vector2, target: Node2D, attack_range: float) -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	var distance = enemy_position.distance_to(target.global_position)
	return distance <= attack_range

## 근접 공격 실행
func execute_melee_attack(target: Node2D, damage: float, enemy_position: Vector2) -> void:
	if not target or not is_instance_valid(target):
		return
	
	if target.has_method("take_damage"):
		var knockback_dir = (target.global_position - enemy_position).normalized()
		target.take_damage(damage, knockback_dir)
	
	attack_finished.emit()

## 원거리 공격 실행
func execute_ranged_attack(
	enemy_position: Vector2,
	target: Node2D,
	damage: float,
	projectile_speed: float,
	projectile_scene: PackedScene = null
) -> void:
	if not target or not is_instance_valid(target):
		return
	
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return
	
	# 발사체 씬 결정 (전달받은 씬 또는 기본 씬)
	var scene_to_use = projectile_scene
	if not scene_to_use:
		scene_to_use = ResourcePathsClass.load_scene(ResourcePathsClass.ENEMY_PROJECTILE)
	
	if not scene_to_use:
		push_warning("EnemyAttackController: No projectile scene available")
		return
	
	var projectile = scene_to_use.instantiate()
	projectile.global_position = enemy_position
	
	# 발사 방향 계산
	var direction = (target.global_position - enemy_position).normalized()
	
	# 발사체 설정
	if projectile.has_method("setup"):
		projectile.setup(direction, projectile_speed, damage)
	else:
		projectile.direction = direction
		projectile.speed = projectile_speed
		projectile.damage = damage
	
	scene_tree.current_scene.call_deferred("add_child", projectile)
	projectile_fired.emit(projectile)
	attack_finished.emit()

## 공격 타입에 따라 적절한 공격 실행
func execute_attack(
	attack_type: EnemyData.AttackType,
	enemy_position: Vector2,
	target: Node2D,
	damage: float,
	projectile_speed: float = 200.0,
	projectile_scene: PackedScene = null
) -> void:
	attack_started.emit()
	
	match attack_type:
		EnemyData.AttackType.MELEE:
			execute_melee_attack(target, damage, enemy_position)
		EnemyData.AttackType.RANGED:
			execute_ranged_attack(enemy_position, target, damage, projectile_speed, projectile_scene)
