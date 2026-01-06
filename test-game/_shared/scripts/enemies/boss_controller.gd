class_name BossController
extends RefCounted

## 보스 관리 컨트롤러
##
## 보스의 페이즈 관리, 시각 효과, 특수 능력을 담당합니다.
## EnemyBase에서 사용합니다.

signal phase_changed(phase: int, total_phases: int)
signal boss_enraged  ## 마지막 페이즈 진입 시

## 보스 참조
var enemy: Node2D
var enemy_data: EnemyData

## 페이즈 상태
var current_phase: int = 1
var total_phases: int = 1
var phase_thresholds: Array[float] = []  ## 체력 비율 임계값 (내림차순)

## 페이즈별 효과
var is_enraged: bool = false

## 초기화
func initialize(boss_enemy: Node2D, data: EnemyData) -> void:
	enemy = boss_enemy
	enemy_data = data
	
	if not enemy_data:
		return
	
	total_phases = enemy_data.boss_phases
	phase_thresholds = enemy_data.phase_health_thresholds.duplicate()
	
	# 임계값 정렬 (내림차순 - 높은 체력 비율부터)
	phase_thresholds.sort()
	phase_thresholds.reverse()
	
	# 보스 시각 효과 적용
	_apply_boss_visuals()

## 보스 시각 효과 적용
func _apply_boss_visuals() -> void:
	if not enemy or not enemy_data:
		return
	
	# 스케일 적용
	var sprite = enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.scale *= enemy_data.boss_scale
		# 보스 전용 색상 (보라색 틴트)
		sprite.modulate = Color(0.8, 0.5, 1.0, 1.0)
	
	# 충돌체 스케일 적용
	var collision = enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is CircleShape2D:
		var circle = collision.shape as CircleShape2D
		circle.radius *= enemy_data.boss_scale

## 체력 변경 시 호출 - 페이즈 체크
func check_phase_transition(health_ratio: float) -> void:
	if phase_thresholds.is_empty():
		return
	
	# 다음 페이즈 임계값 확인
	var next_phase_index = current_phase - 1  # 0-based index
	if next_phase_index >= phase_thresholds.size():
		return
	
	var threshold = phase_thresholds[next_phase_index]
	
	if health_ratio <= threshold:
		_advance_phase()

## 다음 페이즈로 전환
func _advance_phase() -> void:
	current_phase += 1
	
	phase_changed.emit(current_phase, total_phases)
	
	# 마지막 페이즈 = 분노 상태
	if current_phase >= total_phases:
		_enter_enraged_state()
	
	# 페이즈 전환 시각 효과
	_phase_transition_effect()

## 분노 상태 진입
func _enter_enraged_state() -> void:
	if is_enraged:
		return
	
	is_enraged = true
	boss_enraged.emit()
	
	# 분노 상태 시각 효과
	var sprite = enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)  # 붉은색으로 변경
	
	# 이동 속도 증가 (옵션)
	if enemy.has_method("set_speed_multiplier"):
		enemy.set_speed_multiplier(1.5)

## 페이즈 전환 시각 효과
func _phase_transition_effect() -> void:
	if not enemy:
		return
	
	# 간단한 깜빡임 효과
	var sprite = enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color.WHITE
		
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			await scene_tree.create_timer(0.1).timeout
			if is_instance_valid(sprite):
				sprite.modulate = original_modulate

## 현재 페이즈 반환
func get_current_phase() -> int:
	return current_phase

## 분노 상태 여부 반환
func is_boss_enraged() -> bool:
	return is_enraged
