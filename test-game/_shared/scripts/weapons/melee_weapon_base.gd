class_name MeleeWeaponBase
extends "res://_shared/scripts/weapons/weapon_base.gd"

## 근접 무기 베이스 클래스
## 발사체 대신 범위 공격을 수행합니다.

## 범위 수정자 (스킬 등에서 적용)
var range_multiplier: float = 1.0

## 슬래시 이펙트 색상
@export var slash_color: Color = Color(1, 1, 1, 0.8)

## 슬래시 이펙트 클래스 참조
const SlashEffectClass = preload("res://_shared/scripts/weapons/slash_effect.gd")

## 범위 수정자 설정
func set_range_multiplier(value: float) -> void:
	range_multiplier = value

## 현재 범위 계산
func _get_range() -> float:
	var base = weapon_data.base_range if weapon_data else 80.0
	return base * range_multiplier

## 현재 슬래시 각도
func _get_arc_angle() -> float:
	return weapon_data.arc_angle if weapon_data else 120.0

## 슬래시 지속 시간
func _get_slash_duration() -> float:
	return weapon_data.slash_duration if weapon_data else 0.2

## 발사 로직 오버라이드 - 근접 공격
func _fire() -> void:
	can_fire = false
	cooldown_timer = _get_fire_rate()

	# 슬래시 이펙트 생성
	_create_slash_effect()

	# 범위 내 적에게 데미지
	_damage_enemies_in_arc()

	# 시그널 발행
	fired.emit(self, [])

	# EventBus 발행
	if event_bus and owner_node:
		# 근접 공격은 발사체가 없으므로 별도 이벤트 필요 시 추가
		pass

## 슬래시 이펙트 생성
func _create_slash_effect() -> void:
	var effect = SlashEffectClass.new()
	effect.setup(
		_get_range(),
		_get_arc_angle(),
		_get_slash_duration(),
		slash_color
	)

	# 플레이어 위치에 생성
	var spawn_pos = global_position
	effect.global_position = spawn_pos
	effect.rotation = aim_direction.angle()

	get_tree().root.add_child(effect)

## 범위 내 적에게 데미지
func _damage_enemies_in_arc() -> void:
	var range_val = _get_range()
	var half_angle = deg_to_rad(_get_arc_angle() / 2)
	var damage = _get_damage()
	var knockback = weapon_data.knockback_force if weapon_data else 100.0

	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var to_enemy = enemy.global_position - global_position
		var distance = to_enemy.length()

		# 범위 체크
		if distance > range_val:
			continue

		# 각도 체크
		var angle_to_enemy = aim_direction.angle_to(to_enemy.normalized())
		if abs(angle_to_enemy) > half_angle:
			continue

		# 데미지 적용
		if enemy.has_method("take_damage"):
			var direction = to_enemy.normalized()
			enemy.take_damage(damage, direction, knockback)
		elif enemy.has_method("_on_hit"):
			enemy._on_hit(damage, owner_node)

## 발사 사운드 오버라이드 (근접 공격 사운드)
func _play_fire_sound() -> void:
	if weapon_data and weapon_data.fire_sound:
		var audio = AudioStreamPlayer.new()
		audio.stream = weapon_data.fire_sound
		audio.bus = "SFX"
		add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
