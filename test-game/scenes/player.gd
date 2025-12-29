extends "res://_shared/scripts/player/player_base.gd"

## Test Game 플레이어
## WeaponBase 기반 무기 시스템, 지형 충돌, 애니메이션, 스킬 시스템

const SkillManagerClass = preload("res://_shared/scripts/progression/skill_manager.gd")
const WeaponBaseClass = preload("res://_shared/scripts/weapons/weapon_base.gd")

# --- Weapon ---
@export var weapon_data: Resource  ## WeaponData 리소스
var weapon: Node2D = null  ## WeaponBase 인스턴스

# --- Animation State ---
var aim_direction := Vector2.DOWN
@export var direction_smoothing: float = 0.15

# --- Mobile Controls ---
var mobile_controls: CanvasLayer = null

# --- Skill System ---
var skill_manager: SkillManagerClass
var skill_selection_ui: CanvasLayer

## 스킬 리소스 경로들
var skill_paths: Array[String] = [
	"res://resources/skills/attack_speed.tres",
	"res://resources/skills/damage_up.tres",
	"res://resources/skills/max_health.tres",
	"res://resources/skills/move_speed.tres"
]

func _on_ready() -> void:
	# 스프라이트 참조 설정
	player_sprite = $PlayerSprite

	# 시작 애니메이션
	player_sprite.play("idle_down")

	# 무기 시스템 초기화
	_setup_weapon()

	# 스킬 시스템 초기화
	_setup_skill_system()

	# 모바일 컨트롤 찾기
	await get_tree().process_frame
	mobile_controls = get_tree().get_first_node_in_group("mobile_controls")
	if not mobile_controls:
		var parent_node = get_parent()
		if parent_node:
			mobile_controls = parent_node.get_node_or_null("MobileControls")

## 무기 시스템 초기화
func _setup_weapon() -> void:
	# GunPivot 아래에 Weapon 노드 생성
	weapon = WeaponBaseClass.new()
	weapon.name = "Weapon"

	# WeaponData가 없으면 기본 무기 데이터 로드
	if weapon_data:
		weapon.weapon_data = weapon_data
	else:
		weapon.weapon_data = _create_default_weapon_data()

	# Muzzle 위치 설정
	var muzzle = Node2D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector2(16, 0)  # GunPivot 기준 오프셋
	weapon.add_child(muzzle)

	$GunPivot.add_child(weapon)

## 기본 무기 데이터 생성
func _create_default_weapon_data() -> Resource:
	var WeaponDataClass = load("res://_shared/scripts/weapons/weapon_data.gd")
	var data = WeaponDataClass.new()
	data.id = "default_gun"
	data.display_name = "Default Gun"
	data.base_damage = 1.0
	data.fire_rate = 0.25
	data.projectile_speed = 2000.0
	data.projectile_lifetime = 0.5
	data.auto_fire = true
	data.projectile_scene = preload("res://scenes/bullet.tscn")
	return data

## 스킬 시스템 초기화
func _setup_skill_system() -> void:
	# 스킬 매니저 생성
	skill_manager = SkillManagerClass.new()

	# 스킬 풀 로드
	var skills: Array = []
	for path in skill_paths:
		var skill = load(path)
		if skill:
			skills.append(skill)
	skill_manager.set_skill_pool(skills)

	# 스킬 획득 시 효과 적용
	skill_manager.skill_acquired.connect(_on_skill_changed)
	skill_manager.skill_upgraded.connect(_on_skill_changed)

	# 스킬 선택 UI 찾기/생성
	await get_tree().process_frame
	_setup_skill_selection_ui()

## 스킬 선택 UI 설정
func _setup_skill_selection_ui() -> void:
	# 기존 UI 찾기
	skill_selection_ui = get_tree().get_first_node_in_group("skill_selection_ui")

	# 없으면 생성
	if not skill_selection_ui:
		var ui_scene = load("res://scenes/ui/skill_selection.tscn")
		if ui_scene:
			skill_selection_ui = ui_scene.instantiate()
			skill_selection_ui.add_to_group("skill_selection_ui")
			get_tree().root.add_child(skill_selection_ui)

	if skill_selection_ui:
		skill_selection_ui.set_skill_manager(skill_manager)
		skill_selection_ui.skill_selected.connect(_on_skill_selected)

func _process(delta: float) -> void:
	# 부드러운 조준 방향 전환
	aim_direction = aim_direction.lerp(last_direction, 1.0 - pow(direction_smoothing, delta * 60))

	if aim_direction != Vector2.ZERO:
		$GunPivot.rotation = aim_direction.angle()

		# 무기에 조준 방향 전달
		if weapon:
			weapon.set_aim_direction(aim_direction)

	_update_animation()

