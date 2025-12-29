extends "res://_shared/scripts/player/player_base.gd"

## Test Game 플레이어
## 자동 발사, 지형 충돌, 애니메이션, 스킬 시스템

const SkillManagerClass = preload("res://_shared/scripts/progression/skill_manager.gd")

# --- Bullet / Combat Settings ---
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var bullet_speed: int = 2000
@export var base_fire_rate: float = 0.25
@export var base_damage: float = 1.0
@export var shoot_sound: bool = false
@export var rapid_fire: bool = false

var fire_rate: float = 0.25
var bullet_damage: float = 1.0
var can_fire: bool = true

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

	# 스킬 시스템 초기화
	_setup_skill_system()

	# 모바일 컨트롤 찾기
	await get_tree().process_frame
	mobile_controls = get_tree().get_first_node_in_group("mobile_controls")
	if not mobile_controls:
		var parent = get_parent()
		if parent:
			mobile_controls = parent.get_node_or_null("MobileControls")

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

	_update_animation()

func _on_physics_process(_delta: float) -> void:
	# 자동 발사 (뱀서라이크)
	if can_fire:
		_shoot()

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

	var level = get_parent()
	if level.has_method("is_tile_walkable"):
		# X축 체크
		var target_x = global_position + Vector2(potential_vel.x * delta, 0)
		if not _is_position_safe(target_x, level):
			potential_vel.x = 0

		# Y축 체크
		var target_y = global_position + Vector2(0, potential_vel.y * delta)
		if not _is_position_safe(target_y, level):
			potential_vel.y = 0

	return potential_vel

## 위치 안전 체크 (지형 충돌)
func _is_position_safe(target_pos: Vector2, level: Node) -> bool:
	if not has_node("CollisionShape2D"):
		return level.is_tile_walkable(target_pos)

	var col = $CollisionShape2D
	var shape = col.shape

	if not shape is RectangleShape2D:
		return level.is_tile_walkable(target_pos + col.position)

	var half_size = (shape.size * col.scale) / 2
	var center = col.position

	var corners = [
		target_pos + center + Vector2(-half_size.x, -half_size.y),
		target_pos + center + Vector2(half_size.x, -half_size.y),
		target_pos + center + Vector2(half_size.x, half_size.y),
		target_pos + center + Vector2(-half_size.x, half_size.y)
	]

	for p in corners:
		if not level.is_tile_walkable(p):
			return false

	return true

## 현재 위치가 유효한지 체크 (밀림 방지)
func _is_current_position_valid() -> bool:
	var level = get_parent()
	if not level or not level.has_method("is_tile_walkable"):
		return true
	return _is_position_safe(global_position, level)

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

## 발사
func _shoot() -> void:
	can_fire = false

	if shoot_sound:
		$ShootSound.play()

	var bullet_instance = bullet_scene.instantiate()
	var spawn_pos = $GunPivot/BulletOrigin.global_position
	bullet_instance.global_position = spawn_pos

	var direction_rotation = $GunPivot.rotation
	bullet_instance.rotation = direction_rotation

	var direction_vector = Vector2.RIGHT.rotated(direction_rotation)
	bullet_instance.direction = direction_vector

	# 스킬로 강화된 데미지 적용
	bullet_instance.damage = bullet_damage

	get_tree().root.add_child(bullet_instance)

	if not rapid_fire:
		await get_tree().create_timer(fire_rate).timeout
		can_fire = true
	else:
		can_fire = true

## 사망 시 처리 (게임오버 대신 리셋)
func _on_die() -> void:
	print("Player died!")
	current_health = max_health
	health_changed.emit(current_health, max_health)

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
func _on_skill_changed(skill, _level: int) -> void:
	_apply_skill_effects()

## 모든 스킬 효과 재계산
func _apply_skill_effects() -> void:
	# 기본값으로 리셋
	fire_rate = base_fire_rate
	bullet_damage = base_damage
	speed = 200
	max_health = 100.0

	if not skill_manager:
		return

	# Attack Speed
	var attack_speed_value = skill_manager.get_skill_value("attack_speed")
	if attack_speed_value > 0:
		fire_rate = attack_speed_value

	# Damage Up
	var damage_value = skill_manager.get_skill_value("damage_up")
	if damage_value > 0:
		bullet_damage = damage_value

	# Move Speed
	var move_speed_value = skill_manager.get_skill_value("move_speed")
	if move_speed_value > 0:
		speed = int(move_speed_value)

	# Max Health
	var max_health_value = skill_manager.get_skill_value("max_health")
	if max_health_value > 0:
		var health_ratio = current_health / max_health
		max_health = max_health_value
		current_health = max_health * health_ratio
		health_changed.emit(current_health, max_health)

	print("Skills applied - Fire rate: ", fire_rate, " Damage: ", bullet_damage, " Speed: ", speed, " Max HP: ", max_health)
