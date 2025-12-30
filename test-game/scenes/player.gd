extends "res://_shared/scripts/player/player_base.gd"

## Test Game 플레이어
## WeaponManager 기반 다중 무기 시스템, 지형 충돌, 애니메이션, 스킬 시스템

const SkillManagerClass = preload("res://_shared/scripts/progression/skill_manager.gd")
const WeaponManagerClass = preload("res://_shared/scripts/weapons/weapon_manager.gd")
const WeaponBaseClass = preload("res://_shared/scripts/weapons/weapon_base.gd")
const MeleeWeaponBaseClass = preload("res://_shared/scripts/weapons/melee_weapon_base.gd")

# --- Weapon Manager ---
var weapon_manager: WeaponManagerClass = null

## 무기 리소스 경로들 (무기 풀)
var weapon_paths: Array[String] = [
	"res://resources/weapons/default_pistol.tres",
	"res://resources/weapons/shotgun.tres",
	"res://resources/weapons/greatsword.tres"
]

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
	# WeaponManager 생성
	weapon_manager = WeaponManagerClass.new()
	weapon_manager.set_weapon_parent($GunPivot)

	# 무기 풀 로드
	var weapons: Array = []
	for path in weapon_paths:
		var weapon_data = load(path)
		if weapon_data:
			weapons.append(weapon_data)
	weapon_manager.set_weapon_pool(weapons)

	# 시그널 연결
	weapon_manager.weapon_acquired.connect(_on_weapon_acquired)
	weapon_manager.weapon_upgraded.connect(_on_weapon_upgraded)

	# 기본 무기로 시작 (default_pistol)
	if weapons.size() > 0:
		weapon_manager.add_weapon(weapons[0])

## 무기 획득 시
func _on_weapon_acquired(weapon_data, level: int) -> void:
	print("Weapon acquired: ", weapon_data.display_name, " Lv.", level)
	_create_weapon_instance(weapon_data)

## 무기 업그레이드 시
func _on_weapon_upgraded(weapon_data, new_level: int) -> void:
	print("Weapon upgraded: ", weapon_data.display_name, " -> Lv.", new_level)
	# WeaponManager가 자동으로 스탯 업데이트

## 무기 인스턴스 생성
func _create_weapon_instance(weapon_data) -> void:
	var instance = weapon_manager.create_weapon_instance(
		weapon_data,
		WeaponBaseClass,
		MeleeWeaponBaseClass
	)
	$GunPivot.add_child(instance)

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
		if skill_selection_ui.has_method("set_weapon_manager"):
			skill_selection_ui.set_weapon_manager(weapon_manager)
		skill_selection_ui.skill_selected.connect(_on_skill_selected)

func _process(delta: float) -> void:
	# 부드러운 조준 방향 전환
	aim_direction = aim_direction.lerp(last_direction, 1.0 - pow(direction_smoothing, delta * 60))

	if aim_direction != Vector2.ZERO:
		$GunPivot.rotation = aim_direction.angle()

		# 모든 무기에 조준 방향 전달
		if weapon_manager:
			weapon_manager.set_aim_direction(aim_direction)

	_update_animation()

func _on_physics_process(_delta: float) -> void:
	# 모든 무기 자동 발사 (WeaponManager가 처리)
	if weapon_manager:
		weapon_manager.auto_fire_tick()

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

	# EntityLayer 안에 있으므로 그룹으로 레벨 찾기
	var level_node = get_tree().get_first_node_in_group("level")
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
	# EntityLayer 안에 있으므로 그룹으로 레벨 찾기
	var level_node = get_tree().get_first_node_in_group("level")
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

## 레벨업 시 처리 - 무기/패시브 통합 선택 UI 표시
func _on_level_up() -> void:
	print("LEVEL UP! Now level ", current_level)

	# 무기 + 패시브 통합 선택지 생성
	var combined_options: Array = []

	# 무기 옵션 추가
	if weapon_manager:
		combined_options.append_array(weapon_manager.get_available_options())

	# 패시브 옵션 추가
	if skill_manager:
		combined_options.append_array(skill_manager.get_passive_options())

	# 선택지 섞기 및 UI 표시
	if not combined_options.is_empty() and skill_selection_ui:
		combined_options.shuffle()
		# 최대 3개만 표시
		var display_options = combined_options.slice(0, mini(3, combined_options.size()))
		skill_selection_ui.show_selection(display_options)

## 선택 완료 시 (무기 또는 패시브)
func _on_skill_selected(option) -> void:
	# 통합 옵션 형식: {type: "weapon"|"passive", data, level}
	if option is Dictionary and option.has("type"):
		var option_type = option.type
		var data = option.data

		if option_type == "weapon":
			# 무기 획득/업그레이드
			if weapon_manager:
				weapon_manager.add_weapon(data)
			print("Selected weapon: ", data.display_name)
		elif option_type == "passive":
			# 패시브 스킬 획득/업그레이드
			if skill_manager:
				skill_manager.acquire_skill(data)
			print("Selected passive: ", data.display_name)
	else:
		# 기존 스킬 형식 (하위 호환)
		if skill_manager:
			skill_manager.acquire_skill(option)
		print("Selected skill: ", option.display_name)

	# 선택 완료 후 레벨업 무적 효과 시작
	_start_levelup_invincibility()

## 스킬 획득/업그레이드 시 효과 적용
func _on_skill_changed(skill, skill_level: int) -> void:
	# StatManager 기반 수정자 적용
	if skill.has_method("has_stat_modifier") and skill.has_stat_modifier():
		apply_skill_modifier(skill, skill_level)

	# 무기 스탯 업데이트
	_update_weapon_stats()

	_debug_print_stats()

## 무기 스탯 업데이트 (StatManager → 모든 Weapon)
## 무기 레벨별 스탯은 WeaponManager가 set_fire_rate_multiplier로 관리
## 스킬 효과는 set_skill_fire_rate_multiplier로 별도 적용
func _update_weapon_stats() -> void:
	if not weapon_manager or not stat_manager:
		return

	# StatManager 기본값 (수정자 계산용)
	const BASE_DAMAGE: float = 1.0
	const BASE_FIRE_RATE: float = 0.25

	# StatManager에서 무기 관련 스탯 가져오기
	var damage_value = stat_manager.get_damage()
	var fire_rate_value = stat_manager.get_fire_rate()
	var projectile_bonus = stat_manager.get_projectile_count() - 1

	# 데미지 배수 계산 (stat_manager base 대비)
	var damage_mult = damage_value / BASE_DAMAGE

	# Fire rate 배수 계산 - 스킬에 의한 배수만 계산
	# 값이 작을수록 빠름 (0.9 = 10% 빠름)
	var skill_fire_rate_mult = fire_rate_value / BASE_FIRE_RATE

	for weapon_instance in weapon_manager.get_weapon_instances():
		if not is_instance_valid(weapon_instance):
			continue

		# 데미지 적용
		weapon_instance.set_damage_multiplier(damage_mult)

		# Fire rate 스킬 효과 적용 (무기 레벨 배수와는 별도로 곱해짐)
		if weapon_instance.has_method("set_skill_fire_rate_multiplier"):
			weapon_instance.set_skill_fire_rate_multiplier(skill_fire_rate_mult)

		weapon_instance.set_additional_projectiles(projectile_bonus)

## 디버그 출력
func _debug_print_stats() -> void:
	if stat_manager:
		print("Stats - Speed: %.0f, MaxHP: %.0f, Damage: %.1f, FireRate: %.2f" % [
			speed, max_health,
			stat_manager.get_damage(),
			stat_manager.get_fire_rate()
		])