func _on_physics_process(_delta: float) -> void:
	# 자동 발사 (WeaponBase가 처리)
	if weapon:
		weapon.auto_fire_tick()

## 입력 방향 (모바일 조이스틱 지원)
func _get_input_direction() -> Vector2:
	var direction := Input.get_vector("left", "right", "up", "down")

	# 모바일 조이스틱 입력 (키보드 입력이 없을 때)
	if direction == Vector2.ZERO and mobile_controls:
		direction = mobile_controls.get_joystick_direction()

	return direction

## 속도 계산 (지형 충돌 체크)
func _calculate_velocity(direction: Vector2, delta: float) -> Vector2:
	var potential_vel = direction * speed

	var level_node = get_parent()
	if level_node and level_node.has_method("is_tile_walkable"):
		# X축 체크
		var target_x = global_position + Vector2(potential_vel.x * delta, 0)
		if not _is_position_safe(target_x, level_node):
			potential_vel.x = 0

		# Y축 체크
		var target_y = global_position + Vector2(0, potential_vel.y * delta)
		if not _is_position_safe(target_y, level_node):
			potential_vel.y = 0

	return potential_vel

## 위치 안전 체크 (지형 충돌)
func _is_position_safe(target_pos: Vector2, level_node: Node) -> bool:
	if not has_node("CollisionShape2D"):
		return level_node.is_tile_walkable(target_pos)

	var col = $CollisionShape2D
	var col_shape = col.shape

	if not col_shape is RectangleShape2D:
		return level_node.is_tile_walkable(target_pos + col.position)

	var half_size = (col_shape.size * col.scale) / 2
	var center = col.position

	var corners = [
		target_pos + center + Vector2(-half_size.x, -half_size.y),
		target_pos + center + Vector2(half_size.x, -half_size.y),
		target_pos + center + Vector2(half_size.x, half_size.y),
		target_pos + center + Vector2(-half_size.x, half_size.y)
	]

	for p in corners:
		if not level_node.is_tile_walkable(p):
			return false

	return true

## 현재 위치가 유효한지 체크 (밀림 방지)
func _is_current_position_valid() -> bool:
	var level_node = get_parent()
	if not level_node or not level_node.has_method("is_tile_walkable"):
		return true
	return _is_position_safe(global_position, level_node)

## 애니메이션 업데이트
func _update_animation() -> void:
	var anim_name = "idle"

	if velocity.length() > 0:
		anim_name = "walk"

	var dir = last_direction
	if velocity.length() > 0:
		dir = velocity.normalized()

	var final_anim = ""
	var flip = false

	if abs(dir.x) > abs(dir.y):
		final_anim = anim_name + "_right"
		if dir.x < 0:
			flip = true
	else:
		if dir.y < 0:
			final_anim = anim_name + "_up"
		else:
			final_anim = anim_name + "_down"

	player_sprite.flip_h = flip

	if player_sprite.animation != final_anim:
		player_sprite.play(final_anim)

## 사망 시 처리
func _on_die() -> void:
	print("Player died!")

## 레벨업 시 처리 - 스킬 선택 UI 표시
func _on_level_up() -> void:
	print("LEVEL UP! Now level ", current_level)

	# 스킬 선택지 생성 및 UI 표시
	if skill_manager and skill_selection_ui:
		var options = skill_manager.request_skill_selection()
		if not options.is_empty():
			skill_selection_ui.show_selection(options)

## 스킬 선택 완료 시
func _on_skill_selected(skill) -> void:
	print("Selected skill: ", skill.display_name)

## 스킬 획득/업그레이드 시 효과 적용
func _on_skill_changed(skill, skill_level: int) -> void:
	# StatManager 기반 수정자 적용
	if skill.has_method("has_stat_modifier") and skill.has_stat_modifier():
		apply_skill_modifier(skill, skill_level)

	# 무기 스탯 업데이트
	_update_weapon_stats()

	_debug_print_stats()

## 무기 스탯 업데이트 (StatManager → Weapon)
func _update_weapon_stats() -> void:
	if not weapon or not stat_manager:
		return

	# StatManager에서 무기 관련 스탯 가져와서 적용
	weapon.set_damage_multiplier(stat_manager.get_damage())
	weapon.set_fire_rate_multiplier(stat_manager.get_fire_rate() / weapon.weapon_data.fire_rate)
	weapon.set_additional_projectiles(stat_manager.get_projectile_count() - 1)

## 디버그 출력
func _debug_print_stats() -> void:
	if stat_manager:
		print("Stats - Speed: %.0f, MaxHP: %.0f, Damage: %.1f, FireRate: %.2f" % [
			speed, max_health,
			stat_manager.get_damage(),
			stat_manager.get_fire_rate()
		])
